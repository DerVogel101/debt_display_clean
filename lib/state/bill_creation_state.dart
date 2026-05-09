import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class BillDraftTag {
  const BillDraftTag({
    this.id,
    required this.text,
    required this.icon,
    required this.color,
  });

  final int? id;
  final String text;
  final String icon;
  final String color;
}

class BillDraftAttachment {
  const BillDraftAttachment({
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final String? contentType;
}

class BillDraftShare {
  const BillDraftShare({required this.userId, required this.sharePercent});

  final int userId;
  final double sharePercent;
}

class BillCreationState extends ChangeNotifier {
  BillCreationState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  static const maxTitleLength = 256;
  static const maxDescriptionLength = 256;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  bool _isAuthenticated = false;
  bool _hasOpened = false;
  bool _hasLoadedReferenceData = false;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;
  List<TagIndex> _availableTags = const [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  List<TagIndex> get availableTags => _availableTags;

  void updateAuthSession(AuthSessionState authSessionState) {
    final nextAccessToken = authSessionState.accessToken;
    final nextAuthenticated =
        authSessionState.isAuthenticated && nextAccessToken != null;
    final authChanged =
        _isAuthenticated != nextAuthenticated ||
        _accessToken != nextAccessToken;
    if (!authChanged) {
      return;
    }

    _isAuthenticated = nextAuthenticated;
    _accessToken = nextAccessToken;
    if (!_isAuthenticated) {
      _clearData();
      notifyListeners();
      return;
    }

    _markReferenceDataStale();
    if (_hasOpened) {
      Future<void>.microtask(ensureLoaded);
    }
  }

  Future<void> ensureLoaded() async {
    _hasOpened = true;
    if (!_isAuthenticated || _accessToken == null) {
      return;
    }
    if (_isLoading || _hasLoadedReferenceData) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tagsResponse = await _debtBackendService.listRecommendedTags(
        _accessToken!,
      );
      if (!tagsResponse.success) {
        throw StateError(tagsResponse.message);
      }
      _availableTags = List<TagIndex>.unmodifiable(
        tagsResponse.tags.map((tag) => tag.deepCopy()),
      );
      _hasLoadedReferenceData = true;
    } catch (error) {
      _errorMessage = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Receipt?> saveBill({
    required String title,
    required String description,
    required double amountOwed,
    required String currency,
    required int? recipientId,
    required String notes,
    required double? ownerSharePercent,
    required Iterable<BillDraftShare> recipientShares,
    required Iterable<BillDraftTag> tags,
    required Iterable<BillDraftAttachment> attachments,
  }) async {
    final accessToken = _accessToken;
    if (!_isAuthenticated || accessToken == null || _isMutating) {
      return null;
    }

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCurrency = currency.trim().toUpperCase();
    final cleanNotes = notes.trim();
    final cleanShares = recipientShares
        .where((share) => share.sharePercent > 0)
        .toList(growable: false);
    final splitOwnerPercent = ownerSharePercent;

    final validationError = _validate(
      title: cleanTitle,
      description: cleanDescription,
      amountOwed: amountOwed,
      currency: cleanCurrency,
      recipientId: recipientId,
      ownerSharePercent: splitOwnerPercent,
      recipientShares: cleanShares,
    );
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return null;
    }

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    int? createdReceiptId;
    try {
      final request = CreateReceiptRequest(
        title: cleanTitle,
        amountOwed: amountOwed,
        currency: cleanCurrency,
      );
      if (cleanDescription.isNotEmpty) {
        request.description = cleanDescription;
      }
      if (cleanNotes.isNotEmpty) {
        request.notes = cleanNotes;
      }
      if (recipientId != null) {
        request.recipientId = Int64(recipientId);
      }
      if (recipientId != null &&
          splitOwnerPercent != null &&
          cleanShares.isNotEmpty) {
        request.split = ReceiptSplitInput(
          ownerSharePercent: splitOwnerPercent,
          recipientShares: cleanShares
              .map(
                (share) => ReceiptRecipientShareInput(
                  userId: Int64(share.userId),
                  sharePercent: share.sharePercent,
                ),
              )
              .toList(),
        );
      }

      final receiptResponse = await _debtBackendService.createReceipt(
        accessToken,
        request,
      );
      if (!receiptResponse.success) {
        throw StateError(receiptResponse.message);
      }

      final receiptId = receiptResponse.receipt.id.toInt();
      createdReceiptId = receiptId;
      final tagIds = <int>{};
      for (final tag in tags) {
        final cleanTagText = tag.text.trim();
        if (cleanTagText.isEmpty) {
          continue;
        }
        if (tag.id != null) {
          tagIds.add(tag.id!);
          continue;
        }
        final tagResponse = await _debtBackendService.getOrCreateTag(
          accessToken,
          TagUpsertRequest(
            text: cleanTagText,
            icon: tag.icon.trim().isEmpty ? '🏷️' : tag.icon.trim(),
            color: tag.color.trim().isEmpty ? '#64B5F6' : tag.color.trim(),
          ),
        );
        if (!tagResponse.success) {
          throw StateError(tagResponse.message);
        }
        tagIds.add(tagResponse.tag.id.toInt());
      }
      if (tagIds.isNotEmpty) {
        final tagResponse = await _debtBackendService.setReceiptTags(
          accessToken,
          SetReceiptTagsRequest(
            receiptId: receiptResponse.receipt.id,
            tagIds: tagIds.map(Int64.new),
          ),
        );
        if (!tagResponse.success) {
          throw StateError(tagResponse.message);
        }
      }

      for (final attachment in attachments) {
        if (attachment.filename.trim().isEmpty || attachment.bytes.isEmpty) {
          continue;
        }
        final fileResponse = await _debtBackendService.uploadReceiptFile(
          accessToken,
          receiptId: receiptId,
          filename: attachment.filename.trim(),
          bytes: attachment.bytes,
          contentType: attachment.contentType,
        );
        if (!fileResponse.success) {
          throw StateError(fileResponse.message);
        }
      }

      createdReceiptId = null;
      _markReferenceDataStale();
      await ensureLoaded();
      return receiptResponse.receipt.deepCopy();
    } catch (error) {
      final mutationMessage = _formatError(error);
      if (createdReceiptId != null) {
        final rollbackError = await _rollbackCreatedReceipt(
          accessToken,
          createdReceiptId,
        );
        _errorMessage = rollbackError == null
            ? mutationMessage
            : '$mutationMessage Cleanup failed, so the bill may already exist: $rollbackError';
      } else {
        _errorMessage = mutationMessage;
      }
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _markReferenceDataStale();
    await ensureLoaded();
  }

  String? _validate({
    required String title,
    required String description,
    required double amountOwed,
    required String currency,
    required int? recipientId,
    required double? ownerSharePercent,
    required List<BillDraftShare> recipientShares,
  }) {
    if (title.isEmpty) {
      return 'Bill title is required.';
    }
    if (title.length > maxTitleLength) {
      return 'Bill title must be 256 characters or fewer.';
    }
    if (description.length > maxDescriptionLength) {
      return 'Description must be 256 characters or fewer.';
    }
    if (amountOwed <= 0 || !amountOwed.isFinite) {
      return 'Enter a valid bill amount.';
    }
    if (currency.isEmpty || currency.length > 8) {
      return 'Select a valid currency.';
    }
    if (recipientId == null || recipientShares.isEmpty) {
      return null;
    }
    final ownerPercent = ownerSharePercent ?? 0;
    if (ownerPercent < 0 || ownerPercent > 100) {
      return 'Owner share must be between 0% and 100%.';
    }
    final total =
        ownerPercent +
        recipientShares.fold<double>(
          0,
          (sum, share) => sum + share.sharePercent,
        );
    if ((total - 100).abs() > 0.01) {
      return 'Shares must add up to 100%.';
    }
    return null;
  }

  void _markReferenceDataStale() {
    _hasLoadedReferenceData = false;
  }

  void _clearData() {
    _markReferenceDataStale();
    _availableTags = const [];
    _errorMessage = null;
  }

  Future<String?> _rollbackCreatedReceipt(
    String accessToken,
    int receiptId,
  ) async {
    try {
      final response = await _debtBackendService.deleteReceipt(
        accessToken,
        ReceiptLookupRequest(receiptId: Int64(receiptId)),
      );
      if (response.success) {
        return null;
      }
      final message = response.message.trim();
      return message.isEmpty
          ? 'The partially created bill could not be deleted.'
          : message;
    } catch (error) {
      return _formatError(error);
    }
  }

  String _formatError(Object error) {
    final message = error.toString();
    const prefix = 'Bad state: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }
}

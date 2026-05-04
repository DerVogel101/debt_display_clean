import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

enum BillPaymentFilter {
  all('All'),
  unpaid('Unpaid'),
  paid('Paid');

  const BillPaymentFilter(this.label);

  final String label;

  bool? get apiValue => switch (this) {
    BillPaymentFilter.all => null,
    BillPaymentFilter.unpaid => false,
    BillPaymentFilter.paid => true,
  };
}

class BillListState extends ChangeNotifier {
  BillListState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  int? _currentUserId;
  bool _isAuthenticated = false;
  bool _hasOpenedBills = false;
  bool _hasLoadedTags = false;
  bool _hasLoadedPage = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Receipt> _receipts = const [];
  List<TagIndex> _availableTags = const [];
  BillPaymentFilter _paymentFilter = BillPaymentFilter.all;
  Set<int> _selectedTagIds = <int>{};
  ReceiptOrderBy _orderBy = ReceiptOrderBy.RECEIPT_ORDER_BY_ID;
  ReceiptOrderDirection _orderDirection =
      ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC;
  ReceiptActorFilter _actorFilter =
      ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP;
  int _pageSize = 20;
  List<String?> _visitedPageTokens = [null];
  int _currentPageIndex = 0;
  String? _nextPageToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Receipt> get receipts => _receipts;
  List<TagIndex> get availableTags => _availableTags;
  BillPaymentFilter get paymentFilter => _paymentFilter;
  Set<int> get selectedTagIds => Set<int>.unmodifiable(_selectedTagIds);
  ReceiptOrderBy get orderBy => _orderBy;
  ReceiptOrderDirection get orderDirection => _orderDirection;
  ReceiptActorFilter get actorFilter => _actorFilter;
  int get pageSize => _pageSize;
  int get currentPage => _currentPageIndex + 1;
  bool get hasPreviousPage => _currentPageIndex > 0;
  bool get hasNextPage => _nextPageToken != null;

  void updateAuthSession(AuthSessionState authSessionState) {
    final nextAccessToken = authSessionState.accessToken;
    final nextUserId = authSessionState.userId;
    final nextAuthenticated =
        authSessionState.isAuthenticated &&
        nextAccessToken != null &&
        nextUserId != null;

    final authChanged =
        _isAuthenticated != nextAuthenticated ||
        _accessToken != nextAccessToken ||
        _currentUserId != nextUserId;

    if (!authChanged) {
      return;
    }

    _isAuthenticated = nextAuthenticated;
    _accessToken = nextAccessToken;
    _currentUserId = nextUserId;

    if (!_isAuthenticated) {
      _hasLoadedTags = false;
      _hasLoadedPage = false;
      _errorMessage = null;
      _receipts = const [];
      _availableTags = const [];
      _resetPagination();
      return;
    }

    if (_hasOpenedBills) {
      _hasLoadedTags = false;
      _hasLoadedPage = false;
      _resetPagination();
      Future<void>.microtask(() => _runLoad(resetPage: true));
    }
  }

  Future<void> ensureLoaded() async {
    _hasOpenedBills = true;
    if (!_isAuthenticated) {
      return;
    }
    if (_isLoading || (_hasLoadedPage && _hasLoadedTags)) {
      return;
    }
    await _loadPage();
  }

  Future<void> refresh() async {
    await _runLoad(resetPage: true);
  }

  Future<void> goToNextPage() async {
    if (!hasNextPage || _isLoading) {
      return;
    }
    final nextPageToken = _nextPageToken;
    if (nextPageToken == null) {
      return;
    }
    if (_currentPageIndex == _visitedPageTokens.length - 1) {
      _visitedPageTokens.add(nextPageToken);
    } else {
      _visitedPageTokens[_currentPageIndex + 1] = nextPageToken;
      _visitedPageTokens.length = _currentPageIndex + 2;
    }
    _currentPageIndex += 1;
    await _loadPage();
  }

  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage || _isLoading) {
      return;
    }
    _currentPageIndex -= 1;
    await _loadPage();
  }

  Future<void> setPaymentFilter(BillPaymentFilter value) async {
    if (_paymentFilter == value) {
      return;
    }
    _paymentFilter = value;
    await _runLoad(resetPage: true);
  }

  Future<void> toggleTag(int tagId) async {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    await _runLoad(resetPage: true);
  }

  Future<void> setOrderBy(ReceiptOrderBy value) async {
    if (_orderBy == value) {
      return;
    }
    _orderBy = value;
    await _runLoad(resetPage: true);
  }

  Future<void> setOrderDirection(ReceiptOrderDirection value) async {
    if (_orderDirection == value) {
      return;
    }
    _orderDirection = value;
    await _runLoad(resetPage: true);
  }

  Future<void> setActorFilter(ReceiptActorFilter value) async {
    if (_actorFilter == value) {
      return;
    }
    _actorFilter = value;
    await _runLoad(resetPage: true);
  }

  Future<void> setPageSize(int value) async {
    if (_pageSize == value) {
      return;
    }
    _pageSize = value;
    await _runLoad(resetPage: true);
  }

  Future<void> resetFilters() async {
    final filtersAlreadyDefault =
        _paymentFilter == BillPaymentFilter.all &&
        _selectedTagIds.isEmpty &&
        _orderBy == ReceiptOrderBy.RECEIPT_ORDER_BY_ID &&
        _orderDirection == ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC &&
        _actorFilter ==
            ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP &&
        _pageSize == 20 &&
        _currentPageIndex == 0;
    if (filtersAlreadyDefault) {
      return;
    }
    _paymentFilter = BillPaymentFilter.all;
    _selectedTagIds = <int>{};
    _orderBy = ReceiptOrderBy.RECEIPT_ORDER_BY_ID;
    _orderDirection = ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC;
    _actorFilter =
        ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP;
    _pageSize = 20;
    await _runLoad(resetPage: true);
  }

  String roleLabelFor(Receipt receipt) {
    if (_currentUserId == null) {
      return 'Participant';
    }
    return receipt.ownerId.toInt() == _currentUserId ? 'Owner' : 'Participant';
  }

  double myShareFor(Receipt receipt) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return 0;
    }

    if (receipt.ownerId.toInt() == currentUserId) {
      if (receipt.hasSplit()) {
        return receipt.split.ownerAmount;
      }
      return receipt.amountOwed;
    }

    if (!receipt.hasSplit()) {
      return 0;
    }

    for (final share in receipt.split.recipientShares) {
      if (share.userId.toInt() == currentUserId) {
        return share.amount;
      }
    }

    return 0;
  }

  Future<void> _runLoad({required bool resetPage}) async {
    if (resetPage) {
      _resetPagination();
    }
    await _loadPage();
  }

  void _resetPagination() {
    _visitedPageTokens = [null];
    _currentPageIndex = 0;
    _nextPageToken = null;
  }

  Future<void> _loadPage() async {
    if (!_isAuthenticated || _accessToken == null || _currentUserId == null) {
      _receipts = const [];
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_hasLoadedTags) {
        final tagsResponse = await _debtBackendService.listTags(_accessToken!);
        if (!tagsResponse.success) {
          throw StateError(tagsResponse.message);
        }
        _availableTags = List<TagIndex>.unmodifiable(tagsResponse.tags);
        _hasLoadedTags = true;
      }

      final request = ReceiptListRequest(
        limit: _pageSize,
        orderBy: _orderBy,
        orderDirection: _orderDirection,
        actorFilter: _actorFilter,
      );

      final paymentValue = _paymentFilter.apiValue;
      if (paymentValue != null) {
        request.isPaid = paymentValue;
      }
      if (_selectedTagIds.isNotEmpty) {
        request.tagIds.addAll(_selectedTagIds.map((tagId) => Int64(tagId)));
      }

      final currentPageToken = _visitedPageTokens[_currentPageIndex];
      if (currentPageToken != null) {
        request.pageToken = currentPageToken;
      }

      final response = await _debtBackendService.listReceipts(
        _accessToken!,
        request,
      );
      if (!response.success) {
        throw StateError(response.message);
      }

      _receipts = List<Receipt>.unmodifiable(response.receipts);
      _nextPageToken = response.hasNextPageToken()
          ? response.nextPageToken
          : null;
      _hasLoadedPage = true;
    } catch (error) {
      _receipts = const [];
      _nextPageToken = null;
      _errorMessage = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
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

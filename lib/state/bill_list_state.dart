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

class BillListQuery {
  BillListQuery({
    required this.paymentFilter,
    required Set<int> selectedTagIds,
    required this.orderBy,
    required this.orderDirection,
    required this.actorFilter,
    required this.pageSize,
  }) : selectedTagIds = Set<int>.unmodifiable(selectedTagIds);

  factory BillListQuery.defaults() {
    return BillListQuery(
      paymentFilter: BillPaymentFilter.all,
      selectedTagIds: const <int>{},
      orderBy: ReceiptOrderBy.RECEIPT_ORDER_BY_ID,
      orderDirection: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC,
      actorFilter:
          ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
      pageSize: BillListState.defaultPageSize,
    );
  }

  final BillPaymentFilter paymentFilter;
  final Set<int> selectedTagIds;
  final ReceiptOrderBy orderBy;
  final ReceiptOrderDirection orderDirection;
  final ReceiptActorFilter actorFilter;
  final int pageSize;

  BillListQuery copyWith({
    BillPaymentFilter? paymentFilter,
    Set<int>? selectedTagIds,
    ReceiptOrderBy? orderBy,
    ReceiptOrderDirection? orderDirection,
    ReceiptActorFilter? actorFilter,
    int? pageSize,
  }) {
    return BillListQuery(
      paymentFilter: paymentFilter ?? this.paymentFilter,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      orderBy: orderBy ?? this.orderBy,
      orderDirection: orderDirection ?? this.orderDirection,
      actorFilter: actorFilter ?? this.actorFilter,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  bool get isDefault => this == BillListQuery.defaults();

  int get activeFilterCount {
    var count = 0;
    if (paymentFilter != BillPaymentFilter.all) {
      count += 1;
    }
    if (selectedTagIds.isNotEmpty) {
      count += 1;
    }
    if (orderBy != ReceiptOrderBy.RECEIPT_ORDER_BY_ID) {
      count += 1;
    }
    if (orderDirection != ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC) {
      count += 1;
    }
    if (actorFilter !=
        ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP) {
      count += 1;
    }
    if (pageSize != BillListState.defaultPageSize) {
      count += 1;
    }
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BillListQuery &&
        other.paymentFilter == paymentFilter &&
        setEquals(other.selectedTagIds, selectedTagIds) &&
        other.orderBy == orderBy &&
        other.orderDirection == orderDirection &&
        other.actorFilter == actorFilter &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    paymentFilter,
    Object.hashAll(selectedTagIds.toList()..sort()),
    orderBy,
    orderDirection,
    actorFilter,
    pageSize,
  );
}

class BillListState extends ChangeNotifier {
  BillListState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  static const defaultPageSize = 20;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  int? _currentUserId;
  bool _isAuthenticated = false;
  bool _hasOpenedBills = false;
  bool _hasLoadedTags = false;
  bool _hasLoadedPage = false;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;
  List<Receipt> _receipts = const [];
  List<TagIndex> _availableTags = const [];
  BillListQuery _appliedQuery = BillListQuery.defaults();
  List<String?> _visitedPageTokens = [null];
  int _currentPageIndex = 0;
  String? _nextPageToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  List<Receipt> get receipts => _receipts;
  List<TagIndex> get availableTags => _availableTags;
  BillListQuery get appliedQuery => _appliedQuery;
  BillPaymentFilter get paymentFilter => _appliedQuery.paymentFilter;
  Set<int> get selectedTagIds => _appliedQuery.selectedTagIds;
  ReceiptOrderBy get orderBy => _appliedQuery.orderBy;
  ReceiptOrderDirection get orderDirection => _appliedQuery.orderDirection;
  ReceiptActorFilter get actorFilter => _appliedQuery.actorFilter;
  int get pageSize => _appliedQuery.pageSize;
  int get currentPage => _currentPageIndex + 1;
  bool get hasPreviousPage => _currentPageIndex > 0;
  bool get hasNextPage => _nextPageToken != null;
  int? get currentUserId => _currentUserId;

  void updateAuthSession(AuthSessionState authSessionState) {
    final previousAuthenticated = _isAuthenticated;
    final previousUserId = _currentUserId;
    final nextAccessToken = authSessionState.accessToken;
    final nextUserId = authSessionState.userId;
    final nextAuthenticated =
        authSessionState.isAuthenticated && nextAccessToken != null;

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

    final becameUnauthenticated = previousAuthenticated && !nextAuthenticated;
    final switchedPrincipal =
        previousUserId != null &&
        nextUserId != null &&
        previousUserId != nextUserId;

    if (!_isAuthenticated) {
      _clearLoadedData();
      _resetQueryState();
      return;
    }

    if (becameUnauthenticated || switchedPrincipal) {
      _resetQueryState();
    }

    if (_hasOpenedBills) {
      _markDataStale();
      Future<void>.microtask(_loadPage);
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
    await _loadPage();
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

  Future<void> applyQuery(BillListQuery query) async {
    if (_appliedQuery == query) {
      return;
    }
    _appliedQuery = query;
    _resetQueryStatePagination();
    await _loadPage();
  }

  Future<void> resetFilters() async {
    final filtersAlreadyDefault =
        _appliedQuery.isDefault && _currentPageIndex == 0;
    if (filtersAlreadyDefault) {
      return;
    }
    _resetQueryState();
    await _loadPage();
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

  double amountPaidForCurrentUser(Receipt receipt) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return 0;
    }

    if (receipt.ownerId.toInt() == currentUserId) {
      if (receipt.hasSplit()) {
        return receipt.split.ownerAmountPaid;
      }
      return receipt.hasAmountPaid() ? receipt.amountPaid : 0;
    }

    if (!receipt.hasSplit()) {
      return 0;
    }

    for (final share in receipt.split.recipientShares) {
      if (share.userId.toInt() == currentUserId) {
        return share.amountPaid;
      }
    }

    return 0;
  }

  double remainingForCurrentUser(Receipt receipt) {
    return (myShareFor(receipt) - amountPaidForCurrentUser(receipt))
        .clamp(0, double.infinity)
        .toDouble();
  }

  Future<bool> setReceiptPayments({
    required Receipt receipt,
    required double ownerAmountPaid,
    required Map<int, double> recipientAmountsPaid,
  }) async {
    if (!_isAuthenticated || _accessToken == null || _isMutating) {
      return false;
    }

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = SetReceiptPaymentsRequest(receiptId: receipt.id);
      request.payments.add(ReceiptPaymentInput(amountPaid: ownerAmountPaid));
      for (final entry in recipientAmountsPaid.entries) {
        request.payments.add(
          ReceiptPaymentInput(
            userId: Int64(entry.key),
            amountPaid: entry.value,
          ),
        );
      }

      final response = await _debtBackendService.setReceiptPayments(
        _accessToken!,
        request,
      );
      if (!response.success) {
        throw StateError(response.message);
      }

      _replaceReceipt(response.receipt);
      await refresh();
      return true;
    } catch (error) {
      _errorMessage = _formatError(error);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<ReceiptFileDownload?> downloadReceiptFile(ReceiptFile file) async {
    if (!_isAuthenticated || _accessToken == null) {
      return null;
    }

    try {
      return await _debtBackendService.downloadReceiptFile(_accessToken!, file);
    } catch (error) {
      _errorMessage = _formatError(error);
      notifyListeners();
      return null;
    }
  }

  void _resetQueryState() {
    _appliedQuery = BillListQuery.defaults();
    _resetQueryStatePagination();
  }

  void _resetQueryStatePagination() {
    _visitedPageTokens = [null];
    _currentPageIndex = 0;
    _nextPageToken = null;
  }

  void _markDataStale() {
    _hasLoadedTags = false;
    _hasLoadedPage = false;
    _errorMessage = null;
  }

  void _clearLoadedData() {
    _markDataStale();
    _receipts = const [];
    _availableTags = const [];
  }

  void _replaceReceipt(Receipt receipt) {
    _receipts = List<Receipt>.unmodifiable(
      _receipts.map(
        (existing) => existing.id == receipt.id ? receipt.deepCopy() : existing,
      ),
    );
  }

  Future<void> _loadPage() async {
    if (!_isAuthenticated || _accessToken == null) {
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
        limit: _appliedQuery.pageSize,
        orderBy: _appliedQuery.orderBy,
        orderDirection: _appliedQuery.orderDirection,
        actorFilter: _appliedQuery.actorFilter,
      );

      final paymentValue = _appliedQuery.paymentFilter.apiValue;
      if (paymentValue != null) {
        request.isPaid = paymentValue;
      }
      if (_appliedQuery.selectedTagIds.isNotEmpty) {
        request.tagIds.addAll(
          _appliedQuery.selectedTagIds.map((tagId) => Int64(tagId)),
        );
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

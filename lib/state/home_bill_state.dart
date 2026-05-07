import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';

import 'package:flutter/foundation.dart';

class HomeBillState extends ChangeNotifier {
  HomeBillState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  bool _isAuthenticated = false;
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<Receipt> _receipts = const [];
  double _unpaidShareTotal = 0;
  int _unpaidBillCount = 0;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Receipt> get receipts => _receipts;
  double get unpaidShareTotal => _unpaidShareTotal;
  int get unpaidBillCount => _unpaidBillCount;

  void updateAuthSession(AuthSessionState authSessionState) {
    final nextAccessToken = authSessionState.accessToken;
    final nextAuthenticated =
        authSessionState.isAuthenticated && nextAccessToken != null;
    final changed =
        _isAuthenticated != nextAuthenticated ||
        _accessToken != nextAccessToken;
    if (!changed) {
      return;
    }
    _isAuthenticated = nextAuthenticated;
    _accessToken = nextAccessToken;
    _hasLoaded = false;
    _errorMessage = null;
    if (!_isAuthenticated) {
      _receipts = const [];
      _unpaidShareTotal = 0;
      _unpaidBillCount = 0;
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (!_isAuthenticated || _accessToken == null || _isLoading || _hasLoaded) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (!_isAuthenticated || _accessToken == null || _isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _debtBackendService.listReceipts(
        _accessToken!,
        ReceiptListRequest(
          isPaid: false,
          limit: 3,
          orderBy: ReceiptOrderBy.RECEIPT_ORDER_BY_ID,
          orderDirection: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC,
          actorFilter:
              ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
        ),
      );
      final summaryResponse = await _debtBackendService.getUnpaidReceiptSummary(
        _accessToken!,
      );
      if (!response.success) {
        throw StateError(response.message);
      }
      if (!summaryResponse.success) {
        throw StateError(summaryResponse.message);
      }
      _receipts = List<Receipt>.unmodifiable(
        response.receipts.take(3).map((receipt) => receipt.deepCopy()),
      );
      _unpaidShareTotal = summaryResponse.unpaidShareTotal;
      _unpaidBillCount = summaryResponse.unpaidBillCount;
      _hasLoaded = true;
    } catch (error) {
      _receipts = const [];
      _unpaidShareTotal = 0;
      _unpaidBillCount = 0;
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

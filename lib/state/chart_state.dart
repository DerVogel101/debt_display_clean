import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

enum ReceiptChartDatePreset {
  allTime,
  last30Days,
  last90Days,
  thisYear,
  custom,
}

class ChartDateRange {
  const ChartDateRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

class ChartState extends ChangeNotifier {
  ChartState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  static const defaultTagLimit = 5;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  bool _isAuthenticated = false;
  bool _hasOpenedCharts = false;
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;
  ReceiptChartSummaryResponse? _summary;
  ReceiptChartDatePreset _datePreset = ReceiptChartDatePreset.allTime;
  DateTime? _customFrom;
  DateTime? _customTo;
  Set<int> _selectedTagIds = const <int>{};
  bool _usesDefaultTags = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReceiptChartSummaryResponse? get summary => _summary;
  ReceiptChartDatePreset get datePreset => _datePreset;
  DateTime? get customFrom => _customFrom;
  DateTime? get customTo => _customTo;
  Set<int> get selectedTagIds => _selectedTagIds;
  List<TagIndex> get availableTags => _summary?.availableTags ?? const [];
  List<ReceiptChartTagBucket> get tagBuckets =>
      _summary?.tagBuckets ?? const [];
  ReceiptChartStatusTotals get totals =>
      _summary?.totals ?? ReceiptChartStatusTotals();

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
      _summary = null;
      _selectedTagIds = const <int>{};
      _usesDefaultTags = true;
      notifyListeners();
      return;
    }

    notifyListeners();
    if (_hasOpenedCharts) {
      Future<void>.microtask(refresh);
    }
  }

  Future<void> ensureLoaded() async {
    _hasOpenedCharts = true;
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
      final response = await _debtBackendService.getReceiptChartSummary(
        _accessToken!,
        _buildRequest(),
      );
      if (!response.success) {
        throw StateError(response.message);
      }
      _summary = response;
      if (_usesDefaultTags) {
        _selectedTagIds = Set<int>.unmodifiable(
          response.defaultTagIds.map((id) => id.toInt()),
        );
      }
      _hasLoaded = true;
    } catch (error) {
      _summary = null;
      _errorMessage = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDatePreset(ReceiptChartDatePreset preset) async {
    if (_datePreset == preset) {
      return;
    }
    _datePreset = preset;
    if (preset != ReceiptChartDatePreset.custom) {
      _customFrom = null;
      _customTo = null;
    }
    _usesDefaultTags = true;
    _selectedTagIds = const <int>{};
    _hasLoaded = false;
    notifyListeners();
    await refresh();
  }

  Future<void> setCustomDateRange({DateTime? from, DateTime? to}) async {
    _datePreset = ReceiptChartDatePreset.custom;
    _customFrom = from;
    _customTo = to;
    _usesDefaultTags = true;
    _selectedTagIds = const <int>{};
    _hasLoaded = false;
    notifyListeners();
    await refresh();
  }

  Future<void> toggleTag(int tagId) async {
    final next = Set<int>.of(_selectedTagIds);
    if (next.contains(tagId)) {
      if (next.length == 1) {
        return;
      }
      next.remove(tagId);
    } else {
      next.add(tagId);
    }

    if (next.isEmpty) {
      return;
    }

    _selectedTagIds = Set<int>.unmodifiable(next);
    _usesDefaultTags = false;
    _hasLoaded = false;
    notifyListeners();
    await refresh();
  }

  ReceiptChartSummaryRequest _buildRequest() {
    final range = _dateRangeForPreset();
    final request = ReceiptChartSummaryRequest(tagLimit: defaultTagLimit);
    if (range.from != null) {
      request.createdAtFrom = _toUtcIso(range.from!);
    }
    if (range.to != null) {
      request.createdAtTo = _toUtcIso(range.to!);
    }
    if (!_usesDefaultTags) {
      request.tagIds.addAll(_selectedTagIds.map(Int64.new));
    }
    return request;
  }

  ChartDateRange _dateRangeForPreset() {
    final now = DateTime.now();
    return switch (_datePreset) {
      ReceiptChartDatePreset.allTime => const ChartDateRange(),
      ReceiptChartDatePreset.last30Days => ChartDateRange(
        from: now.subtract(const Duration(days: 30)),
        to: now,
      ),
      ReceiptChartDatePreset.last90Days => ChartDateRange(
        from: now.subtract(const Duration(days: 90)),
        to: now,
      ),
      ReceiptChartDatePreset.thisYear => ChartDateRange(
        from: DateTime(now.year),
        to: DateTime(now.year + 1),
      ),
      ReceiptChartDatePreset.custom => ChartDateRange(
        from: _customFrom,
        to: _customTo == null
            ? null
            : DateTime(_customTo!.year, _customTo!.month, _customTo!.day + 1),
      ),
    };
  }

  String _toUtcIso(DateTime value) {
    return value.toUtc().toIso8601String();
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

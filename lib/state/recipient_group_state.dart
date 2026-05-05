import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class RecipientGroupState extends ChangeNotifier {
  RecipientGroupState({required DebtBackendService debtBackendService})
    : _debtBackendService = debtBackendService;

  static const minSearchQueryLength = 3;
  static const defaultSearchLimit = 10;

  final DebtBackendService _debtBackendService;

  String? _accessToken;
  int? _currentUserId;
  bool _isAuthenticated = false;
  bool _hasOpenedGroups = false;
  bool _hasLoadedGroups = false;
  bool _isLoadingGroups = false;
  bool _isMutating = false;
  bool _isSearchingUsers = false;
  String? _errorMessage;
  String? _searchErrorMessage;
  List<Recipient> _groups = const [];
  List<User> _searchResults = const [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoadingGroups => _isLoadingGroups;
  bool get isMutating => _isMutating;
  bool get isSearchingUsers => _isSearchingUsers;
  String? get errorMessage => _errorMessage;
  String? get searchErrorMessage => _searchErrorMessage;
  List<Recipient> get groups => _groups;
  List<User> get searchResults => _searchResults;
  int? get currentUserId => _currentUserId;

  void updateAuthSession(AuthSessionState authSessionState) {
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

    final switchedPrincipal =
        previousUserId != null &&
        nextUserId != null &&
        previousUserId != nextUserId;

    if (!_isAuthenticated || switchedPrincipal) {
      _clearLoadedData();
      notifyListeners();
      return;
    }

    if (_hasOpenedGroups) {
      _markGroupsStale();
      Future<void>.microtask(loadGroups);
    }
  }

  Future<void> ensureLoaded() async {
    _hasOpenedGroups = true;
    if (!_isAuthenticated) {
      return;
    }
    if (_isLoadingGroups || _hasLoadedGroups) {
      return;
    }
    await loadGroups();
  }

  Future<void> loadGroups() async {
    if (!_isAuthenticated || _accessToken == null) {
      _groups = const [];
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (_isLoadingGroups) {
      return;
    }

    _isLoadingGroups = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _debtBackendService.listRecipients(_accessToken!);
      if (!response.success) {
        throw StateError(response.message);
      }
      _groups = List<Recipient>.unmodifiable(
        response.recipients.map((recipient) => recipient.deepCopy()),
      );
      _hasLoadedGroups = true;
    } catch (error) {
      _errorMessage = _formatError(error);
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _markGroupsStale();
    await loadGroups();
  }

  Future<void> searchUsers(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < minSearchQueryLength) {
      _searchResults = const [];
      _searchErrorMessage = null;
      _isSearchingUsers = false;
      notifyListeners();
      return;
    }
    if (!_isAuthenticated || _accessToken == null) {
      return;
    }

    _isSearchingUsers = true;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      final response = await _debtBackendService.searchUsers(
        _accessToken!,
        UserSearchRequest(query: trimmedQuery, limit: defaultSearchLimit),
      );
      if (!response.success) {
        throw StateError(response.message);
      }
      final currentUserId = _currentUserId;
      _searchResults = List<User>.unmodifiable(
        response.users
            .where((user) => user.id.toInt() != currentUserId)
            .map((user) => user.deepCopy()),
      );
    } catch (error) {
      _searchResults = const [];
      _searchErrorMessage = _formatError(error);
    } finally {
      _isSearchingUsers = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    if (_searchResults.isEmpty && _searchErrorMessage == null) {
      return;
    }
    _searchResults = const [];
    _searchErrorMessage = null;
    notifyListeners();
  }

  Future<bool> saveGroup({
    Recipient? existingGroup,
    required String name,
    required String description,
    required Iterable<int> memberIds,
  }) async {
    final accessToken = _accessToken;
    if (!_isAuthenticated || accessToken == null) {
      return false;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _errorMessage = 'Recipient group name is required';
      notifyListeners();
      return false;
    }

    final cleanDescription = description.trim();
    final desiredMemberIds = _memberIdsWithoutCurrentUser(memberIds);

    return _runMutation(() async {
      if (existingGroup == null) {
        final request = CreateRecipientRequest(name: cleanName);
        request.description = cleanDescription;
        request.memberIds.addAll(desiredMemberIds.map((id) => Int64(id)));

        final response = await _debtBackendService.createRecipient(
          accessToken,
          request,
        );
        if (!response.success) {
          throw StateError(response.message);
        }
      } else {
        final request = UpdateRecipientRequest(
          recipientId: existingGroup.id,
          name: cleanName,
        );
        request.description = cleanDescription;

        final response = await _debtBackendService.updateRecipient(
          accessToken,
          request,
        );
        if (!response.success) {
          throw StateError(response.message);
        }
        await _syncMembers(
          accessToken: accessToken,
          recipientId: existingGroup.id,
          currentMemberIds: existingGroup.members.map(
            (user) => user.id.toInt(),
          ),
          desiredMemberIds: desiredMemberIds,
        );
      }

      _markGroupsStale();
      await loadGroups();
    });
  }

  Future<bool> deleteGroup(Recipient group) async {
    final accessToken = _accessToken;
    if (!_isAuthenticated || accessToken == null) {
      return false;
    }

    return _runMutation(() async {
      final response = await _debtBackendService.deleteRecipient(
        accessToken,
        RecipientLookupRequest(recipientId: group.id),
      );
      if (!response.success) {
        throw StateError(response.message);
      }
      _markGroupsStale();
      await loadGroups();
    });
  }

  Future<void> _syncMembers({
    required String accessToken,
    required Int64 recipientId,
    required Iterable<int> currentMemberIds,
    required Set<int> desiredMemberIds,
  }) async {
    final current = _memberIdsWithoutCurrentUser(currentMemberIds);
    final toRemove = current.difference(desiredMemberIds);
    final toAdd = desiredMemberIds.difference(current);

    for (final userId in toRemove) {
      final response = await _debtBackendService.removeRecipientMember(
        accessToken,
        RecipientMemberRequest(recipientId: recipientId, userId: Int64(userId)),
      );
      if (!response.success) {
        throw StateError(response.message);
      }
    }

    for (final userId in toAdd) {
      final response = await _debtBackendService.addRecipientMember(
        accessToken,
        RecipientMemberRequest(recipientId: recipientId, userId: Int64(userId)),
      );
      if (!response.success) {
        throw StateError(response.message);
      }
    }
  }

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    if (_isMutating) {
      return false;
    }

    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await mutation();
      return true;
    } catch (error) {
      _errorMessage = _formatError(error);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Set<int> _memberIdsWithoutCurrentUser(Iterable<int> memberIds) {
    final currentUserId = _currentUserId;
    return memberIds
        .where((userId) => userId > 0 && userId != currentUserId)
        .toSet();
  }

  void _markGroupsStale() {
    _hasLoadedGroups = false;
    _errorMessage = null;
  }

  void _clearLoadedData() {
    _markGroupsStale();
    _groups = const [];
    _searchResults = const [];
    _searchErrorMessage = null;
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

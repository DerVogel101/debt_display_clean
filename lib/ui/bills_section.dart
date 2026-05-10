import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/l10n/generated/app_localizations.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/services/file_mime_policy.dart';
import 'package:debt_display/services/file_preview.dart';
import 'package:debt_display/services/file_viewer.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showBillDetailModal(
  BuildContext context, {
  required Receipt receipt,
  required BillListState state,
  required bool isDesktop,
}) {
  Widget buildContent() {
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final currentReceipt = state.receipts.firstWhere(
          (candidate) => candidate.id == receipt.id,
          orElse: () => receipt,
        );
        return _BillDetailPanel(receipt: currentReceipt, state: state);
      },
    );
  }

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 820,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: buildContent(),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(18),
        child: buildContent(),
      ),
    ),
  );
}

class BillsSection extends StatefulWidget {
  const BillsSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<BillsSection> createState() => _BillsSectionState();
}

class _BillsSectionState extends State<BillsSection> {
  bool _filtersExpanded = false;
  BillListQuery _draftQuery = BillListQuery.defaults();
  BillListQuery _appliedQuerySnapshot = BillListQuery.defaults();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<BillListState>().ensureLoaded();
    });
  }

  void _syncDraftQuery(BillListState billsState) {
    final appliedQuery = billsState.appliedQuery;
    if (_appliedQuerySnapshot != appliedQuery) {
      _appliedQuerySnapshot = appliedQuery;
      _draftQuery = appliedQuery;
    }
  }

  void _toggleFilters(BillListState billsState) {
    setState(() {
      if (_filtersExpanded) {
        _draftQuery = billsState.appliedQuery;
        _appliedQuerySnapshot = billsState.appliedQuery;
      }
      _filtersExpanded = !_filtersExpanded;
    });
  }

  void _resetDraftQuery() {
    setState(() {
      _draftQuery = BillListQuery.defaults();
    });
  }

  Future<void> _applyDraftQuery(BillListState billsState) async {
    await billsState.applyQuery(_draftQuery);
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated,
    );
    final billsState = context.watch<BillListState>();
    _syncDraftQuery(billsState);

    if (!isAuthenticated) {
      return _LoggedOutBillsSection(isDesktop: widget.isDesktop);
    }

    final spacing = widget.isDesktop ? 18.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillsFilterCard(
          isDesktop: widget.isDesktop,
          state: billsState,
          filtersExpanded: _filtersExpanded,
          draftQuery: _draftQuery,
          hasPendingChanges: _draftQuery != billsState.appliedQuery,
          onToggleFilters: () => _toggleFilters(billsState),
          onDraftChanged: (query) {
            setState(() {
              _draftQuery = query;
            });
          },
          onResetDraft: _resetDraftQuery,
          onApplyDraft: () => _applyDraftQuery(billsState),
        ),
        SizedBox(height: spacing),
        if (billsState.errorMessage != null) ...[
          _BillsErrorCard(message: billsState.errorMessage!),
          SizedBox(height: spacing),
        ],
        _BillsListCard(isDesktop: widget.isDesktop, state: billsState),
      ],
    );
  }
}

class _LoggedOutBillsSection extends StatelessWidget {
  const _LoggedOutBillsSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.destinationBills,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.homeLoggedOutDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const ValueKey('bills-login-button'),
            onPressed: () {
              context.read<AuthSessionState>().login();
            },
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.loginToViewBills),
          ),
        ],
      ),
    );
  }
}

class _BillsFilterCard extends StatelessWidget {
  const _BillsFilterCard({
    required this.isDesktop,
    required this.state,
    required this.filtersExpanded,
    required this.draftQuery,
    required this.hasPendingChanges,
    required this.onToggleFilters,
    required this.onDraftChanged,
    required this.onResetDraft,
    required this.onApplyDraft,
  });

  final bool isDesktop;
  final BillListState state;
  final bool filtersExpanded;
  final BillListQuery draftQuery;
  final bool hasPendingChanges;
  final VoidCallback onToggleFilters;
  final ValueChanged<BillListQuery> onDraftChanged;
  final VoidCallback onResetDraft;
  final Future<void> Function() onApplyDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeFilterCount = state.appliedQuery.activeFilterCount;

    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                l10n.destinationBills,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (state.isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  OutlinedButton.icon(
                    key: const ValueKey('bills-refresh-button'),
                    onPressed: state.isLoading ? null : state.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.refresh),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('bills-filters-toggle-button'),
                    onPressed: state.isLoading ? null : onToggleFilters,
                    icon: Icon(
                      filtersExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(
                      activeFilterCount > 0
                          ? l10n.filtersCount(activeFilterCount)
                          : l10n.filters,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.billsDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          if (filtersExpanded) ...[
            const SizedBox(height: 22),
            _ControlBlock(
              label: l10n.role,
              child: SegmentedButton<ReceiptActorFilter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ReceiptActorFilter
                        .RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
                    label: Text(l10n.both),
                  ),
                  ButtonSegment(
                    value: ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER,
                    label: Text(l10n.owner),
                  ),
                  ButtonSegment(
                    value:
                        ReceiptActorFilter.RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP,
                    label: Text(l10n.participant),
                  ),
                ],
                selected: {draftQuery.actorFilter},
                onSelectionChanged: state.isLoading
                    ? null
                    : (selection) {
                        onDraftChanged(
                          draftQuery.copyWith(actorFilter: selection.first),
                        );
                      },
              ),
            ),
            const SizedBox(height: 18),
            _ControlBlock(
              label: l10n.paymentStatus,
              child: SegmentedButton<BillPaymentFilter>(
                key: const ValueKey('bills-payment-filter-control'),
                showSelectedIcon: false,
                segments: BillPaymentFilter.values
                    .map(
                      (filter) => ButtonSegment<BillPaymentFilter>(
                        value: filter,
                        label: Text(_paymentFilterLabel(filter, l10n)),
                      ),
                    )
                    .toList(),
                selected: {draftQuery.paymentFilter},
                onSelectionChanged: state.isLoading
                    ? null
                    : (selection) {
                        onDraftChanged(
                          draftQuery.copyWith(paymentFilter: selection.first),
                        );
                      },
              ),
            ),
            const SizedBox(height: 18),
            _ControlBlock(
              label: l10n.tags,
              helper: l10n.tagsFilterHelper,
              child: state.availableTags.isEmpty
                  ? Text(
                      l10n.noTagsAvailable,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedForegroundColor(context, alpha: 0.84),
                      ),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: state.availableTags
                          .map(
                            (tag) => FilterChip(
                              selected: draftQuery.selectedTagIds.contains(
                                tag.id.toInt(),
                              ),
                              onSelected: state.isLoading
                                  ? null
                                  : (_) {
                                      final nextTagIds = Set<int>.from(
                                        draftQuery.selectedTagIds,
                                      );
                                      if (!nextTagIds.add(tag.id.toInt())) {
                                        nextTagIds.remove(tag.id.toInt());
                                      }
                                      onDraftChanged(
                                        draftQuery.copyWith(
                                          selectedTagIds: nextTagIds,
                                        ),
                                      );
                                    },
                              avatar: Text(tag.icon),
                              label: Text(tag.text),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 18),
            if (isDesktop)
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  SizedBox(
                    width: 240,
                    child: _SortByControl(
                      query: draftQuery,
                      isLoading: state.isLoading,
                      onChanged: (value) {
                        onDraftChanged(draftQuery.copyWith(orderBy: value));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: _DirectionControl(
                      query: draftQuery,
                      isLoading: state.isLoading,
                      onChanged: (value) {
                        onDraftChanged(
                          draftQuery.copyWith(orderDirection: value),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _PageSizeControl(
                      query: draftQuery,
                      isLoading: state.isLoading,
                      onChanged: (value) {
                        onDraftChanged(draftQuery.copyWith(pageSize: value));
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SortByControl(
                    query: draftQuery,
                    isLoading: state.isLoading,
                    onChanged: (value) {
                      onDraftChanged(draftQuery.copyWith(orderBy: value));
                    },
                  ),
                  const SizedBox(height: 18),
                  _DirectionControl(
                    query: draftQuery,
                    isLoading: state.isLoading,
                    onChanged: (value) {
                      onDraftChanged(
                        draftQuery.copyWith(orderDirection: value),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _PageSizeControl(
                    query: draftQuery,
                    isLoading: state.isLoading,
                    onChanged: (value) {
                      onDraftChanged(draftQuery.copyWith(pageSize: value));
                    },
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('bills-draft-reset-button'),
                  onPressed: state.isLoading ? null : onResetDraft,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.reset),
                ),
                FilledButton.icon(
                  key: const ValueKey('bills-apply-filters-button'),
                  onPressed: state.isLoading || !hasPendingChanges
                      ? null
                      : () {
                          onApplyDraft();
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SortByControl extends StatelessWidget {
  const _SortByControl({
    required this.query,
    required this.isLoading,
    required this.onChanged,
  });

  final BillListQuery query;
  final bool isLoading;
  final ValueChanged<ReceiptOrderBy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ControlBlock(
      label: l10n.sortBy,
      child: SizedBox(
        key: const ValueKey('bills-sort-dropdown'),
        child: DropdownButtonFormField<ReceiptOrderBy>(
          key: ValueKey(query.orderBy),
          initialValue: query.orderBy,
          items: [
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_ID,
              child: Text(l10n.id),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_COST_TOTAL,
              child: Text(l10n.total),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_COST_FOR_USER,
              child: Text(l10n.myShare),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
              child: Text(l10n.stillOwed),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_DUE_DATE,
              child: Text(l10n.dueDate),
            ),
          ],
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
        ),
      ),
    );
  }
}

class _DirectionControl extends StatelessWidget {
  const _DirectionControl({
    required this.query,
    required this.isLoading,
    required this.onChanged,
  });

  final BillListQuery query;
  final bool isLoading;
  final ValueChanged<ReceiptOrderDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ControlBlock(
      label: l10n.direction,
      child: SegmentedButton<ReceiptOrderDirection>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_ASC,
            label: Text(l10n.ascending),
          ),
          ButtonSegment(
            value: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC,
            label: Text(l10n.descending),
          ),
        ],
        selected: {query.orderDirection},
        onSelectionChanged: isLoading
            ? null
            : (selection) {
                onChanged(selection.first);
              },
      ),
    );
  }
}

class _PageSizeControl extends StatelessWidget {
  const _PageSizeControl({
    required this.query,
    required this.isLoading,
    required this.onChanged,
  });

  final BillListQuery query;
  final bool isLoading;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlBlock(
      label: AppLocalizations.of(context).pageSize,
      child: SizedBox(
        key: const ValueKey('bills-page-size-dropdown'),
        child: DropdownButtonFormField<int>(
          key: ValueKey(query.pageSize),
          initialValue: query.pageSize,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
        ),
      ),
    );
  }
}

class _BillsListCard extends StatefulWidget {
  const _BillsListCard({required this.isDesktop, required this.state});

  final bool isDesktop;
  final BillListState state;

  @override
  State<_BillsListCard> createState() => _BillsListCardState();
}

class _BillsListCardState extends State<_BillsListCard> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context);
    return PageSection(
      padding: EdgeInsets.all(widget.isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.visibleReceipts,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pageNumber(state.currentPage),
                    key: const ValueKey('bills-page-indicator'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedForegroundColor(context, alpha: 0.84),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('bills-page-previous-button'),
                    onPressed: state.isLoading || !state.hasPreviousPage
                        ? null
                        : state.goToPreviousPage,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text(l10n.previous),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('bills-page-next-button'),
                    onPressed: state.isLoading || !state.hasNextPage
                        ? null
                        : state.goToNextPage,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: Text(l10n.next),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.isLoading && state.receipts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          else if (state.receipts.isEmpty)
            Text(
              l10n.noBillsMatch,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.88),
              ),
            )
          else
            _buildReceiptList(context, state),
        ],
      ),
    );
  }

  Widget _buildReceiptList(BuildContext context, BillListState state) {
    return Column(
      children: [
        for (var index = 0; index < state.receipts.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == state.receipts.length - 1 ? 0 : 12,
            ),
            child: _BillReceiptTile(
              receipt: state.receipts[index],
              state: state,
              onTap: () => _selectReceipt(context, state.receipts[index]),
            ),
          ),
      ],
    );
  }

  void _selectReceipt(BuildContext context, Receipt receipt) {
    showBillDetailModal(
      context,
      receipt: receipt,
      state: widget.state,
      isDesktop: widget.isDesktop,
    );
  }
}

class _BillReceiptTile extends StatelessWidget {
  const _BillReceiptTile({
    required this.receipt,
    required this.state,
    required this.onTap,
  });

  final Receipt receipt;
  final BillListState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final amountFormat = NumberFormat.currency(
      locale: locale.toString(),
      symbol: receipt.currency == 'EUR' ? '€' : '${receipt.currency} ',
      decimalDigits: 2,
    );
    final dueDate = receipt.hasDueDate()
        ? DateTime.tryParse(receipt.dueDate)
        : null;
    final dueLabel = dueDate == null
        ? l10n.noDueDate
        : l10n.dueDateLabel(
            materialLocalizations.formatShortDate(dueDate.toLocal()),
          );
    final recipientLabel = receipt.hasRecipient()
        ? receipt.recipient.name
        : l10n.personalBill;
    final isOwner =
        state.currentUserId != null &&
        receipt.ownerId.toInt() == state.currentUserId;
    final roleLabel = isOwner ? l10n.owner : l10n.participant;
    final peopleLabel = _receiptPeopleLabel(receipt, l10n);
    final filesLabel = receipt.files.length == 1
        ? l10n.oneFileIncluded
        : l10n.filesIncluded(receipt.files.length);
    final remainingAmount = state.remainingForCurrentUser(receipt);

    return InkWell(
      key: ValueKey('receipt-row-${receipt.id}'),
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: GlassPanel.secondary(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (receipt.hasDescription() &&
                      receipt.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      receipt.description,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedForegroundColor(context, alpha: 0.82),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        label: roleLabel,
                        icon: isOwner
                            ? Icons.badge_rounded
                            : Icons.people_alt_rounded,
                      ),
                      _MetaChip(
                        label: receipt.isPaid ? l10n.paid : l10n.unpaid,
                        icon: receipt.isPaid
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        tone: receipt.isPaid ? Colors.green : Colors.orange,
                      ),
                      _MetaChip(
                        label: recipientLabel,
                        icon: Icons.group_work_rounded,
                        tooltip: peopleLabel,
                      ),
                      if (receipt.files.isNotEmpty)
                        _MetaChip(
                          label: filesLabel,
                          icon: Icons.attach_file_rounded,
                        ),
                    ],
                  ),
                  if (receipt.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: receipt.tags
                          .map((tag) => _TagPill(tag: tag))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    dueLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedForegroundColor(context, alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ReceiptAmountMetric(
                    label: l10n.stillOwed,
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(
                          color: mutedForegroundColor(context, alpha: 0.8),
                          fontWeight: FontWeight.w800,
                        ),
                    value: amountFormat.format(remainingAmount),
                    valueStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _ReceiptAmountMetric(
                    label: l10n.total,
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(
                          color: mutedForegroundColor(context, alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                    value: amountFormat.format(receipt.amountOwed),
                    valueStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: mutedForegroundColor(context, alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _ReceiptAmountMetric extends StatelessWidget {
  const _ReceiptAmountMetric({
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final TextStyle? labelStyle;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: labelStyle,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: valueStyle,
        ),
      ],
    );
  }
}

class _BillDetailPanel extends StatelessWidget {
  const _BillDetailPanel({required this.receipt, required this.state});

  final Receipt receipt;
  final BillListState state;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);
    final amountFormat = NumberFormat.currency(
      locale: locale.toString(),
      symbol: receipt.currency == 'EUR' ? '€' : '${receipt.currency} ',
      decimalDigits: 2,
    );
    final isOwner = receipt.ownerId.toInt() == state.currentUserId;
    final amountPaid = state.amountPaidForCurrentUser(receipt);

    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  receipt.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _MetaChip(
                label: isOwner ? l10n.owner : l10n.participant,
                icon: isOwner ? Icons.badge_rounded : Icons.people_alt_rounded,
              ),
            ],
          ),
          if (receipt.hasDescription() &&
              receipt.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              receipt.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.84),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _MetricText(
                label: l10n.total,
                value: amountFormat.format(receipt.amountOwed),
              ),
              _MetricText(
                label: l10n.myShare,
                value: amountFormat.format(state.myShareFor(receipt)),
              ),
              _MetricText(
                label: l10n.paid,
                value: amountFormat.format(amountPaid),
              ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: ValueKey('receipt-payments-${receipt.id}'),
              onPressed: state.isMutating
                  ? null
                  : () => _showReceiptPaymentsDialog(
                      context,
                      state,
                      receipt,
                      amountFormat,
                    ),
              icon: const Icon(Icons.payments_rounded),
              label: Text(l10n.payments),
            ),
          ],
          if (receipt.hasSplit()) ...[
            const SizedBox(height: 16),
            Text(
              l10n.participants,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _ReceiptSplitShareRow(receipt: receipt, amountFormat: amountFormat),
          ],
          if (receipt.hasNotes() && receipt.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.notes,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              receipt.notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.86),
              ),
            ),
          ],
          if (receipt.files.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.files,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _ReceiptFilesDetail(receipt: receipt, state: state),
          ],
        ],
      ),
    );
  }
}

Future<void> _showReceiptPaymentsDialog(
  BuildContext context,
  BillListState state,
  Receipt receipt,
  NumberFormat amountFormat,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ReceiptPaymentsDialog(
      state: state,
      receipt: receipt,
      amountFormat: amountFormat,
    ),
  );
}

class _ReceiptPaymentsDialog extends StatefulWidget {
  const _ReceiptPaymentsDialog({
    required this.state,
    required this.receipt,
    required this.amountFormat,
  });

  final BillListState state;
  final Receipt receipt;
  final NumberFormat amountFormat;

  @override
  State<_ReceiptPaymentsDialog> createState() => _ReceiptPaymentsDialogState();
}

class _ReceiptPaymentsDialogState extends State<_ReceiptPaymentsDialog> {
  late final TextEditingController _ownerController;
  late final Map<int, TextEditingController> _recipientControllers;
  String? _errorText;
  bool _didApplyLocaleFormat = false;

  @override
  void initState() {
    super.initState();
    _ownerController = TextEditingController(
      text: _initialOwnerPaidAmount().toStringAsFixed(2),
    );
    _recipientControllers = {
      for (final share
          in widget.receipt.hasSplit()
              ? widget.receipt.split.recipientShares
              : <ReceiptRecipientShare>[])
        share.userId.toInt(): TextEditingController(
          text: share.amountPaid.toStringAsFixed(2),
        ),
    };
  }

  @override
  void dispose() {
    _ownerController.dispose();
    for (final controller in _recipientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyLocaleFormat) {
      return;
    }
    _ownerController.text = _formatEditableAmount(_initialOwnerPaidAmount());
    final split = widget.receipt.hasSplit() ? widget.receipt.split : null;
    if (split != null) {
      for (final share in split.recipientShares) {
        _recipientControllers[share.userId.toInt()]?.text =
            _formatEditableAmount(share.amountPaid);
      }
    }
    _didApplyLocaleFormat = true;
  }

  double _initialOwnerPaidAmount() {
    if (widget.receipt.hasSplit()) {
      return widget.receipt.split.ownerAmountPaid;
    }
    return widget.receipt.hasAmountPaid() ? widget.receipt.amountPaid : 0.0;
  }

  double _ownerShareAmount() {
    if (widget.receipt.hasSplit()) {
      return widget.receipt.split.ownerAmount;
    }
    return widget.receipt.amountOwed;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final ownerAmountPaid = _parseAmount(_ownerController.text);
    if (ownerAmountPaid == null) {
      setState(() {
        _errorText = l10n.paymentInvalidOwner;
      });
      return;
    }
    if (ownerAmountPaid < 0 || ownerAmountPaid - _ownerShareAmount() > 1e-6) {
      setState(() {
        _errorText = l10n.paymentOwnerExceeded;
      });
      return;
    }

    final recipientAmountsPaid = <int, double>{};
    final split = widget.receipt.hasSplit() ? widget.receipt.split : null;
    for (final entry in _recipientControllers.entries) {
      final amount = _parseAmount(entry.value.text);
      if (amount == null) {
        setState(() {
          _errorText = l10n.paymentInvalidRecipient;
        });
        return;
      }
      final share = split?.recipientShares.where(
        (share) => share.userId.toInt() == entry.key,
      );
      final shareAmount = share == null || share.isEmpty
          ? 0
          : share.first.amount;
      if (amount < 0 || amount - shareAmount > 1e-6) {
        setState(() {
          _errorText = l10n.paymentRecipientExceeded;
        });
        return;
      }
      recipientAmountsPaid[entry.key] = amount;
    }

    final saved = await widget.state.setReceiptPayments(
      receipt: widget.receipt,
      ownerAmountPaid: ownerAmountPaid,
      recipientAmountsPaid: recipientAmountsPaid,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _errorText = widget.state.errorMessage ?? l10n.couldNotSavePayments;
    });
  }

  double? _parseAmount(String raw) {
    final locale = Localizations.localeOf(context);
    var normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return null;
    }
    final separator = NumberFormat.decimalPattern(
      locale.toString(),
    ).symbols.DECIMAL_SEP;
    if (separator == ',') {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
    return double.tryParse(normalized);
  }

  String _formatEditableAmount(double amount) {
    final locale = Localizations.localeOf(context);
    final separator = NumberFormat.decimalPattern(
      locale.toString(),
    ).symbols.DECIMAL_SEP;
    return amount.toStringAsFixed(2).replaceAll('.', separator);
  }

  @override
  Widget build(BuildContext context) {
    final split = widget.receipt.hasSplit() ? widget.receipt.split : null;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.payments),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('receipt-payment-owner-field'),
                controller: _ownerController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.ownerPaid,
                  helperText: l10n.shareAmount(
                    widget.amountFormat.format(_ownerShareAmount()),
                  ),
                ),
              ),
              if (split != null)
                for (final share in split.recipientShares) ...[
                  const SizedBox(height: 14),
                  TextField(
                    key: ValueKey(
                      'receipt-payment-user-${share.userId.toInt()}-field',
                    ),
                    controller: _recipientControllers[share.userId.toInt()]!,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.userPaid(_shareUserLabel(share, l10n)),
                      helperText: l10n.shareAmount(
                        widget.amountFormat.format(share.amount),
                      ),
                    ),
                  ),
                ],
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.state.isMutating
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          key: const ValueKey('receipt-payment-save-button'),
          onPressed: widget.state.isMutating ? null : _save,
          icon: const Icon(Icons.check_rounded),
          label: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ReceiptSplitShareRow extends StatelessWidget {
  const _ReceiptSplitShareRow({
    required this.receipt,
    required this.amountFormat,
  });

  final Receipt receipt;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final split = receipt.split;
    final rows = [
      (
        participant: l10n.owner,
        percent: split.ownerSharePercent,
        shareAmount: split.ownerAmount,
        paidAmount: split.ownerAmountPaid,
      ),
      for (final share in split.recipientShares)
        (
          participant: _shareUserLabel(share, l10n),
          percent: share.sharePercent,
          shareAmount: share.amount,
          paidAmount: share.amountPaid,
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 560),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FixedColumnWidth(74),
            2: FixedColumnWidth(112),
            3: FixedColumnWidth(112),
            4: FixedColumnWidth(112),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          children: [
            _shareTableRow(
              context,
              cells: [
                l10n.participantHeader,
                '%',
                l10n.shareHeader,
                l10n.paidHeader,
                l10n.leftHeader,
              ],
              isHeader: true,
            ),
            for (final row in rows)
              _shareTableRow(
                context,
                cells: [
                  row.participant,
                  '${row.percent.toStringAsFixed(0)}%',
                  amountFormat.format(row.shareAmount),
                  amountFormat.format(row.paidAmount),
                  amountFormat.format(
                    (row.shareAmount - row.paidAmount).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TableRow _shareTableRow(
    BuildContext context, {
    required List<String> cells,
    bool isHeader = false,
  }) {
    final style = isHeader
        ? Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: mutedForegroundColor(context, alpha: 0.78),
          )
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return TableRow(
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            child: Text(
              cell,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}

class _ReceiptFilesDetail extends StatelessWidget {
  const _ReceiptFilesDetail({required this.receipt, required this.state});

  final Receipt receipt;
  final BillListState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: receipt.files
          .map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceiptFileDetailTile(
                file: file,
                state: state,
                showPreview: true,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReceiptFileDetailTile extends StatelessWidget {
  const _ReceiptFileDetailTile({
    required this.file,
    required this.state,
    required this.showPreview,
  });

  final ReceiptFile file;
  final BillListState state;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contentType = file.hasContentType()
        ? normalizeFileContentType(file.contentType)
        : null;
    return DecoratedBox(
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        includeShadows: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_fileIcon(contentType), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.originalFilename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: ValueKey('receipt-file-open-${file.id.toInt()}'),
                  onPressed: () => _openReceiptFile(context, state, file),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.open),
                ),
              ],
            ),
            if (showPreview && _canPreviewInline(contentType)) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: isPdfContentType(contentType) ? 280 : 190,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: _ReceiptFilePreview(file: file, state: state),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptFilePreview extends StatefulWidget {
  const _ReceiptFilePreview({required this.file, required this.state});

  final ReceiptFile file;
  final BillListState state;

  @override
  State<_ReceiptFilePreview> createState() => _ReceiptFilePreviewState();
}

class _ReceiptFilePreviewState extends State<_ReceiptFilePreview> {
  late Future<ReceiptFileDownload?> _downloadFuture;

  @override
  void initState() {
    super.initState();
    _downloadFuture = widget.state.downloadReceiptFile(widget.file);
  }

  @override
  void didUpdateWidget(covariant _ReceiptFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.file.id != widget.file.id) {
      _downloadFuture = widget.state.downloadReceiptFile(widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReceiptFileDownload?>(
      future: _downloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final download = snapshot.data;
        if (download == null) {
          return Center(
            child: Text(AppLocalizations.of(context).previewUnavailable),
          );
        }
        if (isRasterImageContentType(download.contentType)) {
          return Image.memory(download.bytes, fit: BoxFit.contain);
        }
        if (isPdfContentType(download.contentType)) {
          return BlobFilePreview(
            bytes: download.bytes,
            contentType: normalizeFileContentType(download.contentType),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

Future<void> _openReceiptFile(
  BuildContext context,
  BillListState state,
  ReceiptFile file,
) async {
  try {
    final pendingWindow = openPendingFileWindow();
    final download = await state.downloadReceiptFile(file);
    if (download == null) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
      }
      return;
    }
    await pendingWindow.showBytes(
      bytes: download.bytes,
      contentType: normalizeFileContentType(download.contentType),
      filename: download.file.originalFilename,
    );
  } catch (_) {
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenFile)));
    }
  }
}

String _shareUserLabel(ReceiptRecipientShare share, AppLocalizations l10n) {
  if (share.hasUser()) {
    return _recipientMemberLabel(share.user, l10n);
  }
  return '${l10n.user} ${share.userId}';
}

String _receiptPeopleLabel(Receipt receipt, AppLocalizations l10n) {
  if (receipt.hasRecipient() && receipt.recipient.members.isNotEmpty) {
    return receipt.recipient.members
        .map((member) => _recipientMemberLabel(member, l10n))
        .join(', ');
  }
  if (receipt.hasSplit() && receipt.split.recipientShares.isNotEmpty) {
    return receipt.split.recipientShares
        .map((share) => _shareUserLabel(share, l10n))
        .join(', ');
  }
  if (receipt.hasRecipient() && receipt.recipient.name.trim().isNotEmpty) {
    return receipt.recipient.name;
  }
  return l10n.personalBill;
}

String _recipientMemberLabel(User user, AppLocalizations l10n) {
  if (user.deleted) {
    return l10n.deletedUser;
  }
  if (user.hasName() && user.name.trim().isNotEmpty) {
    return user.name;
  }
  if (user.hasEmail() && user.email.trim().isNotEmpty) {
    return user.email;
  }
  return '${l10n.user} ${user.id}';
}

bool _canPreviewInline(String? contentType) {
  return isInlinePreviewContentType(contentType);
}

class _ControlBlock extends StatelessWidget {
  const _ControlBlock({required this.label, required this.child, this.helper});

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.82),
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BillsErrorCard extends StatelessWidget {
  const _BillsErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      tone: scheme.error,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).couldNotLoadBills(message),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _paymentFilterLabel(BillPaymentFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    BillPaymentFilter.all => l10n.all,
    BillPaymentFilter.unpaid => l10n.unpaid,
    BillPaymentFilter.paid => l10n.paid,
  };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    this.tone,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final Color? tone;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        tone: tone ?? brandPrimary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tone ?? brandPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    final message = tooltip?.trim();
    if (message == null || message.isEmpty || message == label) {
      return chip;
    }
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: chip,
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: mutedForegroundColor(context, alpha: 0.8),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final TagIndex tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        tone: _parseTagColor(tag.color),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.icon),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Color _parseTagColor(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (normalized.length == 6) {
    final parsed = int.tryParse('FF$normalized', radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  if (normalized.length == 8) {
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  return brandPrimary;
}

IconData _fileIcon(String? contentType) {
  if (isPdfContentType(contentType)) {
    return Icons.picture_as_pdf_rounded;
  }
  if (isRasterImageContentType(contentType)) {
    return Icons.image_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

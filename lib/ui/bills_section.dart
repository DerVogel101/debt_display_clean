import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bills',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'Log in to load the bills you own or share with other participants.',
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
            label: const Text('Log in to view bills'),
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
                'Bills',
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
                    label: const Text('Refresh'),
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
                          ? 'Filters ($activeFilterCount)'
                          : 'Filters',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Browse every receipt you can access as owner, participant, or both.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          if (filtersExpanded) ...[
            const SizedBox(height: 22),
            _ControlBlock(
              label: 'Role',
              child: SegmentedButton<ReceiptActorFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ReceiptActorFilter
                        .RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
                    label: Text('Both'),
                  ),
                  ButtonSegment(
                    value: ReceiptActorFilter.RECEIPT_ACTOR_FILTER_OWNER,
                    label: Text('Owner'),
                  ),
                  ButtonSegment(
                    value:
                        ReceiptActorFilter.RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP,
                    label: Text('Participant'),
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
              label: 'Payment status',
              child: SegmentedButton<BillPaymentFilter>(
                showSelectedIcon: false,
                segments: BillPaymentFilter.values
                    .map(
                      (filter) => ButtonSegment<BillPaymentFilter>(
                        value: filter,
                        label: Text(filter.label),
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
              label: 'Tags',
              helper: 'Each selected tag must be present on a receipt.',
              child: state.availableTags.isEmpty
                  ? Text(
                      'No tags available yet.',
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
                      onDraftChanged(draftQuery.copyWith(orderDirection: value));
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
                  label: const Text('Reset'),
                ),
                FilledButton.icon(
                  key: const ValueKey('bills-apply-filters-button'),
                  onPressed: state.isLoading || !hasPendingChanges
                      ? null
                      : () {
                          onApplyDraft();
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Apply'),
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
    return _ControlBlock(
      label: 'Sort by',
      child: SizedBox(
        key: const ValueKey('bills-sort-dropdown'),
        child: DropdownButtonFormField<ReceiptOrderBy>(
          key: ValueKey(query.orderBy),
          initialValue: query.orderBy,
          items: const [
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_ID,
              child: Text('ID'),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_COST_TOTAL,
              child: Text('Total'),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_COST_FOR_USER,
              child: Text('My share'),
            ),
            DropdownMenuItem(
              value: ReceiptOrderBy.RECEIPT_ORDER_BY_DUE_DATE,
              child: Text('Due date'),
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
    return _ControlBlock(
      label: 'Direction',
      child: SegmentedButton<ReceiptOrderDirection>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_ASC,
            label: Text('Ascending'),
          ),
          ButtonSegment(
            value: ReceiptOrderDirection.RECEIPT_ORDER_DIRECTION_DESC,
            label: Text('Descending'),
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
      label: 'Page size',
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

class _BillsListCard extends StatelessWidget {
  const _BillsListCard({required this.isDesktop, required this.state});

  final bool isDesktop;
  final BillListState state;

  @override
  Widget build(BuildContext context) {
    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
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
                    'Visible receipts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${state.currentPage}',
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
                    label: const Text('Previous'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('bills-page-next-button'),
                    onPressed: state.isLoading || !state.hasNextPage
                        ? null
                        : state.goToNextPage,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
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
              'No bills match the current filters.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.88),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < state.receipts.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == state.receipts.length - 1 ? 0 : 12,
                    ),
                    child: _BillReceiptTile(
                      receipt: state.receipts[index],
                      state: state,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BillReceiptTile extends StatelessWidget {
  const _BillReceiptTile({required this.receipt, required this.state});

  final Receipt receipt;
  final BillListState state;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
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
        ? 'No due date'
        : 'Due ${materialLocalizations.formatShortDate(dueDate.toLocal())}';
    final recipientLabel = receipt.hasRecipientName()
        ? receipt.recipientName
        : (receipt.hasRecipient() ? receipt.recipient.name : 'Personal bill');
    final myShare = state.myShareFor(receipt);
    final roleLabel = state.roleLabelFor(receipt);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          label: roleLabel,
                          icon: roleLabel == 'Owner'
                              ? Icons.badge_rounded
                              : Icons.people_alt_rounded,
                        ),
                        _MetaChip(
                          label: receipt.isPaid ? 'Paid' : 'Unpaid',
                          icon: receipt.isPaid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          tone: receipt.isPaid ? Colors.green : Colors.orange,
                        ),
                        _MetaChip(
                          label: recipientLabel,
                          icon: Icons.group_work_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                amountFormat.format(receipt.amountOwed),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _MetricText(
                label: 'My share',
                value: amountFormat.format(myShare),
              ),
              _MetricText(label: 'Due', value: dueLabel),
            ],
          ),
          if (receipt.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: receipt.tags.map((tag) => _TagPill(tag: tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }
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
              'Could not load bills. $message',
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon, this.tone});

  final String label;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
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

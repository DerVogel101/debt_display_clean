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

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated,
    );
    final billsState = context.watch<BillListState>();

    if (!isAuthenticated) {
      return _LoggedOutBillsSection(isDesktop: widget.isDesktop);
    }

    final spacing = widget.isDesktop ? 18.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillsFilterCard(isDesktop: widget.isDesktop, state: billsState),
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
  const _BillsFilterCard({required this.isDesktop, required this.state});

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
                  OutlinedButton.icon(
                    key: const ValueKey('bills-reset-button'),
                    onPressed: state.isLoading ? null : state.resetFilters,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset filters'),
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
              selected: {state.actorFilter},
              onSelectionChanged: state.isLoading
                  ? null
                  : (selection) {
                      state.setActorFilter(selection.first);
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
              selected: {state.paymentFilter},
              onSelectionChanged: state.isLoading
                  ? null
                  : (selection) {
                      state.setPaymentFilter(selection.first);
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
                            selected: state.selectedTagIds.contains(
                              tag.id.toInt(),
                            ),
                            onSelected: state.isLoading
                                ? null
                                : (_) {
                                    state.toggleTag(tag.id.toInt());
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
                SizedBox(width: 240, child: _SortByControl(state: state)),
                SizedBox(width: 240, child: _DirectionControl(state: state)),
                SizedBox(width: 180, child: _PageSizeControl(state: state)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SortByControl(state: state),
                const SizedBox(height: 18),
                _DirectionControl(state: state),
                const SizedBox(height: 18),
                _PageSizeControl(state: state),
              ],
            ),
        ],
      ),
    );
  }
}

class _SortByControl extends StatelessWidget {
  const _SortByControl({required this.state});

  final BillListState state;

  @override
  Widget build(BuildContext context) {
    return _ControlBlock(
      label: 'Sort by',
      child: DropdownButtonFormField<ReceiptOrderBy>(
        key: const ValueKey('bills-sort-dropdown'),
        initialValue: state.orderBy,
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
        onChanged: state.isLoading
            ? null
            : (value) {
                if (value != null) {
                  state.setOrderBy(value);
                }
              },
      ),
    );
  }
}

class _DirectionControl extends StatelessWidget {
  const _DirectionControl({required this.state});

  final BillListState state;

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
        selected: {state.orderDirection},
        onSelectionChanged: state.isLoading
            ? null
            : (selection) {
                state.setOrderDirection(selection.first);
              },
      ),
    );
  }
}

class _PageSizeControl extends StatelessWidget {
  const _PageSizeControl({required this.state});

  final BillListState state;

  @override
  Widget build(BuildContext context) {
    return _ControlBlock(
      label: 'Page size',
      child: DropdownButtonFormField<int>(
        key: const ValueKey('bills-page-size-dropdown'),
        initialValue: state.pageSize,
        items: const [
          DropdownMenuItem(value: 10, child: Text('10')),
          DropdownMenuItem(value: 20, child: Text('20')),
          DropdownMenuItem(value: 50, child: Text('50')),
        ],
        onChanged: state.isLoading
            ? null
            : (value) {
                if (value != null) {
                  state.setPageSize(value);
                }
              },
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
    return Color(int.parse('FF$normalized', radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  return brandPrimary;
}

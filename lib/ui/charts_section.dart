import 'dart:math' as math;

import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/l10n/generated/app_localizations.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/chart_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChartsSection extends StatefulWidget {
  const ChartsSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ChartState>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated,
    );
    if (!isAuthenticated) {
      return _LoggedOutChartsSection(isDesktop: widget.isDesktop);
    }

    final state = context.watch<ChartState>();
    final l10n = AppLocalizations.of(context);
    final spacing = widget.isDesktop ? 18.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageSection(
          padding: EdgeInsets.all(widget.isDesktop ? 28 : 22),
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
                    l10n.destinationCharts,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('charts-refresh-button'),
                    onPressed: state.isLoading ? null : state.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.chartsDescription,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _ChartDateControls(state: state),
            ],
          ),
        ),
        SizedBox(height: spacing),
        if (state.errorMessage != null) ...[
          ErrorSection(message: l10n.couldNotLoadCharts(state.errorMessage!)),
          SizedBox(height: spacing),
        ],
        if (state.isLoading && state.summary == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else ...[
          _ChartTagSelector(state: state),
          SizedBox(height: spacing),
          if (widget.isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PieChartPanel(state: state)),
                const SizedBox(width: 18),
                Expanded(child: _BarChartPanel(state: state)),
              ],
            )
          else ...[
            _PieChartPanel(state: state),
            SizedBox(height: spacing),
            _BarChartPanel(state: state),
          ],
        ],
      ],
    );
  }
}

class _LoggedOutChartsSection extends StatelessWidget {
  const _LoggedOutChartsSection({required this.isDesktop});

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
            l10n.destinationCharts,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.chartsDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const ValueKey('charts-login-button'),
            onPressed: context.read<AuthSessionState>().login,
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.loginToViewCharts),
          ),
        ],
      ),
    );
  }
}

class _ChartDateControls extends StatelessWidget {
  const _ChartDateControls({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.chartDateRange,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          key: const ValueKey('charts-date-preset-control'),
          spacing: 8,
          runSpacing: 8,
          children: ReceiptChartDatePreset.values.map((preset) {
            return ChoiceChip(
              key: ValueKey('charts-date-preset-${preset.name}'),
              selected: state.datePreset == preset,
              label: Text(_datePresetLabel(preset, l10n)),
              onSelected: state.isLoading
                  ? null
                  : (_) {
                      state.setDatePreset(preset);
                    },
            );
          }).toList(),
        ),
        if (state.datePreset == ReceiptChartDatePreset.custom) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final maxWidth = constraints.maxWidth;
              final buttonWidth = maxWidth < 360
                  ? maxWidth
                  : (maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _DateRangeButton(
                      key: const ValueKey('charts-from-date-button'),
                      label: l10n.chartFromDate,
                      value: state.customFrom,
                      onPicked: (value) {
                        state.setCustomDateRange(
                          from: value,
                          to: state.customTo,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _DateRangeButton(
                      key: const ValueKey('charts-to-date-button'),
                      label: l10n.chartToDate,
                      value: state.customTo,
                      onPicked: (value) {
                        state.setCustomDateRange(
                          from: state.customFrom,
                          to: value,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final dateLabel = value == null
        ? l10n.chartPickDate
        : materialLocalizations.formatShortDate(value!);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: DateTime(now.year + 5),
          );
          if (context.mounted && picked != null) {
            onPicked(picked);
          }
        },
        child: DecoratedBox(
          decoration: glassSurfaceDecoration(
            context,
            variant: AppGlassVariant.secondary,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            tone: value == null ? null : scheme.primary,
            includeShadows: false,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: value == null
                      ? scheme.onSurfaceVariant
                      : scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label: $dateLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartTagSelector extends StatelessWidget {
  const _ChartTagSelector({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageSection(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= 768 ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chartSelectTags,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (state.availableTags.isEmpty)
            Text(
              l10n.chartNoTags,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedForegroundColor(context, alpha: 0.82),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.availableTags.map((tag) {
                final tagId = tag.id.toInt();
                return FilterChip(
                  key: ValueKey('charts-tag-chip-$tagId'),
                  selected: state.selectedTagIds.contains(tagId),
                  avatar: Text(tag.icon),
                  label: Text(tag.text),
                  onSelected: state.isLoading
                      ? null
                      : (_) => state.toggleTag(tagId),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PieChartPanel extends StatelessWidget {
  const _PieChartPanel({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _chartColors(context);
    final slices = _statusSlices(state.totals, colors, l10n);
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    final amountFormat = _amountFormat(context);

    return PageSection(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= 768 ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chartDebtBreakdown,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          if (total <= 1e-6)
            _EmptyChartMessage(message: l10n.chartNoData)
          else ...[
            SizedBox(
              key: const ValueKey('charts-pie-chart'),
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: slices
                      .where((slice) => slice.value > 1e-6)
                      .map(
                        (slice) => PieChartSectionData(
                          value: slice.value,
                          color: slice.color,
                          radius: 72,
                          title: '${(slice.value / total * 100).round()}%',
                          titleStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...slices.map(
              (slice) => _ChartLegendRow(
                color: slice.color,
                label: slice.label,
                value: amountFormat.format(slice.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _chartColors(context);
    final buckets = state.tagBuckets;
    final amountFormat = _amountFormat(context);
    final maxValue = buckets.fold<double>(
      0,
      (maxSoFar, bucket) => math.max(maxSoFar, _bucketTotal(bucket)),
    );

    return PageSection(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= 768 ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chartTagBreakdown,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          if (buckets.isEmpty || maxValue <= 1e-6)
            _EmptyChartMessage(message: l10n.chartNoData)
          else ...[
            SizedBox(
              key: const ValueKey('charts-bar-chart'),
              height: 280,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxValue * 1.15,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < buckets.length; index++)
                      _barGroup(index, buckets[index], colors),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...buckets.asMap().entries.map(
              (entry) => _TagBucketSummary(
                index: entry.key + 1,
                bucket: entry.value,
                amountFormat: amountFormat,
              ),
            ),
            const SizedBox(height: 10),
            _ChartLegendRow(
              color: colors.paid,
              label: l10n.chartPaidShare,
              value: '',
            ),
            _ChartLegendRow(
              color: colors.open,
              label: l10n.chartOpenShare,
              value: '',
            ),
            _ChartLegendRow(
              color: colors.overdue,
              label: l10n.chartOverdueOpenShare,
              value: '',
            ),
          ],
        ],
      ),
    );
  }
}

class _TagBucketSummary extends StatelessWidget {
  const _TagBucketSummary({
    required this.index,
    required this.bucket,
    required this.amountFormat,
  });

  final int index;
  final ReceiptChartTagBucket bucket;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _severityColor(context, bucket);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: color.withValues(alpha: 0.16),
            foregroundColor: color,
            child: Text(
              '$index',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bucket.tag.icon} ${bucket.tag.text}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${amountFormat.format(_bucketTotal(bucket))} · ${l10n.chartReceiptsCount(bucket.receiptCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: mutedForegroundColor(context, alpha: 0.84),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

typedef _StatusSlice = ({String label, double value, Color color});
typedef _ChartColors = ({Color paid, Color open, Color overdue});

List<_StatusSlice> _statusSlices(
  ReceiptChartStatusTotals totals,
  _ChartColors colors,
  AppLocalizations l10n,
) {
  return [
    (label: l10n.chartPaidShare, value: totals.paidShare, color: colors.paid),
    (label: l10n.chartOpenShare, value: totals.openShare, color: colors.open),
    (
      label: l10n.chartOverdueOpenShare,
      value: totals.overdueOpenShare,
      color: colors.overdue,
    ),
  ];
}

BarChartGroupData _barGroup(
  int index,
  ReceiptChartTagBucket bucket,
  _ChartColors colors,
) {
  final paidTo = bucket.paidShare;
  final openTo = paidTo + bucket.openShare;
  final overdueTo = openTo + bucket.overdueOpenShare;
  return BarChartGroupData(
    x: index,
    barRods: [
      BarChartRodData(
        toY: overdueTo,
        width: 28,
        borderRadius: BorderRadius.circular(7),
        color: colors.open.withValues(alpha: 0.18),
        rodStackItems: [
          BarChartRodStackItem(0, paidTo, colors.paid),
          BarChartRodStackItem(paidTo, openTo, colors.open),
          BarChartRodStackItem(openTo, overdueTo, colors.overdue),
        ],
      ),
    ],
  );
}

_ChartColors _chartColors(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return (paid: scheme.primary, open: scheme.tertiary, overdue: scheme.error);
}

Color _severityColor(BuildContext context, ReceiptChartTagBucket bucket) {
  final colors = _chartColors(context);
  if (bucket.overdueOpenShare > 1e-6) {
    return colors.overdue;
  }
  if (bucket.openShare > 1e-6) {
    return colors.open;
  }
  return colors.paid;
}

double _bucketTotal(ReceiptChartTagBucket bucket) {
  return bucket.paidShare + bucket.openShare + bucket.overdueOpenShare;
}

NumberFormat _amountFormat(BuildContext context) {
  return NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    symbol: '€',
    decimalDigits: 2,
  );
}

String _datePresetLabel(ReceiptChartDatePreset preset, AppLocalizations l10n) {
  return switch (preset) {
    ReceiptChartDatePreset.allTime => l10n.chartAllTime,
    ReceiptChartDatePreset.last30Days => l10n.chartLast30Days,
    ReceiptChartDatePreset.last90Days => l10n.chartLast90Days,
    ReceiptChartDatePreset.thisYear => l10n.chartThisYear,
    ReceiptChartDatePreset.custom => l10n.chartCustom,
  };
}

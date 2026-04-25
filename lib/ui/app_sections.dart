import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/theme_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppSections extends StatefulWidget {
  const AppSections({
    super.key,
    required this.isDesktop,
    required this.mobileBottomInset,
    this.mobileHeader,
  });

  final bool isDesktop;
  final double mobileBottomInset;
  final Widget? mobileHeader;

  @override
  State<AppSections> createState() => _AppSectionsState();
}

class _AppSectionsState extends State<AppSections> {
  static const _topFadeHeight = 28.0;

  late final ScrollController _scrollController;
  bool _showTopFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.isDesktop) {
      if (_showTopFade) {
        setState(() => _showTopFade = false);
      }
      return;
    }

    final nextValue =
        _scrollController.hasClients && _scrollController.offset > 2;
    if (nextValue != _showTopFade) {
      setState(() => _showTopFade = nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = widget.isDesktop ? 1180.0 : 640.0;
    final scrollView = SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        widget.isDesktop ? 32 : 16,
        widget.isDesktop ? 28 : 16,
        widget.isDesktop ? 32 : 16,
        widget.isDesktop ? 32 : widget.mobileBottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isDesktop && widget.mobileHeader != null) ...[
            widget.mobileHeader!,
            const SizedBox(height: 10),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildContent(context),
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: [
            scrollView,
            if (!widget.isDesktop && _showTopFade)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: const SizedBox(height: _topFadeHeight),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isLoading = context.select<AuthSessionState, bool>(
      (state) => state.isLoading,
    );
    final selectedDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );

    if (isLoading) {
      return LoadingSection(
        key: const ValueKey('loading'),
        isDesktop: widget.isDesktop,
      );
    }

    switch (selectedDestination) {
      case AppDestination.home:
        return HomeSection(
          key: const ValueKey('home'),
          isDesktop: widget.isDesktop,
        );
      case AppDestination.profile:
        return const ProfileSection(key: ValueKey('profile'));
      case AppDestination.menu:
        return const MenuSection(key: ValueKey('menu'));
    }
  }
}

class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.isDesktop,
    this.referenceDate,
  });

  final bool isDesktop;
  final DateTime? referenceDate;

  static const List<_PlaceholderBillSeed> _placeholderBillSeeds = [
    _PlaceholderBillSeed(
      title: 'Studio rent top-up',
      dueInDays: 7,
      amount: 427.00,
      tags: [
        _PlaceholderTag(icon: '🏠', text: 'Home', color: '#FFB74D'),
        _PlaceholderTag(icon: '⚠️', text: 'Due soon', color: '#E57373'),
        _PlaceholderTag(icon: '👥', text: 'Shared household', color: '#81C784'),
        _PlaceholderTag(icon: '📆', text: 'Monthly cycle', color: '#64B5F6'),
        _PlaceholderTag(icon: '📌', text: 'Fixed cost', color: '#BA68C8'),
      ],
    ),
    _PlaceholderBillSeed(
      title: 'Quarterly electricity bill',
      dueInDays: 5,
      amount: 248.40,
      tags: [
        _PlaceholderTag(icon: '⚡', text: 'Utilities', color: '#FFD54F'),
        _PlaceholderTag(icon: '🧾', text: 'Invoice', color: '#90A4AE'),
      ],
    ),
    _PlaceholderBillSeed(
      title: 'Spring grocery split',
      dueInDays: 4,
      amount: 413.78,
      tags: [
        _PlaceholderTag(icon: '🛒', text: 'Groceries', color: '#81C784'),
        _PlaceholderTag(icon: '👥', text: 'Shared', color: '#4DB6AC'),
      ],
    ),
    _PlaceholderBillSeed(
      title: 'Weekend train tickets',
      dueInDays: 2,
      amount: 176.30,
      tags: [
        _PlaceholderTag(icon: '🚆', text: 'Travel', color: '#64B5F6'),
        _PlaceholderTag(icon: '🤝', text: 'Split', color: '#A1887F'),
      ],
    ),
    _PlaceholderBillSeed(
      title: 'Internet renewal',
      dueInDays: 1,
      amount: 92.15,
      tags: [
        _PlaceholderTag(icon: '🌐', text: 'Internet', color: '#4FC3F7'),
        _PlaceholderTag(icon: '🔁', text: 'Renewal', color: '#9575CD'),
      ],
    ),
  ];

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static List<_PlaceholderBill> _buildPlaceholderBills(DateTime referenceDate) {
    final baseDate = _dateOnly(referenceDate);

    return _placeholderBillSeeds
        .map(
          (seed) => _PlaceholderBill(
            title: seed.title,
            dueDate: baseDate.add(Duration(days: seed.dueInDays)),
            amount: seed.amount,
            tags: seed.tags,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final backendError = context.select<AuthSessionState, String?>(
      (state) => state.backendError,
    );
    final locale = Localizations.localeOf(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final placeholderBills = _buildPlaceholderBills(referenceDate ?? DateTime.now());
    final currencyFormat = NumberFormat.currency(
      locale: locale.toString(),
      symbol: '€',
      decimalDigits: 2,
    );
    final totalStillOwed = placeholderBills.fold<double>(
      0,
      (sum, bill) => sum + bill.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageSection(
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
                    'Recent outstanding bills',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('open-bill-list-button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Bill list placeholder coming soon.'),
                          ),
                        );
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Open bill list'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Static placeholder data for the upcoming home dashboard.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ...placeholderBills.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == placeholderBills.length - 1 ? 0 : 12,
                  ),
                  child: _PlaceholderBillTile(
                    title: entry.value.title,
                    dueLabel:
                        'Due ${materialLocalizations.formatShortDate(entry.value.dueDate)}',
                    amountLabel: currencyFormat.format(entry.value.amount),
                    tags: entry.value.tags,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (backendError != null) ...[
          ErrorSection(message: backendError),
          const SizedBox(height: 18),
        ],
        PageSection(
          padding: EdgeInsets.all(isDesktop ? 28 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total still owed',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Combined balance across the same five placeholder bills.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              GlassPanel.secondary(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 24 : 20),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                tone: brandPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(totalStillOwed),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${placeholderBills.length} unpaid placeholder bills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: mutedForegroundColor(context, alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authView = context
        .select<
          AuthSessionState,
          ({
            Credentials? credentials,
            String? backendError,
            String? displayName,
          })
        >(
          (state) => (
            credentials: state.credentials,
            backendError: state.backendError,
            displayName: state.displayName,
          ),
        );

    return Column(
      children: [
        PageSection(
          padding: const EdgeInsets.all(24),
          child: authView.credentials == null
              ? const _LoggedOutProfileCard()
              : _LoggedInProfileCard(
                  credentials: authView.credentials!,
                  displayName: authView.displayName ?? 'User',
                ),
        ),
        if (authView.backendError != null) ...[
          const SizedBox(height: 18),
          ErrorSection(message: authView.backendError!),
        ],
      ],
    );
  }
}

class MenuSection extends StatelessWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authView = context
        .select<
          AuthSessionState,
          ({Credentials? credentials, String? backendError})
        >(
          (state) => (
            credentials: state.credentials,
            backendError: state.backendError,
          ),
        );
    final items = [
      (
        title: 'Home',
        body:
            'Return to the placeholder dashboard and outstanding bill overview.',
        icon: Icons.home_rounded,
        destination: AppDestination.home,
      ),
      (
        title: 'Profile',
        body: authView.credentials == null
            ? 'Open your account details to sign in and inspect your user data.'
            : 'Review the synced account profile and active session details.',
        icon: Icons.person_rounded,
        destination: AppDestination.profile,
      ),
    ];

    return Column(
      children: [
        PageSection(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Use this overflow area for profile access and appearance settings, especially on mobile where the bottom bar stays compact.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MenuActionTile(
                    title: item.title,
                    body: item.body,
                    icon: item.icon,
                    onTap: () {
                      context.read<NavigationState>().selectDestination(
                        item.destination,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _ThemeSettingsCard(),
            ],
          ),
        ),
        if (authView.backendError != null) ...[
          const SizedBox(height: 18),
          ErrorSection(message: authView.backendError!),
        ],
      ],
    );
  }
}

class _PlaceholderBillTile extends StatelessWidget {
  const _PlaceholderBillTile({
    required this.title,
    required this.dueLabel,
    required this.amountLabel,
    required this.tags,
  });

  final String title;
  final String dueLabel;
  final String amountLabel;
  final List<_PlaceholderTag> tags;

  @override
  Widget build(BuildContext context) {
    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: glassSurfaceDecoration(
              context,
              variant: AppGlassVariant.secondary,
              tone: brandPrimary,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              includeShadows: false,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: brandPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 10),
                _PlaceholderTagRow(tags: tags),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderBillSeed {
  const _PlaceholderBillSeed({
    required this.title,
    required this.dueInDays,
    required this.amount,
    required this.tags,
  });

  final String title;
  final int dueInDays;
  final double amount;
  final List<_PlaceholderTag> tags;
}

class _PlaceholderBill {
  const _PlaceholderBill({
    required this.title,
    required this.dueDate,
    required this.amount,
    required this.tags,
  });

  final String title;
  final DateTime dueDate;
  final double amount;
  final List<_PlaceholderTag> tags;
}

class _PlaceholderTag {
  const _PlaceholderTag({
    required this.icon,
    required this.text,
    required this.color,
  });

  final String icon;
  final String text;
  final String color;
}

class _PlaceholderTagRow extends StatelessWidget {
  const _PlaceholderTagRow({required this.tags});

  static const _chipSpacing = 8.0;
  static const _chipHorizontalPadding = 10.0;
  static const _iconSpacing = 6.0;

  final List<_PlaceholderTag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        final labelStyle = Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
        final iconStyle = Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 15);

        final visibleTags = <_PlaceholderTag>[];
        final tagWidths = tags
            .map((tag) => _measureTagWidth(context, tag, labelStyle, iconStyle))
            .toList();

        var usedWidth = 0.0;
        for (var index = 0; index < tags.length; index++) {
          final hiddenAfterCurrent = tags.length - (index + 1);
          final tagWidth =
              (visibleTags.isEmpty ? 0 : _chipSpacing) + tagWidths[index];
          final overflowWidth = hiddenAfterCurrent > 0
              ? _chipSpacing +
                    _measureOverflowWidth(
                      context,
                      hiddenAfterCurrent,
                      labelStyle,
                    )
              : 0.0;

          if (usedWidth + tagWidth + overflowWidth > constraints.maxWidth) {
            break;
          }

          visibleTags.add(tags[index]);
          usedWidth += tagWidth;
        }

        final hiddenCount = tags.length - visibleTags.length;
        final children = <Widget>[
          for (final tag in visibleTags) _PlaceholderTagChip(tag: tag),
          if (hiddenCount > 0)
            _PlaceholderTagOverflowChip(hiddenCount: hiddenCount),
        ];

        return Wrap(
          spacing: _chipSpacing,
          runSpacing: _chipSpacing,
          children: children,
        );
      },
    );
  }

  static double _measureTagWidth(
    BuildContext context,
    _PlaceholderTag tag,
    TextStyle? labelStyle,
    TextStyle? iconStyle,
  ) {
    final iconWidth = _measureTextWidth(context, tag.icon, iconStyle);
    final textWidth = _measureTextWidth(context, tag.text, labelStyle);

    return (_chipHorizontalPadding * 2) + iconWidth + _iconSpacing + textWidth;
  }

  static double _measureOverflowWidth(
    BuildContext context,
    int hiddenCount,
    TextStyle? labelStyle,
  ) {
    final textWidth = _measureTextWidth(context, '+$hiddenCount', labelStyle);
    return (_chipHorizontalPadding * 2) + textWidth;
  }

  static double _measureTextWidth(
    BuildContext context,
    String text,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return painter.width;
  }
}

class _PlaceholderTagChip extends StatelessWidget {
  const _PlaceholderTagChip({required this.tag});

  final _PlaceholderTag tag;

  @override
  Widget build(BuildContext context) {
    final tone = _parseTagColor(tag.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        tone: tone,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.icon,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
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

class _PlaceholderTagOverflowChip extends StatelessWidget {
  const _PlaceholderTagOverflowChip({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Text(
        '+$hiddenCount',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: mutedForegroundColor(context, alpha: 0.9),
        ),
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

class _LoggedOutProfileCard extends StatelessWidget {
  const _LoggedOutProfileCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to load your Auth0 identity, sync it with the backend, and expose the account controls in this section.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: mutedForegroundColor(context, alpha: 0.88),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            context.read<AuthSessionState>().login();
          },
          icon: const Icon(Icons.login_rounded),
          label: const Text('Log in to continue'),
        ),
      ],
    );
  }
}

class _LoggedInProfileCard extends StatelessWidget {
  const _LoggedInProfileCard({
    required this.credentials,
    required this.displayName,
  });

  final Credentials credentials;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (credentials.user.pictureUrl != null) ...[
          UserAvatar(
            credentials: credentials,
            radius: 42,
            displayName: displayName,
          ),
          const SizedBox(height: 18),
        ],
        Text(
          displayName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          credentials.user.email ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: mutedForegroundColor(context)),
        ),
        const SizedBox(height: 24),
        _ProfileInfoTable(credentials: credentials, displayName: displayName),
        const SizedBox(height: 24),
        Text(
          'Raw user object',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GlassPanel.secondary(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              credentials.user.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: () {
            context.read<AuthSessionState>().logout();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class _ProfileInfoTable extends StatelessWidget {
  const _ProfileInfoTable({
    required this.credentials,
    required this.displayName,
  });

  final Credentials credentials;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Email', credentials.user.email ?? 'N/A'),
      ('Display name', displayName),
      ('Nickname', credentials.user.nickname ?? 'N/A'),
      ('User ID', credentials.user.sub),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel.secondary(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: mutedForegroundColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      row.$2,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: glassSurfaceDecoration(
          context,
          variant: AppGlassVariant.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: glassSurfaceDecoration(
                context,
                variant: AppGlassVariant.secondary,
                tone: brandPrimary,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                includeShadows: false,
              ),
              child: Icon(icon, color: brandPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedForegroundColor(context, alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _ThemeSettingsCard extends StatelessWidget {
  const _ThemeSettingsCard();

  @override
  Widget build(BuildContext context) {
    final themeView = context
        .select<
          ThemeState,
          ({
            AppThemeMode mode,
            DarkThemePalette palette,
            bool showDarkPalettePicker,
          })
        >(
          (state) => (
            mode: state.themeMode,
            palette: state.darkPalette,
            showDarkPalettePicker: state.showDarkPalettePicker,
          ),
        );

    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a light, auto, or dark theme mode. Dark mode uses your saved palette, with Dracula as the default fallback.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<AppThemeMode>(
            showSelectedIcon: false,
            segments: AppThemeMode.values
                .map(
                  (mode) => ButtonSegment<AppThemeMode>(
                    value: mode,
                    label: Text(mode.label),
                  ),
                )
                .toList(),
            selected: {themeView.mode},
            onSelectionChanged: (selection) {
              context.read<ThemeState>().setThemeMode(selection.first);
            },
          ),
          if (themeView.showDarkPalettePicker) ...[
            const SizedBox(height: 18),
            Text(
              'Dark palette',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: DarkThemePalette.values
                  .map(
                    (palette) => ChoiceChip(
                      label: Text(palette.label),
                      selected: themeView.palette == palette,
                      onSelected: (_) {
                        context.read<ThemeState>().setDarkPalette(palette);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

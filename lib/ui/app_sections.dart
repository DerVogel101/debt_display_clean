import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/state/home_bill_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/recipient_group_state.dart';
import 'package:debt_display/state/theme_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/bill_creation_section.dart';
import 'package:debt_display/ui/bills_section.dart';
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
      case AppDestination.bills:
        return BillsSection(
          key: const ValueKey('bills'),
          isDesktop: widget.isDesktop,
        );
      case AppDestination.createBill:
        return BillCreationSection(
          key: const ValueKey('create-bill'),
          isDesktop: widget.isDesktop,
        );
      case AppDestination.recipientGroups:
        return const RecipientGroupsSection(key: ValueKey('recipient-groups'));
      case AppDestination.profile:
        return const ProfileSection(key: ValueKey('profile'));
      case AppDestination.menu:
        return const MenuSection(key: ValueKey('menu'));
    }
  }
}

class HomeSection extends StatefulWidget {
  const HomeSection({super.key, required this.isDesktop, this.referenceDate});

  final bool isDesktop;
  final DateTime? referenceDate;

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<HomeBillState>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated,
    );
    final backendError = context.select<AuthSessionState, String?>(
      (state) => state.backendError,
    );
    final homeState = context.watch<HomeBillState>();
    final locale = Localizations.localeOf(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: locale.toString(),
      symbol: '€',
      decimalDigits: 2,
    );
    final billListState = context.watch<BillListState>();
    final totalStillOwed = homeState.unpaidShareTotal;

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
                    'Recent outstanding bills',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('open-bill-list-button'),
                        onPressed: () {
                          context.read<NavigationState>().selectDestination(
                            AppDestination.bills,
                          );
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: Text(widget.isDesktop ? 'View Bills' : 'View'),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('open-bill-create-button'),
                        onPressed: () {
                          context.read<NavigationState>().selectDestination(
                            AppDestination.createBill,
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          widget.isDesktop ? 'Create Bill' : 'Create',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isAuthenticated
                    ? 'The newest unpaid bills you own or take part in.'
                    : 'Log in to load the bills you own or share with other participants.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              if (!isAuthenticated)
                FilledButton.icon(
                  key: const ValueKey('home-login-button'),
                  onPressed: context.read<AuthSessionState>().login,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Log in to view bills'),
                )
              else if (homeState.isLoading && homeState.receipts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              else if (homeState.receipts.isEmpty)
                Text(
                  'No unpaid bills right now.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.88),
                  ),
                )
              else
                ...homeState.receipts.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == homeState.receipts.length - 1
                          ? 0
                          : 12,
                    ),
                    child: _HomeBillTile(
                      receipt: entry.value,
                      roleLabel: billListState.roleLabelFor(entry.value),
                      amountLabel: _homeAmountLabel(
                        entry.value,
                        locale,
                        currencyFormat,
                      ),
                      dueLabel: _homeDueLabel(
                        entry.value,
                        materialLocalizations,
                      ),
                      onTap: () => showBillDetailModal(
                        context,
                        receipt: entry.value,
                        state: billListState,
                        isDesktop: widget.isDesktop,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (backendError != null || homeState.errorMessage != null) ...[
          ErrorSection(message: backendError ?? homeState.errorMessage!),
          const SizedBox(height: 18),
        ],
        PageSection(
          padding: EdgeInsets.all(widget.isDesktop ? 28 : 22),
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
                'Combined balance across all unpaid bills you take part in.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.88),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              GlassPanel.secondary(
                width: double.infinity,
                padding: EdgeInsets.all(widget.isDesktop ? 24 : 20),
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
                      '${homeState.unpaidBillCount} unpaid bills need your share',
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

class RecipientGroupsSection extends StatelessWidget {
  const RecipientGroupsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [_RecipientGroupsCard()]);
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
        body: 'Return to the unpaid bill dashboard and overview.',
        icon: Icons.home_rounded,
        destination: AppDestination.home,
      ),
      (
        title: 'Bills',
        body:
            'Open the full bills view with filters, sorting, and pagination controls.',
        icon: Icons.receipt_long_rounded,
        destination: AppDestination.bills,
      ),
      (
        title: 'Create Bill',
        body:
            'Create a bill with tags, splits, notes, and uploaded receipt files.',
        icon: Icons.add_circle_rounded,
        destination: AppDestination.createBill,
      ),
      (
        title: 'Recipient groups',
        body:
            'Create shared recipient groups and manage who can receive split bills.',
        icon: Icons.groups_rounded,
        destination: AppDestination.recipientGroups,
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

String _homeAmountLabel(
  Receipt receipt,
  Locale locale,
  NumberFormat fallbackFormat,
) {
  if (receipt.currency == 'EUR') {
    return fallbackFormat.format(receipt.amountOwed);
  }
  return NumberFormat.currency(
    locale: locale.toString(),
    symbol: '${receipt.currency} ',
    decimalDigits: 2,
  ).format(receipt.amountOwed);
}

String _homeDueLabel(
  Receipt receipt,
  MaterialLocalizations materialLocalizations,
) {
  if (!receipt.hasDueDate()) {
    return 'No due date';
  }
  final dueDate = DateTime.tryParse(receipt.dueDate);
  if (dueDate == null) {
    return 'No due date';
  }
  return 'Due ${materialLocalizations.formatShortDate(dueDate.toLocal())}';
}

String _homeRecipientLabel(Receipt receipt) {
  if (receipt.hasRecipientName() && receipt.recipientName.trim().isNotEmpty) {
    return receipt.recipientName;
  }
  if (receipt.hasRecipient() && receipt.recipient.name.trim().isNotEmpty) {
    return receipt.recipient.name;
  }
  return 'Personal bill';
}

String _homeParticipantsLabel(Receipt receipt) {
  if (receipt.hasRecipient() && receipt.recipient.members.isNotEmpty) {
    return receipt.recipient.members.map(_homeUserLabel).join(', ');
  }
  if (receipt.hasSplit() && receipt.split.recipientShares.isNotEmpty) {
    return receipt.split.recipientShares.map(_homeShareUserLabel).join(', ');
  }
  return _homeRecipientLabel(receipt);
}

String _homeUserLabel(User user) {
  if (user.hasName() && user.name.trim().isNotEmpty) {
    return user.name;
  }
  if (user.hasEmail() && user.email.trim().isNotEmpty) {
    return user.email;
  }
  return 'User ${user.id}';
}

String _homeShareUserLabel(ReceiptRecipientShare share) {
  if (share.hasUserName() && share.userName.trim().isNotEmpty) {
    return share.userName;
  }
  if (share.hasUserEmail() && share.userEmail.trim().isNotEmpty) {
    return share.userEmail;
  }
  return 'User ${share.userId}';
}

class _HomeBillTile extends StatelessWidget {
  const _HomeBillTile({
    required this.receipt,
    required this.roleLabel,
    required this.dueLabel,
    required this.amountLabel,
    required this.onTap,
  });

  final Receipt receipt;
  final String roleLabel;
  final String dueLabel;
  final String amountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final groupLabel = _homeRecipientLabel(receipt);
    final participantsLabel = _homeParticipantsLabel(receipt);
    final filesLabel = receipt.files.length == 1
        ? '1 file included'
        : '${receipt.files.length} files included';
    final panel = GlassPanel.secondary(
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
                  receipt.title,
                  maxLines: 1,
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
                    _HomeMetaChip(
                      label: roleLabel,
                      icon: roleLabel == 'Owner'
                          ? Icons.badge_rounded
                          : Icons.people_alt_rounded,
                    ),
                    _HomeMetaChip(
                      label: receipt.isPaid ? 'Paid' : 'Unpaid',
                      icon: receipt.isPaid
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                    ),
                    _HomeMetaChip(
                      label: groupLabel,
                      icon: Icons.group_work_rounded,
                      tooltip: participantsLabel,
                    ),
                    if (receipt.files.isNotEmpty)
                      _HomeMetaChip(
                        label: filesLabel,
                        icon: Icons.attach_file_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dueLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.82),
                  ),
                ),
                if (receipt.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _HomeTagRow(tags: receipt.tags),
                ],
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
    return InkWell(
      key: ValueKey('home-receipt-row-${receipt.id}'),
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: panel,
    );
  }
}

class _HomeMetaChip extends StatelessWidget {
  const _HomeMetaChip({required this.label, required this.icon, this.tooltip});

  final String label;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        tone: brandPrimary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: brandPrimary),
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

class _HomeTagRow extends StatelessWidget {
  const _HomeTagRow({required this.tags});

  static const _chipSpacing = 8.0;
  static const _chipHorizontalPadding = 10.0;
  static const _iconSpacing = 6.0;

  final List<TagIndex> tags;

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

        final visibleTags = <TagIndex>[];
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
          for (final tag in visibleTags) _HomeTagChip(tag: tag),
          if (hiddenCount > 0) _HomeTagOverflowChip(hiddenCount: hiddenCount),
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
    TagIndex tag,
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

class _HomeTagChip extends StatelessWidget {
  const _HomeTagChip({required this.tag});

  final TagIndex tag;

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

class _HomeTagOverflowChip extends StatelessWidget {
  const _HomeTagOverflowChip({required this.hiddenCount});

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

class _RecipientGroupsCard extends StatefulWidget {
  const _RecipientGroupsCard();

  @override
  State<_RecipientGroupsCard> createState() => _RecipientGroupsCardState();
}

class _RecipientGroupsCardState extends State<_RecipientGroupsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<RecipientGroupState>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecipientGroupState>();

    return GlassPanel.secondary(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
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
                'Recipient groups',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (state.isAuthenticated)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('recipient-groups-refresh-button'),
                      onPressed: state.isLoadingGroups || state.isMutating
                          ? null
                          : state.refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('recipient-groups-create-button'),
                      onPressed: state.isMutating
                          ? null
                          : () => _showRecipientGroupDialog(context),
                      icon: const Icon(Icons.group_add_rounded),
                      label: const Text('Create'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create shared recipient groups and manage who can receive split bills.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          if (!state.isAuthenticated)
            FilledButton.icon(
              key: const ValueKey('recipient-groups-login-button'),
              onPressed: () {
                context.read<AuthSessionState>().login();
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Log in to manage groups'),
            )
          else ...[
            if (state.isLoadingGroups)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ),
            if (state.errorMessage != null) ...[
              _InlineError(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (!state.isLoadingGroups && state.groups.isEmpty)
              Text(
                'No recipient groups yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.82),
                ),
              )
            else
              ...state.groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecipientGroupTile(group: group),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showRecipientGroupDialog(
  BuildContext context, {
  Recipient? group,
}) {
  final recipientGroupState = context.read<RecipientGroupState>();
  recipientGroupState.clearSearchResults();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        ChangeNotifierProvider<RecipientGroupState>.value(
          value: recipientGroupState,
          child: _RecipientGroupEditorDialog(group: group),
        ),
  );
}

class _RecipientGroupTile extends StatelessWidget {
  const _RecipientGroupTile({required this.group});

  final Recipient group;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecipientGroupState>();
    final isOwner = group.ownerId.toInt() == state.currentUserId;

    return DecoratedBox(
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        includeShadows: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _RoleBadge(label: isOwner ? 'Owner' : 'Member'),
                if (isOwner) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: ValueKey('recipient-group-edit-${group.id}'),
                    tooltip: 'Edit group',
                    onPressed: state.isMutating
                        ? null
                        : () =>
                              _showRecipientGroupDialog(context, group: group),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    key: ValueKey('recipient-group-delete-${group.id}'),
                    tooltip: 'Delete group',
                    onPressed: state.isMutating
                        ? null
                        : () => _confirmDelete(context, group),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
            if (group.hasDescription() &&
                group.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.84),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (group.members.isEmpty)
              Text(
                'No members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedForegroundColor(context, alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members
                    .map((member) => _UserChip(user: member))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Recipient group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recipient group?'),
        content: Text(
          'Delete ${group.name}? Existing receipt snapshots remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('recipient-group-confirm-delete-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<RecipientGroupState>().deleteGroup(group);
    }
  }
}

class _RecipientGroupEditorDialog extends StatefulWidget {
  const _RecipientGroupEditorDialog({this.group});

  final Recipient? group;

  @override
  State<_RecipientGroupEditorDialog> createState() =>
      _RecipientGroupEditorDialogState();
}

class _RecipientGroupEditorDialogState
    extends State<_RecipientGroupEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _searchController;
  late final Map<int, User> _selectedMembers;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _descriptionController = TextEditingController(
      text: group?.hasDescription() == true ? group!.description : '',
    );
    _searchController = TextEditingController();
    _selectedMembers = {
      for (final member in group?.members ?? <User>[])
        member.id.toInt(): member.deepCopy(),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecipientGroupState>();
    final title = widget.group == null
        ? 'Create recipient group'
        : 'Edit recipient group';

    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('recipient-group-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('recipient-group-description-field'),
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Text(
                'Members',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (_selectedMembers.isEmpty)
                Text(
                  'No members selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedForegroundColor(context, alpha: 0.82),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers.values
                      .map(
                        (user) => InputChip(
                          key: ValueKey('recipient-selected-member-${user.id}'),
                          label: Text(_userLabel(user)),
                          deleteIcon: Icon(
                            Icons.close_rounded,
                            key: ValueKey(
                              'recipient-selected-member-remove-${user.id}',
                            ),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedMembers.remove(user.id.toInt());
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('recipient-user-search-field'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Find user',
                  helperText: 'Type at least 3 characters from name or email.',
                  suffixIcon: state.isSearchingUsers
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : null,
                ),
                onChanged: context.read<RecipientGroupState>().searchUsers,
              ),
              if (state.searchErrorMessage != null) ...[
                const SizedBox(height: 10),
                _InlineError(message: state.searchErrorMessage!),
              ],
              if (state.searchResults.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...state.searchResults.map(
                  (user) => _UserSearchResultTile(
                    user: user,
                    isSelected: _selectedMembers.containsKey(user.id.toInt()),
                    onAdd: () {
                      setState(() {
                        _selectedMembers[user.id.toInt()] = user.deepCopy();
                      });
                    },
                  ),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                _InlineError(message: state.errorMessage!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isMutating
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('recipient-group-save-button'),
          onPressed: state.isMutating ? null : () => _save(context),
          child: state.isMutating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final saved = await context.read<RecipientGroupState>().saveGroup(
      existingGroup: widget.group,
      name: _nameController.text,
      description: _descriptionController.text,
      memberIds: _selectedMembers.keys,
    );
    if (saved && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _UserSearchResultTile extends StatelessWidget {
  const _UserSearchResultTile({
    required this.user,
    required this.isSelected,
    required this.onAdd,
  });

  final User user;
  final bool isSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('recipient-user-search-result-${user.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_add_alt_1_rounded),
      title: Text(_userLabel(user)),
      subtitle: Text(_userSubtitle(user)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: brandPrimary)
          : IconButton(
              key: ValueKey('recipient-user-add-${user.id}'),
              tooltip: 'Add member',
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
      onTap: isSelected ? null : onAdd,
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.person_rounded, size: 18),
      label: Text(_userLabel(user)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        includeShadows: false,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

String _userLabel(User user) {
  if (user.hasName() && user.name.trim().isNotEmpty) {
    return user.name;
  }
  if (user.hasEmail() && user.email.trim().isNotEmpty) {
    return user.email;
  }
  return 'User ${user.id}';
}

String _userSubtitle(User user) {
  if (user.hasEmail() && user.email.trim().isNotEmpty) {
    return user.email;
  }
  return 'ID ${user.id}';
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

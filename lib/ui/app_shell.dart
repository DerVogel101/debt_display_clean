import 'dart:ui' show ImageFilter;

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_sections.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

export 'package:debt_display/ui/app_shared.dart';

const desktopBreakpoint = 768.0;
const desktopContentMaxWidth = 1180.0;
const desktopTopBarTopPadding = 5.0;
const mobileBottomNavigationHeight = 72.0;
const mobileBottomNavigationHorizontalPadding = 14.0;
const mobileBottomNavigationTopPadding = 4.0;
const mobileBottomNavigationBottomPadding = 14.0;
const mobileBottomNavigationOuterPadding = EdgeInsets.fromLTRB(
  mobileBottomNavigationHorizontalPadding,
  mobileBottomNavigationTopPadding,
  mobileBottomNavigationHorizontalPadding,
  mobileBottomNavigationBottomPadding,
);
const mobileBottomNavigationReservedHeight =
    mobileBottomNavigationHeight +
    mobileBottomNavigationTopPadding +
    mobileBottomNavigationBottomPadding;

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;
        final theme = Theme.of(context);
        final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: buildAppBackgroundGradient(theme),
            ),
            child: SafeArea(
              top: !isDesktop,
              bottom: false,
              child: isDesktop
                  ? const Column(
                      children: [
                        SizedBox(height: desktopTopBarTopPadding),
                        _DesktopAppBar(),
                        Expanded(
                          child: AppSections(
                            isDesktop: true,
                            mobileBottomInset: mobileBottomNavigationReservedHeight,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        AppSections(
                          isDesktop: false,
                          mobileBottomInset:
                              mobileBottomNavigationReservedHeight +
                              safeAreaBottom,
                          mobileHeader: const _MobileTopBar(),
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _MobileBottomNavigation(),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopAppBar extends StatelessWidget {
  const _DesktopAppBar();

  @override
  Widget build(BuildContext context) {
    final selectedDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: desktopContentMaxWidth),
          child: GlassPanel.chrome(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            child: Row(
              children: [
                const _BrandLockup(showSubtitle: true),
                const SizedBox(width: 18),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: _TopBarDestinationChip(
                            destination: selectedDestination,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          fit: FlexFit.loose,
                          child: _DesktopAccountControl(),
                        ),
                        const SizedBox(width: 12),
                        MenuAnchor(
                          menuChildren: AppDestination.values
                              .map(
                                (destination) => MenuItemButton(
                                  leadingIcon: Icon(destination.icon),
                                  onPressed: () {
                                    context
                                        .read<NavigationState>()
                                        .selectDestination(destination);
                                  },
                                  child: Text(destination.label),
                                ),
                              )
                              .toList(),
                          builder: (context, controller, child) {
                            return _TopBarIconButton(
                              tooltip: 'Open navigation',
                              icon: Icons.menu_rounded,
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                            );
                          },
                        ),
                      ],
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

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    final selectedDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );
    final greeting = context.select<AuthSessionState, String>(
      (state) => state.greeting,
    );

    return GlassPanel.chrome(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _BrandLockup(showSubtitle: false)),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TopBarDestinationChip(
                      destination: selectedDestination,
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              greeting,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Shared debt and receipts',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: mutedForegroundColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarDestinationChip extends StatelessWidget {
  const _TopBarDestinationChip({
    required this.destination,
    this.compact = false,
  });

  final AppDestination destination;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        compact
            ? Theme.of(context).textTheme.labelLarge
            : Theme.of(context).textTheme.titleSmall;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        tone: brandPrimary,
        includeShadows: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(destination.icon, size: compact ? 18 : 20, color: brandPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              destination.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: labelStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        includeShadows: false,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 28,
        constraints: const BoxConstraints.tightFor(width: 52, height: 52),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _DesktopAccountControl extends StatelessWidget {
  const _DesktopAccountControl();

  @override
  Widget build(BuildContext context) {
    final authView = context
        .select<
          AuthSessionState,
          ({
            bool isLoading,
            String? name,
            String? email,
            bool isAuthenticated,
            Credentials? credentials,
          })
        >(
          (state) => (
            isLoading: state.isLoading,
            name: state.displayName,
            email: state.userEmail,
            isAuthenticated: state.isAuthenticated,
            credentials: state.credentials,
          ),
        );
    if (authView.isLoading) {
      return const SizedBox(
        width: 46,
        height: 46,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (!authView.isAuthenticated) {
      return FilledButton.icon(
        onPressed: () {
          context.read<AuthSessionState>().login();
        },
        icon: const Icon(Icons.login_rounded),
        label: const Text('Log in'),
      );
    }

    return GlassPanel.chrome(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            credentials: authView.credentials,
            radius: 28,
            displayName: authView.name,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final preferredWidth = maxWidth.isFinite
                    ? (maxWidth >= 130
                          ? maxWidth.clamp(130.0, 200.0)
                          : maxWidth)
                    : 200.0;

                return SizedBox(
                  width: preferredWidth.toDouble(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authView.name ?? 'User',
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.fade,
                            ),
                      ),
                      Text(
                        authView.email ?? '',
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: mutedForegroundColor(context),
                              overflow: TextOverflow.fade,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthSessionState>().logout();
            },
            icon: const Icon(Icons.logout_rounded),
            iconSize: 36,
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.showSubtitle});

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassPanel.secondary(
          padding: const EdgeInsets.all(6),
          borderRadius: BorderRadius.all(
            Radius.circular(showSubtitle ? 14 : 12),
          ),
          child: SizedBox(
            width: showSubtitle ? 74 : 46,
            height: showSubtitle ? 74 : 46,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(showSubtitle ? 12 : 10),
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Debt Display',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (showSubtitle)
              Text(
                'Shared debt and receipts',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: mutedForegroundColor(context),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation();

  static const _blurSigma = 6.0;

  @override
  Widget build(BuildContext context) {
    final currentDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: mobileBottomNavigationOuterPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
              child: DecoratedBox(
                decoration: glassSurfaceDecoration(
                  context,
                  variant: AppGlassVariant.chrome,
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  includeShadows: false,
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedIndex: AppDestination.values.indexOf(
                    currentDestination,
                  ),
                  height: mobileBottomNavigationHeight,
                  elevation: 0,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: AppDestination.values
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          label: destination.label,
                        ),
                      )
                      .toList(),
                  onDestinationSelected: (index) {
                    context.read<NavigationState>().selectDestination(
                      AppDestination.values[index],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

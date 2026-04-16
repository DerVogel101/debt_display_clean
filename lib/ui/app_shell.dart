import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_session_state.dart';
import '../state/navigation_state.dart';
import '../theme/app_themes.dart';
import 'app_shared.dart';
import 'app_sections.dart';

export 'app_shared.dart';

const desktopBreakpoint = 768.0;

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: isDesktop ? const _DesktopAppBar() : null,
          body: Container(
            decoration: BoxDecoration(
              gradient: buildAppBackgroundGradient(theme),
            ),
            child: SafeArea(
              top: false,
              bottom: !isDesktop,
              child: Column(
                children: [
                  if (!isDesktop) const _MobileTopBar(),
                  Expanded(child: AppSections(isDesktop: isDesktop)),
                ],
              ),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : const _MobileBottomNavigation(),
        );
      },
    );
  }
}

class _DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DesktopAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(94);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      shape: Border(
        bottom: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: Row(
          children: [
            const _BrandLockup(showSubtitle: true),
            const Spacer(),
            const _DesktopAccountControl(),
            const SizedBox(width: 12),
            MenuAnchor(
              menuChildren: AppDestination.values
                  .map(
                    (destination) => MenuItemButton(
                      leadingIcon: Icon(destination.icon),
                      onPressed: () {
                        context.read<NavigationState>().selectDestination(
                          destination,
                        );
                      },
                      child: Text(destination.label),
                    ),
                  )
                  .toList(),
              builder: (context, controller, child) {
                return IconButton.filledTonal(
                  iconSize: 36,
                  tooltip: 'Open navigation',
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: const Icon(Icons.menu_rounded),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              selectedDestination.label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const _BrandLockup(showSubtitle: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDestination.label,
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
            ],
          ),
        ),
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
          ({bool isLoading, String? name, String? email, bool isAuthenticated})
        >(
          (state) => (
            isLoading: state.isLoading,
            name: state.displayName,
            email: state.userEmail,
            isAuthenticated: state.isAuthenticated,
          ),
        );
    final scheme = Theme.of(context).colorScheme;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<AuthSessionState, Credentials?>(
            selector: (_, state) => state.credentials,
            builder: (context, credentials, child) {
              return UserAvatar(credentials: credentials, radius: 28);
            },
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                authView.name ?? 'User',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                authView.email ?? '',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: mutedForegroundColor(context),
                ),
              ),
            ],
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
        Container(
          width: showSubtitle ? 86 : 58,
          height: showSubtitle ? 86 : 58,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(showSubtitle ? 14 : 12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(showSubtitle ? 12 : 10),
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
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

  @override
  Widget build(BuildContext context) {
    final currentDestination = context.select<NavigationState, AppDestination>(
      (state) => state.selectedDestination,
    );
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: AppDestination.values.indexOf(currentDestination),
            height: 72,
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
    );
  }
}

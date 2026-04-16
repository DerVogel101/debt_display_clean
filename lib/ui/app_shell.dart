import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

import 'app_shared.dart';
import 'app_sections.dart';

export 'app_shared.dart';

const desktopBreakpoint = 768.0;

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.credentials,
    required this.isLoading,
    required this.backendError,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.onLogin,
    required this.onLogout,
  });

  final Credentials? credentials;
  final bool isLoading;
  final String? backendError;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8EDFF),
                  Color(0xFFF8F4FF),
                  Color(0xFFFFFCF6),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
            child: SafeArea(
              bottom: !isDesktop,
              child: Column(
                children: [
                  if (isDesktop)
                    _DesktopTopBar(
                      credentials: credentials,
                      isLoading: isLoading,
                      selectedDestination: selectedDestination,
                      onDestinationSelected: onDestinationSelected,
                      onLogin: onLogin,
                      onLogout: onLogout,
                    )
                  else
                    _MobileTopBar(selectedDestination: selectedDestination),
                  Expanded(
                    child: AppSections(
                      credentials: credentials,
                      isLoading: isLoading,
                      backendError: backendError,
                      selectedDestination: selectedDestination,
                      onDestinationSelected: onDestinationSelected,
                      onLogin: onLogin,
                      onLogout: onLogout,
                      isDesktop: isDesktop,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : _MobileBottomNavigation(
                  currentDestination: selectedDestination,
                  onDestinationSelected: onDestinationSelected,
                ),
        );
      },
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.credentials,
    required this.isLoading,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.onLogin,
    required this.onLogout,
  });

  final Credentials? credentials;
  final bool isLoading;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const _BrandLockup(showSubtitle: true),
          const Spacer(),
          _DesktopAccountControl(
            credentials: credentials,
            isLoading: isLoading,
            onLogin: onLogin,
            onLogout: onLogout,
          ),
          const SizedBox(width: 12),
          MenuAnchor(
            menuChildren: AppDestination.values
                .map(
                  (destination) => MenuItemButton(
                    leadingIcon: Icon(destination.icon),
                    onPressed: () => onDestinationSelected(destination),
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
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.selectedDestination});

  final AppDestination selectedDestination;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedDestination.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shared debt and receipts',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopAccountControl extends StatelessWidget {
  const _DesktopAccountControl({
    required this.credentials,
    required this.isLoading,
    required this.onLogin,
    required this.onLogout,
  });

  final Credentials? credentials;
  final bool isLoading;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 46,
        height: 46,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (credentials == null) {
      return FilledButton.icon(
        onPressed: onLogin,
        icon: const Icon(Icons.login_rounded),
        label: const Text('Log in'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(credentials: credentials, radius: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                credentials?.user.name ?? 'User',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                credentials?.user.email ?? '',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Log out',
            onPressed: onLogout,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(showSubtitle ? 14 : 12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
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
                'Username Here',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
          ],
        ),
      ],
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  final AppDestination currentDestination;
  final ValueChanged<AppDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
            indicatorColor: brandPrimary.withValues(alpha: 0.14),
            destinations: AppDestination.values
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
                )
                .toList(),
            onDestinationSelected: (index) {
              onDestinationSelected(AppDestination.values[index]);
            },
          ),
        ),
      ),
    );
  }
}

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

import 'app_shared.dart';

class AppSections extends StatelessWidget {
  const AppSections({
    super.key,
    required this.credentials,
    required this.isLoading,
    required this.backendError,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.onLogin,
    required this.onLogout,
    required this.isDesktop,
  });

  final Credentials? credentials;
  final bool isLoading;
  final String? backendError;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final maxWidth = isDesktop ? 1180.0 : 640.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            isDesktop ? 28 : 16,
            isDesktop ? 32 : 16,
            isDesktop ? 32 : 20,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return LoadingSection(
        key: const ValueKey('loading'),
        isDesktop: isDesktop,
      );
    }

    switch (selectedDestination) {
      case AppDestination.home:
        return HomeSection(
          key: const ValueKey('home'),
          credentials: credentials,
          backendError: backendError,
          onLogin: onLogin,
          onOpenProfile: () => onDestinationSelected(AppDestination.profile),
          isDesktop: isDesktop,
        );
      case AppDestination.profile:
        return ProfileSection(
          key: const ValueKey('profile'),
          credentials: credentials,
          backendError: backendError,
          onLogin: onLogin,
          onLogout: onLogout,
        );
      case AppDestination.menu:
        return MenuSection(
          key: const ValueKey('menu'),
          credentials: credentials,
          backendError: backendError,
          onDestinationSelected: onDestinationSelected,
        );
    }
  }
}

class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.credentials,
    required this.backendError,
    required this.onLogin,
    required this.onOpenProfile,
    required this.isDesktop,
  });

  final Credentials? credentials;
  final String? backendError;
  final Future<void> Function() onLogin;
  final VoidCallback onOpenProfile;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageSection(
          padding: EdgeInsets.all(isDesktop ? 36 : 24),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _HeroCopy(credentials: credentials)),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 360,
                      child: _StatusCard(credentials: credentials),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCopy(credentials: credentials),
                    const SizedBox(height: 20),
                    _StatusCard(credentials: credentials),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        if (backendError != null) ...[
          ErrorSection(message: backendError!),
          const SizedBox(height: 18),
        ],
        PageSection(
          padding: EdgeInsets.all(isDesktop ? 28 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next step',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                credentials == null
                    ? 'Authenticate to sync your account with the backend and unlock the profile workspace.'
                    : 'Open your profile to review synced account data and session details.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (credentials == null)
                    FilledButton.icon(
                      onPressed: onLogin,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Log in'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onOpenProfile,
                      icon: const Icon(Icons.person_rounded),
                      label: const Text('Open profile'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onOpenProfile,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Go to profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.credentials,
    required this.backendError,
    required this.onLogin,
    required this.onLogout,
  });

  final Credentials? credentials;
  final String? backendError;
  final Future<void> Function() onLogin;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageSection(
          padding: const EdgeInsets.all(24),
          child: credentials == null
              ? _LoggedOutProfileCard(onLogin: onLogin)
              : _LoggedInProfileCard(
                  credentials: credentials!,
                  onLogout: onLogout,
                ),
        ),
        if (backendError != null) ...[
          const SizedBox(height: 18),
          ErrorSection(message: backendError!),
        ],
      ],
    );
  }
}

class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required this.credentials,
    required this.backendError,
    required this.onDestinationSelected,
  });

  final Credentials? credentials;
  final String? backendError;
  final ValueChanged<AppDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        title: 'Home',
        body: 'Return to the landing view and authentication summary.',
        icon: Icons.home_rounded,
        destination: AppDestination.home,
      ),
      (
        title: 'Profile',
        body: credentials == null
            ? 'Open the account tab to sign in and inspect your user data.'
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
                'This destination works as the current overflow area and keeps future sections visible in the navigation model.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
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
                    onTap: () => onDestinationSelected(item.destination),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (backendError != null) ...[
          const SizedBox(height: 18),
          ErrorSection(message: backendError!),
        ],
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.credentials});

  final Credentials? credentials;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Responsive web shell',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: brandPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Manage authentication across desktop and phone-sized browsers.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          credentials == null
              ? 'Desktop gets a persistent top bar and menu-driven navigation. On smartphones, the interface collapses into touch-first sheets with bottom navigation.'
              : 'Your session is active. Desktop keeps account controls in the top bar, while smartphone actions live under the profile tab.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black87, height: 1.5),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.credentials});

  final Credentials? credentials;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = credentials != null;
    final tone = isLoggedIn ? Colors.green : Colors.red;
    final bg = isLoggedIn ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isLoggedIn
                  ? Icons.verified_user_rounded
                  : Icons.lock_outline_rounded,
              color: tone.shade700,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isLoggedIn ? 'You are logged in' : 'You are logged out',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? credentials?.user.email ?? 'Authenticated session'
                : 'Start an Auth0 login to create or restore a browser session.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutProfileCard extends StatelessWidget {
  const _LoggedOutProfileCard({required this.onLogin});

  final Future<void> Function() onLogin;

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
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onLogin,
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
    required this.onLogout,
  });

  final Credentials credentials;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (credentials.user.pictureUrl != null) ...[
          UserAvatar(credentials: credentials, radius: 42),
          const SizedBox(height: 18),
        ],
        Text(
          credentials.user.name ?? 'User',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          credentials.user.email ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _ProfileInfoTable(credentials: credentials),
        const SizedBox(height: 24),
        Text(
          'Raw user object',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(20),
          ),
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
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class _ProfileInfoTable extends StatelessWidget {
  const _ProfileInfoTable({required this.credentials});

  final Credentials credentials;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Email', credentials.user.email ?? 'N/A'),
      ('Name', credentials.user.name ?? 'N/A'),
      ('Nickname', credentials.user.nickname ?? 'N/A'),
      ('User ID', credentials.user.sub),
    ];

    return Column(
      children: rows
          .map(
            (row) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black54,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
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

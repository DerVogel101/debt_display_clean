import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';

const brandPrimary = Color(0xFF667EEA);

enum AppDestination {
  home('Home', Icons.home_rounded),
  profile('Profile', Icons.person_rounded),
  menu('Menu', Icons.menu_rounded);

  const AppDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class PageSection extends StatelessWidget {
  const PageSection({super.key, required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ErrorSection extends StatelessWidget {
  const ErrorSection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PageSection(
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backend authentication failed: $message',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingSection extends StatelessWidget {
  const LoadingSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return PageSection(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text(
            'Restoring session...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.credentials,
    required this.radius,
  });

  final Credentials? credentials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = credentials?.user.name ?? credentials?.user.nickname ?? 'U';
    final pictureUrl = credentials?.user.pictureUrl?.toString();

    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(pictureUrl),
      );
    }

    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty
        ? trimmed.substring(0, 1).toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: brandPrimary.withValues(alpha: 0.12),
      foregroundColor: brandPrimary,
      child: Text(
        initial,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

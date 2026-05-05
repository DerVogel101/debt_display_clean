import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/config/app_config.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:flutter/material.dart';

enum AppDestination {
  home('Home', Icons.home_rounded),
  bills('Bills', Icons.receipt_long_rounded),
  createBill('Create Bill', Icons.add_circle_rounded),
  recipientGroups('Recipient groups', Icons.groups_rounded),
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
    return GlassPanel(
      padding: padding,
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      width: double.infinity,
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    required this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.variant = AppGlassVariant.primary,
    this.tone,
    this.width,
  });

  const GlassPanel.secondary({
    super.key,
    required this.child,
    required this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tone,
    this.width,
  }) : variant = AppGlassVariant.secondary;

  const GlassPanel.chrome({
    super.key,
    required this.child,
    required this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.tone,
    this.width,
  }) : variant = AppGlassVariant.chrome;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final AppGlassVariant variant;
  final Color? tone;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: glassSurfaceDecoration(
        context,
        variant: variant,
        borderRadius: borderRadius,
        tone: tone,
      ),
      child: child,
    );
  }
}

BoxDecoration glassSurfaceDecoration(
  BuildContext context, {
  AppGlassVariant variant = AppGlassVariant.primary,
  required BorderRadiusGeometry borderRadius,
  Color? tone,
  bool includeShadows = true,
}) {
  final style = appGlassStyle(Theme.of(context), variant: variant, tone: tone);

  return BoxDecoration(
    gradient: style.fillGradient,
    borderRadius: borderRadius,
    border: Border.all(color: style.borderColor),
    boxShadow: includeShadows ? style.shadows : null,
  );
}

class ErrorSection extends StatelessWidget {
  const ErrorSection({super.key, required this.message});

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
              'Backend authentication failed: $message',
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
    this.displayName,
  });

  final Credentials? credentials;
  final double radius;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final name =
        displayName ??
        AuthSessionState.resolveDisplayNameForUser(
          credentials?.user,
          claimKey: AppConfig.auth0FullNameClaim,
        ) ??
        'U';
    final pictureUrl = credentials?.user.pictureUrl?.toString();

    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ClipOval(
          child: Image.network(
            pictureUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackAvatar(context, name);
            },
          ),
        ),
      );
    }

    return _buildFallbackAvatar(context, name);
  }

  Widget _buildFallbackAvatar(BuildContext context, String name) {
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

Color mutedForegroundColor(BuildContext context, {double alpha = 0.72}) {
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);
}

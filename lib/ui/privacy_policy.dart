import 'package:debt_display/l10n/generated/app_localizations.dart';
import 'package:debt_display/state/privacy_consent_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _privacyPolicyAssetPath = 'assets/privacy.txt';

class PrivacyConsentGate extends StatelessWidget {
  const PrivacyConsentGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final privacyView = context
        .select<PrivacyConsentState, ({bool isLoading, bool hasAccepted})>(
          (state) => (
            isLoading: state.isLoading,
            hasAccepted: state.hasAcceptedCurrentVersion,
          ),
        );

    if (privacyView.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: buildAppBackgroundGradient(Theme.of(context)),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    if (privacyView.hasAccepted) {
      return child;
    }

    return const _PrivacyGateScaffold();
  }
}

class _PrivacyGateScaffold extends StatelessWidget {
  const _PrivacyGateScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: buildAppBackgroundGradient(Theme.of(context)),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: PrivacyPolicyCard(requireAcceptance: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicySection extends StatelessWidget {
  const PrivacyPolicySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivacyPolicyCard(requireAcceptance: false);
  }
}

class PrivacyPolicyCard extends StatefulWidget {
  const PrivacyPolicyCard({
    super.key,
    required this.requireAcceptance,
    this.policyTextFuture,
  });

  final bool requireAcceptance;
  final Future<String>? policyTextFuture;

  @override
  State<PrivacyPolicyCard> createState() => _PrivacyPolicyCardState();
}

class _PrivacyPolicyCardState extends State<PrivacyPolicyCard> {
  late final Future<String> _policyTextFuture;

  @override
  void initState() {
    super.initState();
    _policyTextFuture =
        widget.policyTextFuture ??
        rootBundle.loadString(_privacyPolicyAssetPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageSection(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.privacyPolicyTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.privacyPolicyIntro,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedForegroundColor(context, alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<String>(
            future: _policyTextFuture,
            builder: (context, snapshot) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrivacyPolicyText(snapshot: snapshot),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (widget.requireAcceptance && snapshot.hasData)
                      FilledButton.icon(
                        key: const ValueKey('privacy-accept-button'),
                        onPressed: () {
                          context.read<PrivacyConsentState>().accept();
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(l10n.acceptPrivacyPolicy),
                      )
                    else if (!widget.requireAcceptance)
                      OutlinedButton.icon(
                        key: const ValueKey('privacy-revoke-button'),
                        onPressed: () {
                          context.read<PrivacyConsentState>().revoke();
                        },
                        icon: const Icon(Icons.block_rounded),
                        label: Text(l10n.revokePrivacyConsent),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText({required this.snapshot});

  final AsyncSnapshot<String> snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Text(
        l10n.privacyPolicyLoadFailed,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return DecoratedBox(
      decoration: glassSurfaceDecoration(
        context,
        variant: AppGlassVariant.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        includeShadows: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          snapshot.data!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: mutedForegroundColor(context, alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

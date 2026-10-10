import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/eligibility.dart';
import '../../domain/models/scheme.dart';
import '../../domain/rates/rate_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

void openSchemeDetails(BuildContext context, Scheme scheme) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SchemeDetailsScreen(scheme: scheme),
      ),
    );

/// Facts of [s] at today's rate.
List<(SchemeFact, String)> factsFor(S s, RateRepository rates, Scheme scheme) {
  final rate = rates.current(scheme).rate;
  return s.schemeFacts(scheme, pct(rate), kvpMonths: kvpMonths(rate));
}

/// Plain-text version for sending to a customer.
String schemeDetailsText(S s, RateRepository rates, Scheme scheme) => [
  '${s.schemeName(scheme)} (${scheme.code})',
  s.validFrom(dmy(rates.validFrom)),
  '',
  for (final (f, text) in factsFor(s, rates, scheme))
    '${s.factLabel(f)}: $text',
  '',
  '${s.documents}:',
  for (final d in documentsFor(scheme)) '• ${s.doc(d)}',
  '',
  s.estimateOnly,
  '— ${s.appTitle}',
].join('\n');

class SchemeDetailsScreen extends StatelessWidget {
  const SchemeDetailsScreen({super.key, required this.scheme});
  final Scheme scheme;

  static IconData _icon(SchemeFact f) => switch (f) {
    SchemeFact.interest => Icons.percent_rounded,
    SchemeFact.tenure => Icons.schedule_rounded,
    SchemeFact.deposit => Icons.payments_rounded,
    SchemeFact.who => Icons.person_rounded,
    SchemeFact.tax => Icons.receipt_long_rounded,
    SchemeFact.closure => Icons.lock_open_rounded,
    SchemeFact.loan => Icons.account_balance_rounded,
    SchemeFact.maturity => Icons.event_available_rounded,
  };

  Future<void> _share(BuildContext context) async {
    final s = context.s;
    try {
      await SharePlus.instance.share(
        ShareParams(text: schemeDetailsText(s, context.rates, scheme)),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.shareFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final t = Theme.of(context).textTheme;
    final c = scheme.color;
    final facts = factsFor(s, rates, scheme);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            gradient: scheme.gradient,
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BackButton(color: Colors.white),
                      Spacer(),
                      LanguageToggle(onDark: true),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(scheme.icon, color: c, size: 34),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.schemeDetails,
                                style: t.labelLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                s.schemeName(scheme),
                                style: t.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Pill(
                                s.validFrom(dmy(rates.validFrom)),
                                icon: Icons.event_available_rounded,
                                background: Brand.yellow,
                                foreground: Brand.ink,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: c,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(s.shareDetails),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        for (final (i, (f, text)) in facts.indexed)
                          Appear(
                            delay: Appear.step(i, ms: 50),
                            child: ListTile(
                              leading: IconBadge(_icon(f), c, size: 36),
                              title: Text(
                                s.factLabel(f),
                                style: t.labelLarge?.copyWith(
                                  color: scheme.textColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(text, style: t.bodyMedium),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SectionCard(
                  icon: Icons.folder_copy_rounded,
                  title: s.documents,
                  color: c,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in documentsFor(scheme))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: c,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.doc(d))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Note(s.documentsNote),
                Note(s.estimateOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

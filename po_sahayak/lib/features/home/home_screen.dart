import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../calculator/calculator_screen.dart';

/// Schemes grouped as on the Home screen.
List<(String, List<Scheme>)> homeGroups(BuildContext context) {
  final s = context.s;
  return [
    (
      s.groupDeposits,
      [Scheme.td1, Scheme.td2, Scheme.td3, Scheme.td5, Scheme.rd, Scheme.sb],
    ),
    (s.groupIncome, [Scheme.mis, Scheme.scss]),
    (s.groupCertificates, [Scheme.nsc, Scheme.kvp, Scheme.mssc]),
    (s.groupLongTerm, [Scheme.ppf, Scheme.ssy]),
  ];
}

void openCalculator(BuildContext context, Scheme scheme) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CalculatorScreen(scheme: scheme)),
    );

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final top = Scheme.openable.reduce(
      (a, b) => rates.current(a).rate >= rates.current(b).rate ? a : b,
    );
    var index = 0;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(top: top)),
          for (final (title, schemes) in homeGroups(context)) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // Rows of two tiles that grow with their text (large phone
              // font sizes), instead of a fixed-height grid.
              sliver: SliverList.list(
                children: [
                  for (var i = 0; i < schemes.length; i += 2)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = i; j < i + 2; j++) ...[
                            if (j > i) const SizedBox(width: 4),
                            Expanded(
                              child: j < schemes.length
                                  ? Appear(
                                      delay: Appear.step(index++),
                                      child: SchemeTile(scheme: schemes[j]),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList.list(
              children: [
                Note(s.estimateOnly),
                Note(s.notAffiliated, icon: Icons.gpp_maybe_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.top});
  final Scheme top;

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final t = Theme.of(context).textTheme;
    final white70 = Colors.white.withValues(alpha: 0.82);
    return GradientHeader(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and language button on top; the name gets the full
            // width below, so it never wraps beside the button.
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Brand.yellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: Brand.redDark,
                    size: 28,
                  ),
                ),
                const Spacer(),
                const LanguageToggle(onDark: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.appTitle,
              style: t.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(s.tagline, style: t.bodyMedium?.copyWith(color: white70)),
            const SizedBox(height: 20),
            Appear(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 6,
                shadowColor: Colors.black38,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openCalculator(context, top),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(top.icon, top.color, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.highestRate,
                                style: t.labelLarge?.copyWith(
                                  color: Brand.redDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${pct(rates.current(top).rate)}%',
                              style: t.headlineMedium?.copyWith(
                                color: top.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.schemeName(top),
                          style: t.titleMedium?.copyWith(
                            color: Brand.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                s.validFrom(dmy(rates.validFrom)),
                icon: Icons.event_available_rounded,
                background: Brand.yellow,
                foreground: Brand.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coloured tile for one scheme; its icon flies into the calculator header.
class SchemeTile extends StatelessWidget {
  const SchemeTile({super.key, required this.scheme});
  final Scheme scheme;

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final rate = context.rates.current(scheme).rate;
    final closed = scheme == Scheme.mssc;
    final c = scheme.color;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCalculator(context, scheme),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                scheme.icon,
                size: 92,
                color: c.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'scheme-${scheme.code}',
                        child: IconBadge(scheme.icon, c, size: 38),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scheme.code,
                          style: t.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.schemeName(scheme),
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Spacer(),
                  Text(
                    '${pct(rate)}%',
                    style: t.headlineSmall?.copyWith(
                      color: scheme.textColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // Tenure under the rate (TD names already say it).
                  if (closed || !scheme.isTd)
                    Text(
                      closed ? s.closedForNew : s.tenureOf(scheme),
                      style: t.bodySmall?.copyWith(
                        color: closed
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

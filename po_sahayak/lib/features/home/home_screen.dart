import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../calculator/calculator_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.currentRates, style: Theme.of(context).textTheme.titleLarge),
          Note(s.validFrom(dmy(rates.validFrom)), icon: Icons.event),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 560 ? 3 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
                children: [
                  for (final scheme in Scheme.values)
                    _SchemeTile(scheme: scheme),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Note(s.estimateOnly),
          Note(s.notAffiliated),
        ],
      ),
    );
  }
}

class _SchemeTile extends StatelessWidget {
  const _SchemeTile({required this.scheme});
  final Scheme scheme;

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final rate = context.rates.current(scheme).rate;
    final closed = scheme == Scheme.mssc;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CalculatorScreen(scheme: scheme),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scheme.code,
                style: t.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  s.schemeName(scheme),
                  style: t.titleSmall,
                  overflow: TextOverflow.fade,
                ),
              ),
              Text(
                '${pct(rate)}%',
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (closed)
                Text(
                  s.closedForNew,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

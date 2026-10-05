import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/scope.dart';
import '../domain/models/result.dart';

/// Year-wise table: year, deposit, interest, balance.
class ScheduleTable extends StatelessWidget {
  const ScheduleTable({super.key, required this.rows});
  final List<ScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return _FullWidth(
      child: DataTable(
        columnSpacing: 18,
        horizontalMargin: 8,
        headingRowHeight: 44,
        columns: [
          DataColumn(label: Text(s.year)),
          DataColumn(label: Text(s.deposit), numeric: true),
          DataColumn(label: Text(s.interest), numeric: true),
          DataColumn(label: Text(s.balance), numeric: true),
        ],
        rows: [
          for (final r in rows)
            DataRow(
              cells: [
                DataCell(Text('${r.year}\n${dmy(r.date)}')),
                DataCell(Text(rupee(r.deposit))),
                DataCell(Text(rupee(r.interest))),
                DataCell(Text(rupee(r.balance))),
              ],
            ),
        ],
      ),
    );
  }
}

/// Two-column table (label, amount).
class PairTable extends StatelessWidget {
  const PairTable({
    super.key,
    required this.head1,
    required this.head2,
    required this.rows,
  });
  final String head1;
  final String head2;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => _FullWidth(
    child: DataTable(
      columnSpacing: 24,
      horizontalMargin: 8,
      headingRowHeight: 44,
      columns: [
        DataColumn(label: Text(head1)),
        DataColumn(label: Text(head2), numeric: true),
      ],
      rows: [
        for (final (a, b) in rows)
          DataRow(cells: [DataCell(Text(a)), DataCell(Text(b))]),
      ],
    ),
  );
}

/// Scrolls sideways when the table is wider than the card, and otherwise
/// stretches it to the card's full width.
class _FullWidth extends StatelessWidget {
  const _FullWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: c.maxWidth),
        child: child,
      ),
    ),
  );
}

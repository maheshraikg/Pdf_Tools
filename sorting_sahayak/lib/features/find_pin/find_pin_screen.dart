/// Find a PIN from an address (office / village / city / taluk / district;
/// English, Kannada or Hindi), plus the PIN ↔ place mismatch check.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/directory_repo.dart';
import '../../data/models/office.dart';
import '../home_shell.dart';
import 'mismatch_view.dart';

class FindPinScreen extends StatefulWidget {
  const FindPinScreen({super.key});

  @override
  State<FindPinScreen> createState() => _FindPinScreenState();
}

class _FindPinScreenState extends State<FindPinScreen> {
  final _q = TextEditingController();
  final _mmPin = TextEditingController();
  final _mmPlace = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _hits = [];
  bool _searching = false;
  int _seq = 0;
  String? _state;
  String? _district;
  bool _deliveryOnly = false;
  List<String> _states = [];
  List<String> _districts = [];
  bool _checkerOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_states.isEmpty) _loadStates();
  }

  Future<void> _loadStates() async {
    final s = await context.services.directory.states();
    if (mounted) setState(() => _states = s);
  }

  Future<void> _loadDistricts() async {
    final d = _state == null ? <String>[] : await context.services.directory.districts(state: _state);
    if (mounted) setState(() => _districts = d);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _mmPin.dispose();
    _mmPlace.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _search);
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    final seq = ++_seq;
    if (q.length < 2) {
      setState(() {
        _hits = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final hits = await context.services.directory.search(
      q,
      filter: SearchFilter(state: _state, district: _district, deliveryOnly: _deliveryOnly),
      limit: 60,
    );
    if (!mounted || seq != _seq) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  Future<void> _details(Office o) async {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final fav = await services.user.isFavourite(o.pincode, o.officeName);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OfficeTile(office: o),
            if (o.division.isNotEmpty || o.taluk.isNotEmpty)
              ListTile(dense: true, title: Text([if (o.taluk.isNotEmpty) '${l.taluk}: ${o.taluk}', if (o.division.isNotEmpty) '${l.division}: ${o.division}', if (o.region.isNotEmpty) o.region].join(' · '))),
            ListTile(
              leading: const Icon(Icons.dialpad),
              title: Text(l.sortThisPin),
              onTap: () {
                Navigator.pop(c);
                HomeShell.of(context)?.openSort(o.pin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l.copyPin),
              onTap: () {
                Clipboard.setData(ClipboardData(text: o.pin));
                Navigator.pop(c);
                toast(context, l.copied);
              },
            ),
            ListTile(
              leading: Icon(fav ? Icons.star : Icons.star_border),
              title: Text(fav ? l.removeFavourite : l.addFavourite),
              onTap: () async {
                if (fav) {
                  await services.user.removeFavouriteBy(o.pincode, o.officeName);
                } else {
                  await services.user.addFavourite(o);
                }
                services.touchRecents();
                if (c.mounted) Navigator.pop(c);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final engine = services.engine;
    final settings = context.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.navFindPin)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _q,
            autofocus: false,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.findPinHint,
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(tooltip: l.clear, icon: const Icon(Icons.close), onPressed: () {
                      _q.clear();
                      _search();
                    }),
            ),
            onChanged: (v) {
              setState(() {});
              _onChanged(v);
            },
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _ChoiceFilter(
                label: _state ?? l.allStates,
                selected: _state != null,
                options: _states,
                onSelected: (v) {
                  setState(() {
                    _state = v;
                    _district = null;
                  });
                  _loadDistricts();
                  _search();
                },
                allLabel: l.allStates,
              ),
              if (_state != null)
                _ChoiceFilter(
                  label: _district ?? l.allDistricts,
                  selected: _district != null,
                  options: _districts,
                  onSelected: (v) {
                    setState(() => _district = v);
                    _search();
                  },
                  allLabel: l.allDistricts,
                ),
              FilterChip(
                label: Text(l.deliveryOnly),
                selected: _deliveryOnly,
                onSelected: (v) {
                  setState(() => _deliveryOnly = v);
                  _search();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_searching) const LinearProgressIndicator(),
          if (!_searching && _q.text.trim().length >= 2 && _hits.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l.noResults, textAlign: TextAlign.center)),
          for (final h in _hits)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Builder(builder: (_) {
                final res = engine.resolveOffice(h.office, category: settings.category);
                return OfficeTile(
                  office: h.office,
                  onTap: () => _details(h.office),
                  subtitleExtra: res.bag == null ? null : '${l.bag}: ${res.bag!.label}',
                  trailing: res.bag == null
                      ? null
                      : CircleAvatar(backgroundColor: bagColour(context, res.bag), radius: 10),
                );
              }),
            ),
          if (_q.text.isEmpty) ...[
            const SizedBox(height: 8),
            Text(l.findPinTip, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              initiallyExpanded: _checkerOpen,
              onExpansionChanged: (v) => _checkerOpen = v,
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(l.mismatchChecker, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(l.mismatchCheckerSub),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: _mmPin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: l.fPin, counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mmPlace,
                  decoration: InputDecoration(labelText: l.placeOnAddress),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (_mmPin.text.length == 6 && _mmPlace.text.trim().length >= 2)
                  MismatchView(
                    pin: _mmPin.text,
                    place: _mmPlace.text,
                    onPickPin: (o) => setState(() => _mmPin.text = o.pin),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceFilter extends StatelessWidget {
  const _ChoiceFilter({required this.label, required this.selected, required this.options, required this.onSelected, required this.allLabel});

  final String label;
  final bool selected;
  final List<String> options;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: const Icon(Icons.arrow_drop_down),
      showCheckmark: false,
      onSelected: (_) async {
        final v = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (c) => DraggableScrollableSheet(
            expand: false,
            builder: (_, sc) => ListView(
              controller: sc,
              children: [
                ListTile(title: Text(allLabel), onTap: () => Navigator.pop(c, '')),
                for (final o in options) ListTile(title: Text(o), onTap: () => Navigator.pop(c, o)),
              ],
            ),
          ),
        );
        if (v != null) onSelected(v.isEmpty ? null : v);
      },
    );
  }
}

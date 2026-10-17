import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/models.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import 'place_card.dart';

/// The most-used screen: one box for name, door no., street, building,
/// landmark, area or PIN; fuzzy + transliterated matching; voice input.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.startWithVoice = false,
    this.initialQuery = '',
    this.pickMode = false,
    this.pickLabel,
    this.excludeId,
    this.title,
  });
  final bool startWithVoice;
  final String initialQuery;

  /// Returns the chosen place id with Navigator.pop.
  final bool pickMode;
  final String? pickLabel;
  final int? excludeId;
  final String? title;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with LiveLocation {
  late final TextEditingController _q = TextEditingController(text: widget.initialQuery);
  final Map<int, PlaceDetails> _cache = {};
  List<int> _ids = [];
  bool _allBeats = false;
  int _cacheVersion = -1;
  int _token = 0;
  Timer? _debounce;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    startLocation();
    if (widget.initialQuery.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    if (widget.startWithVoice) WidgetsBinding.instance.addPostFrameCallback((_) => _voice());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _run);
  }

  Future<void> _run() async {
    final app = context.app;
    if (app.version != _cacheVersion) {
      _cache.clear();
      _cacheVersion = app.version;
    }
    final token = ++_token;
    final hits = app.search(_q.text, allBeats: _allBeats, limit: 40);
    final ids = hits.map((h) => h.id).where((id) => id != widget.excludeId).toList();
    final missing = ids.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      for (final d in await context.services.places.detailsForIds(missing)) {
        _cache[d.place.id!] = d;
      }
    }
    if (!mounted || token != _token) return;
    setState(() => _ids = ids.where(_cache.containsKey).toList());
  }

  Future<void> _voice() async {
    final l = context.l;
    setState(() => _listening = true);
    final heard = await context.services.voice.listenOnce(
      context.lang,
      onPartial: (p) {
        if (mounted) _q.text = p;
      },
    );
    if (!mounted) return;
    setState(() => _listening = false);
    if (heard == null || heard.isEmpty) {
      context.toast(l.voiceNotHeard);
      return;
    }
    _q.text = heard;
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    if (app.version != _cacheVersion && _q.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l.search),
        actions: [
          if (app.beats.length > 1)
            Row(
              children: [
                Text(l.allBeats, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                Switch(
                  value: _allBeats,
                  onChanged: (v) {
                    setState(() => _allBeats = v);
                    _run();
                  },
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              autofocus: !widget.startWithVoice,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: const Icon(Icons.search, size: 28),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_q.text.isNotEmpty)
                      IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _q.clear();
                          setState(() => _ids = []);
                        },
                      ),
                    IconButton(
                      tooltip: l.voiceInput,
                      icon: Icon(_listening ? Icons.graphic_eq : Icons.mic, size: 28),
                      onPressed: _listening ? null : _voice,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _q.text.trim().isEmpty
                ? EmptyState(icon: Icons.manage_search, text: l.searchTips)
                : _ids.isEmpty
                ? EmptyState(icon: Icons.search_off, text: l.noResults)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: _ids.length,
                    itemBuilder: (c, i) {
                      final d = _cache[_ids[i]]!;
                      return PlaceCard(
                        key: ValueKey(d.place.id),
                        details: d,
                        here: here,
                        heading: heading,
                        pickLabel: widget.pickLabel,
                        onPick: widget.pickMode ? () => Navigator.pop(context, d.place.id) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

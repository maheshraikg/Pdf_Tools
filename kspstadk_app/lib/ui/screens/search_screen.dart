import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/site_config.dart';
import '../../data/wp_api.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'post_list_screen.dart';

/// WordPress search with debounce, recent searches and category filters.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  Concept? _filter;

  void focus() => _focus.requestFocus();

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _submit(String v) {
    _debounce?.cancel();
    setState(() => _query = v.trim());
    context.app.settings.addRecentSearch(v);
  }

  void _useRecent(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _submit(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final app = context.app;
    final locale = Localizations.localeOf(context);
    final filters = [...app.config.tiles];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: l.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l.clear,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _controller.clear();
                      _query = '';
                    }),
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(label: Text(l.filterAll), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                ),
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f.label(locale)),
                      selected: _filter == f,
                      selectedColor: f.color?.withValues(alpha: .18),
                      onSelected: (_) => setState(() => _filter = _filter == f ? null : f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? ListenableBuilder(
                    listenable: app.settings,
                    builder: (context, _) {
                      final recent = app.settings.recentSearches;
                      if (recent.isEmpty) {
                        return EmptyState(icon: Icons.manage_search_rounded, title: l.navSearch, subtitle: l.searchPrompt);
                      }
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(children: [
                            Expanded(child: Text(l.recentSearches, style: t.textTheme.titleSmall)),
                            TextButton(onPressed: app.settings.clearRecentSearches, child: Text(l.clear)),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final q in recent)
                              ActionChip(avatar: const Icon(Icons.history_rounded, size: 18), label: Text(q), onPressed: () => _useRecent(q)),
                          ]),
                        ],
                      );
                    },
                  )
                : PagedPostList(
                    key: ValueKey('$_query|${_filter?.key}'),
                    query: WpApi.postsQuery(search: _query, categories: _filter?.ids),
                    heroPrefix: 'search',
                    emptyBuilder: (context) => EmptyState(icon: Icons.search_off_rounded, title: l.noResults, subtitle: l.searchPrompt),
                  ),
          ),
        ],
      ),
    );
  }
}

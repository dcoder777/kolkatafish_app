import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/seafood_data.dart';
import '../models/sea_product.dart';
import '../widgets/paged_product_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SeaProduct> get _fallbackItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return seafoodProducts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  void _submit(String value) {
    setState(() => _query = value);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _submit,
          onChanged: (value) => setState(() => _query = value),
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search fish, meat, prawns...',
            hintStyle: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? _buildSuggestions(theme)
          : PagedProductGrid(
              key: ValueKey(_query.trim()),
              search: _query.trim(),
              fallbackItems: _fallbackItems,
              emptyMessage: 'No results for "${_query.trim()}"',
            ),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    final suggestions = [
      'Rui',
      'Catla',
      'Chingri',
      'Ilish',
      'Chicken',
      'Mutton',
      'Prawns',
      'Bhetki',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'POPULAR SEARCHES',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (s) => ActionChip(
                  label: Text(s, style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  onPressed: () {
                    _controller.text = s;
                    _submit(s);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

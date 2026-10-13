import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sea_product.dart';
import '../services/store_api_service.dart';
import 'product_card.dart';
import '../screens/product_detail_screen.dart';

/// Grid of products that loads from the live store one page at a time.
///
/// Shows a running count, a "Load more items" button and infinite scroll,
/// and falls back to [fallbackItems] when the network is unavailable.
class PagedProductGrid extends StatefulWidget {
  /// When set, only products of this category are loaded.
  final String? categoryName;

  /// Free-text search applied on the store.
  final String? search;

  /// Static items used when the API cannot be reached.
  final List<SeaProduct> fallbackItems;

  /// Whether to show the "X of Y items" line above the grid.
  final bool showCount;

  final String emptyMessage;

  const PagedProductGrid({
    super.key,
    this.categoryName,
    this.search,
    this.fallbackItems = const [],
    this.showCount = true,
    this.emptyMessage = 'No products found',
  });

  @override
  State<PagedProductGrid> createState() => _PagedProductGridState();
}

class _PagedProductGridState extends State<PagedProductGrid> {
  static const int _perPage = 12;

  final List<SeaProduct> _items = [];
  final ScrollController _scrollController = ScrollController();
  final StoreApiService _service = StoreApiService();

  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _failed = false;
  bool _staticMode = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  bool get _hasMore => !_staticMode && _page <= _totalPages;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels == _lastOffset) return;
    _lastOffset = position.pixels;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final result = widget.categoryName != null
          ? await _service.fetchCategoryProducts(
              categoryName: widget.categoryName!,
              page: _page,
              perPage: _perPage,
            )
          : await _service.fetchProducts(
              page: _page,
              perPage: _perPage,
              search: widget.search,
            );

      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _total = result.total;
        _totalPages = result.totalPages < 1 ? 1 : result.totalPages;
        _page += 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _useFallback();
        } else {
          _failed = true;
        }
      });
    }
  }

  void _useFallback() {
    _staticMode = true;
    _items.addAll(widget.fallbackItems);
    _total = _items.length;
    _totalPages = 1;
    _page = 2;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCount)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              _staticMode || _total == 0
                  ? '${_items.length} item${_items.length == 1 ? '' : 's'}'
                  : '${_items.length} of $_total items',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
          ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.58,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final product = _items[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            },
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _footer() {
    if (_staticMode) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _failed
              ? Center(
                  child: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      'Could not load more - tap to retry',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                )
              : _hasMore
                  ? Center(
                      child: ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text(
                          'Load more items',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF55D2C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'You have seen all $_total items',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
    );
  }
}

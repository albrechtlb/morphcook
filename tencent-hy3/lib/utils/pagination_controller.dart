enum PaginationType { cursor, offset, timeBased, weekly }

class PaginationController<T> {
  final int pageSize;
  final int prefetchThreshold;
  final int maxRendered;
  final PaginationType type;

  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _nextCursor;
  int _currentOffset = 0;

  final Function(PaginationController<T>) onLoadMore;

  PaginationController({
    required this.pageSize,
    required this.prefetchThreshold,
    required this.maxRendered,
    required this.type,
    required this.onLoadMore,
  });

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isEmpty => _items.isEmpty;

  void initialize(List<T> initialItems) {
    _items = initialItems.take(maxRendered).toList();
    _hasMore = initialItems.length > maxRendered;
  }

  bool shouldLoadMore(int index) {
    if (!_hasMore || _isLoading) return false;
    return index >= _items.length - prefetchThreshold;
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    await onLoadMore(this);
    _isLoading = false;
  }

  void appendItems(List<T> newItems) {
    _items.addAll(newItems.take(maxRendered - _items.length));
    _hasMore = newItems.isNotEmpty && _items.length < maxRendered;
  }

  void refresh() {
    _items.clear();
    _hasMore = true;
    _nextCursor = null;
    _currentOffset = 0;
  }

  void reset() {
    _items.clear();
    _isLoading = false;
    _hasMore = true;
    _nextCursor = null;
    _currentOffset = 0;
  }
}

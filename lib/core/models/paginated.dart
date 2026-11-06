class PageMeta {
  const PageMeta({required this.page, required this.pageSize, required this.totalPages});

  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// One page of a list endpoint.
typedef PageResult<T> = ({List<T> items, bool hasMore});

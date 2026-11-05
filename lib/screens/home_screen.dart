import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_services.dart';
import 'add_post_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _service = PostService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Post>> _future;
  List<Post> _posts = [];
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _future = _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Post>> _loadPosts() async {
    final result = await _service.fetchPosts();
    _posts = result;
    return result;
  }

  void _retry() {
    setState(() {
      _future = _loadPosts();
    });
  }

  Future<void> _refresh() async {
    final newFuture = _loadPosts();
    setState(() {
      _future = newFuture;
    });
    try {
      await newFuture;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  Future<void> _openAddPost() async {
    final created = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => const AddPostScreen()),
    );

    if (created != null && mounted) {
      // JSONPlaceholder tidak menyimpan data, jadi kita tampilkan secara lokal.
      setState(() {
        _posts = [created, ..._posts];
        _future = Future.value(_posts);
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Pengumuman berhasil dibuat')),
              ],
            ),
          ),
        );
    }
  }

  void _openDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(post: post)),
    );
  }

  List<Post> _visiblePosts(List<Post> posts) {
    final query = _searchController.text.trim().toLowerCase();
    final results = posts.where((post) {
      return query.isEmpty ||
          post.displayTitle.toLowerCase().contains(query) ||
          post.body.toLowerCase().contains(query) ||
          post.userId.toString().contains(query);
    }).toList();
    results.sort(
      (a, b) => _newestFirst ? b.id.compareTo(a.id) : a.id.compareTo(b.id),
    );
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1040;
            return Row(
              children: [
                if (isWide) _DesktopSidebar(onCreate: _openAddPost),
                Expanded(
                  child: FutureBuilder<List<Post>>(
                    future: _future,
                    builder: (context, snapshot) {
                      final posts = snapshot.data ?? _posts;
                      final visiblePosts = _visiblePosts(posts);
                      final authors = posts.map((post) => post.userId).toSet();

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 42 : 20,
                                isWide ? 36 : 18,
                                isWide ? 42 : 20,
                                40,
                              ),
                              children: [
                                if (!isWide) const _MobileTopbar(),
                                _Header(
                                  totalCount: posts.length,
                                  authorCount: authors.length,
                                  onCreate: _openAddPost,
                                ),
                                const SizedBox(height: 22),
                                _StatsStrip(
                                  totalCount: posts.length,
                                  authorCount: authors.length,
                                ),
                                const SizedBox(height: 30),
                                _SearchTools(
                                  controller: _searchController,
                                  newestFirst: _newestFirst,
                                  onSearchChanged: (_) => setState(() {}),
                                  onSortChanged: (value) => setState(
                                    () => _newestFirst = value,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _SectionHeading(
                                  count: visiblePosts.length,
                                  isSearching:
                                      _searchController.text.trim().isNotEmpty,
                                ),
                                const SizedBox(height: 12),
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const _LoadingView()
                                else if (snapshot.hasError)
                                  _ErrorView(
                                    message: PostException.messageOf(
                                      snapshot.error!,
                                    ),
                                    onRetry: _retry,
                                  )
                                else if (posts.isEmpty)
                                  _EmptyView(onCreate: _openAddPost)
                                else if (visiblePosts.isEmpty)
                                  _NoResults(
                                    onClear: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                else
                                  ...visiblePosts.map(
                                    (post) => _PostCard(
                                      post: post,
                                      onTap: () => _openDetail(post),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget pendukung
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final int totalCount;
  final int authorCount;
  final VoidCallback onCreate;

  const _Header({
    required this.totalCount,
    required this.authorCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF173F37),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF24564B)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8EF91),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: 17,
                      color: Color(0xFF173F37),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'PUSAT INFORMASI',
                    style: TextStyle(
                      color: Color(0xFFD8EF91),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Informasi penting,\ntersusun rapi.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$totalCount pengumuman dari $authorCount penulis. Cari yang kamu perlukan atau bagikan informasi baru.',
                style: const TextStyle(
                  color: Color(0xFFD2E0DA),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 24),
                    _CreateButton(onPressed: onCreate, light: true),
                  ],
                )
              else ...[
                intro,
                const SizedBox(height: 20),
                _CreateButton(onPressed: onCreate, light: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MobileTopbar extends StatelessWidget {
  const _MobileTopbar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          _BrandMark(),
          Spacer(),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF17594F),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.campaign_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'NusaInfo',
          style: TextStyle(
            color: Color(0xFF1E302C),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final VoidCallback onCreate;

  const _DesktopSidebar({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFDCE5DE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 44),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              'RUANG KERJA',
              style: TextStyle(
                color: Color(0xFF84918B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2E9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              children: [
                Icon(Icons.dashboard_rounded,
                    size: 18, color: Color(0xFF17594F)),
                SizedBox(width: 11),
                Text(
                  'Pengumuman',
                  style: TextStyle(
                    color: Color(0xFF17594F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tulis pengumuman'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: const Color(0xFF344A42),
                side: const BorderSide(color: Color(0xFFDCE5DE)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFF60736B)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Temukan kabar terbaru dari komunitasmu.',
                    style: TextStyle(
                      color: Color(0xFF60736B),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool light;

  const _CreateButton({required this.onPressed, this.light = false});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_rounded, size: 17),
      label: const Text('Buat Pengumuman'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor:
            light ? const Color(0xFFD8EF91) : const Color(0xFF17594F),
        foregroundColor: light ? const Color(0xFF173F37) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int totalCount;
  final int authorCount;

  const _StatsStrip({required this.totalCount, required this.authorCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'PENGUMUMAN',
              value: '$totalCount',
              icon: Icons.article_outlined,
            ),
          ),
          Container(width: 1, height: 38, color: const Color(0xFFDCE5DE)),
          Expanded(
            child: _StatItem(
              label: 'KONTRIBUTOR',
              value: '$authorCount',
              icon: Icons.people_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF568075)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718079),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E302C),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchTools extends StatelessWidget {
  final TextEditingController controller;
  final bool newestFirst;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onSortChanged;

  const _SearchTools({
    required this.controller,
    required this.newestFirst,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari judul, isi, atau penulis...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Text(
              'URUTKAN',
              style: TextStyle(
                color: Color(0xFF718079),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const Spacer(),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Terbaru')),
                ButtonSegment(value: false, label: Text('Terlama')),
              ],
              selected: {newestFirst},
              onSelectionChanged: (selection) => onSortChanged(selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final int count;
  final bool isSearching;

  const _SectionHeading({required this.count, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSearching ? 'Hasil pencarian' : 'Semua pengumuman',
                style: const TextStyle(
                  color: Color(0xFF1E302C),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count informasi tersedia',
                style: const TextStyle(color: Color(0xFF718079), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = switch (post.id % 3) {
      0 => const Color(0xFFE28B5B),
      1 => const Color(0xFF347A78),
      _ => const Color(0xFF829B48),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'INFO  /  ${post.id.toString().padLeft(3, '0')}',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: Color(0xFF84918B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Penulis #${post.userId}',
                            style: const TextStyle(
                              color: Color(0xFF718079),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E302C),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.body.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718079),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Baca pengumuman',
                            style: TextStyle(
                              color: Color(0xFF17594F),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: Color(0xFF17594F),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Memuat pengumuman...',
            style: TextStyle(color: Color(0xFF718079), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 38, color: Color(0xFF789087)),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pengumuman',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E302C),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mulai bagikan informasi pertama untuk komunitasmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF718079), fontSize: 13),
          ),
          const SizedBox(height: 18),
          _CreateButton(onPressed: onCreate),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 38,
            color: Color(0xFF789087),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada hasil yang cocok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E302C),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci lain atau hapus pencarian.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF718079), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 17),
            label: const Text('Hapus pencarian'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Oops, ada masalah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E302C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718079),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(160, 48),
            ),
          ),
        ],
      ),
    );
  }
}

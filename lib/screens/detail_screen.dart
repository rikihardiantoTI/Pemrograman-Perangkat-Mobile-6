import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_services.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PostService _service = PostService();
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    // Future dipanggil di initState(), bukan di build().
    _commentsFuture = _service.fetchComments(widget.post.id);
  }

  void _retry() {
    setState(() {
      _commentsFuture = _service.fetchComments(widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Kembali ke daftar',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail pengumuman',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF1E302C),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Pusat informasi NusaInfo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF718079),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFDCE5DE)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 48),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF173F37),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Chip(
                                    icon: Icons.campaign_rounded,
                                    label:
                                        'PENGUMUMAN #${post.id.toString().padLeft(3, '0')}',
                                    color: const Color(0xFFD8EF91),
                                  ),
                                  _Chip(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Penulis #${post.userId}',
                                    color: const Color(0xFFD2E0DA),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                post.displayTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'ISI PENGUMUMAN',
                          style: TextStyle(
                            color: Color(0xFF718079),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .9,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post.body,
                          style: const TextStyle(
                            color: Color(0xFF344A42),
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 34),
                        const Divider(height: 1, color: Color(0xFFDCE5DE)),
                        const SizedBox(height: 28),
                        FutureBuilder<List<Comment>>(
                          future: _commentsFuture,
                          builder: (context, snapshot) {
                            final comments = snapshot.data ?? const <Comment>[];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Diskusi dan tanggapan',
                                        style: TextStyle(
                                          color: Color(0xFF1E302C),
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF2E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        snapshot.connectionState ==
                                                ConnectionState.waiting
                                            ? '...'
                                            : '${comments.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF17594F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const _CommentsLoading()
                                else if (snapshot.hasError)
                                  _CommentsError(
                                    message: PostException.messageOf(
                                      snapshot.error!,
                                    ),
                                    onRetry: _retry,
                                  )
                                else if (comments.isEmpty)
                                  const _NoComments()
                                else
                                  ...comments.map(
                                    (comment) => _CommentCard(comment: comment),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsLoading extends StatelessWidget {
  const _CommentsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            'Memuat tanggapan...',
            style: TextStyle(color: Color(0xFF718079), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NoComments extends StatelessWidget {
  const _NoComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5DE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined, size: 28, color: Color(0xFF789087)),
          SizedBox(height: 8),
          Text(
            'Belum ada tanggapan',
            style: TextStyle(
              color: Color(0xFF344A42),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tanggapan yang tersedia akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF718079), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final initial =
        comment.email.isEmpty ? '?' : comment.email[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFDCE5DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2E9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF17594F),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E302C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718079),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.body.replaceAll('\n', ' '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF52645C),
                    height: 1.6,
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

class _CommentsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommentsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 32, color: Color(0xFFDC2626)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7F1D1D), height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_services.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key, this.service});

  final PostService? service;

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updatePreview);
    _bodyController.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_updatePreview);
    _bodyController.removeListener(_updatePreview);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final newPost = Post(
        id: 0,
        userId: 1,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      final created = await (widget.service ?? PostService()).createPost(
        newPost,
      );

      if (!mounted) return;
      // Kirim hasilnya kembali ke Home Screen.
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(PostException.messageOf(e))),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'Kembali',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tulis pengumuman',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF1E302C),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Bagikan informasi dengan jelas',
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
                  if (MediaQuery.of(context).size.width >= 600) ...[
                    const SizedBox(width: 12),
                    const _EditorStatus(),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFDCE5DE)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final editor = Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi utama',
                          style: TextStyle(
                            color: Color(0xFF1E302C),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Isi detail pengumuman yang akan dilihat pembaca.',
                          style: TextStyle(
                            color: Color(0xFF718079),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('Judul pengumuman'),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 90,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Jadwal Libur Semester',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Judul wajib diisi';
                            if (text.length < 5) {
                              return 'Judul minimal 5 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Isi pengumuman'),
                        TextFormField(
                          controller: _bodyController,
                          enabled: !_isSubmitting,
                          minLines: 8,
                          maxLines: 14,
                          maxLength: 1200,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText:
                                'Jelaskan informasi, waktu, dan hal penting lainnya...',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 128),
                              child: Icon(Icons.subject_rounded),
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Isi pengumuman wajib diisi';
                            }
                            if (text.length < 10) {
                              return 'Isi pengumuman minimal 10 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSubmitting
                                ? 'Mengirim pengumuman...'
                                : 'Terbitkan pengumuman',
                          ),
                        ),
                      ],
                    ),
                  );

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: editor),
                                  const SizedBox(width: 48),
                                  SizedBox(
                                    width: 320,
                                    child: _LivePreview(
                                      title: _titleController.text,
                                      body: _bodyController.text,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  editor,
                                  const SizedBox(height: 32),
                                  _LivePreview(
                                    title: _titleController.text,
                                    body: _bodyController.text,
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
        ),
      ),
    );
  }
}

class _EditorStatus extends StatelessWidget {
  const _EditorStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFF17594F)),
          SizedBox(width: 5),
          Text(
            'EDITOR',
            style: TextStyle(
              color: Color(0xFF17594F),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String title;
  final String body;

  const _LivePreview({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRATINJAU',
          style: TextStyle(
            color: Color(0xFF718079),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .9,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE5DE)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded,
                      size: 16, color: Color(0xFF17594F)),
                  SizedBox(width: 7),
                  Text(
                    'PENGUMUMAN',
                    style: TextStyle(
                      color: Color(0xFF17594F),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title.trim().isEmpty ? 'Judul pengumuman' : title.trim(),
                style: const TextStyle(
                  color: Color(0xFF1E302C),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFDCE5DE)),
              const SizedBox(height: 12),
              Text(
                body.trim().isEmpty
                    ? 'Isi pengumuman akan tampil di area ini.'
                    : body.trim(),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF60736B),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Color(0xFFEAF2E9),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: Color(0xFF17594F),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Penulis #1',
                    style: TextStyle(
                      color: Color(0xFF718079),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E302C),
        ),
      ),
    );
  }
}

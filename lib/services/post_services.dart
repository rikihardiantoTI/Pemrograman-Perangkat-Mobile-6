import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/post.dart';

/// Exception dengan pesan yang ramah untuk ditampilkan ke pengguna.
class PostException implements Exception {
  final String message;
  const PostException(this.message);

  @override
  String toString() => message;

  /// Mengubah error apa pun menjadi pesan yang aman ditampilkan.
  static String messageOf(Object error) {
    if (error is PostException) return error.message;
    return 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
  }
}

/// Semua request HTTP ada di sini.
/// Urutan tiap request: buat alamat -> kirim request -> cek status code
/// -> ubah JSON menjadi objek.
class PostService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _timeout = Duration(seconds: 10);

  /// GET /posts
  Future<List<Post>> fetchPosts() async {
    // 1. Buat alamat
    final uri = Uri.parse('$_baseUrl/posts');
    // 2. Kirim request
    final response = await _send(() => http.get(uri));
    // 3. Cek status code
    _checkStatus(response, 200);
    // 4. Ubah JSON menjadi objek
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /posts/{id}/comments
  Future<List<Comment>> fetchComments(int postId) async {
    final uri = Uri.parse('$_baseUrl/posts/$postId/comments');
    final response = await _send(() => http.get(uri));
    _checkStatus(response, 200);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /posts
  Future<Post> createPost(Post post) async {
    final uri = Uri.parse('$_baseUrl/posts');
    final response = await _send(
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(post.toJson()),
      ),
    );
    _checkStatus(response, 201);
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Menjalankan request dan menerjemahkan error jaringan ke pesan yang jelas.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException {
      throw const PostException(
        'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.',
      );
    } on TimeoutException {
      throw const PostException(
        'Server terlalu lama merespons. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const PostException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const PostException('Data dari server tidak dapat dibaca.');
    }
  }

  void _checkStatus(http.Response response, int expected) {
    if (response.statusCode != expected) {
      throw PostException(
        'Server mengembalikan kode ${response.statusCode}. Silakan coba lagi.',
      );
    }
  }
}
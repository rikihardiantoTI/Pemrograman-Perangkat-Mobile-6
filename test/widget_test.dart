// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nusa_info/models/post.dart';
import 'package:nusa_info/main.dart';
import 'package:nusa_info/screens/add_post_screen.dart';
import 'package:nusa_info/screens/detail_screen.dart';
import 'package:nusa_info/screens/home_screen.dart';
import 'package:nusa_info/services/post_services.dart';

Future<void> _loadScreenshotFonts() async {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path) {
    final fontDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}bin${Platform.pathSeparator}'
      'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts',
    );
    if (fontDirectory.existsSync()) {
      await _loadFont(
        'Roboto',
        File(
            '${fontDirectory.path}${Platform.pathSeparator}roboto-regular.ttf'),
      );
      await _loadFont(
        'MaterialIcons',
        File(
          '${fontDirectory.path}${Platform.pathSeparator}'
          'materialicons-regular.otf',
        ),
      );
      return;
    }
    directory = directory.parent;
  }
  throw StateError('Flutter SDK material fonts were not found.');
}

Future<void> _loadFont(String family, File file) async {
  final fontData = ByteData.sublistView(await file.readAsBytes());
  await (services.FontLoader(family)..addFont(Future.value(fontData))).load();
}

Future<void> _captureScreenshot(String filename) async {
  await expectLater(
    find.byKey(const ValueKey('screenshot-boundary')),
    matchesGoldenFile('screenshots/$filename'),
  );
}

void main() {
  setUpAll(_loadScreenshotFonts);

  testWidgets('NusaInfo app shows its home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NusaInfoApp());

    expect(find.text('NusaInfo'), findsOneWidget);
    expect(find.text('Buat Pengumuman'), findsOneWidget);
    expect(find.text('Cari judul, isi, atau penulis...'), findsOneWidget);
  });

  testWidgets('NusaInfo shows desktop navigation on wide screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NusaInfoApp());

    expect(find.text('RUANG KERJA'), findsOneWidget);
    expect(find.text('Tulis pengumuman'), findsOneWidget);
  });

  testWidgets('announcement editor fits a mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AddPostScreen()));

    expect(find.text('Tulis pengumuman'), findsOneWidget);
    expect(find.text('PRATINJAU'), findsOneWidget);
  });

  testWidgets('announcement detail fits a mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const post = Post(
      id: 12,
      userId: 3,
      title: 'Informasi kegiatan komunitas',
      body: 'Kegiatan akan dimulai pada hari Sabtu pukul sembilan pagi.',
    );
    await tester.pumpWidget(const MaterialApp(home: DetailScreen(post: post)));

    expect(find.text('Informasi kegiatan komunitas'), findsOneWidget);
    expect(find.text('Diskusi dan tanggapan'), findsOneWidget);
  });

  testWidgets('offline announcement shows an error and captures screenshot', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = PostService(
      client: MockClient(
        (_) async => throw const SocketException('No internet connection'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('screenshot-boundary'),
          child: AddPostScreen(service: service),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Informasi pemeliharaan',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Sistem akan diperbarui pada malam ini.',
    );
    await tester.ensureVisible(find.text('Terbitkan pengumuman'));
    await tester.tap(find.text('Terbitkan pengumuman'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.',
      ),
      findsOneWidget,
    );
    await _captureScreenshot('offline-error.png');
  });

  testWidgets(
    'successful announcement shows a SnackBar and captures screenshot',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = PostService(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('[]', 200);
          }
          return http.Response(
            jsonEncode({
              'id': 101,
              'userId': 1,
              'title': 'Informasi pemeliharaan',
              'body': 'Sistem akan diperbarui pada malam ini.',
            }),
            201,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('screenshot-boundary'),
            child: HomeScreen(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat Pengumuman').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Informasi pemeliharaan',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Sistem akan diperbarui pada malam ini.',
      );
      await tester.ensureVisible(find.text('Terbitkan pengumuman'));
      await tester.tap(find.text('Terbitkan pengumuman'));
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman berhasil dibuat'), findsOneWidget);
      await _captureScreenshot('announcement-created-snackbar.png');
    },
  );
}

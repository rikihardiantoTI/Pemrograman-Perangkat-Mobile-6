// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nusa_info/models/post.dart';
import 'package:nusa_info/main.dart';
import 'package:nusa_info/screens/add_post_screen.dart';
import 'package:nusa_info/screens/detail_screen.dart';

void main() {
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
}

// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_supabase/otel_supabase.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_supabase-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span span) {
    return {for (final a in span.attributes.toList()) a.key: a.value};
  }

  group('tracedSupabaseAuth', () {
    test('emits a CLIENT span with supabase.auth.* attrs', () async {
      final res = await tracedSupabaseAuth<String>(
        operation: 'signInWithPassword',
        email: 'ada@example.com',
        invoke: () async => 'token-abc',
      );
      expect(res, 'token-abc');
      final span = spans.findSpanByName('supabase.auth signInWithPassword');
      expect(span, isNotNull);
      expect(span!.kind, SpanKind.client);
      final a = attrsOf(span);
      expect(a['supabase.auth.operation'], 'signInWithPassword');
      expect(a['user.email'], 'ada@example.com');
    });

    test('OAuth flow records provider', () async {
      await tracedSupabaseAuth<String>(
        operation: 'signInWithOAuth',
        provider: 'google',
        invoke: () async => 'ok',
      );
      final span = spans.findSpanByName('supabase.auth signInWithOAuth');
      expect(attrsOf(span!)['supabase.auth.provider'], 'google');
    });

    test('records exception on throw', () async {
      await expectLater(
        tracedSupabaseAuth<String>(
          operation: 'signInWithPassword',
          invoke: () async => throw StateError('bad password'),
        ),
        throwsA(isA<StateError>()),
      );
      final span = spans.findSpanByName('supabase.auth signInWithPassword');
      expect(span!.status, SpanStatusCode.Error);
      expect(attrsOf(span)['error.type'], 'StateError');
    });
  });

  group('tracedSupabaseDb', () {
    test('emits a CLIENT span with db.* + supabase.db.* attrs', () async {
      await tracedSupabaseDb<List<Map<String, dynamic>>>(
        table: 'orders',
        operation: 'select',
        statement: 'SELECT * FROM orders WHERE user_id = \$1',
        invoke: () async => const <Map<String, dynamic>>[],
      );
      final span = spans.findSpanByName('supabase.db select orders');
      expect(span, isNotNull);
      final a = attrsOf(span!);
      expect(a['db.system'], 'postgresql');
      expect(a['db.operation'], 'select');
      expect(a['db.collection.name'], 'orders');
      expect(a['supabase.db.table'], 'orders');
      expect(a['supabase.db.operation'], 'select');
      expect(a['db.statement'], contains('SELECT * FROM orders'));
    });
  });

  group('tracedSupabaseStorage', () {
    test('emits a CLIENT span with supabase.storage.* attrs', () async {
      await tracedSupabaseStorage<String>(
        bucket: 'avatars',
        operation: 'upload',
        path: 'user-42.png',
        sizeBytes: 2048,
        invoke: () async => 'avatars/user-42.png',
      );
      final span = spans.findSpanByName('supabase.storage upload avatars');
      expect(span, isNotNull);
      final a = attrsOf(span!);
      expect(a['supabase.storage.bucket'], 'avatars');
      expect(a['supabase.storage.operation'], 'upload');
      expect(a['supabase.storage.path'], 'user-42.png');
      expect(a['http.request.body.size'], 2048);
    });
  });

  group('tracedSupabaseFunction', () {
    test('emits a CLIENT span naming the Edge Function', () async {
      await tracedSupabaseFunction<String>(
        functionName: 'enrich-order',
        invoke: () async => 'ok',
      );
      final span = spans.findSpanByName('supabase.function enrich-order');
      expect(span, isNotNull);
      expect(attrsOf(span!)['supabase.function.name'], 'enrich-order');
    });
  });

  group('zone-scoped suppression', () {
    test('skips spans across all 4 helpers', () async {
      await runWithoutSupabaseInstrumentationAsync(() async {
        await tracedSupabaseAuth<String>(
          operation: 'signOut',
          invoke: () async => 'ok',
        );
        await tracedSupabaseDb<int>(
          table: 'x',
          operation: 'select',
          invoke: () async => 0,
        );
        await tracedSupabaseStorage<int>(
          bucket: 'b',
          operation: 'list',
          invoke: () async => 0,
        );
        await tracedSupabaseFunction<int>(
          functionName: 'f',
          invoke: () async => 0,
        );
      });
      expect(spans.findSpansStartingWith('supabase.'), isEmpty);
    });
  });
}

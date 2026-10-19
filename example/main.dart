// Licensed under the MIT License.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_supabase/otel_supabase.dart';

/// Traces Supabase Auth (GoTrue) calls with OpenTelemetry.
///
/// `otel_supabase` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Supabase Auth (GoTrue) call in
/// [tracedSupabaseAuth]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'supabase-example');

  // Wraps a Supabase Auth (GoTrue) call in a CLIENT span.
  final supabaseAuthId = await tracedSupabaseAuth<String>(
    operation: 'signInWithPassword',
    email: 'ada@example.com',
    provider: 'example',
    userId: 'user_8f3a2c',
    invoke: () async {
      // Make the Supabase Auth (GoTrue) call here, then report what it returned.
      return 'supabase_8f3a2c';
    },
  );
  OTelLog.info(
      'tracedSupabaseAuth signInWithPassword returned $supabaseAuthId');

  // Wraps a Postgrest (Supabase database) call in a CLIENT span carrying db.system=postgresql plus supabase.db.* attributes.
  final supabaseDbId = await tracedSupabaseDb<String>(
    table: 'orders',
    operation: 'create',
    statement: 'active',
    invoke: () async {
      // Make the Supabase Auth (GoTrue) call here, then report what it returned.
      return 'supabase_8f3a2c';
    },
  );
  OTelLog.info('tracedSupabaseDb create returned $supabaseDbId');

  // Wraps a Supabase Storage call in a CLIENT span.
  final supabaseStorageId = await tracedSupabaseStorage<String>(
    bucket: 'invoices',
    operation: 'create',
    path: '/v1/orders',
    sizeBytes: 512,
    invoke: () async {
      // Make the Supabase Auth (GoTrue) call here, then report what it returned.
      return 'supabase_8f3a2c';
    },
  );
  OTelLog.info('tracedSupabaseStorage create returned $supabaseStorageId');

  // Wraps a Supabase Edge Functions invocation in a CLIENT span.
  final supabaseFunctionId = await tracedSupabaseFunction<String>(
    functionName: 'example',
    invoke: () async {
      // Make the Supabase Auth (GoTrue) call here, then report what it returned.
      return 'supabase_8f3a2c';
    },
  );
  OTelLog.info('tracedSupabaseFunction returned $supabaseFunctionId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSupabaseInstrumentationAsync.
  await runWithoutSupabaseInstrumentationAsync(
    () => tracedSupabaseAuth<String>(
      operation: 'signInWithPassword',
      email: 'ada@example.com',
      provider: 'example',
      userId: 'user_8f3a2c',
      invoke: () async {
        return 'supabase_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}

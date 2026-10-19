// Licensed under the MIT License.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_supabase_suppression.dart';
import 'supabase_semantics.dart';

const _tracerName = 'dartastic_otel_libs_supabase';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Supabase Auth (GoTrue) call in a CLIENT span.
///
/// `supabase_flutter`'s `GoTrueClient` exposes a long list of
/// auth methods (`signInWithPassword`, `signUp`, `signInWithIdToken`,
/// `signInWithOtp`, `signOut`, etc.). This callback-shaped helper
/// works for all of them — pass the operation name and your call:
///
/// ```dart
/// final response = await tracedSupabaseAuth<AuthResponse>(
///   operation: 'signInWithPassword',
///   email: email,
///   invoke: () => supabase.auth.signInWithPassword(
///     email: email,
///     password: password,
///   ),
/// );
/// ```
///
/// The bridge emits a `supabase.auth signInWithPassword` CLIENT span
/// with `supabase.auth.operation`, optional provider/email/user-id
/// attributes, and exception capture on failures.
Future<T> tracedSupabaseAuth<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? email,
  String? provider,
  String? userId,
}) async {
  if (supabaseInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'supabase.auth $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap({
      SupabaseBridgeSemantics.authOperation.key: operation,
      if (provider != null) SupabaseBridgeSemantics.authProvider.key: provider,
      if (email != null) User.userEmail.key: email,
      if (userId != null) User.userId.key: userId,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    _markError(span, e, st);
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Postgrest (Supabase database) call in a CLIENT span
/// carrying `db.system=postgresql` plus `supabase.db.*` attributes.
///
/// ```dart
/// final rows = await tracedSupabaseDb<List<Map<String, dynamic>>>(
///   table: 'orders',
///   operation: 'select',
///   invoke: () => supabase.from('orders').select().eq('user_id', uid),
/// );
/// ```
Future<T> tracedSupabaseDb<T>({
  required String table,
  required String operation,
  required Future<T> Function() invoke,
  String? statement,
}) async {
  if (supabaseInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'supabase.db $operation $table',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap({
      'db.system': 'postgresql',
      'db.operation': operation,
      'db.namespace': 'public',
      'db.collection.name': table,
      SupabaseBridgeSemantics.dbTable.key: table,
      SupabaseBridgeSemantics.dbOperation.key: operation,
      if (statement != null) 'db.statement': statement,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    _markError(span, e, st);
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Supabase Storage call in a CLIENT span.
///
/// ```dart
/// final url = await tracedSupabaseStorage<String>(
///   bucket: 'avatars',
///   path: 'user-42.png',
///   operation: 'upload',
///   invoke: () => supabase.storage.from('avatars').upload(
///     'user-42.png',
///     file,
///   ),
/// );
/// ```
Future<T> tracedSupabaseStorage<T>({
  required String bucket,
  required String operation,
  required Future<T> Function() invoke,
  String? path,
  int? sizeBytes,
}) async {
  if (supabaseInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'supabase.storage $operation $bucket',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap({
      SupabaseBridgeSemantics.storageBucket.key: bucket,
      SupabaseBridgeSemantics.storageOperation.key: operation,
      if (path != null) SupabaseBridgeSemantics.storagePath.key: path,
      if (sizeBytes != null) 'http.request.body.size': sizeBytes,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    _markError(span, e, st);
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Supabase Edge Functions invocation in a CLIENT span.
///
/// ```dart
/// final res = await tracedSupabaseFunction<FunctionResponse>(
///   functionName: 'enrich-order',
///   invoke: () => supabase.functions.invoke(
///     'enrich-order',
///     body: {'orderId': 42},
///   ),
/// );
/// ```
Future<T> tracedSupabaseFunction<T>({
  required String functionName,
  required Future<T> Function() invoke,
}) async {
  if (supabaseInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'supabase.function $functionName',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap({
      SupabaseBridgeSemantics.functionName.key: functionName,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    _markError(span, e, st);
    rethrow;
  } finally {
    span.end();
  }
}

void _markError(APISpan span, Object e, StackTrace st) {
  span.addAttributes(
    OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]),
  );
  span.recordException(e, stackTrace: st);
  span.setStatus(SpanStatusCode.Error, e.toString());
}

// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

/// Attribute keys for the Supabase → OTel bridge.
///
/// Where OTel has an established semconv (`db.*` for postgrest,
/// `messaging.*` for realtime, `enduser.*` for user identity), the
/// bridge uses those keys directly. The `supabase.*` keys below
/// cover Supabase-specific concepts.
enum SupabaseBridgeSemantics implements OTelSemantic {
  /// `supabase.auth.operation` — `signInWithPassword`, `signUp`,
  /// `signOut`, `signInWithIdToken`, `signInWithOtp`, etc.
  authOperation('supabase.auth.operation'),

  /// `supabase.auth.provider` — for OAuth flows: `google`, `github`,
  /// `apple`, etc. Mirrors `OAuthProvider` enum.
  authProvider('supabase.auth.provider'),

  /// `supabase.db.table` — Postgrest table name.
  dbTable('supabase.db.table'),

  /// `supabase.db.operation` — Postgrest verb: `select`, `insert`,
  /// `update`, `upsert`, `delete`, `rpc`.
  dbOperation('supabase.db.operation'),

  /// `supabase.storage.bucket` — Supabase Storage bucket name.
  storageBucket('supabase.storage.bucket'),

  /// `supabase.storage.path` — object key inside the bucket.
  storagePath('supabase.storage.path'),

  /// `supabase.storage.operation` — `upload`, `download`, `remove`,
  /// `list`, `getPublicUrl`, `createSignedUrl`.
  storageOperation('supabase.storage.operation'),

  /// `supabase.function.name` — Edge Function slug being invoked.
  functionName('supabase.function.name');

  const SupabaseBridgeSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}

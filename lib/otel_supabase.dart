// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry bridge for `package:supabase_flutter`.
///
/// Provides four callback-shaped helpers — `tracedSupabaseAuth`,
/// `tracedSupabaseDb`, `tracedSupabaseStorage`, `tracedSupabaseFunction`
/// — that wrap the corresponding Supabase product calls in CLIENT-kind
/// OTel spans with the right semantic-convention attributes (`db.*`
/// for postgrest, `supabase.*` for vendor-specific concepts).
///
/// The wrappers don't depend on a specific Supabase SDK version; pass
/// your existing call inside the `invoke` callback and the bridge
/// records the span around it.
library;

export 'src/otel_supabase.dart';
export 'src/otel_supabase_suppression.dart';
export 'src/supabase_semantics.dart';

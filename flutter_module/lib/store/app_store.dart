import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shared in-memory store — lives in the single Dart isolate.
// Both the Search branch and the Shop branch read/write here, proving they
// share one engine and one memory space (acceptance criterion #3).

/// Cart item count — incremented from Shop, visible in Search.
final cartCountProvider = StateProvider<int>((ref) => 0);

/// Cross-branch shared counter — can be incremented from either branch.
final sharedCounterProvider = StateProvider<int>((ref) => 0);

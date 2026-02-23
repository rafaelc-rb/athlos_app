import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/route_paths.dart';

part 'last_module_provider.g.dart';

const _key = 'last_module_path';

/// Valid module root paths that can be restored on startup.
const _validModulePaths = {
  RoutePaths.training,
  RoutePaths.trainingHome,
  RoutePaths.trainingWorkouts,
  RoutePaths.trainingHistory,
};

/// Holds the SharedPreferences instance, initialized in main().
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('Override in ProviderScope');

/// Manages the last visited module path (sync read, async write).
@Riverpod(keepAlive: true)
class LastModule extends _$LastModule {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved != null && _validModulePaths.contains(saved)) return saved;
    return null;
  }

  void save(String path) {
    final root = _moduleRoot(path);
    if (root == null) return;

    ref.read(sharedPreferencesProvider).setString(_key, root);
    state = root;
  }
}

String? _moduleRoot(String path) {
  if (path.startsWith(RoutePaths.training)) return RoutePaths.trainingHome;
  return null;
}

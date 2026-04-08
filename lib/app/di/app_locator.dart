import 'app_module.dart';

class AppLocator {
  AppLocator._();

  static final Map<Type, AppModule> _modules = {};

  static void register<T extends AppModule>(T module) {
    _modules[T] = module;
  }

  static T get<T extends AppModule>() {
    final module = _modules[T];
    if (module == null) {
      throw Exception('Module $T not registered');
    }
    return module as T;
  }

  static void clear() {
    _modules.clear();
  }
}

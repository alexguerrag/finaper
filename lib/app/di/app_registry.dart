import 'app_module.dart';

class AppRegistry {
  AppRegistry._();

  static final List<AppModule> _modules = <AppModule>[];

  static void registerModule(AppModule module) {
    _modules.add(module);
  }

  static List<AppModule> get modules => _modules;

  static void clear() {
    _modules.clear();
  }
}

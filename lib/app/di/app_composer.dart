import 'app_registry.dart';

class AppComposer {
  Future<void> compose() async {
    for (final module in AppRegistry.modules) {
      await module.register();
    }
  }
}

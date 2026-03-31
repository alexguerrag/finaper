import 'app_module.dart';

class AppComposer {
  AppComposer(this._modules);

  final List<AppModule> _modules;

  Future<void> compose() async {
    for (final module in _modules) {
      await module.register();
    }
  }
}

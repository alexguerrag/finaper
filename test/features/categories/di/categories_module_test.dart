import 'package:finaper/features/categories/di/categories_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CategoriesModule registers dependencies', () async {
    final module = CategoriesModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getCategoriesByKind, isNotNull);
    expect(module.createCategory, isNotNull);
  });
}

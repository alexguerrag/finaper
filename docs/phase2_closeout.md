# Fase 2 — Cierre técnico

## Objetivo
Reducir `AppServices` a una capa mínima de compatibilidad y dejar la composición modular como mecanismo principal de inicialización y resolución de dependencias.

## Resultado esperado
- `AppServices` ya no construye dependencias reales.
- El bootstrap vive en `AppBootstrapController`.
- Los módulos registrados en `AppRegistry` y `AppLocator` son la fuente principal.
- La rama queda lista para revisión y eventual merge.

## Validación
```powershell
dart format .
flutter test
flutter analyze
```

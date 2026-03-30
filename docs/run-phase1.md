# Ejecutar Fase 1 localmente

## Rama
```bash
git fetch origin
git checkout phase-1-stabilization
git pull origin phase-1-stabilization
```

## Dependencias
```bash
flutter pub get
```

## Ejecutar bootstrap de Fase 1
```bash
flutter run -t lib/main_phase1.dart
```

## Validación mínima
- La app inicia
- Si la inicialización falla, debe mostrar vista de error
- El flujo principal sigue operativo

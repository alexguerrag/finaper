# Regression Checklist — Finaper

## Smoke básico
- [ ] La aplicación inicia sin crash.
- [ ] La pantalla inicial renderiza correctamente.
- [ ] Se puede entrar al shell principal.
- [ ] Dashboard carga sin errores visibles.
- [ ] Listado de transacciones abre sin crash.
- [ ] Se puede crear una transacción.
- [ ] La nueva transacción aparece en el listado.
- [ ] Presupuestos abre sin crash.
- [ ] Ajustes abre sin crash.
- [ ] Se pueden guardar preferencias.
- [ ] Exportación JSON genera archivo.
- [ ] Exportación CSV genera archivo.

## Antes de cerrar cualquier hito
- [ ] `flutter analyze`
- [ ] Validación manual del smoke básico
- [ ] No se rompió navegación principal
- [ ] No se rompió persistencia local
- [ ] Errores críticos documentados

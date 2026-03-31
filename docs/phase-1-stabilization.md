# Fase 1 — Estabilización

## Objetivo
Dejar Finaper estable para refactorizar sin romper funcionalidad actual.

## Alcance
### Hito 0
- Baseline funcional
- Checklist de regresión
- Backlog técnico priorizado

### Hito 1
- Endurecimiento inicial de lints
- Logging centralizado
- Convención base de errores
- Base para tests

### Hito 2
- Bootstrap robusto
- Estados de inicialización
- Error screen con retry

## Regla operativa
No se mezcla refactor estructural profundo con cambios de negocio en esta fase.

## Condición de cierre
- La app inicia correctamente en escenario feliz.
- Si falla bootstrap, la app no entra al flujo normal.
- Smoke checklist validado.
- Lints controlados.
- Base técnica común creada.

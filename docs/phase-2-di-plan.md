# Fase 2 — Hito 3: DI y composición

## Objetivo
Reducir el acoplamiento de `AppServices` y preparar una composición modular por feature.

## Alcance inicial
- definir contratos de registro de dependencias
- separar módulos por dominio funcional
- preparar migración incremental sin romper la app

## Orden de migración
1. core/database
2. settings
3. transactions
4. budgets
5. export
6. resto de features

## Regla
La migración será progresiva: coexistencia temporal entre `AppServices` y módulos nuevos hasta completar el reemplazo.

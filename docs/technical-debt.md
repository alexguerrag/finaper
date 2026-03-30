# Technical Debt — Finaper

## Crítica
1. Bootstrap permite iniciar la app aunque falle la inicialización.
2. `AppServices` concentra demasiadas responsabilidades.
3. `presentation` depende de `data` en algunos módulos.
4. `domain` depende de Flutter (`Color` en entidades).
5. La pantalla inicial aparenta auth pero no protege nada.

## Alta
1. Exceso de `debugPrint` distribuido.
2. Falta de estrategia centralizada de logging.
3. Falta de estructura de tests utilizable.
4. Lints demasiado permisivos.
5. Defaults silenciosos que pueden ocultar inconsistencias.

## Media
1. README incompleto.
2. Metadata de proyecto todavía con base template.
3. Rutas por string sin tipado.
4. Estado basado mayormente en `setState`.
5. Agregaciones en memoria que deberían vivir en consultas.

## Baja
1. Mejoras visuales y accesibilidad incremental.
2. Refinamiento de mensajes de error.
3. Documentación interna por módulo.

# FINAPER — Release Checklist

Checklist obligatorio antes de cualquier subida a Play Console.

---

## Antes de generar el AAB

### Código
- [ ] `flutter analyze` sin issues
- [ ] `flutter test --coverage` — todos los tests pasando
- [ ] Sin `.withOpacity` — usar `.withValues(alpha: ...)`
- [ ] Sin precios hardcodeados en el código
- [ ] Sin API keys hardcodeadas en el código

### Flag OVERRIDE_PREMIUM

> **NUNCA usar `--dart-define=OVERRIDE_PREMIUM=true` en builds enviados a Play Console.**

Este flag es exclusivo para APKs locales de desarrollo del owner/desarrollador.
Un AAB con `OVERRIDE_PREMIUM=true` desbloquea Premium para cualquier usuario sin pasar por RevenueCat.

- [ ] Confirmar que `OVERRIDE_PREMIUM` NO está en el comando de build
- [ ] Usar siempre el script seguro: `./scripts/build_play_release.sh`

### Build seguro

Usar el script oficial para generar AAB:

```bash
./scripts/build_play_release.sh <REVENUECAT_ANDROID_API_KEY> <REVENUECAT_ENTITLEMENT_ID>
```

El script rechaza automáticamente cualquier build que tenga `OVERRIDE_PREMIUM=true`.

---

## Play Console

- [ ] Package name correcto: `com.alexguerrag.finaper`
- [ ] Internal Testing track activo
- [ ] Testers internos agregados
- [ ] License testers configurados
- [ ] AAB subido al track correcto
- [ ] Producto `finaper_premium_monthly` activo (suscripción mensual)
- [ ] Producto `finaper_premium_yearly` activo (suscripción anual)
- [ ] Producto `finaper_premium_lifetime_founder` activo (compra única — **NO consumible**)
- [ ] Opt-in link enviado a testers

---

## RevenueCat

- [ ] Proyecto: FINAPER
- [ ] App Android: `com.alexguerrag.finaper`
- [ ] Entitlement ID: `premium`
- [ ] Offering ID: `default` (activo)
- [ ] Package mensual → `finaper_premium_monthly`
- [ ] Package anual → `finaper_premium_yearly`
- [ ] Package lifetime → `finaper_premium_lifetime_founder`
- [ ] Google Play conectado (Service Account JSON en RevenueCat — **NO en el repo**)
- [ ] Android API Key inyectada solo vía `--dart-define`

---

## QA de monetización (Internal Testing)

Instalar desde Play Store Internal Testing (no desde `flutter run`).

### Flujo principal
- [ ] Paywall abre desde Dashboard
- [ ] Paywall abre desde Más → Reportes
- [ ] Precios reales visibles (mensual, anual, lifetime)
- [ ] Anual preseleccionado por defecto
- [ ] Compra mensual desbloquea Premium
- [ ] Compra anual desbloquea Premium
- [ ] Compra lifetime desbloquea Premium
- [ ] Restore desbloquea Premium
- [ ] Reinstalar app + restore funciona
- [ ] Dashboard desbloquea cards Premium post-compra
- [ ] Más → Reportes habilitado post-compra
- [ ] Cancelar compra no muestra error agresivo

### Escenarios negativos
- [ ] Sin packages → restore sigue disponible
- [ ] Sin compra previa → restore no desbloquea Premium y muestra mensaje correcto
- [ ] Compra procesada pero entitlement no activo → no cierra como éxito falso
- [ ] RevenueCat sin configurar → no crash
- [ ] Offline con cache Premium reciente → mantiene acceso

### Usuarios Free
- [ ] Usuario sin Premium sigue con funciones gratuitas normales

---

## Criterio para Release Candidate

Solo aprobar merge de PR #135 y Release Candidate cuando **todo lo anterior esté verde**.

---

## Qué NO subir al repo

```
Service Account JSON de Google Play
Keystore (.jks, .keystore)
Passwords o secrets de cualquier tipo
API keys de RevenueCat
Archivos .env con valores reales
```

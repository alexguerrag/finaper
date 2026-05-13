#!/usr/bin/env bash
# Build seguro para Play Console.
#
# Uso:
#   ./scripts/build_play_release.sh <REVENUECAT_ANDROID_API_KEY> <REVENUECAT_ENTITLEMENT_ID>
#
# Ejemplo:
#   ./scripts/build_play_release.sh appl_abc123 premium
#
# El script falla si detecta OVERRIDE_PREMIUM=true en el entorno o argumentos,
# garantizando que ningún build de Play incluya el flag de owner/developer.

set -euo pipefail

# ── Guard: OVERRIDE_PREMIUM nunca debe estar activo en builds Play ────────────

if [ "${OVERRIDE_PREMIUM:-false}" = "true" ]; then
  echo ""
  echo "ERROR: OVERRIDE_PREMIUM=true detectado en el entorno."
  echo "       Nunca uses este flag para builds enviados a Play Console."
  echo "       Úsalo solo para APKs locales de desarrollo del owner."
  echo ""
  exit 1
fi

for arg in "$@"; do
  if [[ "$arg" == *"OVERRIDE_PREMIUM=true"* ]]; then
    echo ""
    echo "ERROR: OVERRIDE_PREMIUM=true detectado en los argumentos."
    echo "       Nunca uses este flag para builds enviados a Play Console."
    echo ""
    exit 1
  fi
done

# ── Validar argumentos ────────────────────────────────────────────────────────

if [ $# -ne 2 ]; then
  echo "Uso: $0 <REVENUECAT_ANDROID_API_KEY> <REVENUECAT_ENTITLEMENT_ID>"
  echo ""
  echo "Ejemplo:"
  echo "  $0 appl_abc123xyz premium"
  exit 1
fi

RC_API_KEY="$1"
ENTITLEMENT_ID="$2"

if [ -z "$RC_API_KEY" ]; then
  echo "ERROR: REVENUECAT_ANDROID_API_KEY no puede estar vacío."
  exit 1
fi

if [ -z "$ENTITLEMENT_ID" ]; then
  echo "ERROR: REVENUECAT_ENTITLEMENT_ID no puede estar vacío."
  exit 1
fi

# ── Build ─────────────────────────────────────────────────────────────────────

echo ""
echo "▶ Generando AAB para Play Console..."
echo "  Entitlement: $ENTITLEMENT_ID"
echo "  OVERRIDE_PREMIUM: NO (correcto)"
echo ""

flutter build appbundle --release \
  --dart-define=REVENUECAT_ANDROID_API_KEY="$RC_API_KEY" \
  --dart-define=REVENUECAT_ENTITLEMENT_ID="$ENTITLEMENT_ID"

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

echo ""
echo "✓ AAB generado: $AAB_PATH"
echo ""
echo "Siguiente paso:"
echo "  Sube $AAB_PATH a Play Console → Internal Testing."
echo "  Verifica el checklist en RELEASE_CHECKLIST.md antes de publicar."
echo ""

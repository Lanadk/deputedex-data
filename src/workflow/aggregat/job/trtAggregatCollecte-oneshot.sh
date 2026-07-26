#!/usr/bin/env bash

# ==============================================================================
# AGGREGATION ALL - Script pour lancer toutes les agrégations
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS=(
  "$SCRIPT_DIR/groups/aggregation-oneshot.sh"
  "$SCRIPT_DIR/calendar/aggregation-oneshot.sh"
  "$SCRIPT_DIR/deputes/aggregation-oneshot.sh"
  # ajouter ici les futurs domaines
)

echo "=============================================="
echo "🚀 Starting ALL aggregations ONE SHOT"
echo "=============================================="

echo ""
echo "=============================================="
echo "Running acteurs aggregation (TS)"
echo "=============================================="
npx ts-node "$SCRIPT_DIR/acteurs/aggregation-oneshot.ts"

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo ""
        echo "=============================================="
        echo "Running $script"
        echo "=============================================="
        bash "$script"
    else
        echo "⚠️  Script not found: $script, skipping..."
    fi
done

echo ""
echo "=============================================="
echo "🎉 All aggregations completed"
echo "=============================================="
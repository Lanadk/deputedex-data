#!/usr/bin/env bash

# ==============================================================================
# IMPORT ALL - Script pour importer toutes les données dans la DB
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Récupérer le paramètre --auto-cleanup
AUTO_CLEANUP=""
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP="--auto-cleanup"
    echo "ℹ️  Auto cleanup mode enabled"
fi

# ----------------------------------------------------------------------
# Scripts d'import existants
# ----------------------------------------------------------------------
SCRIPTS=(
  "$SCRIPT_DIR/unit-import/dossiers-import.sh"
  "$SCRIPT_DIR/unit-import/documents-import.sh"
  # ajouter ici les futurs imports
)

# ----------------------------------------------------------------------
# Boucle sur tous les scripts
# ----------------------------------------------------------------------
echo "=============================================="
echo "🚀 Starting ALL imports"
echo "=============================================="

echo ""
echo "=============================================="
echo "Running acteurs import (TS)"
echo "=============================================="
npx ts-node "$SCRIPT_DIR/unit-import/importActeurs.ts" $AUTO_CLEANUP

echo ""
echo "=============================================="
echo "Running scrutins import (TS)"
echo "=============================================="
npx ts-node "$SCRIPT_DIR/unit-import/importScrutins.ts" $AUTO_CLEANUP

echo ""
echo "=============================================="
echo "Running mandats import (TS)"
echo "=============================================="
npx ts-node "$SCRIPT_DIR/unit-import/importMandats.ts" $AUTO_CLEANUP

echo ""
echo "=============================================="
echo "Running amendements import (TS)"
echo "=============================================="
npx ts-node "$SCRIPT_DIR/unit-import/importAmendements.ts" $AUTO_CLEANUP

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo ""
        echo "=============================================="
        echo "Running $script"
        echo "=============================================="
        bash "$script" $AUTO_CLEANUP
    else
        echo "⚠️  Script not found: $script, skipping..."
    fi
done

echo ""
echo "=============================================="
echo "🎉 All imports completed"
echo "=============================================="
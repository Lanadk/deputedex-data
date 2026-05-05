#!/usr/bin/env bash

# ==============================================================================
# DEPUTES AGGREGATION SCRIPT
# Rafraîchit les materialized views d'agrégation des deputes
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/sql-utils.sh"

# ==============================================================================
# MAIN
# ==============================================================================
echo "=============================================="
echo "  DEPUTES AGGREGATION REFRESH SCRIPT"
echo "=============================================="
echo ""

refresh_view "agg_deputes_cards"

echo ""
echo "=============================================="
echo "  ✅ DEPUTES AGGREGATION REFRESHED"
echo "=============================================="
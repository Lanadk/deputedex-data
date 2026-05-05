#!/usr/bin/env bash

# ==============================================================================
# DEPUTES AGGREGATION - CREATE SCRIPT (ONE SHOT)
# Création initiale des materialized views d'agrégation des deputes
# A lancer une seule fois lors du premier déploiement
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/sql-utils.sh"

SQL_SCRIPTS_DIR="//sql/scripts/deputes/aggregations"

# ==============================================================================
# MAIN
# ==============================================================================
echo "=============================================="
echo "  DEPUTES AGGREGATION - CREATE (ONE SHOT)"
echo "=============================================="
echo ""

create_view "agg_deputes_cards"          "$SQL_SCRIPTS_DIR/agg_deputes_cards.sql"

echo ""
echo "=============================================="
echo "  ✅ DEPUTES AGGREGATION CREATED"
echo "  ⚠️  NE PAS RELANCER CE SCRIPT"
echo "  👉 Pour mettre à jour : deputes/aggregation.sh"
echo "=============================================="
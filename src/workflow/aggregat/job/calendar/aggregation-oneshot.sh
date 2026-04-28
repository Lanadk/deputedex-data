#!/usr/bin/env bash

# ==============================================================================
# CALENDAR ACTIVITY AGGREGATION - CREATE SCRIPT (ONE SHOT)
# Création initiale des materialized views d'agrégation des activités
# A lancer une seule fois lors du premier déploiement
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/sql-utils.sh"

SQL_SCRIPTS_DIR="//sql/scripts/calendar/aggregations"

# ==============================================================================
# MAIN
# ==============================================================================
echo "=============================================="
echo "  CALENDAR ACTIVITY AGGREGATION - CREATE (ONE SHOT)"
echo "=============================================="
echo ""

create_view "agg_activity_calendar_mv"          "$SQL_SCRIPTS_DIR/agg_activity_calendar_mv.sql"
create_view "agg_activity_calendar_details_mv"                "$SQL_SCRIPTS_DIR/agg_activity_calendar_details_mv.sql"

echo ""
echo "=============================================="
echo "  ✅ CALENDAR ACTIVITY AGGREGATION CREATED"
echo "  ⚠️  NE PAS RELANCER CE SCRIPT"
echo "  👉 Pour mettre à jour : calendar/aggregation.sh"
echo "=============================================="
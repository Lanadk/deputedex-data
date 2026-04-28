#!/usr/bin/env bash

# ==============================================================================
# CALENDAR ACTIVITY AGGREGATION SCRIPT
# Rafraîchit les materialized views d'agrégation des calendriers d'activités
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/sql-utils.sh"

# ==============================================================================
# MAIN
# ==============================================================================
echo "=============================================="
echo "  CALENDAR ACTIVITY AGGREGATION REFRESH SCRIPT"
echo "=============================================="
echo ""

refresh_view "agg_activity_calendar_mv"
refresh_view "agg_activity_calendar_details_mv"

echo ""
echo "=============================================="
echo "  ✅ CALENDAR ACTIVITY AGGREGATION REFRESHED"
echo "=============================================="
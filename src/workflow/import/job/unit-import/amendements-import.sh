#!/usr/bin/env bash

# ==============================================================================
# AMENDEMENTS IMPORT SCRIPT
# Raw → Snapshot → Final pipeline with optional cleanup
# ==============================================================================

set -e

# ==============================================================================
# IMPORTS
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths.sh"
source "$SCRIPT_DIR/json-import-utils.sh"

# ==============================================================================
# CONSTANTS
# ==============================================================================
SQL_SCRIPTS_DIR="//sql/scripts/amendements"

SCHEMA_NAME="amendements.schema.sql"
AMENDEMENTS_JSON="amendements.json"
AMENDEMENTS_CO_AUTEURS_JSON="amendementsCoAuteurs.json"

# ==============================================================================
# ARGUMENTS
# ==============================================================================
AUTO_CLEANUP=false
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
    echo "ℹ️  Auto cleanup mode enabled"
fi

# ==============================================================================
# PROJECTION WRAPPERS
# ==============================================================================
project_amendements() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_amendements.sql"
}

project_amendements_co_auteurs() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_amendements_co_auteurs.sql"
}

# ==============================================================================
# SYNC / CLEANUP / VERIFY WRAPPERS
# ==============================================================================
sync_snapshot_to_final() {
    run_sql_file "$SQL_SCRIPTS_DIR/sync/sync_snapshot_to_final.sql"
}

drop_snapshots() {
    run_sql_file "$SQL_SCRIPTS_DIR/cleanup/drop_snapshots_tables.sql"
}

drop_raw_tables() {
    run_sql_file "$SQL_SCRIPTS_DIR/cleanup/drop_raw_tables.sql"
}

verify_final_counts() {
    run_sql_file "$SQL_SCRIPTS_DIR/verify/final_counts.sql"
}

# ==============================================================================
# GUARDS
# ==============================================================================
for dir in "$SCHEMA_DIR" "$TABLES_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "❌ Missing directory: $dir"
    exit 1
  fi
done

# ==============================================================================
# MAIN
# ==============================================================================
echo "=============================================="
echo "  AMENDEMENTS IMPORT SCRIPT"
echo "=============================================="
echo ""

# -- Schema --------------------------------------------------------------------
echo "📦 [SCHEMA] Importing schema..."
cat "$SCHEMA_DIR/$SCHEMA_NAME" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME"
echo "✓ [SCHEMA] Done"
echo ""

# -- Raw → Snapshot ------------------------------------------------------------
for LEGISLATURE_DIR in "$TABLES_DIR"/*/; do
    LEGISLATURE=$(basename "$LEGISLATURE_DIR")
    if ! [[ "$LEGISLATURE" =~ ^[0-9]+$ ]]; then continue; fi

    echo "=============================================="
    echo "  🏛️  Legislature $LEGISLATURE"
    echo "=============================================="
    echo ""

    echo "📥 [RAW] Importing amendements..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/$AMENDEMENTS_JSON" \
        "amendements_raw" \
        "project_amendements"
    echo "✓ [RAW] amendements done"
    echo " ------------- "

    echo "📥 [RAW] Importing co-auteurs..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/$AMENDEMENTS_CO_AUTEURS_JSON" \
        "amendements_co_auteurs_raw" \
        "project_amendements_co_auteurs"
    echo "✓ [RAW] co-auteurs done"

    echo "----------------------------------------------"
    echo "  ✅ Legislature $LEGISLATURE complete"
    echo "----------------------------------------------"
    echo ""
done

# -- Snapshot → Final ----------------------------------------------------------
echo "=============================================="
echo "  🔄 [SYNC] Snapshot → Final"
echo "=============================================="
sync_snapshot_to_final
echo "✓ [SYNC] Done"
echo ""

# -- Cleanup -------------------------------------------------------------------
echo "=============================================="
echo "  🧼 [CLEANUP] Dropping snapshots"
echo "=============================================="
drop_snapshots
echo "✓ [CLEANUP] Snapshots dropped"
echo ""

echo "=============================================="
echo "  🗑️  [CLEANUP] Drop raw tables"
echo "=============================================="
if [[ "$AUTO_CLEANUP" == true ]]; then
    drop_raw_tables
    echo "✓ [CLEANUP] Raw tables dropped"
else
    read -p "Drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        drop_raw_tables
        echo "✓ [CLEANUP] Raw tables dropped"
    else
        echo "⏭️  [CLEANUP] Raw tables kept"
    fi
fi
echo ""

# -- Verification --------------------------------------------------------------
echo "=============================================="
echo "  📊 [VERIFY] Final row counts"
echo "=============================================="
verify_final_counts
echo ""

echo "=============================================="
echo "  ✅ IMPORT COMPLETED"
echo "=============================================="
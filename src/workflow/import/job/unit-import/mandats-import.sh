#!/usr/bin/env bash

# ==============================================================================
# MANDATS IMPORT SCRIPT
# Imports mandats JSON data into the database for each legislature
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
SQL_SCRIPTS_DIR="//sql/scripts/mandats"

SCHEMA_NAME="mandats.schema.sql"
MANDATS_JSON="mandats.json"
MANDATS_SUPPLEANTS_JSON="mandatsSuppleants.json"

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

project_mandats() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_mandats.sql"
}

project_mandats_suppleants() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_mandats_suppleants.sql"
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
echo "  MANDATS IMPORT SCRIPT"
echo "=============================================="
echo ""

# -- Schema --------------------------------------------------------------------
echo "📦 [SCHEMA] Importing schema..."
cat "$SCHEMA_DIR/$SCHEMA_NAME" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME"
echo "✓ [SCHEMA] Done"
echo ""

# -- Raw → Snapshot (per legislature) -----------------------------------------
for LEGISLATURE_DIR in "$TABLES_DIR"/*/; do
    LEGISLATURE=$(basename "$LEGISLATURE_DIR")
    if ! [[ "$LEGISLATURE" =~ ^[0-9]+$ ]]; then continue; fi

    echo ""
    echo "=============================================="
    echo "  🏛️  Legislature $LEGISLATURE"
    echo "=============================================="
    echo ""

    echo "📥 [RAW] Importing mandats..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$MANDATS_JSON" "mandats_raw" "project_mandats"
    echo "✓ [RAW] mandats done"
    echo " ------------- "

    echo "📥 [RAW] Importing suppléants..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$MANDATS_SUPPLEANTS_JSON" "mandats_suppleants_raw" "project_mandats_suppleants"
    echo "✓ [RAW] suppléants done"

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
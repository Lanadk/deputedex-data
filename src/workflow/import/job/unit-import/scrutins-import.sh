#!/usr/bin/env bash

# ==============================================================================
# SCRUTINS IMPORT SCRIPT
# Imports scrutins JSON data into the database for each legislature
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
SQL_SCRIPTS_DIR="//sql/scripts/scrutins"

SCHEMA_NAME="scrutins.schema.sql"
DEPUTES_JSON="deputes.json"
GROUPES_VU_DES_SCRUTINS_JSON="groupesVuDesScrutins.json"
SCRUTINS_JSON="scrutins.json"
SCRUTINS_GROUPES_JSON="scrutinsGroupes.json"
VOTES_DEPUTES_JSON="votesDeputes.json"
SCRUTINS_AGREGATS_JSON="scrutinsAgregats.json"
SCRUTINS_GROUPES_AGREGATS_JSON="scrutinsGroupesAgregats.json"

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

project_deputes() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_deputes.sql"
}

project_groupes_parlementaires() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_groupes_parlementaires.sql"
}

project_scrutins() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_scrutins.sql"
}

project_scrutins_groupes() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_scrutins_groupes.sql"
}

project_votes_deputes() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_votes_deputes.sql"
}

project_scrutins_agregats() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_scrutins_agregats.sql"
}

project_scrutins_groupes_agregats() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_scrutins_groupes_agregats.sql"
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
echo "  SCRUTINS IMPORT SCRIPT"
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

    echo "📥 [RAW] Importing députes..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$DEPUTES_JSON" "deputes_raw" "project_deputes"
    echo "✓ [RAW] députes done"
    echo " ------------- "

    echo "📥 [RAW] Importing groupes parlementaires..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$GROUPES_VU_DES_SCRUTINS_JSON" "groupes_parlementaires_raw" "project_groupes_parlementaires"
    echo "✓ [RAW] groupes parlementaires done"
    echo " ------------- "

    echo "📥 [RAW] Importing scrutins..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$SCRUTINS_JSON" "scrutins_raw" "project_scrutins"
    echo "✓ [RAW] scrutins done"
    echo " ------------- "

    echo "📥 [RAW] Importing scrutins groupes..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$SCRUTINS_GROUPES_JSON" "scrutins_groupes_raw" "project_scrutins_groupes"
    echo "✓ [RAW] scrutins groupes done"
    echo " ------------- "

    echo "📥 [RAW] Importing votes députes..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$VOTES_DEPUTES_JSON" "votes_deputes_raw" "project_votes_deputes"
    echo "✓ [RAW] votes députes done"
    echo " ------------- "

    echo "📥 [RAW] Importing scrutins agrégats..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$SCRUTINS_AGREGATS_JSON" "scrutins_agregats_raw" "project_scrutins_agregats"
    echo "✓ [RAW] scrutins agrégats done"
    echo " ------------- "

    echo "📥 [RAW] Importing scrutins groupes agrégats..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$SCRUTINS_GROUPES_AGREGATS_JSON" "scrutins_groupes_agregats_raw" "project_scrutins_groupes_agregats"
    echo "✓ [RAW] scrutins groupes agrégats done"

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
#!/usr/bin/env bash

# ==============================================================================
# DOCUMENTS IMPORT SCRIPT
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
SQL_SCRIPTS_DIR="//sql/scripts/documents"

SCHEMA_NAME="documents.schema.sql"
DOCUMENTS_JSON="documents.json"
DOCUMENTS_CLASSIFICATIONS_JSON="documentsClassifications.json"
DOCUMENTS_AUTEURS_JSON="documentsAuteurs.json"
DOCUMENTS_CO_SIGNATAIRES_JSON="documentsCoSignataires.json"
DOCUMENTS_ORGANES_REFERENTS_JSON="documentsOrganesReferents.json"
DOCUMENTS_IMPRIMERIES_JSON="documentsImprimeries.json"
DOCUMENTS_DEPOTS_AMENDEMENTS_JSON="documentsDepotsAmendements.json"

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
project_documents() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents.sql"
}

project_documents_classifications() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_classifications.sql"
}

project_documents_auteurs() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_auteurs.sql"
}

project_documents_co_signataires() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_co_signataires.sql"
}

project_documents_organes_referents() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_organes_referents.sql"
}

project_documents_imprimeries() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_imprimeries.sql"
}

project_documents_depots_amendements() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_documents_depots_amendements.sql"
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
echo "  DOCUMENTS IMPORT SCRIPT"
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

    echo "📥 [RAW] Importing documents..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_JSON" \
        "documents_raw" \
        "project_documents"
    echo "✓ [RAW] documents done"
    echo " ------------- "

    echo "📥 [RAW] Importing documents classifications..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_CLASSIFICATIONS_JSON" \
        "documents_classifications_raw" \
        "project_documents_classifications"
    echo "✓ [RAW] co-auteurs done"

    echo "📥 [RAW] Importing documents auteurs..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_AUTEURS_JSON" \
        "documents_auteurs_raw" \
        "project_documents_auteurs"
    echo "✓ [RAW] co-auteurs done"

    echo "📥 [RAW] Importing documents co-signataires..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_CO_SIGNATAIRES_JSON" \
        "documents_co_signataires_raw" \
        "project_documents_co_signataires"
    echo "✓ [RAW] co-auteurs done"

    echo "📥 [RAW] Importing documents organes referents..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_ORGANES_REFERENTS_JSON" \
        "documents_organes_referents_raw" \
        "project_documents_organes_referents"
    echo "✓ [RAW] co-auteurs done"

    echo "📥 [RAW] Importing documents imprimeries..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_IMPRIMERIES_JSON" \
        "documents_imprimeries_raw" \
        "project_documents_imprimeries"
    echo "✓ [RAW] co-auteurs done"

    echo "📥 [RAW] Importing documents depots amendements..."
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/DOCUMENTS_DEPOTS_AMENDEMENTS_JSON" \
        "documents_depots_amendements_raw" \
        "project_documents_depots_amendements"
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
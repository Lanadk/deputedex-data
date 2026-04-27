#!/usr/bin/env bash

# ==============================================================================
# ACTEURS IMPORT SCRIPT
# Imports acteurs JSON data into the database for each legislature
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
SQL_SCRIPTS_DIR="//sql/scripts/acteurs"

SCHEMA_NAME="acteurs.schema.sql"
ACTEURS_JSON="acteurs.json"
ACTEURS_ADRESSES_POSTALES_JSON="acteursAdressesPostales.json"
ACTEURS_ADRESSES_MAILS_JSON="acteursAdressesMails.json"
ACTEURS_RESEAUX_SOCIAUX_JSON="acteursReseauxSociaux.json"
ACTEURS_TELEPHONES_JSON="acteursTelephones.json"
GROUPES_VU_DES_MANDATS_JSON="groupesVuDesMandats.json"

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

project_acteurs() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_acteurs.sql"
}

project_acteurs_adresses_postales() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_acteurs_adresses_postales.sql"
}

project_acteurs_adresses_mails() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_acteurs_adresses_mails.sql"
}

project_acteurs_reseaux_sociaux() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_acteurs_reseaux_sociaux.sql"
}

project_acteurs_telephones() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_acteurs_telephones.sql"
}

project_groupes_parlementaires() {
    run_sql_file "$SQL_SCRIPTS_DIR/projections/project_groupes_parlementaires.sql"
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
echo "  ACTEURS IMPORT SCRIPT"
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

    echo "=============================================="
    echo "  🏛️  Legislature $LEGISLATURE"
    echo "=============================================="
    echo ""

    echo "📥 [RAW] Importing acteurs..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$ACTEURS_JSON" "acteurs_raw" "project_acteurs"
    echo "✓ [RAW] acteurs done"
    echo " ------------- "

    echo "📥 [RAW] Importing adresses postales..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$ACTEURS_ADRESSES_POSTALES_JSON" "acteurs_adresses_postales_raw" "project_acteurs_adresses_postales"
    echo "✓ [RAW] adresses postales done"
    echo " ------------- "

    echo "📥 [RAW] Importing adresses mails..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$ACTEURS_ADRESSES_MAILS_JSON" "acteurs_adresses_mails_raw" "project_acteurs_adresses_mails"
    echo "✓ [RAW] adresses mails done"
    echo " ------------- "

    echo "📥 [RAW] Importing réseaux sociaux..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$ACTEURS_RESEAUX_SOCIAUX_JSON" "acteurs_reseaux_sociaux_raw" "project_acteurs_reseaux_sociaux"
    echo "✓ [RAW] réseaux sociaux done"
    echo " ------------- "

    echo "📥 [RAW] Importing téléphones..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$ACTEURS_TELEPHONES_JSON" "acteurs_telephones_raw" "project_acteurs_telephones"
    echo "✓ [RAW] téléphones done"

    echo "📥 [RAW] Importing groupes vus depuis mandats..."
    import_json_to_raw_table "$LEGISLATURE_DIR/$GROUPES_VU_DES_MANDATS_JSON" "groupes_parlementaires_raw" "project_groupes_parlementaires"
    echo "✓ [RAW] groupes mandats done"
    echo " ------------- "

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
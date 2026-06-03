#!/usr/bin/env bash

set -e

# ==============================================================================
# DOSSIERS PARLEMENTAIRES IMPORT SCRIPT
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/paths.sh"
source "$SCRIPT_DIR/json-import-utils.sh"

# ==============================================================================
# CONSTANTS
# ==============================================================================

SQL_SCRIPTS_DIR="/sql/scripts/dossiers"

SCHEMA_NAME="dossiers.schema.sql"

DOSSIERS_JSON="dossiersParlementaires.json"
INITIATEURS_JSON="dossierInitiateurs.json"
ACTES_JSON="actesLegislatifs.json"
RAPPORTEURS_JSON="acteRapporteurs.json"
TEXTES_JSON="acteTextesAssocies.json"
REUNIONS_JSON="acteReunions.json"
DECISIONS_JSON="acteDecisions.json"
VOTES_JSON="acteVotes.json"

# ==============================================================================
# ARGUMENTS
# ==============================================================================

AUTO_CLEANUP=false

if [[ "$1" == "--auto-cleanup" ]]; then
  AUTO_CLEANUP=true
  echo "ℹ️  Auto cleanup mode enabled"
fi

# ==============================================================================
# PROJECTIONS
# ==============================================================================

project_dossiers() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_dossiers.sql"
}

project_initiateurs() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_initiateurs.sql"
}

project_actes() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_actes.sql"
}

project_rapporteurs() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_rapporteurs.sql"
}

project_textes_associes() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_textes_associes.sql"
}

project_reunions() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_reunions.sql"
}

project_decisions() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_decisions.sql"
}

project_votes() {
  run_sql_file "$SQL_SCRIPTS_DIR/projections/project_votes.sql"
}

# ==============================================================================
# SYNC / CLEANUP / VERIFY
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
echo "  DOSSIERS PARLEMENTAIRES IMPORT SCRIPT"
echo "=============================================="
echo ""

# ------------------------------------------------------------------------------
# SCHEMA
# ------------------------------------------------------------------------------

echo "📦 [SCHEMA] Importing schema..."

cat "$SCHEMA_DIR/$SCHEMA_NAME" \
| docker exec -i "$DB_CONTAINER" psql \
    -U "$DB_USER_WRITER" \
    -d "$DB_NAME"

echo "✓ [SCHEMA] Done"
echo ""

# ------------------------------------------------------------------------------
# RAW -> SNAPSHOT
# ------------------------------------------------------------------------------

for LEGISLATURE_DIR in "$TABLES_DIR"/*/; do

  LEGISLATURE=$(basename "$LEGISLATURE_DIR")

  if ! [[ "$LEGISLATURE" =~ ^[0-9]+$ ]]; then
      continue
  fi

  echo "=============================================="
  echo "  🏛️  Legislature $LEGISLATURE"
  echo "=============================================="

  echo ""

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$DOSSIERS_JSON" \
      "dossier_parlementaire_raw" \
      "project_dossiers"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$INITIATEURS_JSON" \
      "dossier_initiateur_raw" \
      "project_initiateurs"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$ACTES_JSON" \
      "acte_legislatif_raw" \
      "project_actes"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$RAPPORTEURS_JSON" \
      "acte_rapporteur_raw" \
      "project_rapporteurs"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$TEXTES_JSON" \
      "acte_texte_associe_raw" \
      "project_textes_associes"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$REUNIONS_JSON" \
      "acte_reunion_raw" \
      "project_reunions"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$DECISIONS_JSON" \
      "acte_decision_raw" \
      "project_decisions"

  import_json_to_raw_table \
      "$LEGISLATURE_DIR/$VOTES_JSON" \
      "acte_vote_raw" \
      "project_votes"

  echo ""
  echo "----------------------------------------------"
  echo "  ✅ Legislature $LEGISLATURE complete"
  echo "----------------------------------------------"
  echo ""

done

# ------------------------------------------------------------------------------
# SNAPSHOT -> FINAL
# ------------------------------------------------------------------------------

echo "=============================================="
echo "  🔄 [SYNC] Snapshot → Final"
echo "=============================================="

sync_snapshot_to_final

echo "✓ [SYNC] Done"
echo ""

# ------------------------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------------------------

echo "=============================================="
echo "  🧼 [CLEANUP] Dropping snapshots"
echo "=============================================="

drop_snapshots

echo "✓ [CLEANUP] Snapshots dropped"
echo ""

echo "=============================================="
echo "  🗑️ [CLEANUP] Drop raw tables"
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

# ------------------------------------------------------------------------------
# VERIFY
# ------------------------------------------------------------------------------

echo "=============================================="
echo "  📊 [VERIFY] Final row counts"
echo "=============================================="

verify_final_counts

echo ""

echo "=============================================="
echo "  ✅ IMPORT COMPLETED"
echo "=============================================="
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths.sh"
source "$SCRIPT_DIR/json-import-utils.sh"

AUTO_CLEANUP=false
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
    echo "ℹ️  Auto cleanup mode enabled"
fi

SCHEMA_NAME="amendements.schema.sql"
AMENDEMENTS_JSON="amendements.json"
AMENDEMENTS_CO_AUTEURS_JSON="amendementsCoAuteurs.json"

# ==============================================================================
# FONCTIONS DE PROJECTION
# ==============================================================================
project_amendements() {
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c "INSERT INTO amendements (uid, chronotag, legislature, numero_long, numero_ordre, numero_rect, organe_examen, examen_ref, texte_leg_ref, acteur_uid, groupe_politique_ref, type_auteur, division_titre, division_type, division_avant_apres, alinea_numero, dispositif, expose_sommaire, date_depot, date_publication, date_sort, sort, etat_code, etat_libelle, sous_etat_code, sous_etat_libelle, article99) SELECT data->>'uid', data->>'chronotag', data->>'legislature', data->>'numero_long', data->>'numero_ordre', data->>'numero_rect', data->>'organe_examen', data->>'examen_ref', data->>'texte_leg_ref', data->>'acteur_uid', data->>'groupe_politique_ref', data->>'type_auteur', data->>'division_titre', data->>'division_type', data->>'division_avant_apres', data->>'alinea_numero', data->>'dispositif', data->>'expose_sommaire', NULLIF(data->>'date_depot', '')::date, NULLIF(data->>'date_publication', '')::date, NULLIF(data->>'date_sort', '')::timestamptz, data->>'sort', data->>'etat_code', data->>'etat_libelle', data->>'sous_etat_code', data->>'sous_etat_libelle', CASE WHEN data->>'article99' = 'true' THEN true WHEN data->>'article99' = 'false' THEN false ELSE NULL END FROM amendements_raw ON CONFLICT (uid) DO NOTHING;"
}

project_amendements_co_auteurs() {
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c "INSERT INTO amendements_co_auteurs (amendement_uid, acteur_uid) SELECT data->>'amendement_uid', data->>'acteur_uid' FROM amendements_co_auteurs_raw ON CONFLICT (amendement_uid, acteur_uid) DO NOTHING;"
}
# ==============================================================================
# VÉRIFICATIONS
# ==============================================================================
for dir in "$SCHEMA_DIR" "$TABLES_DIR"; do
    [ ! -d "$dir" ] && echo "❌ Missing directory: $dir" && exit 1
done

echo "=============================================="
echo "AMENDEMENTS IMPORT SCRIPT"
echo "=============================================="

echo "Importing schema..."
cat "$SCHEMA_DIR/$SCHEMA_NAME" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME"
echo "✓ Schema imported"

# ==============================================================================
# BOUCLE SUR LES LÉGISLATURES
# ==============================================================================
for LEGISLATURE_DIR in "$TABLES_DIR"/*/; do
    LEGISLATURE=$(basename "$LEGISLATURE_DIR")
    if ! [[ "$LEGISLATURE" =~ ^[0-9]+$ ]]; then continue; fi

    echo "=============================================="
    echo "🏛️  Legislature $LEGISLATURE"
    echo "=============================================="

    echo "=== AMENDEMENTS ==="
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/$AMENDEMENTS_JSON" \
        "amendements_raw" \
        "project_amendements"
    echo "✓ Amendements imported"

    echo "=== CO-AUTEURS ==="
    import_json_to_raw_table \
        "$LEGISLATURE_DIR/$AMENDEMENTS_CO_AUTEURS_JSON" \
        "amendements_co_auteurs_raw" \
        "project_amendements_co_auteurs"
    echo "✓ Co-auteurs imported"
done

# ==============================================================================
# CLEANUP
# ==============================================================================
if [[ "$AUTO_CLEANUP" == true ]]; then
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "DROP TABLE IF EXISTS amendements_raw, amendements_co_auteurs_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Drop raw tables? (y/n) " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "DROP TABLE IF EXISTS amendements_raw, amendements_co_auteurs_raw CASCADE;"
fi

# ==============================================================================
# VÉRIFICATION FINALE
# ==============================================================================
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c "
SELECT 'amendements', COUNT(*) FROM amendements
UNION ALL
SELECT 'amendements_co_auteurs', COUNT(*) FROM amendements_co_auteurs;"

echo "✓ IMPORT COMPLETED"
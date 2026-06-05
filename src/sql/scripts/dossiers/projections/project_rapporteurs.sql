INSERT INTO acte_rapporteur_snapshot (
    acte_uid,
    acteur_uid,
    type_rapporteur,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'acte_uid',
    data->>'acteur_uid',
    data->>'type_rapporteur',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM acte_rapporteur_raw

ON CONFLICT (acte_uid, acteur_uid) DO NOTHING;
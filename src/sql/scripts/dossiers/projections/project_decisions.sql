INSERT INTO acte_decision_snapshot (
    acte_uid,
    famille_code,
    libelle,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'acte_uid',
    data->>'famille_code',
    data->>'libelle',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM acte_decision_raw

ON CONFLICT (acte_uid) DO NOTHING;
INSERT INTO acte_texte_associe_snapshot (
    acte_uid,
    reference_texte,
    type_texte,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'acte_uid',
    data->>'reference_texte',
    data->>'type_texte',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM acte_texte_associe_raw

ON CONFLICT (acte_uid, reference_texte) DO NOTHING;
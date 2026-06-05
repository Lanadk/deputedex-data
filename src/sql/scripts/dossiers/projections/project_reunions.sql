INSERT INTO acte_reunion_snapshot (
    acte_uid,
    reunion_ref,
    odj_ref,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'acte_uid',
    data->>'reunion_ref',
    data->>'odj_ref',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM acte_reunion_raw

ON CONFLICT (acte_uid) DO NOTHING;
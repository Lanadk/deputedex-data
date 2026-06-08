INSERT INTO acte_vote_snapshot (
    acte_uid,
    vote_ref,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'acte_uid',
    data->>'vote_ref',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM acte_vote_raw

ON CONFLICT (acte_uid,vote_ref) DO NOTHING;

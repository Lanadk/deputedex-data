INSERT INTO dossier_initiateur_snapshot (
    dossier_uid,
    acteur_uid,
    mandat_uid,
    organe_uid,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'dossier_uid',
    data->>'acteur_uid',
    data->>'mandat_uid',
    data->>'organe_uid',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM dossier_initiateur_raw

ON CONFLICT (row_hash) DO NOTHING;
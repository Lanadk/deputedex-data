INSERT INTO dossier_parlementaire_snapshot (
    uid,
    legislature,
    titre,
    titre_chemin,
    senat_chemin,
    procedure_code,
    procedure_libelle,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'uid',
    (data->>'legislature')::integer,
    data->>'titre',
    data->>'titre_chemin',
    data->>'senat_chemin',
    data->>'procedure_code',
    data->>'procedure_libelle',
    md5(data::text),
    (data->>'legislature_snapshot')::integer
FROM dossier_parlementaire_raw

ON CONFLICT (uid) DO NOTHING;
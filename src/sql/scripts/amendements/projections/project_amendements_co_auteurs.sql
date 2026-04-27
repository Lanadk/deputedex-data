INSERT INTO amendements_co_auteurs_snapshot (
    amendement_uid,
    acteur_uid,
    row_hash,
    legislature_snapshot
)
SELECT
    amendement_uid,
    acteur_uid,
    row_hash,
    legislature_snapshot
FROM (
         SELECT
             data->>'amendement_uid' AS amendement_uid,
             data->>'acteur_uid' AS acteur_uid,
             data->>'row_hash' AS row_hash,
             (data->>'legislature_snapshot')::int AS legislature_snapshot,

             ROW_NUMBER() OVER (
                 PARTITION BY data->>'amendement_uid', data->>'acteur_uid'
                 ORDER BY data->>'row_hash' DESC
                 ) AS rn
         FROM amendements_co_auteurs_raw
     ) t
WHERE rn = 1
ON CONFLICT (amendement_uid, acteur_uid)
    DO UPDATE SET
    row_hash = EXCLUDED.row_hash
WHERE amendements_co_auteurs_snapshot.row_hash != EXCLUDED.row_hash;
BEGIN;

-- =====================================================
-- DEPUTES
-- =====================================================

INSERT INTO deputes (id, row_hash, legislature_snapshot)
SELECT id, row_hash, legislature_snapshot
FROM deputes_snapshot
ON CONFLICT (id) DO UPDATE SET row_hash             = EXCLUDED.row_hash,
                               legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE deputes.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_deputes_to_delete AS
SELECT d.id
FROM deputes d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1 FROM deputes_snapshot s WHERE s.id = d.id);

-- votes_deputes_depute_id_fkey est ON DELETE RESTRICT et votes_deputes n'est
-- purgé que plus bas dans ce fichier (section VOTES DEPUTES) : il faut retirer
-- les votes d'un député disparu ici, sinon la suppression ci-dessous échoue.
DELETE
FROM votes_deputes
WHERE depute_id IN (SELECT id FROM tmp_deputes_to_delete);

DELETE
FROM deputes d USING tmp_deputes_to_delete x
WHERE d.id = x.id;
DROP TABLE tmp_deputes_to_delete;

-- =====================================================
-- GROUPES PARLEMENTAIRES
-- =====================================================

INSERT INTO groupes_parlementaires (id, legislature_snapshot, row_hash)
SELECT id, legislature_snapshot, row_hash
FROM groupes_parlementaires_snapshot
ON CONFLICT (id) DO UPDATE SET legislature_snapshot = EXCLUDED.legislature_snapshot,
                               row_hash             = EXCLUDED.row_hash
WHERE groupes_parlementaires.row_hash != EXCLUDED.row_hash;

-- =====================================================
-- SCRUTINS
-- =====================================================

INSERT INTO scrutins (uid, numero, legislature, date_scrutin, titre,
                      type_scrutin_code, type_scrutin_libelle, type_majorite,
                      resultat_code, resultat_libelle, row_hash, legislature_snapshot)
SELECT uid,
       numero,
       legislature,
       date_scrutin,
       titre,
       type_scrutin_code,
       type_scrutin_libelle,
       type_majorite,
       resultat_code,
       resultat_libelle,
       row_hash,
       legislature_snapshot
FROM scrutins_snapshot
ON CONFLICT (uid) DO UPDATE SET numero               = EXCLUDED.numero,
                                legislature          = EXCLUDED.legislature,
                                date_scrutin         = EXCLUDED.date_scrutin,
                                titre                = EXCLUDED.titre,
                                type_scrutin_code    = EXCLUDED.type_scrutin_code,
                                type_scrutin_libelle = EXCLUDED.type_scrutin_libelle,
                                type_majorite        = EXCLUDED.type_majorite,
                                resultat_code        = EXCLUDED.resultat_code,
                                resultat_libelle     = EXCLUDED.resultat_libelle,
                                row_hash             = EXCLUDED.row_hash,
                                legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE scrutins.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_scrutins_to_delete AS
SELECT sc.uid
FROM scrutins sc
WHERE sc.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1 FROM scrutins_snapshot s WHERE s.uid = sc.uid);

DELETE
FROM scrutins sc USING tmp_scrutins_to_delete x
WHERE sc.uid = x.uid;
DROP TABLE tmp_scrutins_to_delete;

-- =====================================================
-- SCRUTINS GROUPES
-- =====================================================

INSERT INTO scrutins_groupes (scrutin_uid, groupe_id, groupe_legislature,
                              nombre_membres, position_majoritaire, row_hash, legislature_snapshot)
SELECT scrutin_uid,
       groupe_id,
       groupe_legislature,
       nombre_membres,
       position_majoritaire,
       row_hash,
       legislature_snapshot
FROM scrutins_groupes_snapshot
ON CONFLICT (scrutin_uid, groupe_id) DO UPDATE SET groupe_legislature   = EXCLUDED.groupe_legislature,
                                                   nombre_membres       = EXCLUDED.nombre_membres,
                                                   position_majoritaire = EXCLUDED.position_majoritaire,
                                                   row_hash             = EXCLUDED.row_hash,
                                                   legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE scrutins_groupes.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_scrutins_groupes_to_delete AS
SELECT sg.scrutin_uid, sg.groupe_id
FROM scrutins_groupes sg
WHERE sg.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM scrutins_groupes_snapshot s
                  WHERE s.scrutin_uid = sg.scrutin_uid
                    AND s.groupe_id = sg.groupe_id);

DELETE
FROM scrutins_groupes sg USING tmp_scrutins_groupes_to_delete x
WHERE sg.scrutin_uid = x.scrutin_uid
  AND sg.groupe_id = x.groupe_id;
DROP TABLE tmp_scrutins_groupes_to_delete;

-- =====================================================
-- VOTES DEPUTES
-- =====================================================

INSERT INTO votes_deputes (scrutin_uid, depute_id, groupe_id, groupe_legislature,
                           mandat_ref, position, cause_position, par_delegation,
                           row_hash, legislature_snapshot)
SELECT scrutin_uid,
       depute_id,
       groupe_id,
       groupe_legislature,
       mandat_ref,
       position,
       cause_position,
       par_delegation,
       row_hash,
       legislature_snapshot
FROM votes_deputes_snapshot
ON CONFLICT (scrutin_uid, depute_id) DO UPDATE SET groupe_id            = EXCLUDED.groupe_id,
                                                   groupe_legislature   = EXCLUDED.groupe_legislature,
                                                   mandat_ref           = EXCLUDED.mandat_ref,
                                                   position             = EXCLUDED.position,
                                                   cause_position       = EXCLUDED.cause_position,
                                                   par_delegation       = EXCLUDED.par_delegation,
                                                   row_hash             = EXCLUDED.row_hash,
                                                   legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE votes_deputes.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_votes_to_delete AS
SELECT vd.scrutin_uid, vd.depute_id
FROM votes_deputes vd
WHERE vd.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM votes_deputes_snapshot s
                  WHERE s.scrutin_uid = vd.scrutin_uid
                    AND s.depute_id = vd.depute_id);

DELETE
FROM votes_deputes vd USING tmp_votes_to_delete x
WHERE vd.scrutin_uid = x.scrutin_uid
  AND vd.depute_id = x.depute_id;
DROP TABLE tmp_votes_to_delete;

-- =====================================================
-- SCRUTINS AGREGATS
-- =====================================================

INSERT INTO scrutins_agregats (scrutin_uid, nombre_votants, suffrages_exprimes,
                               suffrages_requis, total_pour, total_contre,
                               total_abstentions, total_non_votants,
                               total_non_votants_volontaires, row_hash, legislature_snapshot)
SELECT scrutin_uid,
       nombre_votants,
       suffrages_exprimes,
       suffrages_requis,
       total_pour,
       total_contre,
       total_abstentions,
       total_non_votants,
       total_non_votants_volontaires,
       row_hash,
       legislature_snapshot
FROM scrutins_agregats_snapshot
ON CONFLICT (scrutin_uid) DO UPDATE SET nombre_votants                = EXCLUDED.nombre_votants,
                                        suffrages_exprimes            = EXCLUDED.suffrages_exprimes,
                                        suffrages_requis              = EXCLUDED.suffrages_requis,
                                        total_pour                    = EXCLUDED.total_pour,
                                        total_contre                  = EXCLUDED.total_contre,
                                        total_abstentions             = EXCLUDED.total_abstentions,
                                        total_non_votants             = EXCLUDED.total_non_votants,
                                        total_non_votants_volontaires = EXCLUDED.total_non_votants_volontaires,
                                        row_hash                      = EXCLUDED.row_hash,
                                        legislature_snapshot          = EXCLUDED.legislature_snapshot
WHERE scrutins_agregats.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_scrutins_agregats_to_delete AS
SELECT sa.scrutin_uid
FROM scrutins_agregats sa
WHERE sa.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1 FROM scrutins_agregats_snapshot s WHERE s.scrutin_uid = sa.scrutin_uid);

DELETE
FROM scrutins_agregats sa USING tmp_scrutins_agregats_to_delete x
WHERE sa.scrutin_uid = x.scrutin_uid;
DROP TABLE tmp_scrutins_agregats_to_delete;

-- =====================================================
-- SCRUTINS GROUPES AGREGATS
-- =====================================================

INSERT INTO scrutins_groupes_agregats (scrutin_uid, groupe_id, groupe_legislature,
                                       pour, contre, abstentions, non_votants,
                                       non_votants_volontaires, row_hash, legislature_snapshot)
SELECT scrutin_uid,
       groupe_id,
       groupe_legislature,
       pour,
       contre,
       abstentions,
       non_votants,
       non_votants_volontaires,
       row_hash,
       legislature_snapshot
FROM scrutins_groupes_agregats_snapshot
ON CONFLICT (scrutin_uid, groupe_id) DO UPDATE SET groupe_legislature      = EXCLUDED.groupe_legislature,
                                                   pour                    = EXCLUDED.pour,
                                                   contre                  = EXCLUDED.contre,
                                                   abstentions             = EXCLUDED.abstentions,
                                                   non_votants             = EXCLUDED.non_votants,
                                                   non_votants_volontaires = EXCLUDED.non_votants_volontaires,
                                                   row_hash                = EXCLUDED.row_hash,
                                                   legislature_snapshot    = EXCLUDED.legislature_snapshot
WHERE scrutins_groupes_agregats.row_hash != EXCLUDED.row_hash;

CREATE
    TEMP TABLE tmp_scrutins_groupes_agregats_to_delete AS
SELECT sga.scrutin_uid, sga.groupe_id
FROM scrutins_groupes_agregats sga
WHERE sga.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM scrutins_groupes_agregats_snapshot s
                  WHERE s.scrutin_uid = sga.scrutin_uid
                    AND s.groupe_id = sga.groupe_id);

DELETE
FROM scrutins_groupes_agregats sga USING tmp_scrutins_groupes_agregats_to_delete x
WHERE sga.scrutin_uid = x.scrutin_uid
  AND sga.groupe_id = x.groupe_id;
DROP TABLE tmp_scrutins_groupes_agregats_to_delete;

COMMIT;
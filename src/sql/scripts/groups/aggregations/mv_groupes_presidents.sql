CREATE MATERIALIZED VIEW IF NOT EXISTS mv_groupes_presidents AS
WITH legislatures as (select number
                      from param_legislatures),
     presidents_groupes as (select m.uid        as mandat_uid,
                                   m.acteur_uid,
                                   m.legislature,
                                   m.organe_uid as groupe_id,
                                   m.date_debut,
                                   m.date_fin,
                                   m.date_publication,
                                   m.code_qualite,
                                   m.lib_qualite,
                                   m.lib_qualite_sex,
                                   row_number() over (
                                       partition by m.legislature, m.organe_uid
                                       order by
                                           case when m.date_fin is null then 0 else 1 end,
                                           m.date_debut desc,
                                           m.date_publication desc nulls last,
                                           m.uid desc
                                       )        as rn
                            from mandats m
                                     inner join legislatures l
                                                on l.number = m.legislature
                            where m.type_organe = 'GP'
                              and m.code_qualite = 'Président')
select pg.legislature,
       pg.groupe_id,
       rg.groupe_legislature,
       rg.code       as groupe_code,
       rg.libelle    as groupe_libelle,
       pg.lib_qualite_sex,
       pg.acteur_uid,
       a.prenom,
       a.nom,
       pg.date_debut as mandat_president_debut,
       pg.date_fin   as mandat_president_fin,
       pg.mandat_uid
from presidents_groupes pg
         inner join acteurs a
                    on a.uid = pg.acteur_uid
         left join ref_groupes rg
                   on rg.groupe_id = pg.groupe_id
where pg.rn = 1
  and exists (select 1
              from acteurs_groupes ag
              where ag.acteur_uid = pg.acteur_uid
                and ag.groupe_id = pg.groupe_id
                and ag.groupe_legislature = pg.legislature)
order by pg.legislature desc,
         coalesce(rg.code, pg.groupe_id),
         a.nom,
         a.prenom;

CREATE UNIQUE INDEX IF NOT EXISTS mv_groupes_presidents_uq ON mv_groupes_presidents(acteur_uid, legislature, mandat_uid);

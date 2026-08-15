-- OK valide

create materialized view if not exists agg_groupes_stats_professions as
with legislatures_ref as (select pl.number as legislature,
                                 case
                                     when exists (select 1
                                                  from param_current_legislatures pcl
                                                  where pcl.number = pl.number) then current_date
                                     else pl.end_date
                                     end   as date_reference
                          from param_legislatures pl),
     members_at_ref_date as (select distinct ag.groupe_id,
                                             ag.groupe_legislature as legislature,
                                             ag.acteur_uid
                             from acteurs_groupes ag
                                      inner join legislatures_ref lr
                                                 on lr.legislature = ag.groupe_legislature
                             where lr.date_reference is not null
                               and ag.date_debut <= lr.date_reference
                               and (ag.date_fin is null or ag.date_fin >= lr.date_reference)),
     acteurs_dedup as (select a.uid,
                              coalesce(a.profession_libelle, 'Non renseignée')   as profession_libelle,
                              coalesce(a.profession_categorie, 'Non renseignée') as profession_categorie,
                              coalesce(a.profession_famille, 'Non renseignée')   as profession_famille,
                              row_number() over (
                                  partition by a.uid
                                  order by a.created_at desc, a.uid
                                  )                                              as rn
                       from acteurs a),
     base as (select m.legislature,
                     m.groupe_id,
                     rg.code                                             as groupe_code,
                     rg.libelle                                          as groupe_libelle,
                     coalesce(ad.profession_libelle, 'Non renseignée')   as profession_libelle,
                     coalesce(ad.profession_categorie, 'Non renseignée') as profession_categorie,
                     coalesce(ad.profession_famille, 'Non renseignée')   as profession_famille,
                     m.acteur_uid
              from members_at_ref_date m
                       left join acteurs_dedup ad
                                 on ad.uid = m.acteur_uid
                                     and ad.rn = 1
                       left join ref_groupes rg
                                 on rg.groupe_id = m.groupe_id
                                     and rg.groupe_legislature = m.legislature),
     counts as (select legislature,
                       groupe_id,
                       groupe_code,
                       groupe_libelle,
                       profession_libelle,
                       profession_categorie,
                       profession_famille,
                       count(distinct acteur_uid) as nb_acteurs
                from base
                group by legislature,
                         groupe_id,
                         groupe_code,
                         groupe_libelle,
                         profession_libelle,
                         profession_categorie,
                         profession_famille)
select c.legislature,
       c.groupe_id,
       c.groupe_code,
       c.groupe_libelle,
       c.profession_libelle,
       c.profession_categorie,
       c.profession_famille,
       c.nb_acteurs,
       egl.nb_acteurs_photo                                             as nb_total_groupe,
       round(100.0 * c.nb_acteurs / nullif(egl.nb_acteurs_photo, 0), 2) as pct_dans_groupe
from counts c
         inner join agg_groupes_effectifs_legislature egl
                    on egl.groupe_id = c.groupe_id
                        and egl.legislature = c.legislature;

create unique index if not exists agg_groupes_stats_professions_uq on agg_groupes_stats_professions (
                                                      groupe_id,
                                                      legislature,
                                                      profession_libelle,
                                                      profession_categorie,
                                                      profession_famille
    );
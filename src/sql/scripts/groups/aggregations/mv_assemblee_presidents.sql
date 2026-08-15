create materialized view if not exists mv_assemblee_presidents as
with ranked as (
    select
        m.uid as mandat_uid,
        m.acteur_uid,
        m.legislature,
        a.prenom,
        a.nom,
        m.date_debut,
        m.date_fin,
        m.date_publication,
        m.lib_qualite_sex,
        m.lib_qualite,
        row_number() over (
            partition by m.legislature
            order by
                case when m.date_fin is null then 0 else 1 end,
                m.date_debut desc,
                m.date_publication desc nulls last,
                m.uid desc
            ) as rn
    from mandats m
             inner join acteurs a
                        on m.acteur_uid = a.uid
    where m.type_organe = 'CONFPT'
      and m.code_qualite = 'Président de l''Assemblée nationale'
      and m.lib_qualite = 'Président de l''Assemblée nationale'
)
select
    mandat_uid,
    acteur_uid,
    legislature,
    prenom,
    nom,
    lib_qualite,
    lib_qualite_sex,
    date_debut,
    date_fin,
    date_publication
from ranked
where rn = 1;

CREATE UNIQUE INDEX IF NOT EXISTS mv_assemblee_presidents_uq ON mv_assemblee_presidents(legislature);

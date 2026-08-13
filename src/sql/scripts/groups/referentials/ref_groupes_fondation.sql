-- ref_groupes_fondation : référentiel manuel (donnée politique publique, pas
-- scrapée) — année de fondation et site officiel par identité de parti
-- (groupe_code), indépendant de la législature. Un parti renommé/scindé a un
-- nouveau code et donc sa propre ligne : pas de fusion historique (ex. RN
-- distinct de FN, LR distinct de DR, RE distinct de EPR).
--
-- "annee_fondation" = année d'adoption du nom/de l'identité tel qu'affiché
-- actuellement (ex. code renommé -> année du renommage), sauf quand le même
-- groupe_code est réutilisé sans changer d'une législature à l'autre (DEM,
-- HOR, RN, SOC, LIOT, GDR) : dans ce cas on garde l'année d'adoption du nom
-- porté par ce code précis, la plus ancienne pertinente. Sources : AN
-- (assemblee-nationale.fr), sites des partis, Wikipédia (recoupés).
--
-- "site_officiel" : site du groupe parlementaire quand il existe et est
-- distinct du site du parti (SOC, DR, ECOS, LIOT, GDR), sinon site du parti.
-- Laissé NULL quand aucune source fiable n'a été trouvée (EPR, RE) plutôt
-- que d'inventer une URL — à compléter après vérification manuelle.
--
-- Cas particulier UDR / UDDPLR : groupe d'Éric Ciotti renommé en cours de
-- 17e législature ("Groupe UDR" le 12/09/2024 -> "Union des droites pour la
-- République" le 05/09/2025), donc deux groupe_id/groupe_code distincts en
-- base pour la même filiation politique — traité comme deux entités
-- successives, pas un doublon à fusionner.

INSERT INTO ref_groupes_fondation (groupe_code, annee_fondation, site_officiel)
VALUES
    -- 17e législature (codes actuels)
    ('RN', 2018, 'https://rassemblementnational.fr'),
    ('HOR', 2021, 'https://horizonsleparti.fr'),
    ('EPR', 2024, 'https://parti-renaissance.fr/'),
    ('SOC', 2018, 'https://lessocialistes.fr'),
    ('DR', 2024, 'https://www.deputesdroiterepublicaine.fr'),
    ('ECOS', 2024, 'https://ecologisteetsocial.fr'),
    ('DEM', 2007, 'https://mouvementdemocrate.fr'),
    ('LIOT', 2022, 'https://www.groupeliot.fr'),
    ('LFI-NFP', 2024, 'https://lafranceinsoumise.fr'),
    ('GDR', 2007, 'https://groupe-communiste.assemblee-nationale.fr'),
    ('UDR', 2024, 'https://www.udr.fr'),
    ('UDDPLR', 2025, 'https://www.udr.fr'),

    -- 16e législature (codes propres à cette législature uniquement)
    ('LR', 2015, 'https://republicains.fr'),
    ('RE', 2022, 'https://parti-renaissance.fr'),
    ('ECOLO-NUPES', 2022, 'https://lesecologistes.fr'),
    ('GDR-NUPES', 2022, 'https://groupe-communiste.assemblee-nationale.fr'),
    ('LFI-NUPES', 2022, 'https://lafranceinsoumise.fr'),
    ('SOC-NUPES', 2022, 'https://lessocialistes.fr')
ON CONFLICT (groupe_code) DO UPDATE
    SET annee_fondation = EXCLUDED.annee_fondation,
        site_officiel   = EXCLUDED.site_officiel,
        updated_at      = now();

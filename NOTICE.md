# NOTICE — périmètre de la licence

Ce fichier précise ce que couvre (et ne couvre pas) la licence [`LICENSE`](./LICENSE)
(GNU AGPL-3.0) de ce dépôt. En cas de contradiction, la page
[Mentions légales](https://deputydex.fr/mentions-legales) du site (repo
`deputydex-front`) fait foi pour le public ; ce fichier fait foi pour les
contributeurs et réutilisateurs du code.

## Ce qui est sous licence AGPL-3.0

- Tout le code source de ce dépôt (`src/workflow/...` : téléchargement,
  parsing, import, référentiels, enrichissement, agrégation, monitoring)
  ainsi que le schéma Prisma et ses migrations (`prisma/`).
- Toute personne peut lire, auditer, forker et modifier ce code. Toute
  personne qui déploie une version modifiée de ce pipeline, y compris pour
  la faire tourner comme service accessible publiquement (obligation propre
  à l'AGPL, contrairement à une GPL classique), doit republier le code
  source correspondant sous la même licence.

## Ce qui est explicitement exclu de l'AGPL-3.0

- **La marque, le nom « Députédex » et le logo associé** ne sont pas
  couverts par cette licence de code. L'AGPL-3.0 porte sur le droit
  d'auteur du code, pas sur le droit des marques : forker ce dépôt
  n'autorise pas à réutiliser le nom, le logo ou l'identité visuelle
  « Députédex » pour un autre service, a fortiori un service concurrent.
- Toute dépendance tierce listée dans `package.json` reste régie par sa
  propre licence, telle quelle : l'AGPL-3.0 de ce dépôt ne la remplace ni
  ne la modifie.
- **Les données parlementaires traitées par ce pipeline** (députés,
  groupes, mandats, scrutins, votes, amendements, dossiers, documents) ne
  sont ni notre code ni notre propriété : elles proviennent de l'open data
  de l'Assemblée nationale sous
  [Licence Ouverte / Open Licence Etalab](https://www.etalab.gouv.fr/licence-ouverte-open-licence/)
  et restent réutilisables selon les termes de cette licence,
  indépendamment de l'AGPL-3.0 appliquée au code de ce dépôt.

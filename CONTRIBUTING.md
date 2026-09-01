# Contribuer à deputydex-data

Merci de l'intérêt porté à Députédex ! Ce dépôt est l'ETL de l'écosystème —
téléchargement, parsing, import, référentiels, enrichissement et agrégation
des données publiques de l'Assemblée nationale (voir aussi
[`deputydex-front`](https://github.com/Lanadk/deputydex), le front/API qui
consomme ces données). La page [/contribute](https://deputydex.fr/contribute)
du site donne une vue d'ensemble accessible des deux dépôts ; ce fichier est
la référence technique côté contribution pour celui-ci.

## Comment contribuer

- 🐛 **Bug** (donnée manquante, incohérente, étape du pipeline en échec) →
  ouvrez une [issue](https://github.com/Lanadk/deputydex-data/issues/new)
  détaillée : domaine concerné, commande lancée, log d'erreur.
- 💡 **Idée / amélioration** → même chose, en précisant le cas d'usage.
- 🔧 **Pull request** → forkez le repo, créez une branche depuis `master`,
  ouvrez la PR. Pas besoin de discuter au préalable pour un fix évident ;
  pour un changement structurant (notamment tout ce qui touche
  `prisma/schema.prisma`), une issue en amont évite le travail perdu.

## Avant d'ouvrir une PR

- Lisez le [README](./README.md), en particulier
  [Architecture du pipeline](./README.md#architecture-du-pipeline) et
  [Travailler avec Prisma](./README.md#travailler-avec-prisma).
- `npm run build` (`tsc --noEmit`) et `npm test` (unitaires) doivent passer.
  Les tests d'intégration (`npm run test:integration`) nécessitent une base
  Postgres réelle (`npm run docker:db`) — lancez-les si votre changement
  touche l'import/la base.
- Suivez le découpage hexagonal léger existant pour les workflows
  (`domain/`, `infrastructure/`, `job/`) plutôt que d'en inventer un
  nouveau.
- Pas de config de lint dans ce repo actuellement — respectez le style du
  code environnant.
- **Ce dépôt est l'unique propriétaire du schéma de base de données.** Si
  votre PR modifie `prisma/schema.prisma`, elle doit inclure la migration
  générée (`npm run prisma:migrate-dev`). Le job CI `sync-schema` réplique
  ensuite automatiquement le fichier vers `deputydex-front` au merge sur
  `master` — n'éditez jamais le schéma directement côté front.

## Licence de vos contributions

Ce dépôt est sous licence [GNU AGPL-3.0](./LICENSE) (voir
[`NOTICE.md`](./NOTICE.md) pour le détail du périmètre). En ouvrant une pull
request, vous acceptez que votre contribution soit distribuée sous cette
même licence — comme le veut l'usage standard sur GitHub (« inbound =
outbound »). Il n'y a pas de CLA (Contributor License Agreement) à signer.

## Ce qu'une contribution ne couvre pas

Le nom « Députédex », son logo et son identité visuelle ne sont pas
couverts par la licence de code : un fork de ce dépôt ne donne pas le droit
de les réutiliser pour un autre service. Voir la section
[Propriété intellectuelle](https://deputydex.fr/mentions-legales#propriete-intellectuelle)
des mentions légales du site.

## Questions

Pour toute question qui ne rentre pas dans une issue GitHub :
[contact@ottmanbecuwe.com](mailto:contact@ottmanbecuwe.com).

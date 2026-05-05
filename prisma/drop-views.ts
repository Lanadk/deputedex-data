import { prisma } from "./prisma";

async function main() {
    console.log('🗑️ Suppression des vues matérialisées...');

    await prisma.$executeRawUnsafe(`
     -- ACTEURS VIEWS
        DROP MATERIALIZED VIEW IF EXISTS agg_acteurs_stats_professions CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_acteurs_stats_genre CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_acteurs_stats_age CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_acteurs_stats_geographie_election CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_acteurs_stats_geographie_naissance CASCADE;
        
     -- GROUPE VIEWS
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_effectifs_current CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_effectifs_legislature CASCADE;       
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_cohesion_mensuelle CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_cohesion_legislature CASCADE;        
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_couverture_scrutins CASCADE;        
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_participation_legislature CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_participation_mensuelle CASCADE;        
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_expression_votes CASCADE;       
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_votes_positions_politiques CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_votes_positions_comptables CASCADE;        
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_demographie_legislature CASCADE;        
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_stabilite CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_proximite_votes_legislature CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_proximite_votes_mensuelle CASCADE;     
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_professions CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_professions_categories CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_professions_familles CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_fiche_infos CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_age CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_parite CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_cumul_mandats CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_geographie_election CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_geographie_dep_naissance CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_geographie_pays_naissance CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_groupes_stats_tranche_age CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS mv_groupes_presidents CASCADE;
     
     -- DEPUTES VIEWS   
        DROP MATERIALIZED VIEW IF EXISTS agg_deputes_cards CASCADE;
        
     -- CALENDAR ACTIVITY VIEWS
        DROP MATERIALIZED VIEW IF EXISTS agg_activity_calendar_mv CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_activity_calendar_details_mv CASCADE;
        
     -- ASSEMBLEE VIEWS
        DROP MATERIALIZED VIEW IF EXISTS mv_assemblee_presidents CASCADE;
        DROP MATERIALIZED VIEW IF EXISTS agg_assemblee_stats_participation_legislature CASCADE;
    `);

    console.log('✅ Vues matérialisées supprimées');
}

main()
    .catch((e) => {
        console.error('❌ Erreur:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
        process.exit(0);
    });
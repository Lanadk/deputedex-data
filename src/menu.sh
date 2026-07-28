#!/usr/bin/env bash
set -e

# ==============================================================================
# DEPUTYDEX - MAIN MENU
# ==============================================================================

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# -- Download ------------------------------------------------------------------
run_download_all()              { npx ts-node ./workflow/download/job/trtCollecteData.ts; }

# -- Parser --------------------------------------------------------------------
run_parser_all()                { npx ts-node ./workflow/parser/job/trtCheckCollecte.ts; }
run_parser_acteurs()            { npx ts-node ./workflow/parser/job/unit-parser/parseActeurs.ts; }
run_parser_scrutins()           { npx ts-node ./workflow/parser/job/unit-parser/parseScrutins.ts; }
run_parser_amendements()        { npx ts-node ./workflow/parser/job/unit-parser/parseAmendements.ts; }
run_parser_dossiers()           { npx ts-node ./workflow/parser/job/unit-parser/parseDossiers.ts; }
run_parser_documents()          { npx ts-node ./workflow/parser/job/unit-parser/parseDocuments.ts; }

# -- Import --------------------------------------------------------------------
run_import_all()                { npx ts-node ./workflow/import/job/trtImportCollecte.ts "$1"; }
run_import_acteurs()            { npx ts-node ./workflow/import/job/unit-import/importActeurs.ts; }
run_import_scrutins()           { npx ts-node ./workflow/import/job/unit-import/importScrutins.ts; }
run_import_mandats()            { npx ts-node ./workflow/import/job/unit-import/importMandats.ts; }
run_import_amendements()        { npx ts-node ./workflow/import/job/unit-import/importAmendements.ts; }
run_import_dossiers()           { npx ts-node ./workflow/import/job/unit-import/importDossiers.ts; }
run_import_documents()          { npx ts-node ./workflow/import/job/unit-import/importDocuments.ts; }

# -- Aggregation ---------------------------------------------------------------
run_aggregate_all_one_shot()      { npx ts-node ./workflow/aggregat/job/trtAggregatCollecte-oneshot.ts; }
run_aggregate_all_refresh()       { npx ts-node ./workflow/aggregat/job/trtAggregatCollecte.ts; }
run_aggregate_acteurs_one_shot()  { npx ts-node ./workflow/aggregat/job/acteurs/aggregation-oneshot.ts; }
run_aggregate_acteurs_refresh()   { npx ts-node ./workflow/aggregat/job/acteurs/aggregation.ts; }
run_aggregate_groupes_one_shot()  { npx ts-node ./workflow/aggregat/job/groups/aggregation-oneshot.ts; }
run_aggregate_groupes_refresh()   { npx ts-node ./workflow/aggregat/job/groups/aggregation.ts; }
run_aggregate_calendar_one_shot() { npx ts-node ./workflow/aggregat/job/calendar/aggregation-oneshot.ts; }
run_aggregate_calendar_refresh()  { npx ts-node ./workflow/aggregat/job/calendar/aggregation.ts; }
run_aggregate_deputes_one_shot()  { npx ts-node ./workflow/aggregat/job/deputes/aggregation-oneshot.ts; }
run_aggregate_deputes_refresh()   { npx ts-node ./workflow/aggregat/job/deputes/aggregation.ts; }

# -- Referentiels  ---------------------------------------------------------------
run_update_all_referentials_tables() { npx ts-node ./workflow/referentials/job/trtUpdateReferentials.ts; }

# -- Enrichment  ---------------------------------------------------------------
run_all_enrichment_tables() { npx ts-node ./workflow/enrichment/job/trtEnrichmentCollecte.ts; }

# -- Dataset update monitoring  ---------------------------------------------------------------
run_monitor_dataset_update() { npx ts-node ./workflow/_common/job/logDatasetUpdate.ts; }

# ==============================================================================
# WORKFLOWS
# ==============================================================================

workflow_init() {
    echo "🚀 Running INIT Workflow (Download + Parser + Import + Ref CREATION + Enrichment + Aggregate CREATION)..."
    run_download_all
    run_parser_all
    run_import_all --auto-cleanup
    run_update_all_referentials_tables
    run_all_enrichment_tables
    run_aggregate_all_one_shot

    run_monitor_dataset_update
    echo "✅ Init Workflow completed"
}

workflow_update() {
    echo "🔄 Running UPDATE Workflow (Download + Parser + Import + Ref UPDATE + Enrichment + Aggregate UPDATE)..."
    run_download_all
    run_parser_all
    run_import_all --auto-cleanup
    run_update_all_referentials_tables
    run_all_enrichment_tables
    run_aggregate_all_refresh

    run_monitor_dataset_update
    echo "✅ Update Workflow completed"
}

# ==============================================================================
# SUB MENUS
# ==============================================================================

download_menu() {
    while true; do
        echo "=============================================="
        echo "  DOWNLOAD JOBS"
        echo "=============================================="
        echo ""
        echo "1) Download All"
        echo "0) Back"
        echo ""
        echo "=============================================="
        read -p "Select an option: " option

        case $option in
            1) run_download_all ;;
            0) return ;;
            *) echo "⚠️  Invalid option, please try again." ;;
        esac
    done
}

parser_menu() {
    while true; do
        echo "=============================================="
        echo "  PARSER JOBS"
        echo "=============================================="
        echo ""
        echo "1) Parse All"
        echo "2) Parse Acteurs"
        echo "3) Parse Scrutins"
        echo "4) Parse Amendements"
        echo "5) Parse Dossiers"
        echo "6) Parse Documents"
        echo "0) Back"
        echo ""
        echo "=============================================="
        read -p "Select an option: " option

        case $option in
            1) run_parser_all ;;
            2) run_parser_acteurs ;;
            3) run_parser_scrutins ;;
            4) run_parser_amendements ;;
            5) run_parser_dossiers ;;
            6) run_parser_documents ;;
            0) return ;;
            *) echo "⚠️  Invalid option, please try again." ;;
        esac
    done
}

import_menu() {
    while true; do
        echo "=============================================="
        echo "  IMPORT JOBS"
        echo "=============================================="
        echo ""
        echo "1) Import All"
        echo "2) Import Acteurs"
        echo "3) Import Scrutins"
        echo "4) Import Mandats"
        echo "5) Import Amendements"
        echo "6) Import Dossiers"
        echo "7) Import Documents"
        echo "0) Back"
        echo ""
        echo "=============================================="
        read -p "Select an option: " option

        case $option in
            1) run_import_all --auto-cleanup ;;
            2) run_import_acteurs ;;
            3) run_import_scrutins ;;
            4) run_import_mandats ;;
            5) run_import_amendements ;;
            6) run_import_dossiers;;
            7) run_import_documents;;
            0) return ;;
            *) echo "⚠️  Invalid option, please try again." ;;
        esac
    done
}

aggregate_menu() {
    while true; do
        echo "=============================================="
        echo "  AGGREGATION JOBS"
        echo "=============================================="
        echo ""
        echo "1) Aggregate All (Refresh)"
        echo "2) Aggregate All (Create - One shot)"
        echo "3) Aggregate Acteurs (Refresh)"
        echo "4) Aggregate Acteurs (Create - One shot)"
        echo "5) Aggregate Groupes (Refresh)"
        echo "6) Aggregate Groupes (Create - One shot)"
        echo "7) Aggregate Calendar (Refresh)"
        echo "8) Aggregate Calendar (Create - One shot)"
        echo "9) Aggregate Deputes (Refresh)"
        echo "10) Aggregate Deputes (Create - One shot)"
        echo "0) Back"
        echo ""
        echo "=============================================="
        read -p "Select an option: " option

        case $option in
            1) run_aggregate_all_refresh ;;
            2)
                read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_all_one_shot; fi
                ;;
            3) run_aggregate_acteurs_refresh ;;
            4)
                read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_acteurs_one_shot; fi
                ;;
            5) run_aggregate_groupes_refresh ;;
            6)
                read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_groupes_one_shot; fi
                ;;
            7) run_aggregate_calendar_refresh ;;
            8)
                read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_calendar_one_shot; fi
                ;;
            9) run_aggregate_deputes_refresh ;;
            10)
                read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_deputes_one_shot; fi
                ;;
            0) return ;;
            *) echo "⚠️  Invalid option, please try again." ;;
        esac
    done
}

unit_job_menu() {
    while true; do
        echo "=============================================="
        echo "  UNIT JOB MENU"
        echo "=============================================="
        echo ""
        echo "1) Download Jobs"
        echo "2) Parser Jobs"
        echo "3) Import Jobs"
        echo "4) Aggregation Jobs"
        echo "0) Back"
        echo ""
        echo "=============================================="
        read -p "Select an option: " option

        case $option in
            1) download_menu ;;
            2) parser_menu ;;
            3) import_menu ;;
            4) aggregate_menu ;;
            0) return ;;
            *) echo "⚠️  Invalid option, please try again." ;;
        esac
    done
}

# ==============================================================================
# MAIN MENU
# ==============================================================================

while true; do
    echo "=============================================="
    echo " "
    echo "  DEPUTYDEX MAIN MENU"
    echo " "
    echo "=============================================="
    echo " ----------- "
    echo "  WORKFLOWS"
    echo " ----------- "
    echo "  1) Init          (Download + Parse + Import + Referentials CREATE + Enrichment + Aggregate CREATE)"
    echo "  2) Update        (Download + Parse + Import + Referentials UPDATE + Enrichment + Aggregate UPDATE)"
    echo " "
    echo " ----------- "
    echo "  FULL JOBS"
    echo " ----------- "
    echo "  3) Download All"
    echo "  4) Parse All"
    echo "  5) Import All"
    echo "  6) Aggregate All (Refresh)"
    echo "  7) Aggregate All (One shot)"
    echo "  8) Referentials Create / Update"
    echo "  9) Enrichment All"
    echo " "
    echo " ----------- "
    echo "  UNIT JOBS"
    echo " ----------- "
    echo "  11) See unit Jobs"
    echo " "
    echo "  0) Quit"
    echo " "
    echo "=============================================="
    read -p "Select an option: " option

    case $option in
        1) workflow_init ;;
        2) workflow_update ;;
        3) echo "📥 Downloading All..."  && run_download_all ;;
        4) echo "🛠  Parsing All..."     && run_parser_all ;;
        5) echo "📤 Importing All..."    && run_import_all --auto-cleanup ;;
        6) echo "📊 Aggregating All..."  && run_aggregate_all_refresh ;;
        7)
            read -p "⚠️  ONE SHOT - À lancer une seule fois. Confirmer ? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then run_aggregate_all_one_shot; fi
            ;;
        8) echo "📊 Referentials Update ..."  &&  run_update_all_referentials_tables ;;
        9) echo "📊 Enrichment All ..."  &&  run_all_enrichment_tables ;;
        11) unit_job_menu ;;
        0) echo "Bye! 👋" && exit 0 ;;
        *) echo "⚠️  Invalid option, please try again." ;;
    esac

    echo ""
    echo "=============================================="
    echo "✅ Done"
    echo "=============================================="
    echo ""
done
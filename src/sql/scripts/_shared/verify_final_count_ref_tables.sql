-- ==============================================================================
-- VERIFY FINAL COUNT REF TABLES
-- Vérifie que les tables de référence sont bien peuplées
-- ==============================================================================

SELECT 'ref_scrutin_type' AS table_name, COUNT(*) AS total FROM ref_scrutin_type
UNION ALL
SELECT 'ref_organe_type', COUNT(*) FROM ref_organe_type
UNION ALL
SELECT 'ref_groupes', COUNT(*) FROM ref_groupes
UNION ALL
SELECT 'ref_acteurs_photos', COUNT(*) FROM ref_acteurs_photos
ORDER BY table_name;
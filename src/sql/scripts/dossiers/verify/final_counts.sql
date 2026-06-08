SELECT 'dossier_parlementaire', COUNT(*) FROM dossier_parlementaire
UNION ALL
SELECT 'dossier_initiateur', COUNT(*) FROM dossier_initiateur
UNION ALL
SELECT 'acte_legislatif', COUNT(*) FROM acte_legislatif
UNION ALL
SELECT 'acte_rapporteur', COUNT(*) FROM acte_rapporteur
UNION ALL
SELECT 'acte_texte_associe', COUNT(*) FROM acte_texte_associe
UNION ALL
SELECT 'acte_reunion', COUNT(*) FROM acte_reunion
UNION ALL
SELECT 'acte_vote', COUNT(*) FROM acte_vote
UNION ALL
SELECT 'acte_decision', COUNT(*) FROM acte_decision;
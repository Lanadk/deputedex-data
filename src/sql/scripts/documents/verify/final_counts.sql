SELECT 'documents_parlementaires', COUNT(*) FROM documents_parlementaires
UNION ALL
SELECT 'documents_classifications', COUNT(*) FROM documents_classifications
UNION ALL
SELECT 'documents_auteurs', COUNT(*) FROM documents_auteurs
UNION ALL
SELECT 'documents_co_signataires', COUNT(*) FROM documents_co_signataires
UNION ALL
SELECT 'documents_organes_referents', COUNT(*) FROM documents_organes_referents
UNION ALL
SELECT 'documents_imprimeries', COUNT(*) FROM documents_imprimeries
UNION ALL
SELECT 'documents_depot_amendements', COUNT(*) FROM documents_depot_amendements;
-- =====================================================
-- VERIFICAR VALORES DOS ENUMS DE AVALIAÇÃO
-- =====================================================

-- Verificar valores do enum espirito
SELECT 
    'espirito' as campo,
    e.enumlabel as valor,
    e.enumsortorder as ordem
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'intellimen_espirito_enum'
ORDER BY e.enumsortorder;

-- Verificar valores do enum caractere
SELECT 
    'caractere' as campo,
    e.enumlabel as valor,
    e.enumsortorder as ordem
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'intellimen_caractere_enum'
ORDER BY e.enumsortorder;

-- Verificar valores do enum disposicao
SELECT 
    'disposicao' as campo,
    e.enumlabel as valor,
    e.enumsortorder as ordem
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'intellimen_disposicao_enum'
ORDER BY e.enumsortorder;

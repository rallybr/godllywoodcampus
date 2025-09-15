-- =====================================================
-- VERIFICAR TODOS OS ENUMS DISPONÍVEIS
-- =====================================================

-- Listar todos os enums que existem no banco
SELECT 
    t.typname as nome_enum,
    e.enumlabel as valor,
    e.enumsortorder as ordem
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typtype = 'e'
ORDER BY t.typname, e.enumsortorder;

-- Verificar especificamente se existem enums com nomes similares
SELECT 
    t.typname as nome_enum,
    e.enumlabel as valor
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname ILIKE '%espirito%' 
   OR t.typname ILIKE '%caractere%' 
   OR t.typname ILIKE '%disposicao%'
   OR t.typname ILIKE '%avaliacao%'
   OR t.typname ILIKE '%intellimen%'
ORDER BY t.typname, e.enumsortorder;

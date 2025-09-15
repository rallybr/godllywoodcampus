-- =====================================================
-- VERIFICAR ENUMS ESPECÍFICOS PARA AVALIAÇÕES
-- =====================================================

-- Verificar todos os enums existentes no banco
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value,
    e.enumsortorder
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typtype = 'e'
ORDER BY t.typname, e.enumsortorder;

-- Verificar se existem enums com nomes similares aos campos
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname ILIKE '%espirito%' 
   OR t.typname ILIKE '%caractere%' 
   OR t.typname ILIKE '%disposicao%'
   OR t.typname ILIKE '%avaliacao%'
   OR t.typname ILIKE '%avaliar%'
ORDER BY t.typname, e.enumsortorder;

-- Verificar se os campos da tabela avaliacoes são do tipo enum
SELECT 
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_name = 'avaliacoes' 
  AND column_name IN ('espirito', 'caractere', 'disposicao')
ORDER BY column_name;

-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA AVALIACOES
-- =====================================================

-- Verificar estrutura da tabela avaliacoes
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'avaliacoes' 
ORDER BY ordinal_position;

-- Verificar se existem enums relacionados
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname LIKE '%espirito%' 
   OR t.typname LIKE '%caractere%' 
   OR t.typname LIKE '%disposicao%'
   OR t.typname LIKE '%avaliacao%'
ORDER BY t.typname, e.enumsortorder;

-- Verificar constraints da tabela avaliacoes
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'avaliacoes';

-- Verificar se a tabela tem dados de exemplo
SELECT COUNT(*) as total_avaliacoes FROM avaliacoes;

-- Verificar estrutura da tabela roles para confirmar os níveis
SELECT 
    slug, 
    nome, 
    descricao, 
    nivel_hierarquico
FROM roles 
WHERE slug IN (
    'administrador',
    'colaborador', 
    'lider_nacional_iurd',
    'lider_nacional_fju',
    'lider_estadual_iurd',
    'lider_estadual_fju',
    'lider_bloco_iurd',
    'lider_bloco_fju',
    'lider_regional_iurd',
    'lider_igreja_iurd'
)
ORDER BY nivel_hierarquico;

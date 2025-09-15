-- =====================================================
-- VERIFICAR POLÍTICAS RLS DA TABELA AVALIACOES
-- =====================================================

-- Verificar se RLS está habilitado na tabela avaliacoes
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename = 'avaliacoes';

-- Verificar políticas existentes na tabela avaliacoes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'avaliacoes'
ORDER BY policyname;

-- Verificar se a tabela avaliacoes existe e sua estrutura
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'avaliacoes' 
ORDER BY ordinal_position;

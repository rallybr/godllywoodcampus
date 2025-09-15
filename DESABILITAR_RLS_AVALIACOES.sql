-- =====================================================
-- DESABILITAR RLS TEMPORARIAMENTE NA TABELA AVALIACOES
-- =====================================================

-- Desabilitar RLS na tabela avaliacoes
ALTER TABLE avaliacoes DISABLE ROW LEVEL SECURITY;

-- Verificar se RLS foi desabilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename = 'avaliacoes';

-- Testar inserção sem RLS
INSERT INTO avaliacoes (jovem_id, user_id, espirito, caractere, disposicao, data)
VALUES (
    (SELECT id FROM jovens LIMIT 1),
    auth.uid(),
    'bom',
    'bom', 
    'normal',
    CURRENT_DATE
);

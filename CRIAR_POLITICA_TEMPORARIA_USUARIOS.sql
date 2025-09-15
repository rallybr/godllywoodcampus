-- =====================================================
-- CRIAR POLÍTICA TEMPORÁRIA MAIS PERMISSIVA
-- =====================================================

-- Remover política restritiva temporariamente
DROP POLICY IF EXISTS usuarios_self_select ON usuarios;

-- Criar política mais permissiva para SELECT
CREATE POLICY usuarios_select_permissive ON usuarios
FOR SELECT
TO public
USING (true);

-- Verificar se foi criada
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'usuarios' 
AND policyname = 'usuarios_select_permissive';

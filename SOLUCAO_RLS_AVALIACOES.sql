-- =====================================================
-- SOLUÇÃO TEMPORÁRIA PARA RLS AVALIAÇÕES
-- =====================================================

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "avaliacoes_admin_colab" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_by_jovem_access" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_delete_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_insert_by_jovem_access" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_insert_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_select_policy" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_self_delete" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_self_update" ON avaliacoes;
DROP POLICY IF EXISTS "avaliacoes_update_policy" ON avaliacoes;

-- Criar política simples e permissiva para INSERT
CREATE POLICY "avaliacoes_allow_insert" ON avaliacoes
FOR INSERT
WITH CHECK (true);

-- Criar política simples e permissiva para SELECT
CREATE POLICY "avaliacoes_allow_select" ON avaliacoes
FOR SELECT
USING (true);

-- Criar política simples e permissiva para UPDATE
CREATE POLICY "avaliacoes_allow_update" ON avaliacoes
FOR UPDATE
USING (true)
WITH CHECK (true);

-- Criar política simples e permissiva para DELETE
CREATE POLICY "avaliacoes_allow_delete" ON avaliacoes
FOR DELETE
USING (true);

-- Verificar se as políticas foram criadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'avaliacoes'
ORDER BY policyname;

-- Testar inserção simples
INSERT INTO avaliacoes (jovem_id, user_id, espirito, caractere, disposicao, data)
VALUES (
    (SELECT id FROM jovens LIMIT 1),
    auth.uid(),
    'bom',
    'bom', 
    'normal',
    CURRENT_DATE
);

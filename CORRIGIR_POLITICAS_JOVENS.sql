-- =====================================================
-- CORRIGIR POLÍTICAS RLS DA TABELA JOVENS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Corrigir políticas RLS da tabela jovens

-- =====================================================
-- 1. REMOVER POLÍTICAS EXISTENTES
-- =====================================================

DO $$ 
BEGIN
    -- Remover políticas existentes
    DROP POLICY IF EXISTS "jovens_admin_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_colaborador_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_lider_estadual_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_lider_bloco_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_lider_regional_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_lider_igreja_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_self_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_select_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_insert_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_update_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_delete_policy" ON jovens;
    DROP POLICY IF EXISTS "jovens_all_policy" ON jovens;
    
    RAISE NOTICE 'Políticas antigas removidas';
END $$;

-- =====================================================
-- 2. CRIAR POLÍTICAS CORRETAS
-- =====================================================

-- Política para administradores (acesso total)
CREATE POLICY "jovens_admin_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (is_admin_user())
    WITH CHECK (is_admin_user());

-- Política para colaboradores (acesso total)
CREATE POLICY "jovens_colaborador_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (has_role('colaborador'))
    WITH CHECK (has_role('colaborador'));

-- Política para líderes estaduais
CREATE POLICY "jovens_lider_estadual_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug LIKE 'lider_estadual_%'
            AND ur.estado_id = jovens.estado_id
            AND ur.ativo = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug LIKE 'lider_estadual_%'
            AND ur.estado_id = jovens.estado_id
            AND ur.ativo = true
        )
    );

-- Política para líderes de bloco
CREATE POLICY "jovens_lider_bloco_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug LIKE 'lider_bloco_%'
            AND ur.bloco_id = jovens.bloco_id
            AND ur.ativo = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug LIKE 'lider_bloco_%'
            AND ur.bloco_id = jovens.bloco_id
            AND ur.ativo = true
        )
    );

-- Política para líderes regionais
CREATE POLICY "jovens_lider_regional_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug = 'lider_regional_iurd'
            AND ur.regiao_id = jovens.regiao_id
            AND ur.ativo = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug = 'lider_regional_iurd'
            AND ur.regiao_id = jovens.regiao_id
            AND ur.ativo = true
        )
    );

-- Política para líderes de igreja
CREATE POLICY "jovens_lider_igreja_policy" ON jovens
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug = 'lider_igreja_iurd'
            AND ur.igreja_id = jovens.igreja_id
            AND ur.ativo = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
            AND r.slug = 'lider_igreja_iurd'
            AND ur.igreja_id = jovens.igreja_id
            AND ur.ativo = true
        )
    );

-- =====================================================
-- 3. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

SELECT 
    'POLÍTICAS CRIADAS' as status,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- =====================================================
-- 4. TESTAR INSERÇÃO SIMPLES
-- =====================================================

-- Teste de inserção simples
INSERT INTO jovens (
    nome_completo,
    data_nasc,
    whatsapp,
    estado_civil,
    edicao,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id,
    edicao_id,
    idade
) VALUES (
    'Teste RLS',
    '2000-01-01',
    '11999999999',
    'solteiro',
    '2024',
    'c20e70c2-92e6-4c50-96a5-177822095a25'::uuid,
    'b0cb2a8a-5b89-478b-95a9-a5bb8e84f06d'::uuid,
    '84cff91c-3afa-49da-b211-24f50f7cb2ab'::uuid,
    'd3301078-fc09-4131-b9e8-03c78570a774'::uuid,
    '78507ba7-d7cf-4476-8505-ffdc44852c50'::uuid,
    24
);

-- Verificar se foi inserido
SELECT 
    'TESTE INSERÇÃO' as status,
    id,
    nome_completo,
    data_cadastro
FROM jovens 
WHERE nome_completo = 'Teste RLS'
ORDER BY data_cadastro DESC
LIMIT 1;

-- Limpar teste
DELETE FROM jovens WHERE nome_completo = 'Teste RLS';

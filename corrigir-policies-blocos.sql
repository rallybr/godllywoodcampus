-- =====================================================
-- CORREÇÃO DAS POLICIES DA TABELA BLOCOS
-- =====================================================

-- 1. Verificar se RLS está habilitado
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;

-- 2. Remover policies existentes (se houver)
DROP POLICY IF EXISTS "allow_read_all_blocos" ON public.blocos;
DROP POLICY IF EXISTS "blocos_select_all" ON public.blocos;
DROP POLICY IF EXISTS "blocos_admin_modify" ON public.blocos;
DROP POLICY IF EXISTS "blocos_insert_admin" ON public.blocos;
DROP POLICY IF EXISTS "blocos_update_admin" ON public.blocos;
DROP POLICY IF EXISTS "blocos_delete_admin" ON public.blocos;

-- 3. Criar policies corretas para blocos

-- Policy para SELECT (leitura) - todos podem ler
CREATE POLICY "blocos_select_all" ON public.blocos
    FOR SELECT
    USING (true);

-- Policy para INSERT (inserção) - apenas administradores e líderes
CREATE POLICY "blocos_insert_admin" ON public.blocos
    FOR INSERT
    WITH CHECK (
        -- Administradores podem inserir
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
        OR
        -- Líderes nacionais podem inserir
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
        )
        OR
        -- Líderes estaduais podem inserir blocos do seu estado
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = blocos.estado_id
        )
    );

-- Policy para UPDATE (atualização) - apenas administradores e líderes
CREATE POLICY "blocos_update_admin" ON public.blocos
    FOR UPDATE
    USING (
        -- Administradores podem atualizar
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
        OR
        -- Líderes nacionais podem atualizar
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
        )
        OR
        -- Líderes estaduais podem atualizar blocos do seu estado
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = blocos.estado_id
        )
    )
    WITH CHECK (
        -- Mesmas condições para WITH CHECK
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = blocos.estado_id
        )
    );

-- Policy para DELETE (exclusão) - apenas administradores
CREATE POLICY "blocos_delete_admin" ON public.blocos
    FOR DELETE
    USING (
        -- Apenas administradores podem excluir
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
    );

-- 4. Verificar se as policies foram criadas
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
WHERE tablename = 'blocos'
ORDER BY policyname;

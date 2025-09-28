-- =====================================================
-- CORREÇÃO DAS POLICIES DAS TABELAS GEOGRÁFICAS
-- =====================================================

-- =====================================================
-- TABELA REGIÕES
-- =====================================================

-- Habilitar RLS
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;

-- Remover policies existentes
DROP POLICY IF EXISTS "allow_read_all_regioes" ON public.regioes;
DROP POLICY IF EXISTS "regioes_select_all" ON public.regioes;
DROP POLICY IF EXISTS "regioes_insert_admin" ON public.regioes;
DROP POLICY IF EXISTS "regioes_update_admin" ON public.regioes;
DROP POLICY IF EXISTS "regioes_delete_admin" ON public.regioes;

-- Policy para SELECT (leitura) - todos podem ler
CREATE POLICY "regioes_select_all" ON public.regioes
    FOR SELECT
    USING (true);

-- Policy para INSERT (inserção) - apenas administradores e líderes
CREATE POLICY "regioes_insert_admin" ON public.regioes
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
        -- Líderes estaduais podem inserir regiões dos blocos do seu estado
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.blocos b ON b.id = regioes.bloco_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        -- Líderes de bloco podem inserir regiões do seu bloco
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = regioes.bloco_id
        )
    );

-- Policy para UPDATE (atualização)
CREATE POLICY "regioes_update_admin" ON public.regioes
    FOR UPDATE
    USING (
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
            JOIN public.blocos b ON b.id = regioes.bloco_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = regioes.bloco_id
        )
    )
    WITH CHECK (
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
            JOIN public.blocos b ON b.id = regioes.bloco_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = regioes.bloco_id
        )
    );

-- Policy para DELETE (exclusão) - apenas administradores
CREATE POLICY "regioes_delete_admin" ON public.regioes
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
    );

-- =====================================================
-- TABELA IGREJAS
-- =====================================================

-- Habilitar RLS
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;

-- Remover policies existentes
DROP POLICY IF EXISTS "allow_read_all_igrejas" ON public.igrejas;
DROP POLICY IF EXISTS "igrejas_select_all" ON public.igrejas;
DROP POLICY IF EXISTS "igrejas_insert_admin" ON public.igrejas;
DROP POLICY IF EXISTS "igrejas_update_admin" ON public.igrejas;
DROP POLICY IF EXISTS "igrejas_delete_admin" ON public.igrejas;

-- Policy para SELECT (leitura) - todos podem ler
CREATE POLICY "igrejas_select_all" ON public.igrejas
    FOR SELECT
    USING (true);

-- Policy para INSERT (inserção) - apenas administradores e líderes
CREATE POLICY "igrejas_insert_admin" ON public.igrejas
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
        -- Líderes estaduais podem inserir igrejas das regiões dos blocos do seu estado
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.blocos b ON b.id = (
                SELECT r.bloco_id FROM public.regioes r WHERE r.id = igrejas.regiao_id
            )
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        -- Líderes de bloco podem inserir igrejas das regiões do seu bloco
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.regioes r ON r.id = igrejas.regiao_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = r.bloco_id
        )
        OR
        -- Líderes regionais podem inserir igrejas da sua região
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'lider_regional_iurd'
            AND u.regiao_id = igrejas.regiao_id
        )
    );

-- Policy para UPDATE (atualização)
CREATE POLICY "igrejas_update_admin" ON public.igrejas
    FOR UPDATE
    USING (
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
            JOIN public.blocos b ON b.id = (
                SELECT r.bloco_id FROM public.regioes r WHERE r.id = igrejas.regiao_id
            )
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.regioes r ON r.id = igrejas.regiao_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = r.bloco_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'lider_regional_iurd'
            AND u.regiao_id = igrejas.regiao_id
        )
    )
    WITH CHECK (
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
            JOIN public.blocos b ON b.id = (
                SELECT r.bloco_id FROM public.regioes r WHERE r.id = igrejas.regiao_id
            )
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju')
            AND u.estado_id = b.estado_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.regioes r ON r.id = igrejas.regiao_id
            WHERE u.id_auth = auth.uid() 
            AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju')
            AND u.bloco_id = r.bloco_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'lider_regional_iurd'
            AND u.regiao_id = igrejas.regiao_id
        )
    );

-- Policy para DELETE (exclusão) - apenas administradores
CREATE POLICY "igrejas_delete_admin" ON public.igrejas
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id_auth = auth.uid() 
            AND u.nivel = 'administrador'
        )
    );

-- =====================================================
-- VERIFICAR POLICIES CRIADAS
-- =====================================================

-- Verificar policies da tabela blocos
SELECT 'BLOCOS' as tabela, policyname, cmd, qual FROM pg_policies WHERE tablename = 'blocos' ORDER BY policyname;

-- Verificar policies da tabela regioes
SELECT 'REGIOES' as tabela, policyname, cmd, qual FROM pg_policies WHERE tablename = 'regioes' ORDER BY policyname;

-- Verificar policies da tabela igrejas
SELECT 'IGREJAS' as tabela, policyname, cmd, qual FROM pg_policies WHERE tablename = 'igrejas' ORDER BY policyname;

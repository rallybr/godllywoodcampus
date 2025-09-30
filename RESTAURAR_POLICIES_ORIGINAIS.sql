-- RESTAURAR POLICIES ORIGINAIS DO SISTEMA
-- Baseado no GUIA_ESTRUTURA_BANCO_DADOS_COMPLETO.md

-- ============================================
-- 1. REMOVER TODAS AS POLICIES ATUAIS
-- ============================================

-- Remover TODAS as policies existentes
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Remover policies da tabela usuarios
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'usuarios'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.usuarios', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela jovens
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'jovens'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.jovens', policy_record.policyname);
    END LOOP;
    
    -- Remover policies da tabela dados_viagem
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'dados_viagem'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.dados_viagem', policy_record.policyname);
    END LOOP;
END $$;

-- ============================================
-- 2. CRIAR POLICIES ORIGINAIS PARA USUARIOS
-- ============================================

-- USUARIOS - Políticas originais
CREATE POLICY "Allow all for admin" ON public.usuarios
FOR ALL TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

CREATE POLICY "Allow read for authenticated users" ON public.usuarios
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Allow update for own profile" ON public.usuarios
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.id = usuarios.id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.id = usuarios.id)
);

CREATE POLICY "allow_read_own_user_data" ON public.usuarios
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.id = usuarios.id)
);

CREATE POLICY "allow_update_own_user_data" ON public.usuarios
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.id = usuarios.id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.id = usuarios.id)
);

-- ============================================
-- 3. CRIAR POLICIES ORIGINAIS PARA JOVENS
-- ============================================

-- JOVENS - Políticas originais
CREATE POLICY "Allow all for admin" ON public.jovens
FOR ALL TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

CREATE POLICY "Allow insert for authenticated users" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow read based on hierarchy" ON public.jovens
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "Allow update based on hierarchy" ON public.jovens
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "allow_insert_jovens" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

CREATE POLICY "allow_read_jovens_by_hierarchy" ON public.jovens
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "allow_update_jovens_by_hierarchy" ON public.jovens
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "jovens_delete_admin" ON public.jovens
FOR DELETE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

CREATE POLICY "jovens_insert_self_or_admin" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "jovens_select_scoped" ON public.jovens
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

CREATE POLICY "jovens_update_scoped_roles" ON public.jovens
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

-- ============================================
-- 4. CRIAR POLICIES ORIGINAIS PARA DADOS_VIAGEM
-- ============================================

-- DADOS_VIAGEM - Políticas originais
CREATE POLICY "Allow all for admin" ON public.dados_viagem
FOR ALL TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
);

CREATE POLICY "Allow insert for authenticated users" ON public.dados_viagem
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow read based on hierarchy" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
);

CREATE POLICY "Allow update based on hierarchy" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
);

CREATE POLICY "allow_read_dados_viagem" ON public.dados_viagem
FOR SELECT TO authenticated
USING (true);

-- ============================================
-- 5. VERIFICAÇÃO
-- ============================================

SELECT 'Políticas originais restauradas com sucesso!' as status;

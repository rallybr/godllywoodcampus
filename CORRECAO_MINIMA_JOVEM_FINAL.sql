-- CORREÇÃO MÍNIMA APENAS PARA JOVEM
-- Apenas corrige o problema do usuario_id NULL para nível jovem

-- ============================================
-- 1. REMOVER APENAS AS POLICIES PROBLEMÁTICAS
-- ============================================

DROP POLICY IF EXISTS "jovens_select_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_by_hierarchy" ON public.jovens;

-- ============================================
-- 2. RECRIAR APENAS COM CORREÇÃO MÍNIMA
-- ============================================

-- SELECT - Apenas corrige a linha do jovem
CREATE POLICY "jovens_select_by_hierarchy" ON public.jovens
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
  -- CORREÇÃO: Jovem pode ver seus dados mesmo com usuario_id NULL
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- INSERT - Apenas corrige a linha do jovem
CREATE POLICY "jovens_insert_by_hierarchy" ON public.jovens
FOR INSERT TO authenticated
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
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- CORREÇÃO: Jovem pode inserir seus dados mesmo com usuario_id NULL
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- UPDATE - Apenas corrige a linha do jovem
CREATE POLICY "jovens_update_by_hierarchy" ON public.jovens
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
  -- CORREÇÃO: Jovem pode atualizar seus dados mesmo com usuario_id NULL
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
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
  -- CORREÇÃO: Jovem pode atualizar seus dados mesmo com usuario_id NULL
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- ============================================
-- 3. VERIFICAÇÃO
-- ============================================

SELECT 'Correção mínima aplicada!' as status;

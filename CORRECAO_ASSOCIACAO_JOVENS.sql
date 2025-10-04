-- =====================================================
-- CORREÇÃO: ASSOCIAÇÃO DE JOVENS PARA TODOS OS NÍVEIS
-- =====================================================
-- Permite que jovens associados apareçam para qualquer nível de usuário
-- independente da hierarquia geográfica

-- ============================================
-- 1. REMOVER POLICIES EXISTENTES
-- ============================================

DROP POLICY IF EXISTS "jovens_select_by_level" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_hierarquia" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;
DROP POLICY IF EXISTS "allow_read_jovens_by_hierarchy" ON public.jovens;

-- ============================================
-- 2. CRIAR NOVA POLICY CORRIGIDA
-- ============================================

-- Policy para SELECT - Inclui jovens associados para todos os níveis
CREATE POLICY "jovens_select_with_associations" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: acesso ao seu estado OU jovens associados a ele
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') 
    AND (u.estado_id = jovens.estado_id OR u.id = jovens.usuario_id)
  )
  OR
  -- Líderes de bloco: acesso ao seu bloco OU jovens associados a ele
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') 
    AND (u.bloco_id = jovens.bloco_id OR u.id = jovens.usuario_id)
  )
  OR
  -- Líder regional: acesso à sua região OU jovens associados a ele
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_regional_iurd' 
    AND (u.regiao_id = jovens.regiao_id OR u.id = jovens.usuario_id)
  )
  OR
  -- Líder de igreja: acesso à sua igreja OU jovens associados a ele
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_igreja_iurd' 
    AND (u.igreja_id = jovens.igreja_id OR u.id = jovens.usuario_id)
  )
  OR
  -- Colaborador: acesso aos jovens que cadastrou OU jovens associados a ele
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = jovens.usuario_id
  )
  OR
  -- Jovem: acesso apenas aos seus próprios dados
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

-- ============================================
-- 3. VERIFICAR SE RLS ESTÁ HABILITADO
-- ============================================

ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. VERIFICAR A CORREÇÃO
-- ============================================

-- Mostrar as policies ativas
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
WHERE tablename = 'jovens' 
ORDER BY policyname;

-- ============================================
-- 5. TESTE DA CORREÇÃO
-- ============================================

-- Verificar se a policy permite acesso a jovens associados
-- Este teste deve retornar jovens associados ao usuário logado
-- independente da hierarquia geográfica

SELECT 
  'TESTE: Jovens associados devem aparecer para todos os níveis' as status,
  COUNT(*) as total_jovens_associados
FROM public.jovens j
JOIN public.usuarios u ON u.id = j.usuario_id
WHERE u.id_auth = auth.uid();

-- Script para corrigir as políticas RLS da tabela dados_nucleo
-- Implementando controle de acesso hierárquico correto

-- 1. Remover todas as políticas existentes
DROP POLICY IF EXISTS "dados_nucleo_insert_working" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_select_working" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_working" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_delete_working" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_insert_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_select_hierarchical" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_delete_admin" ON public.dados_nucleo;

-- 2. Criar política de SELECT com controle hierárquico correto
CREATE POLICY "dados_nucleo_select_hierarchical" ON public.dados_nucleo
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
  OR
  -- Líder nacional: acesso total
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
  )
  OR
  -- Líder estadual: acesso apenas ao seu estado
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') 
    AND u.estado_id = (
      SELECT j.estado_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder de bloco: acesso apenas ao seu bloco
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') 
    AND u.bloco_id = (
      SELECT j.bloco_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder regional: acesso apenas à sua região
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_regional_iurd' 
    AND u.regiao_id = (
      SELECT j.regiao_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder de igreja: acesso apenas à sua igreja
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_igreja_iurd' 
    AND u.igreja_id = (
      SELECT j.igreja_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Colaborador: acesso apenas aos jovens que cadastrou
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = (
      SELECT j.usuario_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Jovem: acesso apenas aos seus próprios dados
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND u.id = (
      SELECT j.usuario_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
);

-- 3. Criar política de INSERT com controle hierárquico
CREATE POLICY "dados_nucleo_insert_hierarchical" ON public.dados_nucleo
FOR INSERT TO authenticated
WITH CHECK (
  -- Jovem: pode inserir apenas seus próprios dados
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND u.id = dados_nucleo.jovem_id
  )
  OR
  -- Administrador: pode inserir dados de qualquer jovem
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
  OR
  -- Colaborador: pode inserir dados dos jovens que cadastrou
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = dados_nucleo.jovem_id
  )
);

-- 4. Criar política de UPDATE com controle hierárquico
CREATE POLICY "dados_nucleo_update_hierarchical" ON public.dados_nucleo
FOR UPDATE TO authenticated
USING (
  -- Jovem: pode atualizar apenas seus próprios dados
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND u.id = dados_nucleo.jovem_id
  )
  OR
  -- Administrador: pode atualizar dados de qualquer jovem
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
  OR
  -- Colaborador: pode atualizar dados dos jovens que cadastrou
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = dados_nucleo.jovem_id
  )
);

-- 5. Criar política de DELETE (apenas administrador)
CREATE POLICY "dados_nucleo_delete_admin" ON public.dados_nucleo
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
);

-- 6. Verificar as políticas criadas
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
WHERE tablename = 'dados_nucleo'
ORDER BY policyname;

-- Ajuste de RLS: permitir que o próprio jovem acesse seu cadastro
-- quando o vínculo é feito via jovens.id_usuario_jovem

-- 1) Remover a policy atual de SELECT (se existir)
DROP POLICY IF EXISTS "jovens_select_with_associations" ON public.jovens;

-- 2) Recriar a policy incluindo a verificação por id_usuario_jovem
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
  -- Jovem: acesso aos próprios dados (usuario_id OU id_usuario_jovem)
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND (u.id = jovens.usuario_id OR u.id = jovens.id_usuario_jovem)
  )
);

-- 3) Garantir que a RLS está habilitada
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- 4) Verificação rápida
-- SELECT policyname, qual FROM pg_policies WHERE tablename = 'jovens';



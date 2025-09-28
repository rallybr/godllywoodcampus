-- Verificar se há políticas existentes na tabela dados_viagem
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

-- Habilitar RLS na tabela dados_viagem (se não estiver habilitado)
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;

-- Criar política para permitir que jovens vejam seus próprios dados de viagem
CREATE POLICY "jovem pode ver seus dados de viagem" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  jovem_id IN (
    SELECT j.id 
    FROM public.jovens j 
    JOIN public.usuarios u ON u.id = j.usuario_id 
    WHERE u.id_auth = auth.uid()
  )
);

-- Criar política para permitir que jovens atualizem seus próprios dados de viagem
CREATE POLICY "jovem pode atualizar seus dados de viagem" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  jovem_id IN (
    SELECT j.id 
    FROM public.jovens j 
    JOIN public.usuarios u ON u.id = j.usuario_id 
    WHERE u.id_auth = auth.uid()
  )
)
WITH CHECK (
  jovem_id IN (
    SELECT j.id 
    FROM public.jovens j 
    JOIN public.usuarios u ON u.id = j.usuario_id 
    WHERE u.id_auth = auth.uid()
  )
);

-- Criar política para permitir que líderes vejam dados de viagem (usando can_access_jovem)
CREATE POLICY "lideres podem ver dados de viagem" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);

-- Criar política para permitir que líderes atualizem dados de viagem
CREATE POLICY "lideres podem atualizar dados de viagem" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);

-- Verificar se as políticas foram criadas
SELECT 
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'dados_viagem'
ORDER BY policyname;

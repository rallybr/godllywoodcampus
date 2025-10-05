-- RLS Policies para a tabela dados_nucleo
-- Seguindo a mesma hierarquia de acesso da tabela jovens

-- Habilitar RLS na tabela
ALTER TABLE public.dados_nucleo ENABLE ROW LEVEL SECURITY;

-- Policy para SELECT - Acesso baseado na hierarquia
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
  -- Líder estadual: acesso ao seu estado
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') 
    AND u.estado_id = (
      SELECT j.estado_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder de bloco: acesso ao seu bloco
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') 
    AND u.bloco_id = (
      SELECT j.bloco_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder regional: acesso à sua região
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_regional_iurd' 
    AND u.regiao_id = (
      SELECT j.regiao_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Líder de igreja: acesso à sua igreja
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'lider_igreja_iurd' 
    AND u.igreja_id = (
      SELECT j.igreja_id FROM public.jovens j WHERE j.id = dados_nucleo.jovem_id
    )
  )
  OR
  -- Colaborador: acesso aos jovens que cadastrou
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

-- Policy para INSERT - Apenas o próprio jovem pode inserir seus dados
CREATE POLICY "dados_nucleo_insert_own" ON public.dados_nucleo
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

-- Policy para UPDATE - Apenas o próprio jovem pode atualizar seus dados
CREATE POLICY "dados_nucleo_update_own" ON public.dados_nucleo
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

-- Policy para DELETE - Apenas administrador pode deletar
CREATE POLICY "dados_nucleo_delete_admin" ON public.dados_nucleo
FOR DELETE TO authenticated
USING (
  -- Apenas administrador pode deletar
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
);

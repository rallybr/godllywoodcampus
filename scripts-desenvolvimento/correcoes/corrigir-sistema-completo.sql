-- CORREÇÃO COMPLETA DO SISTEMA
-- Baseado na análise da estrutura atual do banco

-- 1. CORRIGIR CONSTRAINT DA TABELA aprovacoes_jovens
ALTER TABLE public.aprovacoes_jovens 
ADD CONSTRAINT unique_aprovacao_por_usuario_jovem_tipo 
UNIQUE (jovem_id, usuario_id, tipo_aprovacao);

-- 2. CORRIGIR FUNÇÃO can_access_jovem
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_roles_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  INTO user_roles_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;

  IF user_roles_info IS NULL THEN RETURN false; END IF;

  -- 1 e 2: admin e líderes nacionais → acesso total
  IF user_roles_info.nivel_hierarquico IN (1, 2) THEN RETURN true; END IF;

  -- 3: estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    RETURN user_roles_info.estado_id = jovem_estado_id;
  END IF;

  -- 4: bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    RETURN user_roles_info.bloco_id = jovem_bloco_id;
  END IF;

  -- 5: regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    RETURN user_roles_info.regiao_id = jovem_regiao_id;
  END IF;

  -- 6: igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    RETURN user_roles_info.igreja_id = jovem_igreja_id;
  END IF;

  -- 7: colaborador → acesso aos jovens que cadastrou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;

  -- 8: jovem → acesso controlado por outras policies
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN false;
  END IF;

  RETURN false;
END;
$$;

-- 3. CORRIGIR FUNÇÃO can_access_viagem_by_level
CREATE OR REPLACE FUNCTION public.can_access_viagem_by_level(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_roles_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;
  
  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  INTO user_roles_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;
  
  IF user_roles_info IS NULL THEN RETURN false; END IF;
  
  -- 1. ADMINISTRADOR (nível 1) - Acesso total
  IF user_roles_info.nivel_hierarquico = 1 THEN RETURN true; END IF;
  
  -- 2. LÍDERES NACIONAIS (nível 2) - Acesso total
  IF user_roles_info.nivel_hierarquico = 2 THEN RETURN true; END IF;
  
  -- 3. LÍDERES ESTADUAIS (nível 3) - Visão estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    RETURN user_roles_info.estado_id = jovem_estado_id;
  END IF;
  
  -- 4. LÍDERES DE BLOCO (nível 4) - Visão de bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    RETURN user_roles_info.bloco_id = jovem_bloco_id;
  END IF;
  
  -- 5. LÍDER REGIONAL (nível 5) - Visão regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    RETURN user_roles_info.regiao_id = jovem_regiao_id;
  END IF;
  
  -- 6. LÍDER DE IGREJA (nível 6) - Visão de igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    RETURN user_roles_info.igreja_id = jovem_igreja_id;
  END IF;
  
  -- 7. COLABORADOR (nível 7) - Acesso aos jovens que cadastrou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  -- 8. JOVEM (nível 8) - Vê apenas seus próprios dados
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  RETURN false;
END;
$$;

-- 4. CRIAR POLICIES CORRETAS PARA JOVENS
DROP POLICY IF EXISTS "Allow all for admin" ON public.jovens;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.jovens;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.jovens;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.jovens;

CREATE POLICY "Allow all for admin" ON public.jovens FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read based on hierarchy" ON public.jovens FOR SELECT USING (
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);
CREATE POLICY "Allow insert for authenticated users" ON public.jovens FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update based on hierarchy" ON public.jovens FOR UPDATE USING (
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- 5. CRIAR POLICIES CORRETAS PARA DADOS_VIAGEM
DROP POLICY IF EXISTS "Allow all for admin" ON public.dados_viagem;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.dados_viagem;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.dados_viagem;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.dados_viagem;

CREATE POLICY "Allow all for admin" ON public.dados_viagem FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read based on hierarchy" ON public.dados_viagem FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_viagem_by_level(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);
CREATE POLICY "Allow insert for authenticated users" ON public.dados_viagem FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update based on hierarchy" ON public.dados_viagem FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_viagem_by_level(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);

-- 6. CRIAR POLICIES CORRETAS PARA AVALIACOES
DROP POLICY IF EXISTS "Allow all for admin" ON public.avaliacoes;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.avaliacoes;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.avaliacoes;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.avaliacoes;

CREATE POLICY "Allow all for admin" ON public.avaliacoes FOR ALL USING (has_role('administrador'));
CREATE POLICY "Allow read based on hierarchy" ON public.avaliacoes FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = avaliacoes.jovem_id 
    AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);
CREATE POLICY "Allow insert for authenticated users" ON public.avaliacoes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update based on hierarchy" ON public.avaliacoes FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = avaliacoes.jovem_id 
    AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);

-- 7. VERIFICAR SE AS CORREÇÕES FORAM APLICADAS
SELECT 
  'Constraint aprovacoes_jovens' as item,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'unique_aprovacao_por_usuario_jovem_tipo'
  ) THEN 'OK' ELSE 'ERRO' END as status;

SELECT 
  'Função can_access_jovem' as item,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'can_access_jovem'
  ) THEN 'OK' ELSE 'ERRO' END as status;

SELECT 
  'Função can_access_viagem_by_level' as item,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'can_access_viagem_by_level'
  ) THEN 'OK' ELSE 'ERRO' END as status;

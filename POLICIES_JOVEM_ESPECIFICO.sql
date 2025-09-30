-- POLICIES ESPECÍFICAS PARA NÍVEL JOVEM
-- Permite que jovem veja apenas seus próprios dados

-- ============================================
-- 1. REMOVER POLICIES EXISTENTES
-- ============================================

-- Remover policies da tabela usuarios
DROP POLICY IF EXISTS "usuarios_select_by_hierarchy" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update_by_hierarchy" ON public.usuarios;

-- Remover policies da tabela jovens
DROP POLICY IF EXISTS "jovens_select_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_by_hierarchy" ON public.jovens;

-- Remover policies da tabela dados_viagem
DROP POLICY IF EXISTS "dados_viagem_select_by_hierarchy" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_insert_by_hierarchy" ON public.dados_viagem;
DROP POLICY IF EXISTS "dados_viagem_update_by_hierarchy" ON public.dados_viagem;

-- ============================================
-- 2. CRIAR POLICIES ESPECÍFICAS PARA JOVEM
-- ============================================

-- USUARIOS - Jovem vê apenas seu próprio perfil
CREATE POLICY "usuarios_select_by_hierarchy" ON public.usuarios
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: acesso por estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = usuarios.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = usuarios.estado_id)
  OR
  -- Líderes de bloco: acesso por bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = usuarios.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = usuarios.bloco_id)
  OR
  -- Líder regional: acesso por região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = usuarios.regiao_id)
  OR
  -- Líder de igreja: acesso por igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = usuarios.igreja_id)
  OR
  -- Colaborador: acesso aos usuários que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = usuarios.id)
  OR
  -- JOVEM: Apenas seu próprio perfil
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = usuarios.id)
);

-- USUARIOS - Jovem pode atualizar apenas seu próprio perfil
CREATE POLICY "usuarios_update_by_hierarchy" ON public.usuarios
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer usuário
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer usuário
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: podem atualizar usuários do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = usuarios.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = usuarios.estado_id)
  OR
  -- Líderes de bloco: podem atualizar usuários do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = usuarios.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = usuarios.bloco_id)
  OR
  -- Líder regional: pode atualizar usuários da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = usuarios.regiao_id)
  OR
  -- Líder de igreja: pode atualizar usuários da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = usuarios.igreja_id)
  OR
  -- Colaborador: pode atualizar usuários que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = usuarios.id)
  OR
  -- JOVEM: Apenas seu próprio perfil
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = usuarios.id)
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = usuarios.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = usuarios.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = usuarios.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = usuarios.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = usuarios.regiao_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = usuarios.igreja_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = usuarios.id)
  OR
  -- JOVEM: Apenas seu próprio perfil
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = usuarios.id)
);

-- JOVENS - Jovem vê apenas seu próprio cadastro
CREATE POLICY "jovens_select_by_hierarchy" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: acesso por estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: acesso por bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: acesso por região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: acesso por igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: acesso aos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  -- JOVEM: Apenas seu próprio cadastro (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- JOVENS - Jovem pode inserir apenas seu próprio cadastro
CREATE POLICY "jovens_insert_by_hierarchy" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: podem inserir jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem inserir jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: pode inserir jovens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: pode inserir jovens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: pode inserir jovens (será associado ao colaborador)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- JOVEM: Apenas seu próprio cadastro (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- JOVENS - Jovem pode atualizar apenas seu próprio cadastro
CREATE POLICY "jovens_update_by_hierarchy" ON public.jovens
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: podem atualizar jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem atualizar jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = jovens.bloco_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: pode atualizar jovens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: pode atualizar jovens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: pode atualizar jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  -- JOVEM: Apenas seu próprio cadastro (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
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
  -- JOVEM: Apenas seu próprio cadastro (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = jovens.usuario_id OR jovens.usuario_id IS NULL))
);

-- DADOS_VIAGEM - Jovem vê apenas sua própria viagem
CREATE POLICY "dados_viagem_select_by_hierarchy" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: acesso por estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: acesso por bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: acesso por região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: acesso por igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: acesso às viagens dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  -- JOVEM: Apenas sua própria viagem (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = dados_viagem.usuario_id OR dados_viagem.usuario_id IS NULL))
);

-- DADOS_VIAGEM - Jovem pode inserir apenas sua própria viagem
CREATE POLICY "dados_viagem_insert_by_hierarchy" ON public.dados_viagem
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: podem inserir viagens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: podem inserir viagens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: pode inserir viagens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: pode inserir viagens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: pode inserir viagens (será associado ao colaborador)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- JOVEM: Apenas sua própria viagem (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = dados_viagem.usuario_id OR dados_viagem.usuario_id IS NULL))
);

-- DADOS_VIAGEM - Jovem pode atualizar apenas sua própria viagem
CREATE POLICY "dados_viagem_update_by_hierarchy" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_iurd')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_nacional_fju')
  OR
  -- Líderes estaduais: podem atualizar viagens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_iurd' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_estadual_fju' AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: podem atualizar viagens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_iurd' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_bloco_fju' AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: pode atualizar viagens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: pode atualizar viagens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: pode atualizar viagens dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  -- JOVEM: Apenas sua própria viagem (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = dados_viagem.usuario_id OR dados_viagem.usuario_id IS NULL))
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
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
  -- JOVEM: Apenas sua própria viagem (incluindo quando usuario_id é null)
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND (u.id = dados_viagem.usuario_id OR dados_viagem.usuario_id IS NULL))
);

-- ============================================
-- 3. VERIFICAÇÃO
-- ============================================

SELECT 'Políticas específicas para jovem criadas com sucesso!' as status;

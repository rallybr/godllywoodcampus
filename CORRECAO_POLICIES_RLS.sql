-- =====================================================
-- CORREÇÃO DAS POLICIES RLS
-- =====================================================
-- Problema: As policies estão permitindo acesso total para usuários autenticados
-- Solução: Implementar policies baseadas no campo nivel da tabela usuarios

-- ============================================
-- 1. REMOVER POLICIES PROBLEMÁTICAS
-- ============================================

-- Remover policies que permitem acesso total para usuários autenticados
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.jovens;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.jovens;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.jovens;

DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.dados_viagem;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.dados_viagem;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.dados_viagem;

DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.avaliacoes;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.avaliacoes;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.avaliacoes;

-- ============================================
-- 2. CRIAR POLICIES CORRETAS PARA JOVENS
-- ============================================

-- Policy para SELECT (leitura) - baseada em níveis hierárquicos
CREATE POLICY "jovens_select_by_level" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: acesso ao seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: acesso ao seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: acesso à sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: acesso à sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: acesso aos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
  OR
  -- Jovem: acesso apenas aos seus próprios dados
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

-- Policy para INSERT (inserção)
CREATE POLICY "jovens_insert_by_level" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem inserir jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem inserir jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
  OR
  -- Líder regional: pode inserir jovens da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
  OR
  -- Líder de igreja: pode inserir jovens da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
  OR
  -- Colaborador: pode inserir jovens
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- Jovem: pode inserir apenas seu próprio cadastro
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
);

-- Policy para UPDATE (atualização)
CREATE POLICY "jovens_update_by_level" ON public.jovens
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer jovem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem atualizar jovens do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  -- Líderes de bloco: podem atualizar jovens do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
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
  -- Jovem: pode atualizar apenas seus próprios dados
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
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
-- 3. CRIAR POLICIES CORRETAS PARA DADOS_VIAGEM
-- ============================================

-- Policy para SELECT (leitura) - baseada em níveis hierárquicos
CREATE POLICY "dados_viagem_select_by_level" ON public.dados_viagem
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: acesso ao seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: acesso ao seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: acesso à sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: acesso à sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: acesso aos dados de viagem dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  -- Jovem: acesso apenas aos seus próprios dados de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
);

-- Policy para INSERT (inserção)
CREATE POLICY "dados_viagem_insert_by_level" ON public.dados_viagem
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer dado de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer dado de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem inserir dados de viagem do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: podem inserir dados de viagem do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: pode inserir dados de viagem da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: pode inserir dados de viagem da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: pode inserir dados de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- Jovem: pode inserir apenas seus próprios dados de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
);

-- Policy para UPDATE (atualização)
CREATE POLICY "dados_viagem_update_by_level" ON public.dados_viagem
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer dado de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer dado de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem atualizar dados de viagem do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líderes de bloco: podem atualizar dados de viagem do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder regional: pode atualizar dados de viagem da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Líder de igreja: pode atualizar dados de viagem da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  -- Colaborador: pode atualizar dados de viagem dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  -- Jovem: pode atualizar apenas seus próprios dados de viagem
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = dados_viagem.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = dados_viagem.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = dados_viagem.usuario_id)
);

-- ============================================
-- 4. CRIAR POLICIES CORRETAS PARA AVALIACOES
-- ============================================

-- Policy para SELECT (leitura) - baseada em níveis hierárquicos
CREATE POLICY "avaliacoes_select_by_level" ON public.avaliacoes
FOR SELECT TO authenticated
USING (
  -- Administrador: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: acesso total
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: acesso ao seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líderes de bloco: acesso ao seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder regional: acesso à sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder de igreja: acesso à sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Colaborador: acesso às avaliações dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = avaliacoes.usuario_id)
  OR
  -- Jovem: acesso apenas às suas próprias avaliações
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = avaliacoes.usuario_id)
);

-- Policy para INSERT (inserção)
CREATE POLICY "avaliacoes_insert_by_level" ON public.avaliacoes
FOR INSERT TO authenticated
WITH CHECK (
  -- Administrador: pode inserir qualquer avaliação
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem inserir qualquer avaliação
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem inserir avaliações do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líderes de bloco: podem inserir avaliações do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder regional: pode inserir avaliações da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder de igreja: pode inserir avaliações da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Colaborador: pode inserir avaliações
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
  OR
  -- Jovem: pode inserir apenas suas próprias avaliações
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = avaliacoes.usuario_id)
);

-- Policy para UPDATE (atualização)
CREATE POLICY "avaliacoes_update_by_level" ON public.avaliacoes
FOR UPDATE TO authenticated
USING (
  -- Administrador: pode atualizar qualquer avaliação
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  -- Líderes nacionais: podem atualizar qualquer avaliação
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  -- Líderes estaduais: podem atualizar avaliações do seu estado
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líderes de bloco: podem atualizar avaliações do seu bloco
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder regional: pode atualizar avaliações da sua região
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Líder de igreja: pode atualizar avaliações da sua igreja
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  -- Colaborador: pode atualizar avaliações dos jovens que cadastrou
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = avaliacoes.usuario_id)
  OR
  -- Jovem: pode atualizar apenas suas próprias avaliações
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = avaliacoes.usuario_id)
)
WITH CHECK (
  -- Mesmas condições para WITH CHECK
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = (SELECT estado_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = (SELECT bloco_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = (SELECT regiao_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = (SELECT igreja_id FROM public.jovens WHERE id = avaliacoes.jovem_id))
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = avaliacoes.usuario_id)
  OR
  EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = avaliacoes.usuario_id)
);

-- ============================================
-- 5. VERIFICAÇÃO FINAL
-- ============================================

SELECT 'Policies RLS corrigidas com sucesso!' as status;

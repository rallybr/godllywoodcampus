-- =====================================================
-- Script SIMPLES para reabilitar RLS policies
-- =====================================================

-- 1. Reabilitar RLS nas tabelas principais
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aprovacoes_jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes_sistema ENABLE ROW LEVEL SECURITY;

-- 2. Remover todas as policies existentes
DROP POLICY IF EXISTS "allow_read_all_roles" ON public.roles;
DROP POLICY IF EXISTS "allow_read_own_user_data" ON public.usuarios;
DROP POLICY IF EXISTS "allow_update_own_user_data" ON public.usuarios;
DROP POLICY IF EXISTS "allow_read_own_user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "allow_read_all_estados" ON public.estados;
DROP POLICY IF EXISTS "allow_read_all_blocos" ON public.blocos;
DROP POLICY IF EXISTS "allow_read_all_regioes" ON public.regioes;
DROP POLICY IF EXISTS "allow_read_all_igrejas" ON public.igrejas;
DROP POLICY IF EXISTS "allow_read_all_edicoes" ON public.edicoes;
DROP POLICY IF EXISTS "allow_read_jovens_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "allow_insert_jovens" ON public.jovens;
DROP POLICY IF EXISTS "allow_update_jovens_by_hierarchy" ON public.jovens;
DROP POLICY IF EXISTS "allow_read_avaliacoes_by_hierarchy" ON public.avaliacoes;
DROP POLICY IF EXISTS "allow_insert_avaliacoes" ON public.avaliacoes;
DROP POLICY IF EXISTS "allow_read_aprovacoes_jovens" ON public.aprovacoes_jovens;
DROP POLICY IF EXISTS "allow_read_dados_viagem" ON public.dados_viagem;
DROP POLICY IF EXISTS "allow_read_logs_auditoria" ON public.logs_auditoria;
DROP POLICY IF EXISTS "allow_read_notificacoes" ON public.notificacoes;
DROP POLICY IF EXISTS "allow_read_sessoes_usuario" ON public.sessoes_usuario;
DROP POLICY IF EXISTS "allow_read_configuracoes_sistema" ON public.configuracoes_sistema;

-- 3. Criar policies básicas e seguras

-- Roles: todos podem ler
CREATE POLICY "allow_read_all_roles" ON public.roles
  FOR SELECT USING (true);

-- Usuários: podem ler e atualizar seus próprios dados
CREATE POLICY "allow_read_own_user_data" ON public.usuarios
  FOR SELECT USING (auth.uid() = id_auth);

CREATE POLICY "allow_update_own_user_data" ON public.usuarios
  FOR UPDATE USING (auth.uid() = id_auth);

-- User roles: podem ler seus próprios roles
CREATE POLICY "allow_read_own_user_roles" ON public.user_roles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u 
      WHERE u.id_auth = auth.uid() 
      AND u.id = user_roles.user_id
    )
  );

-- Dados geográficos: todos podem ler
CREATE POLICY "allow_read_all_estados" ON public.estados
  FOR SELECT USING (true);

CREATE POLICY "allow_read_all_blocos" ON public.blocos
  FOR SELECT USING (true);

CREATE POLICY "allow_read_all_regioes" ON public.regioes
  FOR SELECT USING (true);

CREATE POLICY "allow_read_all_igrejas" ON public.igrejas
  FOR SELECT USING (true);

CREATE POLICY "allow_read_all_edicoes" ON public.edicoes
  FOR SELECT USING (true);

-- Jovens: política baseada na hierarquia
CREATE POLICY "allow_read_jovens_by_hierarchy" ON public.jovens
  FOR SELECT USING (
    -- Administrador: acesso total
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
    OR
    -- Líderes nacionais: acesso nacional
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
    OR
    -- Líderes estaduais: acesso ao estado
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = jovens.estado_id)
    OR
    -- Líderes de bloco: acesso ao bloco
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = jovens.bloco_id)
    OR
    -- Líder regional: acesso à região
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND u.regiao_id = jovens.regiao_id)
    OR
    -- Líder de igreja: acesso à igreja
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND u.igreja_id = jovens.igreja_id)
    OR
    -- Colaborador: acesso aos jovens que cadastrou
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND u.id = jovens.usuario_id)
    OR
    -- Jovem: acesso apenas aos seus próprios dados
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND u.id = jovens.usuario_id)
  );

-- Jovens: inserir (colaboradores e administradores)
CREATE POLICY "allow_insert_jovens" ON public.jovens
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador')
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
  );

-- Jovens: atualizar (baseado na hierarquia)
CREATE POLICY "allow_update_jovens_by_hierarchy" ON public.jovens
  FOR UPDATE USING (
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
  );

-- Avaliações: ler (baseado na hierarquia)
CREATE POLICY "allow_read_avaliacoes_by_hierarchy" ON public.avaliacoes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'administrador')
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju'))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.estado_id = u.estado_id))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.bloco_id = u.bloco_id))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_regional_iurd' AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.regiao_id = u.regiao_id))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'lider_igreja_iurd' AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.igreja_id = u.igreja_id))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'colaborador' AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.usuario_id = u.id))
    OR
    EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id_auth = auth.uid() AND u.nivel = 'jovem' AND EXISTS (SELECT 1 FROM public.jovens j WHERE j.id = avaliacoes.jovem_id AND j.usuario_id = u.id))
  );

-- Avaliações: inserir (usuários autenticados)
CREATE POLICY "allow_insert_avaliacoes" ON public.avaliacoes
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Outras tabelas: todos podem ler
CREATE POLICY "allow_read_aprovacoes_jovens" ON public.aprovacoes_jovens
  FOR SELECT USING (true);

CREATE POLICY "allow_read_dados_viagem" ON public.dados_viagem
  FOR SELECT USING (true);

CREATE POLICY "allow_read_logs_auditoria" ON public.logs_auditoria
  FOR SELECT USING (true);

CREATE POLICY "allow_read_notificacoes" ON public.notificacoes
  FOR SELECT USING (true);

CREATE POLICY "allow_read_sessoes_usuario" ON public.sessoes_usuario
  FOR SELECT USING (true);

CREATE POLICY "allow_read_configuracoes_sistema" ON public.configuracoes_sistema
  FOR SELECT USING (true);

-- 4. Verificar se tudo funcionou
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  hasrls as has_rls_policies
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'usuarios', 'roles', 'user_roles', 'estados', 'blocos', 'regioes', 'igrejas', 
    'edicoes', 'jovens', 'avaliacoes', 'aprovacoes_jovens', 'dados_viagem', 
    'logs_auditoria', 'notificacoes', 'sessoes_usuario', 'configuracoes_sistema'
  )
ORDER BY tablename;

-- 5. Verificar policies criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

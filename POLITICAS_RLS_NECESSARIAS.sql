-- =====================================================
-- POLÍTICAS RLS NECESSÁRIAS PARA O PROJETO
-- =====================================================
-- Data: 2024-12-19
-- Baseado na análise do código do projeto
-- Objetivo: Implementar políticas RLS corretas e funcionais

-- =====================================================
-- 1. HABILITAR RLS EM TODAS AS TABELAS
-- =====================================================

-- Habilitar RLS em todas as tabelas principais
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessoes_usuario ENABLE ROW LEVEL SECURITY;

-- Tabelas geográficas (apenas leitura para todos)
ALTER TABLE estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE igrejas ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. FUNÇÃO AUXILIAR PARA VERIFICAR ADMIN
-- =====================================================

-- Função para verificar se o usuário atual é administrador
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND r.slug = 'administrador'
    AND ur.ativo = true
  );
$$;

-- Função para verificar se o usuário tem papel específico
CREATE OR REPLACE FUNCTION has_role(role_slug text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND r.slug = role_slug
    AND ur.ativo = true
  );
$$;

-- Função para verificar se o usuário pode acessar jovem por localização
CREATE OR REPLACE FUNCTION can_access_jovem(jovem_estado_id uuid, jovem_bloco_id uuid, jovem_regiao_id uuid, jovem_igreja_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND ur.ativo = true
    AND (
      r.slug IN ('administrador', 'colaborador') OR
      (r.slug LIKE 'lider_estadual_%' AND ur.estado_id = jovem_estado_id) OR
      (r.slug LIKE 'lider_bloco_%' AND ur.bloco_id = jovem_bloco_id) OR
      (r.slug = 'lider_regional_iurd' AND ur.regiao_id = jovem_regiao_id) OR
      (r.slug = 'lider_igreja_iurd' AND ur.igreja_id = jovem_igreja_id)
    )
  );
$$;

-- =====================================================
-- 3. POLÍTICAS PARA TABELA USUARIOS
-- =====================================================

-- Administradores têm acesso total
CREATE POLICY "usuarios_admin_full" ON usuarios
  FOR ALL
  USING (is_admin_user());

-- Usuários podem ver seus próprios dados
CREATE POLICY "usuarios_self_select" ON usuarios
  FOR SELECT
  USING (id_auth = auth.uid());

-- Usuários podem atualizar seus próprios dados
CREATE POLICY "usuarios_self_update" ON usuarios
  FOR UPDATE
  USING (id_auth = auth.uid());

-- Colaboradores podem ver todos os usuários
CREATE POLICY "usuarios_colaborador_select" ON usuarios
  FOR SELECT
  USING (has_role('colaborador'));

-- =====================================================
-- 4. POLÍTICAS PARA TABELA JOVENS
-- =====================================================

-- Administradores e colaboradores têm acesso total
CREATE POLICY "jovens_admin_colab" ON jovens
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));

-- Líderes estaduais podem acessar jovens do seu estado
CREATE POLICY "jovens_lider_estadual" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug LIKE 'lider_estadual_%'
      AND ur.estado_id = jovens.estado_id
      AND ur.ativo = true
    )
  );

-- Líderes de bloco podem acessar jovens do seu bloco
CREATE POLICY "jovens_lider_bloco" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug LIKE 'lider_bloco_%'
      AND ur.bloco_id = jovens.bloco_id
      AND ur.ativo = true
    )
  );

-- Líderes regionais podem acessar jovens da sua região
CREATE POLICY "jovens_lider_regional" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'lider_regional_iurd'
      AND ur.regiao_id = jovens.regiao_id
      AND ur.ativo = true
    )
  );

-- Líderes de igreja podem acessar jovens da sua igreja
CREATE POLICY "jovens_lider_igreja" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'lider_igreja_iurd'
      AND ur.igreja_id = jovens.igreja_id
      AND ur.ativo = true
    )
  );

-- =====================================================
-- 5. POLÍTICAS PARA TABELA AVALIACOES
-- =====================================================

-- Administradores e colaboradores têm acesso total
CREATE POLICY "avaliacoes_admin_colab" ON avaliacoes
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));

-- Usuários podem ver avaliações dos jovens que podem acessar
CREATE POLICY "avaliacoes_by_jovem_access" ON avaliacoes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = avaliacoes.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );

-- Usuários podem criar avaliações para jovens que podem acessar
CREATE POLICY "avaliacoes_insert_by_jovem_access" ON avaliacoes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = avaliacoes.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );

-- Usuários podem editar apenas suas próprias avaliações
CREATE POLICY "avaliacoes_self_update" ON avaliacoes
  FOR UPDATE
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));

-- Usuários podem deletar apenas suas próprias avaliações
CREATE POLICY "avaliacoes_self_delete" ON avaliacoes
  FOR DELETE
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));

-- =====================================================
-- 6. POLÍTICAS PARA TABELA EDICOES
-- =====================================================

-- Todos podem ver edições
CREATE POLICY "edicoes_select_all" ON edicoes
  FOR SELECT
  USING (true);

-- Apenas administradores podem modificar edições
CREATE POLICY "edicoes_admin_modify" ON edicoes
  FOR ALL
  USING (is_admin_user());

-- =====================================================
-- 7. POLÍTICAS PARA TABELA ROLES
-- =====================================================

-- Todos podem ver roles
CREATE POLICY "roles_select_all" ON roles
  FOR SELECT
  USING (true);

-- Apenas administradores podem modificar roles
CREATE POLICY "roles_admin_modify" ON roles
  FOR ALL
  USING (is_admin_user());

-- =====================================================
-- 8. POLÍTICAS PARA TABELA USER_ROLES
-- =====================================================

-- Administradores e colaboradores podem gerenciar todos os user_roles
CREATE POLICY "user_roles_admin_colab" ON user_roles
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));

-- Usuários podem ver seus próprios roles
CREATE POLICY "user_roles_self_select" ON user_roles
  FOR SELECT
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));

-- =====================================================
-- 9. POLÍTICAS PARA TABELA LOGS_HISTORICO
-- =====================================================

-- Administradores e colaboradores têm acesso total
CREATE POLICY "logs_historico_admin_colab" ON logs_historico
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));

-- Líderes podem ver logs dos jovens que podem acessar
CREATE POLICY "logs_historico_by_jovem_access" ON logs_historico
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = logs_historico.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );

-- Sistema pode inserir logs (para função criar_log_auditoria)
CREATE POLICY "logs_historico_system_insert" ON logs_historico
  FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 10. POLÍTICAS PARA TABELA NOTIFICACOES
-- =====================================================

-- Usuários podem ver suas próprias notificações
CREATE POLICY "notificacoes_self" ON notificacoes
  FOR ALL
  USING (destinatario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));

-- Sistema pode criar notificações
CREATE POLICY "notificacoes_system_insert" ON notificacoes
  FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 11. POLÍTICAS PARA TABELA LOGS_AUDITORIA
-- =====================================================

-- Apenas administradores podem ver logs de auditoria
CREATE POLICY "logs_auditoria_admin" ON logs_auditoria
  FOR SELECT
  USING (is_admin_user());

-- Sistema pode inserir logs de auditoria
CREATE POLICY "logs_auditoria_system_insert" ON logs_auditoria
  FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 12. POLÍTICAS PARA TABELA CONFIGURACOES_SISTEMA
-- =====================================================

-- Todos podem ver configurações
CREATE POLICY "configuracoes_select_all" ON configuracoes_sistema
  FOR SELECT
  USING (true);

-- Apenas administradores podem modificar configurações
CREATE POLICY "configuracoes_admin_modify" ON configuracoes_sistema
  FOR ALL
  USING (is_admin_user());

-- =====================================================
-- 13. POLÍTICAS PARA TABELA SESSOES_USUARIO
-- =====================================================

-- Usuários podem gerenciar suas próprias sessões
CREATE POLICY "sessoes_self" ON sessoes_usuario
  FOR ALL
  USING (usuario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));

-- Sistema pode criar sessões
CREATE POLICY "sessoes_system_insert" ON sessoes_usuario
  FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 14. POLÍTICAS PARA TABELAS GEOGRÁFICAS
-- =====================================================

-- Todos podem ver dados geográficos
CREATE POLICY "estados_select_all" ON estados
  FOR SELECT
  USING (true);

CREATE POLICY "blocos_select_all" ON blocos
  FOR SELECT
  USING (true);

CREATE POLICY "regioes_select_all" ON regioes
  FOR SELECT
  USING (true);

CREATE POLICY "igrejas_select_all" ON igrejas
  FOR SELECT
  USING (true);

-- Apenas administradores podem modificar dados geográficos
CREATE POLICY "estados_admin_modify" ON estados
  FOR ALL
  USING (is_admin_user());

CREATE POLICY "blocos_admin_modify" ON blocos
  FOR ALL
  USING (is_admin_user());

CREATE POLICY "regioes_admin_modify" ON regioes
  FOR ALL
  USING (is_admin_user());

CREATE POLICY "igrejas_admin_modify" ON igrejas
  FOR ALL
  USING (is_admin_user());

-- =====================================================
-- 15. POLÍTICAS PARA STORAGE BUCKETS
-- =====================================================

-- Política para fotos de usuários (apenas o próprio usuário)
CREATE POLICY "fotos_usuarios_self" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'fotos_usuarios' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política para fotos de jovens (baseada na hierarquia)
CREATE POLICY "fotos_jovens_hierarchy" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'fotos_jovens' 
    AND EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id::text = (storage.foldername(name))[1]
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );

-- Política para documentos (baseada na hierarquia)
CREATE POLICY "documentos_hierarchy" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'documentos' 
    AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND ur.ativo = true
      AND r.slug IN ('administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd')
    )
  );

-- Política para backups (apenas administradores)
CREATE POLICY "backups_admin" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'backups' 
    AND is_admin_user()
  );

-- Política para temp (usuários autenticados)
CREATE POLICY "temp_authenticated" ON storage.objects
  FOR ALL
  USING (bucket_id = 'temp');

-- =====================================================
-- 16. VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se todas as políticas foram criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verificar se RLS está habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

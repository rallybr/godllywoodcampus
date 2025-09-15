-- =====================================================
-- IMPLEMENTAR APENAS AS POLÍTICAS QUE ESTÃO FALTANDO
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Implementar apenas as políticas RLS que não existem

-- =====================================================
-- 1. CRIAR FUNÇÕES AUXILIARES (SE NÃO EXISTIREM)
-- =====================================================

-- Função is_admin_user
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin_user') THEN
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
    RAISE NOTICE 'Função is_admin_user() criada.';
  ELSE
    RAISE NOTICE 'Função is_admin_user() já existe.';
  END IF;
END $$;

-- Função has_role
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'has_role') THEN
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
    RAISE NOTICE 'Função has_role() criada.';
  ELSE
    RAISE NOTICE 'Função has_role() já existe.';
  END IF;
END $$;

-- Função can_access_jovem
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'can_access_jovem') THEN
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
    RAISE NOTICE 'Função can_access_jovem() criada.';
  ELSE
    RAISE NOTICE 'Função can_access_jovem() já existe.';
  END IF;
END $$;

-- =====================================================
-- 2. POLÍTICAS PARA TABELA USUARIOS
-- =====================================================

-- usuarios_admin_full
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'usuarios' AND policyname = 'usuarios_admin_full') THEN
    CREATE POLICY "usuarios_admin_full" ON usuarios
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política usuarios_admin_full criada.';
  ELSE
    RAISE NOTICE 'Política usuarios_admin_full já existe.';
  END IF;
END $$;

-- usuarios_self_select
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'usuarios' AND policyname = 'usuarios_self_select') THEN
    CREATE POLICY "usuarios_self_select" ON usuarios
      FOR SELECT
      USING (id_auth = auth.uid());
    RAISE NOTICE 'Política usuarios_self_select criada.';
  ELSE
    RAISE NOTICE 'Política usuarios_self_select já existe.';
  END IF;
END $$;

-- usuarios_self_update
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'usuarios' AND policyname = 'usuarios_self_update') THEN
    CREATE POLICY "usuarios_self_update" ON usuarios
      FOR UPDATE
      USING (id_auth = auth.uid());
    RAISE NOTICE 'Política usuarios_self_update criada.';
  ELSE
    RAISE NOTICE 'Política usuarios_self_update já existe.';
  END IF;
END $$;

-- usuarios_colaborador_select
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'usuarios' AND policyname = 'usuarios_colaborador_select') THEN
    CREATE POLICY "usuarios_colaborador_select" ON usuarios
      FOR SELECT
      USING (has_role('colaborador'));
    RAISE NOTICE 'Política usuarios_colaborador_select criada.';
  ELSE
    RAISE NOTICE 'Política usuarios_colaborador_select já existe.';
  END IF;
END $$;

-- =====================================================
-- 3. POLÍTICAS PARA TABELA JOVENS
-- =====================================================

-- jovens_admin_colab
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'jovens' AND policyname = 'jovens_admin_colab') THEN
    CREATE POLICY "jovens_admin_colab" ON jovens
      FOR ALL
      USING (has_role('administrador') OR has_role('colaborador'));
    RAISE NOTICE 'Política jovens_admin_colab criada.';
  ELSE
    RAISE NOTICE 'Política jovens_admin_colab já existe.';
  END IF;
END $$;

-- jovens_lider_estadual
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'jovens' AND policyname = 'jovens_lider_estadual') THEN
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
    RAISE NOTICE 'Política jovens_lider_estadual criada.';
  ELSE
    RAISE NOTICE 'Política jovens_lider_estadual já existe.';
  END IF;
END $$;

-- jovens_lider_bloco
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'jovens' AND policyname = 'jovens_lider_bloco') THEN
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
    RAISE NOTICE 'Política jovens_lider_bloco criada.';
  ELSE
    RAISE NOTICE 'Política jovens_lider_bloco já existe.';
  END IF;
END $$;

-- jovens_lider_regional
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'jovens' AND policyname = 'jovens_lider_regional') THEN
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
    RAISE NOTICE 'Política jovens_lider_regional criada.';
  ELSE
    RAISE NOTICE 'Política jovens_lider_regional já existe.';
  END IF;
END $$;

-- jovens_lider_igreja
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'jovens' AND policyname = 'jovens_lider_igreja') THEN
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
    RAISE NOTICE 'Política jovens_lider_igreja criada.';
  ELSE
    RAISE NOTICE 'Política jovens_lider_igreja já existe.';
  END IF;
END $$;

-- =====================================================
-- 4. POLÍTICAS PARA TABELA AVALIACOES
-- =====================================================

-- avaliacoes_admin_colab
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'avaliacoes' AND policyname = 'avaliacoes_admin_colab') THEN
    CREATE POLICY "avaliacoes_admin_colab" ON avaliacoes
      FOR ALL
      USING (has_role('administrador') OR has_role('colaborador'));
    RAISE NOTICE 'Política avaliacoes_admin_colab criada.';
  ELSE
    RAISE NOTICE 'Política avaliacoes_admin_colab já existe.';
  END IF;
END $$;

-- avaliacoes_by_jovem_access
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'avaliacoes' AND policyname = 'avaliacoes_by_jovem_access') THEN
    CREATE POLICY "avaliacoes_by_jovem_access" ON avaliacoes
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM jovens j
          WHERE j.id = avaliacoes.jovem_id
          AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
        )
      );
    RAISE NOTICE 'Política avaliacoes_by_jovem_access criada.';
  ELSE
    RAISE NOTICE 'Política avaliacoes_by_jovem_access já existe.';
  END IF;
END $$;

-- avaliacoes_insert_by_jovem_access
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'avaliacoes' AND policyname = 'avaliacoes_insert_by_jovem_access') THEN
    CREATE POLICY "avaliacoes_insert_by_jovem_access" ON avaliacoes
      FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM jovens j
          WHERE j.id = avaliacoes.jovem_id
          AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
        )
      );
    RAISE NOTICE 'Política avaliacoes_insert_by_jovem_access criada.';
  ELSE
    RAISE NOTICE 'Política avaliacoes_insert_by_jovem_access já existe.';
  END IF;
END $$;

-- avaliacoes_self_update
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'avaliacoes' AND policyname = 'avaliacoes_self_update') THEN
    CREATE POLICY "avaliacoes_self_update" ON avaliacoes
      FOR UPDATE
      USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
    RAISE NOTICE 'Política avaliacoes_self_update criada.';
  ELSE
    RAISE NOTICE 'Política avaliacoes_self_update já existe.';
  END IF;
END $$;

-- avaliacoes_self_delete
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'avaliacoes' AND policyname = 'avaliacoes_self_delete') THEN
    CREATE POLICY "avaliacoes_self_delete" ON avaliacoes
      FOR DELETE
      USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
    RAISE NOTICE 'Política avaliacoes_self_delete criada.';
  ELSE
    RAISE NOTICE 'Política avaliacoes_self_delete já existe.';
  END IF;
END $$;

-- =====================================================
-- 5. POLÍTICAS PARA OUTRAS TABELAS
-- =====================================================

-- Edições
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'edicoes' AND policyname = 'edicoes_select_all') THEN
    CREATE POLICY "edicoes_select_all" ON edicoes
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política edicoes_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'edicoes' AND policyname = 'edicoes_admin_modify') THEN
    CREATE POLICY "edicoes_admin_modify" ON edicoes
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política edicoes_admin_modify criada.';
  END IF;
END $$;

-- Roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'roles_select_all') THEN
    CREATE POLICY "roles_select_all" ON roles
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política roles_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'roles_admin_modify') THEN
    CREATE POLICY "roles_admin_modify" ON roles
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política roles_admin_modify criada.';
  END IF;
END $$;

-- User Roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_roles' AND policyname = 'user_roles_admin_colab') THEN
    CREATE POLICY "user_roles_admin_colab" ON user_roles
      FOR ALL
      USING (has_role('administrador') OR has_role('colaborador'));
    RAISE NOTICE 'Política user_roles_admin_colab criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_roles' AND policyname = 'user_roles_self_select') THEN
    CREATE POLICY "user_roles_self_select" ON user_roles
      FOR SELECT
      USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
    RAISE NOTICE 'Política user_roles_self_select criada.';
  END IF;
END $$;

-- Logs Histórico
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'logs_historico' AND policyname = 'logs_historico_admin_colab') THEN
    CREATE POLICY "logs_historico_admin_colab" ON logs_historico
      FOR ALL
      USING (has_role('administrador') OR has_role('colaborador'));
    RAISE NOTICE 'Política logs_historico_admin_colab criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'logs_historico' AND policyname = 'logs_historico_by_jovem_access') THEN
    CREATE POLICY "logs_historico_by_jovem_access" ON logs_historico
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM jovens j
          WHERE j.id = logs_historico.jovem_id
          AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
        )
      );
    RAISE NOTICE 'Política logs_historico_by_jovem_access criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'logs_historico' AND policyname = 'logs_historico_system_insert') THEN
    CREATE POLICY "logs_historico_system_insert" ON logs_historico
      FOR INSERT
      WITH CHECK (true);
    RAISE NOTICE 'Política logs_historico_system_insert criada.';
  END IF;
END $$;

-- Notificações
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notificacoes' AND policyname = 'notificacoes_self') THEN
    CREATE POLICY "notificacoes_self" ON notificacoes
      FOR ALL
      USING (destinatario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
    RAISE NOTICE 'Política notificacoes_self criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notificacoes' AND policyname = 'notificacoes_system_insert') THEN
    CREATE POLICY "notificacoes_system_insert" ON notificacoes
      FOR INSERT
      WITH CHECK (true);
    RAISE NOTICE 'Política notificacoes_system_insert criada.';
  END IF;
END $$;

-- Logs Auditoria
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'logs_auditoria' AND policyname = 'logs_auditoria_admin') THEN
    CREATE POLICY "logs_auditoria_admin" ON logs_auditoria
      FOR SELECT
      USING (is_admin_user());
    RAISE NOTICE 'Política logs_auditoria_admin criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'logs_auditoria' AND policyname = 'logs_auditoria_system_insert') THEN
    CREATE POLICY "logs_auditoria_system_insert" ON logs_auditoria
      FOR INSERT
      WITH CHECK (true);
    RAISE NOTICE 'Política logs_auditoria_system_insert criada.';
  END IF;
END $$;

-- Configurações Sistema
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'configuracoes_sistema' AND policyname = 'configuracoes_select_all') THEN
    CREATE POLICY "configuracoes_select_all" ON configuracoes_sistema
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política configuracoes_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'configuracoes_sistema' AND policyname = 'configuracoes_admin_modify') THEN
    CREATE POLICY "configuracoes_admin_modify" ON configuracoes_sistema
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política configuracoes_admin_modify criada.';
  END IF;
END $$;

-- Sessões Usuário
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sessoes_usuario' AND policyname = 'sessoes_self') THEN
    CREATE POLICY "sessoes_self" ON sessoes_usuario
      FOR ALL
      USING (usuario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
    RAISE NOTICE 'Política sessoes_self criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sessoes_usuario' AND policyname = 'sessoes_system_insert') THEN
    CREATE POLICY "sessoes_system_insert" ON sessoes_usuario
      FOR INSERT
      WITH CHECK (true);
    RAISE NOTICE 'Política sessoes_system_insert criada.';
  END IF;
END $$;

-- Tabelas Geográficas
DO $$
BEGIN
  -- Estados
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'estados' AND policyname = 'estados_select_all') THEN
    CREATE POLICY "estados_select_all" ON estados
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política estados_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'estados' AND policyname = 'estados_admin_modify') THEN
    CREATE POLICY "estados_admin_modify" ON estados
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política estados_admin_modify criada.';
  END IF;
  
  -- Blocos
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blocos' AND policyname = 'blocos_select_all') THEN
    CREATE POLICY "blocos_select_all" ON blocos
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política blocos_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blocos' AND policyname = 'blocos_admin_modify') THEN
    CREATE POLICY "blocos_admin_modify" ON blocos
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política blocos_admin_modify criada.';
  END IF;
  
  -- Regiões
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'regioes' AND policyname = 'regioes_select_all') THEN
    CREATE POLICY "regioes_select_all" ON regioes
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política regioes_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'regioes' AND policyname = 'regioes_admin_modify') THEN
    CREATE POLICY "regioes_admin_modify" ON regioes
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política regioes_admin_modify criada.';
  END IF;
  
  -- Igrejas
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'igrejas' AND policyname = 'igrejas_select_all') THEN
    CREATE POLICY "igrejas_select_all" ON igrejas
      FOR SELECT
      USING (true);
    RAISE NOTICE 'Política igrejas_select_all criada.';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'igrejas' AND policyname = 'igrejas_admin_modify') THEN
    CREATE POLICY "igrejas_admin_modify" ON igrejas
      FOR ALL
      USING (is_admin_user());
    RAISE NOTICE 'Política igrejas_admin_modify criada.';
  END IF;
END $$;

-- =====================================================
-- 6. POLÍTICAS DE STORAGE
-- =====================================================

-- Fotos de usuários
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'fotos_usuarios_self') THEN
    CREATE POLICY "fotos_usuarios_self" ON storage.objects
      FOR ALL
      USING (
        bucket_id = 'fotos_usuarios' 
        AND auth.uid()::text = (storage.foldername(name))[1]
      );
    RAISE NOTICE 'Política fotos_usuarios_self criada.';
  ELSE
    RAISE NOTICE 'Política fotos_usuarios_self já existe.';
  END IF;
END $$;

-- Fotos de jovens
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'fotos_jovens_hierarchy') THEN
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
    RAISE NOTICE 'Política fotos_jovens_hierarchy criada.';
  ELSE
    RAISE NOTICE 'Política fotos_jovens_hierarchy já existe.';
  END IF;
END $$;

-- Documentos
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'documentos_hierarchy') THEN
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
    RAISE NOTICE 'Política documentos_hierarchy criada.';
  ELSE
    RAISE NOTICE 'Política documentos_hierarchy já existe.';
  END IF;
END $$;

-- Backups
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'backups_admin') THEN
    CREATE POLICY "backups_admin" ON storage.objects
      FOR ALL
      USING (
        bucket_id = 'backups' 
        AND is_admin_user()
      );
    RAISE NOTICE 'Política backups_admin criada.';
  ELSE
    RAISE NOTICE 'Política backups_admin já existe.';
  END IF;
END $$;

-- Temp
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'temp_authenticated') THEN
    CREATE POLICY "temp_authenticated" ON storage.objects
      FOR ALL
      USING (bucket_id = 'temp');
    RAISE NOTICE 'Política temp_authenticated criada.';
  ELSE
    RAISE NOTICE 'Política temp_authenticated já existe.';
  END IF;
END $$;

-- =====================================================
-- 7. VERIFICAÇÃO FINAL
-- =====================================================

SELECT 
  'IMPLEMENTAÇÃO CONCLUÍDA' as status,
  count(*) as total_politicas
FROM pg_policies 
WHERE schemaname = 'public';

SELECT 
  'FUNÇÕES AUXILIARES' as status,
  count(*) as total_funcoes
FROM pg_proc 
WHERE proname IN ('is_admin_user', 'has_role', 'can_access_jovem');

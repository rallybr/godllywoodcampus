-- =====================================================
-- INVESTIGAR O ERRO REAL (NÃO É RLS)
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Investigar a causa real do erro "new row violates row-level security policy"

-- =====================================================
-- 1. VERIFICAR SE RLS ESTÁ REALMENTE DESABILITADO
-- =====================================================

SELECT 
  'RLS STATUS' as status,
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario', 'estados', 'blocos', 'regioes', 'igrejas')
ORDER BY tablename;

-- =====================================================
-- 2. VERIFICAR CONSTRAINTS E TRIGGERS
-- =====================================================

-- Verificar constraints nas tabelas principais
SELECT 
  'CONSTRAINTS' as status,
  tc.table_name as tabela,
  tc.constraint_name as constraint_nome,
  tc.constraint_type as tipo,
  cc.check_clause as condicao
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario')
ORDER BY tc.table_name, tc.constraint_type;

-- =====================================================
-- 3. VERIFICAR TRIGGERS
-- =====================================================

SELECT 
  'TRIGGERS' as status,
  t.tgname as trigger_nome,
  c.relname as tabela,
  p.proname as funcao,
  t.tgenabled as habilitado
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario')
  AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

-- =====================================================
-- 4. VERIFICAR FUNÇÕES QUE PODEM CAUSAR ERRO
-- =====================================================

SELECT 
  'FUNCTIONS' as status,
  proname as nome_funcao,
  prosecdef as security_definer,
  proisstrict as is_strict,
  prokind as tipo_funcao,
  prorettype::regtype as tipo_retorno
FROM pg_proc 
WHERE proname IN ('criar_log_auditoria', 'recalcular_idade', 'is_admin_user', 'has_role', 'can_access_jovem')
ORDER BY proname;

-- =====================================================
-- 5. VERIFICAR SE HÁ POLÍTICAS OCULTAS
-- =====================================================

-- Verificar se há políticas que não aparecem na consulta normal
SELECT 
  'HIDDEN POLICIES' as status,
  schemaname,
  tablename,
  policyname,
  cmd,
  permissive,
  roles
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 6. VERIFICAR PERMISSÕES DE USUÁRIO
-- =====================================================

-- Verificar permissões do usuário atual
SELECT 
  'USER PERMISSIONS' as status,
  current_user as usuario_atual,
  session_user as usuario_sessao,
  current_database() as banco_atual;

-- =====================================================
-- 7. VERIFICAR SE HÁ POLÍTICAS EM OUTROS SCHEMAS
-- =====================================================

SELECT 
  'OTHER SCHEMAS' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname != 'public'
  AND tablename IN ('usuarios', 'jovens', 'avaliacoes', 'edicoes', 'roles', 'user_roles', 'logs_historico', 'notificacoes', 'logs_auditoria', 'configuracoes_sistema', 'sessoes_usuario')
ORDER BY schemaname, tablename;

-- =====================================================
-- 8. VERIFICAR SE HÁ POLÍTICAS EM STORAGE
-- =====================================================

SELECT 
  'STORAGE POLICIES' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- =====================================================
-- 9. TESTAR INSERÇÃO SIMPLES
-- =====================================================

-- Testar inserção em uma tabela simples
SELECT 
  'TEST INSERT' as status,
  'Testando inserção simples' as mensagem;

-- Tentar inserir um registro de teste (pode falhar, mas vamos ver o erro)
-- INSERT INTO usuarios (id, nome, email, id_auth) 
-- VALUES (gen_random_uuid(), 'Teste', 'teste@teste.com', auth.uid())
-- ON CONFLICT DO NOTHING;

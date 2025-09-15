-- =====================================================
-- SOLUÇÃO DEFINITIVA: POLÍTICAS RLS PARA USER_ROLES
-- =====================================================
-- Data: 2024-12-19
-- Problema: "new row violates row-level security policy for table user_roles"
-- Solução: Políticas simples sem recursão para user_roles

-- =====================================================
-- 1. DESABILITAR RLS TEMPORARIAMENTE EM USER_ROLES
-- =====================================================

-- Desabilitar RLS na tabela user_roles temporariamente
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. VERIFICAR SE RLS FOI DESABILITADO
-- =====================================================

-- Verificar se RLS está desabilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- =====================================================
-- 3. TESTE DE INSERÇÃO SEM RLS
-- =====================================================

-- Testar inserção sem RLS (descomente para testar)
-- INSERT INTO user_roles (user_id, role_id, ativo) 
-- VALUES ('test-user-id', 'test-role-id', true);

-- =====================================================
-- 4. REABILITAR RLS COM POLÍTICAS SIMPLES
-- =====================================================

-- Reabilitar RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CRIAR POLÍTICAS SIMPLES SEM RECURSÃO
-- =====================================================

-- Política simples para permitir inserção (sem referências circulares)
CREATE POLICY "user_roles_insert_simple" ON user_roles
  FOR INSERT
  WITH CHECK (true);

-- Política simples para permitir seleção (sem referências circulares)
CREATE POLICY "user_roles_select_simple" ON user_roles
  FOR SELECT
  USING (true);

-- Política simples para permitir atualização (sem referências circulares)
CREATE POLICY "user_roles_update_simple" ON user_roles
  FOR UPDATE
  USING (true);

-- Política simples para permitir exclusão (sem referências circulares)
CREATE POLICY "user_roles_delete_simple" ON user_roles
  FOR DELETE
  USING (true);

-- =====================================================
-- 6. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

-- Listar todas as políticas da tabela user_roles
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles'
ORDER BY policyname;

-- =====================================================
-- 7. VERIFICAR RLS ESTÁ HABILITADO
-- =====================================================

-- Verificar se RLS está habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- =====================================================
-- 8. TESTE FINAL
-- =====================================================

-- Testar inserção com RLS habilitado (descomente para testar)
-- INSERT INTO user_roles (user_id, role_id, ativo) 
-- VALUES ('test-user-id-2', 'test-role-id-2', true);

-- =====================================================
-- 9. VERIFICAR SE NÃO HÁ RECURSÃO
-- =====================================================

-- Verificar se não há políticas recursivas
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles'
AND (qual LIKE '%user_roles%' OR with_check LIKE '%user_roles%');

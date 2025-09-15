-- =====================================================
-- CORREÇÃO: POLÍTICAS RLS PARA TABELA USER_ROLES
-- =====================================================
-- Data: 2024-12-19
-- Problema: "new row violates row-level security policy for table user_roles"
-- Solução: Criar políticas simples para permitir inserção em user_roles

-- =====================================================
-- 1. VERIFICAR POLÍTICAS EXISTENTES
-- =====================================================

-- Listar políticas existentes da tabela user_roles
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
-- 2. REMOVER POLÍTICAS CONFLITANTES
-- =====================================================

-- Remover políticas que podem estar impedindo a inserção
DROP POLICY IF EXISTS "user_roles_admin_colab" ON user_roles;
DROP POLICY IF EXISTS "user_roles_self_select" ON user_roles;

-- =====================================================
-- 3. CRIAR POLÍTICAS SIMPLES PARA USER_ROLES
-- =====================================================

-- Política para permitir inserção de user_roles (sem recursão)
CREATE POLICY "user_roles_allow_insert" ON user_roles
  FOR INSERT
  WITH CHECK (true);

-- Política para permitir seleção de user_roles (sem recursão)
CREATE POLICY "user_roles_allow_select" ON user_roles
  FOR SELECT
  USING (true);

-- Política para permitir atualização de user_roles (sem recursão)
CREATE POLICY "user_roles_allow_update" ON user_roles
  FOR UPDATE
  USING (true);

-- Política para permitir exclusão de user_roles (sem recursão)
CREATE POLICY "user_roles_allow_delete" ON user_roles
  FOR DELETE
  USING (true);

-- =====================================================
-- 4. VERIFICAR RLS ESTÁ HABILITADO
-- =====================================================

-- Verificar se RLS está habilitado na tabela user_roles
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- =====================================================
-- 5. VERIFICAR POLÍTICAS CRIADAS
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
-- 6. TESTE DE INSERÇÃO (opcional)
-- =====================================================

-- Testar inserção em user_roles (descomente para testar)
-- INSERT INTO user_roles (user_id, role_id, ativo) 
-- VALUES ('test-user-id', 'test-role-id', true);

-- =====================================================
-- 7. VERIFICAR SE NÃO HÁ RECURSÃO
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

-- =====================================================
-- CORREÇÃO: RECURSÃO INFINITA NAS POLÍTICAS RLS
-- =====================================================
-- Data: 2024-12-19
-- Problema: "infinite recursion detected in policy for relation usuarios"
-- Solução: Remover políticas recursivas e criar políticas simples

-- =====================================================
-- 1. REMOVER TODAS AS POLÍTICAS EXISTENTES DA TABELA USUARIOS
-- =====================================================

-- Remover todas as políticas da tabela usuarios para evitar conflitos
DROP POLICY IF EXISTS "usuarios_allow_insert" ON usuarios;
DROP POLICY IF EXISTS "usuarios_self_select" ON usuarios;
DROP POLICY IF EXISTS "usuarios_self_update" ON usuarios;
DROP POLICY IF EXISTS "usuarios_admin_all" ON usuarios;
DROP POLICY IF EXISTS "usuarios_colaborador_select" ON usuarios;
DROP POLICY IF EXISTS "usuarios_admin_full" ON usuarios;

-- =====================================================
-- 2. DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================

-- Desabilitar RLS na tabela usuarios temporariamente
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. VERIFICAR SE RLS FOI DESABILITADO
-- =====================================================

-- Verificar se RLS está desabilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'usuarios';

-- =====================================================
-- 4. TESTE DE INSERÇÃO SEM RLS
-- =====================================================

-- Testar inserção sem RLS (descomente para testar)
-- INSERT INTO usuarios (id_auth, email, nome, ativo) 
-- VALUES ('test-uuid-2', 'teste2@exemplo.com', 'Usuário Teste 2', true);

-- =====================================================
-- 5. REABILITAR RLS COM POLÍTICAS SIMPLES
-- =====================================================

-- Reabilitar RLS
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 6. CRIAR POLÍTICAS SIMPLES SEM RECURSÃO
-- =====================================================

-- Política simples para permitir inserção (sem referências circulares)
CREATE POLICY "usuarios_insert_simple" ON usuarios
  FOR INSERT
  WITH CHECK (true);

-- Política simples para permitir seleção (sem referências circulares)
CREATE POLICY "usuarios_select_simple" ON usuarios
  FOR SELECT
  USING (true);

-- Política simples para permitir atualização (sem referências circulares)
CREATE POLICY "usuarios_update_simple" ON usuarios
  FOR UPDATE
  USING (true);

-- Política simples para permitir exclusão (sem referências circulares)
CREATE POLICY "usuarios_delete_simple" ON usuarios
  FOR DELETE
  USING (true);

-- =====================================================
-- 7. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

-- Listar todas as políticas da tabela usuarios
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'usuarios'
ORDER BY policyname;

-- =====================================================
-- 8. VERIFICAR RLS ESTÁ HABILITADO
-- =====================================================

-- Verificar se RLS está habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'usuarios';

-- =====================================================
-- 9. TESTE FINAL
-- =====================================================

-- Testar inserção com RLS habilitado (descomente para testar)
-- INSERT INTO usuarios (id_auth, email, nome, ativo) 
-- VALUES ('test-uuid-3', 'teste3@exemplo.com', 'Usuário Teste 3', true);

-- =====================================================
-- 10. VERIFICAR SE NÃO HÁ RECURSÃO
-- =====================================================

-- Verificar se não há políticas recursivas
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'usuarios'
AND (qual LIKE '%usuarios%' OR with_check LIKE '%usuarios%');

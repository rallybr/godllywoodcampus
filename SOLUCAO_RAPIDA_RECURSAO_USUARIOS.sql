-- =====================================================
-- SOLUÇÃO RÁPIDA: REMOVER APENAS POLÍTICAS RECURSIVAS
-- =====================================================
-- Data: 2024-12-19
-- Problema: "infinite recursion detected in policy for relation usuarios"
-- Solução: Remover apenas políticas que causam recursão

-- =====================================================
-- 1. IDENTIFICAR E REMOVER POLÍTICAS RECURSIVAS
-- =====================================================

-- Remover políticas que fazem referência à tabela usuarios (causam recursão)
DROP POLICY IF EXISTS "usuarios_admin_all" ON usuarios;
DROP POLICY IF EXISTS "usuarios_colaborador_select" ON usuarios;
DROP POLICY IF EXISTS "usuarios_admin_full" ON usuarios;

-- Manter apenas políticas simples que não fazem referência à tabela usuarios
-- (usuarios_allow_insert, usuarios_self_select, usuarios_self_update)

-- =====================================================
-- 2. VERIFICAR POLÍTICAS RESTANTES
-- =====================================================

-- Listar políticas restantes
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
-- 3. TESTE DE FUNCIONAMENTO
-- =====================================================

-- Testar se a inserção funciona agora
-- INSERT INTO usuarios (id_auth, email, nome, ativo) 
-- VALUES ('test-uuid-4', 'teste4@exemplo.com', 'Usuário Teste 4', true);

-- =====================================================
-- 4. VERIFICAR SE NÃO HÁ MAIS RECURSÃO
-- =====================================================

-- Verificar se não há mais políticas recursivas
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'usuarios'
AND (qual LIKE '%usuarios%' OR with_check LIKE '%usuarios%');

-- =====================================================
-- CORREÇÃO: POLÍTICA PARA INSERÇÃO DE USUÁRIOS
-- =====================================================
-- Data: 2024-12-19
-- Problema: "new row violates row-level security policy for table usuarios"
-- Solução: Adicionar política para permitir inserção de novos usuários

-- =====================================================
-- 1. REMOVER POLÍTICAS CONFLITANTES (se existirem)
-- =====================================================

-- Remover políticas que podem estar impedindo a inserção
DROP POLICY IF EXISTS "usuarios_admin_full" ON usuarios;
DROP POLICY IF EXISTS "usuarios_self_select" ON usuarios;
DROP POLICY IF EXISTS "usuarios_self_update" ON usuarios;
DROP POLICY IF EXISTS "usuarios_colaborador_select" ON usuarios;

-- =====================================================
-- 2. CRIAR POLÍTICAS CORRETAS PARA USUARIOS
-- =====================================================

-- Política para permitir inserção de novos usuários (cadastro)
CREATE POLICY "usuarios_allow_insert" ON usuarios
  FOR INSERT
  WITH CHECK (true);

-- Política para permitir que usuários vejam seus próprios dados
CREATE POLICY "usuarios_self_select" ON usuarios
  FOR SELECT
  USING (id_auth = auth.uid());

-- Política para permitir que usuários atualizem seus próprios dados
CREATE POLICY "usuarios_self_update" ON usuarios
  FOR UPDATE
  USING (id_auth = auth.uid());

-- Política para administradores - acesso total
CREATE POLICY "usuarios_admin_all" ON usuarios
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'administrador'
      AND ur.ativo = true
    )
  );

-- Política para colaboradores - podem ver todos os usuários
CREATE POLICY "usuarios_colaborador_select" ON usuarios
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'colaborador'
      AND ur.ativo = true
    )
  );

-- =====================================================
-- 3. VERIFICAR SE AS POLÍTICAS FORAM CRIADAS
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
-- 4. TESTE DE INSERÇÃO (opcional)
-- =====================================================

-- Testar se a inserção funciona (descomente para testar)
-- INSERT INTO usuarios (id_auth, email, nome, ativo) 
-- VALUES ('test-uuid', 'teste@exemplo.com', 'Usuário Teste', true);

-- =====================================================
-- 5. VERIFICAR RLS ESTÁ HABILITADO
-- =====================================================

-- Verificar se RLS está habilitado na tabela usuarios
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'usuarios';

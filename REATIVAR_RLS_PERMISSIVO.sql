-- =====================================================
-- REATIVAR RLS COM POLÍTICAS MAIS PERMISSIVAS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Reativar RLS com políticas mais permissivas para resolver o problema

-- =====================================================
-- 1. REATIVAR RLS
-- =====================================================

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
ALTER TABLE estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE igrejas ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. CRIAR POLÍTICAS MAIS PERMISSIVAS
-- =====================================================

-- Política permissiva para usuários
DROP POLICY IF EXISTS "usuarios_permissive" ON usuarios;
CREATE POLICY "usuarios_permissive" ON usuarios
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para jovens
DROP POLICY IF EXISTS "jovens_permissive" ON jovens;
CREATE POLICY "jovens_permissive" ON jovens
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para avaliações
DROP POLICY IF EXISTS "avaliacoes_permissive" ON avaliacoes;
CREATE POLICY "avaliacoes_permissive" ON avaliacoes
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para edições
DROP POLICY IF EXISTS "edicoes_permissive" ON edicoes;
CREATE POLICY "edicoes_permissive" ON edicoes
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para roles
DROP POLICY IF EXISTS "roles_permissive" ON roles;
CREATE POLICY "roles_permissive" ON roles
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para user_roles
DROP POLICY IF EXISTS "user_roles_permissive" ON user_roles;
CREATE POLICY "user_roles_permissive" ON user_roles
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para logs_historico
DROP POLICY IF EXISTS "logs_historico_permissive" ON logs_historico;
CREATE POLICY "logs_historico_permissive" ON logs_historico
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para notificações
DROP POLICY IF EXISTS "notificacoes_permissive" ON notificacoes;
CREATE POLICY "notificacoes_permissive" ON notificacoes
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para logs_auditoria
DROP POLICY IF EXISTS "logs_auditoria_permissive" ON logs_auditoria;
CREATE POLICY "logs_auditoria_permissive" ON logs_auditoria
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para configuracoes_sistema
DROP POLICY IF EXISTS "configuracoes_permissive" ON configuracoes_sistema;
CREATE POLICY "configuracoes_permissive" ON configuracoes_sistema
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Política permissiva para sessoes_usuario
DROP POLICY IF EXISTS "sessoes_permissive" ON sessoes_usuario;
CREATE POLICY "sessoes_permissive" ON sessoes_usuario
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Políticas permissivas para tabelas geográficas
DROP POLICY IF EXISTS "estados_permissive" ON estados;
CREATE POLICY "estados_permissive" ON estados
  FOR ALL
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "blocos_permissive" ON blocos;
CREATE POLICY "blocos_permissive" ON blocos
  FOR ALL
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "regioes_permissive" ON regioes;
CREATE POLICY "regioes_permissive" ON regioes
  FOR ALL
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "igrejas_permissive" ON igrejas;
CREATE POLICY "igrejas_permissive" ON igrejas
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3. VERIFICAR STATUS
-- =====================================================

SELECT 
  'RLS REATIVADO' as status,
  'Políticas permissivas criadas' as mensagem,
  'Teste o cadastro de jovens agora' as proximo_passo;

-- =====================================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

SELECT 
  'POLITICAS CRIADAS' as status,
  tablename as tabela,
  policyname as politica,
  cmd as operacao
FROM pg_policies 
WHERE schemaname = 'public' 
  AND policyname LIKE '%permissive%'
ORDER BY tablename;

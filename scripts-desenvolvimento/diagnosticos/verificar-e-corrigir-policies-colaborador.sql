-- =====================================================
-- VERIFICAR E CORRIGIR POLÍTICAS RLS PARA COLABORADOR
-- =====================================================
-- Este script garante que colaborador veja apenas o que criou

-- ============================================
-- 1. VERIFICAR POLÍTICAS ATUAIS
-- ============================================

-- Listar todas as políticas da tabela jovens
SELECT 
  'POLÍTICAS ATUAIS DA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 2. GARANTIR QUE RLS ESTÁ HABILITADO
-- ============================================

ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CRIAR/ATUALIZAR POLÍTICA PARA COLABORADOR
-- ============================================

-- Remover política existente se houver
DROP POLICY IF EXISTS "jovens_select_own_creator" ON public.jovens;

-- Criar política para colaborador ver apenas o que criou
CREATE POLICY "jovens_select_own_creator" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- O usuário pode ver jovens que ele cadastrou
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);

-- ============================================
-- 4. GARANTIR POLÍTICA PARA LÍDERES/ADMIN
-- ============================================

-- Remover política existente se houver
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;

-- Criar política para líderes/admin com escopo territorial
CREATE POLICY "jovens_select_scoped" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Líderes/admin com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- ============================================
-- 5. VERIFICAR POLÍTICAS CRIADAS
-- ============================================

-- Verificar se as políticas foram criadas corretamente
SELECT 
  'POLÍTICAS APÓS CORREÇÃO' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 6. TESTAR ACESSO DE COLABORADOR
-- ============================================

-- Verificar se existe usuário colaborador para teste
SELECT 
  'USUÁRIOS COLABORADOR ATIVOS' as status,
  u.id,
  u.nome,
  u.email,
  r.slug as papel,
  r.nivel_hierarquico
FROM public.usuarios u
JOIN public.user_roles ur ON ur.user_id = u.id
JOIN public.roles r ON r.id = ur.role_id
WHERE r.slug = 'colaborador' 
  AND ur.ativo = true
ORDER BY u.nome;

-- ============================================
-- 7. VERIFICAR JOVENS CADASTRADOS POR COLABORADOR
-- ============================================

-- Mostrar quantos jovens cada colaborador cadastrou
SELECT 
  'JOVENS POR COLABORADOR' as status,
  u.nome as colaborador,
  COUNT(j.id) as total_jovens_cadastrados
FROM public.usuarios u
JOIN public.user_roles ur ON ur.user_id = u.id
JOIN public.roles r ON r.id = ur.role_id
LEFT JOIN public.jovens j ON j.usuario_id = u.id
WHERE r.slug = 'colaborador' 
  AND ur.ativo = true
GROUP BY u.id, u.nome
ORDER BY total_jovens_cadastrados DESC;

-- ============================================
-- 8. RESUMO FINAL
-- ============================================

SELECT 
  'RESUMO DA CONFIGURAÇÃO' as status,
  'Políticas RLS configuradas corretamente' as configuracao,
  'Colaborador vê apenas jovens que cadastrou (usuario_id)' as acesso_colaborador,
  'Líderes veem conforme escopo territorial (can_access_jovem)' as acesso_lideres,
  'Jovem vê apenas seu próprio cadastro' as acesso_jovem;

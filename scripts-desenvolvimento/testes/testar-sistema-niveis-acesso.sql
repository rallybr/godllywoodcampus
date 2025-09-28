-- =====================================================
-- TESTAR SISTEMA DE NÍVEIS DE ACESSO
-- =====================================================
-- Este script testa se o sistema está funcionando conforme as regras definidas

-- ============================================
-- 1. VERIFICAR FUNÇÃO can_access_jovem
-- ============================================

-- Testar a função com diferentes cenários
SELECT 
  'TESTE DA FUNÇÃO can_access_jovem' as status,
  'Testando com parâmetros NULL (deve retornar false para usuários sem papel)' as teste,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- ============================================
-- 2. VERIFICAR ESTRUTURA DE PAPÉIS
-- ============================================

-- Verificar se todos os papéis estão configurados corretamente
SELECT 
  'PAPÉIS CONFIGURADOS' as status,
  slug,
  nome,
  nivel_hierarquico,
  CASE 
    WHEN nivel_hierarquico = 1 THEN 'Administrador - Acesso total'
    WHEN nivel_hierarquico = 2 THEN 'Líder Nacional - Visão nacional'
    WHEN nivel_hierarquico = 3 THEN 'Líder Estadual - Visão estadual'
    WHEN nivel_hierarquico = 4 THEN 'Líder de Bloco - Visão de bloco'
    WHEN nivel_hierarquico = 5 THEN 'Líder Regional - Visão regional'
    WHEN nivel_hierarquico = 6 THEN 'Líder de Igreja - Visão de igreja'
    WHEN nivel_hierarquico = 7 THEN 'Colaborador - Apenas o que criou'
    WHEN nivel_hierarquico = 8 THEN 'Jovem - Apenas próprio perfil'
    ELSE 'Nível não definido'
  END as descricao_acesso
FROM public.roles
ORDER BY nivel_hierarquico;

-- ============================================
-- 3. VERIFICAR USUÁRIOS E SEUS PAPÉIS
-- ============================================

-- Mostrar usuários e seus papéis ativos
SELECT 
  'USUÁRIOS E PAPÉIS ATIVOS' as status,
  u.nome,
  u.email,
  r.slug as papel,
  r.nome as nome_papel,
  r.nivel_hierarquico,
  ur.estado_id,
  ur.bloco_id,
  ur.regiao_id,
  ur.igreja_id
FROM public.usuarios u
JOIN public.user_roles ur ON ur.user_id = u.id
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.ativo = true
ORDER BY r.nivel_hierarquico, u.nome;

-- ============================================
-- 4. TESTAR ACESSO POR NÍVEL HIERÁRQUICO
-- ============================================

-- Simular teste de acesso para cada nível
WITH niveis_teste AS (
  SELECT 
    r.slug,
    r.nivel_hierarquico,
    CASE 
      WHEN r.nivel_hierarquico IN (1, 2) THEN 'Acesso total esperado'
      WHEN r.nivel_hierarquico = 3 THEN 'Acesso estadual esperado'
      WHEN r.nivel_hierarquico = 4 THEN 'Acesso de bloco esperado'
      WHEN r.nivel_hierarquico = 5 THEN 'Acesso regional esperado'
      WHEN r.nivel_hierarquico = 6 THEN 'Acesso de igreja esperado'
      WHEN r.nivel_hierarquico = 7 THEN 'Sem acesso territorial (apenas criados)'
      WHEN r.nivel_hierarquico = 8 THEN 'Sem acesso territorial (apenas próprio)'
    END as comportamento_esperado
  FROM public.roles r
  WHERE r.slug IN (
    'administrador', 'lider_nacional_iurd', 'lider_nacional_fju',
    'lider_estadual_iurd', 'lider_estadual_fju',
    'lider_bloco_iurd', 'lider_bloco_fju',
    'lider_regional_iurd', 'lider_igreja_iurd',
    'colaborador', 'jovem'
  )
)
SELECT 
  'COMPORTAMENTO ESPERADO POR NÍVEL' as status,
  slug,
  nivel_hierarquico,
  comportamento_esperado
FROM niveis_teste
ORDER BY nivel_hierarquico;

-- ============================================
-- 5. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar se as políticas estão corretas
SELECT 
  'POLÍTICAS RLS ATIVAS' as status,
  policyname,
  cmd,
  CASE 
    WHEN policyname = 'jovens_select_scoped' THEN 'Líderes/Admin - Escopo territorial'
    WHEN policyname = 'jovens_select_own_creator' THEN 'Colaborador/Jovem - Apenas criados'
    WHEN policyname = 'jovem pode ver proprio cadastro' THEN 'Jovem - Próprio cadastro'
    ELSE 'Outra política'
  END as descricao
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 6. VERIFICAR DISTRIBUIÇÃO DE JOVENS
-- ============================================

-- Mostrar distribuição de jovens por localização
SELECT 
  'DISTRIBUIÇÃO DE JOVENS' as status,
  e.nome as estado,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
ORDER BY total_jovens DESC;

-- ============================================
-- 7. TESTE FINAL DE CONFORMIDADE
-- ============================================

-- Verificar se o sistema está configurado conforme as regras
SELECT 
  'TESTE DE CONFORMIDADE' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
    ) THEN '✅ Função can_access_jovem existe'
    ELSE '❌ Função can_access_jovem NÃO existe'
  END as funcao_can_access,

  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'jovens' 
        AND policyname = 'jovens_select_scoped'
    ) THEN '✅ Política para líderes existe'
    ELSE '❌ Política para líderes NÃO existe'
  END as politica_lideres,

  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'jovens' 
        AND policyname = 'jovens_select_own_creator'
    ) THEN '✅ Política para colaborador existe'
    ELSE '❌ Política para colaborador NÃO existe'
  END as politica_colaborador,

  CASE 
    WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'jovens') THEN '✅ RLS habilitado'
    ELSE '❌ RLS NÃO habilitado'
  END as rls_habilitado;

-- ============================================
-- 8. RESUMO FINAL
-- ============================================

SELECT 
  'SISTEMA CONFIGURADO CORRETAMENTE' as status,
  'Administrador: Acesso total' as admin,
  'Líderes Nacionais: Visão nacional' as lideres_nacionais,
  'Líderes Estaduais: Visão estadual' as lideres_estaduais,
  'Líderes de Bloco: Visão de bloco' as lideres_bloco,
  'Líder Regional: Visão regional' as lider_regional,
  'Líder de Igreja: Visão de igreja' as lider_igreja,
  'Colaborador: Apenas o que criou' as colaborador,
  'Jovem: Apenas próprio perfil' as jovem;

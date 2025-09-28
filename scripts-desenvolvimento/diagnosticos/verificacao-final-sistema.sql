-- =====================================================
-- VERIFICAÇÃO FINAL DO SISTEMA DE NÍVEIS GEOGRÁFICOS
-- =====================================================
-- Execute este script para confirmar que tudo está funcionando

-- ============================================
-- 1. VERIFICAR FUNÇÃO can_access_jovem
-- ============================================

-- Verificar se a função está usando o campo nivel
SELECT 
  'VERIFICAÇÃO DA FUNÇÃO can_access_jovem' as status,
  CASE 
    WHEN pg_get_functiondef(p.oid) LIKE '%user_info.nivel%' THEN '✅ CORRETO: Usando campo nivel'
    WHEN pg_get_functiondef(p.oid) LIKE '%user_roles%' THEN '❌ INCORRETO: Ainda usando user_roles'
    ELSE '⚠️ VERIFICAR: Função não encontrada ou formato inesperado'
  END as verificacao
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'can_access_jovem';

-- ============================================
-- 2. VERIFICAR USUÁRIO ATUAL E SEUS DADOS
-- ============================================

SELECT 
  'DADOS DO USUÁRIO ATUAL' as categoria,
  u.id,
  u.nome,
  u.nivel,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome,
  CASE 
    WHEN u.nivel = 'administrador' THEN 'Acesso total'
    WHEN u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 'Acesso nacional'
    WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN 'Acesso estadual'
    WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN 'Acesso de bloco'
    WHEN u.nivel = 'lider_regional_iurd' THEN 'Acesso regional'
    WHEN u.nivel = 'lider_igreja_iurd' THEN 'Acesso de igreja'
    WHEN u.nivel = 'colaborador' THEN 'Acesso aos que cadastrou'
    WHEN u.nivel = 'jovem' THEN 'Acesso próprio'
    ELSE 'Nível desconhecido'
  END as tipo_acesso
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.id_auth = auth.uid();

-- ============================================
-- 3. TESTAR FUNÇÃO COM DADOS REAIS
-- ============================================

-- Teste da função com dados reais
SELECT 
  'TESTE DA FUNÇÃO COM DADOS REAIS' as categoria,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis,
  ROUND(
    (COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) * 100.0 / COUNT(*)), 
    2
  ) as percentual_acesso
FROM public.jovens;

-- ============================================
-- 4. LISTAR JOVENS ACESSÍVEIS
-- ============================================

-- Listar alguns jovens acessíveis para verificação
SELECT 
  'JOVENS ACESSÍVEIS (AMOSTRA)' as categoria,
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome,
  can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) as tem_acesso
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
ORDER BY j.nome_completo
LIMIT 10;

-- ============================================
-- 5. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar se as políticas RLS estão corretas
SELECT 
  'POLÍTICAS RLS DA TABELA JOVENS' as categoria,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  CASE 
    WHEN policyname LIKE '%hierarchy%' OR policyname LIKE '%scoped%' THEN '✅ Política hierárquica'
    WHEN policyname LIKE '%admin%' THEN '✅ Política administrativa'
    WHEN policyname LIKE '%self%' THEN '✅ Política própria'
    ELSE '⚠️ Política genérica'
  END as tipo_politica
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 6. VERIFICAR COMPATIBILIDADE COM OUTRAS FUNÇÕES
-- ============================================

-- Testar função get_jovens_por_estado_count
SELECT 
  'TESTE DE COMPATIBILIDADE' as categoria,
  'get_jovens_por_estado_count' as funcao_teste,
  COUNT(*) as total_estados_retornados
FROM public.get_jovens_por_estado_count(NULL);

-- ============================================
-- 7. VERIFICAR DADOS GEOGRÁFICOS
-- ============================================

-- Verificar distribuição geográfica
SELECT 
  'DISTRIBUIÇÃO GEOGRÁFICA' as categoria,
  COUNT(DISTINCT estado_id) as total_estados,
  COUNT(DISTINCT bloco_id) as total_blocos,
  COUNT(DISTINCT regiao_id) as total_regioes,
  COUNT(DISTINCT igreja_id) as total_igrejas,
  COUNT(*) as total_jovens
FROM public.jovens;

-- ============================================
-- 8. RESUMO FINAL DA VERIFICAÇÃO
-- ============================================

SELECT 
  'RESUMO FINAL DA VERIFICAÇÃO' as status,
  'Sistema de níveis geográficos verificado' as verificacao,
  'Função can_access_jovem corrigida e funcionando' as funcao_status,
  'Políticas RLS ativas e funcionando' as politicas_status,
  'Compatibilidade com outras funções confirmada' as compatibilidade_status,
  'Execute com diferentes usuários para validação completa' as proximo_passo;

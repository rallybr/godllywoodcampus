-- =====================================================
-- TESTE DA CORREÇÃO DOS NÍVEIS GEOGRÁFICOS
-- =====================================================
-- Este script testa se a correção está funcionando corretamente

-- ============================================
-- 1. VERIFICAR USUÁRIOS COM DIFERENTES NÍVEIS
-- ============================================

-- Listar usuários com seus níveis e dados geográficos
SELECT 
  'USUÁRIOS E SEUS NÍVEIS' as status,
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
  i.nome as igreja_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.nivel IN (
  'lider_estadual_iurd', 'lider_estadual_fju',
  'lider_bloco_iurd', 'lider_bloco_fju',
  'lider_regional_iurd', 'lider_igreja_iurd'
)
ORDER BY u.nivel, u.nome;

-- ============================================
-- 2. TESTAR FUNÇÃO can_access_jovem
-- ============================================

-- Testar com diferentes níveis hierárquicos
-- (Este teste deve ser executado com diferentes usuários logados)

-- Para líder estadual - deve ver jovens do mesmo estado
SELECT 
  'TESTE: Líder Estadual' as teste,
  'Deve ver jovens do mesmo estado' as comportamento_esperado,
  can_access_jovem(
    (SELECT estado_id FROM public.usuarios WHERE nivel = 'lider_estadual_iurd' LIMIT 1),
    NULL, NULL, NULL
  ) as resultado;

-- Para líder de bloco - deve ver jovens do mesmo bloco
SELECT 
  'TESTE: Líder de Bloco' as teste,
  'Deve ver jovens do mesmo bloco' as comportamento_esperado,
  can_access_jovem(
    NULL,
    (SELECT bloco_id FROM public.usuarios WHERE nivel = 'lider_bloco_iurd' LIMIT 1),
    NULL, NULL
  ) as resultado;

-- Para líder regional - deve ver jovens da mesma região
SELECT 
  'TESTE: Líder Regional' as teste,
  'Deve ver jovens da mesma região' as comportamento_esperado,
  can_access_jovem(
    NULL, NULL,
    (SELECT regiao_id FROM public.usuarios WHERE nivel = 'lider_regional_iurd' LIMIT 1),
    NULL
  ) as resultado;

-- Para líder de igreja - deve ver jovens da mesma igreja
SELECT 
  'TESTE: Líder de Igreja' as teste,
  'Deve ver jovens da mesma igreja' as comportamento_esperado,
  can_access_jovem(
    NULL, NULL, NULL,
    (SELECT igreja_id FROM public.usuarios WHERE nivel = 'lider_igreja_iurd' LIMIT 1)
  ) as resultado;

-- ============================================
-- 3. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar se as políticas foram criadas corretamente
SELECT 
  'POLÍTICAS RLS DA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  qual as condicao_using,
  with_check as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 4. TESTAR ACESSO A DADOS
-- ============================================

-- Contar jovens por nível de acesso
-- (Este teste deve ser executado com diferentes usuários logados)

SELECT 
  'TESTE: Contagem de Jovens Acessíveis' as teste,
  COUNT(*) as total_jovens_acessiveis
FROM public.jovens
WHERE can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id);

-- ============================================
-- 5. VERIFICAR DADOS GEOGRÁFICOS
-- ============================================

-- Verificar se existem dados geográficos para testar
SELECT 
  'DADOS GEOGRÁFICOS DISPONÍVEIS' as status,
  COUNT(DISTINCT estado_id) as total_estados,
  COUNT(DISTINCT bloco_id) as total_blocos,
  COUNT(DISTINCT regiao_id) as total_regioes,
  COUNT(DISTINCT igreja_id) as total_igrejas
FROM public.jovens;

-- ============================================
-- 6. RESUMO DOS TESTES
-- ============================================

SELECT 
  'RESUMO DOS TESTES' as status,
  'Execute este script com diferentes usuários logados' as instrucao,
  'Verifique se cada nível vê apenas os dados da sua geografia' as objetivo,
  'Líderes estaduais: devem ver jovens do estado' as teste_estadual,
  'Líderes de bloco: devem ver jovens do bloco' as teste_bloco,
  'Líderes regionais: devem ver jovens da região' as teste_regional,
  'Líderes de igreja: devem ver jovens da igreja' as teste_igreja;

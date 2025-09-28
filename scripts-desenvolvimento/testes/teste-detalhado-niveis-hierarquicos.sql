-- =====================================================
-- TESTE DETALHADO DOS NÍVEIS HIERÁRQUICOS
-- =====================================================
-- Este script testa cada nível hierárquico individualmente

-- ============================================
-- 1. VERIFICAR USUÁRIOS DISPONÍVEIS PARA TESTE
-- ============================================

-- Listar todos os usuários com níveis hierárquicos
SELECT 
  'USUÁRIOS COM NÍVEIS HIERÁRQUICOS' as categoria,
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
  'administrador',
  'lider_nacional_iurd', 'lider_nacional_fju',
  'lider_estadual_iurd', 'lider_estadual_fju',
  'lider_bloco_iurd', 'lider_bloco_fju',
  'lider_regional_iurd', 'lider_igreja_iurd',
  'colaborador', 'jovem'
)
ORDER BY 
  CASE u.nivel
    WHEN 'administrador' THEN 1
    WHEN 'lider_nacional_iurd' THEN 2
    WHEN 'lider_nacional_fju' THEN 2
    WHEN 'lider_estadual_iurd' THEN 3
    WHEN 'lider_estadual_fju' THEN 3
    WHEN 'lider_bloco_iurd' THEN 4
    WHEN 'lider_bloco_fju' THEN 4
    WHEN 'lider_regional_iurd' THEN 5
    WHEN 'lider_igreja_iurd' THEN 6
    WHEN 'colaborador' THEN 7
    WHEN 'jovem' THEN 8
  END,
  u.nome;

-- ============================================
-- 2. TESTAR FUNÇÃO can_access_jovem COM DADOS REAIS
-- ============================================

-- Testar com dados reais de jovens
SELECT 
  'TESTE: Função can_access_jovem com dados reais' as teste,
  j.id as jovem_id,
  j.nome as jovem_nome,
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
LIMIT 10;

-- ============================================
-- 3. CONTAR JOVENS ACESSÍVEIS POR NÍVEL
-- ============================================

-- Contar jovens acessíveis para o usuário atual
SELECT 
  'CONTAGEM DE JOVENS ACESSÍVEIS' as categoria,
  COUNT(*) as total_jovens_acessiveis,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_com_acesso,
  COUNT(CASE WHEN NOT can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_sem_acesso
FROM public.jovens;

-- ============================================
-- 4. TESTAR ACESSO POR NÍVEL HIERÁRQUICO
-- ============================================

-- Testar acesso para cada nível (simulação)
-- NOTA: Para testar completamente, execute este script com diferentes usuários logados

-- Simular teste para líder estadual
SELECT 
  'SIMULAÇÃO: Líder Estadual' as teste,
  'Deve ver jovens do mesmo estado' as comportamento_esperado,
  COUNT(*) as total_jovens_estado,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
WHERE j.estado_id = (
  SELECT estado_id FROM public.usuarios 
  WHERE nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') 
  LIMIT 1
);

-- Simular teste para líder de bloco
SELECT 
  'SIMULAÇÃO: Líder de Bloco' as teste,
  'Deve ver jovens do mesmo bloco' as comportamento_esperado,
  COUNT(*) as total_jovens_bloco,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
WHERE j.bloco_id = (
  SELECT bloco_id FROM public.usuarios 
  WHERE nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') 
  LIMIT 1
);

-- Simular teste para líder regional
SELECT 
  'SIMULAÇÃO: Líder Regional' as teste,
  'Deve ver jovens da mesma região' as comportamento_esperado,
  COUNT(*) as total_jovens_regiao,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
WHERE j.regiao_id = (
  SELECT regiao_id FROM public.usuarios 
  WHERE nivel = 'lider_regional_iurd' 
  LIMIT 1
);

-- Simular teste para líder de igreja
SELECT 
  'SIMULAÇÃO: Líder de Igreja' as teste,
  'Deve ver jovens da mesma igreja' as comportamento_esperado,
  COUNT(*) as total_jovens_igreja,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
WHERE j.igreja_id = (
  SELECT igreja_id FROM public.usuarios 
  WHERE nivel = 'lider_igreja_iurd' 
  LIMIT 1
);

-- ============================================
-- 5. VERIFICAR POLÍTICAS RLS ATIVAS
-- ============================================

-- Verificar políticas RLS da tabela jovens
SELECT 
  'POLÍTICAS RLS ATIVAS' as categoria,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas,
  CASE 
    WHEN qual IS NOT NULL THEN 'Condição USING definida'
    ELSE 'Sem condição USING'
  END as condicao_using,
  CASE 
    WHEN with_check IS NOT NULL THEN 'Condição WITH CHECK definida'
    ELSE 'Sem condição WITH CHECK'
  END as condicao_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 6. VERIFICAR DADOS GEOGRÁFICOS
-- ============================================

-- Verificar distribuição geográfica dos jovens
SELECT 
  'DISTRIBUIÇÃO GEOGRÁFICA DOS JOVENS' as categoria,
  COUNT(DISTINCT estado_id) as total_estados,
  COUNT(DISTINCT bloco_id) as total_blocos,
  COUNT(DISTINCT regiao_id) as total_regioes,
  COUNT(DISTINCT igreja_id) as total_igrejas,
  COUNT(*) as total_jovens
FROM public.jovens;

-- Detalhar por estado
SELECT 
  'JOVENS POR ESTADO' as categoria,
  e.nome as estado_nome,
  COUNT(*) as total_jovens
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
GROUP BY e.nome, j.estado_id
ORDER BY total_jovens DESC;

-- ============================================
-- 7. INSTRUÇÕES PARA TESTE COMPLETO
-- ============================================

SELECT 
  'INSTRUÇÕES PARA TESTE COMPLETO' as categoria,
  '1. Execute este script com um usuário administrador' as passo_1,
  '2. Execute com um líder estadual (iurd ou fju)' as passo_2,
  '3. Execute com um líder de bloco (iurd ou fju)' as passo_3,
  '4. Execute com um líder regional' as passo_4,
  '5. Execute com um líder de igreja' as passo_5,
  '6. Compare os resultados para verificar se cada nível vê apenas sua geografia' as passo_6;

-- ============================================
-- 8. RESUMO FINAL
-- ============================================

SELECT 
  'RESUMO FINAL' as categoria,
  'Sistema corrigido para usar campo nivel da tabela usuarios' as correcao_aplicada,
  'Função can_access_jovem atualizada' as funcao_corrigida,
  'Políticas RLS reorganizadas' as politicas_atualizadas,
  'Teste com diferentes usuários para validar funcionamento' as proximo_passo;

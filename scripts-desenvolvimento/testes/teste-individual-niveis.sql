-- =====================================================
-- TESTE INDIVIDUAL POR NÍVEL HIERÁRQUICO
-- =====================================================
-- Execute este script com diferentes usuários logados para testar cada nível

-- ============================================
-- 1. VERIFICAR USUÁRIO ATUAL
-- ============================================

SELECT 
  'USUÁRIO ATUAL' as categoria,
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
WHERE u.id_auth = auth.uid();

-- ============================================
-- 2. TESTAR ACESSO A JOVENS
-- ============================================

-- Contar jovens acessíveis para o usuário atual
SELECT 
  'JOVENS ACESSÍVEIS PARA O USUÁRIO ATUAL' as categoria,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_com_acesso,
  COUNT(CASE WHEN NOT can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_sem_acesso
FROM public.jovens;

-- ============================================
-- 3. LISTAR JOVENS ACESSÍVEIS
-- ============================================

-- Listar jovens que o usuário atual pode acessar
SELECT 
  'JOVENS QUE O USUÁRIO ATUAL PODE ACESSAR' as categoria,
  j.id,
  j.nome,
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
ORDER BY j.nome
LIMIT 20;

-- ============================================
-- 4. TESTAR FUNÇÃO can_access_jovem
-- ============================================

-- Testar a função com diferentes parâmetros
SELECT 
  'TESTE DA FUNÇÃO can_access_jovem' as categoria,
  'Teste com NULLs' as teste_1,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado_1,
  'Teste com estado do usuário' as teste_2,
  can_access_jovem(
    (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid()),
    NULL, NULL, NULL
  ) as resultado_2;

-- ============================================
-- 5. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar se as políticas RLS estão funcionando
SELECT 
  'VERIFICAÇÃO DAS POLÍTICAS RLS' as categoria,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 6. TESTE ESPECÍFICO POR NÍVEL
-- ============================================

-- Teste específico baseado no nível do usuário atual
SELECT 
  CASE 
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'administrador' 
    THEN 'TESTE: ADMINISTRADOR - Deve ver todos os jovens'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_nacional_iurd', 'lider_nacional_fju')
    THEN 'TESTE: LÍDER NACIONAL - Deve ver todos os jovens'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_estadual_iurd', 'lider_estadual_fju')
    THEN 'TESTE: LÍDER ESTADUAL - Deve ver jovens do estado'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_bloco_iurd', 'lider_bloco_fju')
    THEN 'TESTE: LÍDER DE BLOCO - Deve ver jovens do bloco'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'lider_regional_iurd'
    THEN 'TESTE: LÍDER REGIONAL - Deve ver jovens da região'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'lider_igreja_iurd'
    THEN 'TESTE: LÍDER DE IGREJA - Deve ver jovens da igreja'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'colaborador'
    THEN 'TESTE: COLABORADOR - Deve ver apenas jovens que cadastrou'
    
    WHEN (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'jovem'
    THEN 'TESTE: JOVEM - Deve ver apenas seus próprios dados'
    
    ELSE 'TESTE: NÍVEL DESCONHECIDO'
  END as teste_especifico;

-- ============================================
-- 7. CONTAR JOVENS POR GEOGRAFIA
-- ============================================

-- Contar jovens por estado (para líderes estaduais)
SELECT 
  'JOVENS POR ESTADO' as categoria,
  e.nome as estado_nome,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
GROUP BY e.nome, j.estado_id
ORDER BY total_jovens DESC;

-- Contar jovens por bloco (para líderes de bloco)
SELECT 
  'JOVENS POR BLOCO' as categoria,
  b.nome as bloco_nome,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
GROUP BY b.nome, j.bloco_id
ORDER BY total_jovens DESC;

-- Contar jovens por região (para líderes regionais)
SELECT 
  'JOVENS POR REGIÃO' as categoria,
  r.nome as regiao_nome,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
GROUP BY r.nome, j.regiao_id
ORDER BY total_jovens DESC;

-- Contar jovens por igreja (para líderes de igreja)
SELECT 
  'JOVENS POR IGREJA' as categoria,
  i.nome as igreja_nome,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
GROUP BY i.nome, j.igreja_id
ORDER BY total_jovens DESC;

-- ============================================
-- 8. RESUMO DO TESTE
-- ============================================

SELECT 
  'RESUMO DO TESTE' as categoria,
  'Execute este script com diferentes usuários logados' as instrucao,
  'Verifique se cada nível vê apenas os dados da sua geografia' as objetivo,
  'Compare os resultados entre diferentes níveis' as validacao;

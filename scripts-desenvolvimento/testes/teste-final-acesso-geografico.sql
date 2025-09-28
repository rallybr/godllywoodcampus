-- =====================================================
-- TESTE FINAL DE ACESSO GEOGRÁFICO
-- =====================================================
-- Execute este script para verificar se o acesso geográfico está funcionando

-- ============================================
-- 1. VERIFICAR USUÁRIO ATUAL
-- ============================================

SELECT 
  'USUÁRIO ATUAL - DADOS COMPLETOS' as categoria,
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
-- 2. VERIFICAR PAPÉIS ATRIBUÍDOS
-- ============================================

SELECT 
  'PAPÉIS ATRIBUÍDOS AO USUÁRIO' as categoria,
  ur.id as papel_id,
  r.nome as papel_nome,
  r.slug as papel_slug,
  r.nivel_hierarquico,
  ur.ativo,
  ur.estado_id as papel_estado_id,
  ur.bloco_id as papel_bloco_id,
  ur.regiao_id as papel_regiao_id,
  ur.igreja_id as papel_igreja_id
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  AND ur.ativo = true
ORDER BY r.nivel_hierarquico;

-- ============================================
-- 3. TESTAR FUNÇÃO can_access_jovem
-- ============================================

-- Teste básico da função
SELECT 
  'TESTE DA FUNÇÃO can_access_jovem' as categoria,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado_teste;

-- ============================================
-- 4. CONTAR JOVENS ACESSÍVEIS
-- ============================================

-- Contar jovens que o usuário pode acessar
SELECT 
  'CONTAGEM DE JOVENS ACESSÍVEIS' as categoria,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_com_acesso,
  COUNT(CASE WHEN NOT can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_sem_acesso,
  ROUND(
    (COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) * 100.0 / COUNT(*)), 
    2
  ) as percentual_acesso
FROM public.jovens;

-- ============================================
-- 5. LISTAR JOVENS ACESSÍVEIS
-- ============================================

-- Listar jovens que o usuário pode acessar
SELECT 
  'JOVENS ACESSÍVEIS PARA O USUÁRIO' as categoria,
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
LIMIT 20;

-- ============================================
-- 6. VERIFICAR JOVENS NA GEOGRAFIA ESPECÍFICA
-- ============================================

-- Verificar jovens na geografia do usuário
SELECT 
  'JOVENS NA GEOGRAFIA DO USUÁRIO' as categoria,
  'Estado' as tipo_geografia,
  e.nome as nome_geografia,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
WHERE j.estado_id = (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid())
GROUP BY e.nome, j.estado_id

UNION ALL

SELECT 
  'JOVENS NA GEOGRAFIA DO USUÁRIO' as categoria,
  'Bloco' as tipo_geografia,
  b.nome as nome_geografia,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.blocos b ON b.id = j.bloco_id
WHERE j.bloco_id = (SELECT bloco_id FROM public.usuarios WHERE id_auth = auth.uid())
GROUP BY b.nome, j.bloco_id

UNION ALL

SELECT 
  'JOVENS NA GEOGRAFIA DO USUÁRIO' as categoria,
  'Região' as tipo_geografia,
  r.nome as nome_geografia,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.regioes r ON r.id = j.regiao_id
WHERE j.regiao_id = (SELECT regiao_id FROM public.usuarios WHERE id_auth = auth.uid())
GROUP BY r.nome, j.regiao_id

UNION ALL

SELECT 
  'JOVENS NA GEOGRAFIA DO USUÁRIO' as categoria,
  'Igreja' as tipo_geografia,
  i.nome as nome_geografia,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) THEN 1 END) as jovens_acessiveis
FROM public.jovens j
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.igreja_id = (SELECT igreja_id FROM public.usuarios WHERE id_auth = auth.uid())
GROUP BY i.nome, j.igreja_id;

-- ============================================
-- 7. RESUMO DO TESTE
-- ============================================

SELECT 
  'RESUMO DO TESTE FINAL' as status,
  'Verifique se o usuário vê apenas jovens da sua geografia' as objetivo,
  'Compare os resultados com o nível do usuário' as validacao,
  'Se ainda houver problemas, verifique os dados geográficos' as proximo_passo;

-- =====================================================
-- TESTE DE DADOS GEOGRÁFICOS NO FRONTEND
-- =====================================================

-- 1. VERIFICAR SE OS DADOS GEOGRÁFICOS EXISTEM
-- =====================================================
SELECT 
  'VERIFICAÇÃO DE DADOS GEOGRÁFICOS' as teste,
  COUNT(*) as total_jovens,
  COUNT(estado_id) as com_estado,
  COUNT(bloco_id) as com_bloco,
  COUNT(regiao_id) as com_regiao,
  COUNT(igreja_id) as com_igreja
FROM public.jovens;

-- 2. VERIFICAR DADOS ESPECÍFICOS DE UM JOVEM
-- =====================================================
SELECT 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.nome_completo ILIKE '%RAUL%'
LIMIT 5;

-- 3. VERIFICAR SE AS TABELAS GEOGRÁFICAS TÊM DADOS
-- =====================================================
SELECT 'ESTADOS' as tabela, COUNT(*) as total FROM public.estados
UNION ALL
SELECT 'BLOCOS' as tabela, COUNT(*) as total FROM public.blocos
UNION ALL
SELECT 'REGIÕES' as tabela, COUNT(*) as total FROM public.regioes
UNION ALL
SELECT 'IGREJAS' as tabela, COUNT(*) as total FROM public.igrejas;

-- 4. VERIFICAR RELACIONAMENTOS
-- =====================================================
SELECT 
  'RELACIONAMENTOS' as teste,
  COUNT(CASE WHEN j.estado_id IS NOT NULL AND e.id IS NOT NULL THEN 1 END) as estados_ok,
  COUNT(CASE WHEN j.bloco_id IS NOT NULL AND b.id IS NOT NULL THEN 1 END) as blocos_ok,
  COUNT(CASE WHEN j.regiao_id IS NOT NULL AND r.id IS NOT NULL THEN 1 END) as regioes_ok,
  COUNT(CASE WHEN j.igreja_id IS NOT NULL AND i.id IS NOT NULL THEN 1 END) as igrejas_ok
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id;

-- 5. TESTAR CONSULTA SIMILAR AO FRONTEND
-- =====================================================
SELECT 
  j.id,
  j.nome_completo,
  j.idade,
  j.aprovado,
  jsonb_build_object(
    'nome', e.nome,
    'sigla', e.sigla
  ) as estado,
  jsonb_build_object(
    'nome', b.nome
  ) as bloco,
  jsonb_build_object(
    'nome', r.nome
  ) as regiao,
  jsonb_build_object(
    'nome', i.nome
  ) as igreja
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
WHERE j.nome_completo ILIKE '%RAUL%'
LIMIT 3;

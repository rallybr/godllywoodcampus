-- =====================================================
-- TESTE ESPECÍFICO PARA loadJovemById
-- =====================================================

-- 1. VERIFICAR DADOS DO JOVEM RAUL VICTOR SILVA
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
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 2. TESTAR CONSULTA SIMILAR AO SUPABASE
-- =====================================================
SELECT 
  j.*,
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
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 3. VERIFICAR SE OS IDs EXISTEM NAS TABELAS RELACIONADAS
-- =====================================================
SELECT 'ESTADO' as tipo, COUNT(*) as existe 
FROM public.estados 
WHERE id = 'c20e70c2-92e6-4c50-96a5-177822095a25'
UNION ALL
SELECT 'BLOCO' as tipo, COUNT(*) as existe 
FROM public.blocos 
WHERE id = 'b5a36062-9c86-5ce7-a277-bad68a7fa0d4'
UNION ALL
SELECT 'REGIÃO' as tipo, COUNT(*) as existe 
FROM public.regioes 
WHERE id = '6561c5a8-5685-57c8-b397-f002e810c4e1'
UNION ALL
SELECT 'IGREJA' as tipo, COUNT(*) as existe 
FROM public.igrejas 
WHERE id = '54d4f183-0627-5d79-8070-7c725380575d';

-- =====================================================
-- TESTE: Verificar se a função can_access_jovem_com_associacoes foi criada
-- =====================================================

-- 1. Verificar se a função existe
SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('can_access_jovem_com_associacoes', 'aprovar_jovem_multiplo')
ORDER BY routine_name;

-- 2. Testar a função diretamente (substitua os UUIDs pelos valores reais)
-- SELECT public.can_access_jovem_com_associacoes(
--   'ef6f4033-edb9-5ccb-9f4e-2350200a00ce'::uuid,  -- jovem_estado_id
--   '4fe2a911-82db-58c1-8f19-442b55d3eb39'::uuid,  -- jovem_bloco_id
--   '241fd058-a4e5-58ad-b504-d9b21fb8b53f'::uuid,  -- jovem_regiao_id
--   '46ea9b8d-a2cc-5471-ae97-b65cc8cefbca'::uuid,  -- jovem_igreja_id
--   '21687a5c-b59b-4cf4-8256-c7fb5d0c4884'::uuid   -- jovem_id
-- );

-- 3. Verificar se há conflito de nomes
SELECT 
  routine_name,
  COUNT(*) as count
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%can_access_jovem%'
GROUP BY routine_name;

-- 4. Verificar a definição da função atual
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'can_access_jovem_com_associacoes';

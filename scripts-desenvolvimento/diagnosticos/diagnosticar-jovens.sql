-- DIAGNOSTICAR ONDE ESTÃO OS JOVENS
-- Este script verifica onde estão os 30 jovens

-- 1. Verificar todos os estados e quantos jovens cada um tem
SELECT 
    'Jovens por estado:' as info,
    e.nome as estado,
    e.id as estado_id,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
ORDER BY total_jovens DESC
LIMIT 10;

-- 2. Verificar o estado específico do Roberto
SELECT 
    'Estado do Roberto:' as info,
    e.nome as estado,
    e.id as estado_id,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
WHERE e.id = 'b41b7f2b-4a26-481b-91d7-8ebc20a2c6bd'
GROUP BY e.id, e.nome;

-- 3. Verificar se há jovens sem estado_id
SELECT 
    'Jovens sem estado:' as info,
    COUNT(*) as total
FROM public.jovens 
WHERE estado_id IS NULL;

-- 4. Verificar se há jovens com estado_id diferente
SELECT 
    'Jovens com outros estados:' as info,
    COUNT(*) as total
FROM public.jovens 
WHERE estado_id IS NOT NULL 
  AND estado_id != 'b41b7f2b-4a26-481b-91d7-8ebc20a2c6bd';

-- 5. Verificar se o problema é na tabela estados
SELECT 
    'Estado do Roberto na tabela estados:' as info,
    e.nome as estado,
    e.id as estado_id
FROM public.estados e
WHERE e.id = 'b41b7f2b-4a26-481b-91d7-8ebc20a2c6bd';

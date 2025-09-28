-- VERIFICAR JOVENS DE SÃO PAULO
-- Este script verifica se há jovens do estado de São Paulo

-- 1. Verificar jovens do estado de São Paulo
SELECT 
    'Jovens de São Paulo:' as info,
    COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = 'b41b7f2b-4a26-481b-91d7-8ebc20a2c6bd';

-- 2. Verificar se há jovens sem estado_id
SELECT 
    'Jovens sem estado:' as info,
    COUNT(*) as total
FROM public.jovens 
WHERE estado_id IS NULL;

-- 3. Verificar todos os estados e quantos jovens cada um tem
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

-- 4. Verificar se o problema é na tabela jovens
SELECT 
    'Jovens na tabela jovens:' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN estado_id IS NULL THEN 1 END) as sem_estado,
    COUNT(CASE WHEN estado_id IS NOT NULL THEN 1 END) as com_estado
FROM public.jovens;

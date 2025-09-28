-- TESTE FINAL SIMPLES
-- Este script testa se a função está funcionando com Roberto Guerra

-- 1. Verificar Roberto Guerra
SELECT 
    'Roberto Guerra:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    e.nome as estado
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
WHERE u.id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 2. Verificar jovens do estado do Roberto
SELECT 
    'Jovens do estado do Roberto:' as info,
    COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.estado_id = 'b41b7f2b-4a26-481b-91d7-8ebc20a2c6bd';

-- 3. Testar a função
SELECT 
    'Teste da função:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL);

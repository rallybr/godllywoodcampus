-- Verificar a definição da função RPC
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_jovens_por_estado_count'
AND routine_schema = 'public';

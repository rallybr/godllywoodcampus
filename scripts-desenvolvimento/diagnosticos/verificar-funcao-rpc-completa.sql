-- Verificar a definição completa da função RPC
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_jovens_por_estado_count'
AND routine_schema = 'public';

-- Verificar se a função tem o parâmetro correto
SELECT 
    parameter_name,
    parameter_mode,
    data_type
FROM information_schema.parameters 
WHERE specific_name = (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'get_jovens_por_estado_count'
    AND routine_schema = 'public'
);

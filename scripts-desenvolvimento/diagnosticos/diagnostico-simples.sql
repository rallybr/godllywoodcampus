-- DIAGNÓSTICO SIMPLES
-- Execute este script para identificar o problema

-- 1. Verificar se está autenticado
SELECT 
    'Usuário autenticado:' as info,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NÃO'
        ELSE 'SIM - ID: ' || auth.uid()
    END as resultado;

-- 2. Verificar usuário na tabela
SELECT 
    'Usuário na tabela:' as info,
    u.nome,
    u.nivel,
    CASE 
        WHEN u.id IS NULL THEN 'NÃO ENCONTRADO'
        ELSE 'ENCONTRADO'
    END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. Verificar dados do usuário
SELECT 
    'Dados do usuário:' as info,
    COUNT(j.id) as total_jovens
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 4. Testar a função
SELECT 
    'Teste da função:' as info,
    COUNT(*) as total_estados
FROM public.get_jovens_por_estado_count(NULL);
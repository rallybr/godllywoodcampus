-- DIAGNOSTICAR PROBLEMA DA HIERARQUIA
-- Este script vai identificar exatamente o que está acontecendo

-- 1. Verificar se há usuário autenticado
SELECT 
    'Usuário autenticado:' as status,
    auth.uid() as auth_id,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NÃO AUTENTICADO'
        ELSE 'AUTENTICADO'
    END as resultado;

-- 2. Verificar se o usuário existe na tabela usuarios
SELECT 
    'Usuário na tabela:' as status,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    CASE 
        WHEN u.id IS NULL THEN 'USUÁRIO NÃO ENCONTRADO'
        ELSE 'USUÁRIO ENCONTRADO'
    END as resultado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. Verificar total de jovens na base
SELECT 
    'Total de jovens:' as info,
    COUNT(*) as total
FROM public.jovens;

-- 4. Verificar jovens por estado
SELECT 
    'Jovens por estado:' as info,
    e.nome as estado,
    COUNT(j.id) as total
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total DESC
LIMIT 5;

-- 5. Verificar se há jovens com usuario_id (para colaborador/jovem)
SELECT 
    'Jovens com usuario_id:' as info,
    COUNT(*) as total
FROM public.jovens 
WHERE usuario_id IS NOT NULL;

-- 6. Testar a função diretamente com debug
SELECT 
    'Teste direto da função:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 3;

-- TESTAR HIERARQUIA CORRIGIDA
-- Este script testa se a hierarquia está funcionando corretamente

-- 1. Verificar usuário atual
SELECT 
    'Usuário atual:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. Verificar se há dados para o usuário atual
SELECT 
    'Dados do usuário atual:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 3. Testar a função corrigida
SELECT 
    'Teste da função corrigida:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;

-- 4. Verificar se o problema é de nível
SELECT 
    'Nível do usuário:' as info,
    u.nivel,
    CASE 
        WHEN u.nivel = 'jovem' THEN '❌ Jovem não deveria ver este card'
        WHEN u.nivel = 'colaborador' AND COUNT(j.id) = 0 THEN '❌ Colaborador sem jovens'
        WHEN u.nivel = 'colaborador' AND COUNT(j.id) > 0 THEN '✅ Colaborador com jovens'
        WHEN u.nivel = 'administrador' THEN '✅ Administrador vê tudo'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN '✅ Líder estadual vê seu estado'
        WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN '✅ Líder de bloco vê seu bloco'
        WHEN u.nivel = 'lider_regional_iurd' THEN '✅ Líder regional vê sua região'
        WHEN u.nivel = 'lider_igreja_iurd' THEN '✅ Líder de igreja vê sua igreja'
        ELSE '❓ Nível: ' || u.nivel
    END as comportamento_esperado
FROM public.usuarios u
LEFT JOIN public.jovens j ON j.usuario_id = u.id
WHERE u.id_auth = auth.uid()
GROUP BY u.id, u.nome, u.nivel;

-- VERIFICAR NÍVEL DO USUÁRIO
-- Este script verifica se o problema é o nível do usuário

-- 1. Verificar nível do usuário atual
SELECT 
    'Nível do usuário atual:' as info,
    u.nome,
    u.nivel,
    CASE 
        WHEN u.nivel = 'jovem' THEN '❌ JOVEM - Não deveria ver este card'
        WHEN u.nivel = 'colaborador' THEN '✅ COLABORADOR - Deveria ver apenas seus jovens'
        WHEN u.nivel = 'administrador' THEN '✅ ADMINISTRADOR - Deveria ver todos'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN '✅ LÍDER ESTADUAL - Deveria ver seu estado'
        WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN '✅ LÍDER DE BLOCO - Deveria ver seu bloco'
        WHEN u.nivel = 'lider_regional_iurd' THEN '✅ LÍDER REGIONAL - Deveria ver sua região'
        WHEN u.nivel = 'lider_igreja_iurd' THEN '✅ LÍDER DE IGREJA - Deveria ver sua igreja'
        ELSE '❓ NÍVEL DESCONHECIDO: ' || u.nivel
    END as comportamento_esperado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. Verificar se o usuário tem dados
SELECT 
    'Dados do usuário atual:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 3. Verificar se o card deveria aparecer para este nível
SELECT 
    'Card deveria aparecer?' as info,
    CASE 
        WHEN u.nivel = 'jovem' THEN '❌ NÃO - Jovem não deveria ver este card'
        WHEN u.nivel = 'colaborador' AND COUNT(j.id) = 0 THEN '❌ NÃO - Colaborador sem jovens'
        WHEN u.nivel = 'colaborador' AND COUNT(j.id) > 0 THEN '✅ SIM - Colaborador com jovens'
        WHEN u.nivel = 'administrador' THEN '✅ SIM - Administrador vê tudo'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN '✅ SIM - Líder estadual vê seu estado'
        WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN '✅ SIM - Líder de bloco vê seu bloco'
        WHEN u.nivel = 'lider_regional_iurd' THEN '✅ SIM - Líder regional vê sua região'
        WHEN u.nivel = 'lider_igreja_iurd' THEN '✅ SIM - Líder de igreja vê sua igreja'
        ELSE '❓ DESCONHECIDO'
    END as resultado
FROM public.usuarios u
LEFT JOIN public.jovens j ON j.usuario_id = u.id
WHERE u.id_auth = auth.uid()
GROUP BY u.id, u.nome, u.nivel;
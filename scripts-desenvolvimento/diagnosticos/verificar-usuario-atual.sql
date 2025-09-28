-- VERIFICAR USUÁRIO ATUAL
-- Este script verifica os dados geográficos do usuário atual

-- 1. Verificar usuário atual
SELECT 
    'Usuário atual:' as info,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    CASE 
        WHEN u.estado_id IS NULL THEN '❌ SEM ESTADO'
        WHEN u.bloco_id IS NULL THEN '❌ SEM BLOCO'
        WHEN u.regiao_id IS NULL THEN '❌ SEM REGIÃO'
        WHEN u.igreja_id IS NULL THEN '❌ SEM IGREJA'
        ELSE '✅ DADOS COMPLETOS'
    END as status_geografico
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. Verificar se o usuário tem dados geográficos
SELECT 
    'Dados geográficos do usuário:' as info,
    e.nome as estado,
    b.nome as bloco,
    r.nome as regiao,
    i.nome as igreja
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.id_auth = auth.uid();

-- 3. Verificar se há jovens para o usuário atual
SELECT 
    'Jovens para o usuário atual:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 4. Verificar se o problema é de nível
SELECT 
    'Nível do usuário:' as info,
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

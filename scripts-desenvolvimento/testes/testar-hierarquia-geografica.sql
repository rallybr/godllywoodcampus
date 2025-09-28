-- TESTAR HIERARQUIA GEOGRÁFICA
-- Este script testa se a hierarquia geográfica está funcionando

-- 1. Verificar usuário atual e seus dados geográficos
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

-- 2. Verificar se há dados geográficos para o usuário atual
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

-- 3. Verificar jovens baseados na hierarquia geográfica
SELECT 
    'Jovens baseados na hierarquia:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE (
    -- Líder estadual: jovens do seu estado
    (j.estado_id = (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_estadual_iurd', 'lider_estadual_fju'))
    OR
    -- Líder de bloco: jovens do seu bloco
    (j.bloco_id = (SELECT bloco_id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_bloco_iurd', 'lider_bloco_fju'))
    OR
    -- Líder regional: jovens da sua região
    (j.regiao_id = (SELECT regiao_id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'lider_regional_iurd')
    OR
    -- Líder de igreja: jovens da sua igreja
    (j.igreja_id = (SELECT igreja_id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'lider_igreja_iurd')
    OR
    -- Colaborador: jovens que cadastrou
    (j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'colaborador')
    OR
    -- Jovem: seus próprios dados
    (j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid()) 
     AND (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'jovem')
    OR
    -- Administrador: todos os jovens
    ((SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'administrador')
    OR
    -- Líder nacional: todos os jovens
    ((SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN ('lider_nacional_iurd', 'lider_nacional_fju'))
);

-- 4. Testar a função corrigida
SELECT 
    'Teste da função corrigida:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;

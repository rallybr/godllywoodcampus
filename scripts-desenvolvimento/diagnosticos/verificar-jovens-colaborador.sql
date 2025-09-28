-- Script para verificar quais jovens o colaborador deveria ver
-- Execute no SQL Editor do Supabase

-- 1. Verificar o usuário atual e seus dados
SELECT 
    'USUÁRIO ATUAL' as tipo,
    u.id,
    u.nome,
    u.email,
    u.nivel,
    u.estado_id,
    e.nome as estado_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON u.estado_id = e.id
WHERE u.id_auth = auth.uid();

-- 2. Verificar TODOS os jovens no sistema
SELECT 
    'TODOS OS JOVENS' as tipo,
    COUNT(*) as total,
    'Jovens no sistema' as descricao
FROM public.jovens;

-- 3. Verificar jovens cadastrados pelo usuário atual
SELECT 
    'JOVENS DO USUÁRIO ATUAL' as tipo,
    COUNT(*) as total,
    'Jovens cadastrados pelo usuário' as descricao
FROM public.jovens j
WHERE j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());

-- 4. Verificar jovens do mesmo estado do usuário
SELECT 
    'JOVENS DO MESMO ESTADO' as tipo,
    COUNT(*) as total,
    'Jovens do mesmo estado' as descricao
FROM public.jovens j
WHERE j.estado_id = (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid());

-- 5. Listar detalhes dos jovens cadastrados pelo usuário atual
SELECT 
    'DETALHES DOS JOVENS DO USUÁRIO' as tipo,
    j.id,
    j.nome_completo,
    j.usuario_id,
    j.estado_id,
    e.nome as estado_nome,
    e.sigla as estado_sigla
FROM public.jovens j
LEFT JOIN public.estados e ON j.estado_id = e.id
WHERE j.usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY j.nome_completo;

-- 6. Listar detalhes dos jovens do mesmo estado (para comparação)
SELECT 
    'DETALHES DOS JOVENS DO ESTADO' as tipo,
    j.id,
    j.nome_completo,
    j.usuario_id,
    j.estado_id,
    e.nome as estado_nome,
    e.sigla as estado_sigla,
    u.nome as cadastrado_por
FROM public.jovens j
LEFT JOIN public.estados e ON j.estado_id = e.id
LEFT JOIN public.usuarios u ON j.usuario_id = u.id
WHERE j.estado_id = (SELECT estado_id FROM public.usuarios WHERE id_auth = auth.uid())
ORDER BY j.nome_completo;

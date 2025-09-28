-- Script para testar níveis superiores ao colaborador
-- Execute no SQL Editor do Supabase

-- 1. Verificar usuários com níveis superiores
SELECT 
    u.id,
    u.nome,
    u.email,
    u.nivel,
    u.ativo,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    e.nome as estado_nome,
    b.nome as bloco_nome,
    r.nome as regiao_nome,
    i.nome as igreja_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON u.estado_id = e.id
LEFT JOIN public.blocos b ON u.bloco_id = b.id
LEFT JOIN public.regioes r ON u.regiao_id = r.id
LEFT JOIN public.igrejas i ON u.igreja_id = i.id
WHERE u.nivel IN ('lider_estadual', 'lider_bloco', 'lider_regional', 'lider_igreja', 'lider_nacional', 'administrador')
ORDER BY 
    CASE u.nivel 
        WHEN 'administrador' THEN 1
        WHEN 'lider_nacional' THEN 2
        WHEN 'lider_estadual' THEN 3
        WHEN 'lider_bloco' THEN 4
        WHEN 'lider_regional' THEN 5
        WHEN 'lider_igreja' THEN 6
        ELSE 7
    END;

-- 2. Verificar quantos jovens cada nível deveria ver
SELECT 
    'Total de jovens no sistema' as descricao,
    COUNT(*) as total
FROM public.jovens
UNION ALL
SELECT 
    'Jovens por estado (exemplo: SP)' as descricao,
    COUNT(*) as total
FROM public.jovens j
JOIN public.estados e ON j.estado_id = e.id
WHERE e.sigla = 'SP'
UNION ALL
SELECT 
    'Jovens por bloco (exemplo: primeiro bloco)' as descricao,
    COUNT(*) as total
FROM public.jovens j
JOIN public.blocos b ON j.bloco_id = b.id
WHERE b.id = (SELECT id FROM public.blocos LIMIT 1)
UNION ALL
SELECT 
    'Jovens por região (exemplo: primeira região)' as descricao,
    COUNT(*) as total
FROM public.jovens j
JOIN public.regioes r ON j.regiao_id = r.id
WHERE r.id = (SELECT id FROM public.regioes LIMIT 1)
UNION ALL
SELECT 
    'Jovens por igreja (exemplo: primeira igreja)' as descricao,
    COUNT(*) as total
FROM public.jovens j
JOIN public.igrejas i ON j.igreja_id = i.id
WHERE i.id = (SELECT id FROM public.igrejas LIMIT 1);

-- 3. Testar função can_access_jovem para diferentes níveis
-- (Execute como usuário com nível superior)
SELECT 
    'Teste de acesso para jovem específico' as teste,
    can_access_jovem(
        (SELECT estado_id FROM public.jovens LIMIT 1),
        (SELECT bloco_id FROM public.jovens LIMIT 1),
        (SELECT regiao_id FROM public.jovens LIMIT 1),
        (SELECT igreja_id FROM public.jovens LIMIT 1)
    ) as tem_acesso;

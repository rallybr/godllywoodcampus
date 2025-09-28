-- TESTAR DIFERENTES NÍVEIS DE USUÁRIO
-- Este script simula diferentes níveis para testar a hierarquia

-- 1. Verificar todos os usuários e seus níveis
SELECT 
    'Usuários disponíveis:' as info,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.nivel IN (
    'administrador',
    'lider_nacional_iurd', 'lider_nacional_fju',
    'lider_estadual_iurd', 'lider_estadual_fju',
    'lider_bloco_iurd', 'lider_bloco_fju',
    'lider_regional_iurd', 'lider_igreja_iurd',
    'colaborador', 'jovem'
)
ORDER BY u.nivel, u.nome;

-- 2. Verificar se há dados de teste
SELECT 
    'Dados de teste:' as info,
    'Estados' as tipo,
    COUNT(*) as total
FROM public.estados
UNION ALL
SELECT 
    'Dados de teste:' as info,
    'Jovens' as tipo,
    COUNT(*) as total
FROM public.jovens
UNION ALL
SELECT 
    'Dados de teste:' as info,
    'Usuários' as tipo,
    COUNT(*) as total
FROM public.usuarios;

-- 3. Verificar se há jovens associados a usuários
SELECT 
    'Jovens por usuário:' as info,
    u.nome as usuario,
    u.nivel,
    COUNT(j.id) as total_jovens
FROM public.usuarios u
LEFT JOIN public.jovens j ON j.usuario_id = u.id
WHERE u.nivel IN ('colaborador', 'jovem')
GROUP BY u.id, u.nome, u.nivel
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC;

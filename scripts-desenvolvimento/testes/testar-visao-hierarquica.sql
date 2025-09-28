-- TESTAR VISÃO HIERÁRQUICA
-- Verificar se a função está funcionando corretamente

-- 1. Verificar usuários e seus níveis
SELECT 
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.nivel IN (
    'lider_estadual_iurd', 'lider_estadual_fju',
    'lider_bloco_iurd', 'lider_bloco_fju',
    'lider_regional_iurd', 'lider_igreja_iurd',
    'colaborador', 'jovem'
)
ORDER BY u.nivel, u.nome;

-- 2. Testar a função hierárquica (como administrador)
SELECT 'Teste - Função Hierárquica' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count_hierarquico(NULL);

-- 3. Verificar jovens por estado para entender a distribuição
SELECT 
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
ORDER BY total_jovens DESC
LIMIT 10;

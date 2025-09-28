-- TESTAR HIERARQUIA IMPLEMENTADA
-- Verificar se a função está funcionando corretamente para diferentes níveis

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
    'administrador',
    'lider_nacional_iurd', 'lider_nacional_fju',
    'lider_estadual_iurd', 'lider_estadual_fju',
    'lider_bloco_iurd', 'lider_bloco_fju',
    'lider_regional_iurd', 'lider_igreja_iurd',
    'colaborador', 'jovem'
)
ORDER BY u.nivel, u.nome;

-- 2. Testar a função (como administrador)
SELECT 'Teste - Função Hierárquica' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count(NULL);

-- 3. Verificar distribuição de jovens por estado
SELECT 
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC
LIMIT 10;

-- 4. Verificar se há jovens associados a usuários (colaborador/jovem)
SELECT 
    'Jovens com usuario_id' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE usuario_id IS NOT NULL;

SELECT 
    'Jovens sem usuario_id' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE usuario_id IS NULL;

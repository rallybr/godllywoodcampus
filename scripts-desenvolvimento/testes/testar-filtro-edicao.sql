-- Testar a função RPC com diferentes parâmetros de edição

-- 1. Sem filtro (todas as edições)
SELECT 'Todas as edições' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count(NULL);

-- 2. Com edição específica (3ª Edição - ativa)
SELECT '3ª Edição' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count('27717445-8ad1-4c7a-ad1d-55621011f7b4');

-- 3. Verificar quantos jovens existem por edição
SELECT 
    e.nome as edicao,
    COUNT(j.id) as total_jovens
FROM public.edicoes e
LEFT JOIN public.jovens j ON j.edicao_id = e.id
GROUP BY e.id, e.nome, e.ativa
ORDER BY e.ativa DESC, e.numero DESC;

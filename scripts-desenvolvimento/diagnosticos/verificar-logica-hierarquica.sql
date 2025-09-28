-- VERIFICAR LÓGICA HIERÁRQUICA
-- Analisar se a implementação está correta

-- 1. Verificar estrutura de dados geográficos
SELECT 'ESTADOS' as tipo, COUNT(*) as total FROM public.estados;
SELECT 'BLOCOS' as tipo, COUNT(*) as total FROM public.blocos;
SELECT 'REGIÕES' as tipo, COUNT(*) as total FROM public.regioes;
SELECT 'IGREJAS' as tipo, COUNT(*) as total FROM public.igrejas;

-- 2. Verificar jovens e suas localizações
SELECT 
    'Jovens com estado' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE estado_id IS NOT NULL;

SELECT 
    'Jovens com bloco' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE bloco_id IS NOT NULL;

SELECT 
    'Jovens com região' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE regiao_id IS NOT NULL;

SELECT 
    'Jovens com igreja' as tipo,
    COUNT(*) as total
FROM public.jovens 
WHERE igreja_id IS NOT NULL;

-- 3. Verificar distribuição de jovens por estado
SELECT 
    e.nome as estado,
    COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON j.estado_id = e.id
GROUP BY e.id, e.nome
HAVING COUNT(j.id) > 0
ORDER BY total_jovens DESC;

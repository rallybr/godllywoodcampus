-- CORRIGIR DADOS GEOGRÁFICOS DO USUÁRIO ATUAL
-- Este script corrige os dados geográficos do usuário atual

-- 1. Verificar usuário atual antes da correção
SELECT 
    'ANTES DA CORREÇÃO:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. Atualizar dados geográficos do usuário atual
-- Vamos usar dados de exemplo baseados nos dados que vimos
UPDATE public.usuarios 
SET 
    estado_id = (SELECT id FROM public.estados WHERE nome = 'São Paulo' LIMIT 1),
    bloco_id = (SELECT id FROM public.blocos WHERE nome = 'Templo de Salomao' LIMIT 1),
    regiao_id = (SELECT id FROM public.regioes WHERE nome = 'Templo de Salomao' LIMIT 1),
    igreja_id = (SELECT id FROM public.igrejas WHERE nome = 'Templo de Salomão' LIMIT 1)
WHERE id_auth = auth.uid();

-- 3. Verificar usuário atual após a correção
SELECT 
    'APÓS A CORREÇÃO:' as info,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
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

-- 4. Testar a função após a correção
SELECT 
    'Teste da função após correção:' as info,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;

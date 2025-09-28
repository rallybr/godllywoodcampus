-- VERIFICAR PROBLEMA DE AUTENTICAÇÃO
-- Este script vai identificar se o problema é de autenticação

-- 1. Verificar se há usuário autenticado
SELECT 
    'Status de autenticação:' as info,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NÃO AUTENTICADO'
        ELSE '✅ AUTENTICADO - ID: ' || auth.uid()
    END as status;

-- 2. Verificar se o usuário autenticado existe na tabela
SELECT 
    'Usuário autenticado na tabela:' as info,
    CASE 
        WHEN u.id IS NULL THEN '❌ USUÁRIO NÃO ENCONTRADO NA TABELA'
        ELSE '✅ USUÁRIO ENCONTRADO: ' || u.nome || ' (Nível: ' || u.nivel || ')'
    END as status,
    u.id,
    u.nome,
    u.nivel
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 3. Verificar se o problema é de nível
SELECT 
    'Nível do usuário atual:' as info,
    u.nivel,
    CASE 
        WHEN u.nivel = 'administrador' THEN '✅ Deveria ver todos os estados'
        WHEN u.nivel = 'colaborador' THEN '✅ Deveria ver apenas seus jovens'
        WHEN u.nivel = 'jovem' THEN '✅ Deveria ver apenas seus dados'
        WHEN u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN '✅ Deveria ver apenas seu estado'
        WHEN u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN '✅ Deveria ver apenas seu bloco'
        WHEN u.nivel = 'lider_regional_iurd' THEN '✅ Deveria ver apenas sua região'
        WHEN u.nivel = 'lider_igreja_iurd' THEN '✅ Deveria ver apenas sua igreja'
        ELSE '❓ Nível não reconhecido: ' || u.nivel
    END as comportamento_esperado
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 4. Verificar se há dados para o usuário atual
SELECT 
    'Dados disponíveis para usuário atual:' as info,
    COUNT(j.id) as total_jovens,
    COUNT(DISTINCT j.estado_id) as estados_diferentes
FROM public.jovens j
WHERE j.usuario_id = (
    SELECT id FROM public.usuarios WHERE id_auth = auth.uid()
);

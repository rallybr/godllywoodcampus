-- TESTAR HIERARQUIA SIMPLES
-- Execute este script para verificar se a função está funcionando

-- 1. Verificar se a função existe e está atualizada
SELECT 
    'Função existe:' as status,
    COUNT(*) as total
FROM pg_proc 
WHERE proname = 'get_jovens_por_estado_count' 
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 2. Testar a função (deve retornar dados baseados no usuário atual)
SELECT 
    'Teste da função:' as teste,
    estado_id,
    total
FROM public.get_jovens_por_estado_count(NULL)
LIMIT 5;

-- 3. Verificar usuário atual
SELECT 
    'Usuário atual:' as info,
    u.id,
    u.nome,
    u.nivel,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

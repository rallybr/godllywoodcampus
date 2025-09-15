-- =====================================================
-- VERIFICAR USUÁRIO PARA AVALIAÇÕES
-- =====================================================

-- 1. Verificar usuários cadastrados
SELECT 
    id,
    id_auth,
    nome,
    email,
    ativo,
    CASE 
        WHEN id_auth IS NOT NULL THEN 'OK: Tem id_auth'
        ELSE 'PROBLEMA: id_auth NULL'
    END as status_auth
FROM usuarios
ORDER BY criado_em DESC;

-- 2. Verificar se há relação entre auth.users e usuarios
-- (Execute este comando no Supabase SQL Editor para ver o auth.uid atual)
SELECT 
    'Auth UID atual' as tipo,
    auth.uid() as valor
UNION ALL
SELECT 
    'Usuários na tabela' as tipo,
    COUNT(*)::text as valor
FROM usuarios;

-- 3. Verificar se o usuário atual tem id_auth preenchido
SELECT 
    u.id,
    u.nome,
    u.id_auth,
    CASE 
        WHEN u.id_auth IS NOT NULL THEN 'OK'
        ELSE 'PROBLEMA: Precisa atualizar id_auth'
    END as status
FROM usuarios u
WHERE u.ativo = true;

-- 4. Verificar permissões RLS na tabela usuarios
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'usuarios';

-- 5. Testar query que o modal está usando
-- (Substitua 'SEU_AUTH_UID_AQUI' pelo auth.uid real)
-- SELECT id, nome, id_auth
-- FROM usuarios 
-- WHERE id_auth = 'SEU_AUTH_UID_AQUI';

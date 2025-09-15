-- =====================================================
-- TESTAR QUERY USUARIOS COM ID_AUTH
-- =====================================================

-- Testar a query exata que o modal está fazendo
SELECT 
    id, 
    nome, 
    id_auth
FROM usuarios 
WHERE id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1';

-- Verificar se existe algum problema com a query
SELECT 
    id, 
    nome, 
    id_auth,
    CASE 
        WHEN id_auth = '4075ce47-aea6-4fca-92fc-305e5af6bdf1' THEN 'MATCH'
        ELSE 'NO MATCH'
    END as match_status
FROM usuarios;

-- Verificar se há problemas de RLS
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

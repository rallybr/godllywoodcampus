-- =====================================================
-- VERIFICAR RELAÇÃO ENTRE AUTH.UID E USUARIOS.ID
-- =====================================================

-- Verificar dados da tabela usuarios
SELECT 
    id,
    id_auth,
    nome,
    email,
    nivel
FROM usuarios;

-- Verificar se existe relação entre auth.uid e usuarios.id_auth
-- (O campo id_auth deve conter o auth.uid do Supabase)
SELECT 
    id,
    id_auth,
    nome,
    CASE 
        WHEN id_auth IS NOT NULL THEN 'Tem id_auth'
        ELSE 'Sem id_auth'
    END as status
FROM usuarios;

-- Script para atualizar manualmente o último acesso dos usuários

-- 1. Atualizar último acesso para todos os usuários ativos
UPDATE public.usuarios 
SET ultimo_acesso = NOW() 
WHERE ativo = true;

-- 2. Verificar quantos usuários foram atualizados
SELECT 
    COUNT(*) as usuarios_atualizados,
    MIN(ultimo_acesso) as primeiro_acesso,
    MAX(ultimo_acesso) as ultimo_acesso
FROM public.usuarios 
WHERE ultimo_acesso IS NOT NULL;

-- 3. Verificar usuários que ainda não têm último acesso
SELECT 
    id,
    nome,
    email,
    nivel,
    ativo,
    ultimo_acesso
FROM public.usuarios 
WHERE ultimo_acesso IS NULL
ORDER BY nome;

-- 4. Atualizar último acesso para um usuário específico (substitua o ID)
-- UPDATE public.usuarios 
-- SET ultimo_acesso = NOW() 
-- WHERE id = 'SEU_ID_AQUI';

-- 5. Verificar estatísticas de acesso
SELECT 
    COUNT(*) as total_usuarios,
    COUNT(ultimo_acesso) as usuarios_com_acesso,
    COUNT(*) - COUNT(ultimo_acesso) as usuarios_sem_acesso,
    AVG(EXTRACT(EPOCH FROM (NOW() - ultimo_acesso))/86400) as dias_medio_sem_acesso
FROM public.usuarios;

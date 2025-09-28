-- Script para testar se a função RPC está funcionando
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a coluna foto existe
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
AND table_schema = 'public'
AND column_name = 'foto';

-- 2. Testar a função RPC
SELECT id, nome, foto, ultimo_acesso 
FROM public.buscar_usuarios_com_ultimo_acesso() 
LIMIT 1;

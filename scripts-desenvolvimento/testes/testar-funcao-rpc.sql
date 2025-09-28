-- Script para testar a função RPC
-- Execute este script no Supabase SQL Editor

-- 1. Verificar se a função existe
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'buscar_usuarios_com_ultimo_acesso' 
AND routine_schema = 'public';

-- 2. Testar a função
SELECT * FROM public.buscar_usuarios_com_ultimo_acesso() LIMIT 1;
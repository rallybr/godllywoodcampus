-- Script para debug das políticas RLS da tabela dados_nucleo
-- Execute este script no SQL Editor do Supabase

-- 1. Verificar o usuário atual e seus dados
SELECT 
  u.id,
  u.id_auth,
  u.nivel,
  u.nome,
  auth.uid() as current_auth_uid
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Verificar se existe jovem com esse ID
SELECT 
  j.id as jovem_id,
  j.usuario_id,
  j.nome_completo
FROM jovens j 
WHERE j.usuario_id = (
  SELECT u.id FROM usuarios u WHERE u.id_auth = auth.uid()
);

-- 3. Testar a condição da política manualmente
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM usuarios u 
      WHERE u.id_auth = auth.uid() 
      AND u.nivel = 'jovem' 
      AND u.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid
    ) THEN 'POLICY SHOULD ALLOW'
    ELSE 'POLICY WILL BLOCK'
  END as policy_test;

-- 4. Verificar se o usuário tem nível jovem
SELECT 
  u.id,
  u.nivel,
  CASE 
    WHEN u.nivel = 'jovem' THEN 'IS JOVEM'
    ELSE 'NOT JOVEM'
  END as nivel_check
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 5. Verificar se o ID do usuário corresponde ao jovem_id
SELECT 
  u.id as user_id,
  'e745720c-e9f7-4562-978b-72ba32387420'::uuid as jovem_id,
  CASE 
    WHEN u.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid THEN 'IDS MATCH'
    ELSE 'IDS DO NOT MATCH'
  END as id_comparison
FROM usuarios u 
WHERE u.id_auth = auth.uid();

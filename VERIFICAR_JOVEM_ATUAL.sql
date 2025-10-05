-- Script para verificar e corrigir o jovem atual
-- Execute este script no SQL Editor do Supabase

-- 1. Verificar o usuário atual
SELECT 
  u.id as user_id,
  u.nivel,
  u.nome,
  auth.uid() as current_auth_uid
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Verificar se existe jovem com o ID atual
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.id = '3fcb8e6b-b6db-4d10-8929-cd084ff89133'::uuid;

-- 3. Verificar se existe jovem associado ao usuário atual
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.usuario_id = (
  SELECT u.id FROM usuarios u WHERE u.id_auth = auth.uid()
);

-- 4. Se não existir jovem, vamos criar um para o usuário atual
INSERT INTO public.jovens (
  id,
  nome_completo,
  usuario_id,
  data_cadastro,
  data_nasc,
  edicao
) VALUES (
  '3fcb8e6b-b6db-4d10-8929-cd084ff89133'::uuid,
  'Jovem de Teste - Usuário Atual',
  (SELECT u.id FROM usuarios u WHERE u.id_auth = auth.uid()),
  NOW(),
  '1990-01-01'::date,
  'Teste'
) ON CONFLICT (id) DO NOTHING;

-- 5. Verificar se o jovem foi criado
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM jovens j 
WHERE j.id = '3fcb8e6b-b6db-4d10-8929-cd084ff89133'::uuid;

-- 6. Verificar se já existe dados do núcleo para este jovem
SELECT 
  id,
  jovem_id,
  faz_nucleo,
  ha_quanto_tempo,
  media_pessoas,
  criado_em
FROM public.dados_nucleo 
WHERE jovem_id = '3fcb8e6b-b6db-4d10-8929-cd084ff89133'::uuid;

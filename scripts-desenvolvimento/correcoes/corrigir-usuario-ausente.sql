-- =====================================================
-- CORREÇÃO DO USUÁRIO AUSENTE NA TABELA usuarios
-- =====================================================
-- Este script corrige o problema do usuário não existir na tabela usuarios

-- 1. VERIFICAR USUÁRIO ATUAL NO SUPABASE AUTH
SELECT 
  'USUÁRIO NO SUPABASE AUTH' as diagnostico,
  auth.uid() as user_id_auth,
  auth.email() as user_email,
  auth.role() as user_role;

-- 2. VERIFICAR SE O USUÁRIO EXISTE NA TABELA usuarios
SELECT 
  'VERIFICAÇÃO NA TABELA usuarios' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO EXISTE NA TABELA'
    ELSE '❌ USUÁRIO NÃO EXISTE NA TABELA'
  END as resultado;

-- 3. CRIAR USUÁRIO NA TABELA usuarios SE NÃO EXISTIR
INSERT INTO public.usuarios (
  id,
  id_auth,
  email,
  nome,
  nivel,
  criado_em,
  ativo
)
SELECT 
  uuid_generate_v4(),
  auth.uid(),
  auth.email(),
  COALESCE(auth.email()::text, 'Usuário'),
  'jovem',
  NOW(),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 4. VERIFICAR SE O USUÁRIO FOI CRIADO
SELECT 
  'VERIFICAÇÃO APÓS CRIAÇÃO' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO CRIADO COM SUCESSO'
    ELSE '❌ FALHA AO CRIAR USUÁRIO'
  END as resultado;

-- 5. MOSTRAR DADOS DO USUÁRIO CRIADO
SELECT 
  'DADOS DO USUÁRIO CRIADO' as diagnostico,
  id,
  id_auth,
  email,
  nome,
  nivel,
  criado_em,
  ativo
FROM public.usuarios 
WHERE id_auth = auth.uid();

-- 6. VERIFICAR SE O USUÁRIO TEM PAPÉIS
SELECT 
  'VERIFICAÇÃO DE PAPÉIS' as diagnostico,
  COUNT(*) as total_papeis,
  COUNT(CASE WHEN ur.ativo = true THEN 1 END) as papeis_ativos
FROM public.user_roles ur
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid();

-- 7. SE O USUÁRIO NÃO TEM PAPÉIS, CRIAR PAPEL DE JOVEM
INSERT INTO public.user_roles (
  id,
  user_id,
  role_id,
  ativo,
  criado_em,
  criado_por
)
SELECT 
  uuid_generate_v4(),
  u.id,
  r.id,
  true,
  NOW(),
  u.id
FROM public.usuarios u
CROSS JOIN public.roles r
WHERE u.id_auth = auth.uid()
  AND r.slug = 'jovem'
  AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur2
    WHERE ur2.user_id = u.id
      AND ur2.role_id = r.id
      AND ur2.ativo = true
  );

-- 8. VERIFICAR SE O PAPEL FOI CRIADO
SELECT 
  'VERIFICAÇÃO DE PAPEL CRIADO' as diagnostico,
  r.slug,
  r.nome,
  r.nivel_hierarquico,
  ur.ativo
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
  AND ur.ativo = true;

-- 9. TESTAR FUNCTION can_access_jovem APÓS CORREÇÃO
SELECT 
  'TESTE can_access_jovem APÓS CORREÇÃO' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 10. TESTAR FUNCTION can_access_viagem_by_level APÓS CORREÇÃO
SELECT 
  'TESTE can_access_viagem_by_level APÓS CORREÇÃO' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- 11. VERIFICAR SE O USUÁRIO AGORA TEM ACESSO
SELECT 
  'VERIFICAÇÃO FINAL DE ACESSO' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ USUÁRIO AGORA TEM ACESSO'
    ELSE '❌ USUÁRIO AINDA NÃO TEM ACESSO'
  END as resultado;

-- =====================================================
-- FIM DA CORREÇÃO
-- =====================================================

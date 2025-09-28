-- =====================================================
-- CORREÇÃO FINAL DO USUÁRIO AUSENTE
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

-- 3. MOSTRAR USUÁRIOS EXISTENTES NA TABELA
SELECT 
  'USUÁRIOS EXISTENTES NA TABELA' as diagnostico,
  id,
  id_auth,
  nome,
  email,
  nivel,
  ativo
FROM public.usuarios 
ORDER BY criado_em DESC
LIMIT 5;

-- 4. CRIAR USUÁRIO NA TABELA usuarios SE NÃO EXISTIR
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
  COALESCE(auth.email(), 'usuario@exemplo.com'),
  COALESCE(auth.email()::text, 'Usuário'),
  'jovem',
  NOW(),
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()
);

-- 5. VERIFICAR SE O USUÁRIO FOI CRIADO
SELECT 
  'VERIFICAÇÃO APÓS CRIAÇÃO' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO CRIADO COM SUCESSO'
    ELSE '❌ FALHA AO CRIAR USUÁRIO'
  END as resultado;

-- 6. MOSTRAR DADOS DO USUÁRIO CRIADO
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

-- 7. ATRIBUIR PAPEL DE LÍDER NACIONAL IURD AO USUÁRIO
UPDATE public.usuarios 
SET nivel = 'lider_nacional_iurd'
WHERE id_auth = auth.uid()
  AND nivel = 'jovem';

-- 8. VERIFICAR SE O PAPEL FOI ATRIBUÍDO
SELECT 
  'VERIFICAÇÃO PAPEL ATRIBUÍDO' as diagnostico,
  CASE 
    WHEN u.nivel = 'lider_nacional_iurd' THEN '✅ PAPEL DE LÍDER NACIONAL IURD ATRIBUÍDO'
    ELSE '❌ FALHA AO ATRIBUIR PAPEL DE LÍDER NACIONAL IURD'
  END as resultado,
  u.nivel as nivel_atual
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 9. MOSTRAR DADOS FINAIS DO USUÁRIO
SELECT 
  'DADOS FINAIS DO USUÁRIO' as diagnostico,
  id,
  id_auth,
  email,
  nome,
  nivel,
  criado_em,
  ativo
FROM public.usuarios 
WHERE id_auth = auth.uid();

-- 10. TESTAR FUNCTION can_access_jovem APÓS CORREÇÃO
SELECT 
  'TESTE can_access_jovem APÓS CORREÇÃO' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 11. TESTAR FUNCTION can_access_viagem_by_level APÓS CORREÇÃO
SELECT 
  'TESTE can_access_viagem_by_level APÓS CORREÇÃO' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- 12. VERIFICAÇÃO FINAL DE ACESSO
SELECT 
  'VERIFICAÇÃO FINAL DE ACESSO' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDER NACIONAL AGORA TEM ACESSO TOTAL'
    ELSE '❌ LÍDER NACIONAL AINDA NÃO TEM ACESSO TOTAL'
  END as resultado;

-- =====================================================
-- FIM DA CORREÇÃO FINAL
-- =====================================================

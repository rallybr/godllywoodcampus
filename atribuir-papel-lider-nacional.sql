-- =====================================================
-- ATRIBUIR PAPEL DE LÍDER NACIONAL AO USUÁRIO
-- =====================================================
-- Este script atribui o papel de líder nacional ao usuário atual

-- 1. VERIFICAR USUÁRIO ATUAL
SELECT 
  'USUÁRIO ATUAL' as diagnostico,
  auth.uid() as user_id_auth,
  u.id as user_id,
  u.nome,
  u.email
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- 2. VERIFICAR PAPÉIS ATUAIS DO USUÁRIO
SELECT 
  'PAPÉIS ATUAIS' as diagnostico,
  r.slug,
  r.nome,
  r.nivel_hierarquico,
  ur.ativo
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
ORDER BY r.nivel_hierarquico ASC;

-- 3. VERIFICAR SE O USUÁRIO JÁ TEM PAPEL DE LÍDER NACIONAL
SELECT 
  'VERIFICAÇÃO LÍDER NACIONAL' as diagnostico,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND r.slug IN ('lider_nacional_iurd', 'lider_nacional_fju')
        AND ur.ativo = true
    ) THEN '✅ USUÁRIO JÁ É LÍDER NACIONAL'
    ELSE '❌ USUÁRIO NÃO É LÍDER NACIONAL'
  END as resultado;

-- 4. ATRIBUIR PAPEL DE LÍDER NACIONAL IURD
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
  AND r.slug = 'lider_nacional_iurd'
  AND NOT EXISTS (
    SELECT 1 FROM public.user_roles ur2
    WHERE ur2.user_id = u.id
      AND ur2.role_id = r.id
      AND ur2.ativo = true
  );

-- 5. VERIFICAR SE O PAPEL FOI ATRIBUÍDO
SELECT 
  'VERIFICAÇÃO PAPEL ATRIBUÍDO' as diagnostico,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      JOIN public.usuarios u ON u.id = ur.user_id
      WHERE u.id_auth = auth.uid()
        AND r.slug = 'lider_nacional_iurd'
        AND ur.ativo = true
    ) THEN '✅ PAPEL DE LÍDER NACIONAL IURD ATRIBUÍDO'
    ELSE '❌ FALHA AO ATRIBUIR PAPEL DE LÍDER NACIONAL IURD'
  END as resultado;

-- 6. MOSTRAR PAPÉIS ATUAIS DO USUÁRIO
SELECT 
  'PAPÉIS ATUAIS APÓS ATRIBUIÇÃO' as diagnostico,
  r.slug,
  r.nome,
  r.nivel_hierarquico,
  ur.ativo,
  ur.criado_em
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
ORDER BY r.nivel_hierarquico ASC;

-- 7. VERIFICAR NÍVEL HIERÁRQUICO MÍNIMO
SELECT 
  'NÍVEL HIERÁRQUICO MÍNIMO' as diagnostico,
  MIN(r.nivel_hierarquico) as nivel_minimo,
  CASE 
    WHEN MIN(r.nivel_hierarquico) = 1 THEN 'Administrador'
    WHEN MIN(r.nivel_hierarquico) = 2 THEN 'Líder Nacional'
    WHEN MIN(r.nivel_hierarquico) = 3 THEN 'Líder Estadual'
    WHEN MIN(r.nivel_hierarquico) = 4 THEN 'Líder de Bloco'
    WHEN MIN(r.nivel_hierarquico) = 5 THEN 'Líder Regional'
    WHEN MIN(r.nivel_hierarquico) = 6 THEN 'Líder de Igreja'
    WHEN MIN(r.nivel_hierarquico) = 7 THEN 'Colaborador'
    WHEN MIN(r.nivel_hierarquico) = 8 THEN 'Jovem'
    ELSE 'Nível não definido'
  END as descricao_nivel
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
JOIN public.usuarios u ON u.id = ur.user_id
WHERE u.id_auth = auth.uid()
  AND ur.ativo = true;

-- 8. TESTAR FUNCTION can_access_jovem
SELECT 
  'TESTE can_access_jovem' as diagnostico,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado;

-- 9. TESTAR FUNCTION can_access_viagem_by_level
SELECT 
  'TESTE can_access_viagem_by_level' as diagnostico,
  can_access_viagem_by_level(NULL, NULL, NULL, NULL) as resultado;

-- 10. VERIFICAÇÃO FINAL DE ACESSO
SELECT 
  'VERIFICAÇÃO FINAL DE ACESSO' as diagnostico,
  CASE 
    WHEN can_access_jovem(NULL, NULL, NULL, NULL) = true
     AND can_access_viagem_by_level(NULL, NULL, NULL, NULL) = true
    THEN '✅ LÍDER NACIONAL AGORA TEM ACESSO TOTAL'
    ELSE '❌ LÍDER NACIONAL AINDA NÃO TEM ACESSO TOTAL'
  END as resultado;

-- =====================================================
-- FIM DA ATRIBUIÇÃO
-- =====================================================

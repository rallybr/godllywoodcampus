-- =====================================================
-- SCRIPT PARA POPULAR NÍVEIS HIERÁRQUICOS
-- =====================================================
-- Este script garante que todos os papéis tenham os níveis hierárquicos corretos

-- 1. ATUALIZAR NÍVEIS HIERÁRQUICOS NA TABELA ROLES
-- Garantir que os níveis estejam corretos conforme a hierarquia definida

-- Nível 1: Administrador (acesso total)
UPDATE public.roles 
SET nivel_hierarquico = 1 
WHERE slug = 'administrador';

-- Nível 2: Líderes Nacionais (acesso total como administrador)
UPDATE public.roles 
SET nivel_hierarquico = 2 
WHERE slug IN ('lider_nacional_iurd', 'lider_nacional_fju');

-- Nível 3: Líderes Estaduais (visão estadual)
UPDATE public.roles 
SET nivel_hierarquico = 3 
WHERE slug IN ('lider_estadual_iurd', 'lider_estadual_fju');

-- Nível 4: Líderes de Bloco (visão de bloco)
UPDATE public.roles 
SET nivel_hierarquico = 4 
WHERE slug IN ('lider_bloco_iurd', 'lider_bloco_fju');

-- Nível 5: Líder Regional (visão regional)
UPDATE public.roles 
SET nivel_hierarquico = 5 
WHERE slug = 'lider_regional_iurd';

-- Nível 6: Líder de Igreja (visão de igreja)
UPDATE public.roles 
SET nivel_hierarquico = 6 
WHERE slug = 'lider_igreja_iurd';

-- Nível 7: Colaborador (visão do que criou)
UPDATE public.roles 
SET nivel_hierarquico = 7 
WHERE slug = 'colaborador';

-- Nível 8: Jovem (visão própria)
UPDATE public.roles 
SET nivel_hierarquico = 8 
WHERE slug = 'jovem';

-- 2. VERIFICAR SE TODOS OS PAPÉIS FORAM ATUALIZADOS
SELECT 
  slug,
  nome,
  nivel_hierarquico,
  CASE 
    WHEN nivel_hierarquico = 1 THEN 'Administrador (Acesso Total)'
    WHEN nivel_hierarquico = 2 THEN 'Líder Nacional (Acesso Total)'
    WHEN nivel_hierarquico = 3 THEN 'Líder Estadual (Visão Estadual)'
    WHEN nivel_hierarquico = 4 THEN 'Líder de Bloco (Visão de Bloco)'
    WHEN nivel_hierarquico = 5 THEN 'Líder Regional (Visão Regional)'
    WHEN nivel_hierarquico = 6 THEN 'Líder de Igreja (Visão de Igreja)'
    WHEN nivel_hierarquico = 7 THEN 'Colaborador (Visão do que Criou)'
    WHEN nivel_hierarquico = 8 THEN 'Jovem (Visão Própria)'
    ELSE 'Nível não definido'
  END as descricao_nivel
FROM public.roles 
ORDER BY nivel_hierarquico ASC;

-- 3. CRIAR PAPÉIS SE NÃO EXISTIREM
-- (Execute apenas se necessário)

-- Administrador
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'administrador',
  'Administrador',
  'Acesso total ao sistema',
  1,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'administrador');

-- Líder Nacional IURD
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_nacional_iurd',
  'Líder Nacional IURD',
  'Acesso total - todos os dados do sistema',
  2,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_nacional_iurd');

-- Líder Nacional FJU
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_nacional_fju',
  'Líder Nacional FJU',
  'Acesso total - todos os dados do sistema',
  2,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_nacional_fju');

-- Líder Estadual IURD
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_estadual_iurd',
  'Líder Estadual IURD',
  'Visão estadual - todos os dados do estado',
  3,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_estadual_iurd');

-- Líder Estadual FJU
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_estadual_fju',
  'Líder Estadual FJU',
  'Visão estadual - todos os dados do estado',
  3,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_estadual_fju');

-- Líder de Bloco IURD
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_bloco_iurd',
  'Líder de Bloco IURD',
  'Visão de bloco - todos os dados do bloco',
  4,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_bloco_iurd');

-- Líder de Bloco FJU
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_bloco_fju',
  'Líder de Bloco FJU',
  'Visão de bloco - todos os dados do bloco',
  4,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_bloco_fju');

-- Líder Regional IURD
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_regional_iurd',
  'Líder Regional IURD',
  'Visão regional - todos os dados da região',
  5,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_regional_iurd');

-- Líder de Igreja IURD
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'lider_igreja_iurd',
  'Líder de Igreja IURD',
  'Visão de igreja - todos os dados da igreja',
  6,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_igreja_iurd');

-- Colaborador
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'colaborador',
  'Colaborador',
  'Visão do que criou - jovens e dados relacionados',
  7,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'colaborador');

-- Jovem
INSERT INTO public.roles (id, slug, nome, descricao, nivel_hierarquico, criado_em)
SELECT 
  uuid_generate_v4(),
  'jovem',
  'Jovem',
  'Visão própria - apenas seus próprios dados',
  8,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'jovem');

-- 4. VERIFICAR RESULTADO FINAL
SELECT 
  'RESULTADO FINAL' as status,
  COUNT(*) as total_papeis,
  COUNT(CASE WHEN nivel_hierarquico IS NOT NULL THEN 1 END) as papeis_com_nivel,
  COUNT(CASE WHEN nivel_hierarquico IS NULL THEN 1 END) as papeis_sem_nivel
FROM public.roles;

-- 5. LISTAR TODOS OS PAPÉIS COM SEUS NÍVEIS
SELECT 
  nivel_hierarquico,
  slug,
  nome,
  descricao
FROM public.roles 
ORDER BY nivel_hierarquico ASC, nome ASC;

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================

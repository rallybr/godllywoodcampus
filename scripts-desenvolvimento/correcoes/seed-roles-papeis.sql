-- =====================================================
-- SEED DOS PAPÉIS DO SISTEMA (tabela public.roles)
-- =====================================================
-- IMPORTANTE: backup_roles.sql contém roles do PostgreSQL (login),
-- NÃO os papéis da aplicação. Este script popula public.roles.
--
-- Execute no SQL Editor do Supabase se o dropdown "Papel" estiver vazio.

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '11111111-1111-1111-1111-111111111111', 'Administrador', 'administrador', 1, 'Acesso total ao sistema'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'administrador');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '22222222-2222-2222-2222-222222222222', 'Líder Nacional IURD', 'lider_nacional_iurd', 2, 'Líder nacional da IURD'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_nacional_iurd');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '33333333-3333-3333-3333-333333333333', 'Líder Nacional FJU', 'lider_nacional_fju', 2, 'Líder nacional da FJU'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_nacional_fju');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '44444444-4444-4444-4444-444444444444', 'Líder Estadual IURD', 'lider_estadual_iurd', 3, 'Líder estadual da IURD'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_estadual_iurd');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '55555555-5555-5555-5555-555555555555', 'Líder Estadual FJU', 'lider_estadual_fju', 3, 'Líder estadual da FJU'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_estadual_fju');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '66666666-6666-6666-6666-666666666666', 'Líder de Bloco IURD', 'lider_bloco_iurd', 4, 'Líder de bloco da IURD'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_bloco_iurd');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '77777777-7777-7777-7777-777777777777', 'Líder de Bloco FJU', 'lider_bloco_fju', 4, 'Líder de bloco da FJU'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_bloco_fju');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '88888888-8888-8888-8888-888888888888', 'Líder Regional IURD', 'lider_regional_iurd', 5, 'Líder regional da IURD'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_regional_iurd');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT '99999999-9999-9999-9999-999999999999', 'Líder de Igreja IURD', 'lider_igreja_iurd', 6, 'Líder de igreja da IURD'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'lider_igreja_iurd');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Colaborador', 'colaborador', 7, 'Colaborador do sistema'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'colaborador');

INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao)
SELECT 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Jovem', 'jovem', 8, 'Jovem cadastrado'
WHERE NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'jovem');

-- Verificação
SELECT id, nome, slug, nivel_hierarquico
FROM public.roles
ORDER BY nivel_hierarquico, nome;

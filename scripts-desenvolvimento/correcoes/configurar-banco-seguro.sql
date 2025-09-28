-- =====================================================
-- CONFIGURAÇÃO SEGURA DO BANCO (SEM DUPLICATAS)
-- =====================================================

-- 1. PRIMEIRO: DESABILITAR RLS TEMPORARIAMENTE
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria DISABLE ROW LEVEL SECURITY;

-- 2. CRIAR ROLES (PAPÉIS) DO SISTEMA - APENAS SE NÃO EXISTIREM
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

-- 3. CRIAR USUÁRIO ADMINISTRADOR - APENAS SE NÃO EXISTIR
INSERT INTO public.usuarios (id, nome, email, nivel, id_auth, ativo) 
SELECT 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', 'Bp. Roberto Guerra - Admin', 'roberto@admin.com', 'administrador', '346d397f-1a05-4e17-8bed-f94274b78fe0', true
WHERE NOT EXISTS (SELECT 1 FROM public.usuarios WHERE id = 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde');

-- 4. ATRIBUIR PAPEL DE ADMINISTRADOR - APENAS SE NÃO EXISTIR
INSERT INTO public.user_roles (id, user_id, role_id, ativo) 
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', '11111111-1111-1111-1111-111111111111', true
WHERE NOT EXISTS (SELECT 1 FROM public.user_roles WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc');

-- 5. CRIAR EDIÇÃO - APENAS SE NÃO EXISTIR
INSERT INTO public.edicoes (id, nome, numero, data_inicio, data_fim, ativa) 
SELECT 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Intellimen Campus 2024', 1, '2024-01-01', '2024-12-31', true
WHERE NOT EXISTS (SELECT 1 FROM public.edicoes WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd');

-- 6. CRIAR DADOS GEOGRÁFICOS - APENAS SE NÃO EXISTIREM
-- Estados
INSERT INTO public.estados (id, nome, sigla, bandeira) 
SELECT 'c20e70c2-92e6-4c50-96a5-177822095a25', 'São Paulo', 'SP', 'https://example.com/sp.png'
WHERE NOT EXISTS (SELECT 1 FROM public.estados WHERE id = 'c20e70c2-92e6-4c50-96a5-177822095a25');

INSERT INTO public.estados (id, nome, sigla, bandeira) 
SELECT 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Rio de Janeiro', 'RJ', 'https://example.com/rj.png'
WHERE NOT EXISTS (SELECT 1 FROM public.estados WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');

INSERT INTO public.estados (id, nome, sigla, bandeira) 
SELECT 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Minas Gerais', 'MG', 'https://example.com/mg.png'
WHERE NOT EXISTS (SELECT 1 FROM public.estados WHERE id = 'ffffffff-ffff-ffff-ffff-ffffffffffff');

-- Blocos
INSERT INTO public.blocos (id, nome, estado_id) 
SELECT '3a7786e2-46b8-5b33-810e-e267dc619be3', 'Santo André', 'c20e70c2-92e6-4c50-96a5-177822095a25'
WHERE NOT EXISTS (SELECT 1 FROM public.blocos WHERE id = '3a7786e2-46b8-5b33-810e-e267dc619be3');

INSERT INTO public.blocos (id, nome, estado_id) 
SELECT 'gggggggg-gggg-gggg-gggg-gggggggggggg', 'São Paulo Capital', 'c20e70c2-92e6-4c50-96a5-177822095a25'
WHERE NOT EXISTS (SELECT 1 FROM public.blocos WHERE id = 'gggggggg-gggg-gggg-gggg-gggggggggggg');

INSERT INTO public.blocos (id, nome, estado_id) 
SELECT 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'Rio de Janeiro Capital', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
WHERE NOT EXISTS (SELECT 1 FROM public.blocos WHERE id = 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh');

-- Regiões
INSERT INTO public.regioes (id, nome, bloco_id) 
SELECT '84cff91c-3afa-49da-b211-24f50f7cb2ab', 'Brás', '3a7786e2-46b8-5b33-810e-e267dc619be3'
WHERE NOT EXISTS (SELECT 1 FROM public.regioes WHERE id = '84cff91c-3afa-49da-b211-24f50f7cb2ab');

INSERT INTO public.regioes (id, nome, bloco_id) 
SELECT 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'Centro', 'gggggggg-gggg-gggg-gggg-gggggggggggg'
WHERE NOT EXISTS (SELECT 1 FROM public.regioes WHERE id = 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii');

INSERT INTO public.regioes (id, nome, bloco_id) 
SELECT 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'Copacabana', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh'
WHERE NOT EXISTS (SELECT 1 FROM public.regioes WHERE id = 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj');

-- Igrejas
INSERT INTO public.igrejas (id, nome, endereco, regiao_id) 
SELECT '6af2451e-bbc8-52dd-ba31-3dfcb0aada94', 'Casa Grande', 'Rua Casa Grande, 123', '84cff91c-3afa-49da-b211-24f50f7cb2ab'
WHERE NOT EXISTS (SELECT 1 FROM public.igrejas WHERE id = '6af2451e-bbc8-52dd-ba31-3dfcb0aada94');

INSERT INTO public.igrejas (id, nome, endereco, regiao_id) 
SELECT 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', 'Cidade Líder', 'Rua Cidade Líder, 456', 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii'
WHERE NOT EXISTS (SELECT 1 FROM public.igrejas WHERE id = 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk');

INSERT INTO public.igrejas (id, nome, endereco, regiao_id) 
SELECT 'llllllll-llll-llll-llll-llllllllllll', 'Dutra', 'Rua Dutra, 789', 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj'
WHERE NOT EXISTS (SELECT 1 FROM public.igrejas WHERE id = 'llllllll-llll-llll-llll-llllllllllll');

-- 7. CRIAR JOVENS DE TESTE - APENAS SE NÃO EXISTIREM
INSERT INTO public.jovens (
  id, nome_completo, idade, sexo, whatsapp, data_nasc, 
  estado_id, bloco_id, regiao_id, igreja_id, edicao_id, edicao,
  usuario_id, aprovado
) 
SELECT '0e1bc378-2cd2-476b-9551-d11d444bf499', 'RAUL VICTOR SILVA', 25, 'masculino', '(16) 99387-1637', '1999-01-15',
 'c20e70c2-92e6-4c50-96a5-177822095a25', '3a7786e2-46b8-5b33-810e-e267dc619be3', 
 '84cff91c-3afa-49da-b211-24f50f7cb2ab', '6af2451e-bbc8-52dd-ba31-3dfcb0aada94',
 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Intellimen Campus 2024',
 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', 'aprovado'
WHERE NOT EXISTS (SELECT 1 FROM public.jovens WHERE id = '0e1bc378-2cd2-476b-9551-d11d444bf499');

INSERT INTO public.jovens (
  id, nome_completo, idade, sexo, whatsapp, data_nasc, 
  estado_id, bloco_id, regiao_id, igreja_id, edicao_id, edicao,
  usuario_id, aprovado
) 
SELECT 'mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm', 'MARIA SILVA SANTOS', 22, 'feminino', '(11) 98765-4321', '2002-03-20',
 'c20e70c2-92e6-4c50-96a5-177822095a25', 'gggggggg-gggg-gggg-gggg-gggggggggggg',
 'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk',
 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Intellimen Campus 2024',
 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', 'pre_aprovado'
WHERE NOT EXISTS (SELECT 1 FROM public.jovens WHERE id = 'mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm');

INSERT INTO public.jovens (
  id, nome_completo, idade, sexo, whatsapp, data_nasc, 
  estado_id, bloco_id, regiao_id, igreja_id, edicao_id, edicao,
  usuario_id, aprovado
) 
SELECT 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', 'JOÃO PEDRO OLIVEIRA', 24, 'masculino', '(21) 99876-5432', '2000-07-10',
 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh',
 'jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'llllllll-llll-llll-llll-llllllllllll',
 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Intellimen Campus 2024',
 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', null
WHERE NOT EXISTS (SELECT 1 FROM public.jovens WHERE id = 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn');

-- 8. REABILITAR RLS
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dados_viagem ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs_auditoria ENABLE ROW LEVEL SECURITY;

-- 9. VERIFICAR DADOS INSERIDOS
SELECT 'Estados' as tabela, COUNT(*) as total FROM public.estados
UNION ALL
SELECT 'Blocos' as tabela, COUNT(*) as total FROM public.blocos
UNION ALL
SELECT 'Regiões' as tabela, COUNT(*) as total FROM public.regioes
UNION ALL
SELECT 'Igrejas' as tabela, COUNT(*) as total FROM public.igrejas
UNION ALL
SELECT 'Jovens' as tabela, COUNT(*) as total FROM public.jovens
UNION ALL
SELECT 'Usuários' as tabela, COUNT(*) as total FROM public.usuarios
UNION ALL
SELECT 'Roles' as tabela, COUNT(*) as total FROM public.roles
UNION ALL
SELECT 'User Roles' as tabela, COUNT(*) as total FROM public.user_roles
UNION ALL
SELECT 'Edições' as tabela, COUNT(*) as total FROM public.edicoes;

-- 10. TESTAR CONSULTA COM JOINs
SELECT 
  j.nome_completo,
  e.nome as estado,
  b.nome as bloco,
  r.nome as regiao,
  i.nome as igreja,
  ed.nome as edicao
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
LEFT JOIN public.edicoes ed ON ed.id = j.edicao_id
ORDER BY j.nome_completo;

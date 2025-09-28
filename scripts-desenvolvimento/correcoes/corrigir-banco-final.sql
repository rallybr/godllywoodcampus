-- =====================================================
-- CORRIGIR BANCO COM DADOS REAIS EXISTENTES
-- =====================================================

-- 1. DESABILITAR RLS TEMPORARIAMENTE
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;

-- 2. CRIAR ROLES ESSENCIAIS
INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao) 
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Administrador', 'administrador', 1, 'Acesso total ao sistema'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Colaborador', 'colaborador', 7, 'Colaborador do sistema'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Jovem', 'jovem', 8, 'Jovem cadastrado')
ON CONFLICT (slug) DO NOTHING;

-- 3. CRIAR USUÁRIO ADMINISTRADOR
INSERT INTO public.usuarios (id, nome, email, nivel, id_auth, ativo) 
VALUES ('f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', 'Bp. Roberto Guerra - Admin', 'roberto@admin.com', 'administrador', '346d397f-1a05-4e17-8bed-f94274b78fe0', true)
ON CONFLICT (email) DO NOTHING;

-- 4. ATRIBUIR PAPEL DE ADMINISTRADOR
INSERT INTO public.user_roles (id, user_id, role_id, ativo) 
VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'f2b0d1aa-92b9-4eb7-aa27-0ff9865ffbde', '11111111-1111-1111-1111-111111111111', true)
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 5. CRIAR EDIÇÕES
INSERT INTO public.edicoes (id, nome, numero, data_inicio, data_fim, ativa) 
VALUES 
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', '1ª Edição IntelliMen Campus', 1, '2024-01-01', '2024-12-31', true),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '2ª Edição IntelliMen Campus', 2, '2025-01-01', '2025-12-31', true)
ON CONFLICT (numero) DO NOTHING;

-- 6. EXTRAIR E INSERIR DADOS GEOGRÁFICOS DOS JOVENS EXISTENTES
-- Estados únicos dos jovens
INSERT INTO public.estados (id, nome, sigla, bandeira)
SELECT DISTINCT 
    j.estado_id,
    'Estado ' || j.estado_id::text,
    'ST',
    'bandeira_default.png'
FROM public.jovens j 
WHERE j.estado_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- Blocos únicos dos jovens
INSERT INTO public.blocos (id, nome, estado_id)
SELECT DISTINCT 
    j.bloco_id,
    'Bloco ' || j.bloco_id::text,
    j.estado_id
FROM public.jovens j 
WHERE j.bloco_id IS NOT NULL AND j.estado_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- Regiões únicas dos jovens
INSERT INTO public.regioes (id, nome, bloco_id)
SELECT DISTINCT 
    j.regiao_id,
    'Região ' || j.regiao_id::text,
    j.bloco_id
FROM public.jovens j 
WHERE j.regiao_id IS NOT NULL AND j.bloco_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- Igrejas únicas dos jovens
INSERT INTO public.igrejas (id, nome, endereco, regiao_id)
SELECT DISTINCT 
    j.igreja_id,
    'Igreja ' || j.igreja_id::text,
    'Endereço não informado',
    j.regiao_id
FROM public.jovens j 
WHERE j.igreja_id IS NOT NULL AND j.regiao_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- 7. ATUALIZAR DADOS GEOGRÁFICOS COM NOMES REAIS (baseado nos dados fornecidos)
-- São Paulo
UPDATE public.estados SET nome = 'São Paulo', sigla = 'SP' WHERE id = 'c20e70c2-92e6-4c50-96a5-177822095a25';
-- Bahia  
UPDATE public.estados SET nome = 'Bahia', sigla = 'BA' WHERE id = 'f42ed937-3133-5ac6-a006-854f70e978bb';
-- Minas Gerais
UPDATE public.estados SET nome = 'Minas Gerais', sigla = 'MG' WHERE id = '3373645f-f666-5b4e-a0b0-3556f45a0cc2';
-- Amazonas
UPDATE public.estados SET nome = 'Amazonas', sigla = 'AM' WHERE id = '64a56955-0e5f-5a48-a85f-689e57dc7aeb';
-- Paraná
UPDATE public.estados SET nome = 'Paraná', sigla = 'PR' WHERE id = 'b5b2d5a8-affe-58bd-b172-bff2f6618b1c';
-- Rio de Janeiro
UPDATE public.estados SET nome = 'Rio de Janeiro', sigla = 'RJ' WHERE id = '7e391556-c53e-5215-9d4a-3a0367c149ca';
-- Distrito Federal
UPDATE public.estados SET nome = 'Distrito Federal', sigla = 'DF' WHERE id = 'd61033d3-3b25-5f70-a403-281be2753545';
-- Mato Grosso do Sul
UPDATE public.estados SET nome = 'Mato Grosso do Sul', sigla = 'MS' WHERE id = '5253409d-d1b5-54ff-aff4-47306e240a3b';
-- Pará
UPDATE public.estados SET nome = 'Pará', sigla = 'PA' WHERE id = 'a51e504e-3cb9-5ba1-855b-fd4e82764e9a';
-- Pernambuco
UPDATE public.estados SET nome = 'Pernambuco', sigla = 'PE' WHERE id = '0f922947-675b-5f2b-8dfc-bcc180ccb86d';
-- Goiás
UPDATE public.estados SET nome = 'Goiás', sigla = 'GO' WHERE id = '1b995236-af64-5a3d-b555-62f48d64524c';

-- 8. REABILITAR RLS
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes ENABLE ROW LEVEL SECURITY;

-- 9. VERIFICAR RESULTADO
SELECT 'Jovens' as tabela, COUNT(*) as total FROM public.jovens
UNION ALL
SELECT 'Estados' as tabela, COUNT(*) as total FROM public.estados
UNION ALL
SELECT 'Blocos' as tabela, COUNT(*) as total FROM public.blocos
UNION ALL
SELECT 'Regiões' as tabela, COUNT(*) as total FROM public.regioes
UNION ALL
SELECT 'Igrejas' as tabela, COUNT(*) as total FROM public.igrejas
UNION ALL
SELECT 'Usuários' as tabela, COUNT(*) as total FROM public.usuarios
UNION ALL
SELECT 'Roles' as tabela, COUNT(*) as total FROM public.roles
UNION ALL
SELECT 'User Roles' as tabela, COUNT(*) as total FROM public.user_roles
UNION ALL
SELECT 'Edições' as tabela, COUNT(*) as total FROM public.edicoes;

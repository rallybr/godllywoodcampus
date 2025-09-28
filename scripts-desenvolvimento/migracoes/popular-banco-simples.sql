-- =====================================================
-- SCRIPT SIMPLES PARA POPULAR BANCO (SEM DUPLICATAS)
-- =====================================================

-- 1. DESABILITAR RLS TEMPORARIAMENTE
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.edicoes DISABLE ROW LEVEL SECURITY;

-- 2. VERIFICAR E CRIAR ROLES (PAPÉIS) - APENAS SE NÃO EXISTIREM
DO $$
BEGIN
    -- Criar role de administrador se não existir
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'administrador') THEN
        INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao) 
        VALUES ('11111111-1111-1111-1111-111111111111', 'Administrador', 'administrador', 1, 'Acesso total ao sistema');
    END IF;
    
    -- Criar outros roles se não existirem
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'colaborador') THEN
        INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao) 
        VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Colaborador', 'colaborador', 7, 'Colaborador do sistema');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE slug = 'jovem') THEN
        INSERT INTO public.roles (id, nome, slug, nivel_hierarquico, descricao) 
        VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Jovem', 'jovem', 8, 'Jovem cadastrado');
    END IF;
END $$;

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

-- Blocos
INSERT INTO public.blocos (id, nome, estado_id) 
SELECT '3a7786e2-46b8-5b33-810e-e267dc619be3', 'Santo André', 'c20e70c2-92e6-4c50-96a5-177822095a25'
WHERE NOT EXISTS (SELECT 1 FROM public.blocos WHERE id = '3a7786e2-46b8-5b33-810e-e267dc619be3');

-- Regiões
INSERT INTO public.regioes (id, nome, bloco_id) 
SELECT '84cff91c-3afa-49da-b211-24f50f7cb2ab', 'Brás', '3a7786e2-46b8-5b33-810e-e267dc619be3'
WHERE NOT EXISTS (SELECT 1 FROM public.regioes WHERE id = '84cff91c-3afa-49da-b211-24f50f7cb2ab');

-- Igrejas
INSERT INTO public.igrejas (id, nome, endereco, regiao_id) 
SELECT '6af2451e-bbc8-52dd-ba31-3dfcb0aada94', 'Casa Grande', 'Rua Casa Grande, 123', '84cff91c-3afa-49da-b211-24f50f7cb2ab'
WHERE NOT EXISTS (SELECT 1 FROM public.igrejas WHERE id = '6af2451e-bbc8-52dd-ba31-3dfcb0aada94');

-- 7. CRIAR JOVEM DE TESTE - APENAS SE NÃO EXISTIR
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

-- =====================================================
-- DESABILITAR RLS TEMPORARIAMENTE PARA POPULAR DADOS
-- =====================================================

-- Desabilitar RLS nas tabelas principais
ALTER TABLE public.estados DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens DISABLE ROW LEVEL SECURITY;

-- Inserir dados de teste
INSERT INTO public.estados (id, nome, sigla, bandeira) VALUES 
('c20e70c2-92e6-4c50-96a5-177822095a25', 'São Paulo', 'SP', 'https://example.com/sp.png')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.blocos (id, nome) VALUES 
('3a7786e2-46b8-5b33-810e-e267dc619be3', 'Santo André')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.regioes (id, nome) VALUES 
('84cff91c-3afa-49da-b211-24f50f7cb2ab', 'Brás')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.igrejas (id, nome, endereco) VALUES 
('6af2451e-bbc8-52dd-ba31-3dfcb0aada94', 'Casa Grande', 'Rua Casa Grande, 123')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.jovens (id, nome_completo, idade, sexo, whatsapp, estado_id, bloco_id, regiao_id, igreja_id) VALUES 
('0e1bc378-2cd2-476b-9551-d11d444bf499', 'RAUL VICTOR SILVA', 25, 'masculino', '(16) 99387-1637', 
 'c20e70c2-92e6-4c50-96a5-177822095a25', '3a7786e2-46b8-5b33-810e-e267dc619be3', 
 '84cff91c-3afa-49da-b211-24f50f7cb2ab', '6af2451e-bbc8-52dd-ba31-3dfcb0aada94')
ON CONFLICT (id) DO NOTHING;

-- Reabilitar RLS
ALTER TABLE public.estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.igrejas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- Verificar se os dados foram inseridos
SELECT 'Estados' as tabela, COUNT(*) as total FROM public.estados
UNION ALL
SELECT 'Blocos' as tabela, COUNT(*) as total FROM public.blocos
UNION ALL
SELECT 'Regiões' as tabela, COUNT(*) as total FROM public.regioes
UNION ALL
SELECT 'Igrejas' as tabela, COUNT(*) as total FROM public.igrejas
UNION ALL
SELECT 'Jovens' as tabela, COUNT(*) as total FROM public.jovens;
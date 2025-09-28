-- Verificar se há dados na tabela estados
SELECT '=== VERIFICANDO TABELA ESTADOS ===' as secao;

-- Contar estados
SELECT 'Total de estados:' as info, COUNT(*) as total FROM public.estados;

-- Ver alguns estados
SELECT 'Primeiros 5 estados:' as info;
SELECT id, nome, sigla, bandeira FROM public.estados LIMIT 5;

-- Verificar se há bandeiras
SELECT 'Estados com bandeira:' as info, COUNT(*) as total FROM public.estados WHERE bandeira IS NOT NULL;

-- Verificar se há bandeiras vazias
SELECT 'Estados sem bandeira:' as info, COUNT(*) as total FROM public.estados WHERE bandeira IS NULL OR bandeira = '';

-- Se não há estados, vamos inserir alguns básicos
INSERT INTO public.estados (nome, sigla, bandeira) VALUES 
('São Paulo', 'SP', 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Bandeira_do_estado_de_S%C3%A3o_Paulo.svg/1200px-Bandeira_do_estado_de_S%C3%A3o_Paulo.svg.png'),
('Rio de Janeiro', 'RJ', 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Bandeira_do_estado_do_Rio_de_Janeiro.svg/1200px-Bandeira_do_estado_do_Rio_de_Janeiro.svg.png'),
('Minas Gerais', 'MG', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Bandeira_de_Minas_Gerais.svg/1200px-Bandeira_de_Minas_Gerais.svg.png');

-- Verificar novamente
SELECT 'Estados após inserção:' as info, COUNT(*) as total FROM public.estados;

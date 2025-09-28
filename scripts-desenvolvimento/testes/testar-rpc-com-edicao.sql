-- Testar a função RPC com parâmetro de edição
SELECT * FROM public.get_jovens_por_estado_count(NULL);

-- Verificar se há edições disponíveis
SELECT id, nome, ativa FROM public.edicoes ORDER BY criado_em DESC LIMIT 5;

-- Testar com uma edição específica (se existir)
-- SELECT * FROM public.get_jovens_por_estado_count('ID_DA_EDICAO_AQUI');

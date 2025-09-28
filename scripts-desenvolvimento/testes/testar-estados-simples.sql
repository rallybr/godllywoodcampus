-- Testar consulta simples de estados
SELECT COUNT(*) as total_estados FROM public.estados;

-- Ver alguns estados
SELECT id, nome, sigla, bandeira FROM public.estados LIMIT 5;

-- Testar a função RPC
SELECT * FROM public.get_jovens_por_estado_count() LIMIT 5;

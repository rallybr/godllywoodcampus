-- Testar dados do colaborador para entender por que não aparecem bandeiras
-- Substitua 'e745720c-e9f7-4562-978b-72ba32387420' pelo ID real do colaborador

-- 1. Verificar dados do usuário
SELECT 
  id, 
  nome, 
  nivel, 
  estado_id, 
  bloco_id, 
  regiao_id, 
  igreja_id
FROM public.usuarios 
WHERE id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 2. Verificar jovens cadastrados pelo colaborador
SELECT 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  j.usuario_id,
  e.nome as estado_nome,
  e.sigla as estado_sigla,
  e.bandeira as estado_bandeira
FROM public.jovens j
LEFT JOIN public.estados e ON j.estado_id = e.id
WHERE j.usuario_id = 'e745720c-e9f7-4562-978b-72ba32387420';

-- 3. Contar jovens por estado
SELECT 
  e.id as estado_id,
  e.nome as estado_nome,
  e.sigla,
  e.bandeira,
  COUNT(j.id) as total_jovens
FROM public.estados e
LEFT JOIN public.jovens j ON e.id = j.estado_id AND j.usuario_id = 'e745720c-e9f7-4562-978b-72ba32387420'
GROUP BY e.id, e.nome, e.sigla, e.bandeira
ORDER BY total_jovens DESC;

-- 4. Verificar se há edições ativas
SELECT * FROM public.edicoes WHERE ativa = true;

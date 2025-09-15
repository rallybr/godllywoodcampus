-- Verificar se há dados na tabela blocos
SELECT 
  b.id,
  b.nome,
  b.estado_id,
  e.nome as estado_nome
FROM blocos b
LEFT JOIN estados e ON b.estado_id = e.id
ORDER BY e.nome, b.nome;

-- Verificar quantos blocos existem por estado
SELECT 
  e.nome as estado,
  COUNT(b.id) as total_blocos
FROM estados e
LEFT JOIN blocos b ON e.id = b.estado_id
GROUP BY e.id, e.nome
ORDER BY e.nome;

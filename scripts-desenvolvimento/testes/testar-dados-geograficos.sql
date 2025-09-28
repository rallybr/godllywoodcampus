-- Teste para verificar dados geográficos dos jovens
-- Execute este script para verificar se os dados estão sendo carregados corretamente

-- 1. Verificar se existem dados nas tabelas relacionadas
SELECT 'ESTADOS' as tabela, COUNT(*) as total FROM estados
UNION ALL
SELECT 'BLOCOS' as tabela, COUNT(*) as total FROM blocos  
UNION ALL
SELECT 'REGIÕES' as tabela, COUNT(*) as total FROM regioes
UNION ALL
SELECT 'IGREJAS' as tabela, COUNT(*) as total FROM igrejas;

-- 2. Verificar jovens com dados geográficos
SELECT 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome
FROM jovens j
LEFT JOIN estados e ON e.id = j.estado_id
LEFT JOIN blocos b ON b.id = j.bloco_id  
LEFT JOIN regioes r ON r.id = j.regiao_id
LEFT JOIN igrejas i ON i.id = j.igreja_id
ORDER BY j.nome_completo
LIMIT 10;

-- 3. Verificar se há jovens sem dados geográficos
SELECT 
  COUNT(*) as total_jovens,
  COUNT(estado_id) as com_estado,
  COUNT(bloco_id) as com_bloco,
  COUNT(regiao_id) as com_regiao,
  COUNT(igreja_id) as com_igreja
FROM jovens;

-- 4. Verificar jovens específicos (substitua pelo ID do jovem que está aparecendo N/A)
-- SELECT 
--   j.id,
--   j.nome_completo,
--   j.estado_id,
--   j.bloco_id,
--   j.regiao_id,
--   j.igreja_id,
--   e.nome as estado_nome,
--   b.nome as bloco_nome,
--   r.nome as regiao_nome,
--   i.nome as igreja_nome
-- FROM jovens j
-- LEFT JOIN estados e ON e.id = j.estado_id
-- LEFT JOIN blocos b ON b.id = j.bloco_id  
-- LEFT JOIN regioes r ON r.id = j.regiao_id
-- LEFT JOIN igrejas i ON i.id = j.igreja_id
-- WHERE j.nome_completo ILIKE '%RAUL%';

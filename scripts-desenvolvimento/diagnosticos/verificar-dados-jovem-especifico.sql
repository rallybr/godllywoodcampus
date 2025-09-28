-- =====================================================
-- VERIFICAR DADOS ESPECÍFICOS DO JOVEM
-- =====================================================

-- 1. Verificar dados do jovem Raul Victor Silva
SELECT 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  j.edicao_id
FROM jovens j
WHERE j.nome_completo ILIKE '%RAUL%VICTOR%SILVA%'
   OR j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 2. Verificar se os IDs existem nas tabelas relacionadas
-- Estado
SELECT 'ESTADO' as tipo, 
       j.estado_id as id_jovem,
       e.id as id_tabela,
       e.nome as nome_tabela,
       CASE WHEN e.id IS NOT NULL THEN 'EXISTE' ELSE 'NÃO EXISTE' END as status
FROM jovens j
LEFT JOIN estados e ON e.id = j.estado_id
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499'

UNION ALL

-- Bloco
SELECT 'BLOCO' as tipo,
       j.bloco_id as id_jovem,
       b.id as id_tabela,
       b.nome as nome_tabela,
       CASE WHEN b.id IS NOT NULL THEN 'EXISTE' ELSE 'NÃO EXISTE' END as status
FROM jovens j
LEFT JOIN blocos b ON b.id = j.bloco_id
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499'

UNION ALL

-- Região
SELECT 'REGIÃO' as tipo,
       j.regiao_id as id_jovem,
       r.id as id_tabela,
       r.nome as nome_tabela,
       CASE WHEN r.id IS NOT NULL THEN 'EXISTE' ELSE 'NÃO EXISTE' END as status
FROM jovens j
LEFT JOIN regioes r ON r.id = j.regiao_id
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499'

UNION ALL

-- Igreja
SELECT 'IGREJA' as tipo,
       j.igreja_id as id_jovem,
       i.id as id_tabela,
       i.nome as nome_tabela,
       CASE WHEN i.id IS NOT NULL THEN 'EXISTE' ELSE 'NÃO EXISTE' END as status
FROM jovens j
LEFT JOIN igrejas i ON i.id = j.igreja_id
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 3. Verificar se há dados nas tabelas relacionadas
SELECT 'ESTADOS' as tabela, COUNT(*) as total FROM estados
UNION ALL
SELECT 'BLOCOS' as tabela, COUNT(*) as total FROM blocos
UNION ALL
SELECT 'REGIÕES' as tabela, COUNT(*) as total FROM regioes
UNION ALL
SELECT 'IGREJAS' as tabela, COUNT(*) as total FROM igrejas;

-- 4. Verificar alguns registros das tabelas relacionadas
SELECT 'ESTADOS' as tabela, id, nome FROM estados LIMIT 3
UNION ALL
SELECT 'BLOCOS' as tabela, id, nome FROM blocos LIMIT 3
UNION ALL
SELECT 'REGIÕES' as tabela, id, nome FROM regioes LIMIT 3
UNION ALL
SELECT 'IGREJAS' as tabela, id, nome FROM igrejas LIMIT 3;

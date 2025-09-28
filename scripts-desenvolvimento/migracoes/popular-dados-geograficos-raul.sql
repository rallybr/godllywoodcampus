-- =====================================================
-- POPULAR DADOS GEOGRÁFICOS DO RAUL VICTOR SILVA
-- =====================================================

-- 1. Verificar dados atuais do jovem
SELECT 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id
FROM jovens j
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 2. Verificar se existem dados nas tabelas relacionadas
SELECT 'ESTADOS' as tabela, COUNT(*) as total FROM estados
UNION ALL
SELECT 'BLOCOS' as tabela, COUNT(*) as total FROM blocos
UNION ALL
SELECT 'REGIÕES' as tabela, COUNT(*) as total FROM regioes
UNION ALL
SELECT 'IGREJAS' as tabela, COUNT(*) as total FROM igrejas;

-- 3. Se não houver dados, inserir alguns registros de exemplo
-- Inserir blocos se não existirem
INSERT INTO blocos (id, nome) VALUES 
  (gen_random_uuid(), 'Bloco Central'),
  (gen_random_uuid(), 'Bloco Norte'),
  (gen_random_uuid(), 'Bloco Sul')
ON CONFLICT DO NOTHING;

-- Inserir regiões se não existirem
INSERT INTO regioes (id, nome) VALUES 
  (gen_random_uuid(), 'Região Metropolitana'),
  (gen_random_uuid(), 'Região Interior'),
  (gen_random_uuid(), 'Região Litoral')
ON CONFLICT DO NOTHING;

-- Inserir igrejas se não existirem
INSERT INTO igrejas (id, nome, endereco) VALUES 
  (gen_random_uuid(), 'Igreja Central', 'Rua Central, 123'),
  (gen_random_uuid(), 'Igreja Norte', 'Rua Norte, 456'),
  (gen_random_uuid(), 'Igreja Sul', 'Rua Sul, 789')
ON CONFLICT DO NOTHING;

-- 4. Atualizar o jovem com dados geográficos
-- Primeiro, vamos pegar IDs existentes
WITH dados_geograficos AS (
  SELECT 
    (SELECT id FROM blocos LIMIT 1) as bloco_id,
    (SELECT id FROM regioes LIMIT 1) as regiao_id,
    (SELECT id FROM igrejas LIMIT 1) as igreja_id
)
UPDATE jovens 
SET 
  bloco_id = dados_geograficos.bloco_id,
  regiao_id = dados_geograficos.regiao_id,
  igreja_id = dados_geograficos.igreja_id
FROM dados_geograficos
WHERE jovens.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- 5. Verificar se a atualização funcionou
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
WHERE j.id = '0e1bc378-2cd2-476b-9551-d11d444bf499';

-- Inserir dados de teste para blocos
-- Primeiro, vamos verificar se existem estados
SELECT id, nome FROM estados WHERE nome = 'São Paulo';

-- Inserir blocos para São Paulo (assumindo que o ID do estado é 1)
INSERT INTO blocos (nome, estado_id) VALUES 
('Bloco Central', 1),
('Bloco Norte', 1),
('Bloco Sul', 1),
('Bloco Leste', 1),
('Bloco Oeste', 1)
ON CONFLICT DO NOTHING;

-- Verificar se os blocos foram inseridos
SELECT b.id, b.nome, e.nome as estado 
FROM blocos b 
JOIN estados e ON b.estado_id = e.id 
WHERE e.nome = 'São Paulo';

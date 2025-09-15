-- Script para atualizar a edição do jovem existente
-- Substituir o valor "2024" pelo nome correto da edição

-- Primeiro, vamos ver o jovem atual
SELECT 
  j.id, 
  j.nome_completo, 
  j.edicao, 
  j.edicao_id,
  e.nome as nome_edicao_correta
FROM jovens j
LEFT JOIN edicoes e ON j.edicao_id = e.id
WHERE j.nome_completo = 'Teste';

-- Atualizar a edição do jovem com o nome correto
UPDATE jovens 
SET edicao = (
  SELECT nome 
  FROM edicoes 
  WHERE id = jovens.edicao_id
)
WHERE edicao = '2024' 
  AND edicao_id IS NOT NULL;

-- Verificar o resultado
SELECT 
  j.id, 
  j.nome_completo, 
  j.edicao, 
  j.edicao_id,
  e.nome as nome_edicao_correta
FROM jovens j
LEFT JOIN edicoes e ON j.edicao_id = e.id
WHERE j.nome_completo = 'Teste';

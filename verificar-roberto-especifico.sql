-- Verificar se o jovem Roberto Guerra2 existe e tem usuario_id
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id,
  u.id_auth,
  u.nome as nome_usuario
FROM public.jovens j
LEFT JOIN public.usuarios u ON u.id = j.usuario_id
WHERE j.nome_completo LIKE '%Roberto Guerra2%';

-- Verificar se há dados de viagem para o jovem Roberto Guerra2
SELECT 
  dv.id,
  dv.jovem_id,
  dv.edicao_id,
  dv.pagou_despesas,
  dv.comprovante_pagamento,
  dv.data_passagem_ida,
  dv.comprovante_passagem_ida,
  dv.data_passagem_volta,
  dv.comprovante_passagem_volta,
  j.nome_completo as nome_jovem,
  e.nome as nome_edicao
FROM public.dados_viagem dv
JOIN public.jovens j ON j.id = dv.jovem_id
LEFT JOIN public.edicoes e ON e.id = dv.edicao_id
WHERE j.nome_completo LIKE '%Roberto Guerra2%';

-- Se não houver dados de viagem, vamos criar um registro para o jovem Roberto Guerra2
-- Primeiro, vamos pegar o ID do jovem
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM public.jovens j
WHERE j.nome_completo LIKE '%Roberto Guerra2%'
LIMIT 1;

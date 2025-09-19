-- Primeiro, vamos pegar o ID do jovem Roberto Guerra2
SELECT 
  j.id as jovem_id,
  j.nome_completo,
  j.usuario_id
FROM public.jovens j
WHERE j.nome_completo LIKE '%Roberto Guerra2%'
LIMIT 1;

-- Criar dados de viagem para o jovem Roberto Guerra2 na edição ativa
-- (Execute apenas se o jovem existir e não tiver dados de viagem)
INSERT INTO public.dados_viagem (
  jovem_id,
  edicao_id,
  pagou_despesas,
  data_cadastro,
  atualizado_em,
  usuario_id
) 
SELECT 
  j.id,
  e.id,
  false, -- pagou_despesas = false (não pago)
  now(),
  now(),
  j.usuario_id
FROM public.jovens j
CROSS JOIN public.edicoes e
WHERE j.nome_completo LIKE '%Roberto Guerra2%'
AND e.ativa = true
AND NOT EXISTS (
  SELECT 1 FROM public.dados_viagem dv 
  WHERE dv.jovem_id = j.id 
  AND dv.edicao_id = e.id
);

-- Verificar se o registro foi criado
SELECT 
  dv.id,
  dv.jovem_id,
  dv.edicao_id,
  dv.pagou_despesas,
  dv.comprovante_pagamento,
  j.nome_completo as nome_jovem,
  e.nome as nome_edicao
FROM public.dados_viagem dv
JOIN public.jovens j ON j.id = dv.jovem_id
JOIN public.edicoes e ON e.id = dv.edicao_id
WHERE j.nome_completo LIKE '%Roberto Guerra2%';

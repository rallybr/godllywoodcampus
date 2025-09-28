-- Verificar se a função can_access_viagem_by_level existe
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'can_access_viagem_by_level'
AND routine_schema = 'public';

-- Testar se um jovem pode acessar seus próprios dados de viagem
-- Substitua 'ID_DO_JOVEM_AQUI' pelo ID real do jovem Roberto Guerra2
SELECT 
  dv.id,
  dv.jovem_id,
  dv.edicao_id,
  dv.pagou_despesas,
  dv.comprovante_pagamento,
  j.nome_completo as nome_jovem
FROM public.dados_viagem dv
JOIN public.jovens j ON j.id = dv.jovem_id
WHERE dv.jovem_id IN (
  SELECT j.id 
  FROM public.jovens j 
  JOIN public.usuarios u ON u.id = j.usuario_id 
  WHERE u.id_auth = auth.uid()
);

-- Verificar se há dados de viagem para o jovem Roberto Guerra2
SELECT 
  dv.id,
  dv.jovem_id,
  dv.edicao_id,
  dv.pagou_despesas,
  dv.comprovante_pagamento,
  j.nome_completo as nome_jovem
FROM public.dados_viagem dv
JOIN public.jovens j ON j.id = dv.jovem_id
WHERE j.nome_completo LIKE '%Roberto Guerra2%';

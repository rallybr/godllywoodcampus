-- 1. Primeiro, criar dados de viagem para o jovem Roberto Guerra2 (para teste imediato)
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

-- 2. Criar função para criar dados de viagem para um jovem em todas as edições ativas
CREATE OR REPLACE FUNCTION criar_dados_viagem_para_jovem(p_jovem_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Criar dados de viagem para o jovem em todas as edições ativas
  INSERT INTO public.dados_viagem (
    jovem_id,
    edicao_id,
    pagou_despesas,
    data_cadastro,
    atualizado_em,
    usuario_id
  )
  SELECT 
    p_jovem_id,
    e.id,
    false, -- pagou_despesas = false (não pago)
    now(),
    now(),
    (SELECT usuario_id FROM public.jovens WHERE id = p_jovem_id)
  FROM public.edicoes e
  WHERE e.ativa = true
  AND NOT EXISTS (
    SELECT 1 FROM public.dados_viagem dv 
    WHERE dv.jovem_id = p_jovem_id 
    AND dv.edicao_id = e.id
  );
END;
$$;

-- 3. Criar função para criar dados de viagem para todos os jovens quando uma edição for ativada
CREATE OR REPLACE FUNCTION criar_dados_viagem_para_todos_jovens(p_edicao_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Criar dados de viagem para todos os jovens na edição ativada
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
    p_edicao_id,
    false, -- pagou_despesas = false (não pago)
    now(),
    now(),
    j.usuario_id
  FROM public.jovens j
  WHERE NOT EXISTS (
    SELECT 1 FROM public.dados_viagem dv 
    WHERE dv.jovem_id = j.id 
    AND dv.edicao_id = p_edicao_id
  );
END;
$$;

-- 4. Criar trigger para criar dados de viagem quando um jovem for inserido
CREATE OR REPLACE FUNCTION trigger_criar_dados_viagem_jovem()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Criar dados de viagem para o novo jovem em todas as edições ativas
  PERFORM criar_dados_viagem_para_jovem(NEW.id);
  
  RETURN NEW;
END;
$$;

-- 5. Criar trigger para criar dados de viagem quando uma edição for ativada
CREATE OR REPLACE FUNCTION trigger_criar_dados_viagem_edicao()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Se a edição foi ativada (ativa = true e antes era false)
  IF NEW.ativa = true AND (OLD.ativa = false OR OLD.ativa IS NULL) THEN
    PERFORM criar_dados_viagem_para_todos_jovens(NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$;

-- 6. Aplicar os triggers
DROP TRIGGER IF EXISTS trigger_auto_criar_dados_viagem_jovem ON public.jovens;
CREATE TRIGGER trigger_auto_criar_dados_viagem_jovem
  AFTER INSERT ON public.jovens
  FOR EACH ROW
  EXECUTE FUNCTION trigger_criar_dados_viagem_jovem();

DROP TRIGGER IF EXISTS trigger_auto_criar_dados_viagem_edicao ON public.edicoes;
CREATE TRIGGER trigger_auto_criar_dados_viagem_edicao
  AFTER UPDATE ON public.edicoes
  FOR EACH ROW
  EXECUTE FUNCTION trigger_criar_dados_viagem_edicao();

-- 7. Verificar se o registro foi criado para Roberto Guerra2
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

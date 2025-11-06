-- Script para adicionar novos campos na tabela dados_viagem
-- Execute este script no Supabase SQL Editor

-- Adicionar novos campos à tabela dados_viagem
ALTER TABLE public.dados_viagem
ADD COLUMN IF NOT EXISTS como_pagou_despesas TEXT,
ADD COLUMN IF NOT EXISTS como_pagou_passagens TEXT,
ADD COLUMN IF NOT EXISTS como_conseguiu_valor TEXT,
ADD COLUMN IF NOT EXISTS alguem_ajudou_pagar BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS quem_ajudou_pagar TEXT;

-- Comentários nas colunas para documentação
COMMENT ON COLUMN public.dados_viagem.como_pagou_despesas IS 'Como o jovem pagou as despesas';
COMMENT ON COLUMN public.dados_viagem.como_pagou_passagens IS 'Como o jovem pagou as passagens';
COMMENT ON COLUMN public.dados_viagem.como_conseguiu_valor IS 'Como o jovem conseguiu o valor para pagar';
COMMENT ON COLUMN public.dados_viagem.alguem_ajudou_pagar IS 'Indica se alguém ajudou o jovem a pagar';
COMMENT ON COLUMN public.dados_viagem.quem_ajudou_pagar IS 'Nome de quem ajudou o jovem a pagar (se alguem_ajudou_pagar = true)';

-- Verificar se as colunas foram criadas
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'dados_viagem'
  AND column_name IN (
    'como_pagou_despesas',
    'como_pagou_passagens',
    'como_conseguiu_valor',
    'alguem_ajudou_pagar',
    'quem_ajudou_pagar'
  )
ORDER BY column_name;


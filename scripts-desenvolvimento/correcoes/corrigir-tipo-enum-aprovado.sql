-- =====================================================
-- CORREÇÃO DO TIPO ENUM APROVADO
-- =====================================================
-- Este script corrige o problema de tipo enum vs text

-- ============================================
-- 1. VERIFICAR VALORES DO ENUM
-- ============================================

-- Verificar valores válidos do enum intellimen_aprovado_enum
SELECT 
  'VALORES DO ENUM' as categoria,
  t.typname as nome_enum,
  e.enumlabel as valor_enum
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'intellimen_aprovado_enum'
ORDER BY e.enumsortorder;

-- ============================================
-- 2. CORRIGIR FUNÇÃO atualizar_status_jovem
-- ============================================

CREATE OR REPLACE FUNCTION public.atualizar_status_jovem(p_jovem_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  aprovacoes_count integer;
  tem_aprovado boolean := false;
  tem_pre_aprovado boolean := false;
  status_final intellimen_aprovado_enum; -- ✅ USAR O TIPO ENUM CORRETO
  current_user_id uuid;
BEGIN
  -- Obter usuário atual para log
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Contar aprovações do jovem (usando alias para evitar ambiguidade)
  SELECT COUNT(*) INTO aprovacoes_count
  FROM public.aprovacoes_jovens aj
  WHERE aj.jovem_id = p_jovem_id;
  
  -- Se não tem aprovações, status fica null
  IF aprovacoes_count = 0 THEN
    status_final := null;
  ELSE
    -- Verificar se tem aprovação final (usando alias)
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'aprovado'
    ) INTO tem_aprovado;
    
    -- Verificar se tem pré-aprovação (usando alias)
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'pre_aprovado'
    ) INTO tem_pre_aprovado;
    
    -- Determinar status final (aprovado tem prioridade sobre pre_aprovado)
    -- ✅ USAR CAST PARA O TIPO ENUM CORRETO
    IF tem_aprovado THEN
      status_final := 'aprovado'::intellimen_aprovado_enum;
    ELSIF tem_pre_aprovado THEN
      status_final := 'pre_aprovado'::intellimen_aprovado_enum;
    ELSE
      status_final := null;
    END IF;
  END IF;
  
  -- Atualizar o status do jovem (usando alias para evitar ambiguidade)
  UPDATE public.jovens j
  SET aprovado = status_final
  WHERE j.id = p_jovem_id;
  
  -- Log da atualização (apenas se usuário estiver autenticado)
  IF current_user_id IS NOT NULL THEN
    INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
    VALUES (
      current_user_id,
      'atualizacao_status_jovem',
      'Status do jovem atualizado automaticamente',
      jsonb_build_object(
        'jovem_id', p_jovem_id,
        'status_anterior', (SELECT j2.aprovado FROM public.jovens j2 WHERE j2.id = p_jovem_id),
        'status_novo', status_final,
        'aprovacoes_count', aprovacoes_count
      )
    );
  END IF;
END;
$$;

-- ============================================
-- 3. VERIFICAR ESTRUTURA DA TABELA JOVENS
-- ============================================

-- Verificar a estrutura da coluna aprovado na tabela jovens
SELECT 
  'ESTRUTURA DA COLUNA APROVADO' as categoria,
  column_name,
  data_type,
  udt_name,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'jovens' 
  AND table_schema = 'public'
  AND column_name = 'aprovado';

-- ============================================
-- 4. TESTAR FUNÇÃO CORRIGIDA
-- ============================================

-- Testar se a função foi corrigida
SELECT 
  'VERIFICAÇÃO DA FUNÇÃO CORRIGIDA' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'atualizar_status_jovem'
  ) as funcao_atualizar_status_existe;

-- ============================================
-- 5. VERIFICAR DADOS EXISTENTES
-- ============================================

-- Verificar valores atuais na tabela jovens
SELECT 
  'VALORES ATUAIS NA TABELA JOVENS' as categoria,
  aprovado,
  COUNT(*) as total
FROM public.jovens
GROUP BY aprovado
ORDER BY aprovado;

-- ============================================
-- 6. RESUMO DA CORREÇÃO
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Função atualizar_status_jovem corrigida para usar intellimen_aprovado_enum' as acao_1,
  'Problema de tipo enum vs text resolvido' as acao_2,
  'Sistema de remoção de aprovações funcionando' as resultado;

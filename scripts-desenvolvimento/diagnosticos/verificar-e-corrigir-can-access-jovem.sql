-- =====================================================
-- VERIFICAR E CORRIGIR FUNÇÃO can_access_jovem
-- =====================================================
-- Este script verifica qual versão da função está ativa
-- e aplica a versão correta se necessário

-- ============================================
-- 1. VERIFICAR VERSÃO ATUAL DA FUNÇÃO
-- ============================================

-- Verificar se a função existe
SELECT 
  'VERIFICAÇÃO DA FUNÇÃO can_access_jovem' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as funcao_existe;

-- Mostrar a definição atual da função
SELECT 
  'DEFINIÇÃO ATUAL DA FUNÇÃO' as status,
  pg_get_functiondef(p.oid) as definicao_completa
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'can_access_jovem';

-- ============================================
-- 2. TESTAR COMPORTAMENTO ATUAL
-- ============================================

-- Testar com diferentes níveis hierárquicos
-- (Assumindo que existe um usuário de teste com cada nível)

-- Verificar se colaborador (nível 7) tem acesso territorial
SELECT 
  'TESTE: Colaborador com acesso territorial' as teste,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM public.user_roles ur
      JOIN public.roles r ON r.id = ur.role_id
      WHERE r.slug = 'colaborador' 
        AND ur.ativo = true
      LIMIT 1
    ) THEN 'Usuário colaborador encontrado - testando acesso'
    ELSE 'Nenhum usuário colaborador ativo encontrado'
  END as status;

-- ============================================
-- 3. APLICAR VERSÃO CORRETA DA FUNÇÃO
-- ============================================

-- Aplicar a versão CORRETA que nega acesso territorial para colaborador
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_roles_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  INTO user_roles_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;

  IF user_roles_info IS NULL THEN RETURN false; END IF;

  -- 1 e 2: admin e líderes nacionais → acesso total
  IF user_roles_info.nivel_hierarquico IN (1, 2) THEN RETURN true; END IF;

  -- 3: estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    RETURN user_roles_info.estado_id = jovem_estado_id;
  END IF;

  -- 4: bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    RETURN user_roles_info.bloco_id = jovem_bloco_id;
  END IF;

  -- 5: regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    RETURN user_roles_info.regiao_id = jovem_regiao_id;
  END IF;

  -- 6: igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    RETURN user_roles_info.igreja_id = jovem_igreja_id;
  END IF;

  -- 7: colaborador → NÃO libera visão por localização; acesso só via policy do criador
  IF user_roles_info.nivel_hierarquico = 7 THEN
    RETURN false;
  END IF;

  -- 8: jovem → acesso controlado por outras policies
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN false;
  END IF;

  RETURN false;
END;
$$;

-- ============================================
-- 4. VERIFICAR SE A CORREÇÃO FOI APLICADA
-- ============================================

-- Mostrar a nova definição da função
SELECT 
  'NOVA DEFINIÇÃO DA FUNÇÃO' as status,
  pg_get_functiondef(p.oid) as definicao_corrigida
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'can_access_jovem';

-- ============================================
-- 5. TESTAR A FUNÇÃO CORRIGIDA
-- ============================================

-- Teste básico da função
SELECT 
  'TESTE DA FUNÇÃO CORRIGIDA' as status,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado_teste;

-- ============================================
-- 6. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar se as políticas RLS estão corretas
SELECT 
  'POLÍTICAS RLS DA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- Verificar se existe a política para colaborador ver o que criou
SELECT 
  'POLÍTICA PARA COLABORADOR' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'jovens' 
        AND policyname = 'jovens_select_own_creator'
    ) THEN '✅ Política para colaborador existe'
    ELSE '❌ Política para colaborador NÃO existe'
  END as status_politica;

-- ============================================
-- 7. RESUMO FINAL
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Função can_access_jovem corrigida para negar acesso territorial para colaborador' as acao_realizada,
  'Colaborador agora só vê jovens que ele cadastrou (via usuario_id)' as comportamento_esperado,
  'Líderes mantêm acesso por escopo territorial conforme nível hierárquico' as comportamento_lideres;

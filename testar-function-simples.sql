-- =====================================================
-- TESTE DE FUNCTION SIMPLES
-- =====================================================
-- Este script testa uma function simples para identificar o problema

-- 1. CRIAR FUNCTION DE TESTE SIMPLES
CREATE OR REPLACE FUNCTION public.test_access_simple()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN 'ERRO: Usuário não encontrado';
  END IF;
  
  -- Retornar informações do usuário
  RETURN 'Usuário: ' || user_info.nome || ' | Nível: ' || user_info.nivel;
END;
$function$;

-- 2. TESTAR FUNCTION SIMPLES
SELECT 
  'TESTE FUNCTION SIMPLES' as diagnostico,
  test_access_simple() as resultado;

-- 3. CRIAR FUNCTION DE TESTE PARA LÍDERES NACIONAIS
CREATE OR REPLACE FUNCTION public.test_lider_nacional()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN 'ERRO: Usuário não encontrado';
  END IF;
  
  -- Verificar se é líder nacional
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN
    RETURN 'SUCESSO: Usuário é líder nacional - ' || user_info.nivel;
  END IF;
  
  -- Verificar se é administrador
  IF user_info.nivel = 'administrador' THEN
    RETURN 'SUCESSO: Usuário é administrador';
  END IF;
  
  -- Se não é líder nacional nem administrador
  RETURN 'ERRO: Usuário não é líder nacional nem administrador - Nível: ' || user_info.nivel;
END;
$function$;

-- 4. TESTAR FUNCTION DE LÍDER NACIONAL
SELECT 
  'TESTE LÍDER NACIONAL' as diagnostico,
  test_lider_nacional() as resultado;

-- 5. CRIAR FUNCTION DE TESTE PARA ACESSO
CREATE OR REPLACE FUNCTION public.test_access_simple_return()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN false;
  END IF;
  
  -- Verificar se é líder nacional
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN
    RETURN true;
  END IF;
  
  -- Verificar se é administrador
  IF user_info.nivel = 'administrador' THEN
    RETURN true;
  END IF;
  
  -- Se não é líder nacional nem administrador
  RETURN false;
END;
$function$;

-- 6. TESTAR FUNCTION DE ACESSO SIMPLES
SELECT 
  'TESTE ACESSO SIMPLES' as diagnostico,
  test_access_simple_return() as resultado,
  CASE 
    WHEN test_access_simple_return() = true THEN '✅ ACESSO CONCEDIDO'
    ELSE '❌ ACESSO NEGADO'
  END as status;

-- 7. VERIFICAR SE O USUÁRIO ESTÁ AUTENTICADO
SELECT 
  'VERIFICAÇÃO DE AUTENTICAÇÃO' as diagnostico,
  auth.uid() as user_id_auth,
  CASE 
    WHEN auth.uid() IS NOT NULL THEN '✅ USUÁRIO AUTENTICADO'
    ELSE '❌ USUÁRIO NÃO AUTENTICADO'
  END as resultado;

-- 8. VERIFICAR SE O USUÁRIO EXISTE NA TABELA usuarios
SELECT 
  'VERIFICAÇÃO DE USUÁRIO NA TABELA' as diagnostico,
  CASE 
    WHEN EXISTS (SELECT 1 FROM public.usuarios WHERE id_auth = auth.uid()) THEN '✅ USUÁRIO EXISTE NA TABELA'
    ELSE '❌ USUÁRIO NÃO EXISTE NA TABELA'
  END as resultado;

-- 9. MOSTRAR DADOS DO USUÁRIO ATUAL
SELECT 
  'DADOS DO USUÁRIO ATUAL' as diagnostico,
  u.id,
  u.nome,
  u.email,
  u.nivel,
  u.ativo
FROM public.usuarios u
WHERE u.id_auth = auth.uid();

-- =====================================================
-- FIM DO TESTE SIMPLES
-- =====================================================

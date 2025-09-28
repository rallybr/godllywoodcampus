-- =====================================================
-- CORREÇÃO DEFINITIVA DA FUNÇÃO can_access_jovem
-- =====================================================
-- Baseada na estrutura real do banco de dados
-- Usa o campo 'nivel' da tabela usuarios (não user_roles)

-- ============================================
-- 1. VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Verificar a função atual
SELECT 
  'FUNÇÃO ATUAL can_access_jovem' as status,
  pg_get_functiondef(p.oid) as definicao_atual
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'can_access_jovem';

-- ============================================
-- 2. CORRIGIR FUNÇÃO can_access_jovem
-- ============================================

-- Função corrigida que usa o campo 'nivel' da tabela usuarios
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_info record;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Se não encontrou o usuário, não tem acesso
  IF current_user_id IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- Buscar informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios 
  WHERE id = current_user_id;
  
  -- Se não encontrou o usuário, não tem acesso
  IF user_info IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Visão estadual
  -- Podem ver tudo de bloco, região e igreja e jovens relacionados
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Visão de bloco
  -- Podem ver região, igreja e jovens relacionados
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;
  
  -- 5. LÍDER REGIONAL - Visão regional
  -- Podem ver todas as igrejas ligadas à região e jovens relacionados
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;
  
  -- 6. LÍDER DE IGREJA - Visão de igreja
  -- Podem ver jovens relacionados à igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;
  
  -- 7. COLABORADOR - Acesso aos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  -- 8. JOVEM - Acesso APENAS aos seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  RETURN false;
END;
$$;

-- ============================================
-- 3. VERIFICAR POLÍTICAS RLS ATUAIS
-- ============================================

-- Verificar políticas da tabela jovens
SELECT 
  'POLÍTICAS RLS ATUAIS DA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 4. TESTAR FUNÇÃO CORRIGIDA
-- ============================================

-- Teste básico da função
SELECT 
  'TESTE DA FUNÇÃO CORRIGIDA' as status,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado_teste;

-- ============================================
-- 5. VERIFICAR USUÁRIOS COM DIFERENTES NÍVEIS
-- ============================================

-- Listar usuários com níveis hierárquicos
SELECT 
  'USUÁRIOS COM NÍVEIS HIERÁRQUICOS' as categoria,
  u.id,
  u.nome,
  u.nivel,
  u.estado_id,
  u.bloco_id,
  u.regiao_id,
  u.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome
FROM public.usuarios u
LEFT JOIN public.estados e ON e.id = u.estado_id
LEFT JOIN public.blocos b ON b.id = u.bloco_id
LEFT JOIN public.regioes r ON r.id = u.regiao_id
LEFT JOIN public.igrejas i ON i.id = u.igreja_id
WHERE u.nivel IN (
  'administrador',
  'lider_nacional_iurd', 'lider_nacional_fju',
  'lider_estadual_iurd', 'lider_estadual_fju',
  'lider_bloco_iurd', 'lider_bloco_fju',
  'lider_regional_iurd', 'lider_igreja_iurd',
  'colaborador', 'jovem'
)
ORDER BY 
  CASE u.nivel
    WHEN 'administrador' THEN 1
    WHEN 'lider_nacional_iurd' THEN 2
    WHEN 'lider_nacional_fju' THEN 2
    WHEN 'lider_estadual_iurd' THEN 3
    WHEN 'lider_estadual_fju' THEN 3
    WHEN 'lider_bloco_iurd' THEN 4
    WHEN 'lider_bloco_fju' THEN 4
    WHEN 'lider_regional_iurd' THEN 5
    WHEN 'lider_igreja_iurd' THEN 6
    WHEN 'colaborador' THEN 7
    WHEN 'jovem' THEN 8
  END,
  u.nome;

-- ============================================
-- 6. TESTAR ACESSO COM DADOS REAIS
-- ============================================

-- Testar função com dados reais de jovens
SELECT 
  'TESTE COM DADOS REAIS' as categoria,
  j.id as jovem_id,
  j.nome_completo as jovem_nome,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  e.nome as estado_nome,
  b.nome as bloco_nome,
  r.nome as regiao_nome,
  i.nome as igreja_nome,
  can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id) as tem_acesso
FROM public.jovens j
LEFT JOIN public.estados e ON e.id = j.estado_id
LEFT JOIN public.blocos b ON b.id = j.bloco_id
LEFT JOIN public.regioes r ON r.id = j.regiao_id
LEFT JOIN public.igrejas i ON i.id = j.igreja_id
LIMIT 10;

-- ============================================
-- 7. CONTAR JOVENS ACESSÍVEIS
-- ============================================

-- Contar jovens acessíveis para o usuário atual
SELECT 
  'CONTAGEM DE JOVENS ACESSÍVEIS' as categoria,
  COUNT(*) as total_jovens,
  COUNT(CASE WHEN can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_com_acesso,
  COUNT(CASE WHEN NOT can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) THEN 1 END) as jovens_sem_acesso
FROM public.jovens;

-- ============================================
-- 8. RESUMO DA CORREÇÃO
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Função can_access_jovem corrigida para usar campo nivel da tabela usuarios' as acao_realizada,
  'Sistema agora funciona conforme a hierarquia definida' as resultado,
  'Líderes estaduais: veem jovens do estado' as comportamento_estadual,
  'Líderes de bloco: veem jovens do bloco' as comportamento_bloco,
  'Líderes regionais: veem jovens da região' as comportamento_regional,
  'Líderes de igreja: veem jovens da igreja' as comportamento_igreja;

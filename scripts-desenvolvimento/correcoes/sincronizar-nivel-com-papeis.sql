-- =====================================================
-- SINCRONIZAR NÍVEL COM PAPÉIS
-- =====================================================
-- Este script sincroniza o campo 'nivel' com os papéis atribuídos

-- ============================================
-- 1. VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Verificar usuários com inconsistências
SELECT 
  'USUÁRIOS COM INCONSISTÊNCIAS' as categoria,
  u.id,
  u.nome,
  u.nivel,
  COUNT(ur.id) as total_papeis,
  STRING_AGG(r.slug, ', ') as papeis_atribuidos
FROM public.usuarios u
LEFT JOIN public.user_roles ur ON ur.user_id = u.id AND ur.ativo = true
LEFT JOIN public.roles r ON r.id = ur.role_id
WHERE u.nivel IN (
  'lider_estadual_iurd', 'lider_estadual_fju',
  'lider_bloco_iurd', 'lider_bloco_fju',
  'lider_regional_iurd', 'lider_igreja_iurd'
)
GROUP BY u.id, u.nome, u.nivel
HAVING COUNT(ur.id) = 0 OR u.nivel NOT IN (
  SELECT r2.slug FROM public.user_roles ur2 
  JOIN public.roles r2 ON r2.id = ur2.role_id 
  WHERE ur2.user_id = u.id AND ur2.ativo = true
);

-- ============================================
-- 2. CRIAR FUNÇÃO DE SINCRONIZAÇÃO
-- ============================================

CREATE OR REPLACE FUNCTION public.sincronizar_nivel_com_papeis(p_usuario_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_info record;
  role_info record;
  nivel_correto text;
  resultado jsonb;
BEGIN
  -- Obter informações do usuário
  SELECT id, nome, nivel, estado_id, bloco_id, regiao_id, igreja_id
  INTO user_info
  FROM public.usuarios
  WHERE id = p_usuario_id;
  
  IF user_info IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não encontrado');
  END IF;
  
  -- Buscar o papel com menor nível hierárquico (maior privilégio)
  SELECT r.slug, r.nivel_hierarquico
  INTO role_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = p_usuario_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;
  
  -- Se não tem papéis, manter o nível atual
  IF role_info IS NULL THEN
    RETURN jsonb_build_object(
      'success', true, 
      'message', 'Usuário sem papéis ativos - nível mantido',
      'nivel_atual', user_info.nivel
    );
  END IF;
  
  -- Determinar o nível correto baseado no papel
  nivel_correto := role_info.slug;
  
  -- Atualizar o nível se necessário
  IF user_info.nivel != nivel_correto THEN
    UPDATE public.usuarios
    SET nivel = nivel_correto
    WHERE id = p_usuario_id;
    
    -- Log da alteração
    INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
    VALUES (
      p_usuario_id,
      'sincronizacao_nivel',
      'Nível sincronizado com papéis',
      jsonb_build_object(
        'nivel_anterior', user_info.nivel,
        'nivel_novo', nivel_correto,
        'papel_base', role_info.slug
      )
    );
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Nível sincronizado com sucesso',
      'nivel_anterior', user_info.nivel,
      'nivel_novo', nivel_correto
    );
  ELSE
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Nível já está sincronizado',
      'nivel_atual', user_info.nivel
    );
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ============================================
-- 3. SINCRONIZAR TODOS OS USUÁRIOS
-- ============================================

-- Sincronizar todos os usuários com papéis
DO $$
DECLARE
  user_record record;
  resultado jsonb;
BEGIN
  FOR user_record IN 
    SELECT DISTINCT u.id, u.nome
    FROM public.usuarios u
    JOIN public.user_roles ur ON ur.user_id = u.id AND ur.ativo = true
  LOOP
    SELECT public.sincronizar_nivel_com_papeis(user_record.id) INTO resultado;
    RAISE NOTICE 'Usuário %: %', user_record.nome, resultado->>'message';
  END LOOP;
END $$;

-- ============================================
-- 4. VERIFICAR RESULTADO DA SINCRONIZAÇÃO
-- ============================================

-- Verificar usuários após sincronização
SELECT 
  'USUÁRIOS APÓS SINCRONIZAÇÃO' as categoria,
  u.id,
  u.nome,
  u.nivel,
  COUNT(ur.id) as total_papeis,
  STRING_AGG(r.slug, ', ') as papeis_atribuidos,
  CASE 
    WHEN u.nivel IN (
      SELECT r2.slug FROM public.user_roles ur2 
      JOIN public.roles r2 ON r2.id = ur2.role_id 
      WHERE ur2.user_id = u.id AND ur2.ativo = true
    ) THEN '✅ Sincronizado'
    ELSE '❌ Ainda inconsistente'
  END as status_sincronizacao
FROM public.usuarios u
LEFT JOIN public.user_roles ur ON ur.user_id = u.id AND ur.ativo = true
LEFT JOIN public.roles r ON r.id = ur.role_id
WHERE u.nivel IN (
  'lider_estadual_iurd', 'lider_estadual_fju',
  'lider_bloco_iurd', 'lider_bloco_fju',
  'lider_regional_iurd', 'lider_igreja_iurd'
)
GROUP BY u.id, u.nome, u.nivel
ORDER BY u.nome;

-- ============================================
-- 5. CRIAR TRIGGER PARA SINCRONIZAÇÃO AUTOMÁTICA
-- ============================================

-- Trigger para sincronizar automaticamente quando papéis são alterados
CREATE OR REPLACE FUNCTION public.trigger_sincronizar_nivel()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  resultado jsonb;
BEGIN
  -- Sincronizar nível do usuário afetado
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT public.sincronizar_nivel_com_papeis(NEW.user_id) INTO resultado;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT public.sincronizar_nivel_com_papeis(OLD.user_id) INTO resultado;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Aplicar trigger na tabela user_roles
DROP TRIGGER IF EXISTS trigger_sincronizar_nivel_user_roles ON public.user_roles;
CREATE TRIGGER trigger_sincronizar_nivel_user_roles
  AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW EXECUTE FUNCTION public.trigger_sincronizar_nivel();

-- ============================================
-- 6. RESUMO DA SINCRONIZAÇÃO
-- ============================================

SELECT 
  'RESUMO DA SINCRONIZAÇÃO' as status,
  'Níveis sincronizados com papéis' as acao_realizada,
  'Trigger criado para sincronização automática' as trigger_criado,
  'Sistema agora mantém consistência entre nível e papéis' as resultado;
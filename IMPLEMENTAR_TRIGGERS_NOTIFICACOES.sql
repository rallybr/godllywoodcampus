-- Função para obter líderes que devem receber notificações baseado na localização do jovem
CREATE OR REPLACE FUNCTION obter_lideres_para_notificacao(
  p_estado_id uuid,
  p_bloco_id uuid,
  p_regiao_id uuid,
  p_igreja_id uuid
)
RETURNS TABLE (user_id uuid) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ur.user_id
  FROM user_roles ur
  JOIN roles r ON ur.role_id = r.id
  WHERE (
    -- Administradores e colaboradores recebem todas as notificações
    r.slug IN ('administrador', 'colaborador')
    OR
    -- Líderes nacionais recebem todas as notificações
    r.slug IN ('lider_nacional_iurd', 'lider_nacional_fju')
    OR
    -- Líderes estaduais recebem notificações do seu estado
    (r.slug IN ('lider_estadual_iurd', 'lider_estadual_fju') AND ur.estado_id = p_estado_id)
    OR
    -- Líderes de bloco recebem notificações do seu bloco
    (r.slug IN ('lider_bloco_iurd', 'lider_bloco_fju') AND ur.bloco_id = p_bloco_id)
    OR
    -- Líderes regionais recebem notificações da sua região
    (r.slug = 'lider_regional_iurd' AND ur.regiao_id = p_regiao_id)
    OR
    -- Líderes de igreja recebem notificações da sua igreja
    (r.slug = 'lider_igreja_iurd' AND ur.igreja_id = p_igreja_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para criar notificação para líderes
CREATE OR REPLACE FUNCTION notificar_lideres(
  p_tipo text,
  p_titulo text,
  p_mensagem text,
  p_jovem_id uuid,
  p_acao_url text DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  jovem_record record;
  lider_record record;
BEGIN
  -- Buscar dados do jovem
  SELECT estado_id, bloco_id, regiao_id, igreja_id
  INTO jovem_record
  FROM jovens
  WHERE id = p_jovem_id;
  
  -- Criar notificação para cada líder
  FOR lider_record IN 
    SELECT user_id FROM obter_lideres_para_notificacao(
      jovem_record.estado_id,
      jovem_record.bloco_id,
      jovem_record.regiao_id,
      jovem_record.igreja_id
    )
  LOOP
    INSERT INTO notificacoes (
      destinatario_id,
      tipo,
      titulo,
      mensagem,
      jovem_id,
      acao_url,
      lida
    ) VALUES (
      lider_record.user_id,
      p_tipo,
      p_titulo,
      p_mensagem,
      p_jovem_id,
      p_acao_url,
      false
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para notificar novo cadastro de jovem
CREATE OR REPLACE FUNCTION trigger_notificar_novo_cadastro()
RETURNS trigger AS $$
BEGIN
  -- Notificar líderes sobre novo cadastro
  PERFORM notificar_lideres(
    'cadastro',
    'Novo Jovem Cadastrado',
    'Um novo jovem foi cadastrado no sistema',
    NEW.id,
    '/jovens/' || NEW.id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para novo cadastro
DROP TRIGGER IF EXISTS trigger_novo_cadastro_jovem ON jovens;
CREATE TRIGGER trigger_novo_cadastro_jovem
  AFTER INSERT ON jovens
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notificar_novo_cadastro();

-- Trigger para notificar nova avaliação
CREATE OR REPLACE FUNCTION trigger_notificar_nova_avaliacao()
RETURNS trigger AS $$
BEGIN
  -- Notificar líderes sobre nova avaliação
  PERFORM notificar_lideres(
    'avaliacao',
    'Nova Avaliação',
    'Um jovem recebeu uma nova avaliação',
    NEW.jovem_id,
    '/jovens/' || NEW.jovem_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para nova avaliação
DROP TRIGGER IF EXISTS trigger_nova_avaliacao ON avaliacoes;
CREATE TRIGGER trigger_nova_avaliacao
  AFTER INSERT ON avaliacoes
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notificar_nova_avaliacao();

-- Trigger para notificar mudança de status
CREATE OR REPLACE FUNCTION trigger_notificar_mudanca_status()
RETURNS trigger AS $$
DECLARE
  status_anterior text;
  status_novo text;
BEGIN
  -- Verificar se o status mudou
  IF OLD.aprovado IS DISTINCT FROM NEW.aprovado THEN
    -- Determinar status anterior e novo
    status_anterior := CASE 
      WHEN OLD.aprovado IS NULL THEN 'Não avaliado'
      WHEN OLD.aprovado = 'pre_aprovado' THEN 'Pré-aprovado'
      WHEN OLD.aprovado = 'aprovado' THEN 'Aprovado'
      ELSE 'Desconhecido'
    END;
    
    status_novo := CASE 
      WHEN NEW.aprovado IS NULL THEN 'Não avaliado'
      WHEN NEW.aprovado = 'pre_aprovado' THEN 'Pré-aprovado'
      WHEN NEW.aprovado = 'aprovado' THEN 'Aprovado'
      ELSE 'Desconhecido'
    END;
    
    -- Notificar líderes sobre mudança de status
    PERFORM notificar_lideres(
      'status_alterado',
      'Status Alterado',
      'Um jovem teve seu status alterado de "' || status_anterior || '" para "' || status_novo || '"',
      NEW.id,
      '/jovens/' || NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para mudança de status
DROP TRIGGER IF EXISTS trigger_mudanca_status_jovem ON jovens;
CREATE TRIGGER trigger_mudanca_status_jovem
  AFTER UPDATE ON jovens
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notificar_mudanca_status();

-- Função para criar lembrete de avaliação (pode ser chamada manualmente ou por job)
CREATE OR REPLACE FUNCTION criar_lembretes_avaliacao()
RETURNS void AS $$
DECLARE
  jovem_record record;
  avaliador_record record;
BEGIN
  -- Buscar jovens sem avaliação há mais de 7 dias
  FOR jovem_record IN
    SELECT j.id, j.nome_completo, j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id
    FROM jovens j
    WHERE j.aprovado IS NULL
    AND j.data_cadastro < NOW() - INTERVAL '7 days'
    AND NOT EXISTS (
      SELECT 1 FROM avaliacoes a WHERE a.jovem_id = j.id
    )
  LOOP
    -- Buscar avaliadores (líderes) para este jovem
    FOR avaliador_record IN
      SELECT user_id FROM obter_lideres_para_notificacao(
        jovem_record.estado_id,
        jovem_record.bloco_id,
        jovem_record.regiao_id,
        jovem_record.igreja_id
      )
    LOOP
      -- Verificar se já existe lembrete recente (últimos 3 dias)
      IF NOT EXISTS (
        SELECT 1 FROM notificacoes n
        WHERE n.destinatario_id = avaliador_record.user_id
        AND n.jovem_id = jovem_record.id
        AND n.tipo = 'lembrete_avaliacao'
        AND n.criado_em > NOW() - INTERVAL '3 days'
      ) THEN
        -- Criar lembrete
        INSERT INTO notificacoes (
          destinatario_id,
          tipo,
          titulo,
          mensagem,
          jovem_id,
          acao_url,
          lida
        ) VALUES (
          avaliador_record.user_id,
          'lembrete_avaliacao',
          'Lembrete de Avaliação',
          'Não esqueça de avaliar ' || jovem_record.nome_completo,
          jovem_record.id,
          '/jovens/' || jovem_record.id,
          false
        );
      END IF;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para limpar notificações antigas (manter apenas últimas 30 dias)
CREATE OR REPLACE FUNCTION limpar_notificacoes_antigas()
RETURNS integer AS $$
DECLARE
  count_deleted integer;
BEGIN
  DELETE FROM notificacoes
  WHERE criado_em < NOW() - INTERVAL '30 days';
  
  GET DIAGNOSTICS count_deleted = ROW_COUNT;
  RETURN count_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

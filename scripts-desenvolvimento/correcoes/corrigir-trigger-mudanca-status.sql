-- Corrigir a função trigger_notificar_mudanca_status para usar tipo válido
CREATE OR REPLACE FUNCTION trigger_notificar_mudanca_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
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
    
    -- Notificar líderes sobre mudança de status (usando tipo válido 'aprovacao')
    PERFORM notificar_lideres(
      'aprovacao',  -- ✅ TIPO VÁLIDO!
      'Status Alterado',
      'Um jovem teve seu status alterado de "' || status_anterior || '" para "' || status_novo || '"',
      NEW.id,
      '/jovens/' || NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$;

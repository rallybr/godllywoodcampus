CREATE TRIGGER trg_notificar_nova_avaliacao
AFTER INSERT ON public.avaliacoes
FOR EACH ROW
EXECUTE FUNCTION public.trigger_notificar_nova_avaliacao();

CREATE TRIGGER trg_notificar_mudanca_status
AFTER UPDATE OF aprovado ON public.jovens
FOR EACH ROW
EXECUTE FUNCTION public.trigger_notificar_mudanca_status();

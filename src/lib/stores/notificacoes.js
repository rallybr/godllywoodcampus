import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { user } from './auth';

// Store para notificações
export const notificacoes = writable([]);
export const notificacoesNaoLidas = writable([]);
export const loading = writable(false);
export const error = writable(null);

// Contador de notificações não lidas
export const contadorNaoLidas = derived(
  notificacoesNaoLidas,
  $notificacoesNaoLidas => $notificacoesNaoLidas.length
);

// Tipos de notificação
export const TIPOS_NOTIFICACAO = {
  NOVO_CADASTRO: 'novo_cadastro',
  AVALIACAO_PENDENTE: 'avaliacao_pendente',
  STATUS_ALTERADO: 'status_alterado',
  LEMBRETE_AVALIACAO: 'lembrete_avaliacao',
  SISTEMA: 'sistema'
};

// Solicitar permissão de notificação (browser only)
export async function solicitarPermissaoNotificacao() {
  try {
    if (typeof window === 'undefined' || typeof Notification === 'undefined') {
      return false;
    }
    if (Notification.permission === 'granted') return true;
    if (Notification.permission !== 'denied') {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }
    return false;
  } catch (e) {
    console.error('Falha ao solicitar permissão de notificação:', e);
    return false;
  }
}

// Carregar notificações do usuário
export async function loadNotificacoes(limit = 20, offset = 0) {
  if (!$user) return;
  
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('notificacoes')
      .select('*')
      .eq('destinatario_id', $user.id)
      .order('criado_em', { ascending: false })
      .range(offset, offset + limit - 1);
    
    if (fetchError) throw fetchError;
    
    notificacoes.set(data || []);
  } catch (err) {
    error.set(err.message);
    console.error('Erro ao carregar notificações:', err);
  } finally {
    loading.set(false);
  }
}

// Carregar notificações não lidas
export async function loadNotificacoesNaoLidas() {
  if (!$user) return;
  
  try {
    const { data, error: fetchError } = await supabase
      .from('notificacoes')
      .select('*')
      .eq('destinatario_id', $user.id)
      .eq('lida', false)
      .order('criado_em', { ascending: false });
    
    if (fetchError) throw fetchError;
    
    notificacoesNaoLidas.set(data || []);
  } catch (err) {
    console.error('Erro ao carregar notificações não lidas:', err);
  }
}

// Marcar notificação como lida
export async function marcarComoLida(notificacaoId) {
  try {
    const { error: updateError } = await supabase
      .from('notificacoes')
      .update({ 
        lida: true, 
        lida_em: new Date().toISOString() 
      })
      .eq('id', notificacaoId)
      .eq('destinatario_id', $user.id);
    
    if (updateError) throw updateError;
    
    // Atualizar store local
    notificacoes.update(notificacoes => 
      notificacoes.map(n => 
        n.id === notificacaoId 
          ? { ...n, lida: true, lida_em: new Date().toISOString() }
          : n
      )
    );
    
    // Remover das não lidas
    notificacoesNaoLidas.update(naoLidas => 
      naoLidas.filter(n => n.id !== notificacaoId)
    );
    
  } catch (err) {
    error.set(err.message);
    console.error('Erro ao marcar notificação como lida:', err);
  }
}

// Marcar todas as notificações como lidas
export async function marcarTodasComoLidas() {
  try {
    const { data, error: updateError } = await supabase
      .from('notificacoes')
      .update({ 
        lida: true, 
        lida_em: new Date().toISOString() 
      })
      .eq('destinatario_id', $user.id)
      .eq('lida', false)
      .select('id');
    
    if (updateError) throw updateError;
    
    // Atualizar store local
    notificacoes.update(notificacoes => 
      notificacoes.map(n => ({ ...n, lida: true, lida_em: new Date().toISOString() }))
    );
    
    // Limpar não lidas
    notificacoesNaoLidas.set([]);
    
    return data?.length || 0; // Retorna quantas foram marcadas
    
  } catch (err) {
    error.set(err.message);
    console.error('Erro ao marcar todas as notificações como lidas:', err);
    return 0;
  }
}

// Criar notificação
export async function criarNotificacao(destinatarioId, tipo, titulo, mensagem, jovemId = null, acaoUrl = null, remetenteId = null) {
  try {
    const { data, error: createError } = await supabase
      .from('notificacoes')
      .insert({
        destinatario_id: destinatarioId,
        tipo: tipo,
        titulo: titulo,
        mensagem: mensagem,
        jovem_id: jovemId,
        acao_url: acaoUrl,
        remetente_id: remetenteId,
        lida: false
      })
      .select()
      .single();
    
    if (createError) throw createError;
    
    return data;
  } catch (err) {
    console.error('Erro ao criar notificação:', err);
    return null;
  }
}

// Notificar novo cadastro de jovem
export async function notificarNovoCadastro(jovem, lideres) {
  const titulo = 'Novo Jovem Cadastrado';
  const mensagem = 'Um novo jovem foi cadastrado no sistema';
  const acaoUrl = `/jovens/${jovem.id}`;
  
  // Criar notificação para cada líder
  const promises = lideres.map(lider => 
    criarNotificacao(
      lider.user_id,
      'cadastro',
      titulo,
      mensagem,
      jovem.id,
      acaoUrl
    )
  );
  
  await Promise.all(promises);
}

// Notificar nova avaliação
export async function notificarNovaAvaliacao(jovem, lideres) {
  const titulo = 'Nova Avaliação';
  const mensagem = 'Um jovem recebeu uma nova avaliação';
  const acaoUrl = `/jovens/${jovem.id}`;
  
  // Criar notificação para cada líder
  const promises = lideres.map(lider => 
    criarNotificacao(
      lider.user_id,
      'avaliacao',
      titulo,
      mensagem,
      jovem.id,
      acaoUrl
    )
  );
  
  await Promise.all(promises);
}

// Notificar mudança de status
export async function notificarMudancaStatus(jovem, statusAnterior, statusNovo, lideres) {
  const titulo = 'Status Alterado';
  const mensagem = `${jovem.nome_completo} teve seu status alterado de "${statusAnterior}" para "${statusNovo}"`;
  const acaoUrl = `/jovens/${jovem.id}`;
  
  // Criar notificação para cada líder
  const promises = lideres.map(lider => 
    criarNotificacao(
      lider.user_id,
      'status_alterado',
      titulo,
      mensagem,
      jovem.id,
      acaoUrl
    )
  );
  
  await Promise.all(promises);
}

// Notificar lembrete de avaliação
export async function notificarLembreteAvaliacao(jovem, avaliador) {
  const titulo = 'Lembrete de Avaliação';
  const mensagem = `Não esqueça de avaliar ${jovem.nome_completo}`;
  const acaoUrl = `/jovens/${jovem.id}`;
  
  return await criarNotificacao(
    avaliador.id,
    'lembrete_avaliacao',
    titulo,
    mensagem,
    jovem.id,
    acaoUrl
  );
}

// Obter ícone para tipo de notificação
export function getIconeNotificacao(tipo) {
  switch (tipo) {
    case 'cadastro':
      return 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z';
    case 'avaliacao':
      return 'M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01';
    case 'status_alterado':
      return 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z';
    case 'lembrete_avaliacao':
      return 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z';
    case 'sistema':
      return 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z';
    default:
      return 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
  }
}

// Obter cor para tipo de notificação
export function getCorNotificacao(tipo) {
  switch (tipo) {
    case 'cadastro':
      return 'text-green-600 bg-green-100';
    case 'avaliacao':
      return 'text-yellow-600 bg-yellow-100';
    case 'status_alterado':
      return 'text-blue-600 bg-blue-100';
    case 'lembrete_avaliacao':
      return 'text-orange-600 bg-orange-100';
    case 'sistema':
      return 'text-gray-600 bg-gray-100';
    default:
      return 'text-gray-600 bg-gray-100';
  }
}

// Formatar data da notificação
export function formatarDataNotificacao(dataString) {
  const data = new Date(dataString);
  const agora = new Date();
  const diffMs = agora - data;
  const diffMinutos = Math.floor(diffMs / (1000 * 60));
  const diffHoras = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDias = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffMinutos < 1) return 'Agora mesmo';
  if (diffMinutos < 60) return `${diffMinutos}min atrás`;
  if (diffHoras < 24) return `${diffHoras}h atrás`;
  if (diffDias < 7) return `${diffDias}d atrás`;
  
  return data.toLocaleDateString('pt-BR');
}

// Inicializar notificações quando usuário fizer login
user.subscribe(async (currentUser) => {
  if (currentUser) {
    await loadNotificacoes();
    await loadNotificacoesNaoLidas();
  } else {
    notificacoes.set([]);
    notificacoesNaoLidas.set([]);
  }
});
import { writable, derived, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { userProfile } from './auth';

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
  NOVO_CADASTRO: 'cadastro',
  AVALIACAO_PENDENTE: 'avaliacao',
  STATUS_ALTERADO: 'aprovacao',
  LEMBRETE_AVALIACAO: 'sistema',
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
  const currentUser = get(userProfile);
  if (!currentUser) return;
  
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('notificacoes')
      .select('*')
      .eq('destinatario_id', currentUser.id)
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
  const currentUser = get(userProfile);
  if (!currentUser) return;
  
  try {
    const { data, error: fetchError } = await supabase
      .from('notificacoes')
      .select('*')
      .eq('destinatario_id', currentUser.id)
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
  const currentUser = get(userProfile);
  if (!currentUser) return;
  try {
    const { error: updateError } = await supabase
      .from('notificacoes')
      .update({ 
        lida: true, 
        lida_em: new Date().toISOString() 
      })
      .eq('id', notificacaoId)
      .eq('destinatario_id', currentUser.id);
    
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
  const currentUser = get(userProfile);
  if (!currentUser) return 0;
  try {
    const { data, error: updateError } = await supabase
      .from('notificacoes')
      .update({ 
        lida: true, 
        lida_em: new Date().toISOString() 
      })
      .eq('destinatario_id', currentUser.id)
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

// ===== Utilidades de DESTINATÁRIOS por jovem =====
/**
 * Retorna lista de IDs de usuários que devem ser notificados sobre um jovem
 */
export async function getDestinatariosByJovem(jovemId) {
  try {
    // Buscar dados do jovem necessários
    const { data: jovem, error: jovemErr } = await supabase
      .from('jovens')
      .select('id, usuario_id, estado_id, bloco_id, regiao_id, igreja_id, nome_completo')
      .eq('id', jovemId)
      .single();
    if (jovemErr) throw jovemErr;

    const nacionais = ['administrador', 'lider_nacional_fju', 'lider_nacional_iurd', 'colaborador'];
    const estaduais = ['lider_estadual_fju', 'lider_estadual_iurd'];
    const blocos = ['lider_bloco_fju', 'lider_bloco_iurd'];
    const regionais = ['lider_regional_iurd'];
    const igrejas = ['lider_igreja_iurd'];

    // Montar filtro OR considerando a localização do jovem
    const orParts = [];
    orParts.push(`nivel.in.(${nacionais.join(',')})`);
    if (jovem.estado_id) orParts.push(`and(nivel.in.(${estaduais.join(',')}),estado_id.eq.${jovem.estado_id})`);
    if (jovem.bloco_id) orParts.push(`and(nivel.in.(${blocos.join(',')}),bloco_id.eq.${jovem.bloco_id})`);
    if (jovem.regiao_id) orParts.push(`and(nivel.in.(${regionais.join(',')}),regiao_id.eq.${jovem.regiao_id})`);
    if (jovem.igreja_id) orParts.push(`and(nivel.in.(${igrejas.join(',')}),igreja_id.eq.${jovem.igreja_id})`);

    let destinatariosIds = new Set();

    if (orParts.length > 0) {
      const { data: usuariosLista, error: usersErr } = await supabase
        .from('usuarios')
        .select('id')
        .or(orParts.join(','));
      if (usersErr) throw usersErr;
      (usuariosLista || []).forEach(u => destinatariosIds.add(u.id));
    }

    // Incluir o usuário associado ao jovem (se existir)
    if (jovem.usuario_id) destinatariosIds.add(jovem.usuario_id);

    return { ids: Array.from(destinatariosIds), jovem };
  } catch (err) {
    console.error('Erro ao resolver destinatários:', err);
    return { ids: [], jovem: null };
  }
}

/**
 * Dispara uma notificação para todos destinatários relacionados a um jovem
 */
export async function notificarEventoJovem(jovemId, tipo, titulo, mensagem, remetenteId = null, acaoUrl = null) {
  const { ids } = await getDestinatariosByJovem(jovemId);
  const targets = ids.filter(id => (remetenteId ? id !== remetenteId : true));
  if (targets.length === 0) return 0;
  const promises = targets.map(id => criarNotificacao(id, tipo, titulo, mensagem, jovemId, acaoUrl || `/jovens/${jovemId}`, remetenteId));
  const results = await Promise.all(promises);
  return results.filter(Boolean).length;
}

// ===== Realtime =====
let notificationsChannel = null;
export function subscribeNotificacoesRealtime() {
  try {
    const currentUser = get(userProfile);
    if (!currentUser) return;
    if (notificationsChannel) return; // evitar múltiplas inscrições

    notificationsChannel = supabase
      .channel('notificacoes-realtime')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notificacoes', filter: `destinatario_id=eq.${currentUser.id}` }, (payload) => {
        const nova = payload.new;
        notificacoes.update(list => [nova, ...list]);
        if (!nova.lida) {
          notificacoesNaoLidas.update(list => [nova, ...list]);
        }
      })
      .subscribe();
  } catch (e) {
    console.warn('Falha ao assinar realtime de notificações:', e);
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
      'aprovacao',
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
    'sistema',
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
      // user-plus
      return 'M12 4.5a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z M16 11v2m0 0v2m0-2h2m-2 0h-2 M4 15.5a5.5 5.5 0 1111 0V17a1 1 0 01-1 1H5a1 1 0 01-1-1v-1.5z';
    case 'avaliacao':
      // clipboard-check
      return 'M9 12l2 2 4-4m-6 8h8a2 2 0 002-2V7a2 2 0 00-2-2h-3l-1-1h-4l-1 1H5a2 2 0 00-2 2v9a2 2 0 002 2h4';
    case 'aprovacao':
      // check-circle
      return 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z';
    case 'sistema':
      // information-circle
      return 'M13 16h-1v-4h-1m1-4h.01M12 2a10 10 0 100 20 10 10 0 000-20z';
    default:
      return 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
  }
}

// Obter cor para tipo de notificação
export function getCorNotificacao(tipo) {
  switch (tipo) {
    case 'cadastro':
      return 'text-indigo-600 bg-indigo-100';
    case 'avaliacao':
      return 'text-yellow-600 bg-yellow-100';
    case 'aprovacao':
      return 'text-green-600 bg-green-100';
    case 'sistema':
      return 'text-blue-600 bg-blue-100';
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
userProfile.subscribe(async (currentUser) => {
  if (currentUser) {
    await loadNotificacoes();
    await loadNotificacoesNaoLidas();
    subscribeNotificacoesRealtime();
  } else {
    notificacoes.set([]);
    notificacoesNaoLidas.set([]);
  }
});
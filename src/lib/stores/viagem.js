import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { createAuditLog } from '$lib/stores/security';
import { notificarEventoJovem } from '$lib/stores/notificacoes';

export const viagens = writable([]);
export const loading = writable(false);
export const error = writable(null);
export const filters = writable({
  edicao_id: '',
  estado_id: '',
  bloco_id: '',
  regiao_id: '',
  igreja_id: '',
  nome_like: '',
  pagou_despesas: '',
  tem_passagem_ida: '',
  tem_passagem_volta: ''
});

export const pagination = writable({
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0
});

// Derived store for filtered viagens
export const filteredViagens = derived(
  [viagens, filters],
  ([$viagens, $filters]) => {
    return $viagens.filter((registro) => {
      // Filtros simples por IDs (campos estão no nível raiz do objeto retornado por processedData)
      if ($filters.edicao_id && registro.edicao_id !== $filters.edicao_id) return false;
      if ($filters.estado_id && registro.estado_id !== $filters.estado_id) return false;
      if ($filters.bloco_id && registro.bloco_id !== $filters.bloco_id) return false;
      if ($filters.regiao_id && registro.regiao_id !== $filters.regiao_id) return false;
      if ($filters.igreja_id && registro.igreja_id !== $filters.igreja_id) return false;

      // Filtro por nome com guarda para undefined
      if ($filters.nome_like) {
        const nome = (registro.nome_completo || '').toLowerCase();
        if (!nome.includes($filters.nome_like.toLowerCase())) return false;
      }

      // Filtros baseados nos dados da viagem (que podem estar ausentes)
      const v = registro.viagem || {};
      if ($filters.pagou_despesas && !!v.pagou_despesas !== ($filters.pagou_despesas === 'true')) return false;
      if ($filters.tem_passagem_ida && !!v.comprovante_passagem_ida !== ($filters.tem_passagem_ida === 'true')) return false;
      if ($filters.tem_passagem_volta && !!v.comprovante_passagem_volta !== ($filters.tem_passagem_volta === 'true')) return false;

      return true;
    });
  }
);

/**
 * Carrega dados de viagem apenas para o jovem logado
 */
export async function loadViagensCardsForJovem() {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('=== CARREGANDO DADOS DE VIAGEM PARA JOVEM ===');
    
    // Verificar se o Supabase está configurado
    if (!supabase) {
      throw new Error('Supabase não está configurado');
    }
    
    // Obter usuário atual
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      throw new Error('Usuário não autenticado');
    }
    
    // Buscar dados do jovem logado
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .select(`
        id,
        nome_completo,
        foto,
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        edicao_id,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .eq('usuario_id', (await supabase.from('usuarios').select('id').eq('id_auth', user.id).single()).data.id)
      .single();
    
    console.log('Erro da consulta (jovem):', fetchError);
    console.log('Dados recebidos (jovem):', data);

    if (fetchError) {
      console.error('Erro ao carregar dados de viagem:', fetchError);
      throw fetchError;
    }

    if (!data) {
      throw new Error('Jovem não encontrado');
    }

    // Buscar dados de viagem do jovem
    const { data: viagemData, error: dvErr } = await supabase
      .from('dados_viagem')
      .select('*')
      .eq('jovem_id', data.id)
      .single();

    if (dvErr && dvErr.code !== 'PGRST116') {
      console.error('Erro buscando dados_viagem:', dvErr);
    }

    // Processar dados finais
    const processedData = [{
      ...data,
      viagem: viagemData || null,
      // Campos derivados úteis para filtros (com guards)
      pagou_despesas: !!viagemData?.pagou_despesas,
      comprovante_pagamento: viagemData?.comprovante_pagamento || null,
      data_passagem_ida: viagemData?.data_passagem_ida || null,
      comprovante_passagem_ida: viagemData?.comprovante_passagem_ida || null,
      data_passagem_volta: viagemData?.data_passagem_volta || null,
      comprovante_passagem_volta: viagemData?.comprovante_passagem_volta || null,
      // Usar dados reais dos relacionamentos ou fallback para N/A
      estado: data.estado || { nome: 'N/A', sigla: 'N/A' },
      bloco: data.bloco || { nome: 'N/A' },
      regiao: data.regiao || { nome: 'N/A' },
      igreja: data.igreja || { nome: 'N/A' },
      edicao: { nome: 'N/A', numero: 1 }
    }];

    console.log('Dados processados (jovem com viagem):', processedData);

    viagens.set(processedData);
    pagination.set({
      page: 1,
      limit: 1,
      total: 1,
      totalPages: 1
    });
    
    console.log('=== DADOS DE VIAGEM DO JOVEM CARREGADOS COM SUCESSO ===');
  } catch (err) {
    console.error('=== ERRO AO CARREGAR DADOS DE VIAGEM DO JOVEM ===');
    console.error('Erro completo:', err);
    error.set(err.message);
  } finally {
    loading.set(false);
  }
}

/**
 * Carrega dados de viagem para cards (jovens + dados_viagem + relacionamentos)
 */
export async function loadViagensCards(page = 1, limit = 20, userId = null, userLevel = null) {
  loading.set(true);
  error.set(null);
  
  try {
    
    // Verificar se o Supabase está configurado
    if (!supabase) {
      throw new Error('Supabase não está configurado');
    }
    
    // Buscar jovens com dados básicos e relacionamentos
    let query = supabase
      .from('jovens')
      .select(`
        id,
        nome_completo,
        foto,
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        edicao_id,
        usuario_id,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `, { count: 'exact' });
    
    // Se for colaborador, filtrar apenas jovens que ele cadastrou
    if (userLevel === 'colaborador' && userId) {
      query = query.eq('usuario_id', userId);
    }
    
    const { data, error: fetchError, count } = await query
      .order('data_cadastro', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    

    if (fetchError) {
      console.error('Erro ao carregar dados de viagem:', fetchError);
      throw fetchError;
    }

    // Passo 2: buscar dados_viagem em lote e anexar
    const ids = (data || []).map(j => j.id);
    let viagemByJovemId = new Map();
    if (ids.length > 0) {
      const { data: viagensRows, error: dvErr } = await supabase
        .from('dados_viagem')
        .select('*')
        .in('jovem_id', ids);

      if (dvErr) {
        console.error('Erro buscando dados_viagem:', dvErr);
      } else {
        for (const row of viagensRows || []) {
          // mantém o primeiro por jovem_id (controle por edição pode ser tratado depois)
          if (!viagemByJovemId.has(row.jovem_id)) {
            viagemByJovemId.set(row.jovem_id, row);
          }
        }
      }
    }

    // Processar dados finais anexando viagem
    const processedData = (data || []).map(jovem => {
      const viagem = viagemByJovemId.get(jovem.id) || null;
      return {
        ...jovem,
        viagem,
        // Campos derivados úteis para filtros (com guards)
        pagou_despesas: !!viagem?.pagou_despesas,
        comprovante_pagamento: viagem?.comprovante_pagamento || null,
        data_passagem_ida: viagem?.data_passagem_ida || null,
        comprovante_passagem_ida: viagem?.comprovante_passagem_ida || null,
        data_passagem_volta: viagem?.data_passagem_volta || null,
        comprovante_passagem_volta: viagem?.comprovante_passagem_volta || null,
        // Usar dados reais dos relacionamentos ou fallback para N/A
        estado: jovem.estado || { nome: 'N/A', sigla: 'N/A' },
        bloco: jovem.bloco || { nome: 'N/A' },
        regiao: jovem.regiao || { nome: 'N/A' },
        igreja: jovem.igreja || { nome: 'N/A' },
        edicao: { nome: 'N/A', numero: 1 }
      };
    });

    console.log('Dados processados (com viagem anexada):', processedData);

    viagens.set(processedData);
    pagination.set({
      page,
      limit,
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
    
    console.log('=== DADOS DE VIAGEM CARREGADOS COM SUCESSO ===');
  } catch (err) {
    console.error('=== ERRO AO CARREGAR DADOS DE VIAGEM ===');
    console.error('Erro completo:', err);
    error.set(err.message);
  } finally {
    loading.set(false);
  }
}

/**
 * Busca dados de viagem específicos de um jovem
 */
export async function getDadosViagemByJovem(jovemId, edicaoId = null) {
  loading.set(true);
  error.set(null);
  
  try {
    let query = supabase
      .from('dados_viagem')
      .select('*')
      .eq('jovem_id', jovemId);
    
    if (edicaoId) {
      query = query.eq('edicao_id', edicaoId);
    }
    
    const { data, error: fetchError } = await query.maybeSingle();
    
    if (fetchError && fetchError.code !== 'PGRST116') {
      throw fetchError;
    }
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading dados viagem:', err);
    return null;
  } finally {
    loading.set(false);
  }
}

/**
 * Remove completamente o card de viagem de um jovem (registro em dados_viagem)
 * e tenta remover também os arquivos do storage relacionados
 */
export async function deleteViagemCard(jovemId, edicaoId = null) {
  try {
    // Buscar o registro para obter URLs antes de deletar
    let query = supabase
      .from('dados_viagem')
      .select('*')
      .eq('jovem_id', jovemId)
      .maybeSingle();

    if (edicaoId) {
      query = supabase
        .from('dados_viagem')
        .select('*')
        .eq('jovem_id', jovemId)
        .eq('edicao_id', edicaoId)
        .maybeSingle();
    }

    const { data: row, error: fetchErr } = await query;
    if (fetchErr && fetchErr.code !== 'PGRST116') {
      throw fetchErr;
    }

    // Tentar excluir arquivos do storage se tivermos URLs públicas
    const pathsToRemove = [];
    const extractPathFromPublicUrl = (url) => {
      if (!url) return null;
      // Supabase public URL padrão contém "/object/public/viagens/"
      const marker = '/object/public/viagens/';
      const idx = url.indexOf(marker);
      if (idx === -1) return null;
      return url.substring(idx + marker.length);
    };

    if (row) {
      const p1 = extractPathFromPublicUrl(row.comprovante_pagamento);
      const p2 = extractPathFromPublicUrl(row.comprovante_passagem_ida);
      const p3 = extractPathFromPublicUrl(row.comprovante_passagem_volta);
      for (const p of [p1, p2, p3]) {
        if (p) pathsToRemove.push(p);
      }
    } else {
      // Caso não tenhamos a linha (ou URLs), ainda podemos tentar por convenção
      const base = `${jovemId}/${edicaoId || ''}`.replace(/\/$/, '');
      // Não sabemos a extensão; não force removals sem path explícito
    }

    if (pathsToRemove.length > 0) {
      try {
        await supabase.storage.from('viagens').remove(pathsToRemove);
      } catch (stErr) {
        console.warn('Falha ao remover arquivos do storage:', stErr?.message || stErr);
      }
    }

    // Excluir o registro em dados_viagem (admin tem permissão pela policy)
    let del = supabase.from('dados_viagem').delete().eq('jovem_id', jovemId);
    if (edicaoId) del = del.eq('edicao_id', edicaoId);
    const { error: delErr } = await del;
    if (delErr) throw delErr;

    // Remover o card da store local
    viagens.update((arr) => arr.filter((j) => j.id !== jovemId));

    return true;
  } catch (err) {
    console.error('Erro ao deletar card de viagem:', err);
    throw err;
  }
}

/**
 * Cria ou atualiza dados de viagem (upsert)
 */
export async function upsertDadosViagem(jovemId, edicaoId, dadosViagem) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('upsertDadosViagem - Dados recebidos:', { jovemId, edicaoId, dadosViagem });
    
    // Obter usuário atual
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      throw new Error('Usuário não autenticado');
    }
    
    // Buscar ID do usuário na tabela usuarios
    const { data: usuario, error: usuarioError } = await supabase
      .from('usuarios')
      .select('id')
      .eq('id_auth', user.id)
      .single();
    
    if (usuarioError) {
      console.error('Erro ao buscar usuário:', usuarioError);
      throw new Error('Erro ao identificar usuário');
    }
    
    // Verificar se já existe registro
    const { data: existing, error: existingError } = await supabase
      .from('dados_viagem')
      .select('id')
      .eq('jovem_id', jovemId)
      .eq('edicao_id', edicaoId)
      .maybeSingle();
    
    if (existingError && existingError.code !== 'PGRST116') {
      console.error('Erro ao verificar registro existente:', existingError);
      throw existingError;
    }
    
    let result;
    if (existing) {
      // Buscar dados antigos para auditoria
      const { data: oldData } = await supabase
        .from('dados_viagem')
        .select('*')
        .eq('id', existing.id)
        .single();
      
      // Update
      const { data, error: updateError } = await supabase
        .from('dados_viagem')
        .update({
          ...dadosViagem,
          usuario_id: usuario.id, // Garantir que usuario_id está definido
          atualizado_em: new Date().toISOString()
        })
        .eq('id', existing.id)
        .select()
        .single();
      
      if (updateError) {
        console.error('Erro no update:', updateError);
        throw updateError;
      }
      result = data;
      
      // Criar log de auditoria para update
      try {
        await createAuditLog(
          'edicao_viagem',
          `Dados de viagem atualizados para jovem ${jovemId}`,
          oldData,
          result
        );
      } catch (logError) {
        console.warn('Erro ao criar log de auditoria:', logError);
      }
    } else {
      // Insert
      const { data, error: insertError } = await supabase
        .from('dados_viagem')
        .insert([{
          jovem_id: jovemId,
          edicao_id: edicaoId,
          usuario_id: usuario.id, // Garantir que usuario_id está definido
          ...dadosViagem,
          data_cadastro: new Date().toISOString()
        }])
        .select()
        .single();
      
      if (insertError) {
        console.error('Erro no insert:', insertError);
        throw insertError;
      }
      result = data;
      
      // Criar log de auditoria para insert
      try {
        await createAuditLog(
          'cadastro_viagem',
          `Dados de viagem criados para jovem ${jovemId}`,
          null,
          result
        );
      } catch (logError) {
        console.warn('Erro ao criar log de auditoria:', logError);
      }
    }
    
    // Recarregar lista
    await loadViagensCards();
    
    // Notificações conforme campos alterados (via RPC com fallback)
    try {
      const eventos = [];
      if (dadosViagem.comprovante_pagamento) eventos.push('Comprovante de pagamento adicionado');
      if (dadosViagem.comprovante_passagem_ida) eventos.push('Passagem de ida anexada');
      if (dadosViagem.comprovante_passagem_volta) eventos.push('Passagem de volta anexada');
      if (dadosViagem.pagou_despesas === false) eventos.push('Comprovante de pagamento removido');
      if (dadosViagem.comprovante_passagem_ida === null) eventos.push('Passagem de ida removida');
      if (dadosViagem.comprovante_passagem_volta === null) eventos.push('Passagem de volta removida');
      if (eventos.length > 0) {
        try {
          await supabase.rpc('notificar_evento_jovem', {
            p_jovem_id: jovemId,
            p_tipo: 'sistema',
            p_titulo: 'Atualização de viagem',
            p_mensagem: eventos.join(' · '),
            p_acao_url: `/jovens/${jovemId}`
          });
        } catch (rpcErr) {
          console.warn('RPC notificar_evento_jovem (viagem) falhou, fallback:', rpcErr);
          await notificarEventoJovem(jovemId, 'sistema', 'Atualização de viagem', eventos.join(' · '));
        }
      }
    } catch (e) {
      console.warn('Falha ao compor notificação de viagem:', e);
    }
    
    return result;
  } catch (err) {
    error.set(err.message);
    console.error('Error upserting dados viagem:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

/**
 * Upload de comprovante para storage
 */
export async function uploadComprovante(jovemId, edicaoId, tipo, file) {
  try {
    console.log('uploadComprovante - Parâmetros:', { jovemId, edicaoId, tipo, fileName: file.name });
    
    // Determinar extensão do arquivo
    const fileExt = file.name.split('.').pop();
    const fileName = `${tipo}.${fileExt}`;
    const filePath = `${jovemId}/${edicaoId}/${fileName}`;
    
    console.log('uploadComprovante - Caminho do arquivo:', filePath);
    
    // Tentar upload diretamente para o bucket 'viagens'
    // Se o bucket não existir ou não tiver permissão, o erro será mais específico
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('viagens')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true
      });
    
    if (uploadError) {
      console.error('Erro no upload:', uploadError);
      
      // Se o erro for relacionado ao bucket não existir, tentar criar uma mensagem mais útil
      if (uploadError.message && uploadError.message.includes('not found')) {
        throw new Error('Bucket "viagens" não encontrado ou sem permissão de acesso. Verifique as configurações do Supabase Storage.');
      }
      
      throw uploadError;
    }
    
    console.log('uploadComprovante - Upload realizado:', uploadData);
    
    // Obter URL pública
    const { data: urlData } = supabase.storage
      .from('viagens')
      .getPublicUrl(filePath);
    
    const publicUrl = urlData.publicUrl;
    console.log('uploadComprovante - URL pública:', publicUrl);
    
    return publicUrl;
  } catch (err) {
    console.error('Error uploading comprovante:', err);
    throw err;
  }
}

/**
 * Upload e salva comprovante de pagamento
 */
export async function uploadComprovantePagamento(jovemId, edicaoId, file) {
  try {
    const url = await uploadComprovante(jovemId, edicaoId, 'pagamento', file);
    
    await upsertDadosViagem(jovemId, edicaoId, {
      pagou_despesas: true,
      comprovante_pagamento: url
    });
    
    return url;
  } catch (err) {
    console.error('Error uploading comprovante pagamento:', err);
    throw err;
  }
}

/**
 * Upload e salva comprovante de passagem de ida
 */
export async function uploadComprovanteIda(jovemId, edicaoId, dataPassagem, file) {
  try {
    const url = await uploadComprovante(jovemId, edicaoId, 'ida', file);
    
    await upsertDadosViagem(jovemId, edicaoId, {
      data_passagem_ida: dataPassagem,
      comprovante_passagem_ida: url
    });
    
    return url;
  } catch (err) {
    console.error('Error uploading comprovante ida:', err);
    throw err;
  }
}

/**
 * Upload e salva comprovante de passagem de volta
 */
export async function uploadComprovanteVolta(jovemId, edicaoId, dataPassagem, file) {
  try {
    const url = await uploadComprovante(jovemId, edicaoId, 'volta', file);
    
    await upsertDadosViagem(jovemId, edicaoId, {
      data_passagem_volta: dataPassagem,
      comprovante_passagem_volta: url
    });
    
    return url;
  } catch (err) {
    console.error('Error uploading comprovante volta:', err);
    throw err;
  }
}

/**
 * Remove comprovante (marca como não pago/removido)
 */
export async function removeComprovante(jovemId, edicaoId, tipo) {
  try {
    const updates = {};
    
    switch (tipo) {
      case 'pagamento':
        updates.pagou_despesas = false;
        updates.comprovante_pagamento = null;
        break;
      case 'ida':
        updates.data_passagem_ida = null;
        updates.comprovante_passagem_ida = null;
        break;
      case 'volta':
        updates.data_passagem_volta = null;
        updates.comprovante_passagem_volta = null;
        break;
    }
    
    await upsertDadosViagem(jovemId, edicaoId, updates);
  } catch (err) {
    console.error('Error removing comprovante:', err);
    throw err;
  }
}

/**
 * Busca edição ativa
 */
export async function getEdicaoAtiva() {
  try {
    console.log('🔍 Buscando edição ativa...');
    const { data, error } = await supabase
      .from('edicoes')
      .select('*')
      .eq('ativa', true)
      .maybeSingle(); // Usar maybeSingle() em vez de single() para evitar erro quando não há registros
    
    if (error) {
      console.error('❌ Erro ao buscar edição ativa:', error);
      throw error;
    }
    
    if (data) {
      console.log('✅ Edição ativa encontrada:', data);
    } else {
      console.log('⚠️ Nenhuma edição ativa encontrada');
    }
    return data;
  } catch (err) {
    console.error('❌ Error loading edicao ativa:', err);
    return null;
  }
}

/**
 * Limpa filtros
 */
export function clearFilters() {
  filters.set({
    edicao_id: '',
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: '',
    nome_like: '',
    pagou_despesas: '',
    tem_passagem_ida: '',
    tem_passagem_volta: ''
  });
}

/**
 * Formata data para exibição
 */
export function formatDataViagem(dataISO) {
  if (!dataISO) return '';
  
  try {
    const data = new Date(dataISO);
    return data.toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (err) {
    return dataISO;
  }
}

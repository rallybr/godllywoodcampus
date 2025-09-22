import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { createAuditLog } from '$lib/stores/security';

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
export async function loadViagensCards(page = 1, limit = 20) {
  loading.set(true);
  error.set(null);
  
  try {
    
    // Verificar se o Supabase está configurado
    if (!supabase) {
      throw new Error('Supabase não está configurado');
    }
    
    // Buscar jovens com dados básicos e relacionamentos
    const { data, error: fetchError, count } = await supabase
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
      `, { count: 'exact' })
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
      .single();
    
    if (error) {
      console.error('❌ Erro ao buscar edição ativa:', error);
      throw error;
    }
    
    console.log('✅ Edição ativa encontrada:', data);
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

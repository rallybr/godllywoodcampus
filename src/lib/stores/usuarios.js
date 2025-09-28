import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

export const usuarios = writable([]);
export const loading = writable(false);
export const error = writable(null);
export const roles = writable([]);

// Função para buscar todos os usuários (apenas administradores)
export async function buscarUsuarios() {
  loading.set(true);
  error.set(null);

  try {
    const { data, error: fetchError } = await supabase
      .from('usuarios')
      .select(`
        id,
        id_auth,
        foto,
        nome,
        sexo,
        nivel,
        email,
        ativo,
        criado_em,
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        estado_bandeira
      `)
      .order('nome', { ascending: true });

    if (fetchError) throw fetchError;

    usuarios.set(data || []);
    return data || [];
  } catch (err) {
    error.set(err.message);
    console.error('Error fetching usuarios:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para buscar usuários por nome (autocomplete)
export async function buscarUsuariosPorNome(nome) {
  try {
    const { data, error: fetchError } = await supabase
      .from('usuarios')
      .select(`
        id,
        id_auth,
        foto,
        nome,
        sexo,
        nivel,
        email,
        ativo,
        criado_em,
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        estado_bandeira
      `)
      .ilike('nome', `%${nome}%`)
      .order('nome', { ascending: true })
      .limit(10);

    if (fetchError) throw fetchError;

    return data || [];
  } catch (err) {
    console.error('Error searching usuarios:', err);
    return [];
  }
}

// Função para buscar um usuário específico
export async function buscarUsuarioPorId(usuarioId) {
  try {
    const { data, error: fetchError } = await supabase
      .from('usuarios')
      .select(`
        id,
        id_auth,
        foto,
        nome,
        sexo,
        nivel,
        email,
        ativo,
        criado_em,
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        estado_bandeira,
        estados!estado_id (
          nome,
          bandeira
        ),
        blocos!bloco_id (
          nome
        ),
        regioes!regiao_id (
          nome
        ),
        igrejas!igreja_id (
          nome
        )
      `)
      .eq('id', usuarioId)
      .single();

    if (fetchError) throw fetchError;

    return data;
  } catch (err) {
    console.error('Error fetching usuario:', err);
    throw err;
  }
}

// Função para atualizar usuário
export async function atualizarUsuario(usuarioId, dadosAtualizacao) {
  loading.set(true);
  error.set(null);

  try {
    // Usar RPC para atualização com verificação de permissões
    const { data, error: rpcError } = await supabase.rpc('atualizar_usuario_admin', {
      p_usuario_id: usuarioId,
      p_nome: dadosAtualizacao.nome || null,
      p_email: dadosAtualizacao.email || null,
      p_sexo: dadosAtualizacao.sexo || null,
      p_foto: dadosAtualizacao.foto || null,
      p_nivel: dadosAtualizacao.nivel || null,
      p_ativo: dadosAtualizacao.ativo !== undefined ? dadosAtualizacao.ativo : null
    });

    if (rpcError) throw rpcError;

    if (!data.success) {
      throw new Error(data.error || 'Erro ao atualizar usuário');
    }

    // Atualizar a lista de usuários
    await buscarUsuarios();

    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating usuario:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para fazer upload de foto
export async function uploadFotoUsuario(usuarioId, arquivo) {
  try {
    // Gerar nome único para o arquivo
    const extensao = arquivo.name.split('.').pop();
    const nomeArquivo = `${usuarioId}-${Date.now()}.${extensao}`;
    
    // Upload para o bucket de fotos de usuários
    const { data, error: uploadError } = await supabase.storage
      .from('fotos_usuarios')
      .upload(nomeArquivo, arquivo, {
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) throw uploadError;

    // Obter URL pública
    const { data: urlData } = supabase.storage
      .from('fotos_usuarios')
      .getPublicUrl(nomeArquivo);

    return urlData.publicUrl;
  } catch (err) {
    console.error('Error uploading foto:', err);
    throw err;
  }
}

// Função para deletar foto antiga
export async function deletarFotoAntiga(urlFoto) {
  try {
    if (!urlFoto) return;

    // Extrair nome do arquivo da URL
    const nomeArquivo = urlFoto.split('/').pop();
    
    const { error: deleteError } = await supabase.storage
      .from('fotos_usuarios')
      .remove([nomeArquivo]);

    if (deleteError) {
      console.warn('Error deleting old foto:', deleteError);
    }
  } catch (err) {
    console.warn('Error deleting old foto:', err);
  }
}

// Função para buscar papéis disponíveis
export async function buscarPapeisDisponiveis() {
  try {
    const { data, error } = await supabase.rpc('buscar_papeis_disponiveis');
    if (error) throw error;
    return data || [];
  } catch (err) {
    console.error('Erro ao buscar papéis:', err);
    throw err;
  }
}

// Função para buscar papéis de um usuário
export async function buscarPapeisUsuario(usuarioId) {
  try {
    const { data, error } = await supabase.rpc('buscar_papeis_usuario', {
      p_usuario_id: usuarioId
    });
    if (error) throw error;
    return data || [];
  } catch (err) {
    console.error('Erro ao buscar papéis do usuário:', err);
    throw err;
  }
}

// Função para atribuir papel a usuário
export async function atribuirPapelUsuario(usuarioId, roleId, estadoId = null, blocoId = null, regiaoId = null, igrejaId = null) {
  try {
    const { data, error } = await supabase.rpc('atribuir_papel_usuario', {
      p_usuario_id: usuarioId,
      p_role_id: roleId,
      p_estado_id: estadoId,
      p_bloco_id: blocoId,
      p_regiao_id: regiaoId,
      p_igreja_id: igrejaId
    });
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Erro ao atribuir papel:', err);
    throw err;
  }
}

// Função para remover papel de usuário
export async function removerPapelUsuario(papelId) {
  try {
    const { data, error } = await supabase.rpc('remover_papel_usuario', {
      p_papel_id: papelId
    });
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Erro ao remover papel:', err);
    throw err;
  }
}

// Função para carregar papéis (roles)
export async function loadRoles() {
  try {
    const { data, error } = await supabase.rpc('buscar_papeis_disponiveis');
    if (error) throw error;
    roles.set(data || []);
    return data || [];
  } catch (err) {
    console.error('Erro ao carregar papéis:', err);
    throw err;
  }
}

// Função para registrar último acesso
export async function registrarUltimoAcesso() {
  try {
    const { data, error } = await supabase.rpc('registrar_ultimo_acesso');
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Erro ao registrar último acesso:', err);
    throw err;
  }
}

// Função para buscar usuários com último acesso
export async function buscarUsuariosComUltimoAcesso() {
  try {
    const { data, error } = await supabase.rpc('buscar_usuarios_com_ultimo_acesso');
    if (error) throw error;
    return data || [];
  } catch (err) {
    console.error('Erro ao buscar usuários com último acesso:', err);
    throw err;
  }
}

// Função para obter estatísticas de acesso
export async function obterEstatisticasAcesso() {
  try {
    const { data, error } = await supabase.rpc('estatisticas_acesso_usuarios');
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Erro ao obter estatísticas de acesso:', err);
    throw err;
  }
}
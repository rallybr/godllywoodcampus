import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { withCache, CACHE_KEYS } from '$lib/utils/cache';

// Stores para usuários e roles
export const usuarios = writable([]);
export const roles = writable([]);
export const userRoles = writable([]);
export const loading = writable(false);
export const error = writable(null);

// Função para carregar usuários
export async function loadUsuarios() {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('usuarios')
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome),
        user_roles!user_roles_user_id_fkey(
          id,
          role_id,
          ativo,
          role:roles(id, nome, slug)
        )
      `)
      .order('nome');
    
    if (fetchError) throw fetchError;
    
    usuarios.set(data || []);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading usuarios:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para carregar roles
export async function loadRoles() {
  loading.set(true);
  error.set(null);
  
  try {
    const data = await withCache(
      CACHE_KEYS.ROLES,
      async () => {
        const { data, error: fetchError } = await supabase
          .from('roles')
          .select('*')
          .order('nivel_hierarquico');
        
        if (fetchError) throw fetchError;
        return data || [];
      },
      60 // Cache por 1 hora (roles raramente mudam)
    );
    
    roles.set(data);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading roles:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para carregar user roles
export async function loadUserRoles() {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('user_roles')
      .select(`
        *,
        usuario:usuarios!user_roles_user_id_fkey(nome, email),
        role:roles(nome, slug, nivel_hierarquico),
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .order('criado_em', { ascending: false });
    
    if (fetchError) throw fetchError;
    
    userRoles.set(data || []);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading user roles:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para criar usuário
export async function createUsuario(usuarioData) {
  loading.set(true);
  error.set(null);
  
  try {
    // Validar dados obrigatórios
    if (!usuarioData.nome) throw new Error('Nome é obrigatório');
    if (!usuarioData.email) throw new Error('Email é obrigatório');
    if (!usuarioData.role_id) throw new Error('Papel é obrigatório');
    
    // Criar usuário no Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: usuarioData.email,
      password: usuarioData.password || 'temp123456'
    });
    
    if (authError) throw authError;
    
    // Verificar se o usuário foi criado
    if (!authData.user) {
      throw new Error('Falha ao criar usuário no sistema de autenticação');
    }
    
    // Criar usuário na tabela usuarios
    const { data, error: createError } = await supabase
      .from('usuarios')
      .insert([{
        id_auth: authData.user.id,
        email: usuarioData.email,
        nome: usuarioData.nome,
        foto: usuarioData.foto,
        sexo: usuarioData.sexo,
        nivel: usuarioData.nivel || 'usuario',
        estado_bandeira: usuarioData.estado_bandeira,
        estado_id: usuarioData.estado_id,
        bloco_id: usuarioData.bloco_id,
        regiao_id: usuarioData.regiao_id,
        igreja_id: usuarioData.igreja_id,
        ativo: true
      }])
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .single();
    
    if (createError) throw createError;
    
    // Criar user role (opcional - não falha se der erro)
    try {
      await createUserRole(data.id, usuarioData.role_id, usuarioData);
    } catch (roleError) {
      console.warn('Erro ao criar user role (não crítico):', roleError);
      // Não falha o cadastro se der erro no role
    }
    
    // Reload data
    await loadUsuarios();
    await loadUserRoles();
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error creating usuario:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para criar user role
export async function createUserRole(userId, roleId, locationData) {
  try {
    const { data, error: createError } = await supabase
      .from('user_roles')
      .insert([{
        user_id: userId,
        role_id: roleId,
        estado_id: locationData.estado_id,
        bloco_id: locationData.bloco_id,
        regiao_id: locationData.regiao_id,
        igreja_id: locationData.igreja_id,
        ativo: true
      }])
      .select()
      .single();
    
    if (createError) throw createError;
    
    return data;
  } catch (err) {
    console.error('Error creating user role:', err);
    throw err;
  }
}

// Função para atualizar usuário
export async function updateUsuario(id, updates) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: updateError } = await supabase
      .from('usuarios')
      .update(updates)
      .eq('id', id)
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .single();
    
    if (updateError) throw updateError;
    
    // Update local store
    usuarios.update(usuarios => 
      usuarios.map(u => u.id === id ? data : u)
    );
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating usuario:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para transferir liderança
export async function transferirLideranca(usuarioAtualId, novoUsuarioId, localizacao) {
  loading.set(true);
  error.set(null);
  
  try {
    // Desativar role atual
    const { error: deactivateError } = await supabase
      .from('user_roles')
      .update({ ativo: false })
      .eq('user_id', usuarioAtualId)
      .eq('estado_id', localizacao.estado_id)
      .eq('bloco_id', localizacao.bloco_id)
      .eq('regiao_id', localizacao.regiao_id)
      .eq('igreja_id', localizacao.igreja_id);
    
    if (deactivateError) throw deactivateError;
    
    // Ativar role do novo usuário
    const { error: activateError } = await supabase
      .from('user_roles')
      .update({ ativo: true })
      .eq('user_id', novoUsuarioId)
      .eq('estado_id', localizacao.estado_id)
      .eq('bloco_id', localizacao.bloco_id)
      .eq('regiao_id', localizacao.regiao_id)
      .eq('igreja_id', localizacao.igreja_id);
    
    if (activateError) throw activateError;
    
    // Criar log de auditoria
    try {
      await supabase.rpc('criar_log_auditoria', {
        p_jovem_id: null,
        p_acao: 'transferencia_lideranca',
        p_detalhe: `Liderança transferida de ${usuarioAtualId} para ${novoUsuarioId}`,
        p_dados_novos: JSON.stringify({
          usuario_anterior: usuarioAtualId,
          usuario_novo: novoUsuarioId,
          localizacao: localizacao
        })
      });
    } catch (logError) {
      console.warn('Erro ao criar log de auditoria:', logError);
    }
    
    // Reload data
    await loadUserRoles();
    
  } catch (err) {
    error.set(err.message);
    console.error('Error transferring leadership:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para obter usuários por localização
export function getUsuariosByLocation(estadoId, blocoId, regiaoId, igrejaId) {
  return usuarios.filter(usuario => {
    if (estadoId && usuario.estado_id !== estadoId) return false;
    if (blocoId && usuario.bloco_id !== blocoId) return false;
    if (regiaoId && usuario.regiao_id !== regiaoId) return false;
    if (igrejaId && usuario.igreja_id !== igrejaId) return false;
    return true;
  });
}

// Função para obter roles por nível
export function getRolesByLevel(nivel) {
  return roles.filter(role => role.nivel_hierarquico >= nivel);
}

// Função para atualizar user role
export async function updateUserRole(userId, roleId, locationData) {
  loading.set(true);
  error.set(null);
  
  try {
    // Desativar todos os roles ativos do usuário
    const { error: deactivateError } = await supabase
      .from('user_roles')
      .update({ ativo: false })
      .eq('user_id', userId)
      .eq('ativo', true);
    
    if (deactivateError) throw deactivateError;
    
    // Verificar se já existe um user_role para este papel
    const { data: existingRole } = await supabase
      .from('user_roles')
      .select('*')
      .eq('user_id', userId)
      .eq('role_id', roleId)
      .single();
    
    if (existingRole) {
      // Ativar o role existente
      const { error: activateError } = await supabase
        .from('user_roles')
        .update({ ativo: true })
        .eq('id', existingRole.id);
      
      if (activateError) throw activateError;
    } else {
      // Criar novo user_role
      const { error: createError } = await supabase
        .from('user_roles')
        .insert({
          user_id: userId,
          role_id: roleId,
          estado_id: locationData?.estado_id,
          bloco_id: locationData?.bloco_id,
          regiao_id: locationData?.regiao_id,
          igreja_id: locationData?.igreja_id,
          ativo: true
        });
      
      if (createError) throw createError;
    }
    
    // Reload data
    await loadUserRoles();
    
  } catch (err) {
    error.set(err.message);
    console.error('Error updating user role:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para carregar dados iniciais
export async function loadInitialData() {
  await Promise.all([
    loadUsuarios(),
    loadRoles(),
    loadUserRoles()
  ]);
}

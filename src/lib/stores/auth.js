import { writable, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { registrarUltimoAcesso } from './usuarios';
import { initializeAccessLevels } from './niveis-acesso';
import { initializeCadastroCheck, marcarJovemNaoCadastrado } from './jovem-cadastro';
import { browser } from '$app/environment';

export const user = writable(null);
export const loading = writable(true);
export const userProfile = writable(null);

let profileLoadPromise = null;
let profileLoadUserId = null;

/** Aguarda o perfil do usuário estar disponível (útil para queries com escopo). */
export function waitForUserProfile(timeoutMs = 15000) {
  const current = get(userProfile);
  if (current?.id && current?.nivel) {
    return Promise.resolve(current);
  }
  if (!get(user)) {
    return Promise.resolve(null);
  }

  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      unsub();
      resolve(get(userProfile));
    }, timeoutMs);

    const unsub = userProfile.subscribe((profile) => {
      if (profile?.id && profile?.nivel) {
        clearTimeout(timeout);
        unsub();
        resolve(profile);
      }
    });
  });
}

// Initialize auth state
if (browser) {
  let initialSessionHandled = false;

  function scheduleProfileLoad(userId) {
    setTimeout(async () => {
      try {
        await loadUserProfile(userId);
      } finally {
        loading.set(false);
      }
    }, 0);
  }

  function handleAuthSession(event, session) {
    user.set(session?.user ?? null);

    if (session?.user) {
      if (event === 'INITIAL_SESSION' || event === 'SIGNED_IN' || event === 'USER_UPDATED') {
        scheduleProfileLoad(session.user.id);
        return;
      }
      loading.set(false);
      return;
    }

    userProfile.set(null);
    if (event === 'SIGNED_OUT') {
      marcarJovemNaoCadastrado();
    }
    loading.set(false);
  }

  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'INITIAL_SESSION') {
      if (initialSessionHandled) return;
      initialSessionHandled = true;
    }
    handleAuthSession(event, session);
  });

  // Fallback caso INITIAL_SESSION demore ou não dispare
  supabase.auth.getSession().then(({ data: { session } }) => {
    if (!initialSessionHandled) {
      initialSessionHandled = true;
      handleAuthSession('INITIAL_SESSION', session);
    }
  });

  // Segurança: nunca deixar loading infinito
  setTimeout(() => {
    if (get(loading)) {
      console.warn('Timeout na inicialização do auth — liberando tela.');
      loading.set(false);
    }
  }, 5000);
}

export async function loadUserProfile(userId) {
  if (profileLoadUserId === userId && profileLoadPromise) {
    return profileLoadPromise;
  }

  profileLoadUserId = userId;
  profileLoadPromise = _loadUserProfile(userId).finally(() => {
    profileLoadPromise = null;
    profileLoadUserId = null;
  });

  return profileLoadPromise;
}

function runProfileSideEffects() {
  // Não bloqueia a UI: roles/cadastro/último acesso rodam em paralelo após o perfil
  void Promise.allSettled([
    initializeAccessLevels(),
    initializeCadastroCheck(),
    registrarUltimoAcesso().catch((err) => {
      console.warn('Erro ao registrar último acesso:', err);
    })
  ]);
}

async function _loadUserProfile(userId) {
  try {
    const { data, error } = await supabase
      .from('usuarios')
      .select(`
        *,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('id_auth', userId)
      .single();

    if (error) {
      // Se não encontrar o usuário na tabela, cria um perfil mínimo automaticamente
      if (error.code === 'PGRST116') {
        try {
          const { data: authUserData } = await supabase.auth.getUser();
          const authUser = authUserData?.user;
          if (authUser) {
            const { error: insertErr } = await supabase
              .from('usuarios')
              .insert([{
                id_auth: authUser.id,
                email: authUser.email,
                nome: authUser.email?.split('@')[0] || '',
                nivel: 'jovem',
                criado_em: new Date().toISOString(),
                ativo: true
              }]);
            if (insertErr) throw insertErr;
            // Tentar carregar novamente
            const { data: created, error: reloadErr } = await supabase
              .from('usuarios')
              .select(`
                *,
                user_roles!user_roles_user_id_fkey (
                  *,
                  roles (*)
                )
              `)
              .eq('id_auth', userId)
              .single();
            if (!reloadErr) {
              userProfile.set(created);
              runProfileSideEffects();
              return;
            }
          }
        } catch (e) {
          console.error('Falha ao criar perfil mínimo em usuarios:', e);
        }
        userProfile.set(null);
        return;
      }
      throw error;
    }
    userProfile.set(data);
    runProfileSideEffects();
  } catch (error) {
    console.error('Error loading user profile:', error);
    console.error('Error details:', JSON.stringify(error, null, 2));
    userProfile.set(null);
  }
}

export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  
  if (data?.user) {
    await loadUserProfile(data.user.id);
  }
  
  return { data, error };
}

export async function signUp(email, password) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password
  });
  
  return { data, error };
}

export async function updateProfile(profileData) {
  const { data: { user: currentUser } } = await supabase.auth.getUser();
  
  if (!currentUser) {
    throw new Error('Usuário não autenticado');
  }
  
  // Create user profile in usuarios table
  const { data, error } = await supabase
    .from('usuarios')
    .insert([{
      id_auth: currentUser.id,
      email: currentUser.email,
      nome: profileData.nome,
      telefone: profileData.telefone,
      data_nascimento: profileData.data_nascimento,
      sexo: profileData.sexo,
      estado_civil: profileData.estado_civil,
      escolaridade: profileData.escolaridade,
      profissao: profileData.profissao,
      igreja: profileData.igreja,
      pastor: profileData.pastor,
      tempo_igreja: profileData.tempo_igreja,
      condicao: profileData.condicao,
      batizado_aguas: profileData.batizado_aguas,
      batizado_es: profileData.batizado_es,
      data_batismo_aguas: profileData.data_batismo_aguas,
      data_batismo_es: profileData.data_batismo_es,
      responsabilidades: profileData.responsabilidades,
      observacoes: profileData.observacoes,
      ativo: true,
      data_cadastro: new Date().toISOString()
    }])
    .select()
    .single();
  
  if (error) throw error;
  
  // Load the updated profile
  await loadUserProfile(currentUser.id);
  
  return data;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  user.set(null);
  userProfile.set(null);
  marcarJovemNaoCadastrado();
  return { error };
}

export function hasRole(roleSlug) {
  return (profile) => {
    if (!profile?.nivel) return false;
    return profile.nivel === roleSlug;
  };
}

export function hasPermission(permission) {
  return (profile) => {
    if (!profile?.nivel) return false;
    
    // Admin has all permissions
    if (profile.nivel === 'administrador') {
      return true;
    }
    
    // Check specific permissions based on role
    const role = profile.nivel;
    switch (permission) {
      case 'view_jovens':
        return ['administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
      case 'edit_jovens':
        return ['administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
      case 'manage_users':
        return ['administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador'].includes(role);
      case 'view_user_profiles':
        return ['administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador'].includes(role);
      case 'view_reports':
        return ['administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
      default:
        return false;
    }
  };
}

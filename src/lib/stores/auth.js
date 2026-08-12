import { writable, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
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

const PROFILE_SELECT = `
  *,
  user_roles!user_roles_user_id_fkey (
    *,
    roles (*)
  )
`;

// Initialize auth state
if (browser) {
  let bootstrapped = false;

  function releaseLoading() {
    if (get(loading)) {
      loading.set(false);
    }
  }

  function scheduleProfileLoad(userId) {
    // Fora do callback do onAuthStateChange para evitar deadlock do auth-js
    queueMicrotask(() => {
      void loadUserProfile(userId);
    });
  }

  function bootstrapSession(session) {
    if (bootstrapped) return;
    bootstrapped = true;

    user.set(session?.user ?? null);
    // Libera a UI imediatamente — o perfil carrega em paralelo
    releaseLoading();

    if (session?.user) {
      scheduleProfileLoad(session.user.id);
    } else {
      userProfile.set(null);
    }
  }

  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'INITIAL_SESSION') {
      bootstrapSession(session);
      return;
    }

    user.set(session?.user ?? null);

    if (event === 'SIGNED_IN' || event === 'USER_UPDATED') {
      releaseLoading();
      if (session?.user) {
        scheduleProfileLoad(session.user.id);
      }
      return;
    }

    if (event === 'SIGNED_OUT') {
      userProfile.set(null);
      void import('./jovem-cadastro')
        .then((m) => m.marcarJovemNaoCadastrado())
        .catch(() => {});
      releaseLoading();
      return;
    }

    // TOKEN_REFRESHED e demais eventos: só garante que a tela não fica presa
    releaseLoading();
  });

  // Fallback se INITIAL_SESSION não disparar (versões antigas / edge cases)
  setTimeout(() => {
    if (bootstrapped) {
      releaseLoading();
      return;
    }

    supabase.auth
      .getSession()
      .then(({ data: { session } }) => {
        bootstrapSession(session);
      })
      .catch((err) => {
        console.warn('Falha ao obter sessão inicial:', err);
        bootstrapped = true;
        releaseLoading();
      });
  }, 150);

  // Segurança: nunca deixar loading infinito
  setTimeout(() => {
    if (get(loading)) {
      console.warn('Timeout na inicialização do auth — liberando tela.');
      bootstrapped = true;
      loading.set(false);
    }
  }, 3000);
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
  // Imports dinâmicos evitam dependência circular auth ↔ niveis-acesso / jovem-cadastro
  void Promise.allSettled([
    import('./niveis-acesso').then((m) => m.initializeAccessLevels()),
    import('./jovem-cadastro').then((m) => m.initializeCadastroCheck()),
    import('./usuarios').then((m) =>
      m.registrarUltimoAcesso().catch((err) => {
        console.warn('Erro ao registrar último acesso:', err);
      })
    )
  ]);
}

async function fetchUsuarioByAuthId(userId) {
  return supabase
    .from('usuarios')
    .select(PROFILE_SELECT)
    .eq('id_auth', userId)
    .single();
}

async function _loadUserProfile(userId) {
  try {
    const { data, error } = await fetchUsuarioByAuthId(userId);

    if (error) {
      // Se não encontrar o usuário na tabela, cria um perfil mínimo automaticamente
      if (error.code === 'PGRST116') {
        try {
          const currentUser = get(user);
          const authUser =
            currentUser?.id === userId
              ? currentUser
              : (await supabase.auth.getUser()).data?.user;

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

            const { data: created, error: reloadErr } = await fetchUsuarioByAuthId(userId);
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
  try {
    const { marcarJovemNaoCadastrado } = await import('./jovem-cadastro');
    marcarJovemNaoCadastrado();
  } catch {
    // ignore
  }
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

import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { browser } from '$app/environment';

export const user = writable(null);
export const loading = writable(true);
export const userProfile = writable(null);

// Initialize auth state
if (browser) {
  // Get initial session
  supabase.auth.getSession().then(({ data: { session } }) => {
    user.set(session?.user ?? null);
    loading.set(false);
  });

  // Listen for auth changes
  supabase.auth.onAuthStateChange((event, session) => {
    user.set(session?.user ?? null);
    loading.set(false);
    
    if (session?.user) {
      loadUserProfile(session.user.id);
    } else {
      userProfile.set(null);
    }
  });
}

export async function loadUserProfile(userId) {
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
  return { error };
}

export function hasRole(roleSlug) {
  return (profile) => {
    if (!profile?.user_roles) return false;
    return profile.user_roles.some(ur => ur.roles?.slug === roleSlug && ur.ativo);
  };
}

export function hasPermission(permission) {
  return (profile) => {
    if (!profile?.user_roles) return false;
    
    // Admin has all permissions
    if (profile.user_roles.some(ur => ur.roles?.slug === 'administrador' && ur.ativo)) {
      return true;
    }
    
    // Check specific permissions based on role
    return profile.user_roles.some(ur => {
      if (!ur.ativo) return false;
      
      const role = ur.roles?.slug;
      switch (permission) {
        case 'view_jovens':
          return ['administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                  'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
        case 'edit_jovens':
          return ['administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                  'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
        case 'manage_users':
          return ['administrador', 'colaborador'].includes(role);
        case 'view_reports':
          return ['administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 
                  'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd'].includes(role);
        default:
          return false;
      }
    });
  };
}

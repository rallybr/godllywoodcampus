import { writable, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { userProfile } from './auth';

// Store para verificar se o jovem já se cadastrou
export const jovemJaCadastrado = writable(false);
export const loadingCadastro = writable(false);
export const errorCadastro = writable(null);

/**
 * Verificar se o jovem já se cadastrou
 */
export async function verificarCadastroJovem() {
  const profile = get(userProfile);
  
  if (!profile || profile.nivel !== 'jovem') {
    jovemJaCadastrado.set(false);
    return false;
  }
  
  loadingCadastro.set(true);
  errorCadastro.set(null);
  
  try {
    const { data, error } = await supabase
      .from('jovens')
      .select('id')
      .eq('usuario_id', profile.id)
      .single();
    
    if (error && error.code !== 'PGRST116') {
      throw error;
    }
    
    const cadastrado = !error && data;
    jovemJaCadastrado.set(cadastrado);
    return cadastrado;
    
  } catch (err) {
    errorCadastro.set(err.message);
    console.error('Erro ao verificar cadastro do jovem:', err);
    jovemJaCadastrado.set(false);
    return false;
  } finally {
    loadingCadastro.set(false);
  }
}

/**
 * Marcar jovem como cadastrado (após cadastro bem-sucedido)
 */
export function marcarJovemCadastrado() {
  jovemJaCadastrado.set(true);
}

/**
 * Marcar jovem como não cadastrado (após logout ou mudança de usuário)
 */
export function marcarJovemNaoCadastrado() {
  jovemJaCadastrado.set(false);
}

/**
 * Inicializar verificação de cadastro
 */
export async function initializeCadastroCheck() {
  const profile = get(userProfile);
  if (profile) {
    await verificarCadastroJovem();
  }
}

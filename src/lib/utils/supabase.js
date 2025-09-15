import { createClient } from '@supabase/supabase-js';
import { browser } from '$app/environment';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://seu-projeto.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sua-chave-anonima-aqui';

console.log('Supabase URL:', supabaseUrl);
console.log('Supabase Key:', supabaseAnonKey ? 'Presente' : 'Ausente');

if (!supabaseUrl || !supabaseAnonKey || supabaseUrl === 'https://seu-projeto.supabase.co') {
  console.error('⚠️ CONFIGURAÇÃO DO SUPABASE NECESSÁRIA');
  console.error('Crie um arquivo .env.local na raiz do projeto com:');
  console.error('VITE_SUPABASE_URL=https://seu-projeto.supabase.co');
  console.error('VITE_SUPABASE_ANON_KEY=sua-chave-anonima-aqui');
  console.error('Para encontrar essas informações:');
  console.error('1. Acesse https://supabase.com/dashboard');
  console.error('2. Selecione seu projeto');
  console.error('3. Vá em Settings > API');
  console.error('4. Copie a URL e a chave anônima');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: browser
  }
});

// Helper functions
export const auth = {
  async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    return { data, error };
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    return { error };
  },

  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },

  async resetPassword(email) {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email);
    return { data, error };
  }
};

export const storage = {
  async uploadFile(bucket, path, file) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(path, file);
    return { data, error };
  },

  async getPublicUrl(bucket, path) {
    const { data } = supabase.storage
      .from(bucket)
      .getPublicUrl(path);
    return data.publicUrl;
  },

  async deleteFile(bucket, path) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .remove([path]);
    return { data, error };
  }
};

import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { userProfile } from './auth';

// Stores para configurações
export const configuracoesPerfil = writable({
  nome: '',
  email: '',
  telefone: '',
  foto: '',
  bio: '',
  cargo: '',
  departamento: ''
});

export const configuracoesSistema = writable({
  tema: 'light', // light, dark, auto
  idioma: 'pt-BR',
  fuso_horario: 'America/Sao_Paulo',
  formato_data: 'DD/MM/YYYY',
  formato_hora: '24h', // 12h, 24h
  itens_por_pagina: 20,
  notificacoes_email: true,
  notificacoes_push: true,
  notificacoes_som: true
});

export const configuracoesNotificacoes = writable({
  email_cadastros: true,
  email_avaliacoes: true,
  email_status: true,
  email_lembretes: true,
  email_relatorios: false,
  push_cadastros: true,
  push_avaliacoes: true,
  push_status: true,
  push_lembretes: true,
  push_relatorios: false,
  frequencia_lembretes: 'diario', // diario, semanal, mensal
  horario_lembretes: '09:00'
});

export const configuracoesSeguranca = writable({
  autenticacao_2f: false,
  sessao_duracao: 24, // horas
  login_automatico: false,
  notificar_logins: true,
  backup_automatico: true,
  criptografia_dados: true
});

// Estados de loading e erro
export const loadingConfiguracoes = writable(false);
export const errorConfiguracoes = writable(null);

// Carregar configurações do usuário
export async function carregarConfiguracoes() {
  loadingConfiguracoes.set(true);
  errorConfiguracoes.set(null);
  
  try {
    // Aplicar valores padrão para todas as configurações
    configuracoesPerfil.set({
      nome: '',
      email: '',
      telefone: '',
      foto: '',
      bio: '',
      cargo: '',
      departamento: ''
    });
    
    const configuracoesPadrao = {
      tema: 'light',
      idioma: 'pt-BR',
      fuso_horario: 'America/Sao_Paulo',
      formato_data: 'DD/MM/YYYY',
      formato_hora: '24h',
      itens_por_pagina: 20,
      notificacoes_email: true,
      notificacoes_push: true,
      notificacoes_som: true
    };
    
    configuracoesSistema.set(configuracoesPadrao);
    
    const notificacoesPadrao = {
      email_cadastros: true,
      email_avaliacoes: true,
      email_status: true,
      email_lembretes: true,
      email_relatorios: false,
      push_cadastros: true,
      push_avaliacoes: true,
      push_status: true,
      push_lembretes: true,
      push_relatorios: false,
      frequencia_lembretes: 'diario',
      horario_lembretes: '09:00'
    };
    
    configuracoesNotificacoes.set(notificacoesPadrao);
    
    const segurancaPadrao = {
      autenticacao_2f: false,
      sessao_duracao: 24,
      login_automatico: false,
      notificar_logins: true,
      backup_automatico: true,
      criptografia_dados: true
    };
    
    configuracoesSeguranca.set(segurancaPadrao);
    
  } catch (err) {
    errorConfiguracoes.set(err.message);
    console.error('Erro ao carregar configurações:', err);
  } finally {
    loadingConfiguracoes.set(false);
  }
}

// Salvar configurações de perfil
export async function salvarConfiguracoesPerfil(dados) {
  loadingConfiguracoes.set(true);
  errorConfiguracoes.set(null);
  
  try {
    // Por enquanto, apenas atualizar o store local
    configuracoesPerfil.set(dados);
    
    // Simular delay de salvamento
    await new Promise(resolve => setTimeout(resolve, 1000));
    
  } catch (err) {
    errorConfiguracoes.set(err.message);
    console.error('Erro ao salvar configurações de perfil:', err);
  } finally {
    loadingConfiguracoes.set(false);
  }
}

// Salvar configurações do sistema
export async function salvarConfiguracoesSistema(dados) {
  loadingConfiguracoes.set(true);
  errorConfiguracoes.set(null);
  
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Usuário não autenticado');
    
    // Salvar cada configuração individualmente
    const promises = Object.entries(dados).map(([chave, valor]) => {
      return supabase
        .from('configuracoes_sistema')
        .upsert({
          chave,
          valor: typeof valor === 'object' ? JSON.stringify(valor) : valor,
          descricao: `Configuração de ${chave}`,
          categoria: 'usuario'
        });
    });
    
    const results = await Promise.all(promises);
    
    // Verificar se houve algum erro
    const errors = results.filter(result => result.error);
    if (errors.length > 0) {
      throw errors[0].error;
    }
    
    configuracoesSistema.set(dados);
    
  } catch (err) {
    errorConfiguracoes.set(err.message);
    console.error('Erro ao salvar configurações do sistema:', err);
  } finally {
    loadingConfiguracoes.set(false);
  }
}

// Salvar configurações de notificações
export async function salvarConfiguracoesNotificacoes(dados) {
  loadingConfiguracoes.set(true);
  errorConfiguracoes.set(null);
  
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Usuário não autenticado');
    
    // Salvar cada configuração individualmente
    const promises = Object.entries(dados).map(([chave, valor]) => {
      return supabase
        .from('configuracoes_sistema')
        .upsert({
          chave,
          valor: typeof valor === 'object' ? JSON.stringify(valor) : valor,
          descricao: `Configuração de notificação: ${chave}`,
          categoria: 'notificacoes'
        });
    });
    
    const results = await Promise.all(promises);
    
    // Verificar se houve algum erro
    const errors = results.filter(result => result.error);
    if (errors.length > 0) {
      throw errors[0].error;
    }
    
    configuracoesNotificacoes.set(dados);
    
  } catch (err) {
    errorConfiguracoes.set(err.message);
    console.error('Erro ao salvar configurações de notificações:', err);
  } finally {
    loadingConfiguracoes.set(false);
  }
}

// Salvar configurações de segurança
export async function salvarConfiguracoesSeguranca(dados) {
  loadingConfiguracoes.set(true);
  errorConfiguracoes.set(null);
  
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Usuário não autenticado');
    
    // Salvar cada configuração individualmente
    const promises = Object.entries(dados).map(([chave, valor]) => {
      return supabase
        .from('configuracoes_sistema')
        .upsert({
          chave,
          valor: typeof valor === 'object' ? JSON.stringify(valor) : valor,
          descricao: `Configuração de segurança: ${chave}`,
          categoria: 'seguranca'
        });
    });
    
    const results = await Promise.all(promises);
    
    // Verificar se houve algum erro
    const errors = results.filter(result => result.error);
    if (errors.length > 0) {
      throw errors[0].error;
    }
    
    configuracoesSeguranca.set(dados);
    
  } catch (err) {
    errorConfiguracoes.set(err.message);
    console.error('Erro ao salvar configurações de segurança:', err);
  } finally {
    loadingConfiguracoes.set(false);
  }
}

// Aplicar tema
export function aplicarTema(tema) {
  if (tema === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
}

// Formatar data
export function formatarData(data, formato = 'DD/MM/YYYY') {
  const d = new Date(data);
  const day = d.getDate().toString().padStart(2, '0');
  const month = (d.getMonth() + 1).toString().padStart(2, '0');
  const year = d.getFullYear();
  
  if (formato === 'DD/MM/YYYY') {
    return `${day}/${month}/${year}`;
  } else if (formato === 'MM/DD/YYYY') {
    return `${month}/${day}/${year}`;
  } else if (formato === 'YYYY-MM-DD') {
    return `${year}-${month}-${day}`;
  }
  
  return d.toLocaleDateString();
}

// Formatar hora
export function formatarHora(data, formato = '24h') {
  const d = new Date(data);
  
  if (formato === '24h') {
    return d.toLocaleTimeString('pt-BR', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: false 
    });
  } else {
    return d.toLocaleTimeString('pt-BR', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: true 
    });
  }
}

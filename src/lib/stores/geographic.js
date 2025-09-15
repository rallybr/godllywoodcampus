import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Stores para dados geográficos
export const estados = writable([]);
export const blocos = writable([]);
export const regioes = writable([]);
export const igrejas = writable([]);
export const edicoes = writable([]);

// Loading states
export const loadingEstados = writable(false);
export const loadingBlocos = writable(false);
export const loadingRegioes = writable(false);
export const loadingIgrejas = writable(false);
export const loadingEdicoes = writable(false);

// Função para carregar estados
export async function loadEstados() {
  loadingEstados.set(true);
  try {
    const { data, error } = await supabase
      .from('estados')
      .select('*')
      .order('nome');
    
    if (error) throw error;
    estados.set(data || []);
  } catch (error) {
    console.error('Erro ao carregar estados:', error);
  } finally {
    loadingEstados.set(false);
  }
}

// Função para carregar blocos por estado
export async function loadBlocos(estadoId) {
  if (!estadoId) {
    blocos.set([]);
    return;
  }
  
  console.log('loadBlocos chamada com estadoId:', estadoId);
  loadingBlocos.set(true);
  try {
    const { data, error } = await supabase
      .from('blocos')
      .select('*')
      .eq('estado_id', estadoId)
      .order('nome');
    
    console.log('Resultado da consulta blocos:', { data, error });
    
    if (error) throw error;
    blocos.set(data || []);
    console.log('Blocos definidos no store:', data);
  } catch (error) {
    console.error('Erro ao carregar blocos:', error);
  } finally {
    loadingBlocos.set(false);
  }
}

// Função para carregar regiões por bloco
export async function loadRegioes(blocoId) {
  if (!blocoId) {
    regioes.set([]);
    return;
  }
  
  loadingRegioes.set(true);
  try {
    const { data, error } = await supabase
      .from('regioes')
      .select('*')
      .eq('bloco_id', blocoId)
      .order('nome');
    
    if (error) throw error;
    regioes.set(data || []);
  } catch (error) {
    console.error('Erro ao carregar regiões:', error);
  } finally {
    loadingRegioes.set(false);
  }
}

// Função para carregar igrejas por região
export async function loadIgrejas(regiaoId) {
  if (!regiaoId) {
    igrejas.set([]);
    return;
  }
  
  loadingIgrejas.set(true);
  try {
    const { data, error } = await supabase
      .from('igrejas')
      .select('*')
      .eq('regiao_id', regiaoId)
      .order('nome');
    
    if (error) throw error;
    igrejas.set(data || []);
  } catch (error) {
    console.error('Erro ao carregar igrejas:', error);
  } finally {
    loadingIgrejas.set(false);
  }
}

// Função para carregar edições
export async function loadEdicoes() {
  loadingEdicoes.set(true);
  try {
    const { data, error } = await supabase
      .from('edicoes')
      .select('*')
      .order('numero');
    
    if (error) throw error;
    edicoes.set(data || []);
  } catch (error) {
    console.error('Erro ao carregar edições:', error);
  } finally {
    loadingEdicoes.set(false);
  }
}

// Função para limpar dados hierárquicos
export function clearHierarchy() {
  blocos.set([]);
  regioes.set([]);
  igrejas.set([]);
}

// Função para carregar dados iniciais
export async function loadInitialData() {
  // Importar loadRoles dinamicamente para evitar dependência circular
  const { loadRoles } = await import('./usuarios.js');
  
  await Promise.all([
    loadEstados(),
    loadEdicoes(),
    loadRoles()
  ]);
}

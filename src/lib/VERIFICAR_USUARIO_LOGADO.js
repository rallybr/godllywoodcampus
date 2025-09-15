// =====================================================
// VERIFICAR USUÁRIO LOGADO E PERMISSÕES
// =====================================================
// Data: 2024-12-19
// Objetivo: Verificar se o usuário está logado e tem permissões

import { supabase } from '$lib/utils/supabase';

export async function verificarUsuarioLogado() {
  try {
    console.log('=== VERIFICAÇÃO DO USUÁRIO ===');
    
    // Verificar se há sessão ativa
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('❌ Erro ao verificar sessão:', sessionError);
      return { logado: false, erro: sessionError.message };
    }
    
    if (!session) {
      console.log('❌ Usuário não está logado');
      return { logado: false, erro: 'Usuário não está logado' };
    }
    
    console.log('✅ Usuário logado:', session.user.email);
    console.log('ID do usuário:', session.user.id);
    
    // Verificar dados do usuário na tabela usuarios
    const { data: usuario, error: usuarioError } = await supabase
      .from('usuarios')
      .select(`
        *,
        user_roles!user_roles_user_id_fkey!inner(
          *,
          roles(*)
        )
      `)
      .eq('id_auth', session.user.id)
      .single();
    
    if (usuarioError) {
      console.error('❌ Erro ao buscar usuário:', usuarioError);
      return { logado: true, usuario: null, erro: usuarioError.message };
    }
    
    if (!usuario) {
      console.log('❌ Usuário não encontrado na tabela usuarios');
      return { logado: true, usuario: null, erro: 'Usuário não encontrado' };
    }
    
    console.log('✅ Usuário encontrado:', usuario.nome);
    console.log('Roles do usuário:', usuario.user_roles);
    
    // Verificar se tem role de administrador ou colaborador
    const temPermissao = usuario.user_roles.some(ur => 
      ur.roles.slug === 'administrador' || ur.roles.slug === 'colaborador'
    );
    
    console.log('Tem permissão para cadastrar jovens:', temPermissao);
    
    return {
      logado: true,
      usuario: usuario,
      temPermissao: temPermissao,
      roles: usuario.user_roles.map(ur => ur.roles.slug)
    };
    
  } catch (error) {
    console.error('❌ Erro geral na verificação:', error);
    return { logado: false, erro: error.message };
  }
}

// Função para testar inserção simples
export async function testarInsercaoSimples() {
  try {
    console.log('=== TESTE DE INSERÇÃO SIMPLES ===');
    
    // Primeiro, buscar IDs reais das tabelas
    console.log('Buscando IDs reais das tabelas...');
    
    // Buscar primeiro estado
    const { data: estados, error: estadosError } = await supabase
      .from('estados')
      .select('id')
      .limit(1);
    
    if (estadosError || !estados || estados.length === 0) {
      console.error('❌ Erro ao buscar estados:', estadosError);
      return { sucesso: false, erro: 'Não foi possível buscar estados' };
    }
    
    const estadoId = estados[0].id;
    console.log('Estado encontrado:', estadoId);
    
    // Buscar primeiro bloco
    const { data: blocos, error: blocosError } = await supabase
      .from('blocos')
      .select('id')
      .limit(1);
    
    if (blocosError || !blocos || blocos.length === 0) {
      console.error('❌ Erro ao buscar blocos:', blocosError);
      return { sucesso: false, erro: 'Não foi possível buscar blocos' };
    }
    
    const blocoId = blocos[0].id;
    console.log('Bloco encontrado:', blocoId);
    
    // Buscar primeira região
    const { data: regioes, error: regioesError } = await supabase
      .from('regioes')
      .select('id')
      .limit(1);
    
    if (regioesError || !regioes || regioes.length === 0) {
      console.error('❌ Erro ao buscar regiões:', regioesError);
      return { sucesso: false, erro: 'Não foi possível buscar regiões' };
    }
    
    const regiaoId = regioes[0].id;
    console.log('Região encontrada:', regiaoId);
    
    // Buscar primeira igreja
    const { data: igrejas, error: igrejasError } = await supabase
      .from('igrejas')
      .select('id')
      .limit(1);
    
    if (igrejasError || !igrejas || igrejas.length === 0) {
      console.error('❌ Erro ao buscar igrejas:', igrejasError);
      return { sucesso: false, erro: 'Não foi possível buscar igrejas' };
    }
    
    const igrejaId = igrejas[0].id;
    console.log('Igreja encontrada:', igrejaId);
    
    // Buscar primeira edição
    const { data: edicoes, error: edicoesError } = await supabase
      .from('edicoes')
      .select('id')
      .limit(1);
    
    if (edicoesError || !edicoes || edicoes.length === 0) {
      console.error('❌ Erro ao buscar edições:', edicoesError);
      return { sucesso: false, erro: 'Não foi possível buscar edições' };
    }
    
    const edicaoId = edicoes[0].id;
    console.log('Edição encontrada:', edicaoId);
    
    // Dados de teste com IDs reais (apenas colunas que existem)
    const dadosTeste = {
      nome_completo: 'Teste Debug',
      data_nasc: '2000-01-01',
      whatsapp: '11999999999',
      estado_civil: 'solteiro',
      edicao: '2024', // Coluna obrigatória
      estado_id: estadoId,
      bloco_id: blocoId,
      regiao_id: regiaoId,
      igreja_id: igrejaId,
      edicao_id: edicaoId,
      idade: 24,
      data_cadastro: new Date().toISOString(),
      aprovado: null // Enum, não string
    };
    
    console.log('Tentando inserir dados de teste:', dadosTeste);
    
    const { data, error } = await supabase
      .from('jovens')
      .insert([dadosTeste])
      .select()
      .single();
    
    if (error) {
      console.error('❌ Erro na inserção de teste:', error);
      console.error('❌ Detalhes do erro:', JSON.stringify(error, null, 2));
      return { sucesso: false, erro: error };
    }
    
    console.log('✅ Inserção de teste bem-sucedida:', data);
    return { sucesso: true, data: data };
    
  } catch (error) {
    console.error('❌ Erro geral no teste:', error);
    return { sucesso: false, erro: error.message };
  }
}
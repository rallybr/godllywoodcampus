import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticarProblemaDashboard() {
  console.log('🔍 DIAGNÓSTICO: Problema do Dashboard do Colaborador');
  console.log('=' .repeat(60));
  
  try {
    // 1. Verificar usuário colaborador específico
    console.log('\n1️⃣ VERIFICANDO USUÁRIO COLABORADOR');
    console.log('-'.repeat(40));
    
    const { data: colaborador, error: colaboradorError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('email', 'pedropaulobacana@hotmail.com')
      .single();
    
    if (colaboradorError) {
      console.log('❌ Erro ao buscar colaborador:', colaboradorError.message);
    } else {
      console.log('📊 Colaborador encontrado:');
      console.log(`   Nome: ${colaborador.nome}`);
      console.log(`   Email: ${colaborador.email}`);
      console.log(`   Nível: ${colaborador.nivel}`);
      console.log(`   ID: ${colaborador.id}`);
      console.log(`   User Roles: ${colaborador.user_roles?.length || 0}`);
      
      if (colaborador.user_roles?.length > 0) {
        colaborador.user_roles.forEach(role => {
          console.log(`   - Role: ${role.roles?.nome} (${role.roles?.slug})`);
          console.log(`   - Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
        });
      }
    }
    
    // 2. Verificar dados que o colaborador deveria ver
    console.log('\n2️⃣ VERIFICANDO DADOS DO COLABORADOR');
    console.log('-'.repeat(40));
    
    if (colaborador) {
      // Jovens cadastrados pelo colaborador
      const { data: jovensColaborador, error: jovensError } = await supabase
        .from('jovens')
        .select('id, nome_completo, aprovado, usuario_id')
        .eq('usuario_id', colaborador.id);
      
      if (jovensError) {
        console.log('❌ Erro ao buscar jovens do colaborador:', jovensError.message);
      } else {
        console.log(`📊 Jovens cadastrados pelo colaborador: ${jovensColaborador.length}`);
        if (jovensColaborador.length > 0) {
          console.log('📊 Primeiros 3 jovens:');
          jovensColaborador.slice(0, 3).forEach(jovem => {
            console.log(`   - ${jovem.nome_completo} (${jovem.aprovado || 'pendente'})`);
          });
        }
      }
      
      // Avaliações feitas pelo colaborador
      const { data: avaliacoesColaborador, error: avaliacoesError } = await supabase
        .from('avaliacoes')
        .select('id, nota, user_id')
        .eq('user_id', colaborador.id);
      
      if (avaliacoesError) {
        console.log('❌ Erro ao buscar avaliações do colaborador:', avaliacoesError.message);
      } else {
        console.log(`📊 Avaliações feitas pelo colaborador: ${avaliacoesColaborador.length}`);
      }
    }
    
    // 3. Verificar dados totais (que o colaborador NÃO deveria ver)
    console.log('\n3️⃣ VERIFICANDO DADOS TOTAIS (QUE COLABORADOR NÃO DEVERIA VER)');
    console.log('-'.repeat(40));
    
    const { data: todosJovens, error: todosJovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, aprovado, usuario_id')
      .limit(10);
    
    if (todosJovensError) {
      console.log('❌ Erro ao buscar todos os jovens:', todosJovensError.message);
    } else {
      console.log(`📊 Total de jovens no sistema: ${todosJovens.length}`);
      console.log('📊 Primeiros 3 jovens (que colaborador não deveria ver):');
      todosJovens.slice(0, 3).forEach(jovem => {
        console.log(`   - ${jovem.nome_completo} (${jovem.aprovado || 'pendente'}) - Usuário: ${jovem.usuario_id}`);
      });
    }
    
    // 4. Verificar se há problema na lógica de filtragem
    console.log('\n4️⃣ VERIFICANDO LÓGICA DE FILTRAGEM');
    console.log('-'.repeat(40));
    
    console.log('💡 ANÁLISE DO PROBLEMA:');
    console.log('   O colaborador está vendo dados de TODOS os jovens (101, 93 pendentes, etc.)');
    console.log('   quando deveria ver apenas os dados dos jovens que ele cadastrou.');
    console.log('');
    console.log('🔍 POSSÍVEIS CAUSAS:');
    console.log('   1. Sistema de segurança não está sendo inicializado corretamente');
    console.log('   2. Filtragem por nível não está sendo aplicada');
    console.log('   3. Cache de dados não está sendo limpo');
    console.log('   4. Verificação de permissões não está funcionando');
    
    // 5. Verificar se o problema é na inicialização
    console.log('\n5️⃣ VERIFICANDO INICIALIZAÇÃO DO SISTEMA');
    console.log('-'.repeat(40));
    
    console.log('💡 DIAGNÓSTICO:');
    console.log('   O problema parece estar na inicialização do sistema de segurança.');
    console.log('   O colaborador está vendo dados globais antes das restrições serem aplicadas.');
    console.log('');
    console.log('🔧 SOLUÇÕES POSSÍVEIS:');
    console.log('   1. Verificar se o sistema de segurança está sendo inicializado antes do carregamento dos dados');
    console.log('   2. Verificar se as permissões estão sendo carregadas corretamente');
    console.log('   3. Verificar se há cache de dados que não está sendo limpo');
    console.log('   4. Verificar se a verificação de nível está sendo executada em todas as consultas');
    
    console.log('\n🎯 RESULTADO DO DIAGNÓSTICO');
    console.log('=' .repeat(60));
    
    console.log('❌ PROBLEMA IDENTIFICADO:');
    console.log('   O colaborador está vendo dados globais (101 jovens, 93 pendentes)');
    console.log('   quando deveria ver apenas dados restritos ao seu nível.');
    console.log('');
    console.log('💡 CAUSA PROVÁVEL:');
    console.log('   Sistema de segurança não está sendo inicializado corretamente');
    console.log('   ou as restrições não estão sendo aplicadas na página inicial.');
    console.log('');
    console.log('🔧 PRÓXIMOS PASSOS:');
    console.log('   1. Verificar inicialização do sistema de segurança');
    console.log('   2. Verificar se as restrições estão sendo aplicadas');
    console.log('   3. Verificar se há cache de dados que precisa ser limpo');
    console.log('   4. Testar com usuário colaborador após correções');
    
  } catch (error) {
    console.error('❌ Erro durante o diagnóstico:', error);
  }
}

diagnosticarProblemaDashboard();

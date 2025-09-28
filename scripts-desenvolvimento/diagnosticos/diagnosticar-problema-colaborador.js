import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticarProblemaColaborador() {
  console.log('🔍 DIAGNÓSTICO: Problema do Colaborador vendo todos os dados');
  console.log('=' .repeat(60));
  
  try {
    // 1. Verificar usuários colaboradores
    console.log('\n1️⃣ VERIFICANDO USUÁRIOS COLABORADORES');
    console.log('-'.repeat(40));
    
    const { data: colaboradores, error: colaboradoresError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('nivel', 'colaborador');
    
    if (colaboradoresError) {
      console.log('❌ Erro ao buscar colaboradores:', colaboradoresError.message);
    } else {
      console.log(`📊 Colaboradores encontrados: ${colaboradores.length}`);
      colaboradores.forEach((colab, index) => {
        console.log(`\n${index + 1}. ${colab.nome} (${colab.email})`);
        console.log(`   Nível: ${colab.nivel}`);
        console.log(`   User Roles: ${colab.user_roles?.length || 0}`);
        if (colab.user_roles?.length > 0) {
          colab.user_roles.forEach(role => {
            console.log(`   - Role: ${role.roles?.nome} (${role.roles?.slug})`);
            console.log(`   - Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
          });
        }
      });
    }
    
    // 2. Verificar estrutura de níveis hierárquicos
    console.log('\n2️⃣ VERIFICANDO NÍVEIS HIERÁRQUICOS');
    console.log('-'.repeat(40));
    
    const { data: roles, error: rolesError } = await supabase
      .from('roles')
      .select('*')
      .order('nivel_hierarquico');
    
    if (rolesError) {
      console.log('❌ Erro ao buscar roles:', rolesError.message);
    } else {
      console.log('📊 Roles disponíveis:');
      roles.forEach(role => {
        console.log(`   - ${role.nome} (${role.slug}): Nível ${role.nivel_hierarquico}`);
      });
    }
    
    // 3. Verificar se há problemas na lógica de acesso
    console.log('\n3️⃣ VERIFICANDO LÓGICA DE ACESSO');
    console.log('-'.repeat(40));
    
    // Simular a lógica do frontend
    const niveisHierarquicos = {
      'ADMINISTRADOR': 1,
      'COLABORADOR': 2,
      'LIDER_NACIONAL_IURD': 3,
      'LIDER_NACIONAL_FJU': 3,
      'LIDER_ESTADUAL_IURD': 4,
      'LIDER_ESTADUAL_FJU': 4,
      'LIDER_BLOCO_IURD': 5,
      'LIDER_BLOCO_FJU': 5,
      'LIDER_REGIONAL_IURD': 6,
      'LIDER_IGREJA_IURD': 7
    };
    
    console.log('📊 Níveis hierárquicos definidos:');
    Object.entries(niveisHierarquicos).forEach(([role, level]) => {
      console.log(`   - ${role}: ${level}`);
    });
    
    // 4. Verificar se há problemas na inicialização
    console.log('\n4️⃣ VERIFICANDO PROBLEMAS DE INICIALIZAÇÃO');
    console.log('-'.repeat(40));
    
    console.log('💡 POSSÍVEIS CAUSAS DO PROBLEMA:');
    console.log('   1. Cache de dados no frontend');
    console.log('   2. Inicialização assíncrona não aguardada');
    console.log('   3. Estado de segurança não sendo atualizado');
    console.log('   4. Verificação de permissões não sendo executada');
    
    // 5. Verificar dados de teste
    console.log('\n5️⃣ VERIFICANDO DADOS DE TESTE');
    console.log('-'.repeat(40));
    
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(5);
    
    if (jovensError) {
      console.log('❌ Erro ao buscar jovens:', jovensError.message);
    } else {
      console.log(`📊 Jovens encontrados: ${jovens.length}`);
      if (jovens.length > 0) {
        console.log('📊 Primeiro jovem:', jovens[0]);
      }
    }
    
    console.log('\n🎯 DIAGNÓSTICO CONCLUÍDO');
    console.log('=' .repeat(60));
    
    console.log('\n💡 SOLUÇÕES POSSÍVEIS:');
    console.log('   1. Verificar se o sistema de segurança está sendo inicializado corretamente');
    console.log('   2. Verificar se as permissões estão sendo carregadas antes da renderização');
    console.log('   3. Verificar se há cache de dados que não está sendo limpo');
    console.log('   4. Verificar se a verificação de permissões está sendo executada em todas as páginas');
    
  } catch (error) {
    console.error('❌ Erro durante o diagnóstico:', error);
  }
}

diagnosticarProblemaColaborador();

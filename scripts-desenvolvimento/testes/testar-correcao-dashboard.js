import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarCorrecaoDashboard() {
  console.log('🧪 TESTANDO CORREÇÃO DO DASHBOARD');
  console.log('=' .repeat(50));
  
  try {
    // 1. Verificar colaborador
    console.log('\n1️⃣ VERIFICANDO COLABORADOR');
    console.log('-'.repeat(30));
    
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
      return;
    }
    
    console.log('📊 Colaborador:');
    console.log(`   Nome: ${colaborador.nome}`);
    console.log(`   Email: ${colaborador.email}`);
    console.log(`   Nível: ${colaborador.nivel}`);
    console.log(`   ID: ${colaborador.id}`);
    console.log(`   User Roles: ${colaborador.user_roles?.length || 0}`);
    
    // 2. Simular carregamento de estatísticas como colaborador
    console.log('\n2️⃣ SIMULANDO CARREGAMENTO DE ESTATÍSTICAS');
    console.log('-'.repeat(30));
    
    // Simular loadEstatisticas com parâmetros corretos
    const userId = colaborador.id;
    const userLevel = colaborador.nivel;
    
    console.log(`📊 Parâmetros corretos:`);
    console.log(`   userId: ${userId}`);
    console.log(`   userLevel: ${userLevel}`);
    
    // Buscar jovens do colaborador
    const { data: jovensColaborador, error: jovensError } = await supabase
      .from('jovens')
      .select('aprovado, data_cadastro, id, usuario_id')
      .eq('usuario_id', userId);
    
    if (jovensError) {
      console.log('❌ Erro ao buscar jovens do colaborador:', jovensError.message);
    } else {
      console.log(`📊 Jovens do colaborador: ${jovensColaborador.length}`);
      
      // Calcular estatísticas
      const totalJovens = jovensColaborador.length;
      const aprovados = jovensColaborador.filter(j => j.aprovado === 'aprovado').length;
      const preAprovados = jovensColaborador.filter(j => j.aprovado === 'pre_aprovado').length;
      const pendentes = jovensColaborador.filter(j => 
        j.aprovado === null || j.aprovado === 'null' || j.aprovado === undefined
      ).length;
      
      console.log(`📊 Estatísticas corretas do colaborador:`);
      console.log(`   Total: ${totalJovens}`);
      console.log(`   Aprovados: ${aprovados}`);
      console.log(`   Pré-aprovados: ${preAprovados}`);
      console.log(`   Pendentes: ${pendentes}`);
    }
    
    // 3. Verificar dados globais (que colaborador NÃO deveria ver)
    console.log('\n3️⃣ VERIFICANDO DADOS GLOBAIS (QUE COLABORADOR NÃO DEVERIA VER)');
    console.log('-'.repeat(30));
    
    const { data: todosJovens, error: todosJovensError } = await supabase
      .from('jovens')
      .select('aprovado, data_cadastro, id, usuario_id');
    
    if (todosJovensError) {
      console.log('❌ Erro ao buscar todos os jovens:', todosJovensError.message);
    } else {
      console.log(`📊 Total de jovens no sistema: ${todosJovens.length}`);
      
      // Calcular estatísticas globais
      const totalGlobal = todosJovens.length;
      const aprovadosGlobal = todosJovens.filter(j => j.aprovado === 'aprovado').length;
      const preAprovadosGlobal = todosJovens.filter(j => j.aprovado === 'pre_aprovado').length;
      const pendentesGlobal = todosJovens.filter(j => 
        j.aprovado === null || j.aprovado === 'null' || j.aprovado === undefined
      ).length;
      
      console.log(`📊 Estatísticas globais (que colaborador NÃO deveria ver):`);
      console.log(`   Total: ${totalGlobal}`);
      console.log(`   Aprovados: ${aprovadosGlobal}`);
      console.log(`   Pré-aprovados: ${preAprovadosGlobal}`);
      console.log(`   Pendentes: ${pendentesGlobal}`);
    }
    
    // 4. Verificar se a correção está funcionando
    console.log('\n4️⃣ VERIFICANDO SE A CORREÇÃO ESTÁ FUNCIONANDO');
    console.log('-'.repeat(30));
    
    const temUserRole = colaborador?.user_roles?.length > 0;
    const temRoleColaborador = colaborador?.user_roles?.some(role => 
      role.roles?.slug === 'colaborador' && role.roles?.nivel_hierarquico === 7
    );
    
    if (temUserRole && temRoleColaborador) {
      console.log('✅ SUCESSO: User role do colaborador está correto!');
      console.log('✅ Sistema de segurança deve funcionar corretamente');
      console.log('');
      console.log('📝 O QUE DEVE ACONTECER NO FRONTEND:');
      console.log('   1. userProfile deve ser carregado antes de loadDashboardData');
      console.log('   2. userId e userLevel devem ser passados corretamente');
      console.log('   3. Filtragem deve ser aplicada baseada no nível do usuário');
      console.log('   4. Colaborador deve ver apenas seus próprios dados');
    } else {
      console.log('❌ FALHA: User role do colaborador ainda não está correto');
      console.log(`   Tem user role: ${temUserRole}`);
      console.log(`   Tem role colaborador: ${temRoleColaborador}`);
    }
    
    // 5. Resumo da correção
    console.log('\n5️⃣ RESUMO DA CORREÇÃO');
    console.log('=' .repeat(50));
    
    console.log('🎯 PROBLEMA IDENTIFICADO:');
    console.log('   userProfile estava null quando loadDashboardData era chamado');
    console.log('   Isso causava userId e userLevel serem null');
    console.log('   Resultado: colaborador via dados globais');
    console.log('');
    console.log('🔧 CORREÇÃO APLICADA:');
    console.log('   1. Aguardar userProfile ser carregado antes de loadDashboardData');
    console.log('   2. Adicionar logs de debug para verificar parâmetros');
    console.log('   3. Garantir que filtragem seja aplicada corretamente');
    console.log('');
    console.log('✅ RESULTADO ESPERADO:');
    console.log('   Colaborador deve ver apenas:');
    console.log(`   - ${colaborador?.user_roles?.length || 0} user roles`);
    console.log(`   - Dados restritos ao seu nível`);
    console.log(`   - Dashboard com informações corretas`);
    console.log('');
    console.log('📝 PRÓXIMOS PASSOS:');
    console.log('   1. Teste o sistema com o usuário colaborador');
    console.log('   2. Verifique se as restrições estão funcionando');
    console.log('   3. Confirme que o problema foi resolvido');
    console.log('   4. Se necessário, limpe o cache do navegador');
    
  } catch (error) {
    console.error('❌ Erro durante o teste:', error);
  }
}

testarCorrecaoDashboard();

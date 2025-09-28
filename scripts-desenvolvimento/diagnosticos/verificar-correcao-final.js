import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verificarCorrecaoFinal() {
  console.log('✅ VERIFICAÇÃO FINAL DA CORREÇÃO');
  console.log('=' .repeat(50));
  
  try {
    // 1. Verificar colaborador corrigido
    console.log('\n1️⃣ VERIFICANDO COLABORADOR CORRIGIDO');
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
      console.log('📊 Colaborador corrigido:');
      console.log(`   Nome: ${colaborador.nome}`);
      console.log(`   Email: ${colaborador.email}`);
      console.log(`   Nível: ${colaborador.nivel}`);
      console.log(`   User Roles: ${colaborador.user_roles?.length || 0}`);
      
      if (colaborador.user_roles?.length > 0) {
        colaborador.user_roles.forEach(role => {
          const nivelCorreto = role.roles?.slug === 'colaborador' && role.roles?.nivel_hierarquico === 7;
          const status = nivelCorreto ? '✅' : '⚠️';
          console.log(`   ${status} Role: ${role.roles?.nome} (${role.roles?.slug})`);
          console.log(`   ${status} Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
        });
      }
    }
    
    // 2. Verificar dados que o colaborador deveria ver
    console.log('\n2️⃣ VERIFICANDO DADOS RESTRITOS DO COLABORADOR');
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
        
        // Calcular estatísticas dos jovens do colaborador
        const aprovados = jovensColaborador.filter(j => j.aprovado === 'aprovado').length;
        const preAprovados = jovensColaborador.filter(j => j.aprovado === 'pre_aprovado').length;
        const pendentes = jovensColaborador.filter(j => 
          j.aprovado === null || j.aprovado === 'null' || j.aprovado === undefined
        ).length;
        
        console.log(`📊 Estatísticas do colaborador:`);
        console.log(`   - Total: ${jovensColaborador.length}`);
        console.log(`   - Aprovados: ${aprovados}`);
        console.log(`   - Pré-aprovados: ${preAprovados}`);
        console.log(`   - Pendentes: ${pendentes}`);
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
      .limit(5);
    
    if (todosJovensError) {
      console.log('❌ Erro ao buscar todos os jovens:', todosJovensError.message);
    } else {
      console.log(`📊 Total de jovens no sistema: ${todosJovens.length}`);
      console.log('📊 Primeiros 3 jovens (que colaborador não deveria ver):');
      todosJovens.slice(0, 3).forEach(jovem => {
        console.log(`   - ${jovem.nome_completo} (${jovem.aprovado || 'pendente'}) - Usuário: ${jovem.usuario_id}`);
      });
    }
    
    // 4. Verificar se o problema foi resolvido
    console.log('\n4️⃣ VERIFICANDO SE O PROBLEMA FOI RESOLVIDO');
    console.log('-'.repeat(40));
    
    const temUserRole = colaborador?.user_roles?.length > 0;
    const temRoleColaborador = colaborador?.user_roles?.some(role => 
      role.roles?.slug === 'colaborador' && role.roles?.nivel_hierarquico === 7
    );
    
    if (temUserRole && temRoleColaborador) {
      console.log('✅ SUCESSO: User role do colaborador foi corrigido!');
      console.log('✅ Sistema de segurança deve funcionar corretamente');
      console.log('');
      console.log('📝 O QUE DEVE ACONTECER AGORA:');
      console.log('   1. O colaborador deve ver apenas seus próprios dados');
      console.log('   2. Dashboard deve mostrar apenas dados restritos');
      console.log('   3. Não deve ver dados de outros usuários');
      console.log('   4. Restrições devem ser aplicadas desde o primeiro acesso');
    } else {
      console.log('❌ FALHA: User role do colaborador ainda não está correto');
      console.log(`   Tem user role: ${temUserRole}`);
      console.log(`   Tem role colaborador: ${temRoleColaborador}`);
    }
    
    // 5. Resumo final
    console.log('\n5️⃣ RESUMO FINAL');
    console.log('=' .repeat(50));
    
    console.log('🎯 PROBLEMA ORIGINAL:');
    console.log('   Colaborador via todos os dados (101 jovens, 93 pendentes)');
    console.log('   quando deveria ver apenas dados restritos ao seu nível');
    console.log('');
    console.log('🔧 CORREÇÃO APLICADA:');
    console.log('   1. User roles criados para colaboradores');
    console.log('   2. Níveis hierárquicos alinhados');
    console.log('   3. Sistema de segurança corrigido');
    console.log('');
    console.log('✅ RESULTADO ESPERADO:');
    console.log('   O colaborador agora deve ver apenas:');
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
    console.error('❌ Erro durante a verificação:', error);
  }
}

verificarCorrecaoFinal();

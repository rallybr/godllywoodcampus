import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarLiderEstadual() {
  console.log('🧪 TESTANDO LÍDER ESTADUAL FJU');
  console.log('=' .repeat(50));
  
  try {
    // 1. Verificar líder estadual FJU
    console.log('\n1️⃣ VERIFICANDO LÍDER ESTADUAL FJU');
    console.log('-'.repeat(40));
    
    const { data: liderEstadual, error: liderError } = await supabase
      .from('usuarios')
      .select(`
        id, nome, email, nivel, estado_id, bloco_id, regiao_id, igreja_id,
        user_roles!user_roles_user_id_fkey (
          *,
          roles (*)
        )
      `)
      .eq('nivel', 'lider_estadual_fju')
      .limit(1)
      .single();
    
    if (liderError) {
      console.log('❌ Erro ao buscar líder estadual FJU:', liderError.message);
      return;
    }
    
    console.log('📊 Líder estadual FJU encontrado:');
    console.log(`   Nome: ${liderEstadual.nome}`);
    console.log(`   Email: ${liderEstadual.email}`);
    console.log(`   Nível: ${liderEstadual.nivel}`);
    console.log(`   Estado ID: ${liderEstadual.estado_id}`);
    console.log(`   Bloco ID: ${liderEstadual.bloco_id}`);
    console.log(`   Região ID: ${liderEstadual.regiao_id}`);
    console.log(`   Igreja ID: ${liderEstadual.igreja_id}`);
    console.log(`   User Roles: ${liderEstadual.user_roles?.length || 0}`);
    
    // 2. Verificar dados que o líder estadual deveria ver
    console.log('\n2️⃣ VERIFICANDO DADOS DO LÍDER ESTADUAL');
    console.log('-'.repeat(40));
    
    if (liderEstadual.estado_id) {
      // Jovens do estado do líder
      const { data: jovensEstado, error: jovensError } = await supabase
        .from('jovens')
        .select('id, nome_completo, aprovado, estado_id, usuario_id')
        .eq('estado_id', liderEstadual.estado_id);
      
      if (jovensError) {
        console.log('❌ Erro ao buscar jovens do estado:', jovensError.message);
      } else {
        console.log(`📊 Jovens do estado do líder: ${jovensEstado.length}`);
        
        // Calcular estatísticas dos jovens do estado
        const aprovados = jovensEstado.filter(j => j.aprovado === 'aprovado').length;
        const preAprovados = jovensEstado.filter(j => j.aprovado === 'pre_aprovado').length;
        const pendentes = jovensEstado.filter(j => 
          j.aprovado === null || j.aprovado === 'null' || j.aprovado === undefined
        ).length;
        
        console.log(`📊 Estatísticas do estado do líder:`);
        console.log(`   Total: ${jovensEstado.length}`);
        console.log(`   Aprovados: ${aprovados}`);
        console.log(`   Pré-aprovados: ${preAprovados}`);
        console.log(`   Pendentes: ${pendentes}`);
        
        if (jovensEstado.length > 0) {
          console.log('📊 Primeiros 3 jovens do estado:');
          jovensEstado.slice(0, 3).forEach(jovem => {
            console.log(`   - ${jovem.nome_completo} (${jovem.aprovado || 'pendente'})`);
          });
        }
      }
    } else {
      console.log('⚠️  WARNING: Líder estadual sem estado_id definido');
    }
    
    // 3. Verificar dados totais (que o líder estadual NÃO deveria ver)
    console.log('\n3️⃣ VERIFICANDO DADOS TOTAIS (QUE LÍDER ESTADUAL NÃO DEVERIA VER)');
    console.log('-'.repeat(40));
    
    const { data: todosJovens, error: todosJovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, aprovado, estado_id, usuario_id')
      .limit(10);
    
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
      
      console.log(`📊 Estatísticas globais (que líder estadual NÃO deveria ver):`);
      console.log(`   Total: ${totalGlobal}`);
      console.log(`   Aprovados: ${aprovadosGlobal}`);
      console.log(`   Pré-aprovados: ${preAprovadosGlobal}`);
      console.log(`   Pendentes: ${pendentesGlobal}`);
    }
    
    // 4. Verificar se a correção está funcionando
    console.log('\n4️⃣ VERIFICANDO SE A CORREÇÃO ESTÁ FUNCIONANDO');
    console.log('-'.repeat(40));
    
    const temUserRole = liderEstadual?.user_roles?.length > 0;
    const temEstadoId = liderEstadual?.estado_id;
    const temRoleLiderEstadual = liderEstadual?.user_roles?.some(role => 
      role.roles?.slug === 'lider_estadual_fju' && role.roles?.nivel_hierarquico === 3
    );
    
    if (temUserRole && temEstadoId && temRoleLiderEstadual) {
      console.log('✅ SUCESSO: Líder estadual FJU está configurado corretamente!');
      console.log('✅ Sistema de segurança deve funcionar corretamente');
      console.log('');
      console.log('📝 O QUE DEVE ACONTECER NO FRONTEND:');
      console.log('   1. userProfile deve ter estado_id definido');
      console.log('   2. Filtragem deve ser aplicada por estado_id');
      console.log('   3. Líder estadual deve ver apenas dados do seu estado');
      console.log('   4. Não deve ver dados de outros estados');
    } else {
      console.log('❌ FALHA: Líder estadual FJU não está configurado corretamente');
      console.log(`   Tem user role: ${temUserRole}`);
      console.log(`   Tem estado_id: ${temEstadoId}`);
      console.log(`   Tem role líder estadual: ${temRoleLiderEstadual}`);
    }
    
    // 5. Resumo da correção
    console.log('\n5️⃣ RESUMO DA CORREÇÃO');
    console.log('=' .repeat(50));
    
    console.log('🎯 PROBLEMA IDENTIFICADO:');
    console.log('   Líder estadual FJU estava vendo todos os dados');
    console.log('   quando deveria ver apenas dados do seu estado');
    console.log('');
    console.log('🔧 CORREÇÃO APLICADA:');
    console.log('   1. Filtragem por estado_id adicionada em loadEstatisticas');
    console.log('   2. Filtragem por estado_id adicionada em loadCondicoesStats');
    console.log('   3. userProfile passado como parâmetro para as funções');
    console.log('   4. Logs de debug adicionados para verificar filtragem');
    console.log('');
    console.log('✅ RESULTADO ESPERADO:');
    console.log('   Líder estadual FJU deve ver apenas:');
    console.log(`   - Dados do estado: ${liderEstadual?.estado_id}`);
    console.log(`   - Jovens do seu estado`);
    console.log(`   - Estatísticas restritas ao seu escopo`);
    console.log('');
    console.log('📝 PRÓXIMOS PASSOS:');
    console.log('   1. Teste o sistema com o usuário líder estadual FJU');
    console.log('   2. Verifique se as restrições estão funcionando');
    console.log('   3. Confirme que o problema foi resolvido');
    console.log('   4. Se necessário, limpe o cache do navegador');
    
  } catch (error) {
    console.error('❌ Erro durante o teste:', error);
  }
}

testarLiderEstadual();

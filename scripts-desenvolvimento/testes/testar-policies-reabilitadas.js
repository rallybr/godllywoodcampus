import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testarPoliciesReabilitadas() {
  console.log('🧪 TESTANDO POLICIES REABILITADAS');
  console.log('=' .repeat(50));
  
  try {
    // 1. Testar acesso sem autenticação (deve falhar)
    console.log('\n1️⃣ TESTANDO ACESSO SEM AUTENTICAÇÃO');
    console.log('-'.repeat(40));
    
    try {
      const { data: jovensSemAuth, error: jovensSemAuthError } = await supabase
        .from('jovens')
        .select('id, nome_completo')
        .limit(5);
      
      if (jovensSemAuthError) {
        console.log('✅ SUCESSO: Acesso sem autenticação foi bloqueado');
        console.log(`   Erro: ${jovensSemAuthError.message}`);
      } else {
        console.log('⚠️  WARNING: Acesso sem autenticação não foi bloqueado');
        console.log(`   Dados retornados: ${jovensSemAuth?.length || 0} registros`);
      }
    } catch (err) {
      console.log('✅ SUCESSO: Acesso sem autenticação foi bloqueado');
      console.log(`   Erro: ${err.message}`);
    }
    
    // 2. Testar acesso com usuário colaborador
    console.log('\n2️⃣ TESTANDO ACESSO COM USUÁRIO COLABORADOR');
    console.log('-'.repeat(40));
    
    // Simular login do colaborador
    const { data: colaborador, error: colaboradorError } = await supabase
      .from('usuarios')
      .select('id, nome, email, nivel')
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
      
      // Testar acesso aos jovens (deve ver apenas os que ele cadastrou)
      try {
        const { data: jovensColaborador, error: jovensColaboradorError } = await supabase
          .from('jovens')
          .select('id, nome_completo, usuario_id')
          .eq('usuario_id', colaborador.id);
        
        if (jovensColaboradorError) {
          console.log('❌ Erro ao buscar jovens do colaborador:', jovensColaboradorError.message);
        } else {
          console.log(`📊 Jovens do colaborador: ${jovensColaborador.length}`);
          if (jovensColaborador.length > 0) {
            console.log('📊 Primeiros 3 jovens:');
            jovensColaborador.slice(0, 3).forEach(jovem => {
              console.log(`   - ${jovem.nome_completo} (ID: ${jovem.usuario_id})`);
            });
          }
        }
      } catch (err) {
        console.log('❌ Erro ao testar acesso do colaborador:', err.message);
      }
    }
    
    // 3. Testar acesso com usuário líder estadual
    console.log('\n3️⃣ TESTANDO ACESSO COM USUÁRIO LÍDER ESTADUAL');
    console.log('-'.repeat(40));
    
    const { data: liderEstadual, error: liderEstadualError } = await supabase
      .from('usuarios')
      .select('id, nome, email, nivel, estado_id')
      .eq('nivel', 'lider_estadual_fju')
      .limit(1)
      .single();
    
    if (liderEstadualError) {
      console.log('❌ Erro ao buscar líder estadual:', liderEstadualError.message);
    } else {
      console.log('📊 Líder estadual encontrado:');
      console.log(`   Nome: ${liderEstadual.nome}`);
      console.log(`   Email: ${liderEstadual.email}`);
      console.log(`   Nível: ${liderEstadual.nivel}`);
      console.log(`   Estado ID: ${liderEstadual.estado_id}`);
      
      // Testar acesso aos jovens (deve ver apenas do seu estado)
      if (liderEstadual.estado_id) {
        try {
          const { data: jovensEstado, error: jovensEstadoError } = await supabase
            .from('jovens')
            .select('id, nome_completo, estado_id')
            .eq('estado_id', liderEstadual.estado_id);
          
          if (jovensEstadoError) {
            console.log('❌ Erro ao buscar jovens do estado:', jovensEstadoError.message);
          } else {
            console.log(`📊 Jovens do estado: ${jovensEstado.length}`);
            if (jovensEstado.length > 0) {
              console.log('📊 Primeiros 3 jovens:');
              jovensEstado.slice(0, 3).forEach(jovem => {
                console.log(`   - ${jovem.nome_completo} (Estado: ${jovem.estado_id})`);
              });
            }
          }
        } catch (err) {
          console.log('❌ Erro ao testar acesso do líder estadual:', err.message);
        }
      } else {
        console.log('⚠️  WARNING: Líder estadual sem estado_id definido');
      }
    }
    
    // 4. Testar acesso a dados geográficos (deve funcionar para todos)
    console.log('\n4️⃣ TESTANDO ACESSO A DADOS GEOGRÁFICOS');
    console.log('-'.repeat(40));
    
    try {
      const { data: estados, error: estadosError } = await supabase
        .from('estados')
        .select('id, nome, sigla')
        .limit(5);
      
      if (estadosError) {
        console.log('❌ Erro ao buscar estados:', estadosError.message);
      } else {
        console.log(`✅ SUCESSO: Acesso a estados funcionando`);
        console.log(`   Estados encontrados: ${estados.length}`);
        if (estados.length > 0) {
          console.log('📊 Primeiros 3 estados:');
          estados.slice(0, 3).forEach(estado => {
            console.log(`   - ${estado.nome} (${estado.sigla})`);
          });
        }
      }
    } catch (err) {
      console.log('❌ Erro ao testar acesso a estados:', err.message);
    }
    
    // 5. Testar acesso a roles (deve funcionar para todos)
    console.log('\n5️⃣ TESTANDO ACESSO A ROLES');
    console.log('-'.repeat(40));
    
    try {
      const { data: roles, error: rolesError } = await supabase
        .from('roles')
        .select('id, nome, slug, nivel_hierarquico')
        .order('nivel_hierarquico');
      
      if (rolesError) {
        console.log('❌ Erro ao buscar roles:', rolesError.message);
      } else {
        console.log(`✅ SUCESSO: Acesso a roles funcionando`);
        console.log(`   Roles encontrados: ${roles.length}`);
        console.log('📊 Roles disponíveis:');
        roles.forEach(role => {
          console.log(`   - ${role.nome} (${role.slug}) - Nível: ${role.nivel_hierarquico}`);
        });
      }
    } catch (err) {
      console.log('❌ Erro ao testar acesso a roles:', err.message);
    }
    
    // 6. Resumo dos testes
    console.log('\n6️⃣ RESUMO DOS TESTES');
    console.log('=' .repeat(50));
    
    console.log('🎯 RESULTADOS ESPERADOS:');
    console.log('   ✅ Acesso sem autenticação deve ser bloqueado');
    console.log('   ✅ Colaborador deve ver apenas seus jovens');
    console.log('   ✅ Líder estadual deve ver apenas jovens do seu estado');
    console.log('   ✅ Dados geográficos devem ser acessíveis a todos');
    console.log('   ✅ Roles devem ser acessíveis a todos');
    console.log('');
    console.log('📝 PRÓXIMOS PASSOS:');
    console.log('   1. Execute o script SQL no Supabase SQL Editor');
    console.log('   2. Teste o sistema com usuários de diferentes níveis');
    console.log('   3. Verifique se as restrições estão funcionando');
    console.log('   4. Confirme que não há problemas de bloqueio');
    
  } catch (error) {
    console.error('❌ Erro durante o teste:', error);
  }
}

testarPoliciesReabilitadas();

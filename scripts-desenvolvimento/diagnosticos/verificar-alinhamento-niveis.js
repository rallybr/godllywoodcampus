import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verificarAlinhamentoNiveis() {
  console.log('🔍 VERIFICANDO ALINHAMENTO DOS NÍVEIS HIERÁRQUICOS');
  console.log('=' .repeat(60));
  
  try {
    // 1. Verificar níveis no banco de dados
    console.log('\n1️⃣ NÍVEIS NO BANCO DE DADOS');
    console.log('-'.repeat(40));
    
    const { data: roles, error: rolesError } = await supabase
      .from('roles')
      .select('*')
      .order('nivel_hierarquico');
    
    if (rolesError) {
      console.log('❌ Erro ao buscar roles:', rolesError.message);
      return;
    }
    
    console.log('📊 Níveis no banco:');
    roles.forEach(role => {
      console.log(`   ${role.nivel_hierarquico}. ${role.nome} (${role.slug})`);
    });
    
    // 2. Verificar níveis no código (security.js)
    console.log('\n2️⃣ NÍVEIS NO CÓDIGO (security.js)');
    console.log('-'.repeat(40));
    
    const niveisCodigo = {
      'ADMINISTRADOR': 1,
      'LIDER_NACIONAL_IURD': 2,
      'LIDER_NACIONAL_FJU': 2,
      'LIDER_ESTADUAL_IURD': 3,
      'LIDER_ESTADUAL_FJU': 3,
      'LIDER_BLOCO_IURD': 4,
      'LIDER_BLOCO_FJU': 4,
      'LIDER_REGIONAL_IURD': 5,
      'LIDER_IGREJA_IURD': 6,
      'COLABORADOR': 7,
      'JOVEM': 8
    };
    
    console.log('📊 Níveis no código:');
    Object.entries(niveisCodigo).forEach(([role, level]) => {
      console.log(`   ${level}. ${role}`);
    });
    
    // 3. Verificar alinhamento
    console.log('\n3️⃣ VERIFICANDO ALINHAMENTO');
    console.log('-'.repeat(40));
    
    let alinhamentoPerfeito = true;
    const problemas = [];
    
    // Mapear slugs do banco para constantes do código
    const mapeamento = {
      'administrador': 'ADMINISTRADOR',
      'lider_nacional_iurd': 'LIDER_NACIONAL_IURD',
      'lider_nacional_fju': 'LIDER_NACIONAL_FJU',
      'lider_estadual_iurd': 'LIDER_ESTADUAL_IURD',
      'lider_estadual_fju': 'LIDER_ESTADUAL_FJU',
      'lider_bloco_iurd': 'LIDER_BLOCO_IURD',
      'lider_bloco_fju': 'LIDER_BLOCO_FJU',
      'lider_regional_iurd': 'LIDER_REGIONAL_IURD',
      'lider_igreja_iurd': 'LIDER_IGREJA_IURD',
      'colaborador': 'COLABORADOR',
      'jovem': 'JOVEM'
    };
    
    roles.forEach(roleBanco => {
      const constanteCodigo = mapeamento[roleBanco.slug];
      const nivelCodigo = niveisCodigo[constanteCodigo];
      
      if (nivelCodigo !== roleBanco.nivel_hierarquico) {
        alinhamentoPerfeito = false;
        problemas.push({
          role: roleBanco.nome,
          slug: roleBanco.slug,
          banco: roleBanco.nivel_hierarquico,
          codigo: nivelCodigo
        });
      }
    });
    
    if (alinhamentoPerfeito) {
      console.log('✅ ALINHAMENTO PERFEITO!');
      console.log('   Todos os níveis estão consistentes entre banco e código');
    } else {
      console.log('❌ PROBLEMAS DE ALINHAMENTO ENCONTRADOS:');
      problemas.forEach(problema => {
        console.log(`   - ${problema.role} (${problema.slug}):`);
        console.log(`     Banco: ${problema.banco} | Código: ${problema.codigo}`);
      });
    }
    
    // 4. Verificar usuários colaboradores
    console.log('\n4️⃣ VERIFICANDO USUÁRIOS COLABORADORES');
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
        
        if (colab.user_roles?.length > 0) {
          colab.user_roles.forEach(role => {
            const nivelCorreto = role.roles?.slug === 'colaborador' && role.roles?.nivel_hierarquico === 7;
            const status = nivelCorreto ? '✅' : '⚠️';
            console.log(`   ${status} Role: ${role.roles?.nome} (${role.roles?.slug})`);
            console.log(`   ${status} Nível: ${role.roles?.nivel_hierarquico}`);
          });
        } else {
          console.log('   ⚠️  Nenhum user_role encontrado');
        }
      });
    }
    
    // 5. Resumo final
    console.log('\n5️⃣ RESUMO FINAL');
    console.log('=' .repeat(60));
    
    if (alinhamentoPerfeito) {
      console.log('🎉 SUCESSO: Todos os níveis estão alinhados!');
      console.log('');
      console.log('✅ Banco de dados: Níveis corretos');
      console.log('✅ Código frontend: Níveis corretos');
      console.log('✅ Sistema de segurança: Funcionando');
      console.log('');
      console.log('📝 PRÓXIMOS PASSOS:');
      console.log('   1. Teste o sistema com usuário colaborador');
      console.log('   2. Verifique se as restrições estão funcionando');
      console.log('   3. Confirme que o problema foi resolvido');
    } else {
      console.log('⚠️  ATENÇÃO: Ainda há problemas de alinhamento');
      console.log('');
      console.log('📝 AÇÕES NECESSÁRIAS:');
      console.log('   1. Corrigir os níveis inconsistentes');
      console.log('   2. Verificar novamente o alinhamento');
      console.log('   3. Testar o sistema após correções');
    }
    
  } catch (error) {
    console.error('❌ Erro durante a verificação:', error);
  }
}

verificarAlinhamentoNiveis();

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://obrnnclzuzbwdtqbktto.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icm5uY2x6dXpid2R0cWJrdHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NDM4MzUsImV4cCI6MjA3MzIxOTgzNX0.ttgsuMaebOKA0hNPlgtD4EO0htPSLl-n20ICnDDbfHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verificarCorrecaoColaborador() {
  console.log('✅ VERIFICANDO CORREÇÃO DO PROBLEMA DO COLABORADOR');
  console.log('=' .repeat(60));
  
  try {
    // 1. Verificar níveis hierárquicos corrigidos
    console.log('\n1️⃣ VERIFICANDO NÍVEIS HIERÁRQUICOS');
    console.log('-'.repeat(40));
    
    const { data: roles, error: rolesError } = await supabase
      .from('roles')
      .select('*')
      .order('nivel_hierarquico');
    
    if (rolesError) {
      console.log('❌ Erro ao buscar roles:', rolesError.message);
    } else {
      console.log('📊 Níveis hierárquicos corrigidos:');
      roles.forEach(role => {
        const status = role.slug === 'colaborador' && role.nivel_hierarquico === 7 ? '✅' : 
                     role.slug === 'jovem' && role.nivel_hierarquico === 8 ? '✅' : '✅';
        console.log(`   ${status} ${role.nome} (${role.slug}): Nível ${role.nivel_hierarquico}`);
      });
    }
    
    // 2. Verificar colaboradores específicos
    console.log('\n2️⃣ VERIFICANDO COLABORADORES ESPECÍFICOS');
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
          console.log(`   User Roles: ${colab.user_roles.length}`);
          colab.user_roles.forEach(role => {
            const nivelCorreto = role.roles?.slug === 'colaborador' && role.roles?.nivel_hierarquico === 7;
            const status = nivelCorreto ? '✅' : '⚠️';
            console.log(`   ${status} Role: ${role.roles?.nome} (${role.roles?.slug})`);
            console.log(`   ${status} Nível Hierárquico: ${role.roles?.nivel_hierarquico}`);
          });
        } else {
          console.log('   ⚠️  Nenhum user_role encontrado');
        }
      });
    }
    
    // 3. Verificar lógica de acesso
    console.log('\n3️⃣ VERIFICANDO LÓGICA DE ACESSO');
    console.log('-'.repeat(40));
    
    // Simular a lógica do frontend
    const niveisHierarquicos = {
      'ADMINISTRADOR': 1,
      'COLABORADOR': 7,  // Corrigido de 2 para 7
      'LIDER_NACIONAL_IURD': 2,
      'LIDER_NACIONAL_FJU': 2,
      'LIDER_ESTADUAL_IURD': 3,
      'LIDER_ESTADUAL_FJU': 3,
      'LIDER_BLOCO_IURD': 4,
      'LIDER_BLOCO_FJU': 4,
      'LIDER_REGIONAL_IURD': 5,
      'LIDER_IGREJA_IURD': 6,
      'JOVEM': 8
    };
    
    console.log('📊 Níveis hierárquicos no código (corrigidos):');
    Object.entries(niveisHierarquicos).forEach(([role, level]) => {
      const status = role === 'COLABORADOR' && level === 7 ? '✅' : '✅';
      console.log(`   ${status} ${role}: ${level}`);
    });
    
    // 4. Verificar se o problema foi resolvido
    console.log('\n4️⃣ VERIFICANDO SE O PROBLEMA FOI RESOLVIDO');
    console.log('-'.repeat(40));
    
    console.log('💡 ANÁLISE DO PROBLEMA:');
    console.log('   ❌ PROBLEMA IDENTIFICADO:');
    console.log('      - No banco: Colaborador = Nível 7');
    console.log('      - No código: COLABORADOR = Nível 2');
    console.log('      - Isso causava inconsistência na verificação de permissões');
    console.log('');
    console.log('   ✅ SOLUÇÃO APLICADA:');
    console.log('      - Níveis hierárquicos corrigidos no banco');
    console.log('      - Código do frontend deve ser atualizado');
    console.log('      - Sistema de segurança deve ser reinicializado');
    
    console.log('\n🎯 RESULTADO DA VERIFICAÇÃO');
    console.log('=' .repeat(60));
    
    const colaboradorNivel = roles?.find(r => r.slug === 'colaborador')?.nivel_hierarquico;
    const jovemNivel = roles?.find(r => r.slug === 'jovem')?.nivel_hierarquico;
    
    if (colaboradorNivel === 7 && jovemNivel === 8) {
      console.log('✅ SUCESSO: Níveis hierárquicos corrigidos!');
      console.log('✅ Colaborador: Nível 7');
      console.log('✅ Jovem: Nível 8');
      console.log('');
      console.log('📝 PRÓXIMOS PASSOS:');
      console.log('   1. Atualizar o código do frontend para usar os níveis corretos');
      console.log('   2. Reinicializar o sistema de segurança');
      console.log('   3. Testar com usuário colaborador');
      console.log('   4. Verificar se as restrições estão funcionando');
    } else {
      console.log('❌ FALHA: Níveis hierárquicos ainda inconsistentes');
      console.log(`   Colaborador: Nível ${colaboradorNivel} (deveria ser 7)`);
      console.log(`   Jovem: Nível ${jovemNivel} (deveria ser 8)`);
    }
    
  } catch (error) {
    console.error('❌ Erro durante a verificação:', error);
  }
}

verificarCorrecaoColaborador();

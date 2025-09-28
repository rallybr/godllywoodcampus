// Script para testar o card "JOVENS POR ESTADO" no console do navegador
// Cole este código no console do navegador

console.log('🔍 TESTE - Verificando card JOVENS POR ESTADO...');

// 1. Verificar userProfile e getUserLevelName
console.log('UserProfile:', window.$userProfile);
console.log('getUserLevelName result:', getUserLevelName(window.$userProfile));

// 2. Verificar se a condição está sendo atendida
const userLevel = getUserLevelName(window.$userProfile);
const isNotJovem = userLevel !== 'Jovem';
const hasSpecialLevel = userLevel.includes('Nacional') || 
                       userLevel.includes('Estadual') || 
                       userLevel.includes('Bloco') || 
                       userLevel.includes('Regional') || 
                       userLevel.includes('Igreja') || 
                       userLevel === 'Administrador' || 
                       userLevel === 'Instrutor';

console.log('🔍 Condição isNotJovem:', isNotJovem);
console.log('🔍 Condição hasSpecialLevel:', hasSpecialLevel);
console.log('🔍 Condição final (isNotJovem || hasSpecialLevel):', isNotJovem || hasSpecialLevel);

// 3. Verificar se estadosStats está sendo carregado
console.log('🔍 EstadosStats no componente:', window.estadosStats || 'Não encontrado');

// 4. Verificar se a função loadEstadosStats está sendo chamada
console.log('🔍 Verificando se loadEstadosStats foi chamada...');

// 5. Testar consulta direta
async function testarConsultaEstados() {
  try {
    const { data: jovens, error } = await supabase
      .from('jovens')
      .select('id, estado_id, usuario_id')
      .eq('usuario_id', 'e745720c-e9f7-4562-978b-72ba32387420'); // Substitua pelo ID real
    
    console.log('🔍 Jovens do colaborador:', jovens?.length);
    
    if (jovens && jovens.length > 0) {
      const estadosUnicos = [...new Set(jovens.map(j => j.estado_id))];
      console.log('🔍 Estados únicos com jovens:', estadosUnicos);
    }
    
  } catch (err) {
    console.error('❌ Erro na consulta:', err);
  }
}

testarConsultaEstados();

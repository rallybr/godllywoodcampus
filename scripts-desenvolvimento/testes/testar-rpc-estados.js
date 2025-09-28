// Script para testar a função RPC get_jovens_por_estado_count
// Cole este código no console do navegador

console.log('🔍 TESTE - Função RPC get_jovens_por_estado_count');

async function testarRPC() {
  try {
    console.log('Testando RPC sem parâmetros...');
    const { data: rpcData1, error: rpcError1 } = await supabase.rpc('get_jovens_por_estado_count');
    console.log('RPC sem parâmetros - data:', rpcData1);
    console.log('RPC sem parâmetros - error:', rpcError1);
    
    console.log('Testando RPC com null...');
    const { data: rpcData2, error: rpcError2 } = await supabase.rpc('get_jovens_por_estado_count', {
      edicao_id: null
    });
    console.log('RPC com null - data:', rpcData2);
    console.log('RPC com null - error:', rpcError2);
    
    if (rpcError1 || rpcError2) {
      console.log('❌ RPC não existe ou tem erro. Vamos criar a função...');
      
      // Tentar criar a função
      const { data: createResult, error: createError } = await supabase.rpc('exec_sql', {
        sql: `
          CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(edicao_id uuid DEFAULT NULL)
          RETURNS TABLE (
            estado_id uuid,
            total bigint
          )
          LANGUAGE plpgsql
          SECURITY DEFINER
          AS $$
          BEGIN
            RETURN QUERY
            SELECT 
              j.estado_id,
              COUNT(*) as total
            FROM public.jovens j
            WHERE j.estado_id IS NOT NULL
              AND (edicao_id IS NULL OR j.edicao_id = edicao_id)
            GROUP BY j.estado_id;
          END;
          $$;
        `
      });
      
      console.log('Resultado da criação:', createResult);
      console.log('Erro da criação:', createError);
    }
    
  } catch (err) {
    console.error('Erro ao testar RPC:', err);
  }
}

testarRPC();

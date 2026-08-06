import { supabase } from '$lib/utils/supabase';

async function getJovemIdsAssociados(usuarioId) {
  const { data } = await supabase
    .from('jovens_usuarios_associacoes')
    .select('jovem_id')
    .eq('usuario_id', usuarioId);
  return (data || []).map((a) => a.jovem_id);
}

/**
 * Aplica filtro de escopo por nível de acesso + jovens associados na query de jovens.
 * Retorna `{ query }` (objeto simples) para o await NÃO desembrulhar o builder
 * do Supabase (que é thenable) e executar a query cedo demais.
 */
export async function applyEscopoJovensQuery(query, profile) {
  if (!profile?.nivel) return { query };

  const { nivel, id: usuarioId } = profile;

  if (nivel === 'administrador' || nivel === 'lider_nacional_iurd' || nivel === 'lider_nacional_fju') {
    return { query };
  }

  if (nivel === 'lider_estadual_iurd' || nivel === 'lider_estadual_fju') {
    if (profile.estado_id) {
      const ids = await getJovemIdsAssociados(usuarioId);
      query =
        ids.length > 0
          ? query.or(`estado_id.eq.${profile.estado_id},id.in.(${ids.join(',')})`)
          : query.eq('estado_id', profile.estado_id);
    }
  } else if (nivel === 'lider_bloco_iurd' || nivel === 'lider_bloco_fju') {
    if (profile.bloco_id) {
      const ids = await getJovemIdsAssociados(usuarioId);
      query =
        ids.length > 0
          ? query.or(`bloco_id.eq.${profile.bloco_id},id.in.(${ids.join(',')})`)
          : query.eq('bloco_id', profile.bloco_id);
    }
  } else if (nivel === 'lider_regional_iurd') {
    if (profile.regiao_id) {
      const ids = await getJovemIdsAssociados(usuarioId);
      query =
        ids.length > 0
          ? query.or(`regiao_id.eq.${profile.regiao_id},id.in.(${ids.join(',')})`)
          : query.eq('regiao_id', profile.regiao_id);
    }
  } else if (nivel === 'lider_igreja_iurd') {
    if (profile.igreja_id) {
      const ids = await getJovemIdsAssociados(usuarioId);
      query =
        ids.length > 0
          ? query.or(`igreja_id.eq.${profile.igreja_id},id.in.(${ids.join(',')})`)
          : query.eq('igreja_id', profile.igreja_id);
    }
  } else if ((nivel === 'colaborador' || nivel === 'jovem') && usuarioId) {
    query = query.eq('usuario_id', usuarioId);
  }

  return { query };
}

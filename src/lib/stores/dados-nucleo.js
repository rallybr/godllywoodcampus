import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Store para dados do núcleo
export const dadosNucleo = writable(null);
export const loading = writable(false);
export const error = writable(null);

// Função para carregar dados do núcleo de um jovem
export async function loadDadosNucleo(jovemId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Carregando dados do núcleo para jovem:', jovemId);
    
    const { data, error: fetchError } = await supabase
      .from('dados_nucleo')
      .select('*')
      .eq('jovem_id', jovemId)
      .single();
    
    if (fetchError && fetchError.code !== 'PGRST116') {
      console.error('Erro ao buscar dados do núcleo:', fetchError);
      throw fetchError;
    }
    
    console.log('🔍 DEBUG - Dados do núcleo encontrados:', data);
    
    dadosNucleo.set(data);
    return data;
    
  } catch (err) {
    console.error('Erro ao carregar dados do núcleo:', err);
    error.set(err.message || 'Erro ao carregar dados do núcleo');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para salvar dados do núcleo
export async function saveDadosNucleo(jovemId, dados) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Salvando dados do núcleo para jovem:', jovemId);
    console.log('🔍 DEBUG - Dados a serem salvos:', dados);
    
    // Verificar se já existe registro
    const { data: existingData } = await supabase
      .from('dados_nucleo')
      .select('id')
      .eq('jovem_id', jovemId)
      .single();
    
    let result;
    
    if (existingData) {
      // Atualizar registro existente
      const { data, error: updateError } = await supabase
        .from('dados_nucleo')
        .update({
          ...dados,
          atualizado_em: new Date().toISOString()
        })
        .eq('jovem_id', jovemId)
        .select()
        .single();
      
      if (updateError) {
        console.error('Erro ao atualizar dados do núcleo:', updateError);
        throw updateError;
      }
      
      result = data;
    } else {
      // Criar novo registro
      const { data, error: insertError } = await supabase
        .from('dados_nucleo')
        .insert({
          jovem_id: jovemId,
          ...dados,
          criado_em: new Date().toISOString(),
          atualizado_em: new Date().toISOString()
        })
        .select()
        .single();
      
      if (insertError) {
        console.error('Erro ao inserir dados do núcleo:', insertError);
        throw insertError;
      }
      
      result = data;
    }
    
    console.log('🔍 DEBUG - Dados do núcleo salvos com sucesso:', result);
    
    dadosNucleo.set(result);
    return result;
    
  } catch (err) {
    console.error('Erro ao salvar dados do núcleo:', err);
    error.set(err.message || 'Erro ao salvar dados do núcleo');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para deletar dados do núcleo
export async function deleteDadosNucleo(jovemId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Deletando dados do núcleo para jovem:', jovemId);
    
    const { error: deleteError } = await supabase
      .from('dados_nucleo')
      .delete()
      .eq('jovem_id', jovemId);
    
    if (deleteError) {
      console.error('Erro ao deletar dados do núcleo:', deleteError);
      throw deleteError;
    }
    
    console.log('🔍 DEBUG - Dados do núcleo deletados com sucesso');
    
    dadosNucleo.set(null);
    return true;
    
  } catch (err) {
    console.error('Erro ao deletar dados do núcleo:', err);
    error.set(err.message || 'Erro ao deletar dados do núcleo');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para extrair ID do vídeo do YouTube
export function extractYouTubeVideoId(url) {
  if (!url) return null;
  
  console.log('🔍 DEBUG - Extraindo ID do YouTube da URL:', url);
  
  const patterns = [
    // youtube.com/watch?v=ID
    /(?:youtube\.com\/watch\?v=)([^&\n?#]+)/,
    // youtu.be/ID
    /(?:youtu\.be\/)([^&\n?#]+)/,
    // youtube.com/embed/ID
    /(?:youtube\.com\/embed\/)([^&\n?#]+)/,
    // youtube.com/v/ID
    /(?:youtube\.com\/v\/)([^&\n?#]+)/
  ];
  
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      const videoId = match[1];
      console.log('🔍 DEBUG - ID do vídeo extraído:', videoId);
      return videoId;
    }
  }
  
  console.log('🔍 DEBUG - Nenhum ID de vídeo encontrado');
  return null;
}

// Função para detectar plataforma do vídeo
export function detectVideoPlatform(url) {
  if (!url) return null;
  
  if (url.includes('youtube.com') || url.includes('youtu.be')) {
    return 'youtube';
  } else if (url.includes('drive.google.com')) {
    return 'google_drive';
  } else if (url.includes('instagram.com')) {
    return 'instagram';
  } else if (url.includes('facebook.com') || url.includes('fb.watch')) {
    return 'facebook';
  }
  
  return 'other';
}

// Função para gerar URL de incorporação do YouTube
export function getYouTubeEmbedUrl(videoId) {
  if (!videoId) return null;
  return `https://www.youtube.com/embed/${videoId}`;
}

// Função para gerar URL de incorporação do Google Drive
export function getGoogleDriveEmbedUrl(url) {
  if (!url) return null;
  
  // Extrair ID do arquivo do Google Drive
  const match = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
  if (match) {
    return `https://drive.google.com/file/d/${match[1]}/preview`;
  }
  
  return url;
}

// Função para gerar URL de incorporação do Instagram
export function getInstagramEmbedUrl(url) {
  if (!url) return null;
  
  // Instagram não permite incorporação direta, retornar URL original
  return url;
}

// Função para gerar URL de incorporação do Facebook
export function getFacebookEmbedUrl(url) {
  if (!url) return null;
  
  // Facebook não permite incorporação direta, retornar URL original
  return url;
}

// Função para obter URL de incorporação baseada na plataforma
export function getEmbedUrl(url, platform) {
  console.log('🔍 DEBUG - getEmbedUrl chamada:', { url, platform });
  
  if (!url || !platform) {
    console.log('🔍 DEBUG - URL ou plataforma vazios, retornando null');
    return null;
  }
  
  switch (platform) {
    case 'youtube':
      const videoId = extractYouTubeVideoId(url);
      console.log('🔍 DEBUG - Video ID extraído:', videoId);
      if (videoId) {
        const embedUrl = getYouTubeEmbedUrl(videoId);
        console.log('🔍 DEBUG - URL de incorporação do YouTube:', embedUrl);
        return embedUrl;
      }
      console.log('🔍 DEBUG - Video ID não encontrado, retornando null');
      return null;
    case 'google_drive':
      return getGoogleDriveEmbedUrl(url);
    case 'instagram':
      return getInstagramEmbedUrl(url);
    case 'facebook':
      return getFacebookEmbedUrl(url);
    default:
      console.log('🔍 DEBUG - Plataforma não reconhecida:', platform);
      return url;
  }
}

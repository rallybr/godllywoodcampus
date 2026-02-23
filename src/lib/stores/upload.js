import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Store para estado do upload
export const uploading = writable(false);
export const uploadProgress = writable(0);

// Função para fazer upload de foto de usuário
export async function uploadUserPhoto(userId, file) {
  uploading.set(true);
  uploadProgress.set(0);
  
  try {
    // Validar arquivo
    if (!file) throw new Error('Nenhum arquivo selecionado');
    
    // Validar tipo de arquivo
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      throw new Error('Tipo de arquivo não suportado. Use JPG, PNG ou WEBP');
    }
    
    // Validar tamanho (5MB máximo)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      throw new Error('Arquivo muito grande. Tamanho máximo: 5MB');
    }
    
    // Gerar nome único para o arquivo
    const fileExt = file.name && file.name.includes('.') ? file.name.split('.').pop() : 'jpg';
    const fileName = `${userId}/profile.${fileExt}`;
    
    // Fazer upload para Supabase Storage
    const { data, error } = await supabase.storage
      .from('fotos_usuarios')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: true
      });
    
    if (error) throw error;
    
    // Obter URL pública
    const { data: urlData } = supabase.storage
      .from('fotos_usuarios')
      .getPublicUrl(fileName);
    
    return urlData.publicUrl;
    
  } catch (error) {
    console.error('Erro no upload da foto do usuário:', error);
    throw error;
  } finally {
    uploading.set(false);
    uploadProgress.set(0);
  }
}

// Função para fazer upload de foto de jovem
export async function uploadJovemPhoto(jovemId, file) {
  uploading.set(true);
  uploadProgress.set(0);
  
  try {
    // Validar arquivo
    if (!file) throw new Error('Nenhum arquivo selecionado');
    
    // Validar tipo de arquivo
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      throw new Error('Tipo de arquivo não suportado. Use JPG, PNG ou WEBP');
    }
    
    // Validar tamanho (5MB máximo)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      throw new Error('Arquivo muito grande. Tamanho máximo: 5MB');
    }
    
    // Gerar nome único para o arquivo
    const fileExt = file.name && file.name.includes('.') ? file.name.split('.').pop() : 'jpg';
    const fileName = `${jovemId}/profile.${fileExt}`;
    
    // Fazer upload para Supabase Storage
    console.log('uploadJovemPhoto - Tentando upload:', { fileName, bucket: 'fotos_jovens' });
    
    const { data, error } = await supabase.storage
      .from('fotos_jovens')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: true
      });
    
    console.log('uploadJovemPhoto - Resultado do upload:', { data, error });
    
    if (error) {
      console.error('uploadJovemPhoto - Erro detalhado:', error);
      throw error;
    }
    
    // Obter URL pública
    const { data: urlData } = supabase.storage
      .from('fotos_jovens')
      .getPublicUrl(fileName);
    
    return urlData.publicUrl;
    
  } catch (error) {
    console.error('Erro no upload da foto do jovem:', error);
    throw error;
  } finally {
    uploading.set(false);
    uploadProgress.set(0);
  }
}

// Função para fazer upload da foto do namorado (pastor) da jovem
export async function uploadNamoradoPhoto(jovemId, file) {
  uploading.set(true);
  uploadProgress.set(0);

  try {
    if (!file) throw new Error('Nenhum arquivo selecionado');
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      throw new Error('Tipo de arquivo não suportado. Use JPG, PNG ou WEBP');
    }
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) throw new Error('Arquivo muito grande. Tamanho máximo: 5MB');

    const fileExt = file.name && file.name.includes('.') ? file.name.split('.').pop() : 'jpg';
    const fileName = `namorados/${jovemId}/foto.${fileExt}`;

    const { error } = await supabase.storage
      .from('fotos_jovens')
      .upload(fileName, file, { cacheControl: '3600', upsert: true });

    if (error) throw error;

    const { data: urlData } = supabase.storage
      .from('fotos_jovens')
      .getPublicUrl(fileName);
    return urlData.publicUrl;
  } catch (error) {
    console.error('Erro no upload da foto do namorado:', error);
    throw error;
  } finally {
    uploading.set(false);
    uploadProgress.set(0);
  }
}

// Função para comprimir imagem antes do upload
export function compressImage(file, maxWidth = 800, quality = 0.8) {
  return new Promise((resolve) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();
    
    img.onload = () => {
      // Calcular novas dimensões mantendo proporção
      let { width, height } = img;
      if (width > maxWidth) {
        height = (height * maxWidth) / width;
        width = maxWidth;
      }
      
      canvas.width = width;
      canvas.height = height;
      
      // Desenhar imagem redimensionada
      ctx.drawImage(img, 0, 0, width, height);
      
      // Converter para blob
      canvas.toBlob(resolve, file.type, quality);
    };
    
    img.src = URL.createObjectURL(file);
  });
}

/**
 * Utilitário para lazy loading de imagens
 * Melhora a performance carregando imagens apenas quando necessário
 */

class LazyImageLoader {
  constructor() {
    this.observer = null;
    this.images = new Set();
    this.init();
  }

  init() {
    // Verificar se IntersectionObserver está disponível
    if (typeof window === 'undefined' || !('IntersectionObserver' in window)) {
      // Fallback: carregar todas as imagens imediatamente
      this.loadAllImages();
      return;
    }

    // Configurar IntersectionObserver
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.loadImage(entry.target);
            this.observer.unobserve(entry.target);
          }
        });
      },
      {
        rootMargin: '50px 0px', // Carregar 50px antes de entrar na viewport
        threshold: 0.1
      }
    );
  }

  observe(img) {
    if (this.observer) {
      this.images.add(img);
      this.observer.observe(img);
    } else {
      // Fallback: carregar imediatamente
      this.loadImage(img);
    }
  }

  unobserve(img) {
    if (this.observer) {
      this.images.delete(img);
      this.observer.unobserve(img);
    }
  }

  loadImage(img) {
    const src = img.dataset.src;
    if (!src) return;

    // Criar nova imagem para testar se carrega
    const imageLoader = new Image();
    
    imageLoader.onload = () => {
      img.src = src;
      img.classList.remove('lazy-loading');
      img.classList.add('lazy-loaded');
    };
    
    imageLoader.onerror = () => {
      img.classList.remove('lazy-loading');
      img.classList.add('lazy-error');
      // Usar placeholder de erro se disponível
      if (img.dataset.errorSrc) {
        img.src = img.dataset.errorSrc;
      }
    };
    
    img.classList.add('lazy-loading');
    imageLoader.src = src;
  }

  loadAllImages() {
    // Fallback para navegadores sem IntersectionObserver
    const lazyImages = document.querySelectorAll('img[data-src]');
    lazyImages.forEach(img => this.loadImage(img));
  }

  destroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
    this.images.clear();
  }
}

// Instância global
export const lazyImageLoader = new LazyImageLoader();

/**
 * Função helper para criar uma imagem lazy
 */
export function createLazyImage(src, alt = '', errorSrc = null) {
  return {
    src: '',
    'data-src': src,
    'data-error-src': errorSrc,
    alt,
    class: 'lazy-loading',
    style: 'opacity: 0.5; transition: opacity 0.3s;'
  };
}

/**
 * Hook Svelte para lazy loading de imagens
 */
export function useLazyImage(imgElement) {
  if (imgElement && imgElement.dataset.src) {
    lazyImageLoader.observe(imgElement);
    
    return {
      destroy() {
        lazyImageLoader.unobserve(imgElement);
      }
    };
  }
  
  return {
    destroy() {}
  };
}

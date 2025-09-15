<script>
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
</script>

<svelte:head>
  <title>Ajuda - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 py-8">
  <div class="max-w-4xl mx-auto px-4">
    <!-- Header -->
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900">Central de Ajuda</h1>
      <p class="text-gray-600 mt-2">Encontre respostas para suas dúvidas</p>
    </div>
    
    <!-- Help content -->
    <div class="bg-white rounded-lg shadow-sm p-8">
      <div class="space-y-8">
        <!-- Login issues -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Problemas de Login</h2>
          <div class="space-y-4">
            <div class="border-l-4 border-blue-500 pl-4">
              <h3 class="font-medium text-gray-900">Esqueci minha senha</h3>
              <p class="text-gray-600 text-sm mt-1">Clique em "Esqueceu sua senha?" na página de login para redefinir sua senha.</p>
            </div>
            
            <div class="border-l-4 border-green-500 pl-4">
              <h3 class="font-medium text-gray-900">Não consigo fazer login</h3>
              <p class="text-gray-600 text-sm mt-1">Verifique se seu email e senha estão corretos. Certifique-se de que confirmou seu email.</p>
            </div>
            
            <div class="border-l-4 border-yellow-500 pl-4">
              <h3 class="font-medium text-gray-900">Email não confirmado</h3>
              <p class="text-gray-600 text-sm mt-1">Verifique sua caixa de entrada e spam para o email de confirmação.</p>
            </div>
          </div>
        </div>
        
        <!-- Registration issues -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Problemas de Cadastro</h2>
          <div class="space-y-4">
            <div class="border-l-4 border-blue-500 pl-4">
              <h3 class="font-medium text-gray-900">Como criar uma conta</h3>
              <p class="text-gray-600 text-sm mt-1">1. Clique em "Criar Conta" na página de login<br>
              2. Digite seu email e senha<br>
              3. Confirme seu email<br>
              4. Complete seu perfil</p>
            </div>
            
            <div class="border-l-4 border-green-500 pl-4">
              <h3 class="font-medium text-gray-900">Senha muito fraca</h3>
              <p class="text-gray-600 text-sm mt-1">Use pelo menos 6 caracteres para sua senha.</p>
            </div>
          </div>
        </div>
        
        <!-- Contact -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Contato</h2>
          <div class="bg-gray-50 rounded-lg p-4">
            <p class="text-gray-600 text-sm">
              Se você não encontrou a resposta para sua dúvida, entre em contato conosco:
            </p>
            <div class="mt-3 space-y-2">
              <p class="text-sm"><strong>Email:</strong> suporte@intellimen.com</p>
              <p class="text-sm"><strong>Telefone:</strong> (11) 99999-9999</p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Back button -->
      <div class="mt-8 pt-6 border-t border-gray-200">
        <Button
          variant="outline"
          on:click={() => goto('/login')}
        >
          <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Voltar ao Login
        </Button>
      </div>
    </div>
  </div>
</div>

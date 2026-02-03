<script>
  import { supabase } from '$lib/supabase';
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { PUBLIC_SITE_URL } from '$env/static/public';

  // Usamos un objeto simple para evitar problemas de reactividad si usas Svelte 5
  let formState = {
    email: ''
  };
  
  let loading = false;
  let message = '';

  const getRedirectUrl = () => {
    if (PUBLIC_SITE_URL && PUBLIC_SITE_URL.trim() !== '') {
      return `${PUBLIC_SITE_URL.replace(/\/$/, '')}/app/dashboard`;
    }
    if (browser) {
      return `${window.location.origin}/app/dashboard`;
    }
    return undefined;
  };

  onMount(async () => {
    const { data } = await supabase.auth.getSession();
    if (data.session) {
      goto('/app/dashboard');
    }
  });

  const handleLogin = async () => {
    // Verificación manual antes de enviar
    if (!formState.email || formState.email.trim() === '') {
        message = '❌ El campo email parece vacío. Escribe algo.';
        return;
    }

    try {
      loading = true;
      message = '';
      const redirectUrl = getRedirectUrl();
      const { data, error } = await supabase.auth.signInWithOtp({
        email: formState.email,
        options: redirectUrl ? { emailRedirectTo: redirectUrl } : undefined
      });

      if (error) {
          throw error;
      }

      if (!data) {
        message = '✅ Si el correo existe, recibirás un enlace de acceso.';
        return;
      }

      message = '✅ ¡Correo enviado! Revisa tu bandeja de entrada.';
      
    } catch (error) {
      // Mostramos el mensaje técnico real
      message = '❌ Error Técnico: ' + (error.message || error.error_description || JSON.stringify(error));
    } finally {
      loading = false;
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gray-50">
  <div class="bg-white p-8 rounded-xl shadow-lg w-96 border border-gray-100">
    <h2 class="text-3xl font-bold mb-2 text-center text-gray-800">Bienvenido</h2>
    <p class="text-center text-gray-500 mb-8">Ingresa tu correo para entrar</p>
    
    <div class="mb-4">
      <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
      <input 
        type="email" 
        bind:value={formState.email} 
        placeholder="tu@ejemplo.com" 
        class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
      />
    </div>

    <button 
      onclick={handleLogin} 
      disabled={loading}
      class="w-full bg-blue-600 text-white p-3 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
    >
      {loading ? 'Enviando enlace...' : 'Enviar enlace de acceso'}
    </button>

    {#if message}
      <div class="mt-6 p-3 rounded-lg text-sm text-center {message.includes('Error') ? 'bg-red-50 text-red-600' : 'bg-green-50 text-green-700'}">
        {message}
      </div>
    {/if}

    <div class="mt-6 text-center">
        <a href="/" class="text-sm text-gray-400 hover:text-gray-600">← Volver al inicio</a>
    </div>
  </div>
</div>
<script>
  import { supabase } from '$lib/supabase';
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { PUBLIC_SITE_URL } from '$env/static/public';
  import logo from '$lib/assets/logo.svg';

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

<div class="min-h-screen bg-slate-50">
  <div class="mx-auto flex min-h-screen max-w-5xl items-center gap-12 px-6 py-16">
    <div class="hidden flex-1 flex-col justify-center gap-6 lg:flex">
      <img src={logo} alt="FacturasGen" class="h-12 w-12" />
      <h1 class="text-4xl font-semibold text-slate-900">Bienvenido a FacturasGen</h1>
      <p class="text-base text-slate-600">
        Accede a tu panel de facturación empresarial con un enlace seguro enviado a tu correo.
      </p>
      <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p class="text-sm text-slate-500">Ventajas principales</p>
        <ul class="mt-4 space-y-2 text-sm text-slate-700">
          <li class="flex items-center gap-2">
            <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
            Historial de facturas siempre disponible
          </li>
          <li class="flex items-center gap-2">
            <span class="h-2 w-2 rounded-full bg-blue-500"></span>
            PDF profesional con tu marca
          </li>
          <li class="flex items-center gap-2">
            <span class="h-2 w-2 rounded-full bg-slate-500"></span>
            Configuración fiscal centralizada
          </li>
        </ul>
      </div>
    </div>

    <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-xl">
      <h2 class="text-2xl font-semibold text-slate-900">Accede a tu cuenta</h2>
      <p class="mt-2 text-sm text-slate-500">Te enviaremos un enlace de acceso seguro.</p>

      <div class="mt-6">
        <label class="block text-sm font-medium text-slate-700 mb-2">Correo corporativo</label>
        <input
          type="email"
          bind:value={formState.email}
          placeholder="tu@empresa.com"
          class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition"
        />
      </div>

      <button
        onclick={handleLogin}
        disabled={loading}
        class="mt-6 w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition"
      >
        {loading ? 'Enviando enlace...' : 'Enviar enlace seguro'}
      </button>

      {#if message}
        <div class="mt-5 rounded-xl px-4 py-3 text-sm {message.includes('Error') ? 'bg-red-50 text-red-600' : 'bg-emerald-50 text-emerald-700'}">
          {message}
        </div>
      {/if}

      <div class="mt-6 text-center text-xs text-slate-400">
        Al continuar aceptas nuestro uso de acceso por correo.
      </div>

      <div class="mt-4 text-center">
        <a href="/" class="text-xs text-slate-400 hover:text-slate-600">← Volver al inicio</a>
      </div>
    </div>
  </div>
</div>
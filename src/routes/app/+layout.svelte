<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import logo from '$lib/assets/logo.svg';

  let checkingSession = true;
  let userEmail = '';

  onMount(() => {
    /** @type {{ unsubscribe: () => void } | null} */
    let subscription = null;

    const initSession = async () => {
      const { data } = await supabase.auth.getSession();
      if (!data.session) {
        goto('/?auth=required');
        return;
      }

      userEmail = data.session.user.email ?? '';
      checkingSession = false;

      const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
        if (!session) {
          goto('/?auth=required');
          return;
        }
        userEmail = session.user.email ?? '';
      });

      subscription = listener?.subscription;
    };

    initSession();

    return () => {
      subscription?.unsubscribe();
    };
  });

  // Función para cerrar sesión
  const handleLogout = async () => {
    await supabase.auth.signOut();
    goto('/'); // Redirigir a la página principal al cerrar sesión
  };
</script>

{#if checkingSession}
  <div class="min-h-screen flex items-center justify-center bg-gray-50 text-gray-400">
    Verificando sesión...
  </div>
{:else}
  <div class="flex min-h-screen bg-slate-50">
    <aside class="w-72 bg-slate-900 text-slate-200 flex flex-col">
      <div class="px-6 py-6 border-b border-slate-800">
        <a href="/" class="flex items-center gap-3 text-white hover:opacity-90 transition">
          <img src={logo} alt="FacturasGen" class="h-10 w-10" />
          <div>
            <h1 class="text-lg font-semibold text-white">FacturasGen</h1>
            {#if userEmail}
              <p class="text-xs text-slate-400 truncate max-w-[180px]">{userEmail}</p>
            {/if}
          </div>
        </a>
      </div>

      <nav class="flex-1 px-4 py-6 space-y-1">
        <a
          href="/app/dashboard"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/dashboard')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          Dashboard
        </a>
        <a
          href="/app/editor"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/editor')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          Crear factura
        </a>
        <a
          href="/app/recurring"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/recurring')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          Recurrentes
        </a>
        <a
          href="/app/settings"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/settings')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          Configuración
        </a>
      </nav>

      <div class="px-4 pb-6">
        <div class="rounded-2xl bg-slate-800/60 p-4 text-xs text-slate-300">
          <p class="font-semibold text-white">Plan gratuito</p>
          <p class="mt-1 text-slate-400">Actualiza para quitar el watermark.</p>
        </div>
        <a
          href="/pricing"
          class="mt-4 inline-flex w-full items-center justify-center rounded-xl bg-white px-4 py-2 text-xs font-semibold text-slate-900 hover:bg-slate-100 transition"
        >
          Ver plan Pro
        </a>
        <button
          onclick={handleLogout}
          class="mt-3 flex w-full items-center justify-center gap-2 rounded-xl border border-slate-700 px-4 py-2 text-xs font-semibold text-slate-300 hover:border-slate-500 hover:text-white transition"
        >
          Cerrar sesión
        </button>
      </div>
    </aside>

    <main class="flex-1">
      <div class="border-b border-slate-200 bg-white/70 backdrop-blur">
        <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-8">
          <div class="text-sm text-slate-500">
            {#if $page.url.pathname.startsWith('/app/editor')}
              {$page.url.searchParams.has('id') ? 'Editando factura' : 'Nueva factura'}
            {:else if $page.url.pathname.startsWith('/app/settings')}
              Configuración de empresa
            {:else}
              Panel de empresa
            {/if}
          </div>
          <div class="flex items-center gap-3 text-xs text-slate-500">
            <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
            Sistema operativo
          </div>
        </div>
      </div>
      <div class="mx-auto max-w-6xl px-8 py-8">
        <slot />
      </div>
    </main>
  </div>
{/if}
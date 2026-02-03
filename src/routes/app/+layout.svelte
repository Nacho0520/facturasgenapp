<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';

  let checkingSession = true;
  let userEmail = '';

  onMount(() => {
    let subscription;

    const initSession = async () => {
      const { data } = await supabase.auth.getSession();
      if (!data.session) {
        goto('/login');
        return;
      }

      userEmail = data.session.user.email ?? '';
      checkingSession = false;

      const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
        if (!session) {
          goto('/login');
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
    goto('/login'); // Nos manda al login al terminar
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
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-600 text-white font-semibold">F</div>
          <div>
            <h1 class="text-lg font-semibold text-white">FacturasGen</h1>
            {#if userEmail}
              <p class="text-xs text-slate-400 truncate max-w-[180px]">{userEmail}</p>
            {/if}
          </div>
        </div>
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
          <span class="text-lg">📊</span> Dashboard
        </a>
        <a
          href="/app/editor"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/editor')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          <span class="text-lg">📝</span> Crear factura
        </a>
        <a
          href="/app/settings"
          class={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
            $page.url.pathname.startsWith('/app/settings')
              ? 'bg-slate-800 text-white'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white'
          }`}
        >
          <span class="text-lg">⚙️</span> Configuración
        </a>
      </nav>

      <div class="px-4 pb-6">
        <div class="rounded-2xl bg-slate-800/60 p-4 text-xs text-slate-300">
          <p class="font-semibold text-white">Plan gratuito</p>
          <p class="mt-1 text-slate-400">Actualiza para quitar el watermark.</p>
        </div>
        <button
          onclick={handleLogout}
          class="mt-4 flex w-full items-center justify-center gap-2 rounded-xl border border-slate-700 px-4 py-2 text-xs font-semibold text-slate-300 hover:border-slate-500 hover:text-white transition"
        >
          🚪 Cerrar sesión
        </button>
      </div>
    </aside>

    <main class="flex-1">
      <div class="border-b border-slate-200 bg-white/70 backdrop-blur">
        <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-8">
          <div class="text-sm text-slate-500">Panel de empresa</div>
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
<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
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
  <div class="flex h-screen bg-gray-50">
  <aside class="w-64 bg-white border-r border-gray-200 flex flex-col">
    <div class="p-6 border-b border-gray-100">
      <h1 class="text-2xl font-bold text-blue-600">FacturasGen</h1>
      {#if userEmail}
        <p class="text-xs text-gray-400 mt-1 truncate">{userEmail}</p>
      {/if}
    </div>

    <nav class="flex-1 p-4 space-y-2">
      <a href="/app/dashboard" class="flex items-center px-4 py-3 text-gray-700 hover:bg-blue-50 hover:text-blue-600 rounded-lg transition-colors">
        📊 Dashboard
      </a>
      <a href="/app/editor" class="flex items-center px-4 py-3 text-gray-700 hover:bg-blue-50 hover:text-blue-600 rounded-lg transition-colors">
        📝 Crear Factura
      </a>
      <a href="/app/settings" class="flex items-center px-4 py-3 text-gray-700 hover:bg-blue-50 hover:text-blue-600 rounded-lg transition-colors">
        ⚙️ Configuración
      </a>
    </nav>

    <div class="p-4 border-t border-gray-100">
      <button 
        onclick={handleLogout}
        class="flex items-center w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
      >
        🚪 Cerrar Sesión
      </button>
    </div>
  </aside>

  <main class="flex-1 overflow-y-auto">
    <div class="p-8">
      <slot />
    </div>
  </main>
  </div>
{/if}
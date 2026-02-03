<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let invoices = $state([]);
  let loading = $state(true);
  let errorMessage = $state('');

  const formatDate = (value) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? '-' : date.toLocaleDateString();
  };

  const calculateTotal = (invoice) => {
    const items = invoice.line_items ?? [];
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0);
    const taxRate = invoice.tax_rate ?? 0;
    return subtotal * (1 + taxRate / 100);
  };

  onMount(async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Sesión expirada. Inicia sesión de nuevo.');

      const { data, error } = await supabase
        .from('invoices')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      invoices = data ?? [];
    } catch (error) {
      errorMessage = error.message ?? 'Error al cargar las facturas.';
    } finally {
      loading = false;
    }
  });
</script>

<div class="max-w-4xl mx-auto">
  <div class="flex justify-between items-center mb-8">
    <div>
      <h2 class="text-3xl font-bold text-gray-800">Mis Facturas</h2>
      <p class="text-gray-500">Gestiona tus ingresos desde aquí.</p>
    </div>
    <a href="/app/editor" class="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 shadow-md font-medium flex items-center gap-2">
      + Nueva Factura
    </a>
  </div>

  {#if loading}
    <div class="text-center py-12 text-gray-400">Cargando facturas...</div>
  {:else if errorMessage}
    <div class="bg-red-50 border border-red-100 text-red-600 p-6 rounded-xl text-center">
      {errorMessage}
    </div>
  {:else if invoices.length === 0}
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
      <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
        📄
      </div>
      <h3 class="text-lg font-medium text-gray-900 mb-2">Aún no tienes facturas</h3>
      <p class="text-gray-500 mb-6 max-w-sm mx-auto">Crea tu primera factura profesional en menos de 2 minutos y envíala a tu cliente.</p>

      <a href="/app/editor" class="text-blue-600 font-medium hover:underline">
        Empezar ahora &rarr;
      </a>
    </div>
  {:else}
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <table class="w-full text-left">
        <thead class="bg-gray-50 text-gray-500 text-sm uppercase">
          <tr>
            <th class="px-6 py-4">Nº</th>
            <th class="px-6 py-4">Cliente</th>
            <th class="px-6 py-4">Fecha</th>
            <th class="px-6 py-4 text-right">Total</th>
            <th class="px-6 py-4 text-center">Estado</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          {#each invoices as invoice}
            <tr class="hover:bg-gray-50 transition-colors cursor-pointer" onclick={() => goto(`/app/editor?id=${invoice.id}`)}>
              <td class="px-6 py-4 font-medium text-gray-900">{invoice.number ?? '-'}</td>
              <td class="px-6 py-4 text-gray-600">{invoice.client_name || 'Sin nombre'}</td>
              <td class="px-6 py-4 text-gray-500">{formatDate(invoice.created_at)}</td>
              <td class="px-6 py-4 text-right font-bold text-gray-900">{calculateTotal(invoice).toFixed(2)} €</td>
              <td class="px-6 py-4 text-center">
                <span class="px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                  {invoice.status ?? 'draft'}
                </span>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
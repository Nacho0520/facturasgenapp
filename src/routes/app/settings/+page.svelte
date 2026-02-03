<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let profile = $state({
    business_name: '',
    tax_id: '',
    address: '',
    logo_url: ''
  });

  let loading = $state(true);
  let saving = $state(false);
  let message = $state('');

  const loadProfile = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Sesión expirada. Inicia sesión de nuevo.');

      const { data, error } = await supabase
        .from('profiles')
        .select('business_name, tax_id, address, logo_url')
        .eq('id', user.id)
        .maybeSingle();

      if (error) throw error;
      if (data) {
        profile = {
          business_name: data.business_name ?? '',
          tax_id: data.tax_id ?? '',
          address: data.address ?? '',
          logo_url: data.logo_url ?? ''
        };
      }
    } catch (error) {
      message = error.message ?? 'No se pudo cargar la configuración.';
    } finally {
      loading = false;
    }
  };

  const saveProfile = async () => {
    try {
      saving = true;
      message = '';

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Sesión expirada. Inicia sesión de nuevo.');

      const { error } = await supabase.from('profiles').upsert({
        id: user.id,
        business_name: profile.business_name,
        tax_id: profile.tax_id,
        address: profile.address,
        logo_url: profile.logo_url
      });

      if (error) throw error;
      message = '✅ Datos guardados correctamente.';
    } catch (error) {
      message = '❌ ' + (error.message ?? 'Error al guardar.');
    } finally {
      saving = false;
    }
  };

  onMount(loadProfile);
</script>

<div class="max-w-3xl mx-auto">
  <div class="mb-8">
    <h2 class="text-3xl font-bold text-gray-800">Configuración</h2>
    <p class="text-gray-500">Personaliza los datos que aparecerán en tus facturas.</p>
  </div>

  {#if loading}
    <div class="text-gray-400">Cargando configuración...</div>
  {:else}
    <form class="bg-white rounded-xl shadow-sm border border-gray-100 p-8 space-y-6" onsubmit={(event) => { event.preventDefault(); saveProfile(); }}>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Nombre del negocio</label>
        <input
          type="text"
          bind:value={profile.business_name}
          placeholder="Tu empresa o nombre fiscal"
          class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">NIF/CIF</label>
        <input
          type="text"
          bind:value={profile.tax_id}
          placeholder="B12345678"
          class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Dirección fiscal</label>
        <textarea
          rows="3"
          bind:value={profile.address}
          placeholder="Calle, número, ciudad, país"
          class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
        ></textarea>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Logo (URL)</label>
        <input
          type="url"
          bind:value={profile.logo_url}
          placeholder="https://"
          class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
        />
      </div>

      <div class="flex items-center gap-4">
        <button
          type="submit"
          disabled={saving}
          class="bg-blue-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {saving ? 'Guardando...' : 'Guardar cambios'}
        </button>
        {#if message}
          <span class="text-sm text-gray-500">{message}</span>
        {/if}
      </div>
    </form>
  {/if}
</div>

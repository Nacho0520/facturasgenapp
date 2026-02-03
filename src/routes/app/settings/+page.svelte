<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
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

  const fieldIds = {
    businessName: 'business-name',
    taxId: 'tax-id',
    address: 'tax-address',
    logoUrl: 'logo-url'
  };

  const loadProfile = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        goto('/?auth=required');
        return;
      }

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
      const err = /** @type {Error} */ (error);
      message = err.message ?? 'No se pudo cargar la configuración.';
    } finally {
      loading = false;
    }
  };

  const saveProfile = async () => {
    try {
      saving = true;
      message = '';

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        goto('/?auth=required');
        return;
      }

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
      const err = /** @type {Error} */ (error);
      message = '❌ ' + (err.message ?? 'Error al guardar.');
    } finally {
      saving = false;
    }
  };

  onMount(loadProfile);
</script>

<div class="space-y-8">
  <div>
    <h2 class="text-3xl font-semibold text-slate-900">Configuración</h2>
    <p class="text-sm text-slate-500">Estos datos se mostrarán en tus facturas oficiales.</p>
  </div>

  {#if loading}
    <div class="rounded-2xl border border-slate-200 bg-white p-8 text-slate-400">
      Cargando configuración...
    </div>
  {:else}
    <div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
      <form class="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm space-y-6" onsubmit={(event) => { event.preventDefault(); saveProfile(); }}>
        <div>
        <label class="block text-sm font-medium text-slate-700 mb-2" for={fieldIds.businessName}>Nombre del negocio</label>
          <input
            type="text"
          id={fieldIds.businessName}
            bind:value={profile.business_name}
            placeholder="Tu empresa o nombre fiscal"
            class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition"
          />
        </div>

        <div>
        <label class="block text-sm font-medium text-slate-700 mb-2" for={fieldIds.taxId}>NIF/CIF</label>
          <input
            type="text"
          id={fieldIds.taxId}
            bind:value={profile.tax_id}
            placeholder="B12345678"
            class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition"
          />
        </div>

        <div>
        <label class="block text-sm font-medium text-slate-700 mb-2" for={fieldIds.address}>Dirección fiscal</label>
          <textarea
            rows="4"
          id={fieldIds.address}
            bind:value={profile.address}
            placeholder="Calle, número, ciudad, país"
            class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition"
          ></textarea>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2" for={fieldIds.logoUrl}>Logo (URL)</label>
          <input
            type="url"
            id={fieldIds.logoUrl}
            bind:value={profile.logo_url}
            placeholder="https://"
            class="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition"
          />
          <p class="mt-2 text-xs text-slate-400">Recomendamos subir el logo a tu propio hosting; URLs externas pueden fallar al generar el PDF por CORS.</p>
        </div>

        <div class="flex flex-wrap items-center gap-4">
          <button
            type="submit"
            disabled={saving}
            class="rounded-full bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition"
          >
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
          {#if message}
            <span class="text-xs text-slate-500">{message}</span>
          {/if}
        </div>
      </form>

      <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p class="text-xs uppercase tracking-wide text-slate-400">Vista previa</p>
        <div class="mt-4 rounded-2xl border border-slate-100 bg-slate-50 p-4">
          {#if profile.logo_url}
            <img src={profile.logo_url} alt="Logo" class="h-10 w-auto object-contain mb-3" />
          {:else}
            <div class="h-10 w-24 rounded-lg bg-slate-200 mb-3"></div>
          {/if}
          <p class="text-sm font-semibold text-slate-900">{profile.business_name || 'Tu empresa'}</p>
          <p class="text-xs text-slate-500">{profile.tax_id || 'NIF/CIF'}</p>
          <p class="mt-2 text-xs text-slate-500 whitespace-pre-line">{profile.address || 'Dirección fiscal'}</p>
        </div>
      </div>
    </div>
  {/if}
</div>

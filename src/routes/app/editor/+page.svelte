<script>
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import html2pdf from 'html2pdf.js'; // Asegúrate de haber hecho: npm install html2pdf.js

  // --- ESTADOS (Svelte 5) ---
  let clientName = $state("");
  let taxRate = $state(21);
  let profile = $state({
    business_name: "",
    tax_id: "",
    address: "",
    logo_url: ""
  });
  let showWatermark = $state(true);
  let items = $state([
    { desc: "", price: 0, qty: 1 }
  ]);
  
  let saving = $state(false);
  let user = $state(null);

  // --- CÁLCULOS REACTIVOS ---
  const subtotal = () => items.reduce((sum, item) => sum + (item.price * item.qty), 0);
  const total = () => subtotal() + (subtotal() * (taxRate / 100));

  onMount(async () => {
    const { data } = await supabase.auth.getUser();
    user = data.user;

    if (user) {
      const { data: profileData } = await supabase
        .from('profiles')
        .select('business_name, tax_id, address, logo_url')
        .eq('id', user.id)
        .maybeSingle();

      if (profileData) {
        profile = {
          business_name: profileData.business_name ?? "",
          tax_id: profileData.tax_id ?? "",
          address: profileData.address ?? "",
          logo_url: profileData.logo_url ?? ""
        };
      }
    }

    if (typeof localStorage !== 'undefined') {
      showWatermark = localStorage.getItem('facturasgen_pro') !== 'true';
    }
  });

  // --- FUNCIONES DE LA TABLA ---
  function addItem() {
    items.push({ desc: "", price: 0, qty: 1 });
  }

  function removeItem(index) {
    items = items.filter((_, i) => i !== index);
  }

  // --- GENERACIÓN DE PDF ---
  function downloadPDF() {
    const element = document.getElementById('invoice-canvas');
    const opt = {
      margin:       [0.5, 0.5],
      filename:     `Factura_${clientName.replace(/\s+/g, '_') || 'SaaS'}.pdf`,
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2, useCORS: true },
      jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
    };

    html2pdf().set(opt).from(element).save();
  }

  // --- GUARDADO EN BD ---
  async function saveInvoice() {
    if (!clientName) return alert("Por favor, escribe el nombre del cliente");

    try {
      saving = true;
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      
      if (!currentUser) throw new Error("Sesión expirada. Inicia sesión de nuevo.");

      const { error } = await supabase.from('invoices').insert({
        user_id: currentUser.id,
        client_name: clientName,
        line_items: items,
        tax_rate: taxRate,
        status: 'sent'
      });

      if (error) throw error;
      alert("¡Factura guardada correctamente!");
      goto('/app/dashboard');
    } catch (err) {
      alert("Error: " + err.message);
    } finally {
      saving = false;
    }
  }
</script>

<div class="max-w-5xl mx-auto p-6">
  <div class="flex justify-between items-center mb-8 bg-gray-50 p-4 rounded-xl border border-gray-200 shadow-sm">
    <h1 class="text-xl font-bold text-gray-700">Panel de Control</h1>
    
    <div class="flex gap-3">
      <button 
        onclick={downloadPDF}
        class="bg-gray-800 text-white px-5 py-2 rounded-lg font-bold hover:bg-black transition-all flex items-center gap-2"
      >
        <span>📄</span> Descargar PDF
      </button>

      <button 
        onclick={saveInvoice}
        disabled={saving || !user}
        class="bg-blue-600 text-white px-5 py-2 rounded-lg font-bold hover:bg-blue-700 disabled:opacity-50 transition-all flex items-center gap-2"
      >
        {saving ? '...' : '💾'} {saving ? 'Guardando' : 'Guardar en Nube'}
      </button>
    </div>
  </div>

  <div id="invoice-canvas" class="bg-white rounded-sm shadow-2xl border border-gray-200 p-12 min-h-[1050px] w-[800px] mx-auto overflow-hidden">
    
    <div class="flex justify-between items-start mb-16">
      <div>
        <h2 class="text-5xl font-black text-gray-900 tracking-tighter mb-2">FACTURA</h2>
        <p class="text-gray-400 font-mono italic"># INV-{Math.floor(Math.random() * 1000)}</p>
        <div class="mt-6 text-sm text-gray-500 space-y-1 max-w-xs">
          {#if profile.business_name}
            <div class="text-gray-700 font-semibold">{profile.business_name}</div>
          {/if}
          {#if profile.tax_id}
            <div>NIF/CIF: {profile.tax_id}</div>
          {/if}
          {#if profile.address}
            <div class="whitespace-pre-line">{profile.address}</div>
          {/if}
        </div>
      </div>
      <div class="text-right">
        {#if profile.logo_url}
          <img src={profile.logo_url} alt="Logo" class="h-16 w-auto object-contain ml-auto mb-2" />
        {:else}
          <div class="bg-blue-600 text-white p-4 font-bold rounded-lg inline-block mb-2">LOGO</div>
        {/if}
        <p class="text-sm text-gray-400 uppercase tracking-widest">Original Document</p>
      </div>
    </div>

    <div class="mb-12">
      <label class="block text-xs font-bold text-blue-600 uppercase mb-2 tracking-widest">Información del Cliente</label>
      <input 
        type="text" 
        bind:value={clientName} 
        placeholder="Nombre del Cliente o Empresa"
        class="w-full text-3xl font-bold border-b-2 border-gray-100 focus:border-blue-500 outline-none pb-2 transition-all"
      />
    </div>

    <div class="mb-10">
      <div class="grid grid-cols-12 gap-4 mb-4 text-xs font-bold text-gray-400 uppercase px-2 border-b pb-2">
        <div class="col-span-6">Descripción del Servicio</div>
        <div class="col-span-2 text-right">Cant.</div>
        <div class="col-span-2 text-right">Precio</div>
        <div class="col-span-2 text-right">Total</div>
      </div>

      {#each items as item, i}
        <div class="grid grid-cols-12 gap-4 items-center mb-1 group border-b border-gray-50 p-2 hover:bg-blue-50/30 transition-colors">
          <div class="col-span-6">
            <input type="text" bind:value={item.desc} placeholder="Ej. Diseño de Interfaz" class="w-full bg-transparent outline-none font-medium text-gray-700" />
          </div>
          <div class="col-span-2 text-right">
            <input type="number" bind:value={item.qty} class="w-full text-right bg-transparent outline-none" />
          </div>
          <div class="col-span-2 text-right">
            <input type="number" bind:value={item.price} class="w-full text-right bg-transparent outline-none" />
          </div>
          <div class="col-span-1 text-right font-bold text-gray-900">
            {(item.price * item.qty).toFixed(2)}€
          </div>
          <div class="col-span-1 text-right">
            <button onclick={() => removeItem(i)} class="text-gray-200 hover:text-red-500 transition-colors">✕</button>
          </div>
        </div>
      {/each}
      
      <button onclick={addItem} class="mt-6 text-blue-600 font-bold text-sm flex items-center gap-1 hover:text-blue-800 transition-all">
        <span class="text-lg">+</span> Añadir concepto
      </button>
    </div>

    <div class="flex justify-end pt-10 mt-20 border-t-4 border-gray-900">
      <div class="w-72 space-y-4">
        <div class="flex justify-between text-gray-500 font-medium">
          <span>Subtotal</span>
          <span>{subtotal().toFixed(2)} €</span>
        </div>
        <div class="flex justify-between text-gray-500 items-center">
          <span>Impuestos (IVA {taxRate}%)</span>
          <div class="flex items-center gap-1">
            <input type="number" bind:value={taxRate} class="w-10 text-right border-b border-gray-200 outline-none text-sm" />%
          </div>
        </div>
        <div class="flex justify-between text-3xl font-black text-gray-900 pt-4">
          <span>TOTAL</span>
          <span class="text-blue-600">{total().toFixed(2)} €</span>
        </div>
      </div>
    </div>

    <div class="mt-32 text-xs text-gray-300 border-t pt-4 italic">
      Gracias por su confianza. Este documento es una factura válida generada mediante FacturasGen SaaS.
    </div>
    {#if showWatermark}
      <div class="mt-6 text-[10px] text-gray-300 text-center uppercase tracking-[0.3em]">
        Generado con FacturasGen
      </div>
    {/if}
  </div>
</div>

<style>
  /* Evitar que los inputs se vean como bordes al imprimir */
  input::-webkit-outer-spin-button,
  input::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }
</style>
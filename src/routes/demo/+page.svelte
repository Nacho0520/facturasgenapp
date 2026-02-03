<script>
  import logo from '$lib/assets/logo.svg';
  let clientName = $state('Empresa Demo S.L.');
  let taxRate = $state(21);
  let template = $state('classic');
  let items = $state([
    { desc: 'Consultoría estratégica', price: 750, qty: 1 },
    { desc: 'Implementación', price: 500, qty: 1 }
  ]);

  const subtotal = () => items.reduce((sum, item) => sum + item.price * item.qty, 0);
  const total = () => subtotal() * (1 + taxRate / 100);

  const templateClass = () => {
    if (template === 'minimal') return 'border-slate-100 bg-white';
    if (template === 'modern') return 'border-blue-100 bg-gradient-to-br from-white via-white to-blue-50/40';
    return 'border-slate-200 bg-white';
  };

  const templateHeaderClass = () => {
    if (template === 'minimal') return 'text-slate-900';
    if (template === 'modern') return 'text-blue-700';
    return 'text-slate-900';
  };

  const templateAccentClass = () => {
    if (template === 'minimal') return 'text-slate-500';
    if (template === 'modern') return 'text-blue-600';
    return 'text-slate-500';
  };

  const templateDividerClass = () => {
    if (template === 'minimal') return 'border-slate-100';
    if (template === 'modern') return 'border-blue-100';
    return 'border-slate-100';
  };

  const templatePanelClass = () => {
    if (template === 'minimal') return 'rounded-none border-slate-100 shadow-none';
    if (template === 'modern') return 'rounded-3xl border-blue-100 shadow-2xl';
    return 'rounded-2xl border-slate-200 shadow-xl';
  };

  const templatePillClass = () => {
    if (template === 'minimal') return 'bg-slate-100 text-slate-500';
    if (template === 'modern') return 'bg-blue-50 text-blue-700';
    return 'bg-slate-100 text-slate-600';
  };

  const watermarkRadiusClass = () => {
    if (template === 'minimal') return '';
    return 'rounded-3xl';
  };
</script>

<div class="min-h-screen bg-slate-50">
  <header class="border-b border-slate-200 bg-white/70 backdrop-blur">
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
      <a href="/" class="flex items-center gap-3 text-slate-900 hover:opacity-90 transition">
        <img src={logo} alt="FacturasGen" class="h-9 w-9" />
        <span class="text-lg font-semibold">FacturasGen</span>
      </a>
      <div class="flex items-center gap-3">
        <a href="/" class="rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 hover:border-slate-300">
          Volver
        </a>
        <a href="/login" class="rounded-full bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700">
          Crear cuenta
        </a>
      </div>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-6 py-16 space-y-8">
    <div>
      <p class="text-xs font-semibold uppercase tracking-[0.3em] text-blue-600">Demo</p>
      <h1 class="mt-4 text-3xl font-semibold text-slate-900">Prueba la experiencia sin registrarte</h1>
      <p class="mt-2 text-sm text-slate-500">
        Esta demo genera PDFs con marca de agua y no guarda datos en la nube.
      </p>
    </div>

    <div class="grid gap-6 lg:grid-cols-[1fr_2fr]">
      <aside class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm space-y-6">
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400" for="demo-template">Plantilla</label>
          <select id="demo-template" bind:value={template} class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm">
            <option value="classic">Clásica</option>
            <option value="modern">Moderna</option>
            <option value="minimal">Minimal</option>
          </select>
          <p class="mt-2 text-xs text-slate-400">Más plantillas profesionales disponibles en Pro.</p>
        </div>
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400" for="demo-client">Cliente</label>
          <input
            type="text"
            id="demo-client"
            bind:value={clientName}
            class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400" for="demo-tax">IVA</label>
          <input id="demo-tax" type="number" bind:value={taxRate} class="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
        </div>
      </aside>

      <div class={`relative border ${templateClass()} ${templatePanelClass()} p-10`}>
        <div class={`pointer-events-none absolute inset-0 overflow-hidden ${watermarkRadiusClass()}`}>
          <div class="absolute -left-1/2 top-1/2 w-[200%] -translate-y-1/2 rotate-[-30deg] opacity-10">
            <div class="flex flex-col gap-6 text-[48px] font-semibold uppercase tracking-[0.45em] text-slate-400">
              <div class="flex justify-center gap-10">
                <span>FACTURASGEN</span><span>FACTURASGEN</span><span>FACTURASGEN</span>
              </div>
              <div class="flex justify-center gap-10">
                <span>FACTURASGEN</span><span>FACTURASGEN</span><span>FACTURASGEN</span>
              </div>
              <div class="flex justify-center gap-10">
                <span>FACTURASGEN</span><span>FACTURASGEN</span><span>FACTURASGEN</span>
              </div>
            </div>
          </div>
        </div>

        <div class="relative">
          {#if template === 'modern'}
            <div class="rounded-2xl bg-blue-600 px-6 py-5 text-white">
              <div class="flex items-start justify-between">
                <div>
                  <p class="text-xs uppercase tracking-[0.35em] text-blue-100">Factura</p>
                  <h2 class="mt-2 text-4xl font-semibold">INV-DEMO</h2>
                  <div class="mt-3 flex items-center gap-3 text-xs text-blue-100">
                    <span class="rounded-full bg-white/15 px-2 py-1">Emitida</span>
                    <span>03/02/2026</span>
                  </div>
                </div>
                <div class="text-right text-xs text-blue-100">
                  FacturasGen Demo
                </div>
              </div>
            </div>

            <div class="mt-6 grid gap-6 md:grid-cols-[2fr_1fr]">
              <div class="space-y-5">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.2em] text-blue-600">Cliente</p>
                  <p class="mt-2 text-xl font-semibold text-slate-900">{clientName}</p>
                </div>
                <div class="rounded-2xl border border-blue-100 bg-blue-50/60 p-4">
                  <div class="flex justify-between text-xs uppercase tracking-[0.2em] text-blue-600">
                    <span>Concepto</span>
                    <span>Importe</span>
                  </div>
                  <div class="mt-3 space-y-3">
                    {#each items as item}
                      <div class="flex items-center justify-between text-sm text-slate-600">
                        <span>{item.desc}</span>
                        <span>{(item.price * item.qty).toFixed(2)} €</span>
                      </div>
                    {/each}
                  </div>
                </div>
              </div>

              <div class="rounded-2xl border border-slate-100 bg-white p-4 shadow-sm">
                <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Resumen</p>
                <div class="mt-4 space-y-3 text-sm text-slate-600">
                  <div class="flex justify-between">
                    <span>Subtotal</span>
                    <span>{subtotal().toFixed(2)} €</span>
                  </div>
                  <div class="flex justify-between">
                    <span>IVA</span>
                    <span>{taxRate}%</span>
                  </div>
                  <div class="flex justify-between border-t border-slate-100 pt-3 text-base font-semibold text-slate-900">
                    <span>Total</span>
                    <span>{total().toFixed(2)} €</span>
                  </div>
                </div>
                <p class="mt-4 text-xs text-slate-400">Pago por transferencia bancaria</p>
              </div>
            </div>
          {:else if template === 'minimal'}
            <div class="space-y-10">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-xs uppercase tracking-[0.35em] text-slate-400">Factura</p>
                  <h2 class="mt-2 text-3xl font-semibold text-slate-900">INV-DEMO</h2>
                </div>
                <div class="text-right text-xs text-slate-400">
                  Documento de ejemplo
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-[2fr_1fr]">
                <div>
                  <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Cliente</p>
                  <p class="mt-2 text-lg font-semibold text-slate-900">{clientName}</p>
                </div>
                <div class="text-right text-xs text-slate-400">
                  03/02/2026
                </div>
              </div>

              <div class="space-y-3">
                {#each items as item}
                  <div class="flex items-center justify-between border-b border-slate-100 pb-3 text-sm text-slate-600">
                    <span>{item.desc}</span>
                    <span>{(item.price * item.qty).toFixed(2)} €</span>
                  </div>
                {/each}
              </div>

              <div class="flex items-center justify-between text-sm text-slate-500">
                <span>Subtotal</span>
                <span>{subtotal().toFixed(2)} €</span>
              </div>
              <div class="flex items-center justify-between text-sm text-slate-500">
                <span>IVA ({taxRate}%)</span>
                <span>{(subtotal() * taxRate / 100).toFixed(2)} €</span>
              </div>
              <div class="flex items-center justify-between text-lg font-semibold text-slate-900">
                <span>Total</span>
                <span>{total().toFixed(2)} €</span>
              </div>
            </div>
          {:else}
            <div>
              <div class="flex items-start justify-between">
                <div>
                  <p class={`text-xs uppercase tracking-[0.3em] ${templateAccentClass()}`}>Factura</p>
                  <h2 class={`mt-2 text-3xl font-semibold ${templateHeaderClass()}`}>INV-DEMO</h2>
                </div>
                <div class={`text-right text-xs ${templateAccentClass()}`}>
                  Documento de ejemplo
                </div>
              </div>

              <div class="mt-8 grid gap-4 md:grid-cols-2">
                <div>
                  <p class={`text-xs font-semibold uppercase tracking-[0.2em] ${templateAccentClass()}`}>Cliente</p>
                  <p class={`mt-2 text-xl font-semibold ${templateHeaderClass()}`}>{clientName}</p>
                </div>
                <div class="text-sm text-slate-500 md:text-right">
                  <p class="uppercase text-xs tracking-[0.2em] text-slate-400">Pago</p>
                  <p class="mt-2">Transferencia bancaria</p>
                </div>
              </div>

              <div class={`mt-8 border-t ${templateDividerClass()} pt-4`}>
                <div class="flex justify-between text-xs uppercase tracking-[0.2em] text-slate-400">
                  <span>Concepto</span>
                  <span>Importe</span>
                </div>
                <div class="mt-3 space-y-3">
                  {#each items as item}
                    <div class="flex items-center justify-between text-sm text-slate-600">
                      <span>{item.desc}</span>
                      <span>{(item.price * item.qty).toFixed(2)} €</span>
                    </div>
                  {/each}
                </div>
              </div>

              <div class="mt-10 flex items-center justify-between">
                <div class="text-xs text-slate-400">
                  Gracias por confiar en FacturasGen.
                </div>
                <div class="text-right">
                  <p class={`text-xs ${templateAccentClass()}`}>Total</p>
                  <p class={`text-2xl font-semibold ${templateHeaderClass()}`}>{total().toFixed(2)} €</p>
                </div>
              </div>
            </div>
          {/if}
        </div>
      </div>
    </div>
  </main>
</div>

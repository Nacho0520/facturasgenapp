<script>
  import logo from '$lib/assets/logo.svg';
  import { page } from '$app/stores';
</script>

<div class="min-h-screen bg-slate-50">
  <header class="border-b border-slate-200 bg-white/70 backdrop-blur">
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
      <a href="/" class="flex items-center gap-3 text-slate-900 hover:opacity-90 transition">
        <img src={logo} alt="FacturasGen" class="h-9 w-9" />
        <span class="text-lg font-semibold">FacturasGen</span>
      </a>
      <div class="flex items-center gap-3 text-sm">
        <a href="/login" class="text-slate-600 hover:text-slate-900">Acceder</a>
        <a href="/login" class="rounded-full bg-blue-600 px-4 py-2 text-white font-medium hover:bg-blue-700">
          Crear cuenta
        </a>
      </div>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-6 py-16">
    {#if $page.url.searchParams.get('auth') === 'required'}
      <div class="mb-8 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 text-sm text-amber-800">
        <span>Para acceder al panel necesitas iniciar sesión. Puedes entrar con tu correo o probar la demo sin cuenta.</span>
        <div class="flex flex-wrap gap-2">
          <a href="/login" class="rounded-full bg-amber-600 px-4 py-2 text-xs font-semibold text-white hover:bg-amber-700">
            Iniciar sesión
          </a>
          <a href="/demo" class="rounded-full border border-amber-300 px-4 py-2 text-xs font-semibold text-amber-800 hover:border-amber-400">
            Ver demo
          </a>
        </div>
      </div>
    {/if}
    <div class="grid items-center gap-12 lg:grid-cols-2">
      <div>
        <p class="inline-flex items-center gap-2 rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
          Herramienta profesional para empresas
        </p>
        <h1 class="mt-6 text-4xl font-semibold text-slate-900 sm:text-5xl">
          Facturación moderna, clara y lista para enviar en minutos.
        </h1>
        <p class="mt-4 text-lg text-slate-600">
          Crea facturas con identidad corporativa, guarda tus clientes y controla tu historial con
          una experiencia simple y confiable.
        </p>
        <div class="mt-8 flex flex-wrap items-center gap-4">
          <a href="/login" class="rounded-full bg-blue-600 px-6 py-3 text-white font-semibold hover:bg-blue-700">
            Empezar gratis
          </a>
          <a href="/demo" class="rounded-full border border-slate-200 px-6 py-3 text-slate-700 font-semibold hover:border-slate-300">
            Ver demo
          </a>
        </div>
        <div class="mt-8 flex items-center gap-6 text-sm text-slate-500">
          <div class="flex items-center gap-2">
            <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
            Datos seguros
          </div>
          <div class="flex items-center gap-2">
            <span class="h-2 w-2 rounded-full bg-blue-500"></span>
            PDF listo para enviar
          </div>
        </div>
      </div>

      <div class="rounded-3xl border border-slate-200 bg-white p-6 shadow-xl">
        <div class="rounded-2xl border border-slate-100 bg-slate-50 p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs text-slate-400">Factura</p>
              <h3 class="text-xl font-semibold text-slate-900">INV-2045</h3>
            </div>
            <div class="text-right">
              <p class="text-xs text-slate-400">Total</p>
              <p class="text-2xl font-semibold text-blue-600">1.250 €</p>
            </div>
          </div>
          <div class="mt-6 space-y-3">
            <div class="flex items-center justify-between text-sm text-slate-600">
              <span>Consultoría estratégica</span>
              <span>750 €</span>
            </div>
            <div class="flex items-center justify-between text-sm text-slate-600">
              <span>Implementación</span>
              <span>500 €</span>
            </div>
            <div class="border-t border-slate-200 pt-3 text-sm text-slate-500">
              Factura aprobada · Lista para enviar
            </div>
          </div>
        </div>
        <div class="mt-6 grid gap-4 sm:grid-cols-3 text-sm text-slate-600">
          <div class="rounded-2xl border border-slate-100 bg-white p-4">
            <p class="text-xs text-slate-400">Clientes</p>
            <p class="text-lg font-semibold text-slate-900">24</p>
          </div>
          <div class="rounded-2xl border border-slate-100 bg-white p-4">
            <p class="text-xs text-slate-400">Facturas</p>
            <p class="text-lg font-semibold text-slate-900">128</p>
          </div>
          <div class="rounded-2xl border border-slate-100 bg-white p-4">
            <p class="text-xs text-slate-400">Cobrado</p>
            <p class="text-lg font-semibold text-slate-900">18,4k €</p>
          </div>
        </div>
      </div>
    </div>

    <section class="mt-20 grid gap-6 md:grid-cols-3">
      <div class="rounded-2xl border border-slate-200 bg-white p-6">
        <h3 class="text-lg font-semibold text-slate-900">Marca consistente</h3>
        <p class="mt-2 text-sm text-slate-600">
          Logo, datos fiscales y diseño alineados con tu identidad corporativa.
        </p>
      </div>
      <div class="rounded-2xl border border-slate-200 bg-white p-6">
        <h3 class="text-lg font-semibold text-slate-900">Control de historial</h3>
        <p class="mt-2 text-sm text-slate-600">
          Acceso instantáneo a facturas y estados desde cualquier dispositivo.
        </p>
      </div>
      <div class="rounded-2xl border border-slate-200 bg-white p-6">
        <h3 class="text-lg font-semibold text-slate-900">PDF profesional</h3>
        <p class="mt-2 text-sm text-slate-600">
          Exporta en segundos con un formato listo para enviar al cliente.
        </p>
      </div>
    </section>

    <footer class="mt-20 border-t border-slate-200 py-8 text-center text-sm text-slate-500">
      <a href="/privacy" class="text-slate-600 hover:text-slate-900">Política de privacidad</a>
    </footer>
  </main>
</div>
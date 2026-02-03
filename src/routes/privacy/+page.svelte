<script>
  import { goto } from '$app/navigation';
</script>

<svelte:head>
  <title>Política de privacidad - FacturasGen</title>
</svelte:head>

<div class="mx-auto max-w-3xl px-6 py-12 text-slate-700">
  <h1 class="text-3xl font-semibold text-slate-900">Política de privacidad</h1>
  <p class="mt-2 text-sm text-slate-500">Última actualización: febrero 2025</p>

  <div class="mt-10 space-y-8 text-sm leading-relaxed">
    <section>
      <h2 class="text-lg font-semibold text-slate-900">1. Responsable del tratamiento</h2>
      <p>Los datos que introduces en FacturasGen (datos fiscales, clientes, facturas) son tratados por el titular del servicio. No vendemos ni compartimos tus datos con terceros para marketing.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">2. Datos que procesamos</h2>
      <p>Procesamos los datos necesarios para el servicio: email de acceso, nombre del negocio, NIF/CIF, dirección fiscal, datos de clientes y conceptos de facturas. Estos datos pueden incluir información personal (PII) y se almacenan de forma segura.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">3. Finalidad y base legal</h2>
      <p>Utilizamos tus datos para prestar el servicio de facturación (crear, guardar y emitir facturas). La base legal es la ejecución del contrato y tu consentimiento. No utilizamos payloads de factura en logs de servidor.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">4. Almacenamiento y seguridad</h2>
      <p>Los datos se almacenan en infraestructura con cifrado en reposo. El acceso a facturas y perfiles está protegido por autenticación y políticas de fila (RLS). Los PDFs generados en plan Pro se guardan en almacenamiento privado con enlaces firmados de corta duración.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">5. Derechos (GDPR)</h2>
      <p>Si resides en la UE, tienes derecho a acceder, rectificar, suprimir y limitar el tratamiento de tus datos, así como a la portabilidad y a oponerte. Puedes ejercer estos derechos contactando al responsable del servicio. Tienes derecho a reclamar ante la autoridad de control.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">6. Cookies y sesión</h2>
      <p>Utilizamos cookies de sesión para el inicio de sesión (Magic Link) y el correcto funcionamiento de la aplicación. No utilizamos cookies de seguimiento para publicidad.</p>
    </section>

    <section>
      <h2 class="text-lg font-semibold text-slate-900">7. Contacto</h2>
      <p>Para cualquier consulta sobre privacidad o ejercicio de derechos, utiliza el canal de contacto indicado en la aplicación o en la web.</p>
    </section>
  </div>

  <div class="mt-12">
    <button
      type="button"
      onclick={() => goto('/')}
      class="rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition"
    >
      Volver al inicio
    </button>
  </div>
</div>

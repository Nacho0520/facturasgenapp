# Roadmap estratégico (FacturasGen)

Basado en el informe de riesgos y escalabilidad. Prioridad: **antes del Public Launch**.

---

## Resumen de lo implementado (estado actual)

- **RLS hardening**: trigger que impide bajar `status` de emitida a borrador y modificar `number` en facturas emitidas (`002_rls_hardening_invoices.sql`).
- **Ruta print**: `/invoice/[id]/print` para vista impresión (sin sidebar); soporte opcional con token para PDF server-side (`+page.server.js` con `SUPABASE_SERVICE_ROLE_KEY` y `PDF_TOKEN_SECRET`).
- **API PDF**: `POST /api/invoice/[id]/pdf` con `Authorization: Bearer <token>`; devuelve `printUrl` y opcionalmente `signedUrl` si existe PDF en Storage.
- **Dashboard**: paginación por cursor, métricas vía RPC, columna "Enviado a" y botón "Enviar" para guardar `email_sent_to`.
- **Editor**: autosave, estados Guardando/Guardado/Error, "Vista impresión", navegación por Tab entre campos de conceptos, mensaje "Factura bloqueada" para emitidas, presets de impuestos (IVA, IRPF, rec. equiv.).
- **Facturas recurrentes**: página `/app/recurring` con listado y formulario "Crear serie" (frecuencia, próxima ejecución, cliente).
- **Subida de logo**: en Configuración, subida a bucket Storage `logos` (path `user_id/logo.ext`) y opción URL externa.
- **Política de privacidad**: página `/privacy` con texto GDPR y enlace en pie de la home.
- **Rate limiting**: en `hooks.server.js` para rutas `/login` y `/api/*` (30 req/min por IP).

---

## 1. Hardening multi-tenant + auditoría RLS

- Definir claramente **user_id vs org_id**: stub `orgs` y `org_members` en migración; invoices sigue con `user_id`.
- Políticas RLS **por operación** (SELECT/INSERT/UPDATE/DELETE) aplicadas; **trigger** `invoices_guard_emitida` impide cambiar `status` a draft y modificar `number` en facturas emitidas.
- **Índices**: `supabase/indexes.sql` (user_id, created_at desc); ejecutar si no está aplicado.
- Tests de acceso: comprobar que un usuario A no puede leer/escribir facturas de B.

---

## 2. PDF "modo fiable" (server-side) + Storage privado

- **Hecho (estructura)**: ruta `/invoice/[id]/print` (vista impresión); `+page.server.js` con token para carga server-side; API `POST /api/invoice/[id]/pdf` y signed URLs de Storage.
- **Pendiente**: conectar generación real con Headless Chrome / Browserless / Playwright (job que abra la print URL con token, genere PDF, suba a bucket `invoices-pdf` y devuelva signed URL).
- Mantener PDF en cliente (html2pdf.js) para **demo** y **plan gratuito** (con marca de agua).

---

## 3. Rendimiento del dashboard

- **Hecho**: paginación por cursor (20 por página), "Cargar más", índices, métricas vía RPC `get_user_invoice_stats`.
- Opcional: SSR del listado (requiere @supabase/ssr y sesión por cookies).
- Opcional: virtualización si se quiere "infinite scroll" con muchas filas.

---

## 4. Autosave + estados claros en el editor

- **Hecho**: autosave de borrador con feedback (Guardando… / Guardado / Error), botones "Guardar borrador" y "Emitir factura", "Factura bloqueada" en emitidas, navegación por Tab entre campos.
- **Emitir** = marcar como `sent`, redirigir al dashboard; el trigger RLS impide bajar a draft y cambiar número.

---

## 5. Paquete Pro con features de retención

- **Facturas recurrentes**: UI en `/app/recurring` (listado + crear serie); pendiente lógica de generación automática de borradores y recordatorios.
- **Envío desde la app**: columna "Enviado a" y botón "Enviar" (guarda `email_sent_to`); pendiente envío real por email y tracking (enviada/vista/pagada).
- **Cobro integrado**: pendiente (Stripe link por factura, marcar pagada, export para gestoría).

---

## Otros puntos del informe

- **Logo / imágenes**: subida de logo a Storage en Configuración; aviso en UI sobre URLs externas y CORS.
- **Auth**: rate limiting en hooks para `/login` y `/api/*`; allowlist de redirects y MFA en roadmap.
- **Privacidad**: política en `/privacy`; no loguear payloads de factura en server.
- **Impuestos**: presets en editor (IVA 21/10/4, exento, IRPF 15%, rec. equiv. 5,2%); para España/micropymes valorar más casos (inversión sujeto pasivo, etc.).

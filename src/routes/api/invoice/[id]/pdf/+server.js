import { createClient } from '@supabase/supabase-js';
import { json } from '@sveltejs/kit';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { env } from '$env/dynamic/private';

/**
 * POST /api/invoice/[id]/pdf
 * Requiere Authorization: Bearer <access_token> (sesión Supabase).
 * Para Pro: generar PDF server-side (Headless Chrome/Browserless), subir a Storage y devolver signed URL.
 * Por ahora devuelve printUrl para abrir en navegador e imprimir a PDF, y opcionalmente signedUrl si ya existe en Storage.
 */
export async function POST({ params, request }) {
  const id = params.id;
  const authHeader = request.headers.get('Authorization');
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return json({ error: 'No autorizado. Incluye Authorization: Bearer <token>.' }, { status: 401 });
  }

  const supabaseUrl = PUBLIC_SUPABASE_URL;
  const supabaseAnon = PUBLIC_SUPABASE_ANON_KEY;
  const supabaseServiceKey = env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseAnon) {
    return json({ error: 'Configuración incompleta' }, { status: 500 });
  }

  const supabase = createClient(supabaseUrl, supabaseAnon);
  const { data: { user }, error: userError } = await supabase.auth.getUser(token);

  if (userError || !user) {
    return json({ error: 'Token inválido o expirado' }, { status: 401 });
  }

  const { data: invoice, error: invError } = await supabase
    .from('invoices')
    .select('id, user_id')
    .eq('id', id)
    .eq('user_id', user.id)
    .maybeSingle();

  if (invError || !invoice) {
    return json({ error: 'Factura no encontrada' }, { status: 404 });
  }

  const baseUrl = env.PUBLIC_SITE_URL ?? (typeof request?.url === 'string' ? new URL(request.url).origin : '');
  const printUrl = `${baseUrl}/invoice/${id}/print`;

  let signedUrl = null;
  if (supabaseServiceKey) {
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    const path = `${user.id}/${id}.pdf`;
    const { data: signed } = await supabaseAdmin.storage
      .from('invoices-pdf')
      .createSignedUrl(path, 3600);

    if (signed?.signedUrl) {
      signedUrl = signed.signedUrl;
    }
  }

  return json({
    printUrl,
    signedUrl,
    message: signedUrl
      ? 'PDF disponible (Pro). Descarga con signedUrl.'
      : 'Abre printUrl en el navegador y usa Imprimir > Guardar como PDF. Para PDF server-side (Pro), configure Headless Chrome o Browserless.'
  });
}

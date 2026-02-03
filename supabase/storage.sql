-- Storage: buckets privados para PDFs (Pro) y logos
-- Ejecutar en Supabase Dashboard > SQL (o Storage > New bucket y luego Policies)

-- Crear bucket para PDFs de facturas (privado)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'invoices-pdf',
  'invoices-pdf',
  false,
  5242880,
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Políticas: solo el dueño puede leer/escribir su carpeta user_id/
-- Path: user_id/invoice_id.pdf
CREATE POLICY "invoices_pdf_select_own"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'invoices-pdf' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "invoices_pdf_insert_own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'invoices-pdf' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "invoices_pdf_update_own"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'invoices-pdf' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "invoices_pdf_delete_own"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'invoices-pdf' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Bucket para logos de perfil (público o privado con signed URL)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'logos',
  'logos',
  true,
  1048576,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "logos_select_own"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'logos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "logos_insert_own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'logos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "logos_update_own"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'logos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "logos_delete_own"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'logos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Lectura pública para logos (para mostrar en facturas)
CREATE POLICY "logos_select_public"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'logos');

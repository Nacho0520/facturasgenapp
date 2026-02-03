-- Índices para RLS y rendimiento (dashboard con muchas facturas)
-- Ejecutar en Supabase SQL Editor después de rls.sql

CREATE INDEX IF NOT EXISTS idx_invoices_user_created
  ON invoices (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_invoices_user_id
  ON invoices (user_id);

-- Para búsquedas por estado (opcional)
CREATE INDEX IF NOT EXISTS idx_invoices_user_status
  ON invoices (user_id, status);

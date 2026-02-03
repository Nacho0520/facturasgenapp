-- Hardening RLS: no permitir bajar status de emitida a borrador ni cambiar número una vez emitida
-- Ejecutar después de 001_report_improvements.sql

CREATE OR REPLACE FUNCTION invoices_guard_emitida()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'sent' THEN
    -- No permitir cambiar status de 'sent' a 'draft'
    IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status = 'draft' THEN
      RAISE EXCEPTION 'No se puede cambiar una factura emitida a borrador';
    END IF;
    -- No permitir cambiar el número de factura una vez emitida
    IF NEW.number IS DISTINCT FROM OLD.number THEN
      RAISE EXCEPTION 'No se puede modificar el número de una factura emitida';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS invoices_guard_emitida_trigger ON invoices;
CREATE TRIGGER invoices_guard_emitida_trigger
  BEFORE UPDATE ON invoices
  FOR EACH ROW
  EXECUTE PROCEDURE invoices_guard_emitida();

COMMENT ON FUNCTION invoices_guard_emitida() IS 'Bloquea bajar status a draft y cambiar number en facturas emitidas';

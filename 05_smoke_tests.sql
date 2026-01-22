USE MrLeeDB;
GO

-- Set contexto para auditoría (simula lo que hará tu API C#)
EXEC sp_set_session_context @key=N'audit_user', @value=N'admin_prueba';
EXEC sp_set_session_context @key=N'audit_ip',   @value=N'127.0.0.1';

-- Limpieza por si existía
DELETE FROM dbo.productos WHERE codigo = 'P-999';

-- 1) INSERT producto
INSERT INTO dbo.productos(codigo, nombre, categoria, precio, stock, activo)
VALUES ('P-999','Producto Smoke','Pruebas', 123.45, 5, 1);

DECLARE @id_producto BIGINT;
SELECT @id_producto = id_producto
FROM dbo.productos
WHERE codigo='P-999';

-- 2) UPDATE producto
UPDATE dbo.productos
SET nombre='Producto Smoke Editado', precio=200.00, stock=7
WHERE id_producto=@id_producto;

-- 3) DELETE producto
DELETE dbo.productos
WHERE id_producto=@id_producto;

-- 4) Ver bitácora reciente para productos
SELECT TOP 20 *
FROM dbo.bitacora_auditoria
WHERE tabla_afectada = 'productos'
ORDER BY id_bitacora DESC;

-- 5) Conteos básicos
SELECT
  (SELECT COUNT(*) FROM dbo.usuarios) AS usuarios,
  (SELECT COUNT(*) FROM dbo.clientes) AS clientes,
  (SELECT COUNT(*) FROM dbo.productos) AS productos,
  (SELECT COUNT(*) FROM dbo.pedidos) AS pedidos,
  (SELECT COUNT(*) FROM dbo.detalle_pedidos) AS detalle_pedidos,
  (SELECT COUNT(*) FROM dbo.ingresos) AS ingresos,
  (SELECT COUNT(*) FROM dbo.empleados) AS empleados,
  (SELECT COUNT(*) FROM dbo.ausencias) AS ausencias,
  (SELECT COUNT(*) FROM dbo.documentos_empleado) AS documentos_empleado,
  (SELECT COUNT(*) FROM dbo.bitacora_auditoria) AS bitacora_total;
GO

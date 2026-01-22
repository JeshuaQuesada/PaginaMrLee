/*
04_seed_data.sql
Datos mínimos para pruebas.
*/

USE MrLeeDB;
GO

-- Set auditoría para que el seed quede registrado con usuario/ip
EXEC sp_set_session_context @key=N'audit_user', @value=N'admin_seed';
EXEC sp_set_session_context @key=N'audit_ip',   @value=N'127.0.0.1';
GO

-- Roles
IF NOT EXISTS (SELECT 1 FROM dbo.roles)
BEGIN
  INSERT INTO dbo.roles(nombre) VALUES
  ('Administrador'),
  ('Bodega'),
  ('Contabilidad'),
  ('RRHH'),
  ('Gerencia'),
  ('Cliente');
END
GO

-- Usuarios (password_hash placeholder)
IF NOT EXISTS (SELECT 1 FROM dbo.usuarios)
BEGIN
  INSERT INTO dbo.usuarios(nombre_usuario, nombre_completo, correo, password_hash, activo)
  VALUES
  ('admin', 'Admin Sistema', 'admin@mrlee.local', 'HASH_PLACEHOLDER', 1),
  ('bodega', 'Usuario Bodega', 'bodega@mrlee.local', 'HASH_PLACEHOLDER', 1),
  ('conta', 'Usuario Contabilidad', 'conta@mrlee.local', 'HASH_PLACEHOLDER', 1),
  ('rrhh', 'Usuario RRHH', 'rrhh@mrlee.local', 'HASH_PLACEHOLDER', 1),
  ('gerencia', 'Usuario Gerencia', 'gerencia@mrlee.local', 'HASH_PLACEHOLDER', 1),
  ('cliente1', 'Cliente Uno', 'cliente1@mrlee.local', 'HASH_PLACEHOLDER', 1);
END
GO

-- Asignación roles a usuarios
;WITH R AS (SELECT id_rol, nombre FROM dbo.roles),
     U AS (SELECT id_usuario, nombre_usuario FROM dbo.usuarios)
INSERT INTO dbo.usuario_roles(id_usuario, id_rol)
SELECT U.id_usuario, R.id_rol
FROM U
JOIN R ON
 (U.nombre_usuario='admin'    AND R.nombre='Administrador') OR
 (U.nombre_usuario='bodega'   AND R.nombre='Bodega') OR
 (U.nombre_usuario='conta'    AND R.nombre='Contabilidad') OR
 (U.nombre_usuario='rrhh'     AND R.nombre='RRHH') OR
 (U.nombre_usuario='gerencia' AND R.nombre='Gerencia') OR
 (U.nombre_usuario='cliente1' AND R.nombre='Cliente')
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.usuario_roles ur
  WHERE ur.id_usuario = U.id_usuario AND ur.id_rol = R.id_rol
);
GO

-- Clientes
IF NOT EXISTS (SELECT 1 FROM dbo.clientes)
BEGIN
  INSERT INTO dbo.clientes(nombre, correo, telefono, direccion)
  VALUES
  ('Carlos Mora', 'carlos@email.com', '8888-1111', 'Heredia centro'),
  ('María Pérez', 'maria@email.com', '8888-2222', 'San José'),
  ('Juan Soto',   NULL,              '8888-3333', 'Alajuela');
END
GO

-- Productos
IF NOT EXISTS (SELECT 1 FROM dbo.productos)
BEGIN
  INSERT INTO dbo.productos(codigo, nombre, categoria, precio, stock, activo)
  VALUES
  ('P-001','Pan Francés','Pan', 350, 100, 1),
  ('P-002','Pan Integral','Pan', 450, 80, 1),
  ('P-003','Baguette','Pan', 600, 40, 1),
  ('P-004','Croissant','Repostería', 700, 50, 1),
  ('P-005','Queque seco','Repostería', 1200, 25, 1),
  ('P-006','Empanada','Salado', 800, 60, 1),
  ('P-007','Galletas','Repostería', 500, 90, 1),
  ('P-008','Pan dulce','Pan', 400, 70, 1),
  ('P-009','Dona','Repostería', 650, 55, 1),
  ('P-010','Torta pequeña','Repostería', 2500, 10, 1);
END
GO

-- Métodos de pago
IF NOT EXISTS (SELECT 1 FROM dbo.metodos_pago)
BEGIN
  INSERT INTO dbo.metodos_pago(nombre) VALUES ('Efectivo'), ('Tarjeta'), ('SINPE');
END
GO

-- Pedido + detalle (1 pedido con 2 líneas)
IF NOT EXISTS (SELECT 1 FROM dbo.pedidos)
BEGIN
  DECLARE @id_cliente BIGINT = (SELECT TOP 1 id_cliente FROM dbo.clientes ORDER BY id_cliente);
  INSERT INTO dbo.pedidos(numero_pedido, id_cliente, estado)
  VALUES ('PED-2025-00001', @id_cliente, 'CREADO');

  DECLARE @id_pedido BIGINT = SCOPE_IDENTITY();
  DECLARE @p1 BIGINT = (SELECT id_producto FROM dbo.productos WHERE codigo='P-001');
  DECLARE @p2 BIGINT = (SELECT id_producto FROM dbo.productos WHERE codigo='P-004');

  INSERT INTO dbo.detalle_pedidos(id_pedido, id_producto, cantidad, precio_unitario)
  VALUES
  (@id_pedido, @p1, 10, (SELECT precio FROM dbo.productos WHERE id_producto=@p1)),
  (@id_pedido, @p2,  3, (SELECT precio FROM dbo.productos WHERE id_producto=@p2));

  UPDATE dbo.pedidos
  SET total = (SELECT SUM(subtotal) FROM dbo.detalle_pedidos WHERE id_pedido=@id_pedido)
  WHERE id_pedido=@id_pedido;
END
GO

-- Movimientos inventario (2)
IF NOT EXISTS (SELECT 1 FROM dbo.movimientos_inventario)
BEGIN
  DECLARE @p BIGINT = (SELECT id_producto FROM dbo.productos WHERE codigo='P-001');
  INSERT INTO dbo.movimientos_inventario(id_producto, tipo, cantidad, motivo)
  VALUES
  (@p, 'SALIDA', 10, 'Salida por pedido PED-2025-00001'),
  (@p, 'ENTRADA', 20, 'Ingreso de producción');
END
GO

-- Ingresos (2)
IF NOT EXISTS (SELECT 1 FROM dbo.ingresos)
BEGIN
  DECLARE @c BIGINT = (SELECT TOP 1 id_cliente FROM dbo.clientes ORDER BY id_cliente);
  DECLARE @mp BIGINT = (SELECT TOP 1 id_metodo_pago FROM dbo.metodos_pago WHERE nombre='Efectivo');
  INSERT INTO dbo.ingresos(id_cliente, id_metodo_pago, monto, descripcion)
  VALUES
  (@c, @mp, 15000, 'Venta diaria'),
  (@c, @mp,  8000, 'Venta mostrador');
END
GO

-- Empleados + ausencias + documentos
IF NOT EXISTS (SELECT 1 FROM dbo.empleados)
BEGIN
  INSERT INTO dbo.empleados(identificacion, nombre, apellidos, puesto, sucursal, telefono, salario)
  VALUES
  ('1-1111-1111','Ana','Rojas','Panadera','Central','8888-4444', 450000),
  ('2-2222-2222','Luis','Mora','Cajero','Central','8888-5555', 400000);

  DECLARE @e BIGINT = (SELECT TOP 1 id_empleado FROM dbo.empleados ORDER BY id_empleado);

  INSERT INTO dbo.ausencias(id_empleado, tipo, fecha_inicio, fecha_fin, motivo)
  VALUES (@e, 'VACACIONES', DATEADD(DAY,-3,CAST(GETDATE() AS DATE)), DATEADD(DAY,2,CAST(GETDATE() AS DATE)), 'Vacaciones programadas');

  INSERT INTO dbo.documentos_empleado(id_empleado, tipo, url_documento)
  VALUES (@e, 'Contrato', 'C:\docs\contrato_ana.pdf');
END
GO

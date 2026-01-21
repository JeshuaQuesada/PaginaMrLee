/*
03_triggers_bitacora.sql
Triggers AFTER INSERT/UPDATE/DELETE para las tablas auditadas (DN01).
Lee usuario/ip desde SESSION_CONTEXT: audit_user, audit_ip.
*/

USE MrLeeDB;
GO

-- Helper: valores por defecto de auditoría
-- (se usan dentro de cada trigger)
-- usuario_responsable = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system')
-- ip_origen          = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0')

   USUARIOS (Usuarios y Accesos)

IF OBJECT_ID('dbo.tr_audit_usuarios','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_usuarios;
GO
CREATE TRIGGER dbo.tr_audit_usuarios
ON dbo.usuarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'usuarios',
    COALESCE(i.id_usuario, d.id_usuario),
    CASE
      WHEN i.id_usuario IS NOT NULL AND d.id_usuario IS NULL THEN 'CREATE'
      WHEN i.id_usuario IS NOT NULL AND d.id_usuario IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Usuarios y Accesos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_usuario IS NULL THEN NULL ELSE
      (SELECT
         d.id_usuario       AS id_usuario,
         d.nombre_usuario   AS nombre_usuario,
         d.nombre_completo  AS nombre_completo,
         d.correo           AS correo,
         '[REDACTED]'       AS password_hash,
         d.activo           AS activo,
         d.intentos_fallidos AS intentos_fallidos,
         d.lockout_hasta    AS lockout_hasta,
         d.creado_en        AS creado_en
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    END,
    CASE WHEN i.id_usuario IS NULL THEN NULL ELSE
      (SELECT
         i.id_usuario       AS id_usuario,
         i.nombre_usuario   AS nombre_usuario,
         i.nombre_completo  AS nombre_completo,
         i.correo           AS correo,
         '[REDACTED]'       AS password_hash,
         i.activo           AS activo,
         i.intentos_fallidos AS intentos_fallidos,
         i.lockout_hasta    AS lockout_hasta,
         i.creado_en        AS creado_en
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_usuario = d.id_usuario;
END
GO


-- CLIENTES (Sitio para Clientes)

IF OBJECT_ID('dbo.tr_audit_clientes','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_clientes;
GO
CREATE TRIGGER dbo.tr_audit_clientes
ON dbo.clientes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'clientes',
    COALESCE(i.id_cliente, d.id_cliente),
    CASE
      WHEN i.id_cliente IS NOT NULL AND d.id_cliente IS NULL THEN 'CREATE'
      WHEN i.id_cliente IS NOT NULL AND d.id_cliente IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Sitio para Clientes',
    @usr,
    GETDATE(),
    CASE WHEN d.id_cliente IS NULL THEN NULL ELSE
      (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    END,
    CASE WHEN i.id_cliente IS NULL THEN NULL ELSE
      (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_cliente = d.id_cliente;
END
GO


-- PRODUCTOS (Inventario)

IF OBJECT_ID('dbo.tr_audit_productos','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_productos;
GO
CREATE TRIGGER dbo.tr_audit_productos
ON dbo.productos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'productos',
    COALESCE(i.id_producto, d.id_producto),
    CASE
      WHEN i.id_producto IS NOT NULL AND d.id_producto IS NULL THEN 'CREATE'
      WHEN i.id_producto IS NOT NULL AND d.id_producto IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Inventario',
    @usr,
    GETDATE(),
    CASE WHEN d.id_producto IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_producto IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_producto = d.id_producto;
END
GO


-- MOVIMIENTOS INVENTARIO (Inventario)

IF OBJECT_ID('dbo.tr_audit_movimientos_inventario','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_movimientos_inventario;
GO
CREATE TRIGGER dbo.tr_audit_movimientos_inventario
ON dbo.movimientos_inventario
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'movimientos_inventario',
    COALESCE(i.id_movimiento, d.id_movimiento),
    CASE
      WHEN i.id_movimiento IS NOT NULL AND d.id_movimiento IS NULL THEN 'CREATE'
      WHEN i.id_movimiento IS NOT NULL AND d.id_movimiento IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Inventario',
    @usr,
    GETDATE(),
    CASE WHEN d.id_movimiento IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_movimiento IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_movimiento = d.id_movimiento;
END
GO


-- PEDIDOS (Seguimiento de Pedidos)

IF OBJECT_ID('dbo.tr_audit_pedidos','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_pedidos;
GO
CREATE TRIGGER dbo.tr_audit_pedidos
ON dbo.pedidos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'pedidos',
    COALESCE(i.id_pedido, d.id_pedido),
    CASE
      WHEN i.id_pedido IS NOT NULL AND d.id_pedido IS NULL THEN 'CREATE'
      WHEN i.id_pedido IS NOT NULL AND d.id_pedido IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Seguimiento de Pedidos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_pedido IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_pedido IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_pedido = d.id_pedido;
END
GO


-- DETALLE PEDIDOS (Seguimiento de Pedidos)

IF OBJECT_ID('dbo.tr_audit_detalle_pedidos','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_detalle_pedidos;
GO
CREATE TRIGGER dbo.tr_audit_detalle_pedidos
ON dbo.detalle_pedidos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'detalle_pedidos',
    COALESCE(i.id_detalle, d.id_detalle),
    CASE
      WHEN i.id_detalle IS NOT NULL AND d.id_detalle IS NULL THEN 'CREATE'
      WHEN i.id_detalle IS NOT NULL AND d.id_detalle IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Seguimiento de Pedidos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_detalle IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_detalle IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_detalle = d.id_detalle;
END
GO


-- INGRESOS (Ingresos Operativos)

IF OBJECT_ID('dbo.tr_audit_ingresos','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_ingresos;
GO
CREATE TRIGGER dbo.tr_audit_ingresos
ON dbo.ingresos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'ingresos',
    COALESCE(i.id_ingreso, d.id_ingreso),
    CASE
      WHEN i.id_ingreso IS NOT NULL AND d.id_ingreso IS NULL THEN 'CREATE'
      WHEN i.id_ingreso IS NOT NULL AND d.id_ingreso IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Ingresos Operativos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_ingreso IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_ingreso IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_ingreso = d.id_ingreso;
END
GO


-- EMPLEADOS (Recursos Humanos)

IF OBJECT_ID('dbo.tr_audit_empleados','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_empleados;
GO
CREATE TRIGGER dbo.tr_audit_empleados
ON dbo.empleados
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'empleados',
    COALESCE(i.id_empleado, d.id_empleado),
    CASE
      WHEN i.id_empleado IS NOT NULL AND d.id_empleado IS NULL THEN 'CREATE'
      WHEN i.id_empleado IS NOT NULL AND d.id_empleado IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Recursos Humanos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_empleado IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_empleado IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_empleado = d.id_empleado;
END
GO


-- AUSENCIAS (Recursos Humanos)

IF OBJECT_ID('dbo.tr_audit_ausencias','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_ausencias;
GO
CREATE TRIGGER dbo.tr_audit_ausencias
ON dbo.ausencias
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'ausencias',
    COALESCE(i.id_ausencia, d.id_ausencia),
    CASE
      WHEN i.id_ausencia IS NOT NULL AND d.id_ausencia IS NULL THEN 'CREATE'
      WHEN i.id_ausencia IS NOT NULL AND d.id_ausencia IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Recursos Humanos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_ausencia IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_ausencia IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_ausencia = d.id_ausencia;
END
GO


-- DOCUMENTOS EMPLEADO (Recursos Humanos)

IF OBJECT_ID('dbo.tr_audit_documentos_empleado','TR') IS NOT NULL DROP TRIGGER dbo.tr_audit_documentos_empleado;
GO
CREATE TRIGGER dbo.tr_audit_documentos_empleado
ON dbo.documentos_empleado
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @usr VARCHAR(100) = COALESCE(CONVERT(VARCHAR(100), SESSION_CONTEXT(N'audit_user')), 'system');
  DECLARE @ip  VARCHAR(50)  = COALESCE(CONVERT(VARCHAR(50),  SESSION_CONTEXT(N'audit_ip')),  '0.0.0.0');

  INSERT INTO dbo.bitacora_auditoria
  (tabla_afectada, id_registro, accion, modulo, usuario_responsable, fecha_hora, datos_anteriores, datos_nuevos, ip_origen, descripcion)
  SELECT
    'documentos_empleado',
    COALESCE(i.id_documento, d.id_documento),
    CASE
      WHEN i.id_documento IS NOT NULL AND d.id_documento IS NULL THEN 'CREATE'
      WHEN i.id_documento IS NOT NULL AND d.id_documento IS NOT NULL THEN 'UPDATE'
      ELSE 'DELETE'
    END,
    'Recursos Humanos',
    @usr,
    GETDATE(),
    CASE WHEN d.id_documento IS NULL THEN NULL ELSE (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    CASE WHEN i.id_documento IS NULL THEN NULL ELSE (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
    @ip,
    'Auditoría automática por trigger'
  FROM inserted i
  FULL OUTER JOIN deleted d ON i.id_documento = d.id_documento;
END
GO

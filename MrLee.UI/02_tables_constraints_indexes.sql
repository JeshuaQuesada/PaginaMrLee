/*
02_tables_constraints_indexes.sql
Esquema mínimo normalizado + constraints + índices.
*/

USE MrLeeDB;
GO

-- Seguridad / Usuarios
IF OBJECT_ID('dbo.usuario_roles','U') IS NOT NULL DROP TABLE dbo.usuario_roles;
IF OBJECT_ID('dbo.usuarios','U') IS NOT NULL DROP TABLE dbo.usuarios;
IF OBJECT_ID('dbo.roles','U') IS NOT NULL DROP TABLE dbo.roles;
GO

CREATE TABLE dbo.roles (
  id_rol        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_roles PRIMARY KEY,
  nombre        VARCHAR(50) NOT NULL CONSTRAINT UQ_roles_nombre UNIQUE
);
GO

CREATE TABLE dbo.usuarios (
  id_usuario        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_usuarios PRIMARY KEY,
  nombre_usuario    VARCHAR(60) NOT NULL CONSTRAINT UQ_usuarios_nombre_usuario UNIQUE,
  nombre_completo   VARCHAR(120) NOT NULL,
  correo            VARCHAR(120) NOT NULL CONSTRAINT UQ_usuarios_correo UNIQUE,
  password_hash     VARCHAR(255) NOT NULL, -- hash, nunca texto plano
  activo            BIT NOT NULL CONSTRAINT DF_usuarios_activo DEFAULT(1),
  intentos_fallidos INT NOT NULL CONSTRAINT DF_usuarios_intentos DEFAULT(0),
  lockout_hasta     DATETIME NULL,
  creado_en         DATETIME NOT NULL CONSTRAINT DF_usuarios_creado_en DEFAULT(GETDATE())
);
GO

CREATE TABLE dbo.usuario_roles (
  id_usuario BIGINT NOT NULL,
  id_rol     BIGINT NOT NULL,
  CONSTRAINT PK_usuario_roles PRIMARY KEY (id_usuario, id_rol),
  CONSTRAINT FK_usuario_roles_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuarios(id_usuario),
  CONSTRAINT FK_usuario_roles_rol     FOREIGN KEY (id_rol)     REFERENCES dbo.roles(id_rol)
);
GO

CREATE INDEX IX_usuarios_correo ON dbo.usuarios(correo);
CREATE INDEX IX_usuarios_activo ON dbo.usuarios(activo);
GO

-- Clientes

IF OBJECT_ID('dbo.clientes','U') IS NOT NULL DROP TABLE dbo.clientes;
GO

CREATE TABLE dbo.clientes (
  id_cliente      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_clientes PRIMARY KEY,
  nombre          VARCHAR(120) NOT NULL,
  correo          VARCHAR(120) NULL,
  telefono        VARCHAR(30)  NULL,
  direccion       VARCHAR(250) NULL,
  activo          BIT NOT NULL CONSTRAINT DF_clientes_activo DEFAULT(1),
  creado_en       DATETIME NOT NULL CONSTRAINT DF_clientes_creado_en DEFAULT(GETDATE())
);
GO

CREATE INDEX IX_clientes_nombre ON dbo.clientes(nombre);
GO

-- Inventario

IF OBJECT_ID('dbo.movimientos_inventario','U') IS NOT NULL DROP TABLE dbo.movimientos_inventario;
IF OBJECT_ID('dbo.productos','U') IS NOT NULL DROP TABLE dbo.productos;
GO

CREATE TABLE dbo.productos (
  id_producto BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_productos PRIMARY KEY,
  codigo      VARCHAR(40) NOT NULL CONSTRAINT UQ_productos_codigo UNIQUE,
  nombre      VARCHAR(140) NOT NULL,
  categoria   VARCHAR(80) NULL,
  precio      DECIMAL(12,2) NOT NULL CONSTRAINT CK_productos_precio CHECK (precio >= 0),
  stock       INT NOT NULL CONSTRAINT CK_productos_stock CHECK (stock >= 0),
  activo      BIT NOT NULL CONSTRAINT DF_productos_activo DEFAULT(1),
  creado_en   DATETIME NOT NULL CONSTRAINT DF_productos_creado_en DEFAULT(GETDATE())
);
GO

CREATE TABLE dbo.movimientos_inventario (
  id_movimiento BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_movimientos_inventario PRIMARY KEY,
  id_producto   BIGINT NOT NULL,
  tipo          VARCHAR(10) NOT NULL CONSTRAINT CK_movinv_tipo CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE')),
  cantidad      INT NOT NULL CONSTRAINT CK_movinv_cantidad CHECK (cantidad > 0),
  motivo        VARCHAR(200) NULL,
  fecha         DATETIME NOT NULL CONSTRAINT DF_movinv_fecha DEFAULT(GETDATE()),
  CONSTRAINT FK_movinv_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos(id_producto)
);
GO

CREATE INDEX IX_productos_nombre ON dbo.productos(nombre);
CREATE INDEX IX_movinv_producto_fecha ON dbo.movimientos_inventario(id_producto, fecha DESC);
GO

-- Pedidos

IF OBJECT_ID('dbo.detalle_pedidos','U') IS NOT NULL DROP TABLE dbo.detalle_pedidos;
IF OBJECT_ID('dbo.pedidos','U') IS NOT NULL DROP TABLE dbo.pedidos;
GO

CREATE TABLE dbo.pedidos (
  id_pedido     BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_pedidos PRIMARY KEY,
  numero_pedido VARCHAR(30) NOT NULL CONSTRAINT UQ_pedidos_numero UNIQUE,
  id_cliente    BIGINT NOT NULL,
  estado        VARCHAR(20) NOT NULL CONSTRAINT CK_pedidos_estado CHECK (estado IN ('CREADO','EN_PROCESO','LISTO','ENTREGADO','CANCELADO')),
  fecha_pedido  DATETIME NOT NULL CONSTRAINT DF_pedidos_fecha DEFAULT(GETDATE()),
  total         DECIMAL(12,2) NOT NULL CONSTRAINT DF_pedidos_total DEFAULT(0) CONSTRAINT CK_pedidos_total CHECK (total >= 0),
  CONSTRAINT FK_pedidos_cliente FOREIGN KEY (id_cliente) REFERENCES dbo.clientes(id_cliente)
);
GO

CREATE TABLE dbo.detalle_pedidos (
  id_detalle      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_detalle_pedidos PRIMARY KEY,
  id_pedido       BIGINT NOT NULL,
  id_producto     BIGINT NOT NULL,
  cantidad        INT NOT NULL CONSTRAINT CK_detped_cantidad CHECK (cantidad > 0),
  precio_unitario DECIMAL(12,2) NOT NULL CONSTRAINT CK_detped_precio CHECK (precio_unitario >= 0),
  subtotal        AS (CAST(cantidad AS DECIMAL(12,2)) * precio_unitario) PERSISTED,
  CONSTRAINT FK_detped_pedido   FOREIGN KEY (id_pedido)   REFERENCES dbo.pedidos(id_pedido),
  CONSTRAINT FK_detped_producto FOREIGN KEY (id_producto) REFERENCES dbo.productos(id_producto)
);
GO

CREATE INDEX IX_pedidos_fecha_estado ON dbo.pedidos(fecha_pedido DESC, estado);
CREATE INDEX IX_pedidos_cliente ON dbo.pedidos(id_cliente);
CREATE INDEX IX_detped_pedido ON dbo.detalle_pedidos(id_pedido);
GO

-- Ingresos operativos

IF OBJECT_ID('dbo.ingresos','U') IS NOT NULL DROP TABLE dbo.ingresos;
IF OBJECT_ID('dbo.metodos_pago','U') IS NOT NULL DROP TABLE dbo.metodos_pago;
GO

CREATE TABLE dbo.metodos_pago (
  id_metodo_pago BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_metodos_pago PRIMARY KEY,
  nombre         VARCHAR(60) NOT NULL CONSTRAINT UQ_metodos_pago_nombre UNIQUE
);
GO

CREATE TABLE dbo.ingresos (
  id_ingreso      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ingresos PRIMARY KEY,
  id_cliente      BIGINT NULL,
  id_metodo_pago  BIGINT NULL,
  monto           DECIMAL(12,2) NOT NULL CONSTRAINT CK_ingresos_monto CHECK (monto > 0),
  fecha_ingreso   DATETIME NOT NULL CONSTRAINT DF_ingresos_fecha DEFAULT(GETDATE()),
  descripcion     VARCHAR(300) NULL,
  anulado         BIT NOT NULL CONSTRAINT DF_ingresos_anulado DEFAULT(0),
  CONSTRAINT FK_ingresos_cliente     FOREIGN KEY (id_cliente)     REFERENCES dbo.clientes(id_cliente),
  CONSTRAINT FK_ingresos_metodo_pago FOREIGN KEY (id_metodo_pago) REFERENCES dbo.metodos_pago(id_metodo_pago)
);
GO

CREATE INDEX IX_ingresos_fecha ON dbo.ingresos(fecha_ingreso DESC);
CREATE INDEX IX_ingresos_cliente ON dbo.ingresos(id_cliente);
GO

-- Recursos Humanos

IF OBJECT_ID('dbo.documentos_empleado','U') IS NOT NULL DROP TABLE dbo.documentos_empleado;
IF OBJECT_ID('dbo.ausencias','U') IS NOT NULL DROP TABLE dbo.ausencias;
IF OBJECT_ID('dbo.empleados','U') IS NOT NULL DROP TABLE dbo.empleados;
GO

CREATE TABLE dbo.empleados (
  id_empleado     BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_empleados PRIMARY KEY,
  identificacion  VARCHAR(30) NOT NULL CONSTRAINT UQ_empleados_ident UNIQUE,
  nombre          VARCHAR(80) NOT NULL,
  apellidos       VARCHAR(120) NOT NULL,
  puesto          VARCHAR(80) NOT NULL,
  fecha_ingreso   DATE NOT NULL CONSTRAINT DF_empleados_fecha_ingreso DEFAULT(CAST(GETDATE() AS DATE)),
  sucursal        VARCHAR(80) NULL,
  telefono        VARCHAR(30) NULL,
  salario         DECIMAL(12,2) NOT NULL CONSTRAINT CK_empleados_salario CHECK (salario >= 0),
  activo          BIT NOT NULL CONSTRAINT DF_empleados_activo DEFAULT(1),
  creado_en       DATETIME NOT NULL CONSTRAINT DF_empleados_creado_en DEFAULT(GETDATE())
);
GO

CREATE TABLE dbo.ausencias (
  id_ausencia   BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ausencias PRIMARY KEY,
  id_empleado   BIGINT NOT NULL,
  tipo          VARCHAR(15) NOT NULL CONSTRAINT CK_ausencias_tipo CHECK (tipo IN ('VACACIONES','INCAPACIDAD','PERMISO')),
  fecha_inicio  DATE NOT NULL,
  fecha_fin     DATE NOT NULL,
  motivo        VARCHAR(250) NULL,
  CONSTRAINT CK_ausencias_rango CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT FK_ausencias_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleados(id_empleado)
);
GO

CREATE TABLE dbo.documentos_empleado (
  id_documento   BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_documentos_empleado PRIMARY KEY,
  id_empleado    BIGINT NOT NULL,
  tipo           VARCHAR(60) NOT NULL,
  url_documento  VARCHAR(500) NOT NULL,
  fecha          DATE NOT NULL CONSTRAINT DF_documentos_fecha DEFAULT(CAST(GETDATE() AS DATE)),
  CONSTRAINT FK_documentos_empleado FOREIGN KEY (id_empleado) REFERENCES dbo.empleados(id_empleado)
);
GO

CREATE INDEX IX_ausencias_empleado_inicio ON dbo.ausencias(id_empleado, fecha_inicio DESC);
CREATE INDEX IX_documentos_empleado_empleado ON dbo.documentos_empleado(id_empleado);
GO

-- Bitácora (tabla base; triggers en script 03)

IF OBJECT_ID('dbo.bitacora_auditoria','U') IS NOT NULL DROP TABLE dbo.bitacora_auditoria;
GO

CREATE TABLE dbo.bitacora_auditoria (
  id_bitacora         BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_bitacora PRIMARY KEY,
  tabla_afectada      VARCHAR(100) NOT NULL,
  id_registro         BIGINT NULL,
  accion              VARCHAR(20) NOT NULL CONSTRAINT CK_bitacora_accion CHECK (accion IN ('CREATE','UPDATE','DELETE')),
  modulo              VARCHAR(100) NOT NULL,
  usuario_responsable VARCHAR(100) NOT NULL,
  fecha_hora          DATETIME NOT NULL CONSTRAINT DF_bitacora_fecha DEFAULT(GETDATE()),
  datos_anteriores    NVARCHAR(MAX) NULL, -- JSON
  datos_nuevos        NVARCHAR(MAX) NULL, -- JSON
  ip_origen           VARCHAR(50) NOT NULL,
  descripcion         VARCHAR(500) NULL
);
GO

CREATE INDEX IX_bitacora_fecha ON dbo.bitacora_auditoria(fecha_hora DESC);
CREATE INDEX IX_bitacora_tabla ON dbo.bitacora_auditoria(tabla_afectada, fecha_hora DESC);
CREATE INDEX IX_bitacora_usuario ON dbo.bitacora_auditoria(usuario_responsable, fecha_hora DESC);
GO

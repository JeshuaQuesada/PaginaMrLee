-- =====================================================================
-- Base de datos para Mr Lee - Módulo Seguimiento de Pedidos
-- SQL Server Management Studio
-- =====================================================================

-- Crear base de datos
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MrLee_DB')
BEGIN
    CREATE DATABASE MrLee_DB;
END
GO

USE MrLee_DB;
GO

-- =====================================================================
-- Tablas del Sistema
-- =====================================================================

-- Catálogo de Estados de Pedidos
CREATE TABLE EstadosPedido (
    IdEstado INT IDENTITY(1,1) PRIMARY KEY,
    NombreEstado NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200),
    Activo BIT DEFAULT 1
);
GO

-- Catálogo de Prioridades
CREATE TABLE Prioridades (
    IdPrioridad INT IDENTITY(1,1) PRIMARY KEY,
    NombrePrioridad NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200),
    Nivel INT NOT NULL CHECK (Nivel > 0)
);
GO

-- Tabla de Roles (para manejo de permisos)
CREATE TABLE Roles (
    IdRol INT IDENTITY(1,1) PRIMARY KEY,
    NombreRol NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500),
    Activo BIT DEFAULT 1
);
GO

-- Tabla de Usuarios del Sistema
CREATE TABLE Usuarios (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto NVARCHAR(200) NOT NULL,
    NombreUsuario NVARCHAR(50) NOT NULL UNIQUE,
    CorreoElectronico NVARCHAR(150) NOT NULL UNIQUE,
    Contrasena NVARCHAR(255) NOT NULL, -- Encriptada
    IdRol INT NOT NULL,
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (IdRol) REFERENCES Roles(IdRol)
);
GO

-- =====================================================================
-- Tablas Principales del Módulo de Seguimiento de Pedidos
-- =====================================================================

-- Tabla de Clientes
CREATE TABLE Clientes (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto NVARCHAR(200) NOT NULL,
    Telefono NVARCHAR(20) NOT NULL,
    CorreoElectronico NVARCHAR(150),
    Direccion NVARCHAR(300) NOT NULL,
    Latitud DECIMAL(10, 8) NULL, -- Para limitación geográfica
    Longitud DECIMAL(11, 8) NULL,  -- Para limitación geográfica
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL
);
GO

-- Tabla Principal de Pedidos
CREATE TABLE Pedidos (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY,
    NumeroSeguimiento NVARCHAR(50) NOT NULL UNIQUE,
    IdCliente INT NOT NULL,
    IdEstado INT NOT NULL,
    IdPrioridad INT NOT NULL,
    IdUsuarioCreacion INT NOT NULL,
    
    -- Datos del pedido
    DireccionEntrega NVARCHAR(300) NOT NULL,
    TelefonoContacto NVARCHAR(20) NOT NULL,
    Observaciones NVARCHAR(MAX) NULL,
    
    -- Fechas importantes
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaPrometida DATE NOT NULL,
    FechaEntregaReal DATETIME NULL,
    
    -- Control de anulación
    Anulado BIT DEFAULT 0,
    FechaAnulacion DATETIME NULL,
    MotivoAnulacion NVARCHAR(500) NULL,
    IdUsuarioAnulacion INT NULL,
    
    -- Datos de auditoría
    FechaUltimaModificacion DATETIME NULL,
    IdUsuarioUltimaModificacion INT NULL,
    
    CONSTRAINT FK_Pedidos_Clientes FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT FK_Pedidos_Estados FOREIGN KEY (IdEstado) REFERENCES EstadosPedido(IdEstado),
    CONSTRAINT FK_Pedidos_Prioridades FOREIGN KEY (IdPrioridad) REFERENCES Prioridades(IdPrioridad),
    CONSTRAINT FK_Pedidos_UsuarioCreacion FOREIGN KEY (IdUsuarioCreacion) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Pedidos_UsuarioAnulacion FOREIGN KEY (IdUsuarioAnulacion) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Pedidos_UsuarioUltimaModificacion FOREIGN KEY (IdUsuarioUltimaModificacion) REFERENCES Usuarios(IdUsuario),
    
    CONSTRAINT CHK_FechaPrometida_Valida CHECK (FechaPrometida >= CAST(FechaCreacion AS DATE) AND FechaPrometida <= DATEADD(MONTH, 2, CAST(FechaCreacion AS DATE))),
    CONSTRAINT CHK_FechaEntrega_Valida CHECK (FechaEntregaReal IS NULL OR FechaEntregaReal >= FechaCreacion)
);
GO

-- Tabla de Detalles de Pedidos (Productos en el pedido)
CREATE TABLE PedidoDetalles (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT NOT NULL,
    NombreProducto NVARCHAR(200) NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(18, 2) NOT NULL CHECK (PrecioUnitario >= 0),
    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED,
    
    CONSTRAINT FK_PedidoDetalles_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos(IdPedido) ON DELETE CASCADE
);
GO

-- Historial de Cambios de Estado (Timeline)
CREATE TABLE HistorialEstados (
    IdHistorial INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT NOT NULL,
    IdEstadoAnterior INT NULL,
    IdEstadoNuevo INT NOT NULL,
    IdUsuarioResponsable INT NOT NULL,
    Comentario NVARCHAR(500) NULL,
    FechaCambio DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_HistorialEstados_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos(IdPedido) ON DELETE CASCADE,
    CONSTRAINT FK_HistorialEstados_EstadoAnterior FOREIGN KEY (IdEstadoAnterior) REFERENCES EstadosPedido(IdEstado),
    CONSTRAINT FK_HistorialEstados_EstadoNuevo FOREIGN KEY (IdEstadoNuevo) REFERENCES EstadosPedido(IdEstado),
    CONSTRAINT FK_HistorialEstados_Usuario FOREIGN KEY (IdUsuarioResponsable) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tabla de Notas del Pedido
CREATE TABLE NotasPedido (
    IdNota INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT NOT NULL,
    IdUsuario INT NOT NULL,
    Nota NVARCHAR(MAX) NOT NULL,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    Activa BIT DEFAULT 1,
    
    CONSTRAINT FK_NotasPedido_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos(IdPedido) ON DELETE CASCADE,
    CONSTRAINT FK_NotasPedido_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- =====================================================================
-- Índices para optimización
-- =====================================================================

CREATE INDEX IX_Pedidos_NumeroSeguimiento ON Pedidos(NumeroSeguimiento);
CREATE INDEX IX_Pedidos_Cliente ON Pedidos(IdCliente);
CREATE INDEX IX_Pedidos_Estado ON Pedidos(IdEstado);
CREATE INDEX IX_Pedidos_FechaCreacion ON Pedidos(FechaCreacion);
CREATE INDEX IX_Pedidos_FechaPrometida ON Pedidos(FechaPrometida);
CREATE INDEX IX_HistorialEstados_Pedido ON HistorialEstados(IdPedido);
CREATE INDEX IX_HistorialEstados_Fecha ON HistorialEstados(FechaCambio);
CREATE INDEX IX_NotasPedido_Pedido ON NotasPedido(IdPedido);
CREATE INDEX IX_Clientes_Telefono ON Clientes(Telefono);
CREATE INDEX IX_Clientes_Correo ON Clientes(CorreoElectronico);

GO

-- =====================================================================
-- Triggers para auditoría automática
-- =====================================================================

-- Trigger para actualizar FechaUltimaModificación en Pedidos
CREATE TRIGGER TR_Pedidos_Auditoria
ON Pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET p.FechaUltimaModificacion = GETDATE(),
        p.IdUsuarioUltimaModificacion = (
            CASE 
                WHEN UPDATE(FechaAnulacion) THEN (SELECT IdUsuarioAnulacion FROM inserted)
                ELSE NULL -- En aplicación real, esto vendría del contexto del usuario
            END
        )
    FROM Pedidos p
    INNER JOIN inserted i ON p.IdPedido = i.IdPedido;
END;
GO

-- Trigger para registrar cambios de estado automáticamente
CREATE TRIGGER TR_Pedidos_RegistrarCambioEstado
ON Pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Solo si cambió el estado
    IF UPDATE(IdEstado)
    BEGIN
        INSERT INTO HistorialEstados (
            IdPedido, 
            IdEstadoAnterior, 
            IdEstadoNuevo, 
            IdUsuarioResponsable, 
            Comentario
        )
        SELECT 
            i.IdPedido,
            d.IdEstado,
            i.IdEstado,
            i.IdUsuarioUltimaModificacion, -- O el usuario actual
            'Cambio de estado automático'
        FROM inserted i
        INNER JOIN deleted d ON i.IdPedido = d.IdPedido
        WHERE i.IdEstado <> d.IdEstado;
    END
END;
GO

PRINT 'Base de datos MrLee_DB - Módulo Seguimiento de Pedidos creada exitosamente';
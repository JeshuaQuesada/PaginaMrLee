-- =====================================================================
-- Módulo de Inventario - Mr Lee (CORREGIDO)
-- SQL Server (SSMS)
-- Se integra con la base de datos MrLee_DB existente
-- Requiere tabla dbo.Usuarios (IdUsuario) ya creada en el proyecto
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- LIMPIEZA (permite re-ejecutar el script)
-- =====================================================================

IF OBJECT_ID('dbo.TR_Productos_Auditoria', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Productos_Auditoria;
IF OBJECT_ID('dbo.TR_Productos_RegistrarCambioPrecio', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Productos_RegistrarCambioPrecio;
IF OBJECT_ID('dbo.TR_Productos_ValidarCambioCodigo', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Productos_ValidarCambioCodigo;
IF OBJECT_ID('dbo.TR_Productos_ValidarDesactivacion', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Productos_ValidarDesactivacion;
GO

IF OBJECT_ID('dbo.sp_RegistrarMovimientoInventario', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarMovimientoInventario;
IF OBJECT_ID('dbo.sp_ConsultarProductos', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ConsultarProductos;
GO

DROP TABLE IF EXISTS dbo.MovimientosInventario;
DROP TABLE IF EXISTS dbo.ImagenesProducto;
DROP TABLE IF EXISTS dbo.HistorialPrecios;
DROP TABLE IF EXISTS dbo.Productos;
DROP TABLE IF EXISTS dbo.Proveedores;
DROP TABLE IF EXISTS dbo.TiposMovimiento;
DROP TABLE IF EXISTS dbo.Categorias;
GO

-- =====================================================================
-- Tablas de Catálogos para Inventario
-- =====================================================================

-- Categorías de Productos
CREATE TABLE dbo.Categorias (
    IdCategoria INT IDENTITY(1,1) CONSTRAINT PK_Categorias PRIMARY KEY,
    NombreCategoria NVARCHAR(100) NOT NULL CONSTRAINT UQ_Categorias_Nombre UNIQUE,
    Descripcion NVARCHAR(500) NULL,
    Activa BIT NOT NULL CONSTRAINT DF_Categorias_Activa DEFAULT 1,
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_Categorias_FechaCreacion DEFAULT GETDATE()
);
GO

-- Tipos de Movimiento de Inventario
-- AfectaStock:  1 = Entrada, -1 = Salida, 0 = Ajuste
CREATE TABLE dbo.TiposMovimiento (
    IdTipoMovimiento INT IDENTITY(1,1) CONSTRAINT PK_TiposMovimiento PRIMARY KEY,
    NombreMovimiento NVARCHAR(50) NOT NULL CONSTRAINT UQ_TiposMovimiento_Nombre UNIQUE,
    Descripcion NVARCHAR(200) NULL,
    AfectaStock SMALLINT NOT NULL CONSTRAINT CHK_TiposMovimiento_AfectaStock CHECK (AfectaStock IN (-1, 0, 1)),
    Activo BIT NOT NULL CONSTRAINT DF_TiposMovimiento_Activo DEFAULT 1
);
GO

-- Datos iniciales (tipos de movimiento básicos)
INSERT INTO dbo.TiposMovimiento (NombreMovimiento, Descripcion, AfectaStock)
VALUES
    ('Entrada', 'Ingreso por compra o recepción',  1),
    ('Salida',  'Salida por venta o consumo',     -1),
    ('Ajuste',  'Ajuste manual (+/-)',            0);
GO

-- Proveedores
CREATE TABLE dbo.Proveedores (
    IdProveedor INT IDENTITY(1,1) CONSTRAINT PK_Proveedores PRIMARY KEY,
    NombreProveedor NVARCHAR(200) NOT NULL,
    Telefono NVARCHAR(20) NULL,
    CorreoElectronico NVARCHAR(150) NULL,
    Direccion NVARCHAR(300) NULL,
    RUC NVARCHAR(20) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Proveedores_Activo DEFAULT 1,
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_Proveedores_FechaCreacion DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL
);
GO

-- =====================================================================
-- Tablas Principales de Inventario
-- =====================================================================

-- Productos (Catálogo principal)
CREATE TABLE dbo.Productos (
    IdProducto INT IDENTITY(1,1) CONSTRAINT PK_Productos PRIMARY KEY,
    CodigoProducto NVARCHAR(50) NOT NULL CONSTRAINT UQ_Productos_Codigo UNIQUE,
    CodigoBarras NVARCHAR(50) NULL, -- SKU opcional
    NombreProducto NVARCHAR(200) NOT NULL,
    Descripcion NVARCHAR(MAX) NULL,

    IdCategoria INT NOT NULL,

    -- Datos de precio y stock
    PrecioUnitario DECIMAL(18, 2) NOT NULL CONSTRAINT CHK_Productos_Precio CHECK (PrecioUnitario >= 0),
    StockActual INT NOT NULL CONSTRAINT DF_Productos_Stock DEFAULT 0 CONSTRAINT CHK_Productos_StockActual CHECK (StockActual >= 0),
    StockMinimo INT NOT NULL CONSTRAINT DF_Productos_StockMin DEFAULT 5 CONSTRAINT CHK_Productos_StockMinimo CHECK (StockMinimo >= 0),
    UnidadMedida NVARCHAR(50) NOT NULL CONSTRAINT DF_Productos_Unidad DEFAULT 'unidad',

    -- Control de estado
    Activo BIT NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT 1,

    -- Columna calculada (CORREGIDA: NO lleva tipo antes de AS)
    TieneStock AS CAST(CASE WHEN StockActual > 0 THEN 1 ELSE 0 END AS BIT) PERSISTED,

    -- Auditoría
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_Productos_FechaCreacion DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    IdUsuarioCreacion INT NOT NULL,
    IdUsuarioUltimaModificacion INT NULL,

    CONSTRAINT FK_Productos_Categorias
        FOREIGN KEY (IdCategoria) REFERENCES dbo.Categorias(IdCategoria),
    CONSTRAINT FK_Productos_UsuarioCreacion
        FOREIGN KEY (IdUsuarioCreacion) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT FK_Productos_UsuarioUltimaModificacion
        FOREIGN KEY (IdUsuarioUltimaModificacion) REFERENCES dbo.Usuarios(IdUsuario)
);
GO

-- Historial de Precios
CREATE TABLE dbo.HistorialPrecios (
    IdHistorialPrecio INT IDENTITY(1,1) CONSTRAINT PK_HistorialPrecios PRIMARY KEY,
    IdProducto INT NOT NULL,
    PrecioAnterior DECIMAL(18, 2) NOT NULL,
    PrecioNuevo DECIMAL(18, 2) NOT NULL,
    MotivoCambio NVARCHAR(500) NOT NULL,
    FechaVigencia DATETIME NOT NULL CONSTRAINT DF_HistorialPrecios_Fecha DEFAULT GETDATE(),
    IdUsuarioResponsable INT NOT NULL,

    CONSTRAINT FK_HistorialPrecios_Productos
        FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT FK_HistorialPrecios_Usuario
        FOREIGN KEY (IdUsuarioResponsable) REFERENCES dbo.Usuarios(IdUsuario)
);
GO

-- Imágenes de Productos
CREATE TABLE dbo.ImagenesProducto (
    IdImagen INT IDENTITY(1,1) CONSTRAINT PK_ImagenesProducto PRIMARY KEY,
    IdProducto INT NOT NULL,
    NombreArchivo NVARCHAR(255) NOT NULL,
    RutaArchivo NVARCHAR(500) NOT NULL,
    Descripcion NVARCHAR(200) NULL,
    Activa BIT NOT NULL CONSTRAINT DF_ImagenesProducto_Activa DEFAULT 1,
    FechaCarga DATETIME NOT NULL CONSTRAINT DF_ImagenesProducto_Fecha DEFAULT GETDATE(),
    IdUsuarioCarga INT NOT NULL,

    CONSTRAINT FK_ImagenesProducto_Productos
        FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT FK_ImagenesProducto_Usuario
        FOREIGN KEY (IdUsuarioCarga) REFERENCES dbo.Usuarios(IdUsuario)
);
GO

-- Movimientos de Inventario (Registro de todas las transacciones)
CREATE TABLE dbo.MovimientosInventario (
    IdMovimiento INT IDENTITY(1,1) CONSTRAINT PK_MovimientosInventario PRIMARY KEY,
    IdProducto INT NOT NULL,
    IdTipoMovimiento INT NOT NULL,
    IdProveedor INT NULL, -- Solo para entradas por compra
    IdUsuarioResponsable INT NOT NULL,

    -- Datos del movimiento
    Cantidad INT NOT NULL, -- Entradas (+), salidas (-), ajustes (+/-)
    StockAnterior INT NOT NULL,
    StockNuevo INT NOT NULL,

    -- Documentación y referencias
    NumeroDocumento NVARCHAR(50) NULL, -- Factura, guía, etc.
    Lote NVARCHAR(50) NULL,
    FechaVencimiento DATE NULL,

    -- Motivo y observaciones
    MotivoMovimiento NVARCHAR(500) NOT NULL,
    Observaciones NVARCHAR(MAX) NULL,

    -- Auditoría
    FechaMovimiento DATETIME NOT NULL CONSTRAINT DF_MovimientosInventario_Fecha DEFAULT GETDATE(),

    CONSTRAINT FK_MovimientosInventario_Productos
        FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT FK_MovimientosInventario_TipoMovimiento
        FOREIGN KEY (IdTipoMovimiento) REFERENCES dbo.TiposMovimiento(IdTipoMovimiento),
    CONSTRAINT FK_MovimientosInventario_Proveedor
        FOREIGN KEY (IdProveedor) REFERENCES dbo.Proveedores(IdProveedor),
    CONSTRAINT FK_MovimientosInventario_Usuario
        FOREIGN KEY (IdUsuarioResponsable) REFERENCES dbo.Usuarios(IdUsuario),

    CONSTRAINT CHK_MovimientosInventario_Cantidad CHECK (Cantidad <> 0),
    CONSTRAINT CHK_MovimientosInventario_Stock CHECK (StockNuevo >= 0)
);
GO

-- =====================================================================
-- Índices para optimización
-- =====================================================================

CREATE INDEX IX_Productos_Codigo ON dbo.Productos(CodigoProducto);
CREATE INDEX IX_Productos_CodigoBarras ON dbo.Productos(CodigoBarras);
CREATE INDEX IX_Productos_Nombre ON dbo.Productos(NombreProducto);
CREATE INDEX IX_Productos_Categoria ON dbo.Productos(IdCategoria);
CREATE INDEX IX_Productos_Activo ON dbo.Productos(Activo);
CREATE INDEX IX_Productos_StockMinimo ON dbo.Productos(StockMinimo);

CREATE INDEX IX_MovimientosInventario_Producto ON dbo.MovimientosInventario(IdProducto);
CREATE INDEX IX_MovimientosInventario_Tipo ON dbo.MovimientosInventario(IdTipoMovimiento);
CREATE INDEX IX_MovimientosInventario_Fecha ON dbo.MovimientosInventario(FechaMovimiento);
CREATE INDEX IX_MovimientosInventario_Proveedor ON dbo.MovimientosInventario(IdProveedor);

CREATE INDEX IX_HistorialPrecios_Producto ON dbo.HistorialPrecios(IdProducto);
CREATE INDEX IX_HistorialPrecios_Fecha ON dbo.HistorialPrecios(FechaVigencia);

CREATE INDEX IX_ImagenesProducto_Producto ON dbo.ImagenesProducto(IdProducto);
CREATE INDEX IX_ImagenesProducto_Activa ON dbo.ImagenesProducto(Activa);
GO

-- =====================================================================
-- Triggers para auditoría y control automático
-- =====================================================================

-- Trigger para actualizar FechaUltimaModificacion en Productos
CREATE TRIGGER dbo.TR_Productos_Auditoria
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET
        p.FechaUltimaModificacion = GETDATE(),
        p.IdUsuarioUltimaModificacion = COALESCE(i.IdUsuarioUltimaModificacion, p.IdUsuarioUltimaModificacion)
    FROM dbo.Productos p
    INNER JOIN inserted i ON p.IdProducto = i.IdProducto;
END;
GO

-- Trigger para registrar cambios de precio en historial
CREATE TRIGGER dbo.TR_Productos_RegistrarCambioPrecio
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(PrecioUnitario)
    BEGIN
        INSERT INTO dbo.HistorialPrecios (
            IdProducto,
            PrecioAnterior,
            PrecioNuevo,
            MotivoCambio,
            IdUsuarioResponsable
        )
        SELECT
            i.IdProducto,
            d.PrecioUnitario,
            i.PrecioUnitario,
            'Actualización de precio',
            COALESCE(i.IdUsuarioUltimaModificacion, i.IdUsuarioCreacion)
        FROM inserted i
        INNER JOIN deleted d ON i.IdProducto = d.IdProducto
        WHERE i.PrecioUnitario <> d.PrecioUnitario;
    END
END;
GO

-- Trigger para validar que no se pueda cambiar código con movimientos
CREATE TRIGGER dbo.TR_Productos_ValidarCambioCodigo
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(CodigoProducto)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON i.IdProducto = d.IdProducto
            WHERE i.CodigoProducto <> d.CodigoProducto
              AND EXISTS (SELECT 1 FROM dbo.MovimientosInventario mi WHERE mi.IdProducto = i.IdProducto)
        )
        BEGIN
            RAISERROR('No se puede cambiar el código de un producto que ya tiene movimientos de inventario.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

-- Trigger para validar desactivación con stock
CREATE TRIGGER dbo.TR_Productos_ValidarDesactivacion
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Activo)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON i.IdProducto = d.IdProducto
            WHERE i.Activo = 0 AND d.Activo = 1
              AND i.StockActual > 0
        )
        BEGIN
            RAISERROR('No se puede desactivar un producto que tiene stock disponible. Primero debe drenar o ajustar el stock.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

-- =====================================================================
-- Procedimientos Almacenados Útiles
-- =====================================================================

-- Procedimiento para registrar movimiento de inventario
CREATE PROCEDURE dbo.sp_RegistrarMovimientoInventario
    @IdProducto INT,
    @IdTipoMovimiento INT,
    @Cantidad INT,
    @Motivo NVARCHAR(500),
    @IdUsuario INT,
    @IdProveedor INT = NULL,
    @NumeroDocumento NVARCHAR(50) = NULL,
    @Lote NVARCHAR(50) = NULL,
    @FechaVencimiento DATE = NULL,
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StockAnterior INT;
    DECLARE @StockNuevo INT;
    DECLARE @AfectaStock SMALLINT;
    DECLARE @CantidadRegistrada INT;

    -- Validaciones base
    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE IdProducto = @IdProducto)
    BEGIN
        RAISERROR('El producto no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TiposMovimiento WHERE IdTipoMovimiento = @IdTipoMovimiento AND Activo = 1)
    BEGIN
        RAISERROR('El tipo de movimiento no existe o está inactivo.', 16, 1);
        RETURN;
    END

    IF @Cantidad = 0
    BEGIN
        RAISERROR('La cantidad no puede ser 0.', 16, 1);
        RETURN;
    END

    -- Obtener stock actual y cómo afecta el movimiento
    SELECT @StockAnterior = StockActual FROM dbo.Productos WHERE IdProducto = @IdProducto;
    SELECT @AfectaStock = AfectaStock FROM dbo.TiposMovimiento WHERE IdTipoMovimiento = @IdTipoMovimiento;

    -- Normalizar cantidad para guardar el signo correcto:
    -- Entrada:  +ABS(cantidad)
    -- Salida:   -ABS(cantidad)
    -- Ajuste:   cantidad tal cual (+/-)
    IF @AfectaStock = 1
        SET @CantidadRegistrada = ABS(@Cantidad);
    ELSE IF @AfectaStock = -1
        SET @CantidadRegistrada = -ABS(@Cantidad);
    ELSE
        SET @CantidadRegistrada = @Cantidad;

    SET @StockNuevo = @StockAnterior + @CantidadRegistrada;

    IF @StockNuevo < 0
    BEGIN
        RAISERROR('Stock insuficiente para realizar esta operación.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
        INSERT INTO dbo.MovimientosInventario (
            IdProducto, IdTipoMovimiento, IdProveedor, IdUsuarioResponsable,
            Cantidad, StockAnterior, StockNuevo, NumeroDocumento, Lote, FechaVencimiento,
            MotivoMovimiento, Observaciones
        ) VALUES (
            @IdProducto, @IdTipoMovimiento, @IdProveedor, @IdUsuario,
            @CantidadRegistrada, @StockAnterior, @StockNuevo, @NumeroDocumento, @Lote, @FechaVencimiento,
            @Motivo, @Observaciones
        );

        UPDATE dbo.Productos
        SET StockActual = @StockNuevo,
            FechaUltimaModificacion = GETDATE(),
            IdUsuarioUltimaModificacion = @IdUsuario
        WHERE IdProducto = @IdProducto;
    COMMIT TRANSACTION;
END;
GO

-- Procedimiento para consultar productos con filtros
CREATE PROCEDURE dbo.sp_ConsultarProductos
    @TextoBusqueda NVARCHAR(200) = NULL,
    @IdCategoria INT = NULL,
    @Activo BIT = NULL,
    @OrdenPor NVARCHAR(50) = 'NombreProducto',
    @OrdenDireccion NVARCHAR(4) = 'ASC',
    @Pagina INT = 1,
    @TamanoPagina INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Pagina - 1) * @TamanoPagina;

    -- Query dinámica con filtros
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT
            p.IdProducto, p.CodigoProducto, p.CodigoBarras, p.NombreProducto,
            p.Descripcion, p.PrecioUnitario, p.StockActual, p.StockMinimo,
            p.UnidadMedida, p.Activo, p.TieneStock, p.FechaCreacion,
            c.NombreCategoria,
            (SELECT TOP 1 NombreArchivo
             FROM dbo.ImagenesProducto
             WHERE IdProducto = p.IdProducto AND Activa = 1
             ORDER BY FechaCarga DESC) AS ImagenPrincipal
        FROM dbo.Productos p
        INNER JOIN dbo.Categorias c ON p.IdCategoria = c.IdCategoria
        WHERE 1=1';

    -- Agregar filtros (nota: para tareas académicas; en producción se parametriza para evitar SQL injection)
    IF @TextoBusqueda IS NOT NULL
        SET @SQL = @SQL + N' AND (p.NombreProducto LIKE ''%' + @TextoBusqueda + N'%'' OR p.CodigoProducto LIKE ''%' + @TextoBusqueda + N'%'' OR p.CodigoBarras LIKE ''%' + @TextoBusqueda + N'%'')';

    IF @IdCategoria IS NOT NULL
        SET @SQL = @SQL + N' AND p.IdCategoria = ' + CAST(@IdCategoria AS NVARCHAR(10));

    IF @Activo IS NOT NULL
        SET @SQL = @SQL + N' AND p.Activo = ' + CAST(@Activo AS NVARCHAR(1));

    -- Agregar ordenamiento
    SET @SQL = @SQL + N' ORDER BY ' +
        CASE @OrdenPor
            WHEN 'NombreProducto' THEN N'p.NombreProducto'
            WHEN 'CodigoProducto' THEN N'p.CodigoProducto'
            WHEN 'FechaCreacion' THEN N'p.FechaCreacion'
            WHEN 'StockActual' THEN N'p.StockActual'
            ELSE N'p.NombreProducto'
        END + N' ' + @OrdenDireccion;

    -- Agregar paginación
    SET @SQL = @SQL + N' OFFSET ' + CAST(@Offset AS NVARCHAR(10)) + N' ROWS FETCH NEXT ' + CAST(@TamanoPagina AS NVARCHAR(10)) + N' ROWS ONLY';

    EXEC sp_executesql @SQL;
END;
GO

PRINT 'Módulo de Inventario creado exitosamente en MrLee_DB (CORREGIDO)';

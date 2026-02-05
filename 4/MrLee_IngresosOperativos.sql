-- =====================================================================
--  Módulo de Ingresos Operativos - Mr Lee (CORREGIDO)
--  SQL Server Management Studio
--  Integración con la base de datos MrLee_DB existente
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Tablas de Catálogos para Ingresos Operativos
-- =====================================================================

-- Tipos de Ingreso
CREATE TABLE TiposIngreso (
    IdTipoIngreso INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipo NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500),
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Categorías de Ingreso
CREATE TABLE CategoriasIngreso (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500),
    Activa BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Métodos de Pago
CREATE TABLE MetodosPago (
    IdMetodoPago INT IDENTITY(1,1) PRIMARY KEY,
    NombreMetodo NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200),
    RequiereReferencia BIT DEFAULT 0,
    RequiereDatosTarjeta BIT DEFAULT 0,
    RequiereBanco BIT DEFAULT 0,
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Periodos Contables
CREATE TABLE PeriodosContables (
    IdPeriodo INT IDENTITY(1,1) PRIMARY KEY,
    NombrePeriodo NVARCHAR(20) NOT NULL UNIQUE, -- Formato: YYYY-MM
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Estado NVARCHAR(20) NOT NULL DEFAULT 'ABIERTO', -- ABIERTO, CERRADO
    FechaCierre DATETIME NULL,
    IdUsuarioCierre INT NULL,
    MotivoCierre NVARCHAR(500) NULL,
    
    CONSTRAINT CHK_Periodos_Fechas_Validas CHECK (FechaFin > FechaInicio),
    CONSTRAINT CHK_Periodos_Estado_Valido CHECK (Estado IN ('ABIERTO', 'CERRADO')),
    CONSTRAINT FK_Periodos_UsuarioCierre FOREIGN KEY (IdUsuarioCierre) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tipos de Cambio (USD/CRC)
CREATE TABLE TiposCambio (
    IdTipoCambio INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    TipoCambio DECIMAL(10, 4) NOT NULL CHECK (TipoCambio > 0),
    MonedaOrigen NVARCHAR(3) NOT NULL DEFAULT 'USD',
    MonedaDestino NVARCHAR(3) NOT NULL DEFAULT 'CRC',
    IdUsuarioRegistro INT NOT NULL,
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1,
    
    CONSTRAINT FK_TiposCambio_Usuario FOREIGN KEY (IdUsuarioRegistro) REFERENCES Usuarios(IdUsuario)
);
GO

-- =====================================================================
-- Tablas Principales de Ingresos Operativos
-- =====================================================================

-- Ingresos Operativos (Tabla principal)
CREATE TABLE IngresosOperativos (
    IdIngreso INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Datos básicos
    FechaIngreso DATE NOT NULL,
    IdPeriodo INT NOT NULL,
    Monto DECIMAL(12, 2) NOT NULL CHECK (Monto > 0),
    Moneda NVARCHAR(3) NOT NULL DEFAULT 'CRC', -- CRC o USD
    
    -- Clasificación
    IdTipoIngreso INT NOT NULL,
    IdCategoria INT NOT NULL,
    IdMetodoPago INT NOT NULL,
    
    -- Referencia y pago
    ReferenciaPago NVARCHAR(100) NULL,
    
    -- Datos específicos por método de pago
    Ultimos4Tarjeta INT NULL, -- Últimos 4 dígitos de tarjeta
    VoucherAutorizacion NVARCHAR(50) NULL,
    Banco NVARCHAR(100) NULL,
    NumeroCheque NVARCHAR(50) NULL,
    
    -- Relaciones con otros módulos
    IdCliente INT NULL,
    IdPedido INT NULL,
    
    -- Conversión de moneda
    IdTipoCambio INT NULL, -- Solo si es USD
    MontoUSD DECIMAL(12, 2) NULL, -- Monto original en USD
    MontoCRC DECIMAL(12, 2) NULL, -- Monto convertido a CRC
    
    -- Estado y control
    Estado NVARCHAR(20) NOT NULL DEFAULT 'REGISTRADO', -- REGISTRADO, ANULADO
    MotivoAnulacion NVARCHAR(500) NULL,
    FechaAnulacion DATETIME NULL,
    IdUsuarioAnulacion INT NULL,
    
    -- Auditoría
    IdUsuarioCreacion INT NOT NULL,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    IdUsuarioUltimaModificacion INT NULL,
    FechaUltimaModificacion DATETIME NULL,
    
    CONSTRAINT FK_Ingresos_Periodo FOREIGN KEY (IdPeriodo) REFERENCES PeriodosContables(IdPeriodo),
    CONSTRAINT FK_Ingresos_TipoIngreso FOREIGN KEY (IdTipoIngreso) REFERENCES TiposIngreso(IdTipoIngreso),
    CONSTRAINT FK_Ingresos_Categoria FOREIGN KEY (IdCategoria) REFERENCES CategoriasIngreso(IdCategoria),
    CONSTRAINT FK_Ingresos_MetodoPago FOREIGN KEY (IdMetodoPago) REFERENCES MetodosPago(IdMetodoPago),
    CONSTRAINT FK_Ingresos_TipoCambio FOREIGN KEY (IdTipoCambio) REFERENCES TiposCambio(IdTipoCambio),
    CONSTRAINT FK_Ingresos_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT FK_Ingresos_Pedido FOREIGN KEY (IdPedido) REFERENCES Pedidos(IdPedido),
    CONSTRAINT FK_Ingresos_UsuarioCreacion FOREIGN KEY (IdUsuarioCreacion) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Ingresos_UsuarioAnulacion FOREIGN KEY (IdUsuarioAnulacion) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Ingresos_UsuarioUltimaModificacion FOREIGN KEY (IdUsuarioUltimaModificacion) REFERENCES Usuarios(IdUsuario),
    
    CONSTRAINT CHK_Ingresos_Moneda_Valida CHECK (Moneda IN ('CRC', 'USD')),
    CONSTRAINT CHK_Ingresos_Estado_Valido CHECK (Estado IN ('REGISTRADO', 'ANULADO')),
    CONSTRAINT CHK_Ingresos_Ultimos4Tarjeta_Valido CHECK (Ultimos4Tarjeta IS NULL OR (Ultimos4Tarjeta >= 1000 AND Ultimos4Tarjeta <= 9999)),
    CONSTRAINT CHK_Ingresos_MontoUSD_Valido CHECK (MontoUSD IS NULL OR MontoUSD > 0),
    CONSTRAINT CHK_Ingresos_MontoCRC_Valido CHECK (MontoCRC IS NULL OR MontoCRC > 0)
);
GO

-- Auditoría Específica de Ingresos
CREATE TABLE AuditoriaIngresos (
    IdAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    IdIngreso INT NULL, -- NULL si es operación general
    IdUsuario INT NOT NULL,
    Accion NVARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE, ANULAR, CERRAR_PERIODO, REABRIR_PERIODO
    Modulo NVARCHAR(50) NOT NULL DEFAULT 'INGRESOS',
    DescripcionAccion NVARCHAR(500) NOT NULL,
    
    -- Datos anteriores y nuevos (JSON)
    ValoresAnteriores NVARCHAR(MAX) NULL,
    ValoresNuevos NVARCHAR(MAX) NULL,
    
    -- Contexto
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    
    FechaAccion DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_AuditoriaIngresos_Ingreso FOREIGN KEY (IdIngreso) REFERENCES IngresosOperativos(IdIngreso),
    CONSTRAINT FK_AuditoriaIngresos_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Presets de Filtros Personalizados
CREATE TABLE PresetsFiltrosIngresos (
    IdPreset INT IDENTITY(1,1) PRIMARY KEY,
    NombrePreset NVARCHAR(100) NOT NULL,
    IdUsuario INT NOT NULL,
    
    -- Filtros guardados
    FechaInicio DATE NULL,
    FechaFin DATE NULL,
    IdTipoIngreso INT NULL,
    IdCategoria INT NULL,
    IdMetodoPago INT NULL,
    Estado NVARCHAR(20) NULL,
    Moneda NVARCHAR(3) NULL,
    
    -- Configuración
    Publico BIT DEFAULT 0, -- Si otros usuarios pueden verlo
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaUltimoUso DATETIME NULL,
    
    CONSTRAINT FK_PresetsFiltros_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- =====================================================================
-- Índices para optimización
-- =====================================================================

CREATE INDEX IX_Ingresos_Fecha ON IngresosOperativos(FechaIngreso);
CREATE INDEX IX_Ingresos_Periodo ON IngresosOperativos(IdPeriodo);
CREATE INDEX IX_Ingresos_Estado ON IngresosOperativos(Estado);
CREATE INDEX IX_Ingresos_Moneda ON IngresosOperativos(Moneda);
CREATE INDEX IX_Ingresos_TipoIngreso ON IngresosOperativos(IdTipoIngreso);
CREATE INDEX IX_Ingresos_Categoria ON IngresosOperativos(IdCategoria);
CREATE INDEX IX_Ingresos_MetodoPago ON IngresosOperativos(IdMetodoPago);
CREATE INDEX IX_Ingresos_Cliente ON IngresosOperativos(IdCliente);
CREATE INDEX IX_Ingresos_Pedido ON IngresosOperativos(IdPedido);
CREATE INDEX IX_Ingresos_Referencia ON IngresosOperativos(ReferenciaPago);
CREATE INDEX IX_Ingresos_FechaCreacion ON IngresosOperativos(FechaCreacion);

CREATE INDEX IX_AuditoriaIngresos_Ingreso ON AuditoriaIngresos(IdIngreso);
CREATE INDEX IX_AuditoriaIngresos_Usuario ON AuditoriaIngresos(IdUsuario);
CREATE INDEX IX_AuditoriaIngresos_Fecha ON AuditoriaIngresos(FechaAccion);
CREATE INDEX IX_AuditoriaIngresos_Accion ON AuditoriaIngresos(Accion);

CREATE INDEX IX_PeriodosContables_Estado ON PeriodosContables(Estado);
CREATE INDEX IX_PeriodosContables_Fechas ON PeriodosContables(FechaInicio, FechaFin);

CREATE INDEX IX_TiposCambio_Fecha ON TiposCambio(Fecha);
CREATE INDEX IX_TiposCambio_Activo ON TiposCambio(Activo);
GO

-- =====================================================================
-- Triggers para Auditoría y Validaciones
-- =====================================================================

-- Trigger para auditoría automática de ingresos
CREATE TRIGGER TR_IngresosOperativos_Auditoria
ON IngresosOperativos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Para INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaIngresos (
            IdIngreso, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdIngreso, i.IdUsuarioCreacion, 'INSERT', 'INGRESOS', 
            'Creación de ingreso operativo',
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdIngreso = i.IdIngreso
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i;
    END
    
    -- Para UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaIngresos (
            IdIngreso, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresAnteriores, ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdIngreso, 
            ISNULL(i.IdUsuarioUltimaModificacion, i.IdUsuarioCreacion), 
            'UPDATE', 'INGRESOS', 'Modificación de ingreso operativo',
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdIngreso = i.IdIngreso
                FOR JSON PATH
            ),
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdIngreso = i.IdIngreso
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i
        INNER JOIN deleted d ON i.IdIngreso = d.IdIngreso;
    END
    
    -- Para DELETE (baja lógica)
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaIngresos (
            IdIngreso, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresAnteriores, DireccionIP, Navegador
        )
        SELECT 
            d.IdIngreso, d.IdUsuarioCreacion, 'DELETE', 'INGRESOS', 
            'Eliminación de ingreso operativo',
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdIngreso = d.IdIngreso
                FOR JSON PATH
            ),
            NULL, NULL
        FROM deleted d;
    END
END;
GO

-- Trigger para validar periodo contable
CREATE TRIGGER TR_Ingresos_ValidarPeriodo
ON IngresosOperativos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que el periodo esté abierto
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN PeriodosContables pc ON i.IdPeriodo = pc.IdPeriodo
        WHERE pc.Estado = 'CERRADO'
    )
    BEGIN
        RAISERROR('No se puede registrar ingresos en un periodo contable cerrado.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Validar que la fecha esté dentro del periodo
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN PeriodosContables pc ON i.IdPeriodo = pc.IdPeriodo
        WHERE i.FechaIngreso < pc.FechaInicio OR i.FechaIngreso > pc.FechaFin
    )
    BEGIN
        RAISERROR('La fecha del ingreso debe estar dentro del rango del periodo contable.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger para validar duplicados por referencia del mismo día
CREATE TRIGGER TR_Ingresos_ValidarDuplicados
ON IngresosOperativos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        WHERE EXISTS (
            SELECT 1 
            FROM IngresosOperativos io 
            WHERE io.ReferenciaPago = i.ReferenciaPago 
            AND io.FechaIngreso = i.FechaIngreso 
            AND io.IdMetodoPago = i.IdMetodoPago
            AND io.IdIngreso <> i.IdIngreso
            AND io.Estado = 'REGISTRADO'
        )
        AND i.ReferenciaPago IS NOT NULL
    )
    BEGIN
        RAISERROR('Ya existe un ingreso con la misma referencia de pago en la misma fecha.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- =====================================================================
-- Procedimientos Almacenados
-- =====================================================================

-- Procedimiento para registrar ingreso operativo
CREATE PROCEDURE sp_RegistrarIngresoOperativo
    @FechaIngreso DATE,
    @Monto DECIMAL(12, 2),
    @Moneda NVARCHAR(3),
    @IdTipoIngreso INT,
    @IdCategoria INT,
    @IdMetodoPago INT,
    @ReferenciaPago NVARCHAR(100) = NULL,
    @Ultimos4Tarjeta INT = NULL,
    @VoucherAutorizacion NVARCHAR(50) = NULL,
    @Banco NVARCHAR(100) = NULL,
    @NumeroCheque NVARCHAR(50) = NULL,
    @IdCliente INT = NULL,
    @IdPedido INT = NULL,
    @IdUsuarioCreacion INT,
    @Observaciones NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdPeriodo INT;
    DECLARE @IdTipoCambio INT = NULL;
    DECLARE @TipoCambio DECIMAL(10, 4) = NULL;
    DECLARE @MontoUSD DECIMAL(12, 2) = NULL;
    DECLARE @MontoCRC DECIMAL(12, 2) = NULL;
    
    -- Determinar periodo contable
    SELECT @IdPeriodo = IdPeriodo
    FROM PeriodosContables
    WHERE @FechaIngreso BETWEEN FechaInicio AND FechaFin
    AND Estado = 'ABIERTO';
    
    IF @IdPeriodo IS NULL
    BEGIN
        SELECT 0 as Exito, 'No existe un periodo contable abierto para la fecha especificada' as Mensaje;
        RETURN;
    END
    
    -- Validar y obtener tipo de cambio si es USD
    IF @Moneda = 'USD'
    BEGIN
        SELECT @IdTipoCambio = IdTipoCambio, @TipoCambio = TipoCambio
        FROM TiposCambio
        WHERE Fecha = @FechaIngreso AND Activo = 1;
        
        IF @IdTipoCambio IS NULL
        BEGIN
            SELECT 0 as Exito, 'No existe un tipo de cambio registrado para la fecha en USD' as Mensaje;
            RETURN;
        END
        
        SET @MontoUSD = @Monto;
        SET @MontoCRC = @Monto * @TipoCambio;
    END
    ELSE
    BEGIN
        SET @MontoCRC = @Monto;
    END
    
    -- Validar datos específicos del método de pago
    DECLARE @RequiereReferencia BIT, @RequiereDatosTarjeta BIT, @RequiereBanco BIT;
    
    SELECT @RequiereReferencia = RequiereReferencia, 
           @RequiereDatosTarjeta = RequiereDatosTarjeta,
           @RequiereBanco = RequiereBanco
    FROM MetodosPago
    WHERE IdMetodoPago = @IdMetodoPago;
    
    -- Validaciones según método de pago
    IF @RequiereReferencia = 1 AND @ReferenciaPago IS NULL
    BEGIN
        SELECT 0 as Exito, 'El método de pago seleccionado requiere una referencia de pago' as Mensaje;
        RETURN;
    END
    
    IF @RequiereDatosTarjeta = 1 AND (@Ultimos4Tarjeta IS NULL OR @VoucherAutorizacion IS NULL)
    BEGIN
        SELECT 0 as Exito, 'El pago con tarjeta requiere los últimos 4 dígitos y el voucher de autorización' as Mensaje;
        RETURN;
    END
    
    IF @RequiereBanco = 1 AND @Banco IS NULL
    BEGIN
        SELECT 0 as Exito, 'El método de pago seleccionado requiere el nombre del banco' as Mensaje;
        RETURN;
    END
    
    -- Insertar ingreso
    INSERT INTO IngresosOperativos (
        FechaIngreso, IdPeriodo, Monto, Moneda, IdTipoIngreso, IdCategoria, IdMetodoPago,
        ReferenciaPago, Ultimos4Tarjeta, VoucherAutorizacion, Banco, NumeroCheque,
        IdCliente, IdPedido, IdTipoCambio, MontoUSD, MontoCRC, IdUsuarioCreacion
    )
    VALUES (
        @FechaIngreso, @IdPeriodo, @Monto, @Moneda, @IdTipoIngreso, @IdCategoria, @IdMetodoPago,
        @ReferenciaPago, @Ultimos4Tarjeta, @VoucherAutorizacion, @Banco, @NumeroCheque,
        @IdCliente, @IdPedido, @IdTipoCambio, @MontoUSD, @MontoCRC, @IdUsuarioCreacion
    );
    
    DECLARE @IdIngreso INT = SCOPE_IDENTITY();
    
    SELECT 1 as Exito, 'Ingreso registrado exitosamente' as Mensaje, @IdIngreso as IdIngreso;
END;
GO

-- Procedimiento para consultar ingresos con filtros
CREATE PROCEDURE sp_ConsultarIngresos
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @IdTipoIngreso INT = NULL,
    @IdCategoria INT = NULL,
    @IdMetodoPago INT = NULL,
    @Estado NVARCHAR(20) = NULL,
    @Moneda NVARCHAR(3) = NULL,
    @Pagina INT = 1,
    @TamanoPagina INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar rango de fechas (máximo 31 días)
    IF @FechaInicio IS NOT NULL AND @FechaFin IS NOT NULL
    BEGIN
        DECLARE @DiasRango INT = DATEDIFF(DAY, @FechaInicio, @FechaFin);
        IF @DiasRango > 31
        BEGIN
            SELECT 0 as Exito, 'El rango de fechas no puede superar los 31 días' as Mensaje;
            RETURN;
        END
        
        -- Corregir rango invertido
        IF @FechaInicio > @FechaFin
        BEGIN
            DECLARE @TempFecha DATE = @FechaInicio;
            SET @FechaInicio = @FechaFin;
            SET @FechaFin = @TempFecha;
        END
    END
    
    DECLARE @Offset INT = (@Pagina - 1) * @TamanoPagina;
    
    -- Query principal
    SELECT 
        io.IdIngreso, io.FechaIngreso, io.Monto, io.Moneda, io.Estado,
        io.ReferenciaPago, io.FechaCreacion,
        ti.NombreTipo as TipoIngreso,
        ci.NombreCategoria as Categoria,
        mp.NombreMetodo as MetodoPago,
        ISNULL(c.NombreCompleto, 'Sin cliente') as NombreCliente,
        ISNULL(p.NumeroSeguimiento, 'Sin pedido') as NumeroPedido,
        u.NombreCompleto as UsuarioCreacion,
        CASE 
            WHEN io.Moneda = 'USD' AND io.MontoUSD IS NOT NULL THEN '$' + CAST(io.MontoUSD AS NVARCHAR(20))
            ELSE '₡' + CAST(io.MontoCRC AS NVARCHAR(20))
        END as MontoFormateado
    FROM IngresosOperativos io
    INNER JOIN TiposIngreso ti ON io.IdTipoIngreso = ti.IdTipoIngreso
    INNER JOIN CategoriasIngreso ci ON io.IdCategoria = ci.IdCategoria
    INNER JOIN MetodosPago mp ON io.IdMetodoPago = mp.IdMetodoPago
    INNER JOIN Usuarios u ON io.IdUsuarioCreacion = u.IdUsuario
    LEFT JOIN Clientes c ON io.IdCliente = c.IdCliente
    LEFT JOIN Pedidos p ON io.IdPedido = p.IdPedido
    WHERE (@FechaInicio IS NULL OR io.FechaIngreso >= @FechaInicio)
    AND (@FechaFin IS NULL OR io.FechaIngreso <= @FechaFin)
    AND (@IdTipoIngreso IS NULL OR io.IdTipoIngreso = @IdTipoIngreso)
    AND (@IdCategoria IS NULL OR io.IdCategoria = @IdCategoria)
    AND (@IdMetodoPago IS NULL OR io.IdMetodoPago = @IdMetodoPago)
    AND (@Estado IS NULL OR io.Estado = @Estado)
    AND (@Moneda IS NULL OR io.Moneda = @Moneda)
    ORDER BY io.FechaIngreso DESC, io.FechaCreacion DESC
    OFFSET @Offset ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
    
    -- Total de registros
    SELECT COUNT(*) as TotalRegistros
    FROM IngresosOperativos io
    WHERE (@FechaInicio IS NULL OR io.FechaIngreso >= @FechaInicio)
    AND (@FechaFin IS NULL OR io.FechaIngreso <= @FechaFin)
    AND (@IdTipoIngreso IS NULL OR io.IdTipoIngreso = @IdTipoIngreso)
    AND (@IdCategoria IS NULL OR io.IdCategoria = @IdCategoria)
    AND (@IdMetodoPago IS NULL OR io.IdMetodoPago = @IdMetodoPago)
    AND (@Estado IS NULL OR io.Estado = @Estado)
    AND (@Moneda IS NULL OR io.Moneda = @Moneda);
    
    SELECT 1 as Exito, 'Consulta ejecutada exitosamente' as Mensaje;
END;
GO

-- Procedimiento para obtener sumas agregadas
CREATE PROCEDURE sp_ObtenerSumasIngresos
    @FechaInicio DATE,
    @FechaFin DATE,
    @Agregacion NVARCHAR(10) = 'DIA', -- DIA, SEMANA, MES, AÑO
    @IdCategoria INT = NULL,
    @IdMetodoPago INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX) = '
    SELECT 
        CASE 
            WHEN @Agregacion = ''DIA'' THEN CAST(io.FechaIngreso AS DATE)
            WHEN @Agregacion = ''SEMANA'' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, io.FechaIngreso) - 1), CAST(io.FechaIngreso AS DATE))
            WHEN @Agregacion = ''MES'' THEN DATEFROMPARTS(YEAR(io.FechaIngreso), MONTH(io.FechaIngreso), 1)
            WHEN @Agregacion = ''AÑO'' THEN DATEFROMPARTS(YEAR(io.FechaIngreso), 1, 1)
        END as Periodo,
        COUNT(*) as TotalIngresos,
        SUM(io.MontoCRC) as TotalCRC,
        SUM(ISNULL(io.MontoUSD, 0)) as TotalUSD,
        AVG(io.MontoCRC) as PromedioCRC
    FROM IngresosOperativos io
    WHERE io.FechaIngreso BETWEEN @FechaInicio AND @FechaFin
    AND io.Estado = ''REGISTRADO'''
    
    -- Agregar filtros adicionales
    IF @IdCategoria IS NOT NULL
        SET @SQL = @SQL + ' AND io.IdCategoria = @IdCategoria';
    
    IF @IdMetodoPago IS NOT NULL
        SET @SQL = @SQL + ' AND io.IdMetodoPago = @IdMetodoPago';
    
    SET @SQL = @SQL + '
    GROUP BY 
        CASE 
            WHEN @Agregacion = ''DIA'' THEN CAST(io.FechaIngreso AS DATE)
            WHEN @Agregacion = ''SEMANA'' THEN DATEADD(DAY, -(DATEPART(WEEKDAY, io.FechaIngreso) - 1), CAST(io.FechaIngreso AS DATE))
            WHEN @Agregacion = ''MES'' THEN DATEFROMPARTS(YEAR(io.FechaIngreso), MONTH(io.FechaIngreso), 1)
            WHEN @Agregacion = ''AÑO'' THEN DATEFROMPARTS(YEAR(io.FechaIngreso), 1, 1)
        END
    ORDER BY Periodo';
    
    EXEC sp_executesql @SQL, 
        N'@FechaInicio DATE, @FechaFin DATE, @Agregacion NVARCHAR(10), @IdCategoria INT, @IdMetodoPago INT',
        @FechaInicio, @FechaFin, @Agregacion, @IdCategoria, @IdMetodoPago;
END;
GO

PRINT 'Módulo de Ingresos Operativos creado exitosamente en MrLee_DB (CORREGIDO)';

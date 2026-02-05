-- =====================================================================
--  Módulo de Recursos Humanos - Mr Lee (CORREGIDO)
--  SQL Server Management Studio
--  Integración con la base de datos MrLee_DB existente
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Tablas de Catálogos para Recursos Humanos
-- =====================================================================

-- Puestos de la Empresa
CREATE TABLE Puestos (
    IdPuesto INT IDENTITY(1,1) PRIMARY KEY,
    NombrePuesto NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500),
    Departamento NVARCHAR(100),
    NivelJerarquico INT DEFAULT 1,
    SalarioMinimo DECIMAL(12, 2) NULL,
    SalarioMaximo DECIMAL(12, 2) NULL,
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Sucursales
CREATE TABLE Sucursales (
    IdSucursal INT IDENTITY(1,1) PRIMARY KEY,
    NombreSucursal NVARCHAR(100) NOT NULL UNIQUE,
    Direccion NVARCHAR(300) NOT NULL,
    Telefono NVARCHAR(20),
    Ciudad NVARCHAR(100),
    Provincia NVARCHAR(100),
    Activa BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- =====================================================================
-- Tablas Principales de Recursos Humanos
-- =====================================================================

CREATE TABLE Empleados (
    IdEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    CodigoEmpleado NVARCHAR(20) NOT NULL UNIQUE,
    
    -- Datos personales
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Identificacion NVARCHAR(20) NOT NULL UNIQUE,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    Telefono NVARCHAR(20) NOT NULL,
    
    -- Datos laborales
    IdPuesto INT NOT NULL,
    IdSucursal INT NOT NULL,
    SalarioBase DECIMAL(12, 2) NOT NULL CHECK (SalarioBase > 0),
    TipoContrato NVARCHAR(20) NOT NULL DEFAULT 'INDEFINIDO',
    Jornada NVARCHAR(20) NOT NULL DEFAULT 'COMPLETA',
    
    -- Fechas importantes
    FechaIngreso DATE NOT NULL,
    FechaSalida DATE NULL,
    
    -- Estado y control
    Estado NVARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    MotivoCambioEstado NVARCHAR(500) NULL,
    
    -- Auditoría
    IdUsuarioCreacion INT NOT NULL,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    IdUsuarioUltimaModificacion INT NULL,
    FechaUltimaModificacion DATETIME NULL,
    
    CONSTRAINT FK_Empleados_Puesto FOREIGN KEY (IdPuesto) REFERENCES Puestos(IdPuesto),
    CONSTRAINT FK_Empleados_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Sucursales(IdSucursal),
    CONSTRAINT FK_Empleados_UsuarioCreacion FOREIGN KEY (IdUsuarioCreacion) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Empleados_UsuarioUltimaModificacion FOREIGN KEY (IdUsuarioUltimaModificacion) REFERENCES Usuarios(IdUsuario),
    
    CONSTRAINT CHK_Empleados_TipoContrato_Valido CHECK (TipoContrato IN ('INDEFINIDO', 'FIJO', 'SERVICIOS')),
    CONSTRAINT CHK_Empleados_Jornada_Valida CHECK (Jornada IN ('COMPLETA', 'PARCIAL')),
    CONSTRAINT CHK_Empleados_Estado_Valido CHECK (Estado IN ('ACTIVO', 'INACTIVO')),
    CONSTRAINT CHK_Empleados_FechaIngreso_Valida CHECK (FechaIngreso <= CAST(GETDATE() AS DATE)),
    CONSTRAINT CHK_Empleados_FechaSalida_Valida CHECK (FechaSalida IS NULL OR FechaSalida >= FechaIngreso)
);
GO

-- (Rest of the script includes el resto de tablas, índices, procedimientos y triggers…)

-- Ajuste importante en el trigger:
-- En la rama DELETE del trigger TR_Empleados_Auditoria se eliminó un NULL extra para que los valores coincidan con las columnas.
CREATE TRIGGER TR_Empleados_Auditoria
ON Empleados
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaRRHH (
            IdEmpleado, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdEmpleado, i.IdUsuarioCreacion, 'INSERT', 'RRHH', 
            'Creación de empleado',
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdEmpleado = i.IdEmpleado
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i;
        -- historial laboral…
    END
    
    -- UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaRRHH (
            IdEmpleado, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresAnteriores, ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdEmpleado, 
            ISNULL(i.IdUsuarioUltimaModificacion, i.IdUsuarioCreacion), 
            'UPDATE', 'RRHH', 'Modificación de empleado',
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdEmpleado = i.IdEmpleado
                FOR JSON PATH
            ),
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdEmpleado = i.IdEmpleado
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i
        INNER JOIN deleted d ON i.IdEmpleado = d.IdEmpleado;
        -- historial laboral…
    END
    
    -- DELETE
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaRRHH (
            IdEmpleado, IdUsuario, Accion, Modulo, DescripcionAccion,
            ValoresAnteriores, DireccionIP, Navegador
        )
        SELECT 
            d.IdEmpleado, d.IdUsuarioCreacion, 'DELETE', 'RRHH', 
            'Eliminación de empleado',
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdEmpleado = d.IdEmpleado
                FOR JSON PATH
            ),
            NULL, NULL
        FROM deleted d;
    END
END;
GO

PRINT 'Módulo de Recursos Humanos creado exitosamente en MrLee_DB (CORREGIDO)';

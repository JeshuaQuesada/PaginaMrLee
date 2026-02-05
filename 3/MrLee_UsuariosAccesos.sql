-- =====================================================================
--  Módulo de Usuarios y Accesos - Mr Lee (CORREGIDO)
--  SQL Server Management Studio
--  Amplía y mejora la base de datos MrLee_DB existente
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Ampliación de Tablas Existentes
-- =====================================================================

-- Ampliar tabla Usuarios con campos adicionales (solo si no existen ya)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Usuarios') AND name = 'Puesto')
BEGIN
    ALTER TABLE Usuarios 
    ADD 
        Puesto NVARCHAR(200) NULL,
        Telefono NVARCHAR(20) NULL,
        Bloqueado BIT DEFAULT 0,
        FechaBloqueo DATETIME NULL,
        IntentosFallidos INT DEFAULT 0,
        FechaUltimoLogin DATETIME NULL,
        FechaUltimoIntentoFallido DATETIME NULL,
        Eliminado BIT DEFAULT 0,
        FechaEliminacion DATETIME NULL,
        IdUsuarioEliminacion INT NULL;
    
    PRINT 'Tabla Usuarios ampliada con campos adicionales';
END;
GO

-- Ampliar tabla Roles con descripción extendida (solo si no existen ya)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Roles') AND name = 'NivelAcceso')
BEGIN
    ALTER TABLE Roles 
    ADD 
        NivelAcceso INT DEFAULT 0, -- 0=Básico, 1=Intermedio, 2=Avanzado, 3=Administrador
        FechaCreacion DATETIME DEFAULT GETDATE(),
        FechaUltimaModificacion DATETIME NULL;
    
    PRINT 'Tabla Roles ampliada con campos adicionales';
END;
GO

-- =====================================================================
-- Nuevas Tablas del Sistema de Accesos
-- =====================================================================

-- Catálogo de Permisos del Sistema
CREATE TABLE Permisos (
    IdPermiso INT IDENTITY(1,1) PRIMARY KEY,
    NombrePermiso NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(500),
    Modulo NVARCHAR(50) NOT NULL,
    Accion NVARCHAR(50) NOT NULL,
    Activo BIT DEFAULT 1,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Relación entre Roles y Permisos (muchos a muchos)
CREATE TABLE RolesPermisos (
    IdRolPermiso INT IDENTITY(1,1) PRIMARY KEY,
    IdRol INT NOT NULL,
    IdPermiso INT NOT NULL,
    Concedido BIT DEFAULT 1,
    FechaAsignacion DATETIME DEFAULT GETDATE(),
    IdUsuarioAsignacion INT NOT NULL,
    
    CONSTRAINT FK_RolesPermisos_Roles FOREIGN KEY (IdRol) REFERENCES Roles(IdRol),
    CONSTRAINT FK_RolesPermisos_Permisos FOREIGN KEY (IdPermiso) REFERENCES Permisos(IdPermiso),
    CONSTRAINT FK_RolesPermisos_Usuario FOREIGN KEY (IdUsuarioAsignacion) REFERENCES Usuarios(IdUsuario),
    
    CONSTRAINT UQ_RolesPermisos UNIQUE (IdRol, IdPermiso)
);
GO

-- Control de Sesiones de Usuario
CREATE TABLE Sesiones (
    IdSesion INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    TokenSesion NVARCHAR(255) NOT NULL UNIQUE,
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    FechaInicio DATETIME DEFAULT GETDATE(),
    FechaUltimaActividad DATETIME DEFAULT GETDATE(),
    FechaCierre DATETIME NULL,
    Activa BIT DEFAULT 1,
    
    CONSTRAINT FK_Sesiones_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Registro de Intentos de Login
CREATE TABLE IntentosLogin (
    IdIntento INT IDENTITY(1,1) PRIMARY KEY,
    CorreoElectronico NVARCHAR(150) NOT NULL,
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    FechaIntento DATETIME DEFAULT GETDATE(),
    Exitoso BIT DEFAULT 0,
    MotivoFallo NVARCHAR(200) NULL,
    IdUsuario INT NULL,
    
    CONSTRAINT FK_IntentosLogin_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Bitácora de Auditoría del Sistema
CREATE TABLE BitacoraAuditoria (
    IdBitacora INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    Accion NVARCHAR(100) NOT NULL,
    Modulo NVARCHAR(50) NOT NULL,
    EntidadAfectada NVARCHAR(100) NOT NULL,
    IdEntidadAfectada INT NULL,
    ValoresAnteriores NVARCHAR(MAX) NULL,
    ValoresNuevos NVARCHAR(MAX) NULL,
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    FechaAccion DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_BitacoraAuditoria_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Restablecimiento de Contraseñas
CREATE TABLE RestablecimientoContrasena (
    IdRestablecimiento INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    TokenRestablecimiento NVARCHAR(255) NOT NULL UNIQUE,
    FechaSolicitud DATETIME DEFAULT GETDATE(),
    FechaExpiracion DATETIME NOT NULL,
    FechaUso DATETIME NULL,
    Usado BIT DEFAULT 0,
    DireccionIP NVARCHAR(50) NULL,
    ForzadoPorAdmin BIT DEFAULT 0,
    IdUsuarioAdmin INT NULL,
    
    CONSTRAINT FK_RestablecimientoContrasena_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_RestablecimientoContrasena_Admin FOREIGN KEY (IdUsuarioAdmin) REFERENCES Usuarios(IdUsuario)
);
GO

-- =====================================================================
-- Índices para optimización
-- =====================================================================

CREATE INDEX IX_Usuarios_Correo ON Usuarios(CorreoElectronico);
CREATE INDEX IX_Usuarios_Activo ON Usuarios(Activo);
CREATE INDEX IX_Usuarios_Bloqueado ON Usuarios(Bloqueado);
CREATE INDEX IX_Usuarios_Eliminado ON Usuarios(Eliminado);
CREATE INDEX IX_Usuarios_FechaUltimoLogin ON Usuarios(FechaUltimoLogin);

CREATE INDEX IX_Sesiones_Usuario ON Sesiones(IdUsuario);
CREATE INDEX IX_Sesiones_Token ON Sesiones(TokenSesion);
CREATE INDEX IX_Sesiones_Activa ON Sesiones(Activa);
CREATE INDEX IX_Sesiones_UltimaActividad ON Sesiones(FechaUltimaActividad);

CREATE INDEX IX_IntentosLogin_Correo ON IntentosLogin(CorreoElectronico);
CREATE INDEX IX_IntentosLogin_Fecha ON IntentosLogin(FechaIntento);
CREATE INDEX IX_IntentosLogin_Exitoso ON IntentosLogin(Exitoso);

CREATE INDEX IX_BitacoraAuditoria_Usuario ON BitacoraAuditoria(IdUsuario);
CREATE INDEX IX_BitacoraAuditoria_Fecha ON BitacoraAuditoria(FechaAccion);
CREATE INDEX IX_BitacoraAuditoria_Modulo ON BitacoraAuditoria(Modulo);
CREATE INDEX IX_BitacoraAuditoria_Accion ON BitacoraAuditoria(Accion);

CREATE INDEX IX_RestablecimientoContrasena_Usuario ON RestablecimientoContrasena(IdUsuario);
CREATE INDEX IX_RestablecimientoContrasena_Token ON RestablecimientoContrasena(TokenRestablecimiento);
CREATE INDEX IX_RestablecimientoContrasena_Expiracion ON RestablecimientoContrasena(FechaExpiracion);
GO

-- =====================================================================
-- Triggers para Auditoría Automática
-- =====================================================================

-- Trigger para auditoría de cambios en Usuarios
CREATE TRIGGER TR_Usuarios_Auditoria
ON Usuarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Para INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO BitacoraAuditoria (
            IdUsuario, Accion, Modulo, EntidadAfectada, IdEntidadAfectada,
            ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdUsuario, 'INSERT', 'Usuarios', 'Usuarios', i.IdUsuario,
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdUsuario = i.IdUsuario
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i;
    END
    
    -- Para UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO BitacoraAuditoria (
            IdUsuario, Accion, Modulo, EntidadAfectada, IdEntidadAfectada,
            ValoresAnteriores, ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdUsuario, 'UPDATE', 'Usuarios', 'Usuarios', i.IdUsuario,
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdUsuario = i.IdUsuario
                FOR JSON PATH
            ),
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdUsuario = i.IdUsuario
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i
        INNER JOIN deleted d ON i.IdUsuario = d.IdUsuario;
    END
    
    -- Para DELETE (baja lógica)
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO BitacoraAuditoria (
            IdUsuario, Accion, Modulo, EntidadAfectada, IdEntidadAfectada,
            ValoresAnteriores, DireccionIP, Navegador
        )
        SELECT 
            d.IdUsuario, 'DELETE', 'Usuarios', 'Usuarios', d.IdUsuario,
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdUsuario = d.IdUsuario
                FOR JSON PATH
            ),
            NULL, NULL
        FROM deleted d;
    END
END;
GO

-- Trigger para registrar intentos de login
CREATE TRIGGER TR_Usuarios_RegistrarIntentoLogin
ON Usuarios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si se actualizó IntentosFallidos o Bloqueado
    IF UPDATE(IntentosFallidos) OR UPDATE(Bloqueado)
    BEGIN
        INSERT INTO IntentosLogin (
            CorreoElectronico, DireccionIP, Navegador, FechaIntento, 
            Exitoso, MotivoFallo, IdUsuario
        )
        SELECT 
            i.CorreoElectronico, NULL, NULL, GETDATE(),
            CASE WHEN i.Bloqueado = 1 THEN 0 ELSE 1 END,
            CASE 
                WHEN i.Bloqueado = 1 AND d.Bloqueado = 0 THEN 'Cuenta bloqueada por intentos fallidos'
                WHEN i.IntentosFallidos > d.IntentosFallidos THEN 'Intento de login fallido'
                ELSE 'Login exitoso'
            END,
            i.IdUsuario
        FROM inserted i
        INNER JOIN deleted d ON i.IdUsuario = d.IdUsuario
        WHERE (i.IntentosFallidos <> d.IntentosFallidos OR i.Bloqueado <> d.Bloqueado);
    END
END;
GO

-- =====================================================================
-- Procedimientos Almacenados
-- =====================================================================

-- Procedimiento para validar login
CREATE PROCEDURE sp_ValidarLogin
    @Correo NVARCHAR(150),
    @Contrasena NVARCHAR(255),
    @DireccionIP NVARCHAR(50) = NULL,
    @Navegador NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdUsuario INT;
    DECLARE @ContrasenaAlmacenada NVARCHAR(255);
    DECLARE @Activo BIT;
    DECLARE @Bloqueado BIT;
    DECLARE @IntentosFallidos INT;
    DECLARE @LoginExitoso BIT = 0;
    
    -- Buscar usuario
    SELECT 
        @IdUsuario = IdUsuario,
        @ContrasenaAlmacenada = Contrasena,
        @Activo = Activo,
        @Bloqueado = Bloqueado,
        @IntentosFallidos = IntentosFallidos
    FROM Usuarios 
    WHERE CorreoElectronico = @Correo AND Eliminado = 0;
    
    -- Registrar intento
    INSERT INTO IntentosLogin (CorreoElectronico, DireccionIP, Navegador, FechaIntento, Exitoso, IdUsuario)
    VALUES (@Correo, @DireccionIP, @Navegador, GETDATE(), 0, @IdUsuario);
    
    -- Validaciones
    IF @IdUsuario IS NULL
    BEGIN
        -- Usuario no existe
        UPDATE IntentosLogin
        SET MotivoFallo = 'Usuario no existe'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Usuario o contraseña incorrectos' as Mensaje;
        RETURN;
    END
    
    IF @Activo = 0
    BEGIN
        -- Usuario inactivo
        UPDATE IntentosLogin
        SET MotivoFallo = 'Usuario inactivo'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Usuario inactivo' as Mensaje;
        RETURN;
    END
    
    IF @Bloqueado = 1
    BEGIN
        -- Usuario bloqueado
        UPDATE IntentosLogin
        SET MotivoFallo = 'Cuenta bloqueada'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Cuenta bloqueada. Contacte al administrador' as Mensaje;
        RETURN;
    END
    
    -- Validar contraseña (en aplicación real se usaría hash)
    IF @ContrasenaAlmacenada = @Contrasena
    BEGIN
        -- Login exitoso
        SET @LoginExitoso = 1;
        
        -- Actualizar último login y resetear intentos fallidos
        UPDATE Usuarios
        SET FechaUltimoLogin = GETDATE(),
            IntentosFallidos = 0,
            Bloqueado = 0
        WHERE IdUsuario = @IdUsuario;
        
        -- Actualizar intento como exitoso
        UPDATE IntentosLogin
        SET Exitoso = 1,
            MotivoFallo = NULL
        WHERE IdIntento = SCOPE_IDENTITY();
        
        -- Registrar en bitácora
        INSERT INTO BitacoraAuditoria (
            IdUsuario, Accion, Modulo, EntidadAfectada, IdEntidadAfectada,
            DireccionIP, Navegador
        )
        VALUES (@IdUsuario, 'LOGIN', 'Usuarios', 'Usuarios', @IdUsuario, @DireccionIP, @Navegador);
        
        SELECT 1 as LoginExitoso, 'Login exitoso' as Mensaje, @IdUsuario as IdUsuario;
    END
    ELSE
    BEGIN
        -- Contraseña incorrecta
        SET @IntentosFallidos = @IntentosFallidos + 1;
        
        -- Actualizar intentos fallidos
        UPDATE Usuarios
        SET IntentosFallidos = @IntentosFallidos,
            FechaUltimoIntentoFallido = GETDATE(),
            Bloqueado = CASE WHEN @IntentosFallidos >= 5 THEN 1 ELSE 0 END
        WHERE IdUsuario = @IdUsuario;
        
        -- Actualizar motivo del fallo
        UPDATE IntentosLogin
        SET MotivoFallo = 'Contraseña incorrecta'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        DECLARE @Mensaje NVARCHAR(200);
        IF @IntentosFallidos >= 5
        BEGIN
            SET @Mensaje = 'Cuenta bloqueada por exceder intentos fallidos';
        END
        ELSE
        BEGIN
            SET @Mensaje = 'Usuario o contraseña incorrectos. Intentos restantes: ' + CAST(5 - @IntentosFallidos AS NVARCHAR(10));
        END
        
        SELECT 0 as LoginExitoso, @Mensaje as Mensaje;
    END
END;
GO

-- Procedimiento para crear usuario
CREATE PROCEDURE sp_CrearUsuario
    @NombreCompleto NVARCHAR(200),
    @Correo NVARCHAR(150),
    @Contrasena NVARCHAR(255),
    @Telefono NVARCHAR(20),
    @Puesto NVARCHAR(200),
    @IdRol INT,
    @IdUsuarioCrea INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar correo no exista
    IF EXISTS (SELECT 1 FROM Usuarios WHERE CorreoElectronico = @Correo AND Eliminado = 0)
    BEGIN
        SELECT 0 as Exito, 'El correo electrónico ya está registrado' as Mensaje;
        RETURN;
    END
    
    -- Validar formato de correo
    IF @Correo NOT LIKE '%_@__%.__%' OR CHARINDEX(' ', @Correo) > 0
    BEGIN
        SELECT 0 as Exito, 'El formato del correo electrónico no es válido' as Mensaje;
        RETURN;
    END
    
    -- Validar complejidad de contraseña (mínimo 8 caracteres, 1 mayúscula, 1 número)
    IF LEN(@Contrasena) < 8 OR @Contrasena NOT LIKE '%[A-Z]%' OR @Contrasena NOT LIKE '%[0-9]%'
    BEGIN
        SELECT 0 as Exito, 'La contraseña debe tener al menos 8 caracteres, 1 mayúscula y 1 número' as Mensaje;
        RETURN;
    END
    
    BEGIN TRANSACTION;
        -- Se omite IdUsuarioCreacion porque la tabla Usuarios no tiene ese campo
        INSERT INTO Usuarios (
            NombreCompleto, CorreoElectronico, Contrasena, Telefono, Puesto,
            IdRol
        )
        VALUES (
            @NombreCompleto, @Correo, @Contrasena, @Telefono, @Puesto,
            @IdRol
        );
        
        DECLARE @IdUsuarioNuevo INT = SCOPE_IDENTITY();
        
        -- Asignar permisos del rol (heredar permisos explícitos del rol al usuario)
        INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
        SELECT @IdRol, rp.IdPermiso, @IdUsuarioCrea
        FROM RolesPermisos rp
        WHERE rp.IdRol = @IdRol;
        
    COMMIT TRANSACTION;
    
    SELECT 1 as Exito, 'Usuario creado exitosamente' as Mensaje, @IdUsuarioNuevo as IdUsuario;
END;
GO

-- Procedimiento para consultar usuarios con filtros
CREATE PROCEDURE sp_ConsultarUsuarios
    @TextoBusqueda NVARCHAR(200) = NULL,
    @IdRol INT = NULL,
    @Activo BIT = NULL,
    @Pagina INT = 1,
    @TamanoPagina INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@Pagina - 1) * @TamanoPagina;
    
    SELECT 
        u.IdUsuario, u.NombreCompleto, u.CorreoElectronico, u.Telefono,
        u.Puesto, u.Activo, u.Bloqueado, u.FechaCreacion, u.FechaUltimoLogin,
        r.NombreRol,
        (SELECT COUNT(*) FROM IntentosLogin il WHERE il.IdUsuario = u.IdUsuario AND il.Exitoso = 1) as TotalLogins,
        (SELECT COUNT(*) FROM IntentosLogin il WHERE il.IdUsuario = u.IdUsuario AND il.Exitoso = 0 AND il.FechaIntento >= DATEADD(DAY, -30, GETDATE())) as IntentosFallidos30Dias
    FROM Usuarios u
    INNER JOIN Roles r ON u.IdRol = r.IdRol
    WHERE u.Eliminado = 0
    AND (@TextoBusqueda IS NULL OR u.NombreCompleto LIKE '%' + @TextoBusqueda + '%' OR u.CorreoElectronico LIKE '%' + @TextoBusqueda + '%')
    AND (@IdRol IS NULL OR u.IdRol = @IdRol)
    AND (@Activo IS NULL OR u.Activo = @Activo)
    ORDER BY u.FechaCreacion DESC
    OFFSET @Offset ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
    
    -- Total de registros para paginación
    SELECT COUNT(*) as TotalRegistros
    FROM Usuarios u
    WHERE u.Eliminado = 0
    AND (@TextoBusqueda IS NULL OR u.NombreCompleto LIKE '%' + @TextoBusqueda + '%' OR u.CorreoElectronico LIKE '%' + @TextoBusqueda + '%')
    AND (@IdRol IS NULL OR u.IdRol = @IdRol)
    AND (@Activo IS NULL OR u.Activo = @Activo);
END;
GO

PRINT 'Módulo de Usuarios y Accesos ampliado exitosamente en MrLee_DB (CORREGIDO)';

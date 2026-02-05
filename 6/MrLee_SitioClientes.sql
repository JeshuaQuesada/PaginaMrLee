-- =====================================================================
--  Módulo de Sitio para Clientes - Mr Lee (CORREGIDO)
--  SQL Server Management Studio
--  Integración con la base de datos MrLee_DB existente
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Ampliación de Tablas Existentes para Sitio Web
-- =====================================================================

-- Ampliar tabla Clientes con datos adicionales para el sitio web
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Clientes') AND name = 'Password')
BEGIN
    ALTER TABLE Clientes 
    ADD 
        -- Datos de acceso web
        Password NVARCHAR(255) NULL, -- Encriptada
        Email NVARCHAR(150) NULL, -- Correo para acceso web
        TipoIdentificacion NVARCHAR(20) NULL, -- CEDULA, DIMEX, PASAPORTE
        FechaVerificacionEmail DATETIME NULL,
        TokenVerificacion NVARCHAR(255) NULL,
        FechaExpiracionToken DATETIME NULL,
        
        -- Estado y control web
        EstadoWeb NVARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, ACTIVO, INACTIVO, BLOQUEADO
        FechaUltimoLogin DATETIME NULL,
        IntentosFallidos INT DEFAULT 0,
        -- Campo adicional para registrar la fecha del último intento fallido (corrección)
        FechaUltimoIntentoFallido DATETIME NULL,
        FechaBloqueo DATETIME NULL,
        
        -- Preferencias
        AceptaTerminos BIT DEFAULT 0,
        FechaAceptaTerminos DATETIME NULL,
        FechaDesactivacion DATETIME NULL,
        MotivoDesactivacion NVARCHAR(500) NULL,
        
        -- Auditoría web
        IPRegistro NVARCHAR(50) NULL,
        NavegadorRegistro NVARCHAR(200) NULL,
        FechaRegistroWeb DATETIME NULL;
    
    PRINT 'Tabla Clientes ampliada con campos para sitio web';
END;
GO

-- =====================================================================
-- Tablas del Sistema de Sitio Web
-- =====================================================================

-- Sesiones Web de Clientes
CREATE TABLE SesionesWeb (
    IdSesionWeb INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    TokenSesion NVARCHAR(255) NOT NULL UNIQUE,
    
    -- Información de dispositivo
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    SistemaOperativo NVARCHAR(100) NULL,
    Dispositivo NVARCHAR(100) NULL,
    
    -- Control de sesión
    FechaInicio DATETIME DEFAULT GETDATE(),
    FechaUltimaActividad DATETIME DEFAULT GETDATE(),
    FechaExpiracion DATETIME NOT NULL,
    RecordarDispositivo BIT DEFAULT 0,
    Activa BIT DEFAULT 1,
    FechaCierre DATETIME NULL,
    
    CONSTRAINT FK_SesionesWeb_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT CHK_SesionesWeb_Fechas_Validas CHECK (FechaExpiracion > FechaInicio)
);
GO

-- Tokens de Verificación y Recuperación
CREATE TABLE TokensVerificacion (
    IdToken INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    TipoToken NVARCHAR(50) NOT NULL,
    Token NVARCHAR(255) NOT NULL UNIQUE,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaExpiracion DATETIME NOT NULL,
    FechaUso DATETIME NULL,
    Usado BIT DEFAULT 0,
    DireccionIP NVARCHAR(50) NULL,
    
    CONSTRAINT FK_TokensVerificacion_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT CHK_TokensVerificacion_Tipo_Valido CHECK (TipoToken IN ('VERIFICACION_EMAIL', 'RECUPERACION_PASSWORD', 'REACTIVACION_CUENTA'))
);
GO

-- Configuración de Notificaciones de Clientes
CREATE TABLE ConfiguracionNotificaciones (
    IdConfiguracion INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    
    -- Canales de notificación
    NotificacionEmail BIT DEFAULT 1,
    NotificacionSMS BIT DEFAULT 0,
    NotificacionWhatsApp BIT DEFAULT 0,
    
    -- Verificación de canales
    EmailVerificado BIT DEFAULT 0,
    TelefonoVerificado BIT DEFAULT 0,
    FechaVerificacionEmail DATETIME NULL,
    FechaVerificacionTelefono DATETIME NULL,
    
    -- Horario de silencio
    HorarioSilencio BIT DEFAULT 0,
    HoraSilencioInicio TIME NULL,
    HoraSilencioFin TIME NULL,
    
    -- Preferencias específicas
    NotificarEstadoPedido BIT DEFAULT 1,
    NotificarPromociones BIT DEFAULT 0,
    NotificarNuevosProductos BIT DEFAULT 0,
    
    -- Auditoría
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NULL,
    
    CONSTRAINT FK_ConfiguracionNotificaciones_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT CHK_ConfiguracionNotificaciones_Horas_Validas CHECK (
        (HoraSilencioInicio IS NULL AND HoraSilencioFin IS NULL) OR
        (HoraSilencioInicio IS NOT NULL AND HoraSilencioFin IS NOT NULL)
    )
);
GO

-- Intentos de Login de Clientes (Control de seguridad)
CREATE TABLE IntentosLoginClientes (
    IdIntento INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(150) NOT NULL,
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    FechaIntento DATETIME DEFAULT GETDATE(),
    Exitoso BIT DEFAULT 0,
    MotivoFallo NVARCHAR(200) NULL,
    IdCliente INT NULL,
    
    CONSTRAINT FK_IntentosLoginClientes_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente)
);
GO

-- Dispositivos Confiados (Remember Me)
CREATE TABLE DispositivosConfiados (
    IdDispositivo INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NOT NULL,
    IdentificadorDispositivo NVARCHAR(255) NOT NULL,
    NombreDispositivo NVARCHAR(200) NULL,
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    
    -- Control
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaUltimoUso DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1,
    FechaRevocacion DATETIME NULL,
    
    CONSTRAINT FK_DispositivosConfiados_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente),
    CONSTRAINT UQ_DispositivosConfiados_ClienteDispositivo UNIQUE (IdCliente, IdentificadorDispositivo)
);
GO

-- Auditoría Específica del Sitio Web
CREATE TABLE AuditoriaWeb (
    IdAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente INT NULL,
    Accion NVARCHAR(50) NOT NULL,
    Modulo NVARCHAR(50) NOT NULL DEFAULT 'SITIO_WEB',
    DescripcionAccion NVARCHAR(500) NOT NULL,
    
    -- Datos anteriores y nuevos (JSON)
    ValoresAnteriores NVARCHAR(MAX) NULL,
    ValoresNuevos NVARCHAR(MAX) NULL,
    
    -- Contexto web
    DireccionIP NVARCHAR(50) NULL,
    Navegador NVARCHAR(200) NULL,
    SistemaOperativo NVARCHAR(100) NULL,
    
    -- Control
    FechaAccion DATETIME DEFAULT GETDATE(),
    SesionId NVARCHAR(255) NULL,
    
    CONSTRAINT FK_AuditoriaWeb_Cliente FOREIGN KEY (IdCliente) REFERENCES Clientes(IdCliente)
);
GO

-- =====================================================================
-- Índices para optimización
-- =====================================================================

CREATE INDEX IX_Clientes_Email ON Clientes(Email);
CREATE INDEX IX_Clientes_EstadoWeb ON Clientes(EstadoWeb);
CREATE INDEX IX_Clientes_TokenVerificacion ON Clientes(TokenVerificacion);
CREATE INDEX IX_Clientes_FechaUltimoLogin ON Clientes(FechaUltimoLogin);
CREATE INDEX IX_Clientes_Bloqueo ON Clientes(FechaBloqueo);

CREATE INDEX IX_SesionesWeb_Cliente ON SesionesWeb(IdCliente);
CREATE INDEX IX_SesionesWeb_Token ON SesionesWeb(TokenSesion);
CREATE INDEX IX_SesionesWeb_Activa ON SesionesWeb(Activa);
CREATE INDEX IX_SesionesWeb_Expiracion ON SesionesWeb(FechaExpiracion);
CREATE INDEX IX_SesionesWeb_IP ON SesionesWeb(DireccionIP);

CREATE INDEX IX_TokensVerificacion_Cliente ON TokensVerificacion(IdCliente);
CREATE INDEX IX_TokensVerificacion_Token ON TokensVerificacion(Token);
CREATE INDEX IX_TokensVerificacion_Tipo ON TokensVerificacion(TipoToken);
CREATE INDEX IX_TokensVerificacion_Expiracion ON TokensVerificacion(FechaExpiracion);

CREATE INDEX IX_ConfiguracionNotificaciones_Cliente ON ConfiguracionNotificaciones(IdCliente);

CREATE INDEX IX_IntentosLoginClientes_Email ON IntentosLoginClientes(Email);
CREATE INDEX IX_IntentosLoginClientes_Fecha ON IntentosLoginClientes(FechaIntento);
CREATE INDEX IX_IntentosLoginClientes_IP ON IntentosLoginClientes(DireccionIP);
CREATE INDEX IX_IntentosLoginClientes_Exitoso ON IntentosLoginClientes(Exitoso);

CREATE INDEX IX_DispositivosConfiados_Cliente ON DispositivosConfiados(IdCliente);
CREATE INDEX IX_DispositivosConfiados_Identificador ON DispositivosConfiados(IdentificadorDispositivo);
CREATE INDEX IX_DispositivosConfiados_Activo ON DispositivosConfiados(Activo);

CREATE INDEX IX_AuditoriaWeb_Cliente ON AuditoriaWeb(IdCliente);
CREATE INDEX IX_AuditoriaWeb_Fecha ON AuditoriaWeb(FechaAccion);
CREATE INDEX IX_AuditoriaWeb_Accion ON AuditoriaWeb(Accion);
CREATE INDEX IX_AuditoriaWeb_IP ON AuditoriaWeb(DireccionIP);

GO

-- =====================================================================
-- Triggers para Auditoría y Validaciones
-- =====================================================================

-- Trigger para auditoría de cambios en clientes web
CREATE TRIGGER TR_ClientesWeb_Auditoria
ON Clientes
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Para INSERT (nuevos registros web)
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaWeb (
            IdCliente, Accion, Modulo, DescripcionAccion,
            ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdCliente, 'REGISTRO', 'SITIO_WEB', 
            'Registro de cliente en sitio web',
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdCliente = i.IdCliente
                FOR JSON PATH
            ),
            i.IPRegistro, i.NavegadorRegistro
        FROM inserted i
        WHERE i.FechaRegistroWeb IS NOT NULL;
    END
    
    -- Para UPDATE (modificaciones web)
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditoriaWeb (
            IdCliente, Accion, Modulo, DescripcionAccion,
            ValoresAnteriores, ValoresNuevos, DireccionIP, Navegador
        )
        SELECT 
            i.IdCliente, 'ACTUALIZAR_PERFIL', 'SITIO_WEB', 
            'Actualización de perfil de cliente',
            (
                SELECT *
                FROM deleted d2
                WHERE d2.IdCliente = i.IdCliente
                FOR JSON PATH
            ),
            (
                SELECT *
                FROM inserted i2
                WHERE i2.IdCliente = i.IdCliente
                FOR JSON PATH
            ),
            NULL, NULL
        FROM inserted i
        INNER JOIN deleted d ON i.IdCliente = d.IdCliente
        WHERE i.FechaRegistroWeb IS NOT NULL OR d.FechaRegistroWeb IS NOT NULL;
    END
END;
GO

-- Trigger para registrar intentos de login de clientes
CREATE TRIGGER TR_ClientesWeb_RegistrarIntentoLogin
ON Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si se actualizó IntentosFallidos o FechaBloqueo o FechaUltimoLogin
    IF UPDATE(IntentosFallidos) OR UPDATE(FechaBloqueo) OR UPDATE(FechaUltimoLogin)
    BEGIN
        INSERT INTO IntentosLoginClientes (
            Email, DireccionIP, Navegador, FechaIntento, 
            Exitoso, MotivoFallo, IdCliente
        )
        SELECT 
            i.Email, NULL, NULL, GETDATE(),
            CASE 
                WHEN i.FechaUltimoLogin IS NOT NULL AND d.FechaUltimoLogin IS NULL THEN 1
                WHEN i.FechaBloqueo IS NOT NULL AND d.FechaBloqueo IS NULL THEN 0
                WHEN i.IntentosFallidos > d.IntentosFallidos THEN 0
                ELSE 1
            END,
            CASE 
                WHEN i.FechaBloqueo IS NOT NULL AND d.FechaBloqueo IS NULL THEN 'Cuenta bloqueada por intentos fallidos'
                WHEN i.IntentosFallidos > d.IntentosFallidos THEN 'Intento de login fallido'
                WHEN i.FechaUltimoLogin IS NOT NULL AND d.FechaUltimoLogin IS NULL THEN 'Login exitoso'
                ELSE 'Actualización de estado'
            END,
            i.IdCliente
        FROM inserted i
        INNER JOIN deleted d ON i.IdCliente = d.IdCliente
        WHERE (i.IntentosFallidos <> d.IntentosFallidos OR i.FechaBloqueo <> d.FechaBloqueo OR i.FechaUltimoLogin <> d.FechaUltimoLogin)
        AND i.Email IS NOT NULL;
    END
END;
GO

-- Trigger para limpiar sesiones expiradas
CREATE TRIGGER TR_SesionesWeb_LimpiarExpiradas
ON SesionesWeb
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Marcar como inactivas las sesiones expiradas
    UPDATE SesionesWeb
    SET Activa = 0,
        FechaCierre = GETDATE()
    WHERE Activa = 1 
    AND FechaExpiracion < GETDATE();
END;
GO

-- =====================================================================
-- Procedimientos Almacenados
-- =====================================================================

-- Procedimiento para registrar cliente web
CREATE PROCEDURE sp_RegistrarClienteWeb
    @Nombre NVARCHAR(200),
    @Apellido NVARCHAR(200),
    @Email NVARCHAR(150),
    @Password NVARCHAR(255),
    @Telefono NVARCHAR(20),
    @TipoIdentificacion NVARCHAR(20),
    @Identificacion NVARCHAR(20),
    @Direccion NVARCHAR(300),
    @AceptaTerminos BIT,
    @IPRegistro NVARCHAR(50) = NULL,
    @NavegadorRegistro NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar formato de email
    IF @Email NOT LIKE '%_@__%.__%' OR CHARINDEX(' ', @Email) > 0
    BEGIN
        SELECT 0 as Exito, 'El formato del correo electrónico no es válido' as Mensaje;
        RETURN;
    END
    
    -- Validar política de contraseña (mínimo 8 caracteres, 1 mayúscula, 1 número)
    IF LEN(@Password) < 8 OR @Password NOT LIKE '%[A-Z]%' OR @Password NOT LIKE '%[0-9]%'
    BEGIN
        SELECT 0 as Exito, 'La contraseña debe tener al menos 8 caracteres, 1 mayúscula y 1 número' as Mensaje;
        RETURN;
    END
    
    -- Validar que acepte términos
    IF @AceptaTerminos = 0
    BEGIN
        SELECT 0 as Exito, 'Debe aceptar los términos y condiciones' as Mensaje;
        RETURN;
    END
    
    -- Validar tipo de identificación
    IF @TipoIdentificacion NOT IN ('CEDULA', 'DIMEX', 'PASAPORTE')
    BEGIN
        SELECT 0 as Exito, 'El tipo de identificación no es válido' as Mensaje;
        RETURN;
    END
    
    -- Verificar si el email ya existe
    IF EXISTS (SELECT 1 FROM Clientes WHERE Email = @Email)
    BEGIN
        SELECT 0 as Exito, 'El correo electrónico ya está registrado' as Mensaje;
        RETURN;
    END
    
    -- Generar token de verificación
    DECLARE @TokenVerificacion NVARCHAR(255) = 'VER_' + CONVERT(NVARCHAR(50), NEWID());
    DECLARE @FechaExpiracionToken DATETIME = DATEADD(HOUR, 24, GETDATE());
    
    BEGIN TRANSACTION;
        -- Insertar cliente
        INSERT INTO Clientes (
            NombreCompleto, Telefono, CorreoElectronico, Direccion,
            Email, Password, TipoIdentificacion, EstadoWeb,
            TokenVerificacion, FechaExpiracionToken, AceptaTerminos,
            FechaAceptaTerminos, IPRegistro, NavegadorRegistro, FechaRegistroWeb,
            Activo
        )
        VALUES (
            @Nombre + ' ' + @Apellido, @Telefono, @Email, @Direccion,
            @Email, @Password, @TipoIdentificacion, 'PENDIENTE',
            @TokenVerificacion, @FechaExpiracionToken, @AceptaTerminos,
            GETDATE(), @IPRegistro, @NavegadorRegistro, GETDATE(),
            1
        );
        
        DECLARE @IdCliente INT = SCOPE_IDENTITY();
        
        -- Insertar configuración de notificaciones por defecto
        INSERT INTO ConfiguracionNotificaciones (IdCliente)
        VALUES (@IdCliente);
        
        -- Insertar token de verificación
        INSERT INTO TokensVerificacion (
            IdCliente, TipoToken, Token, FechaExpiracion, DireccionIP
        )
        VALUES (
            @IdCliente, 'VERIFICACION_EMAIL', @TokenVerificacion, @FechaExpiracionToken, @IPRegistro
        );
        
    COMMIT TRANSACTION;
    
    SELECT 1 as Exito, 'Cliente registrado exitosamente. Por favor verifique su correo electrónico.' as Mensaje, @IdCliente as IdCliente, @TokenVerificacion as TokenVerificacion;
END;
GO

-- Procedimiento para login de cliente web
CREATE PROCEDURE sp_LoginClienteWeb
    @Email NVARCHAR(150),
    @Password NVARCHAR(255),
    @RecordarDispositivo BIT = 0,
    @DireccionIP NVARCHAR(50) = NULL,
    @Navegador NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdCliente INT;
    DECLARE @PasswordAlmacenada NVARCHAR(255);
    DECLARE @EstadoWeb NVARCHAR(20);
    DECLARE @Bloqueado BIT;
    DECLARE @IntentosFallidos INT;
    DECLARE @FechaBloqueo DATETIME;
    DECLARE @LoginExitoso BIT = 0;
    
    -- Buscar cliente
    SELECT 
        @IdCliente = IdCliente,
        @PasswordAlmacenada = Password,
        @EstadoWeb = EstadoWeb,
        @Bloqueado = CASE 
            WHEN FechaBloqueo IS NOT NULL AND FechaBloqueo > DATEADD(HOUR, -1, GETDATE()) THEN 1 
            ELSE 0 
        END,
        @IntentosFallidos = IntentosFallidos,
        @FechaBloqueo = FechaBloqueo
    FROM Clientes 
    WHERE Email = @Email AND Activo = 1;
    
    -- Registrar intento
    INSERT INTO IntentosLoginClientes (Email, DireccionIP, Navegador, FechaIntento, Exitoso, IdCliente)
    VALUES (@Email, @DireccionIP, @Navegador, GETDATE(), 0, @IdCliente);
    
    -- Validaciones
    IF @IdCliente IS NULL
    BEGIN
        -- Cliente no existe
        UPDATE IntentosLoginClientes
        SET MotivoFallo = 'Cuenta no encontrada'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Correo o contraseña incorrectos' as Mensaje;
        RETURN;
    END
    
    IF @EstadoWeb = 'BLOQUEADO' OR @Bloqueado = 1
    BEGIN
        -- Cliente bloqueado
        UPDATE IntentosLoginClientes
        SET MotivoFallo = 'Cuenta bloqueada'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Cuenta bloqueada temporalmente. Intente más tarde.' as Mensaje;
        RETURN;
    END
    
    IF @EstadoWeb = 'PENDIENTE'
    BEGIN
        -- Cuenta no verificada
        UPDATE IntentosLoginClientes
        SET MotivoFallo = 'Cuenta no verificada'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Debe verificar su correo electrónico antes de iniciar sesión.' as Mensaje;
        RETURN;
    END
    
    IF @EstadoWeb = 'INACTIVO'
    BEGIN
        -- Cuenta inactiva
        UPDATE IntentosLoginClientes
        SET MotivoFallo = 'Cuenta inactiva'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        SELECT 0 as LoginExitoso, 'Cuenta desactivada. Contacte al soporte.' as Mensaje;
        RETURN;
    END
    
    -- Validar contraseña (en aplicación real se usaría hash)
    IF @PasswordAlmacenada = @Password
    BEGIN
        -- Login exitoso
        SET @LoginExitoso = 1;
        
        -- Actualizar último login y resetear intentos fallidos
        UPDATE Clientes
        SET FechaUltimoLogin = GETDATE(),
            IntentosFallidos = 0,
            FechaBloqueo = NULL
        WHERE IdCliente = @IdCliente;
        
        -- Actualizar intento como exitoso
        UPDATE IntentosLoginClientes
        SET Exitoso = 1,
            MotivoFallo = NULL
        WHERE IdIntento = SCOPE_IDENTITY();
        
        -- Crear sesión web
        DECLARE @TokenSesion NVARCHAR(255) = 'SES_' + CONVERT(NVARCHAR(50), NEWID());
        DECLARE @FechaExpiracionSesion DATETIME = 
            CASE 
                WHEN @RecordarDispositivo = 1 THEN DATEADD(DAY, 30, GETDATE())
                ELSE DATEADD(HOUR, 2, GETDATE())
            END;
        
        INSERT INTO SesionesWeb (
            IdCliente, TokenSesion, DireccionIP, Navegador,
            FechaExpiracion, RecordarDispositivo
        )
        VALUES (
            @IdCliente, @TokenSesion, @DireccionIP, @Navegador,
            @FechaExpiracionSesion, @RecordarDispositivo
        );
        
        -- Registrar en auditoría
        INSERT INTO AuditoriaWeb (
            IdCliente, Accion, Modulo, DescripcionAccion,
            DireccionIP, Navegador, SesionId
        )
        VALUES (
            @IdCliente, 'LOGIN', 'SITIO_WEB', 'Inicio de sesión exitoso',
            @DireccionIP, @Navegador, @TokenSesion
        );
        
        SELECT 1 as LoginExitoso, 'Login exitoso' as Mensaje, @IdCliente as IdCliente, @TokenSesion as TokenSesion;
    END
    ELSE
    BEGIN
        -- Contraseña incorrecta
        SET @IntentosFallidos = @IntentosFallidos + 1;
        
        -- Actualizar intentos fallidos
        UPDATE Clientes
        SET IntentosFallidos = @IntentosFallidos,
            FechaUltimoIntentoFallido = GETDATE(),
            FechaBloqueo = CASE 
                WHEN @IntentosFallidos >= 5 THEN GETDATE()
                ELSE NULL
            END
        WHERE IdCliente = @IdCliente;
        
        -- Actualizar motivo del fallo
        UPDATE IntentosLoginClientes
        SET MotivoFallo = 'Contraseña incorrecta'
        WHERE IdIntento = SCOPE_IDENTITY();
        
        DECLARE @Mensaje NVARCHAR(200);
        IF @IntentosFallidos >= 5
        BEGIN
            SET @Mensaje = 'Cuenta bloqueada por exceder intentos fallidos';
        END
        ELSE
        BEGIN
            SET @Mensaje = 'Correo o contraseña incorrectos. Intentos restantes: ' + CAST(5 - @IntentosFallidos AS NVARCHAR(10));
        END
        
        SELECT 0 as LoginExitoso, @Mensaje as Mensaje;
    END
END;
GO

-- Procedimiento para consultar pedidos del cliente
CREATE PROCEDURE sp_ConsultarPedidosCliente
    @IdCliente INT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @EstadoPedido NVARCHAR(50) = NULL,
    @Pagina INT = 1,
    @TamanoPagina INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@Pagina - 1) * @TamanoPagina;
    
    -- Validar que el cliente exista y esté activo
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE IdCliente = @IdCliente AND Activo = 1)
    BEGIN
        SELECT 0 as Exito, 'Cliente no encontrado o inactivo' as Mensaje;
        RETURN;
    END
    
    -- Query principal
    SELECT 
        p.IdPedido, p.NumeroSeguimiento, p.FechaCreacion, p.FechaPrometida,
        p.FechaEntregaReal, p.Observaciones, p.Anulado,
        e.NombreEstado as EstadoPedido,
        pr.NombrePrioridad as Prioridad,
        ISNULL(pd.TotalProductos, 0) as CantidadProductos,
        ISNULL(pd.TotalMonto, 0) as MontoTotal
    FROM Pedidos p
    INNER JOIN EstadosPedido e ON p.IdEstado = e.IdEstado
    INNER JOIN Prioridades pr ON p.IdPrioridad = pr.IdPrioridad
    LEFT JOIN (
        SELECT 
            IdPedido, 
            COUNT(*) as TotalProductos,
            SUM(Cantidad * PrecioUnitario) as TotalMonto
        FROM PedidoDetalles
        GROUP BY IdPedido
    ) pd ON p.IdPedido = pd.IdPedido
    WHERE p.IdCliente = @IdCliente
    AND (@FechaInicio IS NULL OR p.FechaCreacion >= @FechaInicio)
    AND (@FechaFin IS NULL OR p.FechaCreacion <= @FechaFin)
    AND (@EstadoPedido IS NULL OR e.NombreEstado = @EstadoPedido)
    ORDER BY p.FechaCreacion DESC
    OFFSET @Offset ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
    
    -- Total de registros para paginación
    SELECT COUNT(*) as TotalRegistros
    FROM Pedidos p
    INNER JOIN EstadosPedido e ON p.IdEstado = e.IdEstado
    WHERE p.IdCliente = @IdCliente
    AND (@FechaInicio IS NULL OR p.FechaCreacion >= @FechaInicio)
    AND (@FechaFin IS NULL OR p.FechaCreacion <= @FechaFin)
    AND (@EstadoPedido IS NULL OR e.NombreEstado = @EstadoPedido);
    
    SELECT 1 as Exito, 'Consulta ejecutada exitosamente' as Mensaje;
END;
GO

PRINT 'Módulo de Sitio para Clientes creado exitosamente en MrLee_DB (CORREGIDO)';
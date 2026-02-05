-- =====================================================================
-- Script de Integración y Pruebas para Módulo de Sitio para Clientes
-- Mr Lee - Integración completa con todos los módulos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Pruebas del Módulo de Sitio para Clientes
-- =====================================================================

PRINT '=== PRUEBAS DEL MÓDULO DE SITIO PARA CLIENTES ===';

-- Prueba 1: Registrar nuevo cliente web
PRINT '=== PRUEBA 1: Registrar nuevo cliente web ===';
DECLARE @Resultado INT;
DECLARE @Mensaje NVARCHAR(500);
DECLARE @IdClienteWeb INT;
DECLARE @TokenVerificacion NVARCHAR(255);

EXEC @Resultado = sp_RegistrarClienteWeb
    @Nombre = 'Carlos',
    @Apellido = 'Ramírez',
    @Email = 'carlos.ramirez@email.com',
    @Password = 'Password123',
    @Telefono = '8888-7777',
    @TipoIdentificacion = 'CEDULA',
    @Identificacion = '155566777',
    @Direccion = 'Calle Ficticia #123, San José',
    @AceptaTerminos = 1,
    @IPRegistro = '192.168.1.100',
    @NavegadorRegistro = 'Chrome 120.0';

SELECT @IdClienteWeb = IdCliente, @TokenVerificacion = TokenVerificacion 
FROM (SELECT 1 as Exito, 'Cliente registrado exitosamente' as Mensaje, IdCliente, TokenVerificacion) as result
WHERE Exito = 1;

IF @Resultado = 1
    PRINT 'Cliente web registrado exitosamente';
ELSE
    PRINT 'Error al registrar cliente web';

-- Verificar cliente creado
SELECT TOP 1 IdCliente, NombreCompleto, Email, EstadoWeb, TokenVerificacion, FechaExpiracionToken 
FROM Clientes 
WHERE Email = 'carlos.ramirez@email.com';
GO

-- Prueba 2: Intentar registrar con email duplicado (debe fallar)
PRINT '=== PRUEBA 2: Email duplicado (debe fallar) ===';
EXEC sp_RegistrarClienteWeb
    @Nombre = 'Otro Carlos',
    @Apellido = 'Ramírez',
    @Email = 'carlos.ramirez@email.com', -- Mismo email
    @Password = 'Password123',
    @Telefono = '8888-9999',
    @TipoIdentificacion = 'CEDULA',
    @Identificacion = '188899999',
    @Direccion = 'Otra dirección',
    @AceptaTerminos = 1;
GO

-- Prueba 3: Intentar registrar con contraseña débil (debe fallar)
PRINT '=== PRUEBA 3: Contraseña débil (debe fallar) ===';
EXEC sp_RegistrarClienteWeb
    @Nombre = 'Ana',
    @Apellido = 'Gómez',
    @Email = 'ana.gomez@email.com',
    @Password = '123', -- Contraseña muy débil
    @Telefono = '8888-6666',
    @TipoIdentificacion = 'CEDULA',
    @Identificacion = '144455566',
    @Direccion = 'Dirección de Ana',
    @AceptaTerminos = 1;
GO

-- Prueba 4: Intentar registrar sin aceptar términos (debe fallar)
PRINT '=== PRUEBA 4: Sin aceptar términos (debe fallar) ===';
EXEC sp_RegistrarClienteWeb
    @Nombre = 'Luis',
    @Apellido = 'Mora',
    @Email = 'luis.mora@email.com',
    @Password = 'Password123',
    @Telefono = '8888-5555',
    @TipoIdentificacion = 'CEDULA',
    @Identificacion = '133344455',
    @Direccion = 'Dirección de Luis',
    @AceptaTerminos = 0; -- No acepta términos
GO

-- Prueba 5: Verificar email del cliente (simular verificación)
PRINT '=== PRUEBA 5: Verificar email del cliente ===';
DECLARE @IdClienteVerificar INT = (SELECT TOP 1 IdCliente FROM Clientes WHERE Email = 'carlos.ramirez@email.com');

IF @IdClienteVerificar IS NOT NULL
BEGIN
    UPDATE Clientes
    SET EstadoWeb = 'ACTIVO',
        FechaVerificacionEmail = GETDATE(),
        TokenVerificacion = NULL,
        FechaExpiracionToken = NULL
    WHERE IdCliente = @IdClienteVerificar;
    
    -- Marcar token como usado
    UPDATE TokensVerificacion
    SET Usado = 1, FechaUso = GETDATE()
    WHERE IdCliente = @IdClienteVerificar AND TipoToken = 'VERIFICACION_EMAIL';
    
    PRINT 'Email verificado exitosamente';
END;
GO

-- Prueba 6: Login exitoso de cliente web
PRINT '=== PRUEBA 6: Login exitoso de cliente web ===';
DECLARE @TokenSesion NVARCHAR(255);

EXEC sp_LoginClienteWeb
    @Email = 'carlos.ramirez@email.com',
    @Password = 'Password123',
    @RecordarDispositivo = 0,
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';

-- Verificar sesión creada
SELECT TOP 1 * FROM SesionesWeb WHERE IdCliente = (SELECT IdCliente FROM Clientes WHERE Email = 'carlos.ramirez@email.com') ORDER BY FechaInicio DESC;
GO

-- Prueba 7: Login con contraseña incorrecta
PRINT '=== PRUEBA 7: Login con contraseña incorrecta ===';
EXEC sp_LoginClienteWeb
    @Email = 'carlos.ramirez@email.com',
    @Password = 'contraseña_incorrecta',
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';
GO

-- Prueba 8: Simular bloqueo por intentos fallidos
PRINT '=== PRUEBA 8: Bloqueo por intentos fallidos ===';
DECLARE @Contador INT = 0;
WHILE @Contador < 5
BEGIN
    EXEC sp_LoginClienteWeb
        @Email = 'carlos.ramirez@email.com',
        @Password = 'contraseña_incorrecta',
        @DireccionIP = '192.168.1.100',
        @Navegador = 'Chrome 120.0';
    SET @Contador = @Contador + 1;
END

-- Verificar estado del cliente
SELECT Email, EstadoWeb, IntentosFallidos, FechaBloqueo 
FROM Clientes 
WHERE Email = 'carlos.ramirez@email.com';
GO

-- Prueba 9: Intentar login con cuenta bloqueada
PRINT '=== PRUEBA 9: Login con cuenta bloqueada ===';
EXEC sp_LoginClienteWeb
    @Email = 'carlos.ramirez@email.com',
    @Password = 'Password123', -- Contraseña correcta
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';
GO

-- Prueba 10: Reactivar cliente bloqueado
PRINT '=== PRUEBA 10: Reactivar cliente bloqueado ===';
UPDATE Clientes 
SET EstadoWeb = 'ACTIVO', 
    IntentosFallidos = 0, 
    FechaBloqueo = NULL
WHERE Email = 'carlos.ramirez@email.com';

-- Verificar reactivación
SELECT Email, EstadoWeb, IntentosFallidos, FechaBloqueo 
FROM Clientes 
WHERE Email = 'carlos.ramirez@email.com';
GO

-- Prueba 11: Consultar pedidos del cliente
PRINT '=== PRUEBA 11: Consultar pedidos del cliente ===';
DECLARE @IdClienteConsulta INT = (SELECT IdCliente FROM Clientes WHERE Email = 'carlos.ramirez@email.com');

EXEC sp_ConsultarPedidosCliente
    @IdCliente = @IdClienteConsulta,
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- Prueba 12: Consultar pedidos con filtros
PRINT '=== PRUEBA 12: Consultar pedidos con filtros ===';
EXEC sp_ConsultarPedidosCliente
    @IdCliente = @IdClienteConsulta,
    @FechaInicio = '2026-01-01',
    @FechaFin = '2026-01-31',
    @EstadoPedido = 'Recibido',
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- =====================================================================
-- Pruebas de Configuración de Notificaciones
-- =====================================================================

-- Prueba 13: Configurar notificaciones del cliente
PRINT '=== PRUEBA 13: Configurar notificaciones del cliente ===';
DECLARE @IdClienteNotif INT = (SELECT IdCliente FROM Clientes WHERE Email = 'carlos.ramirez@email.com');

UPDATE ConfiguracionNotificaciones
SET 
    NotificacionEmail = 1,
    NotificacionSMS = 1,
    NotificacionWhatsApp = 0,
    HorarioSilencio = 1,
    HoraSilencioInicio = '22:00:00',
    HoraSilencioFin = '08:00:00',
    NotificarEstadoPedido = 1,
    NotificarPromociones = 0,
    FechaUltimaModificacion = GETDATE()
WHERE IdCliente = @IdClienteNotif;

PRINT 'Notificaciones configuradas exitosamente';
GO

-- Prueba 14: Verificar configuración de notificaciones
PRINT '=== PRUEBA 14: Verificar configuración de notificaciones ===';
SELECT 
    c.NombreCompleto,
    cn.NotificacionEmail, cn.NotificacionSMS, cn.NotificacionWhatsApp,
    cn.HorarioSilencio, cn.HoraSilencioInicio, cn.HoraSilencioFin,
    cn.NotificarEstadoPedido, cn.NotificarPromociones
FROM ConfiguracionNotificaciones cn
INNER JOIN Clientes c ON cn.IdCliente = c.IdCliente
WHERE c.Email = 'carlos.ramirez@email.com';
GO

-- =====================================================================
-- Pruebas de Dispositivos Confiados
-- =====================================================================

-- Prueba 15: Agregar dispositivo confiado
PRINT '=== PRUEBA 15: Agregar dispositivo confiado ===';
DECLARE @IdClienteDispositivo INT = (SELECT IdCliente FROM Clientes WHERE Email = 'carlos.ramirez@email.com');
DECLARE @IdentificadorDispositivo NVARCHAR(255) = 'DEV_' + CONVERT(NVARCHAR(50), NEWID());

INSERT INTO DispositivosConfiados (
    IdCliente, IdentificadorDispositivo, NombreDispositivo, 
    DireccionIP, Navegador
)
VALUES (
    @IdClienteDispositivo, @IdentificadorDispositivo, 
    'Chrome en Windows - Casa', '192.168.1.100', 'Chrome 120.0'
);

PRINT 'Dispositivo confiado agregado exitosamente';
GO

-- Prueba 16: Verificar dispositivos confiados
PRINT '=== PRUEBA 16: Verificar dispositivos confiados ===';
SELECT 
    dc.NombreDispositivo, dc.DireccionIP, dc.Navegador,
    dc.FechaCreacion, dc.FechaUltimoUso, dc.Activo
FROM DispositivosConfiados dc
INNER JOIN Clientes c ON dc.IdCliente = c.IdCliente
WHERE c.Email = 'carlos.ramirez@email.com';
GO

-- =====================================================================
-- Pruebas de Auditoría Web
-- =====================================================================

-- Prueba 17: Verificar auditoría web
PRINT '=== PRUEBA 17: Verificar auditoría web ===';
SELECT TOP 10
    a.IdAuditoria,
    a.Accion,
    a.Modulo,
    a.DescripcionAccion,
    a.FechaAccion,
    a.DireccionIP,
    a.Navegador,
    c.NombreCompleto as NombreCliente
FROM AuditoriaWeb a
LEFT JOIN Clientes c ON a.IdCliente = c.IdCliente
ORDER BY a.FechaAccion DESC;
GO

-- Prueba 18: Verificar intentos de login
PRINT '=== PRUEBA 18: Verificar intentos de login ===';
SELECT TOP 10
    il.IdIntento,
    il.Email,
    il.Exitoso,
    il.MotivoFallo,
    il.FechaIntento,
    il.DireccionIP,
    c.NombreCompleto as NombreCliente
FROM IntentosLoginClientes il
LEFT JOIN Clientes c ON il.IdCliente = c.IdCliente
ORDER BY il.FechaIntento DESC;
GO

-- =====================================================================
-- Pruebas de Validaciones Adicionales
-- =====================================================================

-- Prueba 19: Intentar login con cuenta no verificada
PRINT '=== PRUEBA 19: Login con cuenta no verificada ===';
-- Crear cliente no verificado
EXEC sp_RegistrarClienteWeb
    @Nombre = 'María',
    @Apellido = 'Soto',
    @Email = 'maria.soto@email.com',
    @Password = 'Password123',
    @Telefono = '8888-4444',
    @TipoIdentificacion = 'CEDULA',
    @Identificacion = '122233344',
    @Direccion = 'Dirección de María',
    @AceptaTerminos = 1;

-- Intentar login sin verificar
EXEC sp_LoginClienteWeb
    @Email = 'maria.soto@email.com',
    @Password = 'Password123',
    @DireccionIP = '192.168.1.101',
    @Navegador = 'Firefox 121.0';
GO

-- Prueba 20: Verificar tokens de verificación
PRINT '=== PRUEBA 20: Verificar tokens de verificación ===';
SELECT 
    t.IdToken, t.TipoToken, t.FechaCreacion, t.FechaExpiracion, t.Usado, t.FechaUso,
    c.NombreCompleto, c.Email
FROM TokensVerificacion t
INNER JOIN Clientes c ON t.IdCliente = c.IdCliente
WHERE c.Email IN ('carlos.ramirez@email.com', 'maria.soto@email.com')
ORDER BY t.FechaCreacion DESC;
GO

-- Prueba 21: Verificar sesiones web activas
PRINT '=== PRUEBA 21: Verificar sesiones web activas ===';
SELECT 
    sw.IdSesionWeb, sw.FechaInicio, sw.FechaUltimaActividad, sw.FechaExpiracion,
    sw.Activa, sw.RecordarDispositivo, sw.DireccionIP, sw.Navegador,
    c.NombreCompleto, c.Email
FROM SesionesWeb sw
INNER JOIN Clientes c ON sw.IdCliente = c.IdCliente
WHERE sw.Activa = 1
ORDER BY sw.FechaUltimaActividad DESC;
GO

-- =====================================================================
-- Pruebas de Desactivación de Cuenta
-- =====================================================================

-- Prueba 22: Desactivar cuenta de cliente
PRINT '=== PRUEBA 22: Desactivar cuenta de cliente ===';
DECLARE @IdClienteDesactivar INT = (SELECT IdCliente FROM Clientes WHERE Email = 'maria.soto@email.com');

IF @IdClienteDesactivar IS NOT NULL
BEGIN
    UPDATE Clientes
    SET EstadoWeb = 'INACTIVO',
        FechaDesactivacion = GETDATE(),
        MotivoDesactivacion = 'Desactivación voluntaria del cliente'
    WHERE IdCliente = @IdClienteDesactivar;
    
    -- Cerrar sesiones activas
    UPDATE SesionesWeb
    SET Activa = 0, FechaCierre = GETDATE()
    WHERE IdCliente = @IdClienteDesactivar AND Activa = 1;
    
    PRINT 'Cuenta desactivada exitosamente';
END;
GO

-- Prueba 23: Intentar login con cuenta inactiva
PRINT '=== PRUEBA 23: Login con cuenta inactiva ===';
EXEC sp_LoginClienteWeb
    @Email = 'maria.soto@email.com',
    @Password = 'Password123',
    @DireccionIP = '192.168.1.101',
    @Navegador = 'Firefox 121.0';
GO

-- =====================================================================
-- Reportes del Sitio Web
-- =====================================================================

PRINT '=== REPORTES DEL SITIO WEB ===';

-- Clientes web por estado
PRINT '--- Clientes web por estado ---';
SELECT 
    EstadoWeb,
    COUNT(*) as TotalClientes,
    SUM(CASE WHEN FechaVerificacionEmail IS NOT NULL THEN 1 ELSE 0 END) as Verificados,
    SUM(CASE WHEN FechaUltimoLogin IS NOT NULL THEN 1 ELSE 0 END) as ConLogin,
    AVG(DATEDIFF(DAY, FechaRegistroWeb, GETDATE())) as PromedioDiasRegistrado
FROM Clientes
WHERE Email IS NOT NULL
GROUP BY EstadoWeb
ORDER BY TotalClientes DESC;

-- Actividad reciente
PRINT '--- Actividad reciente de clientes ---';
SELECT 
    COUNT(DISTINCT IdCliente) as ClientesActivos,
    COUNT(*) as TotalLogins,
    COUNT(CASE WHEN Exitoso = 1 THEN 1 END) as LoginsExitosos,
    COUNT(CASE WHEN Exitoso = 0 THEN 1 END) as LoginsFallidos
FROM IntentosLoginClientes
WHERE FechaIntento >= DATEADD(DAY, -7, GETDATE());

-- Sesiones activas
PRINT '--- Sesiones activas por dispositivo ---';
SELECT 
    Dispositivo,
    COUNT(*) as TotalSesiones,
    COUNT(CASE WHEN RecordarDispositivo = 1 THEN 1 END) as Recordadas,
    AVG(DATEDIFF(MINUTE, FechaInicio, GETDATE())) as PromedioMinutosActivas
FROM SesionesWeb
WHERE Activa = 1
GROUP BY Dispositivo
ORDER BY TotalSesiones DESC;

-- Dispositivos más usados
PRINT '--- Dispositivos más usados ---';
SELECT TOP 10
    Navegador,
    COUNT(*) as TotalSesiones,
    COUNT(DISTINCT IdCliente) as ClientesUnicos
FROM SesionesWeb
GROUP BY Navegador
ORDER BY TotalSesiones DESC;

GO

-- =====================================================================
-- Limpieza de datos de prueba
-- =====================================================================

-- Reactivar cliente bloqueado para pruebas futuras
UPDATE Clientes 
SET EstadoWeb = 'ACTIVO', 
    IntentosFallidos = 0, 
    FechaBloqueo = NULL
WHERE Email = 'carlos.ramirez@email.com';

-- Limpiar sesiones de prueba
DELETE FROM SesionesWeb WHERE IdCliente IN (SELECT IdCliente FROM Clientes WHERE Email LIKE '%@email.com');

PRINT '=== PRUEBAS DEL MÓDULO DE SITIO PARA CLIENTES COMPLETADAS ===';
PRINT 'Módulo de Sitio para Clientes completamente integrado y probado';
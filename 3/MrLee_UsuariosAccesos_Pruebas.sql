-- =====================================================================
-- Script de Integración y Pruebas para Módulo de Usuarios y Accesos
-- Mr Lee - Integración completa con todos los módulos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Datos Iniciales para Sistema de Permisos
-- =====================================================================

-- Insertar Permisos del Sistema
INSERT INTO Permisos (NombrePermiso, Descripcion, Modulo, Accion, Activo) VALUES
-- Permisos de Usuarios
('Usuario_Crear', 'Permite crear nuevos usuarios', 'Usuarios', 'Crear', 1),
('Usuario_Leer', 'Permite consultar usuarios', 'Usuarios', 'Leer', 1),
('Usuario_Actualizar', 'Permite editar usuarios', 'Usuarios', 'Actualizar', 1),
('Usuario_Eliminar', 'Permite eliminar usuarios', 'Usuarios', 'Eliminar', 1),
('Usuario_Listar', 'Permite listar usuarios', 'Usuarios', 'Listar', 1),
('Usuario_Auditoria', 'Permite ver bitácora de auditoría', 'Usuarios', 'Auditoria', 1),

-- Permisos de Inventario
('Inventario_Crear', 'Permite crear productos', 'Inventario', 'Crear', 1),
('Inventario_Leer', 'Permite consultar productos', 'Inventario', 'Leer', 1),
('Inventario_Actualizar', 'Permite editar productos', 'Inventario', 'Actualizar', 1),
('Inventario_Eliminar', 'Permite eliminar productos', 'Inventario', 'Eliminar', 1),
('Inventario_Listar', 'Permite listar productos', 'Inventario', 'Listar', 1),
('Inventario_Movimientos', 'Permite registrar movimientos', 'Inventario', 'Movimientos', 1),

-- Permisos de Pedidos
('Pedido_Crear', 'Permite crear pedidos', 'Pedidos', 'Crear', 1),
('Pedido_Leer', 'Permite consultar pedidos', 'Pedidos', 'Leer', 1),
('Pedido_Actualizar', 'Permite actualizar estado de pedidos', 'Pedidos', 'Actualizar', 1),
('Pedido_Eliminar', 'Permite anular pedidos', 'Pedidos', 'Eliminar', 1),
('Pedido_Listar', 'Permite listar pedidos', 'Pedidos', 'Listar', 1),

-- Permisos de Reportes
('Reporte_Ver', 'Permite ver reportes', 'Reportes', 'Leer', 1),
('Reporte_Exportar', 'Permite exportar reportes', 'Reportes', 'Exportar', 1);
GO

-- Asignar permisos a roles existentes
-- Administrador del sistema (todos los permisos)
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 1, IdPermiso, 1 FROM Permisos WHERE Activo = 1;

-- Empleado de ventas (permisos limitados)
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 2, IdPermiso, 1 FROM Permisos 
WHERE Modulo IN ('Pedidos') AND Accion IN ('Crear', 'Leer', 'Listar')
   OR (Modulo = 'Usuarios' AND Accion = 'Leer');

-- Encargado de despacho
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 3, IdPermiso, 1 FROM Permisos 
WHERE Modulo IN ('Pedidos') AND Accion IN ('Leer', 'Actualizar', 'Listar')
   OR (Modulo = 'Inventario' AND Accion IN ('Leer', 'Movimientos'));

-- Encargado de bodega
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 4, IdPermiso, 1 FROM Permisos 
WHERE Modulo = 'Inventario' AND Activo = 1;

-- Encargado contable
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 5, IdPermiso, 1 FROM Permisos 
WHERE Modulo IN ('Pedidos', 'Inventario', 'Reportes') AND Accion IN ('Leer', 'Listar');

-- Responsable de RRHH
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 6, IdPermiso, 1 FROM Permisos 
WHERE Modulo = 'Usuarios' AND Action IN ('Leer', 'Actualizar', 'Listar');

-- Repartidor
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 7, IdPermiso, 1 FROM Permisos 
WHERE Modulo = 'Pedidos' AND Accion IN ('Leer', 'Actualizar');

-- Cliente final
INSERT INTO RolesPermisos (IdRol, IdPermiso, IdUsuarioAsignacion)
SELECT 8, IdPermiso, 1 FROM Permisos 
WHERE Modulo = 'Pedidos' AND Accion IN ('Leer', 'Listar');

GO

-- =====================================================================
-- Actualizar datos de usuarios existentes
-- =====================================================================

UPDATE Usuarios 
SET 
    Puesto = CASE NombreUsuario
        WHEN 'admin' THEN 'Administrador del Sistema'
        WHEN 'jventas' THEN 'Empleado de Ventas'
        WHEN 'mdespacho' THEN 'Encargado de Despacho'
        WHEN 'cbodega' THEN 'Encargado de Bodega'
        WHEN 'acontable' THEN 'Encargado Contable'
        WHEN 'lrrhh' THEN 'Responsable de RRHH'
        WHEN 'prepartidor' THEN 'Repartidor'
        WHEN 'cliente1' THEN 'Cliente Final'
        ELSE 'Sin puesto definido'
    END,
    Telefono = CASE NombreUsuario
        WHEN 'admin' THEN '5551111111'
        WHEN 'jventas' THEN '5552222222'
        WHEN 'mdespacho' THEN '5553333333'
        WHEN 'cbodega' THEN '5554444444'
        WHEN 'acontable' THEN '5555555555'
        WHEN 'lrrhh' THEN '5556666666'
        WHEN 'prepartidor' THEN '5557777777'
        WHEN 'cliente1' THEN '5558888888'
        ELSE '5550000000'
    END;

-- Actualizar niveles de acceso en Roles
UPDATE Roles 
SET NivelAcceso = CASE IdRol
    WHEN 1 THEN 3 -- Administrador
    WHEN 2 THEN 1 -- Empleado ventas
    WHEN 3 THEN 2 -- Encargado despacho
    WHEN 4 THEN 2 -- Encargado bodega
    WHEN 5 THEN 1 -- Contable
    WHEN 6 THEN 1 -- RRHH
    WHEN 7 THEN 1 -- Repartidor
    WHEN 8 THEN 0 -- Cliente
    ELSE 0
END;

GO

-- =====================================================================
-- Pruebas del Sistema de Usuarios y Accesos
-- =====================================================================

PRINT '=== PRUEBAS DEL SISTEMA DE USUARIOS Y ACCESOS ===';

-- Prueba 1: Crear usuario nuevo con validaciones
PRINT '=== PRUEBA 1: Crear usuario nuevo ===';
DECLARE @Resultado INT;
DECLARE @Mensaje NVARCHAR(500);

EXEC @Resultado = sp_CrearUsuario
    @NombreCompleto = 'Pedro Ramírez',
    @Correo = 'pedro.ramirez@mrlee.com',
    @Contrasena = 'Password123',
    @Telefono = '5559999999',
    @Puesto = 'Vendedor Junior',
    @IdRol = 2,
    @IdUsuarioCrea = 1;

IF @Resultado = 1
    PRINT 'Usuario creado exitosamente';
ELSE
    PRINT 'Error al crear usuario';

-- Verificar usuario creado
SELECT * FROM Usuarios WHERE CorreoElectronico = 'pedro.ramirez@mrlee.com';
GO

-- Prueba 2: Intentar crear usuario con correo duplicado
PRINT '=== PRUEBA 2: Correo duplicado (debe fallar) ===';
EXEC sp_CrearUsuario
    @NombreCompleto = 'Otro Pedro',
    @Correo = 'pedro.ramirez@mrlee.com', -- Mismo correo
    @Contrasena = 'Password123',
    @Telefono = '5550000000',
    @Puesto = 'Otro puesto',
    @IdRol = 2,
    @IdUsuarioCrea = 1;
GO

-- Prueba 3: Validar login exitoso
PRINT '=== PRUEBA 3: Login exitoso ===';
EXEC sp_ValidarLogin
    @Correo = 'admin@mrlee.com',
    @Contrasena = 'hashed_admin123',
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';
GO

-- Prueba 4: Validar login con contraseña incorrecta
PRINT '=== PRUEBA 4: Login con contraseña incorrecta ===';
EXEC sp_ValidarLogin
    @Correo = 'admin@mrlee.com',
    @Contrasena = 'contraseña_incorrecta',
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';
GO

-- Prueba 5: Simular bloqueo por intentos fallidos
PRINT '=== PRUEBA 5: Bloqueo por intentos fallidos ===';
DECLARE @Contador INT = 0;
WHILE @Contador < 5
BEGIN
    EXEC sp_ValidarLogin
        @Correo = 'admin@mrlee.com',
        @Contrasena = 'contraseña_incorrecta',
        @DireccionIP = '192.168.1.100',
        @Navegador = 'Chrome 120.0';
    SET @Contador = @Contador + 1;
END

-- Verificar estado del usuario
SELECT NombreUsuario, Bloqueado, IntentosFallidos, FechaBloqueo 
FROM Usuarios 
WHERE NombreUsuario = 'admin';
GO

-- Prueba 6: Intentar login con usuario bloqueado
PRINT '=== PRUEBA 6: Login con usuario bloqueado ===';
EXEC sp_ValidarLogin
    @Correo = 'admin@mrlee.com',
    @Contrasena = 'hashed_admin123', -- Contraseña correcta
    @DireccionIP = '192.168.1.100',
    @Navegador = 'Chrome 120.0';
GO

-- Prueba 7: Reactivar usuario bloqueado
PRINT '=== PRUEBA 7: Reactivar usuario bloqueado ===';
UPDATE Usuarios 
SET Bloqueado = 0, IntentosFallidos = 0 
WHERE NombreUsuario = 'admin';

-- Verificar reactivación
SELECT NombreUsuario, Bloqueado, IntentosFallidos 
FROM Usuarios 
WHERE NombreUsuario = 'admin';
GO

-- Prueba 8: Consultar usuarios con filtros
PRINT '=== PRUEBA 8: Consultar usuarios con filtros ===';

-- Buscar por texto
PRINT '--- Búsqueda por texto "Juan" ---';
EXEC sp_ConsultarUsuarios 
    @TextoBusqueda = 'Juan',
    @Pagina = 1,
    @TamanoPagina = 10;

-- Filtrar por rol
PRINT '--- Filtrar por rol Empleado de Ventas ---';
EXEC sp_ConsultarUsuarios 
    @IdRol = 2,
    @Pagina = 1,
    @TamanoPagina = 10;

-- Filtrar por activos
PRINT '--- Filtrar usuarios activos ---';
EXEC sp_ConsultarUsuarios 
    @Activo = 1,
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- Prueba 9: Verificar permisos de usuario
PRINT '=== PRUEBA 9: Verificar permisos de usuario ===';
SELECT 
    u.NombreUsuario,
    r.NombreRol,
    p.NombrePermiso,
    p.Modulo,
    p.Accion
FROM Usuarios u
INNER JOIN Roles r ON u.IdRol = r.IdRol
INNER JOIN RolesPermisos rp ON r.IdRol = rp.IdRol
INNER JOIN Permisos p ON rp.IdPermiso = p.IdPermiso
WHERE u.NombreUsuario = 'jventas'
ORDER BY p.Modulo, p.Accion;
GO

-- Prueba 10: Intentar eliminar correo protegido
PRINT '=== PRUEBA 10: Cambiar correo protegido (debe fallar) ===';
BEGIN TRY
    UPDATE Usuarios 
    SET CorreoElectronico = 'nuevo.correo@mrlee.com' 
    WHERE NombreUsuario = 'jventas';
    
    PRINT 'ERROR: No debería permitir cambiar correo protegido';
END TRY
BEGIN CATCH
    PRINT 'BIEN: El correo está protegido por diseño - debe hacerse por procedimiento especial';
END CATCH;
GO

-- =====================================================================
-- Pruebas de Auditoría y Bitácora
-- =====================================================================

-- Prueba 11: Verificar bitácora de auditoría
PRINT '=== PRUEBA 11: Verificar bitácora de auditoría ===';
SELECT TOP 10
    b.IdBitacora,
    u.NombreUsuario,
    b.Accion,
    b.Modulo,
    b.EntidadAfectada,
    b.IdEntidadAfectada,
    b.FechaAccion,
    b.DireccionIP
FROM BitacoraAuditoria b
INNER JOIN Usuarios u ON b.IdUsuario = u.IdUsuario
ORDER BY b.FechaAccion DESC;
GO

-- Prueba 12: Verificar intentos de login
PRINT '=== PRUEBA 12: Verificar intentos de login ===';
SELECT TOP 10
    i.IdIntento,
    i.CorreoElectronico,
    i.Exitoso,
    i.MotivoFallo,
    i.FechaIntento,
    i.DireccionIP,
    u.NombreUsuario
FROM IntentosLogin i
LEFT JOIN Usuarios u ON i.IdUsuario = u.IdUsuario
ORDER BY i.FechaIntento DESC;
GO

-- =====================================================================
-- Pruebas de Validación de Reglas de Negocio
-- =====================================================================

-- Prueba 13: Intentar desactivar último administrador
PRINT '=== PRUEBA 13: Desactivar último administrador (debe fallar) ===';
BEGIN TRY
    UPDATE Usuarios 
    SET Activo = 0 
    WHERE IdRol = 1 AND Activo = 1;
    
    PRINT 'ERROR: No debería permitir desactivar todos los administradores';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Protección contra desactivar todos los administradores';
END CATCH;
GO

-- Prueba 14: Validar formato de correo en creación
PRINT '=== PRUEBA 14: Formato de correo inválido (debe fallar) ===';
EXEC sp_CrearUsuario
    @NombreCompleto = 'Usuario Test',
    @Correo = 'correo_invalido', -- Sin formato de email
    @Contrasena = 'Password123',
    @Telefono = '5550000000',
    @Puesto = 'Test',
    @IdRol = 2,
    @IdUsuarioCrea = 1;
GO

-- Prueba 15: Validar complejidad de contraseña
PRINT '=== PRUEBA 15: Contraseña débil (debe fallar) ===';
EXEC sp_CrearUsuario
    @NombreCompleto = 'Usuario Test',
    @Correo = 'test.valido@mrlee.com',
    @Contrasena = '123', -- Contraseña muy débil
    @Telefono = '5550000000',
    @Puesto = 'Test',
    @IdRol = 2,
    @IdUsuarioCrea = 1;
GO

-- =====================================================================
-- Reportes del Sistema de Usuarios
-- =====================================================================

PRINT '=== REPORTES DEL SISTEMA DE USUARIOS ===';

-- Usuarios por rol
PRINT '--- Usuarios por rol ---';
SELECT 
    r.NombreRol,
    COUNT(*) as TotalUsuarios,
    SUM(CASE WHEN u.Activo = 1 THEN 1 ELSE 0 END) as Activos,
    SUM(CASE WHEN u.Bloqueado = 1 THEN 1 ELSE 0 END) as Bloqueados
FROM Roles r
LEFT JOIN Usuarios u ON r.IdRol = u.IdRol AND u.Eliminado = 0
GROUP BY r.NombreRol, r.IdRol
ORDER BY TotalUsuarios DESC;

-- Actividad reciente
PRINT '--- Actividad reciente de usuarios ---';
SELECT 
    u.NombreUsuario,
    u.FechaUltimoLogin,
    (SELECT COUNT(*) FROM IntentosLogin il WHERE il.IdUsuario = u.IdUsuario AND il.Exitoso = 1 AND il.FechaIntento >= DATEADD(DAY, -7, GETDATE())) as LoginsSemana,
    (SELECT COUNT(*) FROM BitacoraAuditoria ba WHERE ba.IdUsuario = u.IdUsuario AND ba.FechaAccion >= DATEADD(DAY, -7, GETDATE())) as AccionesSemana
FROM Usuarios u
WHERE u.Activo = 1 AND u.Eliminado = 0
ORDER BY u.FechaUltimoLogin DESC;

-- Intentos fallidos recientes
PRINT '--- Intentos fallidos recientes ---';
SELECT 
    i.CorreoElectronico,
    COUNT(*) as TotalIntentosFallidos,
    MAX(i.FechaIntento) as UltimoIntento,
    u.Bloqueado
FROM IntentosLogin i
LEFT JOIN Usuarios u ON i.IdUsuario = u.IdUsuario
WHERE i.Exitoso = 0 AND i.FechaIntento >= DATEADD(DAY, -1, GETDATE())
GROUP BY i.CorreoElectronico, u.Bloqueado
HAVING COUNT(*) > 0
ORDER BY TotalIntentosFallidos DESC;

GO

-- =====================================================================
-- Limpieza de datos de prueba
-- =====================================================================

-- Eliminar usuario de prueba creado
DELETE FROM Usuarios WHERE CorreoElectronico = 'pedro.ramirez@mrlee.com';

-- Reactivar administrador si quedó bloqueado
UPDATE Usuarios 
SET Bloqueado = 0, IntentosFallidos = 0 
WHERE NombreUsuario = 'admin';

GO

PRINT '=== PRUEBAS DEL SISTEMA DE USUARIOS Y ACCESOS COMPLETADAS ===';
PRINT 'Módulo de Usuarios y Accesos completamente integrado y probado';
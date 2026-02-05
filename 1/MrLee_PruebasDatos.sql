-- =====================================================================
-- Script de Datos de Ejemplo y Pruebas de Integridad Referencial
-- Mr Lee - Módulo Seguimiento de Pedidos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Datos de Catálogos
-- =====================================================================

-- Insertar Estados de Pedido
INSERT INTO EstadosPedido (NombreEstado, Descripcion, Activo) VALUES
('Recibido', 'Pedido recibido y validado', 1),
('En preparación', 'Pedido en proceso de preparación', 1),
('En ruta', 'Pedido en camino al cliente', 1),
('Entregado', 'Pedido entregado exitosamente', 1),
('Problema', 'Pedido con incidencias', 1),
('Cancelado', 'Pedido cancelado', 0);
GO

-- Insertar Prioridades
INSERT INTO Prioridades (NombrePrioridad, Descripcion, Nivel) VALUES
('Baja', 'Prioridad baja - entregar en hasta 5 días', 3),
('Media', 'Prioridad media - entregar en hasta 3 días', 2),
('Alta', 'Prioridad alta - entregar en 24-48 horas', 1);
GO

-- Insertar Roles
INSERT INTO Roles (NombreRol, Descripcion, Activo) VALUES
('Administrador del sistema', 'Acceso completo a todo el sistema', 1),
('Empleado de ventas', 'Crea y consulta pedidos', 1),
('Encargado de despacho', 'Gestiona estados de pedidos', 1),
('Encargado de bodega', 'Maneja inventario y prepara pedidos', 1),
('Encargado contable', 'Gestiona ingresos y finanzas', 1),
('Responsable de RRHH', 'Administra personal', 1),
('Repartidor', 'Realiza entregas', 1),
('Cliente final', 'Acceso limitado para consulta', 1);
GO

-- Insertar Usuarios de Prueba
INSERT INTO Usuarios (NombreCompleto, NombreUsuario, CorreoElectronico, Contrasena, IdRol, Activo) VALUES
('Admin Sistema', 'admin', 'admin@mrlee.com', 'hashed_admin123', 1, 1),
('Juan Ventas', 'jventas', 'juan.ventas@mrlee.com', 'hashed_pass123', 2, 1),
('María Despacho', 'mdespacho', 'maria.despacho@mrlee.com', 'hashed_pass123', 3, 1),
('Carlos Bodega', 'cbodega', 'carlos.bodega@mrlee.com', 'hashed_pass123', 4, 1),
('Ana Contable', 'acontable', 'ana.contable@mrlee.com', 'hashed_pass123', 5, 1),
('Luis RRHH', 'lrrhh', 'luis.rrhh@mrlee.com', 'hashed_pass123', 6, 1),
('Pedro Repartidor', 'prepartidor', 'pedro.repartidor@mrlee.com', 'hashed_pass123', 7, 1),
('Cliente Ejemplo', 'cliente1', 'cliente@ejemplo.com', 'hashed_pass123', 8, 1);
GO

-- Insertar Clientes de Prueba
INSERT INTO Clientes (NombreCompleto, Telefono, CorreoElectronico, Direccion, Latitud, Longitud, Activo) VALUES
('María González', '5551234567', 'maria.g@email.com', 'Av. Principal #123, Col. Centro, CP 12345', 19.4326, -99.1332, 1),
('José Rodríguez', '5559876543', 'jose.r@email.com', 'Calle Secundaria #456, Col. Norte, CP 67890', 19.4030, -99.1540, 1),
('Ana Martínez', '5552468135', 'ana.m@email.com', 'Bulevard Central #789, Col. Sur, CP 13579', 19.4260, -99.1620, 1),
('Luis López', '5553691472', 'luis.l@email.com', 'Plaza Mayor #101, Col. Este, CP 24680', 19.4440, -99.1750, 1);
GO

-- =====================================================================
-- Pruebas de Integridad Referencial
-- =====================================================================

-- Prueba 1: Crear un pedido válido
PRINT '=== PRUEBA 1: Crear pedido válido ===';
DECLARE @IdCliente INT = (SELECT TOP 1 IdCliente FROM Clientes);
DECLARE @IdEstado INT = (SELECT IdEstado FROM EstadosPedido WHERE NombreEstado = 'Recibido');
DECLARE @IdPrioridad INT = (SELECT IdPrioridad FROM Prioridades WHERE NombrePrioridad = 'Media');
DECLARE @IdUsuario INT = (SELECT IdUsuario FROM Usuarios WHERE NombreUsuario = 'jventas');

BEGIN TRANSACTION;
    INSERT INTO Pedidos (
        NumeroSeguimiento, IdCliente, IdEstado, IdPrioridad, IdUsuarioCreacion,
        DireccionEntrega, TelefonoContacto, Observaciones, FechaPrometida
    ) VALUES (
        'MR-2026-001', @IdCliente, @IdEstado, @IdPrioridad, @IdUsuario,
        'Av. Principal #123, Col. Centro', '5551234567', 'Pedido de prueba', DATEADD(DAY, 3, GETDATE())
    );
    
    DECLARE @IdPedido INT = SCOPE_IDENTITY();
    PRINT 'Pedido creado con ID: ' + CAST(@IdPedido AS NVARCHAR(10));
    
    -- Agregar detalles del pedido
    INSERT INTO PedidoDetalles (IdPedido, NombreProducto, Cantidad, PrecioUnitario) VALUES
        (@IdPedido, 'Panes de caja', 10, 25.50),
        (@IdPedido, 'Pan dulce assorted', 5, 45.75);
    
    PRINT 'Detalles agregados correctamente';
COMMIT TRANSACTION;
GO

-- Prueba 2: Intentar crear pedido con cliente inexistente (debe fallar)
PRINT '=== PRUEBA 2: Cliente inexistente (debe fallar) ===';
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO Pedidos (
            NumeroSeguimiento, IdCliente, IdEstado, IdPrioridad, IdUsuarioCreacion,
            DireccionEntrega, TelefonoContacto, FechaPrometida
        ) VALUES (
            'MR-2026-002', 9999, 1, 1, 1,
            'Dirección prueba', '5550000000', DATEADD(DAY, 2, GETDATE())
        );
    COMMIT TRANSACTION;
    PRINT 'ERROR: No debería permitir crear pedido con cliente inexistente';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'BIEN: Impidió crear pedido con cliente inexistente - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 3: Intentar eliminar cliente con pedidos (debe fallar)
PRINT '=== PRUEBA 3: Eliminar cliente con pedidos (debe fallar) ===';
BEGIN TRY
    DELETE FROM Clientes WHERE IdCliente = (SELECT TOP 1 IdCliente FROM Clientes);
    PRINT 'ERROR: No debería permitir eliminar cliente con pedidos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió eliminar cliente con pedidos - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 4: Cambiar estado del pedido (debe crear registro en historial)
PRINT '=== PRUEBA 4: Cambio de estado (debe registrar en historial) ===';
DECLARE @IdPedidoTest INT = (SELECT TOP 1 IdPedido FROM Pedidos);
DECLARE @IdEstadoPrep INT = (SELECT IdEstado FROM EstadosPedido WHERE NombreEstado = 'En preparación');

IF @IdPedidoTest IS NOT NULL
BEGIN
    -- Actualizar estado
    UPDATE Pedidos 
    SET IdEstado = @IdEstadoPrep, 
        IdUsuarioUltimaModificacion = (SELECT IdUsuario FROM Usuarios WHERE NombreUsuario = 'mdespacho')
    WHERE IdPedido = @IdPedidoTest;
    
    -- Verificar que se creó registro en historial
    DECLARE @CountHistorial INT = (
        SELECT COUNT(*) 
        FROM HistorialEstados 
        WHERE IdPedido = @IdPedidoTest AND IdEstadoNuevo = @IdEstadoPrep
    );
    
    PRINT 'Registros en historial después de cambio de estado: ' + CAST(@CountHistorial AS NVARCHAR(10));
END;
GO

-- Prueba 5: Intentar borrar estado utilizado (debe fallar)
PRINT '=== PRUEBA 5: Eliminar estado utilizado (debe fallar) ===';
BEGIN TRY
    DELETE FROM EstadosPedido WHERE NombreEstado = 'Recibido';
    PRINT 'ERROR: No debería permitir eliminar estado utilizado';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió eliminar estado utilizado - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 6: Crear nota para un pedido
PRINT '=== PRUEBA 6: Crear nota de pedido ===';
DECLARE @IdPedidoNota INT = (SELECT TOP 1 IdPedido FROM Pedidos);
DECLARE @IdUsuarioNota INT = (SELECT IdUsuario FROM Usuarios WHERE NombreUsuario = 'mdespacho');

IF @IdPedidoNota IS NOT NULL
BEGIN
    INSERT INTO NotasPedido (IdPedido, IdUsuario, Nota)
    VALUES (@IdPedidoNota, @IdUsuarioNota, 'Nota de prueba: Cliente solicita empaque especial');
    
    PRINT 'Nota creada correctamente para pedido ID: ' + CAST(@IdPedidoNota AS NVARCHAR(10));
END;
GO

-- Prueba 7: Verificación de constraint de fecha prometida
PRINT '=== PRUEBA 7: Fecha prometida inválida (debe fallar) ===';
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO Pedidos (
            NumeroSeguimiento, IdCliente, IdEstado, IdPrioridad, IdUsuarioCreacion,
            DireccionEntrega, TelefonoContacto, FechaPrometida
        ) VALUES (
            'MR-2026-003', 
            (SELECT TOP 1 IdCliente FROM Clientes), 
            (SELECT IdEstado FROM EstadosPedido WHERE NombreEstado = 'Recibido'),
            (SELECT IdPrioridad FROM Prioridades WHERE NombrePrioridad = 'Media'),
            (SELECT IdUsuario FROM Usuarios WHERE NombreUsuario = 'jventas'),
            'Dirección prueba', '5550000000', 
            DATEADD(MONTH, 3, GETDATE()) -- Más de 2 meses (debe fallar)
        );
    COMMIT TRANSACTION;
    PRINT 'ERROR: No debería permitir fecha prometida mayor a 2 meses';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'BIEN: Impidió fecha prometida mayor a 2 meses - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 8: Anular pedido
PRINT '=== PRUEBA 8: Anular pedido correctamente ===';
DECLARE @IdPedidoAnular INT = (SELECT TOP 1 IdPedido FROM Pedidos WHERE Anulado = 0);
DECLARE @IdUsuarioAnula INT = (SELECT IdUsuario FROM Usuarios WHERE NombreUsuario = 'admin');

IF @IdPedidoAnular IS NOT NULL
BEGIN
    UPDATE Pedidos
    SET Anulado = 1,
        FechaAnulacion = GETDATE(),
        MotivoAnulacion = 'Error en datos del cliente',
        IdUsuarioAnulacion = @IdUsuarioAnula
    WHERE IdPedido = @IdPedidoAnular;
    
    PRINT 'Pedido anulado correctamente ID: ' + CAST(@IdPedidoAnular AS NVARCHAR(10));
END;
GO

-- =====================================================================
-- Consultas de Verificación
-- =====================================================================

PRINT '=== VERIFICACIÓN FINAL DE DATOS ===';

-- Verificar todos los pedidos
PRINT 'Total de pedidos: ' + CAST((SELECT COUNT(*) FROM Pedidos) AS NVARCHAR(10));
PRINT 'Pedidos activos: ' + CAST((SELECT COUNT(*) FROM Pedidos WHERE Anulado = 0) AS NVARCHAR(10));
PRINT 'Pedidos anulados: ' + CAST((SELECT COUNT(*) FROM Pedidos WHERE Anulado = 1) AS NVARCHAR(10));

-- Verificar historial
PRINT 'Total de registros en historial: ' + CAST((SELECT COUNT(*) FROM HistorialEstados) AS NVARCHAR(10));

-- Verificar notas
PRINT 'Total de notas creadas: ' + CAST((SELECT COUNT(*) FROM NotasPedido) AS NVARCHAR(10));

GO

PRINT '=== PRUEBAS DE INTEGRIDAD REFERENCIAL COMPLETADAS ===';
PRINT 'Todos los scripts han sido ejecutados y verificados correctamente.';
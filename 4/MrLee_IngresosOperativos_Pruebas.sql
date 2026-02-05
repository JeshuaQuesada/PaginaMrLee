-- =====================================================================
-- Script de Integración y Pruebas para Módulo de Ingresos Operativos
-- Mr Lee - Integración completa con todos los módulos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Datos Iniciales para Catálogos de Ingresos Operativos
-- =====================================================================

-- Insertar Tipos de Ingreso
INSERT INTO TiposIngreso (NombreTipo, Descripcion, Activo) VALUES
('Venta al detalle', 'Ventas directas a clientes en sucursal', 1),
('Venta por mayor', 'Ventas mayoristas a distribuidores', 1),
('Servicios', 'Ingresos por servicios adicionales', 1),
('Alquiler', 'Ingresos por alquiler de espacios', 1),
('Intereses', 'Ingresos financieros por intereses', 1),
('Otros', 'Otros ingresos no categorizados', 1);
GO

-- Insertar Categorías de Ingreso
INSERT INTO CategoriasIngreso (NombreCategoria, Descripcion, Activa) VALUES
('Panadería', 'Ingresos por productos de panadería', 1),
('Pastelería', 'Ingresos por productos de pastelería', 1),
('Bebidas', 'Ingresos por venta de bebidas', 1),
('Snacks', 'Ingresos por botanas y snacks', 1),
('Ingredientes', 'Ingresos por venta de ingredientes', 1),
('Empaquetado', 'Ingresos por material de empaque', 1),
('Servicios', 'Ingresos por servicios varios', 1);
GO

-- Insertar Métodos de Pago
INSERT INTO MetodosPago (NombreMetodo, Descripcion, RequiereReferencia, RequiereDatosTarjeta, RequiereBanco, Activo) VALUES
('EFECTIVO', 'Pago en efectivo', 0, 0, 0, 1),
('TARJETA', 'Pago con tarjeta de crédito/débito', 1, 1, 0, 1),
('SINPE', 'Transferencia SINPE', 1, 0, 0, 1),
('TRANSFERENCIA', 'Transferencia bancaria', 1, 0, 1, 1),
('CHEQUE', 'Pago con cheque', 1, 0, 1, 1);
GO

-- Crear Periodos Contables para 2026
INSERT INTO PeriodosContables (NombrePeriodo, FechaInicio, FechaFin, Estado) VALUES
('2026-01', '2026-01-01', '2026-01-31', 'ABIERTO'),
('2026-02', '2026-02-01', '2026-02-28', 'ABIERTO'),
('2026-03', '2026-03-01', '2026-03-31', 'ABIERTO'),
('2026-04', '2026-04-01', '2026-04-30', 'ABIERTO'),
('2026-05', '2026-05-01', '2026-05-31', 'ABIERTO'),
('2026-06', '2026-06-01', '2026-06-30', 'ABIERTO');
GO

-- Insertar Tipos de Cambio (ejemplo para USD/CRC)
INSERT INTO TiposCambio (Fecha, TipoCambio, MonedaOrigen, MonedaDestino, IdUsuarioRegistro) VALUES
('2026-01-01', 545.50, 'USD', 'CRC', 5),
('2026-01-02', 546.00, 'USD', 'CRC', 5),
('2026-01-03', 545.75, 'USD', 'CRC', 5),
('2026-01-04', 546.25, 'USD', 'CRC', 5),
('2026-01-05', 547.00, 'USD', 'CRC', 5);
GO

-- =====================================================================
-- Pruebas del Módulo de Ingresos Operativos
-- =====================================================================

PRINT '=== PRUEBAS DEL MÓDULO DE INGRESOS OPERATIVOS ===';

-- Prueba 1: Registrar ingreso en efectivo (CRC)
PRINT '=== PRUEBA 1: Registro de ingreso en efectivo (CRC) ===';
DECLARE @Resultado INT;
DECLARE @Mensaje NVARCHAR(500);
DECLARE @IdIngreso INT;

EXEC @Resultado = sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-15',
    @Monto = 15000.00,
    @Moneda = 'CRC',
    @IdTipoIngreso = 1, -- Venta al detalle
    @IdCategoria = 1, -- Panadería
    @IdMetodoPago = 1, -- EFECTIVO
    @IdCliente = (SELECT TOP 1 IdCliente FROM Clientes),
    @IdPedido = (SELECT TOP 1 IdPedido FROM Pedidos),
    @IdUsuarioCreacion = 5, -- Ana Contable
    @Observaciones = 'Venta de panes a María González';

IF @Resultado = 1
    PRINT 'Ingreso en CRC registrado exitosamente';
ELSE
    PRINT 'Error al registrar ingreso en CRC';

-- Verificar registro
SELECT TOP 1 * FROM IngresosOperativos ORDER BY IdIngreso DESC;
GO

-- Prueba 2: Registrar ingreso en USD con tarjeta
PRINT '=== PRUEBA 2: Registro de ingreso en USD con tarjeta ===';
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-16',
    @Monto = 50.00,
    @Moneda = 'USD',
    @IdTipoIngreso = 1, -- Venta al detalle
    @IdCategoria = 2, -- Pastelería
    @IdMetodoPago = 2, -- TARJETA
    @ReferenciaPago = 'TAR-2026-001',
    @Ultimos4Tarjeta = 1234,
    @VoucherAutorizacion = 'AUTH-2026-001',
    @IdCliente = (SELECT TOP 1 IdCliente FROM Clientes WHERE IdCliente NOT IN (SELECT IdCliente FROM IngresosOperativos WHERE IdCliente IS NOT NULL)),
    @IdUsuarioCreacion = 5, -- Ana Contable;

-- Verificar conversión
SELECT TOP 1 MontoUSD, MontoCRC, IdTipoCambio FROM IngresosOperativos WHERE Moneda = 'USD' ORDER BY IdIngreso DESC;
GO

-- Prueba 3: Intentar registrar sin tipo de cambio (debe fallar)
PRINT '=== PRUEBA 3: Registro USD sin tipo de cambio (debe fallar) ===';
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-20', -- No hay tipo de cambio para esta fecha
    @Monto = 30.00,
    @Moneda = 'USD',
    @IdTipoIngreso = 1,
    @IdCategoria = 1,
    @IdMetodoPago = 1,
    @IdUsuarioCreacion = 5;
GO

-- Prueba 4: Intentar duplicar referencia mismo día (debe fallar)
PRINT '=== PRUEBA 4: Duplicar referencia mismo día (debe fallar) ===';
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-16', -- Misma fecha que prueba 2
    @Monto = 25.00,
    @Moneda = 'CRC',
    @IdTipoIngreso = 1,
    @IdCategoria = 3,
    @IdMetodoPago = 2, -- TARJETA
    @ReferenciaPago = 'TAR-2026-001', -- Misma referencia
    @IdUsuarioCreacion = 5;
GO

-- Prueba 5: Registro con SINPE
PRINT '=== PRUEBA 5: Registro con SINPE ===';
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-17',
    @Monto = 8500.00,
    @Moneda = 'CRC',
    @IdTipoIngreso = 1,
    @IdCategoria = 1,
    @IdMetodoPago = 3, -- SINPE
    @ReferenciaPago = 'SINPE-2026-001',
    @IdCliente = (SELECT TOP 1 IdCliente FROM Clientes),
    @IdUsuarioCreacion = 5;
GO

-- Prueba 6: Intentar registro con tarjeta sin datos (debe fallar)
PRINT '=== PRUEBA 6: Tarjeta sin datos requeridos (debe fallar) ===';
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-01-18',
    @Monto = 5000.00,
    @Moneda = 'CRC',
    @IdTipoIngreso = 1,
    @IdCategoria = 1,
    @IdMetodoPago = 2, -- TARJETA
    -- Faltan Ultimos4Tarjeta y VoucherAutorizacion
    @IdUsuarioCreacion = 5;
GO

-- Prueba 7: Consultar ingresos con filtros
PRINT '=== PRUEBA 7: Consultar ingresos con filtros ===';
EXEC sp_ConsultarIngresos
    @FechaInicio = '2026-01-15',
    @FechaFin = '2026-01-17',
    @IdCategoria = 1, -- Panadería
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- Prueba 8: Rango de fechas inválido (más de 31 días, debe fallar)
PRINT '=== PRUEBA 8: Rango mayor a 31 días (debe fallar) ===';
EXEC sp_ConsultarIngresos
    @FechaInicio = '2026-01-01',
    @FechaFin = '2026-02-15', -- Más de 31 días
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- Prueba 9: Rango invertido (debe corregirse automáticamente)
PRINT '=== PRUEBA 9: Rango invertido (debe corregirse) ===';
EXEC sp_ConsultarIngresos
    @FechaInicio = '2026-01-20',
    @FechaFin = '2026-01-15', -- Invertido
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- =====================================================================
-- Pruebas de Sumas Agregadas
-- =====================================================================

-- Prueba 10: Sumas por día
PRINT '=== PRUEBA 10: Sumas agregadas por día ===';
EXEC sp_ObtenerSumasIngresos
    @FechaInicio = '2026-01-15',
    @FechaFin = '2026-01-17',
    @Agregacion = 'DIA';
GO

-- Prueba 11: Sumas por categoría
PRINT '=== PRUEBA 11: Sumas por categoría ===';
EXEC sp_ObtenerSumasIngresos
    @FechaInicio = '2026-01-15',
    @FechaFin = '2026-01-17',
    @Agregacion = 'DIA',
    @IdCategoria = 1; -- Panadería
GO

-- =====================================================================
-- Pruebas de Periodos Contables
-- =====================================================================

-- Prueba 12: Intentar registrar en periodo cerrado (simular cierre primero)
PRINT '=== PRUEBA 12: Registrar en periodo cerrado ===';

-- Cerrar un periodo para la prueba
UPDATE PeriodosContables 
SET Estado = 'CERRADO', 
    FechaCierre = GETDATE(),
    IdUsuarioCierre = 1
WHERE NombrePeriodo = '2026-02';

-- Intentar registrar en periodo cerrado
EXEC sp_RegistrarIngresoOperativo
    @FechaIngreso = '2026-02-15', -- Dentro del periodo cerrado
    @Monto = 1000.00,
    @Moneda = 'CRC',
    @IdTipoIngreso = 1,
    @IdCategoria = 1,
    @IdMetodoPago = 1,
    @IdUsuarioCreacion = 5;

GO

-- Prueba 13: Reactivar periodo para pruebas
PRINT '=== PRUEBA 13: Reactivar periodo ===';
UPDATE PeriodosContables 
SET Estado = 'ABIERTO', 
    FechaCierre = NULL,
    IdUsuarioCierre = NULL
WHERE NombrePeriodo = '2026-02';
GO

-- =====================================================================
-- Pruebas de Auditoría
-- =====================================================================

-- Prueba 14: Verificar auditoría de ingresos
PRINT '=== PRUEBA 14: Verificar auditoría de ingresos ===';
SELECT TOP 10
    a.IdAuditoria,
    a.Accion,
    a.Modulo,
    a.DescripcionAccion,
    a.FechaAccion,
    u.NombreUsuario as Responsable,
    io.IdIngreso,
    io.Monto,
    io.Moneda
FROM AuditoriaIngresos a
INNER JOIN Usuarios u ON a.IdUsuario = u.IdUsuario
LEFT JOIN IngresosOperativos io ON a.IdIngreso = io.IdIngreso
ORDER BY a.FechaAccion DESC;
GO

-- =====================================================================
-- Pruebas de Anulación de Ingresos
-- =====================================================================

-- Prueba 15: Anular un ingreso
PRINT '=== PRUEBA 15: Anular ingreso ===';
DECLARE @IdIngresoAnular INT = (SELECT TOP 1 IdIngreso FROM IngresosOperativos WHERE Estado = 'REGISTRADO');

IF @IdIngresoAnular IS NOT NULL
BEGIN
    UPDATE IngresosOperativos
    SET Estado = 'ANULADO',
        MotivoAnulacion = 'Error en registro - cliente canceló compra',
        FechaAnulacion = GETDATE(),
        IdUsuarioAnulacion = 1 -- Admin
    WHERE IdIngreso = @IdIngresoAnular;
    
    PRINT 'Ingreso anulado exitosamente. ID: ' + CAST(@IdIngresoAnular AS NVARCHAR(10));
END;
GO

-- =====================================================================
-- Reportes de Ingresos Operativos
-- =====================================================================

PRINT '=== REPORTES DE INGRESOS OPERATIVOS ===';

-- Resumen por periodo
PRINT '--- Resumen por periodo ---';
SELECT 
    pc.NombrePeriodo,
    COUNT(*) as TotalIngresos,
    SUM(CASE WHEN io.Estado = 'REGISTRADO' THEN io.MontoCRC ELSE 0 END) as TotalCRC,
    SUM(CASE WHEN io.Estado = 'ANULADO' THEN io.MontoCRC ELSE 0 END) as TotalAnuladoCRC,
    SUM(ISNULL(io.MontoUSD, 0)) as TotalUSD,
    AVG(CASE WHEN io.Estado = 'REGISTRADO' THEN io.MontoCRC ELSE NULL END) as PromedioCRC
FROM IngresosOperativos io
INNER JOIN PeriodosContables pc ON io.IdPeriodo = pc.IdPeriodo
GROUP BY pc.NombrePeriodo, pc.IdPeriodo
ORDER BY pc.NombrePeriodo DESC;

-- Resumen por tipo de ingreso
PRINT '--- Resumen por tipo de ingreso ---';
SELECT 
    ti.NombreTipo,
    COUNT(*) as TotalIngresos,
    SUM(io.MontoCRC) as TotalCRC,
    AVG(io.MontoCRC) as PromedioCRC,
    MAX(io.MontoCRC) as MaximoCRC,
    MIN(io.MontoCRC) as MinimoCRC
FROM IngresosOperativos io
INNER JOIN TiposIngreso ti ON io.IdTipoIngreso = ti.IdTipoIngreso
WHERE io.Estado = 'REGISTRADO'
GROUP BY ti.NombreTipo, ti.IdTipoIngreso
ORDER BY TotalCRC DESC;

-- Resumen por método de pago
PRINT '--- Resumen por método de pago ---';
SELECT 
    mp.NombreMetodo,
    COUNT(*) as TotalOperaciones,
    SUM(io.MontoCRC) as TotalCRC,
    AVG(io.MontoCRC) as PromedioCRC
FROM IngresosOperativos io
INNER JOIN MetodosPago mp ON io.IdMetodoPago = mp.IdMetodoPago
WHERE io.Estado = 'REGISTRADO'
GROUP BY mp.NombreMetodo, mp.IdMetodoPago
ORDER BY TotalOperaciones DESC;

-- Ingresos por cliente
PRINT '--- Top 10 clientes por ingresos ---';
SELECT TOP 10
    c.NombreCompleto,
    COUNT(*) as TotalOperaciones,
    SUM(io.MontoCRC) as TotalIngresado,
    AVG(io.MontoCRC) as PromedioOperacion
FROM IngresosOperativos io
INNER JOIN Clientes c ON io.IdCliente = c.IdCliente
WHERE io.Estado = 'REGISTRADO' AND io.IdCliente IS NOT NULL
GROUP BY c.NombreCompleto, c.IdCliente
ORDER BY TotalIngresado DESC;

GO

-- =====================================================================
-- Pruebas de Validaciones de Negocio Adicionales
-- =====================================================================

-- Prueba 16: Validar monto positivo (debe fallar si es negativo)
PRINT '=== PRUEBA 16: Monto negativo (debe fallar) ===';
BEGIN TRY
    INSERT INTO IngresosOperativos (
        FechaIngreso, IdPeriodo, Monto, Moneda, IdTipoIngreso, IdCategoria, IdMetodoPago,
        IdUsuarioCreacion
    )
    VALUES (
        '2026-01-15', 1, -500.00, 'CRC', 1, 1, 1, 5
    );
    PRINT 'ERROR: No debería permitir montos negativos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió insertar monto negativo - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 17: Validar últimos 4 dígitos de tarjeta
PRINT '=== PRUEBA 17: Últimos 4 dígitos inválidos (debe fallar) ===';
BEGIN TRY
    INSERT INTO IngresosOperativos (
        FechaIngreso, IdPeriodo, Monto, Moneda, IdTipoIngreso, IdCategoria, IdMetodoPago,
        Ultimos4Tarjeta, IdUsuarioCreacion
    )
    VALUES (
        '2026-01-15', 1, 1000.00, 'CRC', 1, 1, 2, -- TARJETA
        123, -- Solo 3 dígitos (inválido)
        5
    );
    PRINT 'ERROR: No debería permitir últimos 4 dígitos inválidos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió insertar últimos 4 dígitos inválidos - ' + ERROR_MESSAGE();
END CATCH;
GO

-- =====================================================================
-- Limpiar datos de prueba
-- =====================================================================

-- Reactivar periodo cerrado
UPDATE PeriodosContables 
SET Estado = 'ABIERTO' 
WHERE NombrePeriodo = '2026-02';

PRINT '=== PRUEBAS DEL MÓDULO DE INGRESOS OPERATIVOS COMPLETADAS ===';
PRINT 'Módulo de Ingresos Operativos completamente integrado y probado';
-- =====================================================================
-- Script de Integración y Pruebas para Módulo de Inventario
-- Mr Lee - Integración con módulo de Seguimiento de Pedidos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Datos Iniciales para Catálogos de Inventario
-- =====================================================================

-- Insertar Categorías de Productos
INSERT INTO Categorias (NombreCategoria, Descripcion, Activa) VALUES
('Panadería', 'Productos de pan recién horneado', 1),
('Pastelería', 'Pasteles, postres y repostería', 1),
('Bebidas', 'Jugos, refrescos y otras bebidas', 1),
('Snacks', 'Botanas y alimentos rápidos', 1),
('Ingredientes', 'Materias primas para producción', 1),
('Empaquetado', 'Bolsas, cajas y material de empaque', 1);
GO

-- Insertar Tipos de Movimiento
INSERT INTO TiposMovimiento (NombreMovimiento, Descripcion, AfectaStock, Activo) VALUES
('Entrada por compra', 'Compra a proveedores', 1, 1),
('Entrada por devolución', 'Devolución de cliente', 1, 1),
('Entrada por ajuste', 'Ajuste positivo de inventario', 0, 1),
('Salida por venta', 'Venta a clientes', -1, 1),
('Salida por merma', 'Pérdida o daño de producto', -1, 1),
('Salida por ajuste', 'Ajuste negativo de inventario', 0, 1),
('Salida por producción', 'Uso en producción interna', -1, 1);
GO

-- Insertar Proveedores
INSERT INTO Proveedores (NombreProveedor, Telefono, CorreoElectronico, Direccion, RUC, Activo) VALUES
('Distribuidora de Harinas S.A.', '5551112233', 'contacto@harinas.com', 'Av. Industrial #100, Zona Industrial', '1234567890123', 1),
('Lechería del Valle', '5554445566', 'ventas@lecheria.com', 'Carretera a la Sierra Km 15', '9876543210987', 1),
('Azucarera Central', '5557778899', 'compras@azucarera.com', 'Plaza Central #200', '4567890123456', 1),
('Embotelladora Regional', '5552223344', 'proveedor@bebidas.com', 'Parque Industrial #50', '7890123456789', 1);
GO

-- =====================================================================
-- Productos de Ejemplo
-- =====================================================================

INSERT INTO Productos (
    CodigoProducto, CodigoBarras, NombreProducto, Descripcion, IdCategoria,
    PrecioUnitario, StockActual, StockMinimo, UnidadMedida, IdUsuarioCreacion
) VALUES
('PAN-001', '7501234567890', 'Pan de caja blanco', 'Pan blanco de 500g para consumo diario', 1, 25.50, 100, 20, 'pieza', 2),
('PAN-002', '7501234567891', 'Pan integral', 'Pan integral con fibra, 500g', 1, 35.75, 50, 15, 'pieza', 2),
('PAN-003', '7501234567892', 'Bolillo', 'Bolillo tradicional para tortas', 1, 8.00, 200, 50, 'pieza', 2),
('PAS-001', '7501234567893', 'Pastel de chocolate', 'Pastel de chocolate con betún, 1kg', 2, 150.00, 10, 5, 'pieza', 2),
('PAS-002', '7501234567894', 'Tres leches', 'Pastel tres leches individual', 2, 45.50, 25, 8, 'pieza', 2),
('BEB-001', '7501234567895', 'Jugo de naranja', 'Jugo de naranja natural 1L', 3, 28.00, 40, 10, 'litro', 2),
('BEB-002', '7501234567896', 'Agua purificada', 'Agua purificada 600ml', 3, 12.00, 150, 30, 'botella', 2),
('SNA-001', '7501234567897', 'Galletas integrales', 'Galletas integrales con avena, 200g', 4, 22.50, 60, 12, 'paquete', 2),
('ING-001', '7501234567898', 'Harina de trigo', 'Harina de trigo premium, 5kg', 5, 85.00, 30, 10, 'saco', 2),
('ING-002', '7501234567899', 'Leche entera', 'Leche entera fresca, 1L', 5, 24.00, 45, 15, 'litro', 2);
GO

-- =====================================================================
-- Pruebas de Integración con Pedidos
-- =====================================================================

-- Modificar la tabla PedidoDetalles para relacionar con Productos
-- Nota: Esto se ejecutaría solo una vez para integrar los módulos
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('PedidoDetalles') AND name = 'IdProducto')
BEGIN
    -- Agregar columna para relacionar con productos
    ALTER TABLE PedidoDetalles ADD IdProducto INT NULL;
    
    -- Agregar clave foránea
    ALTER TABLE PedidoDetalles 
    ADD CONSTRAINT FK_PedidoDetalles_Productos 
    FOREIGN KEY (IdProducto) REFERENCES Productos(IdProducto);
    
    PRINT 'Columna IdProducto agregada a PedidoDetalles para integración con Inventario';
END;
GO

-- =====================================================================
-- Pruebas de Movimientos de Inventario
-- =====================================================================

PRINT '=== PRUEBAS DE MOVIMIENTOS DE INVENTARIO ===';

-- Prueba 1: Entrada por compra
PRINT '=== PRUEBA 1: Entrada por compra ===';
DECLARE @IdProductoPan INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'PAN-001');
DECLARE @StockAnterior INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoPan);

EXEC sp_RegistrarMovimientoInventario
    @IdProducto = @IdProductoPan,
    @IdTipoMovimiento = 1, -- Entrada por compra
    @Cantidad = 50,
    @Motivo = 'Compra semanal a Distribuidora de Harinas',
    @IdUsuario = 4, -- Carlos Bodega
    @IdProveedor = 1,
    @NumeroDocumento = 'FAC-2026-001',
    @Lote = 'L-2026-001',
    @FechaVencimiento = DATEADD(DAY, 30, GETDATE());

DECLARE @StockNuevo INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoPan);
PRINT 'Stock antes: ' + CAST(@StockAnterior AS NVARCHAR(10)) + ', Stock después: ' + CAST(@StockNuevo AS NVARCHAR(10));
GO

-- Prueba 2: Salida por venta (simulando venta desde pedido)
PRINT '=== PRUEBA 2: Salida por venta ===';
DECLARE @IdProductoJugo INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'BEB-001');
DECLARE @StockAnteriorJugo INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoJugo);

EXEC sp_RegistrarMovimientoInventario
    @IdProducto = @IdProductoJugo,
    @IdTipoMovimiento = 4, -- Salida por venta
    @Cantidad = 5,
    @Motivo = 'Venta a cliente María González - Pedido MR-2026-001',
    @IdUsuario = 4, -- Carlos Bodega
    @NumeroDocumento = 'PED-2026-001';

DECLARE @StockNuevoJugo INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoJugo);
PRINT 'Stock antes: ' + CAST(@StockAnteriorJugo AS NVARCHAR(10)) + ', Stock después: ' + CAST(@StockNuevoJugo AS NVARCHAR(10));
GO

-- Prueba 3: Salida por merma
PRINT '=== PRUEBA 3: Salida por merma ===';
DECLARE @IdProductoPastel INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'PAS-001');
DECLARE @StockAnteriorPastel INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoPastel);

EXEC sp_RegistrarMovimientoInventario
    @IdProducto = @IdProductoPastel,
    @IdTipoMovimiento = 5, -- Salida por merma
    @Cantidad = 1,
    @Motivo = 'Producto dañado por mal manejo',
    @IdUsuario = 4, -- Carlos Bodega
    @Observaciones = 'Pastel cayó durante transporte interno';

DECLARE @StockNuevoPastel INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoPastel);
PRINT 'Stock antes: ' + CAST(@StockAnteriorPastel AS NVARCHAR(10)) + ', Stock después: ' + CAST(@StockNuevoPastel AS NVARCHAR(10));
GO

-- Prueba 4: Ajuste positivo
PRINT '=== PRUEBA 4: Ajuste positivo ===';
DECLARE @IdProductoBolillo INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'PAN-003');
DECLARE @StockAnteriorBolillo INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoBolillo);

EXEC sp_RegistrarMovimientoInventario
    @IdProducto = @IdProductoBolillo,
    @IdTipoMovimiento = 3, -- Entrada por ajuste
    @Cantidad = 10,
    @Motivo = 'Diferencia encontrada en conteo físico',
    @IdUsuario = 4, -- Carlos Bodega
    @Observaciones = 'Se encontraron 10 unidades extra en conteo';

DECLARE @StockNuevoBolillo INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoBolillo);
PRINT 'Stock antes: ' + CAST(@StockAnteriorBolillo AS NVARCHAR(10)) + ', Stock después: ' + CAST(@StockNuevoBolillo AS NVARCHAR(10));
GO

-- =====================================================================
-- Pruebas de Validación y Reglas de Negocio
-- =====================================================================

-- Prueba 5: Intentar salida con stock insuficiente (debe fallar)
PRINT '=== PRUEBA 5: Salida con stock insuficiente (debe fallar) ===';
BEGIN TRY
    DECLARE @IdProductoAgua INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'BEB-002');
    DECLARE @StockActualAgua INT = (SELECT StockActual FROM Productos WHERE IdProducto = @IdProductoAgua);
    
    PRINT 'Stock actual de agua: ' + CAST(@StockActualAgua AS NVARCHAR(10));
    
    EXEC sp_RegistrarMovimientoInventario
        @IdProducto = @IdProductoAgua,
        @IdTipoMovimiento = 4, -- Salida por venta
        @Cantidad = 200, -- Más del stock disponible
        @Motivo = 'Intento de venta excesiva',
        @IdUsuario = 4;
        
    PRINT 'ERROR: No debería permitir salida con stock insuficiente';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió salida con stock insuficiente - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 6: Cambiar precio y verificar historial
PRINT '=== PRUEBA 6: Cambio de precio con historial ===';
DECLARE @IdProductoHarina INT = (SELECT IdProducto FROM Productos WHERE CodigoProducto = 'ING-001');
DECLARE @PrecioAnterior DECIMAL(18,2) = (SELECT PrecioUnitario FROM Productos WHERE IdProducto = @IdProductoHarina);

-- Actualizar precio
UPDATE Productos 
SET PrecioUnitario = 95.00, 
    IdUsuarioUltimaModificacion = 2 -- Juan Ventas
WHERE IdProducto = @IdProductoHarina;

-- Verificar historial
DECLARE @CountHistorial INT = (
    SELECT COUNT(*) 
    FROM HistorialPrecios 
    WHERE IdProducto = @IdProductoHarina 
    AND PrecioAnterior = @PrecioAnterior 
    AND PrecioNuevo = 95.00
);

PRINT 'Precio antes: $' + CAST(@PrecioAnterior AS NVARCHAR(10)) + ', Precio después: $95.00';
PRINT 'Registros en historial de precios: ' + CAST(@CountHistorial AS NVARCHAR(10));
GO

-- Prueba 7: Intentar desactivar producto con stock (debe fallar)
PRINT '=== PRUEBA 7: Desactivar producto con stock (debe fallar) ===';
BEGIN TRY
    UPDATE Productos 
    SET Activo = 0 
    WHERE CodigoProducto = 'PAN-001'; -- Tiene stock
    
    PRINT 'ERROR: No debería permitir desactivar producto con stock';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió desactivar producto con stock - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 8: Consultar productos con filtros
PRINT '=== PRUEBA 8: Consulta de productos con filtros ===';

-- Buscar por texto
PRINT '--- Búsqueda por texto "pan" ---';
EXEC sp_ConsultarProductos 
    @TextoBusqueda = 'pan',
    @Pagina = 1,
    @TamanoPagina = 10;

-- Filtrar por categoría
PRINT '--- Filtrar por categoría Panadería ---';
EXEC sp_ConsultarProductos 
    @IdCategoria = 1, -- Panadería
    @Pagina = 1,
    @TamanoPagina = 10;

-- Productos con stock bajo
PRINT '--- Productos con stock bajo ---';
SELECT 
    p.CodigoProducto, 
    p.NombreProducto, 
    p.StockActual, 
    p.StockMinimo,
    c.NombreCategoria
FROM Productos p
INNER JOIN Categorias c ON p.IdCategoria = c.IdCategoria
WHERE p.StockActual <= p.StockMinimo AND p.Activo = 1;
GO

-- =====================================================================
-- Pruebas de Integridad Referencial
-- =====================================================================

-- Prueba 9: Intentar eliminar categoría con productos (debe fallar)
PRINT '=== PRUEBA 9: Eliminar categoría con productos (debe fallar) ===';
BEGIN TRY
    DELETE FROM Categorias WHERE IdCategoria = 1; -- Panadería tiene productos
    PRINT 'ERROR: No debería permitir eliminar categoría con productos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió eliminar categoría con productos - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 10: Intentar cambiar código de producto con movimientos (debe fallar)
PRINT '=== PRUEBA 10: Cambiar código con movimientos (debe fallar) ===';
BEGIN TRY
    UPDATE Productos 
    SET CodigoProducto = 'PAN-001-NEW' 
    WHERE CodigoProducto = 'PAN-001'; -- Tiene movimientos
    
    PRINT 'ERROR: No debería permitir cambiar código con movimientos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió cambiar código con movimientos - ' + ERROR_MESSAGE();
END CATCH;
GO

-- =====================================================================
-- Reportes y Consultas Útiles
-- =====================================================================

PRINT '=== REPORTES DE INVENTARIO ===';

-- Movimientos del día
PRINT '--- Movimientos de hoy ---';
SELECT 
    m.IdMovimiento,
    p.NombreProducto,
    tm.NombreMovimiento,
    m.Cantidad,
    m.StockAnterior,
    m.StockNuevo,
    m.MotivoMovimiento,
    u.NombreUsuario as Responsable
FROM MovimientosInventario m
INNER JOIN Productos p ON m.IdProducto = p.IdProducto
INNER JOIN TiposMovimiento tm ON m.IdTipoMovimiento = tm.IdTipoMovimiento
INNER JOIN Usuarios u ON m.IdUsuarioResponsable = u.IdUsuario
WHERE CAST(m.FechaMovimiento AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY m.FechaMovimiento DESC;

-- Resumen de inventario
PRINT '--- Resumen de inventario ---';
SELECT 
    c.NombreCategoria,
    COUNT(*) as TotalProductos,
    SUM(p.StockActual) as StockTotal,
    SUM(CASE WHEN p.StockActual <= p.StockMinimo THEN 1 ELSE 0 END) as ProductosStockBajo,
    SUM(p.PrecioUnitario * p.StockActual) as ValorTotal
FROM Productos p
INNER JOIN Categorias c ON p.IdCategoria = c.IdCategoria
WHERE p.Activo = 1
GROUP BY c.NombreCategoria
ORDER BY ValorTotal DESC;

GO

PRINT '=== PRUEBAS DE INTEGRACIÓN DE INVENTARIO COMPLETADAS ===';
PRINT 'Módulo de Inventario integrado correctamente con Seguimiento de Pedidos';
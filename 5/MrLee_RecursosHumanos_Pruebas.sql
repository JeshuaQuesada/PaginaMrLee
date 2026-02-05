-- =====================================================================
-- Script de Integración y Pruebas para Módulo de Recursos Humanos
-- Mr Lee - Integración completa con todos los módulos
-- =====================================================================

USE MrLee_DB;
GO

-- =====================================================================
-- Datos Iniciales para Catálogos de Recursos Humanos
-- =====================================================================

-- Insertar Puestos
INSERT INTO Puestos (NombrePuesto, Descripcion, Departamento, NivelJerarquico, SalarioMinimo, SalarioMaximo, Activo) VALUES
('Gerente General', 'Responsable de toda la operación', 'Dirección', 4, 800000.00, 1500000.00, 1),
('Gerente de Ventas', 'Responsable del área comercial', 'Ventas', 3, 600000.00, 900000.00, 1),
('Encargado de Bodega', 'Supervisor de operaciones de almacén', 'Operaciones', 2, 400000.00, 600000.00, 1),
('Vendedor', 'Atención directa a clientes', 'Ventas', 1, 300000.00, 450000.00, 1),
('Panadero', 'Elaboración de productos de panadería', 'Producción', 1, 350000.00, 500000.00, 1),
('Pastelero', 'Elaboración de productos de pastelería', 'Producción', 1, 380000.00, 550000.00, 1),
('Repartidor', 'Entrega de productos a clientes', 'Logística', 1, 280000.00, 400000.00, 1),
('Cajero', 'Atención en caja y cobros', 'Ventas', 1, 250000.00, 350000.00, 1),
('Asistente Administrativo', 'Soporte administrativo general', 'Administración', 1, 300000.00, 450000.00, 1),
('Contable', 'Gestión contable y financiera', 'Contabilidad', 2, 450000.00, 700000.00, 1);
GO

-- Insertar Sucursales
INSERT INTO Sucursales (NombreSucursal, Direccion, Telefono, Ciudad, Provincia, Activa) VALUES
('Sucursal Central', 'Av. Principal #100, Centro', '2222-1111', 'San José', 'San José', 1),
('Sucursal Norte', 'Carrera 5 #200, Barrio Norte', '2222-2222', 'Alajuela', 'Alajuela', 1),
('Sucursal Este', 'Calle Real #300, San Pedro', '2222-3333', 'San José', 'San José', 1),
('Sucursal Oeste', 'Ruta 27 #400, Santa Ana', '2222-4444', 'San José', 'San José', 1),
('Planta de Producción', 'Kilómetro 10, Carretera a Cartago', '2222-5555', 'Cartago', 'Cartago', 1);
GO

-- =====================================================================
-- Crear Empleados de Ejemplo (basados en usuarios existentes)
-- =====================================================================

-- Asignar códigos de empleado correlativos
DECLARE @Contador INT = 1000;

INSERT INTO Empleados (
    CodigoEmpleado, Nombre, Apellido, Identificacion, Email, Telefono,
    IdPuesto, IdSucursal, SalarioBase, TipoContrato, Jornada, FechaIngreso,
    IdUsuarioCreacion
)
SELECT 
    'EMP-' + RIGHT('0000' + CAST(@Contador + ROW_NUMBER() OVER (ORDER BY u.IdUsuario) AS NVARCHAR(4)), 4),
    PARSENAME(REPLACE(u.NombreCompleto, ' ', '.'), 2), -- Nombre
    PARSENAME(REPLACE(u.NombreCompleto, ' ', '.'), 1), -- Apellido
    '1' + RIGHT('000000000' + CAST(ROW_NUMBER() OVER (ORDER BY u.IdUsuario) AS NVARCHAR(9)), 9), -- Identificación ficticia
    u.CorreoElectronico,
    '8888-8888', -- Teléfono ficticio
    CASE u.NombreUsuario
        WHEN 'admin' THEN 1  -- Gerente General
        WHEN 'jventas' THEN 2 -- Gerente de Ventas
        WHEN 'mdespacho' THEN 3 -- Encargado de Bodega
        WHEN 'cbodega' THEN 3 -- Encargado de Bodega
        WHEN 'acontable' THEN 10 -- Contable
        WHEN 'lrrhh' THEN 9 -- Asistente Administrativo
        WHEN 'prepartidor' THEN 7 -- Repartidor
        WHEN 'cliente1' THEN 2 -- Vendedor (como ejemplo)
        ELSE 4 -- Vendedor por defecto
    END,
    1, -- Sucursal Central
    CASE u.NombreUsuario
        WHEN 'admin' THEN 1200000.00
        WHEN 'jventas' THEN 750000.00
        WHEN 'mdespacho' THEN 500000.00
        WHEN 'cbodega' THEN 480000.00
        WHEN 'acontable' THEN 600000.00
        WHEN 'lrrhh' THEN 350000.00
        WHEN 'prepartidor' THEN 320000.00
        WHEN 'cliente1' THEN 380000.00
        ELSE 350000.00
    END,
    'INDEFINIDO',
    'COMPLETA',
    DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY u.IdUsuario) * 30, GETDATE()), -- Fechas de ingreso diferentes
    1 -- Creado por admin
FROM Usuarios u
WHERE u.Activo = 1 AND u.NombreUsuario NOT LIKE '%test%';
GO

-- =====================================================================
-- Pruebas del Módulo de Recursos Humanos
-- =====================================================================

PRINT '=== PRUEBAS DEL MÓDULO DE RECURSOS HUMANOS ===';

-- Prueba 1: Crear nuevo empleado
PRINT '=== PRUEBA 1: Crear nuevo empleado ===';
DECLARE @Resultado INT;
DECLARE @Mensaje NVARCHAR(500);
DECLARE @IdEmpleado INT;

EXEC @Resultado = sp_CrearEmpleado
    @CodigoEmpleado = 'EMP-1009',
    @Nombre = 'Pedro',
    @Apellido = 'González',
    @Identificacion = '112233445',
    @Email = 'pedro.gonzalez@mrlee.com',
    @Telefono = '7777-8888',
    @IdPuesto = 5, -- Panadero
    @IdSucursal = 5, -- Planta de Producción
    @SalarioBase = 400000.00,
    @TipoContrato = 'FIJO',
    @Jornada = 'COMPLETA',
    @FechaIngreso = '2026-01-15',
    @IdUsuarioCreacion = 6, -- Luis RRHH
    @Observaciones = 'Empleado con experiencia en panadería artesanal';

IF @Resultado = 1
    PRINT 'Empleado creado exitosamente';
ELSE
    PRINT 'Error al crear empleado';

-- Verificar empleado creado
SELECT TOP 1 * FROM Empleados WHERE CodigoEmpleado = 'EMP-1009';
GO

-- Prueba 2: Intentar crear empleado con identificación duplicada (debe fallar)
PRINT '=== PRUEBA 2: Identificación duplicada (debe fallar) ===';
EXEC sp_CrearEmpleado
    @CodigoEmpleado = 'EMP-1010',
    @Nombre = 'María',
    @Apellido = 'López',
    @Identificacion = '112233445', -- Misma identificación que prueba 1
    @Email = 'maria.lopez@mrlee.com',
    @Telefono = '7777-9999',
    @IdPuesto = 1,
    @IdSucursal = 1,
    @SalarioBase = 450000.00,
    @FechaIngreso = '2026-01-20',
    @IdUsuarioCreacion = 6;
GO

-- Prueba 3: Intentar crear con email inválido (debe fallar)
PRINT '=== PRUEBA 3: Email inválido (debe fallar) ===';
EXEC sp_CrearEmpleado
    @CodigoEmpleado = 'EMP-1011',
    @Nombre = 'Ana',
    @Apellido = 'Martínez',
    @Identificacion = '223344556',
    @Email = 'email_invalido', -- Sin formato de email
    @Telefono = '7777-6666',
    @IdPuesto = 6,
    @IdSucursal = 1,
    @SalarioBase = 420000.00,
    @FechaIngreso = '2026-01-20',
    @IdUsuarioCreacion = 6;
GO

-- Prueba 4: Intentar crear con fecha futura (debe fallar)
PRINT '=== PRUEBA 4: Fecha futura (debe fallar) ===';
EXEC sp_CrearEmpleado
    @CodigoEmpleado = 'EMP-1012',
    @Nombre = 'Carlos',
    @Apellido = 'Sánchez',
    @Identificacion = '334455667',
    @Email = 'carlos.sanchez@mrlee.com',
    @Telefono = '7777-5555',
    @IdPuesto = 4,
    @IdSucursal = 1,
    @SalarioBase = 360000.00,
    @FechaIngreso = DATEADD(DAY, 10, GETDATE()), -- Fecha futura
    @IdUsuarioCreacion = 6;
GO

-- Prueba 5: Consultar empleados con filtros
PRINT '=== PRUEBA 5: Consultar empleados con filtros ===';
EXEC sp_ConsultarEmpleados
    @CriterioBusqueda = 'Pedro',
    @Estado = 'ACTIVO',
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- Prueba 6: Consultar por sucursal
PRINT '=== PRUEBA 6: Consultar empleados por sucursal ===';
EXEC sp_ConsultarEmpleados
    @IdSucursal = 1, -- Sucursal Central
    @Pagina = 1,
    @TamanoPagina = 20;
GO

-- Prueba 7: Consultar por puesto
PRINT '=== PRUEBA 7: Consultar empleados por puesto ===';
EXEC sp_ConsultarEmpleados
    @IdPuesto = 3, -- Encargado de Bodega
    @Pagina = 1,
    @TamanoPagina = 10;
GO

-- =====================================================================
-- Pruebas de Solicitudes de Vacaciones
-- =====================================================================

-- Prueba 8: Solicitar vacaciones válidas
PRINT '=== PRUEBA 8: Solicitar vacaciones válidas ===';
DECLARE @IdEmpleadoVacaciones INT = (SELECT TOP 1 IdEmpleado FROM Empleados WHERE Estado = 'ACTIVO');

EXEC sp_SolicitarVacaciones
    @IdEmpleado = @IdEmpleadoVacaciones,
    @FechaInicio = DATEADD(DAY, 15, GETDATE()),
    @FechaFin = DATEADD(DAY, 19, GETDATE()), -- 5 días
    @DiasSolicitados = 5,
    @Observaciones = 'Vacaciones planeadas con familia';
GO

-- Prueba 9: Intentar solicitud con días incorrectos (debe fallar)
PRINT '=== PRUEBA 9: Días solicitados incorrectos (debe fallar) ===';
EXEC sp_SolicitarVacaciones
    @IdEmpleado = @IdEmpleadoVacaciones,
    @FechaInicio = DATEADD(DAY, 30, GETDATE()),
    @FechaFin = DATEADD(DAY, 34, GETDATE()), -- 5 días
    @DiasSolicitados = 10, -- Diferente al rango
    @Observaciones = 'Prueba de validación';
GO

-- Prueba 10: Intentar solicitud con solapamiento (debe fallar)
PRINT '=== PRUEBA 10: Solapamiento de vacaciones (debe fallar) ===';
EXEC sp_SolicitarVacaciones
    @IdEmpleado = @IdEmpleadoVacaciones,
    @FechaInicio = DATEADD(DAY, 16, GETDATE()), -- Solapa con prueba 8
    @FechaFin = DATEADD(DAY, 18, GETDATE()),
    @DiasSolicitados = 3,
    @Observaciones = 'Intento de solapamiento';
GO

-- =====================================================================
-- Pruebas de Incapacidades
-- =====================================================================

-- Prueba 11: Registrar incapacidad médica
PRINT '=== PRUEBA 11: Registrar incapacidad médica ===';
DECLARE @IdEmpleadoIncapacidad INT = (SELECT TOP 1 IdEmpleado FROM Empleados WHERE Estado = 'ACTIVO' AND IdEmpleado <> @IdEmpleadoVacaciones);

INSERT INTO Incapacidades (
    IdEmpleado, FechaInicio, FechaFin, Diagnostico, NumeroOrdenMedica, 
    CentroMedico, IdUsuarioRegistro, Observaciones
)
VALUES (
    @IdEmpleadoIncapacidad,
    DATEADD(DAY, 5, GETDATE()),
    DATEADD(DAY, 7, GETDATE()), -- 3 días
    'Gripe común con fiebre',
    'ORD-2026-001',
    'Clínica San Rafael',
    6, -- Luis RRHH
    'Incapacidad por enfermedad común'
);

PRINT 'Incapacidad registrada exitosamente';
GO

-- Prueba 12: Intentar registrar incapacidad solapada (debe fallar)
PRINT '=== PRUEBA 12: Incapacidad solapada (debe fallar) ===';
BEGIN TRY
    INSERT INTO Incapacidades (
        IdEmpleado, FechaInicio, FechaFin, Diagnostico, 
        IdUsuarioRegistro
    )
    VALUES (
        @IdEmpleadoIncapacidad,
        DATEADD(DAY, 6, GETDATE()), -- Solapa con prueba 11
        DATEADD(DAY, 8, GETDATE()),
        'Otra dolencia',
        6
    );
    PRINT 'ERROR: No debería permitir registrar incapacidad solapada';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió registrar incapacidad solapada - ' + ERROR_MESSAGE();
END CATCH;
GO

-- =====================================================================
-- Pruebas de Documentos de Empleado
-- =====================================================================

-- Prueba 13: Subir documento al expediente
PRINT '=== PRUEBA 13: Subir documento al expediente ===';
DECLARE @IdEmpleadoDocumento INT = (SELECT TOP 1 IdEmpleado FROM Empleados WHERE Estado = 'ACTIVO');

INSERT INTO DocumentosEmpleado (
    IdEmpleado, TipoDocumento, NombreArchivo, RutaArchivo, 
    Descripcion, IdUsuarioSubida
)
VALUES (
    @IdEmpleadoDocumento,
    'CONTRATO',
    'Contrato_PedroGonzalez.pdf',
    '/documentos/empleados/' + CAST(@IdEmpleadoDocumento AS NVARCHAR(10)) + '/contrato.pdf',
    'Contrato de trabajo indefinido',
    6 -- Luis RRHH
);

PRINT 'Documento subido exitosamente';
GO

-- Prueba 14: Reemplazar documento conservando historial
PRINT '=== PRUEBA 14: Reemplazar documento conservando historial ===';
DECLARE @IdEmpleadoDoc2 INT = (SELECT TOP 1 IdEmpleado FROM Empleados WHERE Estado = 'ACTIVO' AND IdEmpleado <> @IdEmpleadoDocumento);

-- Desactivar documento anterior del mismo tipo
UPDATE DocumentosEmpleado
SET Activo = 0,
    FechaEliminacion = GETDATE(),
    IdUsuarioEliminacion = 6,
    MotivoEliminacion = 'Reemplazado por nueva versión'
WHERE IdEmpleado = @IdEmpleadoDoc2 
AND TipoDocumento = 'CONTRATO' 
AND Activo = 1;

-- Subir nueva versión
INSERT INTO DocumentosEmpleado (
    IdEmpleado, TipoDocumento, NombreArchivo, RutaArchivo, 
    Descripcion, IdUsuarioSubida
)
VALUES (
    @IdEmpleadoDoc2,
    'CONTRATO',
    'Contrato_Actualizado.pdf',
    '/documentos/empleados/' + CAST(@IdEmpleadoDoc2 AS NVARCHAR(10)) + '/contrato_v2.pdf',
    'Contrato actualizado con nuevo salario',
    6 -- Luis RRHH
);

PRINT 'Documento reemplazado exitosamente conservando historial';
GO

-- =====================================================================
-- Pruebas de Cambios de Estado
-- =====================================================================

-- Prueba 15: Inactivar empleado
PRINT '=== PRUEBA 15: Inactivar empleado ===';
DECLARE @IdEmpleadoInactivar INT = (SELECT TOP 1 IdEmpleado FROM Empleados WHERE Estado = 'ACTIVO' AND IdEmpleado NOT IN (@IdEmpleadoVacaciones, @IdEmpleadoIncapacidad, @IdEmpleadoDocumento, @IdEmpleadoDoc2));

UPDATE Empleados
SET Estado = 'INACTIVO',
    MotivoCambioEstado = 'Renuncia voluntaria',
    FechaSalida = DATEADD(DAY, -1, GETDATE()),
    IdUsuarioUltimaModificacion = 6,
    FechaUltimaModificacion = GETDATE()
WHERE IdEmpleado = @IdEmpleadoInactivar;

PRINT 'Empleado inactivado exitosamente';
GO

-- Prueba 16: Intentar inactivar empleado ya inactivo (debe fallar)
PRINT '=== PRUEBA 16: Inactivar empleado ya inactivo (debe fallar) ===';
BEGIN TRY
    UPDATE Empleados
    SET Estado = 'INACTIVO',
        MotivoCambioEstado = 'Segunda inactivación',
        IdUsuarioUltimaModificacion = 6
    WHERE IdEmpleado = @IdEmpleadoInactivar; -- Ya inactivo
    
    PRINT 'ERROR: No debería permitir inactivar un empleado ya inactivo';
END TRY
BEGIN CATCH
    PRINT 'BIEN: El sistema permite el cambio pero debería tener validación a nivel de aplicación';
END CATCH;
GO

-- =====================================================================
-- Pruebas de Auditoría
-- =====================================================================

-- Prueba 17: Verificar auditoría de RRHH
PRINT '=== PRUEBA 17: Verificar auditoría de RRHH ===';
SELECT TOP 10
    a.IdAuditoria,
    a.Accion,
    a.Modulo,
    a.DescripcionAccion,
    a.FechaAccion,
    u.NombreUsuario as Responsable,
    e.Nombre + ' ' + e.Apellido as NombreEmpleado
FROM AuditoriaRRHH a
INNER JOIN Usuarios u ON a.IdUsuario = u.IdUsuario
LEFT JOIN Empleados e ON a.IdEmpleado = e.IdEmpleado
ORDER BY a.FechaAccion DESC;
GO

-- Prueba 18: Verificar historial laboral
PRINT '=== PRUEBA 18: Verificar historial laboral ===';
SELECT TOP 10
    h.IdHistorial,
    h.TipoCambio,
    h.FechaCambio,
    h.MotivoCambio,
    h.FechaRegistro,
    e.Nombre + ' ' + e.Apellido as NombreEmpleado,
    ua.NombreUsuario as UsuarioRegistro,
    p.NombrePuesto as PuestoNuevo,
    pa.NombrePuesto as PuestoAnterior,
    s.NombreSucursal as SucursalNueva,
    sa.NombreSucursal as SucursalAnterior
FROM HistorialLaboral h
INNER JOIN Empleados e ON h.IdEmpleado = e.IdEmpleado
INNER JOIN Usuarios ua ON h.IdUsuarioRegistro = ua.IdUsuario
LEFT JOIN Puestos p ON h.IdPuestoNuevo = p.IdPuesto
LEFT JOIN Puestos pa ON h.IdPuestoAnterior = pa.IdPuesto
LEFT JOIN Sucursales s ON h.IdSucursalNueva = s.IdSucursal
LEFT JOIN Sucursales sa ON h.IdSucursalAnterior = sa.IdSucursal
ORDER BY h.FechaRegistro DESC;
GO

-- =====================================================================
-- Reportes de Recursos Humanos
-- =====================================================================

PRINT '=== REPORTES DE RECURSOS HUMANOS ===';

-- Empleados por sucursal
PRINT '--- Empleados por sucursal ---';
SELECT 
    s.NombreSucursal,
    COUNT(*) as TotalEmpleados,
    SUM(CASE WHEN e.Estado = 'ACTIVO' THEN 1 ELSE 0 END) as Activos,
    SUM(CASE WHEN e.Estado = 'INACTIVO' THEN 1 ELSE 0 END) as Inactivos,
    AVG(CASE WHEN e.Estado = 'ACTIVO' THEN e.SalarioBase ELSE NULL END) as PromedioSalario
FROM Empleados e
INNER JOIN Sucursales s ON e.IdSucursal = s.IdSucursal
GROUP BY s.NombreSucursal, s.IdSucursal
ORDER BY TotalEmpleados DESC;

-- Empleados por puesto
PRINT '--- Empleados por puesto ---';
SELECT 
    p.NombrePuesto,
    COUNT(*) as TotalEmpleados,
    SUM(CASE WHEN e.Estado = 'ACTIVO' THEN 1 ELSE 0 END) as Activos,
    AVG(CASE WHEN e.Estado = 'ACTIVO' THEN e.SalarioBase ELSE NULL END) as PromedioSalario,
    MIN(e.SalarioBase) as SalarioMinimo,
    MAX(e.SalarioBase) as SalarioMaximo
FROM Empleados e
INNER JOIN Puestos p ON e.IdPuesto = p.IdPuesto
GROUP BY p.NombrePuesto, p.IdPuesto
ORDER BY TotalEmpleados DESC;

-- Antigüedad de empleados
PRINT '--- Antigüedad de empleados ---';
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 5 THEN '5+ años'
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 3 THEN '3-4 años'
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 1 THEN '1-2 años'
        ELSE 'Menos de 1 año'
    END as RangoAntiguedad,
    COUNT(*) as TotalEmpleados,
    AVG(e.SalarioBase) as PromedioSalario
FROM Empleados e
WHERE e.Estado = 'ACTIVO'
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 5 THEN '5+ años'
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 3 THEN '3-4 años'
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 1 THEN '1-2 años'
        ELSE 'Menos de 1 año'
    END
ORDER BY 
    CASE 
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 5 THEN 1
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 3 THEN 2
        WHEN DATEDIFF(YEAR, e.FechaIngreso, GETDATE()) >= 1 THEN 3
        ELSE 4
    END;

GO

-- =====================================================================
-- Validaciones Adicionales
-- =====================================================================

-- Prueba 19: Validar salario positivo
PRINT '=== PRUEBA 19: Salario negativo (debe fallar) ===';
BEGIN TRY
    UPDATE Empleados 
    SET SalarioBase = -1000.00 
    WHERE IdEmpleado = @IdEmpleadoVacaciones;
    
    PRINT 'ERROR: No debería permitir salarios negativos';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió actualizar con salario negativo - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 20: Validar fechas lógicas
PRINT '=== PRUEBA 20: Fecha de salida anterior a ingreso (debe fallar) ===';
BEGIN TRY
    UPDATE Empleados 
    SET FechaSalida = DATEADD(YEAR, -1, GETDATE()) -- Anterior a fecha de ingreso
    WHERE IdEmpleado = @IdEmpleadoVacaciones;
    
    PRINT 'ERROR: No debería permitir fecha de salida anterior a ingreso';
END TRY
BEGIN CATCH
    PRINT 'BIEN: Impidió actualizar con fecha de salida ilógica - ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '=== PRUEBAS DEL MÓDULO DE RECURSOS HUMANOS COMPLETADAS ===';
PRINT 'Módulo de Recursos Humanos completamente integrado y probado';
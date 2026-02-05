-- =====================================================================
-- Base de Datos MrLee_DB - Creación Inicial
-- SQL Server Management Studio
-- Sistema Integral para Mr Lee Panes
-- =====================================================================

-- Crear base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MrLee_DB')
BEGIN
    CREATE DATABASE MrLee_DB;
    PRINT 'Base de datos MrLee_DB creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La base de datos MrLee_DB ya existe.';
END;
GO

-- Usar la base de datos
USE MrLee_DB;
GO

PRINT 'Configuración inicial de MrLee_DB completada.';
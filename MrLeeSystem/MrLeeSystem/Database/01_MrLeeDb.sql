/*
  Mr Lee - Script SQL Server (DB + tablas principales)
  Módulos incluidos: Seguimiento de pedidos, Inventario, Usuarios/Accesos + Bitácora.

  Nota:
  - Este script crea la base de datos y el esquema básico.
  - El proyecto también incluye EF Core (AppDbContext). Si prefiere migraciones:
      1) Configure connection string en appsettings.json
      2) Ejecute: dotnet ef database update
*/

IF DB_ID('MrLeeDb') IS NULL
BEGIN
    CREATE DATABASE MrLeeDb;
END
GO

USE MrLeeDb;
GO

/*  Seguridad: Roles / Permisos / Usuarios  */

IF OBJECT_ID('dbo.Roles','U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles(
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL UNIQUE,
        IsActive BIT NOT NULL CONSTRAINT DF_Roles_IsActive DEFAULT(1)
    );
END
GO

IF OBJECT_ID('dbo.Permissions','U') IS NULL
BEGIN
    CREATE TABLE dbo.Permissions(
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL UNIQUE,
        Description NVARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Permissions_IsActive DEFAULT(1)
    );
END
GO

IF OBJECT_ID('dbo.RolePermissions','U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermissions(
        RoleId INT NOT NULL,
        PermissionId INT NOT NULL,
        CONSTRAINT PK_RolePermissions PRIMARY KEY(RoleId, PermissionId),
        CONSTRAINT FK_RolePermissions_Roles FOREIGN KEY(RoleId) REFERENCES dbo.Roles(Id),
        CONSTRAINT FK_RolePermissions_Permissions FOREIGN KEY(PermissionId) REFERENCES dbo.Permissions(Id)
    );
END
GO

IF OBJECT_ID('dbo.Users','U') IS NULL
BEGIN
    CREATE TABLE dbo.Users(
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FullName NVARCHAR(150) NOT NULL,
        Email NVARCHAR(200) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(500) NOT NULL,
        FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_Failed DEFAULT(0),
        LockoutEndUtc DATETIME2 NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT(1),
        RoleId INT NOT NULL,
        CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Users_Created DEFAULT(SYSUTCDATETIME()),
        UpdatedAtUtc DATETIME2 NULL,
        CONSTRAINT FK_Users_Roles FOREIGN KEY(RoleId) REFERENCES dbo.Roles(Id)
    );
END
GO

IF OBJECT_ID('dbo.ActionLogs','U') IS NULL
BEGIN
    CREATE TABLE dbo.ActionLogs(
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        AtUtc DATETIME2 NOT NULL CONSTRAINT DF_ActionLogs_At DEFAULT(SYSUTCDATETIME()),
        ActorUserId INT NULL,
        ActorEmail NVARCHAR(200) NOT NULL,
        Action NVARCHAR(80) NOT NULL,
        Entity NVARCHAR(80) NOT NULL,
        EntityId NVARCHAR(50) NOT NULL,
        DetailJson NVARCHAR(MAX) NOT NULL CONSTRAINT DF_ActionLogs_Detail DEFAULT('{}'),
        IpAddress NVARCHAR(60) NOT NULL CONSTRAINT DF_ActionLogs_Ip DEFAULT(''),
        CONSTRAINT FK_ActionLogs_Users FOREIGN KEY(ActorUserId) REFERENCES dbo.Users(Id)
    );
    CREATE INDEX IX_ActionLogs_AtUtc ON dbo.ActionLogs(AtUtc DESC);
END
GO

/*  Inventario  */

IF OBJECT_ID('dbo.Products','U') IS NULL
BEGIN
    CREATE TABLE dbo.Products(
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Sku NVARCHAR(50) NOT NULL UNIQUE,
        Name NVARCHAR(200) NOT NULL,
        Unit NVARCHAR(30) NOT NULL CONSTRAINT DF_Products_Unit DEFAULT('unidad'),
        UnitPrice DECIMAL(18,2) NOT NULL CONSTRAINT DF_Products_UnitPrice DEFAULT(0),
        CurrentStock DECIMAL(18,2) NOT NULL CONSTRAINT DF_Products_CurrentStock DEFAULT(0),
        IsActive BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT(1),
        CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Products_Created DEFAULT(SYSUTCDATETIME())
    );
END
GO

IF OBJECT_ID('dbo.StockMovements','U') IS NULL
BEGIN
    CREATE TABLE dbo.StockMovements(
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ProductId INT NOT NULL,
        Type INT NOT NULL, -- 1=Entry, 2=Exit, 3=Adjustment
        Quantity DECIMAL(18,2) NOT NULL,
        Reason NVARCHAR(300) NOT NULL CONSTRAINT DF_StockMovements_Reason DEFAULT(''),
        AtUtc DATETIME2 NOT NULL CONSTRAINT DF_StockMovements_At DEFAULT(SYSUTCDATETIME()),
        CreatedByUserId INT NULL,
        CreatedByEmail NVARCHAR(200) NOT NULL CONSTRAINT DF_StockMovements_Email DEFAULT(''),
        CONSTRAINT FK_StockMovements_Products FOREIGN KEY(ProductId) REFERENCES dbo.Products(Id),
        CONSTRAINT FK_StockMovements_Users FOREIGN KEY(CreatedByUserId) REFERENCES dbo.Users(Id),
        CONSTRAINT CK_StockMovements_Type CHECK (Type IN (1,2,3))
    );
    CREATE INDEX IX_StockMovements_ProductId_AtUtc ON dbo.StockMovements(ProductId, AtUtc DESC);
END
GO

/*  Seguimiento de pedidos  */

IF OBJECT_ID('dbo.Orders','U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders(
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TrackingNumber NVARCHAR(40) NOT NULL UNIQUE,
        CustomerName NVARCHAR(150) NOT NULL,
        CustomerPhone NVARCHAR(50) NOT NULL,
        DeliveryAddress NVARCHAR(300) NOT NULL,
        Notes NVARCHAR(500) NOT NULL CONSTRAINT DF_Orders_Notes DEFAULT(''),
        Status INT NOT NULL CONSTRAINT DF_Orders_Status DEFAULT(1), -- 1=Recibido
        CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Orders_Created DEFAULT(SYSUTCDATETIME()),
        UpdatedAtUtc DATETIME2 NULL,
        CONSTRAINT CK_Orders_Status CHECK (Status IN (1,2,3,4,5))
    );
    CREATE INDEX IX_Orders_CreatedAtUtc ON dbo.Orders(CreatedAtUtc DESC);
END
GO

IF OBJECT_ID('dbo.OrderItems','U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItems(
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId BIGINT NOT NULL,
        ProductId INT NOT NULL,
        Quantity DECIMAL(18,2) NOT NULL,
        UnitPrice DECIMAL(18,2) NOT NULL,
        CONSTRAINT FK_OrderItems_Orders FOREIGN KEY(OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
        CONSTRAINT FK_OrderItems_Products FOREIGN KEY(ProductId) REFERENCES dbo.Products(Id),
        CONSTRAINT CK_OrderItems_Qty CHECK (Quantity > 0)
    );
    CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);
END
GO

IF OBJECT_ID('dbo.OrderStatusHistory','U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderStatusHistory(
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        OrderId BIGINT NOT NULL,
        Status INT NOT NULL,
        Comment NVARCHAR(300) NOT NULL CONSTRAINT DF_OrderStatusHistory_Comment DEFAULT(''),
        AtUtc DATETIME2 NOT NULL CONSTRAINT DF_OrderStatusHistory_At DEFAULT(SYSUTCDATETIME()),
        ChangedByUserId INT NULL,
        ChangedByEmail NVARCHAR(200) NOT NULL CONSTRAINT DF_OrderStatusHistory_Email DEFAULT(''),
        CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY(OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
        CONSTRAINT FK_OrderStatusHistory_Users FOREIGN KEY(ChangedByUserId) REFERENCES dbo.Users(Id),
        CONSTRAINT CK_OrderStatusHistory_Status CHECK (Status IN (1,2,3,4,5))
    );
    CREATE INDEX IX_OrderStatusHistory_OrderId_AtUtc ON dbo.OrderStatusHistory(OrderId, AtUtc DESC);
END
GO

/*  Seed mínimo (Roles + Permisos)  */

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Name = 'Administrador')
BEGIN
    INSERT INTO dbo.Roles(Name, IsActive) VALUES
    ('Administrador', 1),
    ('Cajero',        1),
    ('Panadero',      1),
    ('Repartidor',    1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Permissions)
BEGIN
    INSERT INTO dbo.Permissions(Code, Description, IsActive) VALUES
    ('USR.VIEW',      'Ver usuarios',                     1),
    ('USR.MANAGE',    'Administrar usuarios',             1),
    ('USR.AUDIT',     'Ver bitácora',                     1),
    ('INV.VIEW',      'Ver inventario',                   1),
    ('INV.MANAGE',    'Administrar productos',            1),
    ('INV.MOVEMENTS', 'Registrar movimientos inventario', 1),
    ('ORD.VIEW',      'Ver pedidos',                      1),
    ('ORD.MANAGE',    'Administrar pedidos',              1),
    ('ORD.STATUS',    'Actualizar estado del pedido',     1);
END
GO

-- Dar todos los permisos al Administrador
DECLARE @AdminRoleId INT = (SELECT TOP 1 Id FROM dbo.Roles WHERE Name='Administrador');
IF NOT EXISTS (SELECT 1 FROM dbo.RolePermissions WHERE RoleId=@AdminRoleId)
BEGIN
    INSERT INTO dbo.RolePermissions(RoleId, PermissionId)
    SELECT @AdminRoleId, p.Id FROM dbo.Permissions p;
END
GO

/*  Seed Productos - Panadería  */

IF NOT EXISTS (SELECT 1 FROM dbo.Products)
BEGIN
    INSERT INTO dbo.Products(Sku, Name, Unit, UnitPrice, CurrentStock, IsActive) VALUES
    -- Panes
    ('PAN-001', 'Pan francés',           'unidad',  0.15, 500, 1),
    ('PAN-002', 'Pan de molde blanco',   'bolsa',   2.50,  80, 1),
    ('PAN-003', 'Pan integral',          'bolsa',   3.00,  60, 1),
    ('PAN-004', 'Croissant mantequilla', 'unidad',  1.20, 150, 1),
    ('PAN-005', 'Baguette',              'unidad',  1.80, 100, 1),
    -- Dulces y pasteles
    ('DUL-001', 'Empanada de queso',     'unidad',  0.80, 200, 1),
    ('DUL-002', 'Empanada de pollo',     'unidad',  1.00, 180, 1),
    ('DUL-003', 'Pastel de chocolate',   'porción', 2.00,  40, 1),
    ('DUL-004', 'Rosca de canela',       'unidad',  3.50,  30, 1),
    ('DUL-005', 'Galletas de avena',     'bolsa',   2.20,  90, 1),
    -- Tortas
    ('TOR-001', 'Torta de cumpleaños',   'unidad', 25.00,   5, 1),
    ('TOR-002', 'Torta de bodas (piso)', 'piso',   60.00,   2, 1),
    -- Insumos
    ('INS-001', 'Harina de trigo 50 kg', 'saco',   18.00,  20, 1),
    ('INS-002', 'Azúcar blanca 50 kg',   'saco',   22.00,  15, 1),
    ('INS-003', 'Mantequilla 1 kg',      'kg',      5.50,  30, 1),
    ('INS-004', 'Levadura seca 500 g',   'paquete', 3.00,  25, 1),
    ('INS-005', 'Sal 1 kg',              'kg',      0.80,  40, 1);
END
GO

/*  Seed Pedido de ejemplo  */

IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    INSERT INTO dbo.Orders(TrackingNumber, CustomerName, CustomerPhone, DeliveryAddress, Notes, Status)
    VALUES ('TRK-20240001', 'María González', '0987654321',
            'Av. Bolívar 123, Local 1', 'Entregar antes de las 8 am', 1);

    DECLARE @OrderId BIGINT = SCOPE_IDENTITY();

    INSERT INTO dbo.OrderItems(OrderId, ProductId, Quantity, UnitPrice)
    SELECT @OrderId, Id, 1,  UnitPrice FROM dbo.Products WHERE Sku = 'TOR-001'
    UNION ALL
    SELECT @OrderId, Id, 10, UnitPrice FROM dbo.Products WHERE Sku = 'DUL-003'
    UNION ALL
    SELECT @OrderId, Id, 20, UnitPrice FROM dbo.Products WHERE Sku = 'PAN-004';

    INSERT INTO dbo.OrderStatusHistory(OrderId, Status, Comment, ChangedByEmail)
    VALUES (@OrderId, 1, 'Pedido recibido', 'admin@panaderia.com');
END
GO
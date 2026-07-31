# Mr Lee System

Sistema web de gestión interna y portal de clientes para Mr Lee.  
Permite administrar pedidos, inventario, ingresos operativos, usuarios, clientes y procesos de RRHH desde un panel administrativo.

![.NET 8](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet&logoColor=white)
![ASP.NET Core MVC](https://img.shields.io/badge/ASP.NET%20Core-MVC-blue)
![SQL Server](https://img.shields.io/badge/Database-SQL%20Server-red)
![EF Core](https://img.shields.io/badge/ORM-EF%20Core-purple)

## Características

- **Pedidos:** creación de pedidos, número de seguimiento único, consulta, cambio de estado e historial.
- **Inventario:** catálogo de productos, existencias, movimientos de entrada/salida/ajuste y activación/inactivación de productos.
- **Ingresos operativos:** registro, edición, anulación, adjuntos, resumen, exportación y control de períodos.
- **Usuarios y accesos:** usuarios internos, asignación de roles, permisos por módulo, reset de contraseña y bitácora.
- **Portal de clientes:** registro, login, perfil, pedidos, carrito/tienda, preferencias y baja/reactivación de cuenta.
- **RRHH:** empleados, vacaciones, incapacidades, documentos de expediente, contactos, cuentas bancarias y movimientos laborales.

## Tecnologías

- ASP.NET Core MVC `net8.0`
- Entity Framework Core
- SQL Server
- Autenticación por cookies
- Autorización por roles y permisos
- Bootstrap 5

## Requisitos

- Visual Studio 2022 o VS Code
- .NET 8 SDK
- SQL Server, LocalDB, Express o Azure SQL

## Configuración

1. Abrir la solución `MrLeeSystem.sln`.
2. Configurar la cadena de conexión en `src/MrLee.Web/appsettings.json`.
3. Crear o actualizar la base de datos usando los scripts SQL disponibles.
4. Ejecutar el proyecto web `src/MrLee.Web`.

## Base de datos

El sistema usa SQL Server mediante EF Core.  
El arranque ejecuta `Database.Migrate()` y realiza seed de datos iniciales, pero este repositorio no incluye migraciones EF visibles, por lo que para una base nueva se recomienda usar los scripts SQL.

Scripts disponibles actualmente:

- `MrLeeSystem-main/Database/01_MrLeeDb.sql`
- `MrLeeSystem-main/Database/Clientes.sql`
- `MrLeeSystem-main/Database/Rrhh.sql`

## Seed inicial

Al iniciar el sistema se crean permisos, roles básicos y un usuario administrador cuando la tabla de usuarios está vacía.

Roles iniciales:

- Administrador
- Ventas
- Bodega
- Despacho

Las credenciales iniciales se configuran desde `appsettings.json` en la sección `Seed`.

## Rutas principales

- Login administrativo: `/Account/Login`
- Pedidos: `/Orders`
- Inventario: `/Inventory`
- Usuarios: `/Users`
- Bitácora: `/Users/Audit`
- Ingresos: `/OperatingIncome`
- Empleados: `/Empleados`
- Vacaciones: `/Vacaciones/Pendientes`
- Portal de clientes: `/Portal`
- Tienda/Carrito: `/Carrito/Tienda`

## Seguridad

- Contraseñas internas con PBKDF2, SHA256 y 100,000 iteraciones.
- Bloqueo temporal después de 5 intentos fallidos.
- Control de acceso por permisos.
- Bitácora de acciones en `ActionLogs`.

## Estructura

- `MrLeeSystem.sln`
- `src/MrLee.Web/`
- `src/MrLee.Web/wwwroot/img/logo.jpeg`
- `MrLeeSystem-main/Database/`
- `Docs/`

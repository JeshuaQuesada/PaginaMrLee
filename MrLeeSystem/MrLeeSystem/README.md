# Sistema Mr Lee

Este ZIP incluye un proyecto **ASP.NET Core MVC (net8.0)** con **arquitectura MVC**, **EF Core (SQL Server)**, autenticación por **cookies**, control de acceso por **roles/permisos**, y los 3 módulos solicitados:

- **Seguimiento de pedidos**: crear pedido, número único, consultar, actualizar estado y ver historial/timeline.

- **Inventario**: catálogo de productos, existencias, entradas/salidas/ajustes (movimientos) y desactivar productos.

- **Usuarios y accesos**: CRUD de usuarios, roles/permisos, activar/desactivar, reset de contraseña y bitácora.



---

## Requisitos

- Visual Studio 2022 (o VS Code) con .NET 8
- SQL Server (LocalDB o Express)

---

## 1) Base de datos

### Ejecutar script SQL
1. Abra `Database/01_MrLeeDb.sql` en SQL Server Management Studio.
2. Ejecútelo (crea `MrLeeDb` y tablas).

### Con migraciones EF Core
El proyecto incluye `db.Database.Migrate()` en el arranque.
1. Configure el connection string en `src/MrLee.Web/appsettings.json`
2. Ejecute el proyecto y se crearán tablas automáticamente.

---

## 2) Credenciales iniciales (admin)

Al levantar el sistema por primera vez, se hace **seed** de:
- Roles básicos (Administrador, Ventas, Bodega, Despacho)
- Permisos del sistema
- Usuario admin (si la tabla Users está vacía)

Se leen de `appsettings.json`:

```json
"Seed": {
  "AdminEmail": "admin@mrlee.local",
  "AdminPassword": "Admin123!"
}
```

---

## 3) Módulos incluidos (rutas)

- Pedidos: `/Orders`
- Inventario: `/Inventory`
- Usuarios: `/Users`
- Bitácora: `/Users/Audit`
- Login: `/Account/Login`

---

## 4) Notas técnicas

- **Passwords**: PBKDF2 (SHA256, 100k iteraciones) almacenado en `Users.PasswordHash`.
- **Bloqueo por intentos fallidos**: al 5to intento, bloqueo 15 minutos (requerimiento SEGR-006).
- **Bitácora**: tabla `ActionLogs`.

---

## Estructura del repositorio

- `MrLeeSystem.sln`
- `src/MrLee.Web/` (proyecto web)
- `Database/01_MrLeeDb.sql` (script SQL Server)
- `wwwroot/img/logo.jpeg` (logo)


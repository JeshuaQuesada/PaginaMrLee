using Microsoft.EntityFrameworkCore;
using MrLee.Web.Models;
using MrLee.Web.Security;
using MrLee.Web.Services;

namespace MrLee.Web.Data;

public static class SeedData
{
    public static async Task EnsureSeedAsync(IServiceProvider sp)
    {
        using var scope = sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var pwd = scope.ServiceProvider.GetRequiredService<PasswordService>();
        var cfg = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        await db.Database.ExecuteSqlRawAsync(@"
IF COL_LENGTH('dbo.Users', 'MustChangePassword') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD MustChangePassword BIT NOT NULL CONSTRAINT DF_Users_MustChangePassword DEFAULT(0);
END
IF COL_LENGTH('dbo.Users', 'TemporaryPasswordIssuedUtc') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD TemporaryPasswordIssuedUtc DATETIME2 NULL;
END");

        // Permissions
        var existingPermissionCodes = await db.Permissions.Select(p => p.Code).ToListAsync();
        var missingPermissions = PermissionCatalog.All
            .Where(code => !existingPermissionCodes.Contains(code))
            .Select(code => new Permission { Code = code, Description = code })
            .ToList();

        if (missingPermissions.Count > 0)
        {
            db.Permissions.AddRange(missingPermissions);
            await db.SaveChangesAsync();
        }

        var rolePermissions = new Dictionary<string, string[]>
        {
            ["Administrador"] = PermissionCatalog.All,
            ["Ventas"] = new[] { PermissionCatalog.ORD_VIEW, PermissionCatalog.ORD_MANAGE },
            ["Despacho"] = new[] { PermissionCatalog.ORD_VIEW, PermissionCatalog.ORD_STATUS },
            ["Bodega"] = new[] { PermissionCatalog.INV_VIEW, PermissionCatalog.INV_MANAGE, PermissionCatalog.INV_MOVEMENTS },
            ["Contabilidad"] = new[] { PermissionCatalog.ING_VIEW, PermissionCatalog.ING_MANAGE, PermissionCatalog.ING_AUDIT },
            ["Recursos Humanos"] = new[] { PermissionCatalog.RRHH_VIEW, PermissionCatalog.RRHH_MANAGE, PermissionCatalog.RRHH_VACACIONES }
        };

        foreach (var roleName in rolePermissions.Keys)
        {
            var role = await db.Roles.FirstOrDefaultAsync(r => r.Name == roleName);
            if (role == null)
            {
                db.Roles.Add(new Role { Name = roleName, IsActive = true });
            }
            else if (!role.IsActive)
            {
                role.IsActive = true;
            }
        }
        await db.SaveChangesAsync();

        var permissionsByCode = await db.Permissions.ToDictionaryAsync(p => p.Code, p => p.Id);
        var rolesByName = await db.Roles.ToDictionaryAsync(r => r.Name, r => r.Id);

        foreach (var (roleName, permissionCodes) in rolePermissions)
        {
            var roleId = rolesByName[roleName];
            var currentPermissionIds = await db.RolePermissions
                .Where(rp => rp.RoleId == roleId)
                .Select(rp => rp.PermissionId)
                .ToListAsync();

            var missingRolePermissions = permissionCodes
                .Where(permissionsByCode.ContainsKey)
                .Select(code => permissionsByCode[code])
                .Where(permissionId => !currentPermissionIds.Contains(permissionId))
                .Select(permissionId => new RolePermission { RoleId = roleId, PermissionId = permissionId })
                .ToList();

            if (missingRolePermissions.Count > 0)
                db.RolePermissions.AddRange(missingRolePermissions);
        }
        await db.SaveChangesAsync();

        var admin = await db.Roles.FirstAsync(r => r.Name == "Administrador");

        // Seed admin user (if none)
        if (!await db.Users.AnyAsync())
        {
            var adminEmail = cfg["Seed:AdminEmail"] ?? "admin@mrlee.local";
            var adminPass = cfg["Seed:AdminPassword"] ?? "Admin123!";

            var hash = pwd.HashPassword(adminPass);
            db.Users.Add(new AppUser
            {
                FullName = "Administrador",
                Email = adminEmail,
                PasswordHash = hash,
                RoleId = admin.Id,
                IsActive = true
            });
            await db.SaveChangesAsync();
        }
    }
}

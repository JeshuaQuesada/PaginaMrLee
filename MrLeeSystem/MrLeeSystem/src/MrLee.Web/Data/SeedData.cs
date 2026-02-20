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

        // Permissions
        if (!await db.Permissions.AnyAsync())
        {
            db.Permissions.AddRange(PermissionCatalog.All.Select(code =>
                new Permission { Code = code, Description = code }));
            await db.SaveChangesAsync();
        }

        // Roles
        var adminRole = await db.Roles.FirstOrDefaultAsync(r => r.Name == "Administrador");
        if (adminRole == null)
        {
            adminRole = new Role { Name = "Administrador", IsActive = true };
            db.Roles.Add(adminRole);

            var ventasRole = new Role { Name = "Ventas", IsActive = true };
            var bodegaRole = new Role { Name = "Bodega", IsActive = true };
            var despachoRole = new Role { Name = "Despacho", IsActive = true };

            db.Roles.AddRange(ventasRole, bodegaRole, despachoRole);
            await db.SaveChangesAsync();
        }

        // Assign ALL permissions to Admin
        var admin = await db.Roles.FirstAsync(r => r.Name == "Administrador");
        var adminHas = await db.RolePermissions.Where(rp => rp.RoleId == admin.Id).AnyAsync();
        if (!adminHas)
        {
            var permIds = await db.Permissions.Select(p => p.Id).ToListAsync();
            db.RolePermissions.AddRange(permIds.Select(pid => new RolePermission { RoleId = admin.Id, PermissionId = pid }));
            await db.SaveChangesAsync();
        }

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

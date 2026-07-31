using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;

namespace MrLee.Web.Security;

public sealed class PermissionService : IPermissionService
{
    private readonly AppDbContext _db;

    public PermissionService(AppDbContext db) => _db = db;

    public async Task<IReadOnlyList<string>> GetPermissionsForUserAsync(int userId)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || !user.IsActive) return Array.Empty<string>();

        var perms = await _db.RolePermissions
            .Where(rp => rp.RoleId == user.RoleId)
            .Select(rp => rp.Permission.Code)
            .ToListAsync();

        return perms;
    }

    public async Task<bool> UserHasPermissionAsync(int userId, string permissionCode)
    {
        var perms = await GetPermissionsForUserAsync(userId);
        return perms.Contains(permissionCode);
    }
}

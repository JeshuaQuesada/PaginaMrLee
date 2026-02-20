namespace MrLee.Web.Security;

public interface IPermissionService
{
    Task<bool> UserHasPermissionAsync(int userId, string permissionCode);
    Task<IReadOnlyList<string>> GetPermissionsForUserAsync(int userId);
}

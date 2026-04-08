using Microsoft.AspNetCore.Authorization;

namespace MrLee.Web.Security;

public sealed class PermissionRequirement : IAuthorizationRequirement
{
    public PermissionRequirement(string permission) => Permission = permission;
    public string Permission { get; }
}

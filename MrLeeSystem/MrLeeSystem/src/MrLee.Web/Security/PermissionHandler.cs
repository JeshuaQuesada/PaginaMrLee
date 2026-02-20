using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace MrLee.Web.Security;

public sealed class PermissionHandler : AuthorizationHandler<PermissionRequirement>
{
    private readonly IPermissionService _permissions;

    public PermissionHandler(IPermissionService permissions)
    {
        _permissions = permissions;
    }

    protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
    {
        var userIdStr = context.User.FindFirstValue("UserId");
        if (!int.TryParse(userIdStr, out var userId))
            return;

        if (await _permissions.UserHasPermissionAsync(userId, requirement.Permission))
            context.Succeed(requirement);
    }
}

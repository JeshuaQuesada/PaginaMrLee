using System.Security.Claims;

namespace MrLee.Web.Security;

public static class ClaimsExtensions
{
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var val = user.FindFirstValue("UserId");
        return int.TryParse(val, out var id) ? id : null;
    }

    public static string GetEmail(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Email) ?? "";

    public static string GetRoleName(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Role) ?? "";
}

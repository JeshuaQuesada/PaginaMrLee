namespace MrLee.Web.Security;

public static class PermissionCatalog
{
    // Keep codes short + consistent. Add more as you expand modules.
    public const string USERS_VIEW = "USR.VIEW";
    public const string USERS_MANAGE = "USR.MANAGE";
    public const string USERS_AUDIT = "USR.AUDIT";

    public const string INV_VIEW = "INV.VIEW";
    public const string INV_MANAGE = "INV.MANAGE";
    public const string INV_MOVEMENTS = "INV.MOVEMENTS";

    public const string ORD_VIEW = "ORD.VIEW";
    public const string ORD_MANAGE = "ORD.MANAGE";
    public const string ORD_STATUS = "ORD.STATUS";

    public static readonly string[] All = new[]
    {
        USERS_VIEW, USERS_MANAGE, USERS_AUDIT,
        INV_VIEW, INV_MANAGE, INV_MOVEMENTS,
        ORD_VIEW, ORD_MANAGE, ORD_STATUS
    };
}

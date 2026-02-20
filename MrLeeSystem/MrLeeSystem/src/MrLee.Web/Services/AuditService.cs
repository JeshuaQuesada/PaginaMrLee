using System.Text.Json;
using Microsoft.AspNetCore.Http;
using MrLee.Web.Data;
using MrLee.Web.Models;

namespace MrLee.Web.Services;

public sealed class AuditService
{
    private readonly AppDbContext _db;
    private readonly IHttpContextAccessor _http;

    public AuditService(AppDbContext db, IHttpContextAccessor http)
    {
        _db = db;
        _http = http;
    }

    public async Task LogAsync(int? actorUserId, string actorEmail, string action, string entity, string entityId, object? detail = null)
    {
        var ip = _http.HttpContext?.Connection?.RemoteIpAddress?.ToString() ?? "";

        var log = new ActionLog
        {
            ActorUserId = actorUserId,
            ActorEmail = actorEmail ?? "",
            Action = action,
            Entity = entity,
            EntityId = entityId ?? "",
            DetailJson = JsonSerializer.Serialize(detail ?? new { }),
            IpAddress = ip
        };
        _db.ActionLogs.Add(log);
        await _db.SaveChangesAsync();
    }
}

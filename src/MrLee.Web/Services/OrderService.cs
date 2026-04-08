using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;

namespace MrLee.Web.Services;

public sealed class OrderService
{
    private readonly AppDbContext _db;
    private readonly InventoryService _inventory;

    public OrderService(AppDbContext db, InventoryService inventory)
    {
        _db = db;
        _inventory = inventory;
    }

    public async Task<string> GenerateTrackingNumberAsync()
    {
        // MRLEE-YYYYMMDD-XXXX
        var date = DateTime.UtcNow.ToString("yyyyMMdd");
        var rnd = Random.Shared.Next(1000, 9999);
        var code = $"MRLEE-{date}-{rnd}";
        // Ensure unique
        while (await _db.Orders.AnyAsync(o => o.TrackingNumber == code))
        {
            rnd = Random.Shared.Next(1000, 9999);
            code = $"MRLEE-{date}-{rnd}";
        }
        return code;
    }

    public async Task AppendHistoryAsync(long orderId, OrderStatus status, string comment, int? userId, string userEmail)
    {
        _db.OrderStatusHistory.Add(new OrderStatusHistory
        {
            OrderId = orderId,
            Status = status,
            Comment = comment ?? "",
            ChangedByUserId = userId,
            ChangedByEmail = userEmail ?? ""
        });
        await _db.SaveChangesAsync();
    }

    public async Task UpdateStatusAsync(long orderId, OrderStatus newStatus, string comment, int? userId, string userEmail)
    {
        var order = await _db.Orders
            .Include(o => o.Items)
            .FirstAsync(o => o.Id == orderId);

        order.Status = newStatus;
        order.UpdatedAtUtc = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await AppendHistoryAsync(orderId, newStatus, comment, userId, userEmail);

        // Inventory integration: on "Entregado", register exits for items (simple approach)
        if (newStatus == OrderStatus.Entregado)
        {
            foreach (var item in order.Items)
            {
                await _inventory.AddMovementAsync(item.ProductId, StockMovementType.Exit, item.Quantity, $"Salida por pedido {order.TrackingNumber}", userId, userEmail);
            }
        }
    }
}

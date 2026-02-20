using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;

namespace MrLee.Web.Services;

public sealed class InventoryService
{
    private readonly AppDbContext _db;

    public InventoryService(AppDbContext db) => _db = db;

    public async Task RecalculateProductStockAsync(int productId)
    {
        var movements = await _db.StockMovements
            .Where(m => m.ProductId == productId)
            .AsNoTracking()
            .ToListAsync();

        decimal stock = 0m;
        foreach (var m in movements)
        {
            var sign = m.Type switch
            {
                StockMovementType.Entry => 1m,
                StockMovementType.Exit => -1m,
                StockMovementType.Adjustment => 1m,
                _ => 0m
            };
            stock += sign * m.Quantity;
        }

        var product = await _db.Products.FirstAsync(p => p.Id == productId);
        product.CurrentStock = stock;
        await _db.SaveChangesAsync();
    }

    public async Task AddMovementAsync(int productId, StockMovementType type, decimal quantity, string reason, int? userId, string userEmail)
    {
        if (quantity == 0m) throw new ArgumentException("La cantidad no puede ser 0.");

        var movement = new StockMovement
        {
            ProductId = productId,
            Type = type,
            Quantity = quantity,
            Reason = reason ?? "",
            CreatedByUserId = userId,
            CreatedByEmail = userEmail ?? ""
        };

        _db.StockMovements.Add(movement);
        await _db.SaveChangesAsync();

        await RecalculateProductStockAsync(productId);
    }
}

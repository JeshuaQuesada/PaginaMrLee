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

    public async Task<(bool Ok, string Error)> AddMovementAsync(int productId, StockMovementType type, decimal quantity, string reason, int? userId, string userEmail)
    {
        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == productId);
        if (product == null) return (false, "Producto no encontrado.");

        var validationError = ValidateMovement(product, type, quantity);
        if (!string.IsNullOrWhiteSpace(validationError))
            return (false, validationError);

        var movement = new StockMovement
        {
            ProductId = productId,
            Type = type,
            Quantity = quantity,
            Reason = reason?.Trim() ?? "",
            CreatedByUserId = userId,
            CreatedByEmail = userEmail ?? ""
        };

        _db.StockMovements.Add(movement);
        await _db.SaveChangesAsync();

        await RecalculateProductStockAsync(productId);
        return (true, "");
    }

    private static string? ValidateMovement(Product product, StockMovementType type, decimal quantity)
    {
        if (quantity == 0m)
            return "La cantidad no puede ser 0.";

        if ((type == StockMovementType.Entry || type == StockMovementType.Exit) && quantity < 0m)
            return "La cantidad debe ser mayor a 0 para entradas y salidas.";

        var resultingStock = type switch
        {
            StockMovementType.Entry => product.CurrentStock + quantity,
            StockMovementType.Exit => product.CurrentStock - quantity,
            StockMovementType.Adjustment => product.CurrentStock + quantity,
            _ => product.CurrentStock
        };

        if (resultingStock < 0m)
            return $"No hay stock suficiente. Existencia actual: {product.CurrentStock:N2}.";

        return null;
    }
}

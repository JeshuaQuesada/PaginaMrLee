namespace MrLee.Web.Models;

public class Product
{
    public int Id { get; set; }
    public string Sku { get; set; } = "";
    public string Name { get; set; } = "";
    public string Unit { get; set; } = "unidad";
    public decimal UnitPrice { get; set; } = 0m;

    public decimal CurrentStock { get; set; } = 0m;

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public List<StockMovement> Movements { get; set; } = new();
}

public enum StockMovementType
{
    Entry = 1,
    Exit = 2,
    Adjustment = 3
}

public class StockMovement
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = default!;

    public StockMovementType Type { get; set; }
    public decimal Quantity { get; set; } 
    public string Reason { get; set; } = "";
    public DateTime AtUtc { get; set; } = DateTime.UtcNow;

    public int? CreatedByUserId { get; set; }
    public string CreatedByEmail { get; set; } = "";
}

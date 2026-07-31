namespace MrLee.Web.Models;

public enum OrderStatus
{
    Recibido = 1,
    EnPreparacion = 2,
    EnRuta = 3,
    Entregado = 4,
    Cancelado = 5
}

public class Order
{
    public long Id { get; set; }
    public string TrackingNumber { get; set; } = ""; // unique
    public string CustomerName { get; set; } = "";
    public string CustomerPhone { get; set; } = "";
    public string DeliveryAddress { get; set; } = "";
    public string Notes { get; set; } = "";

    public OrderStatus Status { get; set; } = OrderStatus.Recibido;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public List<OrderItem> Items { get; set; } = new();
    public List<OrderStatusHistory> History { get; set; } = new();
}

public class OrderItem
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public Order Order { get; set; } = default!;

    public int ProductId { get; set; }
    public Product Product { get; set; } = default!;

    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class OrderStatusHistory
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public Order Order { get; set; } = default!;

    public OrderStatus Status { get; set; }
    public string Comment { get; set; } = "";
    public DateTime AtUtc { get; set; } = DateTime.UtcNow;

    public int? ChangedByUserId { get; set; }
    public string ChangedByEmail { get; set; } = "";
}

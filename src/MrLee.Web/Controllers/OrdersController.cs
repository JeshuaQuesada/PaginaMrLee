using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;
using MrLee.Web.Security;
using MrLee.Web.Services;
using System.ComponentModel.DataAnnotations;

namespace MrLee.Web.Controllers;

[Authorize(Policy = PermissionCatalog.ORD_VIEW)]
public class OrdersController : Controller
{
    private readonly AppDbContext _db;
    private readonly OrderService _orders;
    private readonly AuditService _audit;

    public OrdersController(AppDbContext db, OrderService orders, AuditService audit)
    {
        _db = db;
        _orders = orders;
        _audit = audit;
    }

    public async Task<IActionResult> Index(string? q = null, OrderStatus? status = null)
    {
        var orders = _db.Orders.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
            orders = orders.Where(o => o.TrackingNumber.Contains(q) || o.CustomerName.Contains(q) || o.CustomerPhone.Contains(q));

        if (status.HasValue)
            orders = orders.Where(o => o.Status == status.Value);

        var list = await orders.OrderByDescending(o => o.CreatedAtUtc).Take(300).ToListAsync();
        ViewBag.Query = q ?? "";
        ViewBag.Status = status;
        return View(list);
    }

    [Authorize(Policy = PermissionCatalog.ORD_MANAGE)]
    public async Task<IActionResult> Create()
    {
        ViewBag.Products = await _db.Products.Where(p => p.IsActive).OrderBy(p => p.Name).ToListAsync();
        return View(new OrderCreateVm());
    }

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.ORD_MANAGE)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(OrderCreateVm vm)
    {
        ViewBag.Products = await _db.Products.Where(p => p.IsActive).OrderBy(p => p.Name).ToListAsync();
        if (!ModelState.IsValid) return View(vm);

        var tracking = await _orders.GenerateTrackingNumberAsync();

        var order = new Order
        {
            TrackingNumber = tracking,
            CustomerName = vm.CustomerName.Trim(),
            CustomerPhone = vm.CustomerPhone.Trim(),
            DeliveryAddress = vm.DeliveryAddress.Trim(),
            Notes = vm.Notes?.Trim() ?? "",
            Status = OrderStatus.Recibido
        };

        // build items (ignore empty lines)
        var lines = vm.Items.Where(i => i.ProductId.HasValue && i.Quantity > 0).ToList();
        if (lines.Count == 0)
        {
            ModelState.AddModelError("", "Agregue al menos un producto al pedido.");
            return View(vm);
        }

        var productIds = lines.Select(l => l.ProductId!.Value).Distinct().ToList();
        var products = await _db.Products.Where(p => productIds.Contains(p.Id)).ToListAsync();
        foreach (var l in lines)
        {
            var p = products.First(x => x.Id == l.ProductId!.Value);
            order.Items.Add(new OrderItem
            {
                ProductId = p.Id,
                Quantity = l.Quantity,
                UnitPrice = p.UnitPrice
            });
        }

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        await _orders.AppendHistoryAsync(order.Id, OrderStatus.Recibido, "Pedido creado", User.GetUserId(), User.GetEmail());

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "ORD.CREATE", "Order", order.Id.ToString(),
            new { order.TrackingNumber, order.CustomerName, items = lines.Count });

        return RedirectToAction(nameof(Details), new { id = order.Id });
    }

    public async Task<IActionResult> Details(long id)
    {
        var order = await _db.Orders
            .Include(o => o.Items).ThenInclude(i => i.Product)
            .Include(o => o.History)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order == null) return NotFound();

        order.History = order.History.OrderByDescending(h => h.AtUtc).ToList();
        return View(order);
    }

    [Authorize(Policy = PermissionCatalog.ORD_STATUS)]
    public async Task<IActionResult> UpdateStatus(long id)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();

        return View(new UpdateStatusVm { OrderId = id, CurrentStatus = order.Status, NewStatus = order.Status });
    }

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.ORD_STATUS)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(UpdateStatusVm vm)
    {
        if (!ModelState.IsValid) return View(vm);

        await _orders.UpdateStatusAsync(vm.OrderId, vm.NewStatus, vm.Comment ?? "", User.GetUserId(), User.GetEmail());

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "ORD.STATUS", "Order", vm.OrderId.ToString(),
            new { vm.NewStatus, vm.Comment });

        return RedirectToAction(nameof(Details), new { id = vm.OrderId });
    }

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.ORD_MANAGE)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(long id)
    {
        var order = await _db.Orders.Include(o => o.Items).Include(o => o.History).FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound();

        _db.OrderItems.RemoveRange(order.Items);
        _db.OrderStatusHistory.RemoveRange(order.History);
        _db.Orders.Remove(order);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "ORD.DELETE", "Order", id.ToString(),
            new { order.TrackingNumber });

        return RedirectToAction(nameof(Index));
    }
}

public class OrderCreateVm
{
    [Required]
    public string CustomerName { get; set; } = "";

    [Required]
    public string CustomerPhone { get; set; } = "";

    [Required]
    public string DeliveryAddress { get; set; } = "";

    public string? Notes { get; set; }

    // 5 lines to keep the UI simple (can be extended)
    public List<OrderLineVm> Items { get; set; } = new()
    {
        new OrderLineVm(), new OrderLineVm(), new OrderLineVm(), new OrderLineVm(), new OrderLineVm()
    };
}

public class OrderLineVm
{
    public int? ProductId { get; set; }

    [Range(0, 999999)]
    public decimal Quantity { get; set; } = 0m;
}

public class UpdateStatusVm
{
    public long OrderId { get; set; }

    public OrderStatus CurrentStatus { get; set; }

    [Required]
    public OrderStatus NewStatus { get; set; }

    public string? Comment { get; set; }
}

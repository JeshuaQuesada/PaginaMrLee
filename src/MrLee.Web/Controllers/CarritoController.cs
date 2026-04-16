using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;
using MrLee.Web.Services;
using System.Security.Claims;

namespace MrLee.Web.Controllers;

[Authorize(AuthenticationSchemes = "ClienteCookie")]
public class CarritoController : Controller
{
    private readonly CarritoService _carrito;
    private readonly AppDbContext _db;
    private readonly AuditService _audit;
    private readonly ClienteService _clienteSvc;

    public CarritoController(CarritoService carrito, AppDbContext db,
        AuditService audit, ClienteService clienteSvc)
    {
        _carrito = carrito;
        _db = db;
        _audit = audit;
        _clienteSvc = clienteSvc;
    }

    private int ClienteId => int.TryParse(
        User.FindFirstValue("ClienteId"), out var id) ? id : 0;
    private string ClienteEmail => User.FindFirstValue("ClienteEmail") ?? "";

    // ── Ver carrito ───────────────────────────────────────────
    public IActionResult Index()
    {
        var carrito = _carrito.ObtenerCarrito();
        return View(carrito);
    }

    // ── Agregar producto al carrito (AJAX o form) ─────────────
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Agregar(int productoId, decimal cantidad = 1)
    {
        var producto = await _db.Products
            .FirstOrDefaultAsync(p => p.Id == productoId && p.IsActive);

        if (producto == null)
            return Json(new { ok = false, msg = "Producto no encontrado." });

        if (producto.CurrentStock < cantidad)
            return Json(new { ok = false, msg = $"Stock insuficiente. Disponible: {producto.CurrentStock} {producto.Unit}." });

        _carrito.AgregarItem(productoId, producto.Name, producto.Unit,
            producto.UnitPrice, cantidad);

        var carrito = _carrito.ObtenerCarrito();
        return Json(new
        {
            ok = true,
            totalItems = carrito.TotalItems,
            total = carrito.Total.ToString("N2")
        });
    }

    // ── Actualizar cantidad ───────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken]
    public IActionResult Actualizar(int productoId, decimal cantidad)
    {
        _carrito.ActualizarCantidad(productoId, cantidad);
        var carrito = _carrito.ObtenerCarrito();
        return Json(new
        {
            ok = true,
            totalItems = carrito.TotalItems,
            total = carrito.Total.ToString("N2")
        });
    }

    // ── Eliminar item ─────────────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken]
    public IActionResult Eliminar(int productoId)
    {
        _carrito.EliminarItem(productoId);
        var carrito = _carrito.ObtenerCarrito();
        return Json(new
        {
            ok = true,
            totalItems = carrito.TotalItems,
            total = carrito.Total.ToString("N2")
        });
    }

    // ── Vaciar carrito ────────────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken]
    public IActionResult Vaciar()
    {
        _carrito.LimpiarCarrito();
        TempData["Msg"] = "Carrito vaciado.";
        return RedirectToAction(nameof(Index));
    }

    // ── Confirmar pedido (GET) ────────────────────────────────
    public async Task<IActionResult> Confirmar()
    {
        var carrito = _carrito.ObtenerCarrito();
        if (!carrito.Items.Any())
        {
            TempData["Error"] = "El carrito está vacío.";
            return RedirectToAction(nameof(Index));
        }

        var cliente = await _clienteSvc.FindByIdAsync(ClienteId);
        var dir = cliente?.Direcciones.FirstOrDefault(d => d.EsPrincipal);

        var vm = new ConfirmarPedidoVm
        {
            NombreCliente = $"{cliente?.Nombre} {cliente?.Apellido}".Trim(),
            TelefonoCliente = cliente?.Telefono ?? "",
            DireccionEntrega = dir?.Direccion ?? "",
            Carrito = carrito
        };
        return View(vm);
    }

    // ── Confirmar pedido (POST) ───────────────────────────────
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Confirmar(ConfirmarPedidoVm vm)
    {
        vm.Carrito = _carrito.ObtenerCarrito();

        if (!vm.Carrito.Items.Any())
        {
            ModelState.AddModelError("", "El carrito está vacío.");
            return View(vm);
        }

        if (!ModelState.IsValid) return View(vm);

        // Generar tracking único
        var date = DateTime.UtcNow.ToString("yyyyMMdd");
        var rnd = Random.Shared.Next(1000, 9999);
        var tracking = $"MRLEE-{date}-{rnd}";
        while (await _db.Orders.AnyAsync(o => o.TrackingNumber == tracking))
        {
            rnd = Random.Shared.Next(1000, 9999);
            tracking = $"MRLEE-{date}-{rnd}";
        }

        // Obtener productos de BD para validar precios y stock
        var ids = vm.Carrito.Items.Select(i => i.ProductoId).ToList();
        var productos = await _db.Products.Where(p => ids.Contains(p.Id)).ToListAsync();

        // Validar stock
        foreach (var item in vm.Carrito.Items)
        {
            var prod = productos.FirstOrDefault(p => p.Id == item.ProductoId);
            if (prod == null || prod.CurrentStock < item.Cantidad)
            {
                ModelState.AddModelError("",
                    $"Stock insuficiente para '{item.Nombre}'. Disponible: {prod?.CurrentStock ?? 0}.");
                return View(vm);
            }
        }

        // Crear pedido
        var order = new Order
        {
            TrackingNumber = tracking,
            CustomerName = vm.NombreCliente.Trim(),
            CustomerPhone = vm.TelefonoCliente.Trim(),
            DeliveryAddress = vm.DireccionEntrega.Trim(),
            Notes = vm.Notas.Trim(),
            Status = OrderStatus.EnPreparacion
        };

        foreach (var item in vm.Carrito.Items)
        {
            var prod = productos.First(p => p.Id == item.ProductoId);
            order.Items.Add(new OrderItem
            {
                ProductId = prod.Id,
                Quantity = item.Cantidad,
                UnitPrice = prod.UnitPrice
            });
        }

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(null, ClienteEmail, "CLIENTE.PEDIDO_CARRITO",
            "Order", order.Id.ToString(),
            new { tracking, vm.NombreCliente, Total = vm.Carrito.Total });

        _carrito.LimpiarCarrito();

        TempData["Msg"] = $"¡Pedido confirmado! Tu número de seguimiento es {tracking} 🎉";
        return RedirectToAction("MisPedidos", "Portal");
    }

    // ── Catálogo de productos (tienda) ────────────────────────
    [AllowAnonymous]
    public async Task<IActionResult> Tienda(string? categoria = null)
    {
        var productos = await _db.Products
            .Where(p => p.IsActive && p.CurrentStock > 0)
            .OrderBy(p => p.Name)
            .ToListAsync();

        ViewBag.Categoria = categoria;
        ViewBag.CarritoItems = _carrito.ContarItems();
        return View(productos);
    }
}
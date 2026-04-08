using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;
using MrLee.Web.Security;
using MrLee.Web.Services;
using System.ComponentModel.DataAnnotations;

namespace MrLee.Web.Controllers;

[Authorize(Policy = PermissionCatalog.INV_VIEW)]
public class InventoryController : Controller
{
    private readonly AppDbContext _db;
    private readonly InventoryService _inv;
    private readonly AuditService _audit;

    public InventoryController(AppDbContext db, InventoryService inv, AuditService audit)
    {
        _db = db;
        _inv = inv;
        _audit = audit;
    }

    public async Task<IActionResult> Index(string? q = null)
    {
        var products = _db.Products.AsQueryable();
        if (!string.IsNullOrWhiteSpace(q))
            products = products.Where(p => p.Name.Contains(q) || p.Sku.Contains(q));

        var list = await products.OrderBy(p => p.Name).ToListAsync();
        ViewBag.Query = q ?? "";
        return View(list);
    }

    [Authorize(Policy = PermissionCatalog.INV_MANAGE)]
    public IActionResult Create() => View(new ProductVm());

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.INV_MANAGE)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(ProductVm vm)
    {
        if (!ModelState.IsValid) return View(vm);

        if (await _db.Products.AnyAsync(p => p.Sku == vm.Sku))
        {
            ModelState.AddModelError(nameof(vm.Sku), "SKU ya existe.");
            return View(vm);
        }

        var product = new Product
        {
            Sku = vm.Sku.Trim(),
            Name = vm.Name.Trim(),
            Unit = vm.Unit.Trim(),
            UnitPrice = vm.UnitPrice,
            IsActive = vm.IsActive
        };
        _db.Products.Add(product);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "INV.CREATE_PRODUCT", "Product", product.Id.ToString(),
            new { product.Sku, product.Name });

        return RedirectToAction(nameof(Index));
    }

    [Authorize(Policy = PermissionCatalog.INV_MANAGE)]
    public async Task<IActionResult> Edit(int id)
    {
        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == id);
        if (p == null) return NotFound();

        return View(new ProductVm
        {
            Id = p.Id,
            Sku = p.Sku,
            Name = p.Name,
            Unit = p.Unit,
            UnitPrice = p.UnitPrice,
            IsActive = p.IsActive
        });
    }

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.INV_MANAGE)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(ProductVm vm)
    {
        if (!ModelState.IsValid) return View(vm);

        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == vm.Id);
        if (p == null) return NotFound();

        p.Sku = vm.Sku.Trim();
        p.Name = vm.Name.Trim();
        p.Unit = vm.Unit.Trim();
        p.UnitPrice = vm.UnitPrice;
        p.IsActive = vm.IsActive;

        await _db.SaveChangesAsync();

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "INV.EDIT_PRODUCT", "Product", p.Id.ToString(),
            new { p.Sku, p.Name, p.IsActive });

        return RedirectToAction(nameof(Index));
    }

    [Authorize(Policy = PermissionCatalog.INV_MOVEMENTS)]
    public async Task<IActionResult> Movements(int id)
    {
        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (product == null) return NotFound();

        var moves = await _db.StockMovements
            .Where(m => m.ProductId == id)
            .OrderByDescending(m => m.AtUtc)
            .Take(200)
            .ToListAsync();

        ViewBag.Product = product;
        return View(moves);
    }

    [Authorize(Policy = PermissionCatalog.INV_MOVEMENTS)]
    public async Task<IActionResult> AddMovement(int id)
    {
        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (product == null) return NotFound();

        ViewBag.Product = product;
        return View(new StockMovementVm { ProductId = id, Type = StockMovementType.Entry, Quantity = 1 });
    }

    [HttpPost]
    [Authorize(Policy = PermissionCatalog.INV_MOVEMENTS)]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddMovement(StockMovementVm vm)
    {
        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == vm.ProductId);
        if (product == null) return NotFound();

        ViewBag.Product = product;
        if (!ModelState.IsValid) return View(vm);

        await _inv.AddMovementAsync(vm.ProductId, vm.Type, vm.Quantity, vm.Reason, User.GetUserId(), User.GetEmail());

        await _audit.LogAsync(User.GetUserId(), User.GetEmail(), "INV.MOVEMENT", "Product", vm.ProductId.ToString(),
            new { vm.Type, vm.Quantity, vm.Reason });

        return RedirectToAction(nameof(Movements), new { id = vm.ProductId });
    }
}

public class ProductVm
{
    public int Id { get; set; }

    [Required]
    public string Sku { get; set; } = "";

    [Required]
    public string Name { get; set; } = "";

    [Required]
    public string Unit { get; set; } = "unidad";

    [Range(0, 999999)]
    public decimal UnitPrice { get; set; } = 0m;

    public bool IsActive { get; set; } = true;
}

public class StockMovementVm
{
    public int ProductId { get; set; }

    [Required]
    public StockMovementType Type { get; set; }

    [Range(-999999, 999999)]
    public decimal Quantity { get; set; } = 1m;

    public string Reason { get; set; } = "";
}

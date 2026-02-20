using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MrLee.Web.Data;
using MrLee.Web.Models;
using MrLee.Web.Services;
using System.Security.Claims;
using System.ComponentModel.DataAnnotations;

namespace MrLee.Web.Controllers;

public class AccountController : Controller
{
    private readonly AppDbContext _db;
    private readonly PasswordService _pwd;
    private readonly AuditService _audit;

    public AccountController(AppDbContext db, PasswordService pwd, AuditService audit)
    {
        _db = db;
        _pwd = pwd;
        _audit = audit;
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        ViewBag.ReturnUrl = returnUrl;
        return View(new LoginVm());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginVm vm, string? returnUrl = null)
    {
        ViewBag.ReturnUrl = returnUrl;

        if (!ModelState.IsValid) return View(vm);

        var user = await _db.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.Email == vm.Email);
        if (user == null)
        {
            ModelState.AddModelError("", "Credenciales inválidas.");
            return View(vm);
        }

        if (!user.IsActive)
        {
            ModelState.AddModelError("", "Usuario desactivado.");
            return View(vm);
        }

        if (user.LockoutEndUtc.HasValue && user.LockoutEndUtc.Value > DateTime.UtcNow)
        {
            ModelState.AddModelError("", $"Usuario bloqueado temporalmente. Intente nuevamente más tarde.");
            return View(vm);
        }

        if (!_pwd.Verify(vm.Password, user.PasswordHash))
        {
            user.FailedLoginCount += 1;
            if (user.FailedLoginCount >= 5) // SEGR-006 
            {
                user.LockoutEndUtc = DateTime.UtcNow.AddMinutes(15);
                user.FailedLoginCount = 0;
            }
            await _db.SaveChangesAsync();

            ModelState.AddModelError("", "Credenciales inválidas.");
            return View(vm);
        }

        user.FailedLoginCount = 0;
        user.LockoutEndUtc = null;
        await _db.SaveChangesAsync();

        var claims = new List<Claim>
        {
            new("UserId", user.Id.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Role.Name),
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        await _audit.LogAsync(user.Id, user.Email, "AUTH.LOGIN", "AppUser", user.Id.ToString(), new { user.Email });

        if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
            return Redirect(returnUrl);

        return RedirectToAction("Index", "Home");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        var userId = User.FindFirstValue("UserId");
        await _audit.LogAsync(int.TryParse(userId, out var id) ? id : null, User.FindFirstValue(ClaimTypes.Email) ?? "",
            "AUTH.LOGOUT", "AppUser", userId ?? "");

        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    public IActionResult AccessDenied() => View();
}

public class LoginVm
{
    [Required, EmailAddress]
    public string Email { get; set; } = "";
    [Required]
    public string Password { get; set; } = "";
}

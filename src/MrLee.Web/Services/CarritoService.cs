using System.Text.Json;
using MrLee.Web.Models;

namespace MrLee.Web.Services;

public class CarritoService
{
    private const string SESSION_KEY = "MrLee_Carrito";
    private readonly IHttpContextAccessor _http;

    public CarritoService(IHttpContextAccessor http) => _http = http;

    private ISession Session => _http.HttpContext!.Session;

    public CarritoVm ObtenerCarrito()
    {
        var json = Session.GetString(SESSION_KEY);
        if (string.IsNullOrEmpty(json)) return new CarritoVm();
        try { return JsonSerializer.Deserialize<CarritoVm>(json) ?? new CarritoVm(); }
        catch { return new CarritoVm(); }
    }

    private void GuardarCarrito(CarritoVm carrito) =>
        Session.SetString(SESSION_KEY, JsonSerializer.Serialize(carrito));

    public void AgregarItem(int productoId, string nombre, string unidad, decimal precio, decimal cantidad)
    {
        var carrito = ObtenerCarrito();
        var item = carrito.Items.FirstOrDefault(i => i.ProductoId == productoId);

        if (item != null)
            item.Cantidad += cantidad;
        else
            carrito.Items.Add(new CarritoItemVm
            {
                ProductoId = productoId,
                Nombre = nombre,
                Unidad = unidad,
                Precio = precio,
                Cantidad = cantidad
            });

        GuardarCarrito(carrito);
    }

    public void ActualizarCantidad(int productoId, decimal cantidad)
    {
        var carrito = ObtenerCarrito();
        var item = carrito.Items.FirstOrDefault(i => i.ProductoId == productoId);
        if (item != null)
        {
            if (cantidad <= 0)
                carrito.Items.Remove(item);
            else
                item.Cantidad = cantidad;
        }
        GuardarCarrito(carrito);
    }

    public void EliminarItem(int productoId)
    {
        var carrito = ObtenerCarrito();
        carrito.Items.RemoveAll(i => i.ProductoId == productoId);
        GuardarCarrito(carrito);
    }

    public void LimpiarCarrito() => Session.Remove(SESSION_KEY);

    public int ContarItems() => ObtenerCarrito().TotalItems;
}

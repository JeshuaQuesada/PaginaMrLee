using System.ComponentModel.DataAnnotations;

namespace MrLee.Web.Models;

public class CarritoItemVm
{
    public int ProductoId { get; set; }
    public string Nombre { get; set; } = "";
    public string Unidad { get; set; } = "";
    public decimal Precio { get; set; }
    public decimal Cantidad { get; set; }
    public decimal Subtotal => Precio * Cantidad;
}

public class CarritoVm
{
    public List<CarritoItemVm> Items { get; set; } = new();
    public decimal Total => Items.Sum(i => i.Subtotal);
    public int TotalItems => Items.Count;
}

public class ConfirmarPedidoVm
{
    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [StringLength(150)]
    public string NombreCliente { get; set; } = "";

    [Required(ErrorMessage = "El teléfono es obligatorio.")]
    [RegularExpression(@"^\+?[0-9\s\-\(\)]{7,20}$", ErrorMessage = "Formato inválido.")]
    [StringLength(20)]
    public string TelefonoCliente { get; set; } = "";

    [Required(ErrorMessage = "La dirección es obligatoria.")]
    [StringLength(300)]
    public string DireccionEntrega { get; set; } = "";

    [StringLength(500)]
    public string Notas { get; set; } = "";

    public CarritoVm Carrito { get; set; } = new();
}

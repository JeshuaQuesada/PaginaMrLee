using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MrLee.Models
{
    [Table("EstadosPedido")]
    public class EstadoPedido
    {
        [Key]
        [Column("IdEstado")]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        [Column("NombreEstado")]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(200)]
        [Column("Descripcion")]
        public string? Descripcion { get; set; }

        [Column("Activo")]
        public bool Activo { get; set; } = true;
    }

    [Table("Prioridades")]
    public class Prioridad
    {
        [Key]
        [Column("IdPrioridad")]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        [Column("NombrePrioridad")]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(200)]
        [Column("Descripcion")]
        public string? Descripcion { get; set; }

        [Required]
        [Column("Nivel")]
        public int Nivel { get; set; }
    }

    [Table("PedidoDetalles")]
    public class PedidoDetalle
    {
        [Key]
        [Column("IdDetalle")]
        public int Id { get; set; }

        [Required]
        [Column("IdPedido")]
        public int PedidoId { get; set; }

        [ForeignKey("PedidoId")]
        public virtual Pedido? Pedido { get; set; }

        [Required]
        [StringLength(200)]
        [Column("NombreProducto")]
        public string NombreProducto { get; set; } = string.Empty;

        [Required]
        [Column("Cantidad")]
        public int Cantidad { get; set; }

        [Required]
        [Column("PrecioUnitario")]
        public decimal PrecioUnitario { get; set; }

        [NotMapped]
        public decimal Subtotal => Cantidad * PrecioUnitario;
    }

    [Table("NotasPedido")]
    public class NotaPedido
    {
        [Key]
        [Column("IdNota")]
        public int Id { get; set; }

        [Required]
        [Column("IdPedido")]
        public int PedidoId { get; set; }

        [ForeignKey("PedidoId")]
        public virtual Pedido? Pedido { get; set; }

        [Required]
        [Column("IdUsuario")]
        public int UsuarioId { get; set; }

        [Required]
        [Column("Nota")]
        public string Texto { get; set; } = string.Empty;

        [Column("FechaCreacion")]
        public DateTime FechaCreacion { get; set; } = DateTime.Now;

        [Column("Activa")]
        public bool Activa { get; set; } = true;
    }

    [Table("Usuarios")]
    public class Usuario
    {
        [Key]
        [Column("IdUsuario")]
        public int Id { get; set; }

        [Required]
        [StringLength(200)]
        [Column("NombreCompleto")]
        public string NombreCompleto { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [Column("NombreUsuario")]
        public string NombreUsuario { get; set; } = string.Empty;

        [Required]
        [StringLength(150)]
        [Column("CorreoElectronico")]
        public string CorreoElectronico { get; set; } = string.Empty;

        [Required]
        [StringLength(255)]
        [Column("Contrasena")]
        public string Contrasena { get; set; } = string.Empty;

        [Required]
        [Column("IdRol")]
        public int RolId { get; set; }

        [Column("Activo")]
        public bool Activo { get; set; } = true;

        [Column("FechaCreacion")]
        public DateTime FechaCreacion { get; set; } = DateTime.Now;

        [Column("FechaUltimaModificacion")]
        public DateTime? FechaUltimaModificacion { get; set; }
    }

    // Producto simple (puede no estar en tu BD pero lo dejamos para compatibilidad)
    [Table("Productos")]
    public class Producto
    {
        [Key]
        [Column("IdProducto")]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        [Column("CodigoProducto")]
        public string CodigoProducto { get; set; } = string.Empty;

        [StringLength(50)]
        [Column("CodigoBarras")]
        public string? CodigoBarras { get; set; }

        [Required]
        [StringLength(200)]
        [Column("NombreProducto")]
        public string Nombre { get; set; } = string.Empty;

        [Column("Descripcion")]
        public string? Descripcion { get; set; }

        [Required]
        [Column("IdCategoria")]
        public int CategoriaId { get; set; }

        [Required]
        [Column("PrecioUnitario")]
        public decimal Precio { get; set; }

        [Column("StockActual")]
        public int StockActual { get; set; } = 0;

        [Column("StockMinimo")]
        public int StockMinimo { get; set; } = 5;

        [StringLength(50)]
        [Column("UnidadMedida")]
        public string UnidadMedida { get; set; } = "unidad";

        [Column("Activo")]
        public bool Activo { get; set; } = true;

        [Column("FechaCreacion")]
        public DateTime FechaCreacion { get; set; } = DateTime.Now;

        [Column("FechaUltimaModificacion")]
        public DateTime? FechaUltimaModificacion { get; set; }

        [Column("IdUsuarioCreacion")]
        public int UsuarioCreacionId { get; set; }

        [Column("IdUsuarioUltimaModificacion")]
        public int? UsuarioUltimaModificacionId { get; set; }
    }
}
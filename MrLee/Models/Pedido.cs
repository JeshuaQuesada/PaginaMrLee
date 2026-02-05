using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MrLee.Models
{
    [Table("Pedidos")]
    public class Pedido
    {
        [Key]
        [Column("IdPedido")]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        [Column("NumeroSeguimiento")]
        public string NumeroSeguimiento { get; set; } = string.Empty;

        [Required]
        [Column("IdCliente")]
        public int ClienteId { get; set; }

        [ForeignKey("ClienteId")]
        public virtual Cliente? Cliente { get; set; }

        [Required]
        [Column("IdEstado")]
        public int EstadoId { get; set; } = 1;

        [Required]
        [Column("IdPrioridad")]
        public int PrioridadId { get; set; } = 2;

        [Required]
        [Column("IdUsuarioCreacion")]
        public int UsuarioCreacionId { get; set; } = 1;

        [Required]
        [StringLength(300)]
        [Column("DireccionEntrega")]
        public string Direccion { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        [Column("TelefonoContacto")]
        public string Telefono { get; set; } = string.Empty;

        [Column("Observaciones")]
        public string? Notas { get; set; }

        [Column("FechaCreacion")]
        public DateTime FechaCreacion { get; set; } = DateTime.Now;

        [Required]
        [Column("FechaPrometida")]
        public DateTime Fecha { get; set; }

        [Column("FechaEntregaReal")]
        public DateTime? FechaEntregaReal { get; set; }

        [Column("Anulado")]
        public bool Anulado { get; set; } = false;

        [Column("FechaAnulacion")]
        public DateTime? FechaAnulacion { get; set; }

        [StringLength(500)]
        [Column("MotivoAnulacion")]
        public string? MotivoAnulacion { get; set; }

        [Column("IdUsuarioAnulacion")]
        public int? UsuarioAnulacionId { get; set; }

        [Column("FechaUltimaModificacion")]
        public DateTime? FechaUltimaModificacion { get; set; }

        [Column("IdUsuarioUltimaModificacion")]
        public int? UsuarioUltimaModificacionId { get; set; }

        public virtual ICollection<PedidoDetalle> Detalles { get; set; } = new List<PedidoDetalle>();

        public virtual ICollection<NotaPedido> NotasPedido { get; set; } = new List<NotaPedido>();
    }
}
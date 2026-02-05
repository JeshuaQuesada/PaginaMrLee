using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MrLee.Models
{
    [Table("Clientes")]
    public class Cliente
    {
        [Key]
        [Column("IdCliente")]
        public int Id { get; set; }

        [Required(ErrorMessage = "El nombre completo es obligatorio")]
        [StringLength(200)]
        [Column("NombreCompleto")]
        public string Nombre { get; set; } = string.Empty;

        [Required]
        [StringLength(20)]
        [Column("Telefono")]
        public string Telefono { get; set; } = string.Empty;

        [StringLength(150)]
        [Column("CorreoElectronico")]
        public string? CorreoElectronico { get; set; }

        [Required]
        [StringLength(300)]
        [Column("Direccion")]
        public string Direccion { get; set; } = string.Empty;

        [Column("Latitud")]
        public decimal? Latitud { get; set; }

        [Column("Longitud")]
        public decimal? Longitud { get; set; }

        [Column("Activo")]
        public bool Activo { get; set; } = true;

        [Column("FechaCreacion")]
        public DateTime FechaRegistro { get; set; } = DateTime.Now;

        [Column("FechaUltimaModificacion")]
        public DateTime? FechaUltimaModificacion { get; set; }

        // Relación con pedidos
        public virtual ICollection<Pedido> Pedidos { get; set; } = new List<Pedido>();
    }
}
namespace MrLee.Models.DTOs
{
    public class PedidoCreateDto
    {
        public int? ClienteId { get; set; }
        public string? ClienteNombre { get; set; }
        public string Productos { get; set; } = string.Empty;
        public int Cantidades { get; set; }
        public string Direccion { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public string Prioridad { get; set; } = "Normal";
        public DateTime Fecha { get; set; }
        public string? Notas { get; set; }
        public double? DistanciaKm { get; set; }
    }

    public class PedidoResponseDto
    {
        public int Id { get; set; }
        public string NumeroSeguimiento { get; set; } = string.Empty;
        public string Cliente { get; set; } = string.Empty;
        public string Productos { get; set; } = string.Empty;
        public int Cantidades { get; set; }
        public string Direccion { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
        public string Prioridad { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
        public DateTime FechaCreacion { get; set; }
        public string? Responsable { get; set; }
        public string? Notas { get; set; }
        public double? DistanciaKm { get; set; }
    }

    public class ValidationResult
    {
        public bool IsValid { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
        public string Message { get; set; } = string.Empty;
    }
}
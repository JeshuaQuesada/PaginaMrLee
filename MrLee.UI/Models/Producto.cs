namespace MrLee.UI.Models
{
    public class Producto
    {
        public long id_producto { get; set; }
        public string codigo { get; set; }
        public string nombre { get; set; }
        public string categoria { get; set; }
        public decimal precio { get; set; }
        public int stock { get; set; }
        public bool activo { get; set; }
    }
}

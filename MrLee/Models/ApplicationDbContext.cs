using Microsoft.EntityFrameworkCore;

namespace MrLee.Models
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Cliente> Clientes { get; set; } = null!;
        public DbSet<Pedido> Pedidos { get; set; } = null!;
        public DbSet<PedidoDetalle> PedidoDetalles { get; set; } = null!;
        public DbSet<NotaPedido> NotasPedido { get; set; } = null!;
        public DbSet<EstadoPedido> EstadosPedido { get; set; } = null!;
        public DbSet<Prioridad> Prioridades { get; set; } = null!;
        public DbSet<Usuario> Usuarios { get; set; } = null!;
        public DbSet<Producto> Productos { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configuración de relaciones
            modelBuilder.Entity<Pedido>()
                .HasOne(p => p.Cliente)
                .WithMany(c => c.Pedidos)
                .HasForeignKey(p => p.ClienteId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<PedidoDetalle>()
                .HasOne(pd => pd.Pedido)
                .WithMany(p => p.Detalles)
                .HasForeignKey(pd => pd.PedidoId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<NotaPedido>()
                .HasOne(n => n.Pedido)
                .WithMany(p => p.NotasPedido)
                .HasForeignKey(n => n.PedidoId)
                .OnDelete(DeleteBehavior.Cascade);

            // Deshabilitar triggers automáticos de Entity Framework
            modelBuilder.Entity<Pedido>()
                .ToTable(tb => tb.HasTrigger("TR_Pedidos_Auditoria"));

            modelBuilder.Entity<Pedido>()
                .ToTable(tb => tb.HasTrigger("TR_Pedidos_RegistrarCambioEstado"));
        }
    }
}
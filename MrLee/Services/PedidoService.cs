using MrLee.Models;
using MrLee.Models.DTOs;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;

namespace MrLee.Services
{
    public class PedidoService
    {
        private readonly ApplicationDbContext _context;

        public PedidoService(ApplicationDbContext context)
        {
            _context = context;
        }

        // Generar número de seguimiento único
        private string GenerarNumeroSeguimiento()
        {
            var fecha = DateTime.Now;
            var random = new Random();
            return $"PED-{fecha:yyyyMMdd}-{random.Next(1000, 9999)}";
        }

        // Escenario 1: Crear pedido de forma exitosa
        public async Task<(bool success, string message, int? pedidoId)> CrearPedidoAsync(PedidoCreateDto dto)
        {
            // Validar todos los escenarios
            var validacion = await ValidarPedidoAsync(dto);

            if (!validacion.IsValid)
            {
                return (false, string.Join(", ", validacion.Errors), null);
            }

            // Escenario 6: Verificar si el cliente existe
            Cliente? cliente;
            if (dto.ClienteId.HasValue)
            {
                cliente = await _context.Clientes.FindAsync(dto.ClienteId.Value);
                if (cliente == null || !cliente.Activo)
                {
                    return (false, "El cliente seleccionado no existe en el catálogo. Por favor, cree o seleccione un cliente válido.", null);
                }
            }
            else if (!string.IsNullOrEmpty(dto.ClienteNombre))
            {
                // Crear nuevo cliente si no existe
                cliente = new Cliente
                {
                    Nombre = dto.ClienteNombre,
                    Telefono = dto.Telefono,
                    Direccion = dto.Direccion,
                    Activo = true,
                    FechaRegistro = DateTime.Now
                };
                _context.Clientes.Add(cliente);
                await _context.SaveChangesAsync();
            }
            else
            {
                return (false, "Debe proporcionar un cliente existente o un nombre para crear uno nuevo.", null);
            }

            // Calcular distancia si hay coordenadas (Escenario 3)
            if (dto.DistanciaKm.HasValue && dto.DistanciaKm > 10)
            {
                return (false, "La ubicación excede el límite de 10 kilómetros. Solo se aceptan pedidos dentro de este rango.", null);
            }

            var pedido = new Pedido
            {
                NumeroSeguimiento = GenerarNumeroSeguimiento(),
                ClienteId = cliente.Id,
                EstadoId = 1, 
                PrioridadId = ObtenerPrioridadId(dto.Prioridad),
                UsuarioCreacionId = 1, 
                Direccion = dto.Direccion,
                Telefono = dto.Telefono,
                Notas = dto.Notas,
                FechaCreacion = DateTime.Now,
                Fecha = dto.Fecha,
                Anulado = false
            };

            _context.Pedidos.Add(pedido);
            await _context.SaveChangesAsync();

            // Agregar detalles del pedido
            if (!string.IsNullOrEmpty(dto.Productos))
            {
                var productos = dto.Productos.Split(',').Select(p => p.Trim()).ToList();
                foreach (var producto in productos)
                {
                    var detalle = new PedidoDetalle
                    {
                        PedidoId = pedido.Id,
                        NombreProducto = producto,
                        Cantidad = dto.Cantidades / productos.Count, 
                        PrecioUnitario = 0 
                    };
                    _context.PedidoDetalles.Add(detalle);
                }
                await _context.SaveChangesAsync();
            }

            return (true, $"Pedido #{pedido.NumeroSeguimiento} creado exitosamente", pedido.Id);
        }

        private int ObtenerPrioridadId(string prioridad)
        {
            return prioridad.ToLower() switch
            {
                "baja" => 1,
                "normal" => 2,
                "alta" => 3,
                "urgente" => 4,
                _ => 2
            };
        }

        // Escenario 2: Guardar nota u observación
        public async Task<bool> GuardarNotaAsync(int pedidoId, string nota)
        {
            var pedido = await _context.Pedidos.FindAsync(pedidoId);
            if (pedido == null)
                return false;

            var notaPedido = new NotaPedido
            {
                PedidoId = pedidoId,
                UsuarioId = 1, // Usuario sistema
                Texto = nota,
                FechaCreacion = DateTime.Now,
                Activa = true
            };

            _context.NotasPedido.Add(notaPedido);
            await _context.SaveChangesAsync();
            return true;
        }

        // Validaciones para todos los escenarios
        private async Task<ValidationResult> ValidarPedidoAsync(PedidoCreateDto dto)
        {
            var result = new ValidationResult { IsValid = true };

            // Escenario 4: Validar campos obligatorios
            if (string.IsNullOrWhiteSpace(dto.Productos))
            {
                result.Errors.Add("Los productos son obligatorios");
            }

            if (dto.Cantidades <= 0)
            {
                result.Errors.Add("Las cantidades deben ser mayores a 0");
            }

            if (string.IsNullOrWhiteSpace(dto.Direccion))
            {
                result.Errors.Add("La dirección es obligatoria");
            }

            if (string.IsNullOrWhiteSpace(dto.Telefono))
            {
                result.Errors.Add("El teléfono es obligatorio");
            }

            if (dto.Fecha == default(DateTime))
            {
                result.Errors.Add("La fecha es obligatoria");
            }

            // Escenario 5: Validar formatos
            if (!string.IsNullOrWhiteSpace(dto.Telefono))
            {
                if (!Regex.IsMatch(dto.Telefono, @"^[\d\s\-\+\(\)]+$"))
                {
                    result.Errors.Add("El formato del teléfono es inválido. Use solo números, espacios, guiones o paréntesis.");
                }
            }

            // Validar formato de fecha (no más de 2 meses adelante)
            if (dto.Fecha != default(DateTime))
            {
                var fechaLimite = DateTime.Now.AddMonths(2);
                if (dto.Fecha > fechaLimite)
                {
                    result.Errors.Add($"La fecha no puede ser posterior a {fechaLimite:dd/MM/yyyy} (máximo 2 meses adelante)");
                }

                if (dto.Fecha < DateTime.Now.Date)
                {
                    result.Errors.Add("La fecha no puede ser anterior a hoy");
                }
            }

            // Escenario 3: Validar limitación geográfica (máximo 10km)
            if (dto.DistanciaKm.HasValue && dto.DistanciaKm.Value > 10)
            {
                result.Errors.Add("La ubicación excede el límite de 10 kilómetros. Solo se muestran locales dentro de este rango.");
            }

            result.IsValid = result.Errors.Count == 0;
            return result;
        }

        // Obtener todos los pedidos
        public async Task<List<PedidoResponseDto>> ObtenerPedidosAsync()
        {
            var pedidos = await _context.Pedidos
                .Include(p => p.Cliente)
                .Include(p => p.Detalles)
                .Where(p => !p.Anulado)
                .OrderByDescending(p => p.FechaCreacion)
                .ToListAsync();

            // Obtener estados y prioridades
            var estados = await _context.EstadosPedido.ToDictionaryAsync(e => e.Id, e => e.Nombre);
            var prioridades = await _context.Prioridades.ToDictionaryAsync(p => p.Id, p => p.Nombre);

            return pedidos.Select(p => new PedidoResponseDto
            {
                Id = p.Id,
                NumeroSeguimiento = p.NumeroSeguimiento,
                Cliente = p.Cliente?.Nombre ?? "Sin cliente",
                Productos = string.Join(", ", p.Detalles.Select(d => d.NombreProducto)),
                Cantidades = p.Detalles.Sum(d => d.Cantidad),
                Direccion = p.Direccion,
                Telefono = p.Telefono,
                Estado = estados.ContainsKey(p.EstadoId) ? estados[p.EstadoId] : "Desconocido",
                Prioridad = prioridades.ContainsKey(p.PrioridadId) ? prioridades[p.PrioridadId] : "Normal",
                Fecha = p.Fecha,
                FechaCreacion = p.FechaCreacion,
                Responsable = "Sistema",
                Notas = p.Notas,
                DistanciaKm = null
            }).ToList();
        }

        // Obtener pedido por ID
        public async Task<PedidoResponseDto?> ObtenerPedidoPorIdAsync(int id)
        {
            var pedido = await _context.Pedidos
                .Include(p => p.Cliente)
                .Include(p => p.Detalles)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (pedido == null)
                return null;

            var estado = await _context.EstadosPedido.FindAsync(pedido.EstadoId);
            var prioridad = await _context.Prioridades.FindAsync(pedido.PrioridadId);

            return new PedidoResponseDto
            {
                Id = pedido.Id,
                NumeroSeguimiento = pedido.NumeroSeguimiento,
                Cliente = pedido.Cliente?.Nombre ?? "Sin cliente",
                Productos = string.Join(", ", pedido.Detalles.Select(d => d.NombreProducto)),
                Cantidades = pedido.Detalles.Sum(d => d.Cantidad),
                Direccion = pedido.Direccion,
                Telefono = pedido.Telefono,
                Estado = estado?.Nombre ?? "Desconocido",
                Prioridad = prioridad?.Nombre ?? "Normal",
                Fecha = pedido.Fecha,
                FechaCreacion = pedido.FechaCreacion,
                Responsable = "Sistema",
                Notas = pedido.Notas,
                DistanciaKm = null
            };
        }

        // Obtener clientes para el dropdown
        public async Task<List<Cliente>> ObtenerClientesAsync()
        {
            return await _context.Clientes
                .Where(c => c.Activo)
                .OrderBy(c => c.Nombre)
                .ToListAsync();
        }

        // Obtener productos para el dropdown
        public async Task<List<Producto>> ObtenerProductosAsync()
        {
            return await _context.Productos
                .Where(p => p.Activo)
                .OrderBy(p => p.Nombre)
                .ToListAsync();
        }
    }
}
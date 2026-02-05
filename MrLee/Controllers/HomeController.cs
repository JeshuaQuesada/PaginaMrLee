using Microsoft.AspNetCore.Mvc;
using MrLee.Services;
using MrLee.Models;
using MrLee.Models.DTOs;

namespace MrLee.Controllers
{
    public class HomeController : Controller
    {
        private readonly PedidoService _pedidoService;
        private readonly ILogger<HomeController> _logger;

        public HomeController(PedidoService pedidoService, ILogger<HomeController> logger)
        {
            _pedidoService = pedidoService;
            _logger = logger;
        }

        // Vista principal
        public async Task<IActionResult> Index()
        {
            var clientes = await _pedidoService.ObtenerClientesAsync();
            var productos = await _pedidoService.ObtenerProductosAsync();

            ViewBag.Clientes = clientes;
            ViewBag.Productos = productos;

            return View();
        }

        // Vista de listado de pedidos
        public async Task<IActionResult> Pedidos()
        {
            var pedidos = await _pedidoService.ObtenerPedidosAsync();
            return View(pedidos);
        }

        // Crear pedido - Escenario 1
        [HttpPost]
        public async Task<IActionResult> CrearPedido([FromBody] PedidoCreateDto dto)
        {
            try
            {
                // Escenario 7: Verificar permisos (simulado)
                var tienePermisos = true; 

                if (!tienePermisos)
                {
                    return Json(new { success = false, message = "No tiene permisos para crear pedidos" });
                }

                var resultado = await _pedidoService.CrearPedidoAsync(dto);

                return Json(new
                {
                    success = resultado.success,
                    message = resultado.message,
                    pedidoId = resultado.pedidoId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al crear pedido");
                return Json(new { success = false, message = "Error al procesar el pedido: " + ex.Message });
            }
        }

        // Guardar nota - Escenario 2
        [HttpPost]
        public async Task<IActionResult> GuardarNota([FromBody] NotaRequest request)
        {
            try
            {
                var resultado = await _pedidoService.GuardarNotaAsync(request.PedidoId, request.Nota);

                if (resultado)
                {
                    return Json(new { success = true, message = "Nota guardada exitosamente" });
                }

                return Json(new { success = false, message = "No se encontró el pedido" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al guardar nota");
                return Json(new { success = false, message = "Error al guardar la nota" });
            }
        }

        // Obtener clientes
        [HttpGet]
        public async Task<IActionResult> ObtenerClientes()
        {
            try
            {
                var clientes = await _pedidoService.ObtenerClientesAsync();
                return Json(new { success = true, data = clientes });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener clientes");
                return Json(new { success = false, message = "Error al obtener clientes" });
            }
        }

        // Obtener productos
        [HttpGet]
        public async Task<IActionResult> ObtenerProductos()
        {
            try
            {
                var productos = await _pedidoService.ObtenerProductosAsync();
                return Json(new { success = true, data = productos });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener productos");
                return Json(new { success = false, message = "Error al obtener productos" });
            }
        }

        // Obtener pedido por ID
        [HttpGet]
        public async Task<IActionResult> ObtenerPedido(int id)
        {
            try
            {
                var pedido = await _pedidoService.ObtenerPedidoPorIdAsync(id);

                if (pedido == null)
                {
                    return Json(new { success = false, message = "Pedido no encontrado" });
                }

                return Json(new { success = true, data = pedido });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener pedido");
                return Json(new { success = false, message = "Error al obtener el pedido" });
            }
        }

        // Error
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = System.Diagnostics.Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }

    public class NotaRequest
    {
        public int PedidoId { get; set; }
        public string Nota { get; set; } = string.Empty;
    }

    public class ErrorViewModel
    {
        public string? RequestId { get; set; }
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
    }
}
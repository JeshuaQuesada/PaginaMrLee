using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;
using MrLee.UI.Models;

namespace MrLee.UI.Controllers
{
    public class ProductosController : Controller
    {
        private string _connectionString = ConfigurationManager.ConnectionStrings["MrLeeDB"]?.ConnectionString;

        public ActionResult Index()
        {
            var productos = new List<Producto>();
            try
            {
                using (var conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = "SELECT id_producto, codigo, nombre, categoria, precio, stock, activo FROM dbo.productos ORDER BY id_producto DESC";
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                productos.Add(new Producto
                                {
                                    id_producto = (long)reader["id_producto"],
                                    codigo = reader["codigo"].ToString(),
                                    nombre = reader["nombre"].ToString(),
                                    categoria = reader["categoria"] != DBNull.Value ? reader["categoria"].ToString() : string.Empty,
                                    precio = (decimal)reader["precio"],
                                    stock = (int)reader["stock"],
                                    activo = (bool)reader["activo"]
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = ex.Message;
            }
            return View(productos);
        }

        public ActionResult Editar(long id)
        {
            var producto = new Producto();
            try
            {
                using (var conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = "SELECT id_producto, codigo, nombre, categoria, precio, stock, activo FROM dbo.productos WHERE id_producto = @id";
                        cmd.Parameters.AddWithValue("@id", id);
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                producto.id_producto = (long)reader["id_producto"];
                                producto.codigo = reader["codigo"].ToString();
                                producto.nombre = reader["nombre"].ToString();
                                producto.categoria = reader["categoria"] != DBNull.Value ? reader["categoria"].ToString() : string.Empty;
                                producto.precio = (decimal)reader["precio"];
                                producto.stock = (int)reader["stock"];
                                producto.activo = (bool)reader["activo"];
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = ex.Message;
            }
            return View(producto);
        }

        public ActionResult Crear()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Guardar(long id, string codigo, string nombre, string categoria, decimal precio, int stock)
        {
            try
            {
                using (var conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = conn.CreateCommand())
                    {
                        if (id == 0)
                        {
                            cmd.CommandText = @"
                                INSERT INTO dbo.productos (codigo, nombre, categoria, precio, stock, activo)
                                VALUES (@codigo, @nombre, @categoria, @precio, @stock, 1)
                            ";
                        }
                        else
                        {
                            cmd.CommandText = @"
                                UPDATE dbo.productos
                                SET codigo = @codigo, nombre = @nombre, categoria = @categoria, precio = @precio, stock = @stock
                                WHERE id_producto = @id
                            ";
                            cmd.Parameters.AddWithValue("@id", id);
                        }
                        cmd.Parameters.AddWithValue("@codigo", codigo);
                        cmd.Parameters.AddWithValue("@nombre", nombre);
                        cmd.Parameters.AddWithValue("@categoria", string.IsNullOrEmpty(categoria) ? (object)DBNull.Value : categoria);
                        cmd.Parameters.AddWithValue("@precio", precio);
                        cmd.Parameters.AddWithValue("@stock", stock);
                        cmd.ExecuteNonQuery();
                    }
                }
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                ViewBag.Error = ex.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        public ActionResult Eliminar(long id)
        {
            try
            {
                using (var conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = "DELETE FROM dbo.productos WHERE id_producto = @id";
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.ExecuteNonQuery();
                    }
                }
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                ViewBag.Error = ex.Message;
                return RedirectToAction("Index");
            }
        }
    }
}

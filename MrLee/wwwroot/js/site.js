document.addEventListener('DOMContentLoaded', function () {
    initializePedidoForm();
});


// Inicializar Formulario

function initializePedidoForm() {
    const form = document.getElementById('formPedido');
    const btnLimpiar = document.getElementById('btnLimpiar');
    const tipoClienteRadios = document.querySelectorAll('input[name="tipoCliente"]');

    // Configurar fecha mínima y máxima
    setupDateLimits();

    // Manejar cambio de tipo de cliente
    tipoClienteRadios.forEach(radio => {
        radio.addEventListener('change', handleTipoClienteChange);
    });

    // Manejar envío del formulario
    if (form) {
        form.addEventListener('submit', handleFormSubmit);
    }

    // Manejar botón limpiar
    if (btnLimpiar) {
        btnLimpiar.addEventListener('click', limpiarFormulario);
    }

    // Validación en tiempo real de distancia
    const distanciaInput = document.getElementById('distancia');
    if (distanciaInput) {
        distanciaInput.addEventListener('input', validarDistancia);
    }

    // Validación en tiempo real de teléfono
    const telefonoInput = document.getElementById('telefono');
    if (telefonoInput) {
        telefonoInput.addEventListener('input', validarTelefono);
    }
}

// Configurar límites de fecha
function setupDateLimits() {
    const fechaInput = document.getElementById('fecha');
    if (!fechaInput) return;

    // Fecha mínima: hoy
    const hoy = new Date();
    const minDate = hoy.toISOString().split('T')[0];
    fechaInput.min = minDate;

    // Fecha máxima: 2 meses adelante
    const maxDate = new Date();
    maxDate.setMonth(maxDate.getMonth() + 2);
    fechaInput.max = maxDate.toISOString().split('T')[0];

    // Establecer fecha por defecto
    fechaInput.value = minDate;
}


// Manejar cambio de tipo de cliente

function handleTipoClienteChange(e) {
    const clienteExistente = document.getElementById('clienteExistente');
    const clienteNuevo = document.getElementById('clienteNuevo');
    const clienteIdSelect = document.getElementById('clienteId');
    const clienteNombreInput = document.getElementById('clienteNombre');

    if (e.target.value === 'existente') {
        clienteExistente.classList.remove('hidden');
        clienteNuevo.classList.add('hidden');
        clienteIdSelect.required = true;
        clienteNombreInput.required = false;
        clienteNombreInput.value = '';
    } else {
        clienteExistente.classList.add('hidden');
        clienteNuevo.classList.remove('hidden');
        clienteIdSelect.required = false;
        clienteIdSelect.value = '';
        clienteNombreInput.required = true;
    }
}


// Validar distancia (Escenario 3)

function validarDistancia(e) {
    const distancia = parseFloat(e.target.value);

    if (distancia > 10) {
        mostrarNotificacion('La distancia máxima permitida es 10 km', 'error');
        e.target.value = 10;
    }
}


// Validar teléfono (Escenario 5)

function validarTelefono(e) {
    const telefono = e.target.value;
    const regex = /^[\d\s\-\+\(\)]+$/;

    if (telefono && !regex.test(telefono)) {
        e.target.setCustomValidity('Use solo números, espacios, guiones o paréntesis');
    } else {
        e.target.setCustomValidity('');
    }
}


// Manejar envío del formulario

async function handleFormSubmit(e) {
    e.preventDefault();

    const form = e.target;
    const submitBtn = form.querySelector('button[type="submit"]');

    // Deshabilitar botón mientras se procesa
    submitBtn.disabled = true;
    submitBtn.textContent = '⏳ Procesando...';

    // Recopilar datos del formulario
    const formData = recopilarDatosFormulario(form);

    // Validar datos (Escenario 4 y 5)
    const validacion = validarDatosFormulario(formData);
    if (!validacion.isValid) {
        mostrarNotificacion(validacion.message, 'error');
        submitBtn.disabled = false;
        submitBtn.textContent = '✅ Crear Pedido';
        return;
    }

    try {
        // Enviar pedido al servidor
        const response = await fetch('/Home/CrearPedido', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        const result = await response.json();

        if (result.success) {
            // Escenario 1: Creación exitosa
            mostrarNotificacion(`✅ ${result.message}`, 'success');
            limpiarFormulario();

            // Redirigir al listado después de 2 segundos
            setTimeout(() => {
                window.location.href = '/Home/Pedidos';
            }, 2000);
        } else {
            // Escenario 4, 5, 6: Errores de validación
            mostrarNotificacion(`❌ ${result.message}`, 'error');
        }
    } catch (error) {
        console.error('Error:', error);
        mostrarNotificacion('❌ Error al procesar el pedido. Intente nuevamente.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = '✅ Crear Pedido';
    }
}


// Recopilar datos del formulario

function recopilarDatosFormulario(form) {
    const tipoCliente = form.querySelector('input[name="tipoCliente"]:checked').value;

    const data = {
        productos: form.productos.value.trim(),
        cantidades: parseInt(form.cantidades.value) || 0,
        direccion: form.direccion.value.trim(),
        telefono: form.telefono.value.trim(),
        prioridad: form.prioridad.value,
        fecha: form.fecha.value,
        notas: form.notas.value.trim() || null,
        distanciaKm: form.distancia.value ? parseFloat(form.distancia.value) : null
    };

    if (tipoCliente === 'existente') {
        data.clienteId = parseInt(form.clienteId.value) || null;
    } else {
        data.clienteNombre = form.clienteNombre.value.trim();
    }

    return data;
}


// Validar datos del formulario

function validarDatosFormulario(data) {
    const errores = [];

    // Validar cliente (Escenario 6)
    if (!data.clienteId && !data.clienteNombre) {
        errores.push('Debe seleccionar un cliente existente o ingresar un nombre para crear uno nuevo');
    }

    // Validar productos (Escenario 4)
    if (!data.productos) {
        errores.push('Los productos son obligatorios');
    }

    // Validar cantidades (Escenario 4)
    if (!data.cantidades || data.cantidades <= 0) {
        errores.push('Las cantidades deben ser mayores a 0');
    }

    // Validar dirección (Escenario 4)
    if (!data.direccion) {
        errores.push('La dirección es obligatoria');
    }

    // Validar teléfono (Escenario 4 y 5)
    if (!data.telefono) {
        errores.push('El teléfono es obligatorio');
    } else {
        const regex = /^[\d\s\-\+\(\)]+$/;
        if (!regex.test(data.telefono)) {
            errores.push('Formato de teléfono inválido');
        }
    }

    // Validar fecha (Escenario 5)
    if (!data.fecha) {
        errores.push('La fecha es obligatoria');
    } else {
        const fecha = new Date(data.fecha);
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);

        const fechaLimite = new Date();
        fechaLimite.setMonth(fechaLimite.getMonth() + 2);

        if (fecha < hoy) {
            errores.push('La fecha no puede ser anterior a hoy');
        } else if (fecha > fechaLimite) {
            errores.push('La fecha no puede ser posterior a 2 meses adelante');
        }
    }

    // Validar distancia (Escenario 3)
    if (data.distanciaKm && data.distanciaKm > 10) {
        errores.push('La distancia máxima permitida es 10 km');
    }

    return {
        isValid: errores.length === 0,
        message: errores.join('. ')
    };
}


// Limpiar formulario

function limpiarFormulario() {
    const form = document.getElementById('formPedido');
    if (form) {
        form.reset();

        // Restablecer tipo de cliente a "existente"
        const radioExistente = form.querySelector('input[name="tipoCliente"][value="existente"]');
        if (radioExistente) {
            radioExistente.checked = true;
            handleTipoClienteChange({ target: radioExistente });
        }

        // Restablecer fecha
        setupDateLimits();
    }
}


// Mostrar notificación

function mostrarNotificacion(mensaje, tipo = 'success') {
    const notification = document.getElementById('notification');
    if (!notification) return;

    notification.className = `notification ${tipo}`;
    notification.textContent = mensaje;
    notification.classList.remove('hidden');

    // Auto-ocultar después de 5 segundos
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 5000);

    // Scroll hacia la notificación
    notification.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}


// Guardar nota (Escenario 2)

async function guardarNota(pedidoId, nota) {
    try {
        const response = await fetch('/Home/GuardarNota', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                pedidoId: pedidoId,
                nota: nota
            })
        });

        const result = await response.json();

        if (result.success) {
            mostrarNotificacion('✅ Nota guardada exitosamente', 'success');
            return true;
        } else {
            mostrarNotificacion('❌ Error al guardar la nota', 'error');
            return false;
        }
    } catch (error) {
        console.error('Error:', error);
        mostrarNotificacion('❌ Error al guardar la nota', 'error');
        return false;
    }
}

// Utilidades

// Formatear fecha
function formatearFecha(fecha) {
    const f = new Date(fecha);
    const dia = String(f.getDate()).padStart(2, '0');
    const mes = String(f.getMonth() + 1).padStart(2, '0');
    const año = f.getFullYear();
    return `${dia}/${mes}/${año}`;
}

// Formatear hora
function formatearHora(fecha) {
    const f = new Date(fecha);
    const hora = String(f.getHours()).padStart(2, '0');
    const minutos = String(f.getMinutes()).padStart(2, '0');
    return `${hora}:${minutos}`;
}
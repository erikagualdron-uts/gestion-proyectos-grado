// Validaciones del navegador (se repiten en el servidor, RNF-06) y mostrar/ocultar contraseña.
(function () {
  'use strict';

  // Botón de ojo en los campos de contraseña
  document.querySelectorAll('.ver-clave').forEach(function (boton) {
    boton.addEventListener('click', function () {
      var campo = document.getElementById(boton.getAttribute('data-target'));
      var icono = boton.querySelector('i');
      var visible = campo.type === 'text';
      campo.type = visible ? 'password' : 'text';
      icono.className = visible ? 'bi bi-eye' : 'bi bi-eye-slash';
      boton.setAttribute('aria-label', visible ? 'Mostrar contraseña' : 'Ocultar contraseña');
    });
  });

  // La confirmación de contraseña debe coincidir
  function revisarConfirmacion(form) {
    var clave = form.querySelector('[name="clave"]');
    var confirmar = form.querySelector('[name="confirmar"]');
    if (clave && confirmar) {
      confirmar.setCustomValidity(clave.value !== confirmar.value ? 'No coincide' : '');
    }
  }

  document.querySelectorAll('form.needs-validation').forEach(function (form) {
    form.addEventListener('input', function () { revisarConfirmacion(form); });
    form.addEventListener('submit', function (evento) {
      revisarConfirmacion(form);
      var correo = form.querySelector('[name="correo"]');
      if (correo) { correo.value = correo.value.trim().toLowerCase(); }
      if (!form.checkValidity()) {
        evento.preventDefault();
        evento.stopPropagation();
      }
      form.classList.add('was-validated');
    });
  });
})();

// Comportamiento común de listados: filtros automáticos, registros por página y ventanas de detalle.
(function () {
  'use strict';

  // Los filtros marcados con data-autoenviar envían el formulario al cambiar
  document.querySelectorAll('[data-autoenviar]').forEach(function (campo) {
    campo.addEventListener('change', function () {
      var form = campo.form;
      var pag = form.querySelector('[name="pag"]');
      if (pag) { pag.value = '1'; }
      form.submit();
    });
  });

  // Selector de "registros por página": conserva los filtros y vuelve a la página 1
  document.querySelectorAll('select[data-por-pagina]').forEach(function (selector) {
    selector.addEventListener('change', function () {
      var url = new URL(window.location.href);
      url.searchParams.set('pp', selector.value);
      url.searchParams.set('pag', '1');
      window.location.href = url.toString();
    });
  });

  // Ventanas modales: el botón que las abre trae los datos en atributos data-*.
  // [data-llenar="clave"] recibe el texto y [data-llenar-valor="clave"] recibe el valor de un campo.
  document.querySelectorAll('.modal').forEach(function (modal) {
    modal.addEventListener('show.bs.modal', function (evento) {
      var boton = evento.relatedTarget;
      if (!boton) { return; }
      var formulario = modal.querySelector('form');
      if (formulario) { formulario.reset(); formulario.classList.remove('was-validated'); }
      // data-llenar-accion: la ruta del proceso viene en el botón (data-accion-url)
      modal.querySelectorAll('form[data-llenar-accion]').forEach(function (f) {
        if (boton.dataset.accionUrl) { f.action = boton.dataset.accionUrl; }
      });
      // data-mostrar-si="clave:valor": muestra el bloque solo si el botón trae ese dato
      modal.querySelectorAll('[data-mostrar-si]').forEach(function (bloque) {
        var par = bloque.getAttribute('data-mostrar-si').split(':');
        // valor "*": se muestra solo si el botón trae ese dato con contenido
        // valor "!": se muestra solo si el dato está vacío
        if (par[1] === '*') { bloque.hidden = !boton.dataset[par[0]]; }
        else if (par[1] === '!') { bloque.hidden = !!boton.dataset[par[0]]; }
        else { bloque.hidden = (boton.dataset[par[0]] !== par[1]); }
      });
      // data-clases="clave|Valor=clase|Valor=clase": cambia la clase del elemento según el dato del botón
      modal.querySelectorAll('[data-clases]').forEach(function (nodo) {
        var partes = nodo.getAttribute('data-clases').split('|');
        var valor = boton.dataset[partes.shift()];
        var mapa = {};
        partes.forEach(function (par) { var i = par.indexOf('='); mapa[par.slice(0, i)] = par.slice(i + 1); });
        Object.keys(mapa).forEach(function (k) { nodo.classList.remove(mapa[k]); });
        if (mapa[valor]) { nodo.classList.add(mapa[valor]); }
      });
      // data-llenar-href="clave": el enlace toma su dirección del botón
      modal.querySelectorAll('[data-llenar-href]').forEach(function (enlace) {
        var destino = boton.dataset[enlace.getAttribute('data-llenar-href')] || '';
        enlace.setAttribute('href', /^(https?:\/\/|\/)/i.test(destino) ? destino : '#');
      });
      modal.querySelectorAll('[data-llenar]').forEach(function (nodo) {
        var valor = boton.dataset[nodo.getAttribute('data-llenar')];
        nodo.textContent = (valor && valor.length) ? valor : (nodo.getAttribute('data-vacio') || '—');
      });
      modal.querySelectorAll('[data-llenar-valor]').forEach(function (campo) {
        campo.value = boton.dataset[campo.getAttribute('data-llenar-valor')] || '';
      });
      // data-excluir="clave1,clave2": deshabilita las opciones cuyo valor coincide con esos datos del botón
      modal.querySelectorAll('select[data-excluir]').forEach(function (lista) {
        var prohibidos = lista.getAttribute('data-excluir').split(',').map(function (c) { return boton.dataset[c]; });
        Array.prototype.forEach.call(lista.options, function (opcion) {
          var excluida = opcion.value !== '' && prohibidos.indexOf(opcion.value) !== -1;
          opcion.disabled = excluida;
          opcion.hidden = excluida;
        });
      });
    });
  });

  // select[data-ayudas="VALOR=texto|VALOR=texto"]: muestra bajo la lista la explicación de la opción elegida
  document.querySelectorAll('select[data-ayudas]').forEach(function (lista) {
    var destino = document.querySelector('[data-ayuda-de="' + lista.id + '"]');
    if (!destino) { return; }
    var textos = {};
    lista.getAttribute('data-ayudas').split('|').forEach(function (par) {
      var i = par.indexOf('=');
      textos[par.slice(0, i)] = par.slice(i + 1);
    });
    function mostrar() { destino.textContent = textos[lista.value] || ''; }
    lista.addEventListener('change', mostrar);
    mostrar();
  });

  // Decisión sobre una cuenta: aprobar exige nivel; rechazar exige observación y confirmación
  document.querySelectorAll('form[data-decisiones]').forEach(function (form) {
    form.addEventListener('submit', function (evento) {
      var decision = evento.submitter ? evento.submitter.value : '';
      var nivel = form.querySelector('[name="nivel"]');
      var observacion = form.querySelector('[name="observacion"]');
      form.querySelectorAll('[data-obligatoria-aprobar]').forEach(function (campo) {
        campo.required = (decision === 'APROBAR') && !campo.closest('[hidden]');
      });
      if (nivel) { nivel.required = (decision === 'APROBAR'); }
      if (observacion) { observacion.required = (decision === 'RECHAZAR' || decision === 'APLAZAR'); }
      form.classList.add('was-validated');
      if (!form.checkValidity()) { evento.preventDefault(); return; }
      if (decision === 'RECHAZAR' && !window.confirm('¿Seguro que deseas rechazar? Esta decisión es extrema y queda registrada.')) {
        evento.preventDefault();
      }
    });
  });

  // Asignación: el director y el evaluador no pueden ser la misma persona
  document.querySelectorAll('form[data-asignacion]').forEach(function (form) {
    var director = form.querySelector('[name="director"]');
    var evaluador = form.querySelector('[name="evaluador"]');
    // El docente elegido en una lista no se ofrece en la otra
    function excluirEn(lista, valor) {
      Array.prototype.forEach.call(lista.options, function (opcion) {
        var fuera = valor !== '' && opcion.value === valor;
        opcion.disabled = fuera;
        opcion.hidden = fuera;
      });
    }
    function revisar() {
      excluirEn(evaluador, director.value);
      excluirEn(director, evaluador.value);
      var iguales = director.value !== '' && director.value === evaluador.value;
      evaluador.setCustomValidity(iguales ? 'Deben ser distintos' : '');
      evaluador.classList.toggle('is-invalid', iguales);
    }
    director.addEventListener('change', revisar);
    evaluador.addEventListener('change', revisar);
    var ventana = form.closest('.modal');
    if (ventana) { ventana.addEventListener('show.bs.modal', revisar); }
    form.addEventListener('submit', function (evento) {
      revisar();
      if (!form.checkValidity()) { evento.preventDefault(); }
    });
  });

  // Confirmaciones antes de enviar (data-confirmar="mensaje")
  document.querySelectorAll('form[data-confirmar]').forEach(function (form) {
    form.addEventListener('submit', function (evento) {
      if (!window.confirm(form.getAttribute('data-confirmar'))) { evento.preventDefault(); }
    });
  });
})();

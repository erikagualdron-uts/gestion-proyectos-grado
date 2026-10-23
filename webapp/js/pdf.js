/* Descarga de una sección de la página como PDF (html2pdf.js, en el navegador: no se envía nada al servidor).
   <button data-descargar-pdf="id-del-contenedor" data-pdf-nombre="archivo" data-pdf-titulo="Título del informe">
   El contenedor puede tener un div.pdf-cabecera[hidden] que se rellena con el título y la fecha solo durante la captura. */
(function () {
  if (typeof html2pdf === 'undefined') { return; }

  document.querySelectorAll('[data-descargar-pdf]').forEach(function (boton) {
    boton.addEventListener('click', function () {
      var contenedor = document.getElementById(boton.getAttribute('data-descargar-pdf'));
      if (!contenedor) { return; }
      var nombre = (boton.getAttribute('data-pdf-nombre') || 'informe') + '.pdf';
      var titulo = boton.getAttribute('data-pdf-titulo') || 'Informe';
      var textoOriginal = boton.innerHTML;
      var cabecera = contenedor.querySelector('.pdf-cabecera');
      // El PDF se arma con un ancho fijo: así las tarjetas y los gráficos (que se redibujan al cambiar el ancho)
      // quedan del mismo tamaño que en la captura y no se salen de la hoja.
      var estiloOriginal = contenedor.getAttribute('style');
      contenedor.style.width = '1000px';
      contenedor.style.maxWidth = '1000px';
      window.dispatchEvent(new Event('resize'));

      boton.disabled = true;
      boton.innerHTML = '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Generando PDF…';
      document.body.classList.add('generando-pdf');
      if (cabecera) {
        var fecha = new Date().toLocaleString('es-CO', { dateStyle: 'long', timeStyle: 'short' });
        cabecera.innerHTML = '<div class="pdf-sistema">Sistema de Gestión de Proyectos de Grado · UTS</div>' +
          '<h1 class="pdf-titulo"></h1><div class="pdf-fecha">Generado el ' + fecha + '</div>';
        cabecera.querySelector('.pdf-titulo').textContent = titulo;
        cabecera.hidden = false;
      }

      function restaurar() {
        if (estiloOriginal === null) { contenedor.removeAttribute('style'); } else { contenedor.setAttribute('style', estiloOriginal); }
        window.dispatchEvent(new Event('resize'));
        document.body.classList.remove('generando-pdf');
        if (cabecera) { cabecera.hidden = true; cabecera.innerHTML = ''; }
        boton.disabled = false;
        boton.innerHTML = textoOriginal;
      }

      // Se espera para que los gráficos terminen de redibujarse con el ancho del PDF
      setTimeout(function () {
        html2pdf().set({
          margin: [8, 8, 8, 8],
          filename: nombre,
          image: { type: 'jpeg', quality: 0.95 },
          html2canvas: { scale: 2, useCORS: true, backgroundColor: '#F5F8F6', scrollX: 0, scrollY: 0, windowWidth: 1280 },
          jsPDF: { unit: 'mm', format: 'a4', orientation: 'landscape' },
          pagebreak: { mode: ['css', 'legacy'], avoid: ['.grafico-tarjeta', '.tarjeta.resumen', 'tr'] }
        }).from(contenedor).save().then(restaurar).catch(function () {
          restaurar();
          alert('No se pudo generar el PDF. Inténtalo de nuevo.');
        });
      }, 700);
    });
  });
})();

/* Dibuja los gráficos del panel con Chart.js. Los datos llegan desde el servidor en atributos data-* del canvas:
   data-grafico  = barras | barras-horizontal | barras-apiladas | dona
   data-etiquetas = "Etiqueta 1|Etiqueta 2"
   data-series    = "Serie A=1,2,3|Serie B=4,5,6"
   data-colores   = "#14684B|#C4D600" (un color por serie; en la dona, uno por etiqueta) */
(function () {
  if (typeof Chart === 'undefined') { return; }
  var paleta = ['#0B3D2E', '#14684B', '#3E9B74', '#7CC4A0', '#C4D600', '#A8B5AE'];

  function partir(texto, separador) {
    var limpio = (texto || '').replace(new RegExp('\\' + separador + '+$'), '');
    return limpio === '' ? [] : limpio.split(separador);
  }

  Chart.defaults.font.family = "'Inter', system-ui, sans-serif";
  Chart.defaults.color = '#5E6B66';
  Chart.defaults.animation = false;

  document.querySelectorAll('canvas[data-grafico]').forEach(function (lienzo) {
    var tipo = lienzo.getAttribute('data-grafico');
    var etiquetas = partir(lienzo.getAttribute('data-etiquetas'), '|');
    var colores = partir(lienzo.getAttribute('data-colores'), '|');
    var series = partir(lienzo.getAttribute('data-series'), '|').map(function (s) {
      var i = s.indexOf('=');
      return { nombre: s.slice(0, i), datos: partir(s.slice(i + 1), ',').map(Number) };
    });
    if (etiquetas.length === 0 || series.length === 0) { return; }

    var esDona = tipo === 'dona';
    var horizontal = tipo === 'barras-horizontal';
    var apiladas = tipo === 'barras-apiladas';

    var conjuntos = series.map(function (s, n) {
      var color = colores[n] || paleta[n % paleta.length];
      return {
        label: s.nombre,
        data: s.datos,
        backgroundColor: esDona ? (colores.length ? colores : paleta) : color,
        borderColor: esDona ? '#fff' : color,
        borderWidth: esDona ? 2 : 0,
        borderRadius: esDona ? 0 : 4,
        maxBarThickness: 28
      };
    });

    var opciones = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: esDona || series.length > 1, position: 'bottom', labels: { boxWidth: 12, usePointStyle: true } } }
    };
    if (!esDona) {
      if (horizontal) { opciones.indexAxis = 'y'; }
      opciones.scales = {
        x: { stacked: apiladas, grid: { display: horizontal }, ticks: { precision: 0 } },
        y: { stacked: apiladas, beginAtZero: true, grid: { color: '#E3E8E5' }, ticks: { precision: 0 } }
      };
    }

    new Chart(lienzo, { type: esDona ? 'doughnut' : 'bar', data: { labels: etiquetas, datasets: conjuntos }, options: opciones });
  });

  // Al imprimir, cada gráfico se reemplaza por una imagen de su estado actual: el lienzo conserva el tamaño de pantalla
  // y se salía de su tarjeta. Al terminar de imprimir se quitan las imágenes.
  window.addEventListener('beforeprint', function () {
    document.querySelectorAll('canvas[data-grafico]').forEach(function (lienzo) {
      if (lienzo.nextElementSibling && lienzo.nextElementSibling.classList.contains('grafico-imprimir')) { return; }
      var imagen = document.createElement('img');
      imagen.className = 'grafico-imprimir';
      imagen.alt = lienzo.getAttribute('aria-label') || 'Gráfico';
      imagen.width = lienzo.width;
      imagen.height = lienzo.height;
      imagen.src = lienzo.toDataURL('image/png');
      lienzo.insertAdjacentElement('afterend', imagen);
    });
  });
  window.addEventListener('afterprint', function () {
    document.querySelectorAll('img.grafico-imprimir').forEach(function (imagen) { imagen.remove(); });
  });
})();

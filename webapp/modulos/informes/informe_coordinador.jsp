<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/informe_filtros.jsp" %>
<%-- Panel de control (RF-60, RF-62), solo para el coordinador, en dos pestañas: Resumen (indicadores y gráficos con Chart.js)
     y Proyectos (informe de estado con filtros). Se imprime desde el navegador. --%>
<c:set var="titulo" value="Panel de control" scope="request" />
<c:set var="vista" value="${fn:contains(',resumen,proyectos,', ',' += param.vista += ',') ? param.vista : 'resumen'}" />
<c:if test="${vista == 'resumen'}"><c:set var="usarGraficos" value="si" scope="request" /></c:if>

<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<%-- ================= Resumen ================= --%>
<c:if test="${vista == 'resumen'}">
  <sql:query var="resumen" dataSource="${bd}">
    SELECT COALESCE(SUM(estado_general = 'EN_CURSO'), 0) AS en_curso, COALESCE(SUM(estado_general = 'APTO_GRADUACION'), 0) AS listos,
           COALESCE(SUM(estado_general = 'CERRADO'), 0) AS cerrados, COALESCE(SUM(id_director IS NULL OR id_evaluador IS NULL), 0) AS sin_asignar
    FROM proyecto
  </sql:query>
  <c:set var="rs" value="${resumen.rows[0]}" />
  <c:set var="totalProyectos" value="${rs.en_curso + rs.listos + rs.cerrados}" />

  <sql:query var="porFase" dataSource="${bd}">
    SELECT f.id_fase, f.nombre, COUNT(pr.id_proyecto) AS n
    FROM fase f LEFT JOIN proyecto pr ON pr.fase_actual = f.id_fase
    GROUP BY f.id_fase, f.nombre ORDER BY f.id_fase
  </sql:query>
  <c:set var="etFase" value="" /><c:set var="daFase" value="" />
  <c:forEach var="f" items="${porFase.rows}">
    <c:set var="etFase" value="${etFase += f.id_fase += '. ' += f.nombre += '|'}" />
    <c:set var="daFase" value="${daFase += f.n += ','}" />
  </c:forEach>

  <sql:query var="porDocente" dataSource="${bd}">
    SELECT u.nombre_completo AS nombre,
           COALESCE(SUM(pr.id_director = u.id_usuario), 0) AS como_director,
           COALESCE(SUM(pr.id_evaluador = u.id_usuario), 0) AS como_evaluador
    FROM usuario u
    JOIN rol r ON r.id_rol = u.id_rol
    JOIN proyecto pr ON (pr.id_director = u.id_usuario OR pr.id_evaluador = u.id_usuario) AND pr.estado_general = 'EN_CURSO'
    WHERE r.nombre = 'DOCENTE'
    GROUP BY u.id_usuario, u.nombre_completo
    ORDER BY (como_director + como_evaluador) DESC, nombre LIMIT 10
  </sql:query>
  <c:set var="etDoc" value="" /><c:set var="daDir" value="" /><c:set var="daEva" value="" />
  <c:forEach var="d" items="${porDocente.rows}">
    <c:set var="etDoc" value="${etDoc += fn:replace(d.nombre, '|', ' ') += '|'}" />
    <c:set var="daDir" value="${daDir += d.como_director += ','}" />
    <c:set var="daEva" value="${daEva += d.como_evaluador += ','}" />
  </c:forEach>

  <sql:query var="porPqrs" dataSource="${bd}">
    SELECT CASE tipo WHEN 'PRORROGA' THEN 'Prórroga' WHEN 'CAMBIO_DIRECTOR' THEN 'Cambio de director' WHEN 'PETICION' THEN 'Petición'
             WHEN 'QUEJA' THEN 'Queja' WHEN 'RECLAMO' THEN 'Reclamo' ELSE 'Sugerencia' END AS tipo_texto,
           SUM(estado = 'PENDIENTE') AS pendientes, SUM(estado = 'APROBADO') AS aprobadas, SUM(estado = 'RECHAZADO') AS rechazadas
    FROM pqrs GROUP BY tipo ORDER BY tipo
  </sql:query>
  <c:set var="etPqrs" value="" /><c:set var="daPen" value="" /><c:set var="daApr" value="" /><c:set var="daRec" value="" />
  <c:forEach var="t" items="${porPqrs.rows}">
    <c:set var="etPqrs" value="${etPqrs += t.tipo_texto += '|'}" />
    <c:set var="daPen" value="${daPen += t.pendientes += ','}" />
    <c:set var="daApr" value="${daApr += t.aprobadas += ','}" />
    <c:set var="daRec" value="${daRec += t.rechazadas += ','}" />
  </c:forEach>

  <sql:query var="porDia" dataSource="${bd}">
    SELECT DATE_FORMAT(MIN(fecha_evento), '%d/%m') AS dia, COUNT(*) AS n
    FROM historial_version
    WHERE fecha_evento >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
    GROUP BY DATE(fecha_evento) ORDER BY DATE(fecha_evento)
  </sql:query>
  <c:set var="etDia" value="" /><c:set var="daDia" value="" /><c:set var="totalDias" value="${0}" />
  <c:forEach var="d" items="${porDia.rows}">
    <c:set var="etDia" value="${etDia += d.dia += '|'}" />
    <c:set var="daDia" value="${daDia += d.n += ','}" />
    <c:set var="totalDias" value="${totalDias + d.n}" />
  </c:forEach>
</c:if>

<%-- ================= Proyectos ================= --%>
<c:if test="${vista == 'proyectos'}">
  <sql:query var="docentes" dataSource="${bd}">
    SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1 ORDER BY u.nombre_completo
  </sql:query>
  <sql:query var="conteo" dataSource="${bd}">
    SELECT COUNT(*) AS total ${desdeInforme}
    <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
    <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
    <sql:param value="${filtroDirector}" /><sql:param value="${filtroDirector}" /><sql:param value="${filtroEvaluador}" /><sql:param value="${filtroEvaluador}" />
  </sql:query>
  <c:set var="totalRegistros" value="${conteo.rows[0].total}" />
  <c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
  <c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
  <c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />
  <sql:query var="proyectos" dataSource="${bd}">
    SELECT ${columnasInforme} ${desdeInforme}
    ORDER BY pr.id_proyecto DESC LIMIT ? OFFSET ?
    <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
    <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
    <sql:param value="${filtroDirector}" /><sql:param value="${filtroDirector}" /><sql:param value="${filtroEvaluador}" /><sql:param value="${filtroEvaluador}" />
    <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
  </sql:query>
  <c:url var="pagBase" value="/modulos/informes/informe_coordinador.jsp">
    <c:param name="vista" value="proyectos" />
    <c:param name="q" value="${q}" /><c:param name="fase" value="${filtroFase}" /><c:param name="estado" value="${filtroEstado}" />
    <c:param name="director" value="${filtroDirector}" /><c:param name="evaluador" value="${filtroEvaluador}" />
  </c:url>
</c:if>

<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Panel de control</h1>
    <p class="descripcion-pagina mb-3">Vista general del sistema: indicadores y gráficos, y estado de cada proyecto.</p>
  </div>
  <div class="d-flex flex-wrap gap-2 mb-3 no-imprimir">
    <button type="button" class="btn btn-outline-uts" data-imprimir><i class="bi bi-printer me-1"></i>Imprimir</button>
  </div>
</div>

<ul class="nav pestanas no-imprimir" role="tablist">
  <li class="nav-item"><a class="nav-link ${vista == 'resumen' ? 'active' : ''}" href="${ctx}/modulos/informes/informe_coordinador.jsp?vista=resumen"><i class="bi bi-pie-chart me-1"></i>Resumen</a></li>
  <li class="nav-item"><a class="nav-link ${vista == 'proyectos' ? 'active' : ''}" href="${ctx}/modulos/informes/informe_coordinador.jsp?vista=proyectos"><i class="bi bi-folder2-open me-1"></i>Proyectos</a></li>
</ul>

<c:choose>
  <%-- ======================== RESUMEN ======================== --%>
  <c:when test="${vista == 'resumen'}">
    <div class="row g-3 mb-4">
      <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-hourglass-split"></i></span><div><div class="resumen-numero"><c:out value="${rs.en_curso}" /></div><div class="resumen-etiqueta">En curso</div></div></div></div>
      <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-mortarboard"></i></span><div><div class="resumen-numero"><c:out value="${rs.listos}" /></div><div class="resumen-etiqueta">Listos para sustentación</div></div></div></div>
      <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono rechazado"><i class="bi bi-x-circle"></i></span><div><div class="resumen-numero"><c:out value="${rs.cerrados}" /></div><div class="resumen-etiqueta">Cerrados</div></div></div></div>
      <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aplazado"><i class="bi bi-person-dash"></i></span><div><div class="resumen-numero"><c:out value="${rs.sin_asignar}" /></div><div class="resumen-etiqueta">Sin director o evaluador</div></div></div></div>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-12 col-lg-7">
        <div class="tarjeta grafico-tarjeta h-100">
          <h2>Proyectos por fase</h2>
          <div class="texto-sec">Cuántos proyectos están hoy en cada fase.</div>
          <c:choose>
            <c:when test="${totalProyectos > 0}">
              <div class="grafico-caja"><canvas data-grafico="barras" data-etiquetas="<c:out value='${etFase}' />" data-series="Proyectos=<c:out value='${daFase}' />" data-colores="#14684B" role="img" aria-label="Gráfico de barras de proyectos por fase"></canvas></div>
            </c:when>
            <c:otherwise><div class="grafico-vacio">Aún no hay proyectos.</div></c:otherwise>
          </c:choose>
        </div>
      </div>
      <div class="col-12 col-lg-5">
        <div class="tarjeta grafico-tarjeta h-100">
          <h2>Proyectos por estado</h2>
          <div class="texto-sec">En curso, listos para sustentación y cerrados.</div>
          <c:choose>
            <c:when test="${totalProyectos > 0}">
              <div class="grafico-caja"><canvas data-grafico="dona" data-etiquetas="En curso|Listos para sustentación|Cerrados" data-series="Proyectos=${rs.en_curso},${rs.listos},${rs.cerrados}" data-colores="#8A9A93|#14684B|#C0392B" role="img" aria-label="Gráfico de proyectos por estado"></canvas></div>
            </c:when>
            <c:otherwise><div class="grafico-vacio">Aún no hay proyectos.</div></c:otherwise>
          </c:choose>
        </div>
      </div>
      <div class="col-12 col-lg-6">
        <div class="tarjeta grafico-tarjeta h-100">
          <h2>Carga de los docentes</h2>
          <div class="texto-sec">Proyectos en curso de cada docente, como director y como evaluador.</div>
          <c:choose>
            <c:when test="${porDocente.rowCount > 0}">
              <div class="grafico-caja"><canvas data-grafico="barras-horizontal" data-etiquetas="<c:out value='${etDoc}' />" data-series="Como director=<c:out value='${daDir}' />|Como evaluador=<c:out value='${daEva}' />" data-colores="#14684B|#C4D600" role="img" aria-label="Gráfico de la carga de los docentes"></canvas></div>
            </c:when>
            <c:otherwise><div class="grafico-vacio">Aún no hay docentes con proyectos asignados.</div></c:otherwise>
          </c:choose>
        </div>
      </div>
      <div class="col-12 col-lg-6">
        <div class="tarjeta grafico-tarjeta h-100">
          <h2>PQRS por tipo y estado</h2>
          <div class="texto-sec">Solicitudes radicadas y cómo van.</div>
          <c:choose>
            <c:when test="${porPqrs.rowCount > 0}">
              <div class="grafico-caja"><canvas data-grafico="barras-apiladas" data-etiquetas="<c:out value='${etPqrs}' />" data-series="Pendientes=<c:out value='${daPen}' />|Aprobadas=<c:out value='${daApr}' />|Rechazadas=<c:out value='${daRec}' />" data-colores="#8A9A93|#14684B|#C0392B" role="img" aria-label="Gráfico de PQRS por tipo y estado"></canvas></div>
            </c:when>
            <c:otherwise><div class="grafico-vacio">Aún no hay PQRS radicadas.</div></c:otherwise>
          </c:choose>
        </div>
      </div>
      <div class="col-12">
        <div class="tarjeta grafico-tarjeta">
          <h2>Actividad de los últimos 30 días</h2>
          <div class="texto-sec"><c:out value="${totalDias}" /> evento(s) registrados. Cada barra es un día con actividad.</div>
          <c:choose>
            <c:when test="${porDia.rowCount > 0}">
              <div class="grafico-caja"><canvas data-grafico="barras" data-etiquetas="<c:out value='${etDia}' />" data-series="Eventos=<c:out value='${daDia}' />" data-colores="#0B3D2E" role="img" aria-label="Gráfico de eventos por día"></canvas></div>
            </c:when>
            <c:otherwise><div class="grafico-vacio">No hay actividad registrada en los últimos 30 días.</div></c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>
  </c:when>

  <%-- ======================== PROYECTOS ======================== --%>
  <c:otherwise>
    <form method="get" action="${ctx}/modulos/informes/informe_coordinador.jsp" class="row g-3 align-items-end mb-3 no-imprimir">
      <input type="hidden" name="vista" value="proyectos">
      <input type="hidden" name="pp" value="${pp}">
      <input type="hidden" name="pag" value="1">
      <div class="col-12 col-lg">
        <label for="q" class="form-label">Buscar</label>
        <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, título o estudiante" maxlength="120">
      </div>
      <div class="col-6 col-lg-auto">
        <label for="fase" class="form-label">Fase</label>
        <select class="form-select" id="fase" name="fase" data-autoenviar>
          <option value="0">Todas</option>
          <c:forEach var="n" begin="1" end="6"><option value="${n}" ${filtroFase == n ? 'selected' : ''}>Fase ${n}</option></c:forEach>
        </select>
      </div>
      <div class="col-6 col-lg-auto">
        <label for="estado" class="form-label">Estado</label>
        <select class="form-select" id="estado" name="estado" data-autoenviar>
          <option value="">Todos</option>
          <option value="EN_CURSO" ${filtroEstado == 'EN_CURSO' ? 'selected' : ''}>En curso</option>
          <option value="APTO_GRADUACION" ${filtroEstado == 'APTO_GRADUACION' ? 'selected' : ''}>Listo para sustentación</option>
          <option value="CERRADO" ${filtroEstado == 'CERRADO' ? 'selected' : ''}>Cerrado</option>
        </select>
      </div>
      <div class="col-6 col-lg-auto">
        <label for="director" class="form-label">Director</label>
        <select class="form-select" id="director" name="director" data-autoenviar>
          <option value="0">Todos</option>
          <c:forEach var="d" items="${docentes.rows}"><option value="${d.id_usuario}" ${filtroDirector == d.id_usuario ? 'selected' : ''}><c:out value="${d.nombre_completo}" /></option></c:forEach>
        </select>
      </div>
      <div class="col-6 col-lg-auto">
        <label for="evaluador" class="form-label">Evaluador</label>
        <select class="form-select" id="evaluador" name="evaluador" data-autoenviar>
          <option value="0">Todos</option>
          <c:forEach var="d" items="${docentes.rows}"><option value="${d.id_usuario}" ${filtroEvaluador == d.id_usuario ? 'selected' : ''}><c:out value="${d.nombre_completo}" /></option></c:forEach>
        </select>
      </div>
      <div class="col-12 col-lg-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
    </form>

    <c:choose>
      <c:when test="${proyectos.rowCount == 0}">
        <div class="vacio"><span class="icono-circulo"><i class="bi bi-bar-chart"></i></span><h3>No hay proyectos para mostrar</h3><p>Cambia la búsqueda o los filtros.</p></div>
      </c:when>
      <c:otherwise>
        <div class="tabla-envoltorio table-responsive">
          <table class="table tabla-uts">
            <thead><tr><th>Proyecto</th><th>Fase</th><th>Estado</th><th>Director</th><th>Evaluador</th><th>Último movimiento</th><th class="text-end no-imprimir">Acciones</th></tr></thead>
            <tbody>
              <c:forEach var="p" items="${proyectos.rows}">
                <tr>
                  <td style="min-width: 240px"><div class="fw-semibold"><c:out value="${p.codigo}" /> · <c:out value="${p.titulo}" /></div><div class="texto-sec"><c:out value="${p.estudiantes}" /></div></td>
                  <td style="white-space: nowrap">Fase <c:out value="${p.fase_actual}" /> · <c:out value="${p.fase}" /></td>
                  <td><span class="insignia insignia-${p.estado_general == 'EN_CURSO' ? 'pendiente' : (p.estado_general == 'CERRADO' ? 'rechazado' : 'aprobado')}"><c:out value="${p.estado_general == 'EN_CURSO' ? 'En curso' : (p.estado_general == 'CERRADO' ? 'Cerrado' : 'Listo para sustentación')}" /></span></td>
                  <td><c:out value="${empty p.director ? 'Sin asignar' : p.director}" /></td>
                  <td><c:out value="${empty p.evaluador ? 'Sin asignar' : p.evaluador}" /></td>
                  <td><c:choose><c:when test="${empty p.ultimo_fecha}">—</c:when><c:otherwise><div><c:out value="${p.ultimo_movimiento}" /></div><div class="texto-sec"><c:out value="${p.ultimo_fecha}" /></div></c:otherwise></c:choose></td>
                  <td class="acciones no-imprimir">
                    <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${p.id_proyecto}" aria-label="Ver el seguimiento de ${fn:escapeXml(p.codigo)}"><i class="bi bi-eye"></i></a>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
      </c:otherwise>
    </c:choose>
  </c:otherwise>

</c:choose>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

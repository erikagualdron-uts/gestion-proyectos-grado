<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/informe_filtros.jsp" %>
<%-- Informe de estado (RF-60, RF-62), solo para el coordinador: proyecto, fase, estado y último movimiento,
     con filtros por estudiante, director, evaluador, fase y estado, y exportación a CSV. --%>
<c:set var="titulo" value="Informes de estado" scope="request" />

<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<sql:query var="resumen" dataSource="${bd}">
  SELECT SUM(estado_general = 'EN_CURSO') AS en_curso, SUM(estado_general = 'APTO_GRADUACION') AS listos,
         SUM(estado_general = 'CERRADO') AS cerrados, SUM(id_director IS NULL OR id_evaluador IS NULL) AS sin_asignar
  FROM proyecto
</sql:query>
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
  <c:param name="q" value="${q}" /><c:param name="fase" value="${filtroFase}" /><c:param name="estado" value="${filtroEstado}" />
  <c:param name="director" value="${filtroDirector}" /><c:param name="evaluador" value="${filtroEvaluador}" />
</c:url>
<c:url var="urlExcel" value="/modulos/informes/informe_excel.jsp">
  <c:param name="q" value="${q}" /><c:param name="fase" value="${filtroFase}" /><c:param name="estado" value="${filtroEstado}" />
  <c:param name="director" value="${filtroDirector}" /><c:param name="evaluador" value="${filtroEvaluador}" />
</c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Informes de estado</h1>
    <p class="descripcion-pagina mb-3">Seguimiento general de los proyectos: fase, estado, director, evaluador y último movimiento.</p>
  </div>
  <div class="d-flex flex-wrap gap-2 mb-3 no-imprimir">
    <button type="button" class="btn btn-outline-uts" data-imprimir><i class="bi bi-printer me-1"></i>Imprimir</button>
    <a class="btn btn-uts" href="${urlExcel}"><i class="bi bi-file-earmark-excel me-1"></i>Exportar a Excel</a>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-hourglass-split"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].en_curso}" default="0" /></div><div class="resumen-etiqueta">En curso</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-mortarboard"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].listos}" default="0" /></div><div class="resumen-etiqueta">Listos para sustentación</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono rechazado"><i class="bi bi-x-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].cerrados}" default="0" /></div><div class="resumen-etiqueta">Cerrados</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aplazado"><i class="bi bi-person-dash"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].sin_asignar}" default="0" /></div><div class="resumen-etiqueta">Sin director o evaluador</div></div></div></div>
</div>

<form method="get" action="${ctx}/modulos/informes/informe_coordinador.jsp" class="row g-3 align-items-end mb-3 no-imprimir">
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
                <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/historial/historial.jsp?id=${p.id_proyecto}" aria-label="Ver el historial de ${fn:escapeXml(p.codigo)}"><i class="bi bi-clock-history"></i></a>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

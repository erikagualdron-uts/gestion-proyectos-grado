<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Asignación de proyectos (RF-34, RF-35): el coordinador asigna director y evaluador a cada proyecto aprobado.
     Solo se listan docentes activos y el director y el evaluador deben ser personas distintas. --%>
<c:set var="titulo" value="Asignación de proyectos" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="filtroAsignacion" value="${fn:contains(',SIN_DIRECTOR,SIN_EVALUADOR,COMPLETOS,', ',' += param.asignacion += ',') ? param.asignacion : ''}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<%-- Parte común de las consultas (conteo y lista) --%>
<c:set var="desdeProyectos">
  FROM proyecto pr
  JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  JOIN fase f ON f.id_fase = pr.fase_actual
  LEFT JOIN usuario d ON d.id_usuario = pr.id_director
  LEFT JOIN usuario ev ON ev.id_usuario = pr.id_evaluador
  WHERE (? = '' OR p.codigo LIKE ? OR p.titulo LIKE ? OR d.nombre_completo LIKE ? OR ev.nombre_completo LIKE ?
         OR EXISTS (SELECT 1 FROM propuesta_estudiante pe2 JOIN usuario e2 ON e2.id_usuario = pe2.id_estudiante
                    WHERE pe2.id_propuesta = p.id_propuesta AND (e2.nombre_completo LIKE ? OR e2.numero_documento LIKE ?)))
    AND (? = '' OR (? = 'SIN_DIRECTOR' AND pr.id_director IS NULL) OR (? = 'SIN_EVALUADOR' AND pr.id_evaluador IS NULL)
         OR (? = 'COMPLETOS' AND pr.id_director IS NOT NULL AND pr.id_evaluador IS NOT NULL))
</c:set>

<sql:query var="resumen" dataSource="${bd}">
  SELECT COUNT(*) AS total, SUM(id_director IS NULL) AS sin_director, SUM(id_evaluador IS NULL) AS sin_evaluador,
         SUM(id_director IS NOT NULL AND id_evaluador IS NOT NULL) AS completos
  FROM proyecto
</sql:query>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total ${desdeProyectos}
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="proyectos" dataSource="${bd}">
  SELECT pr.id_proyecto, p.codigo, p.titulo, pr.fase_actual, f.nombre AS fase, pr.estado_general,
         pr.id_director, pr.id_evaluador, d.nombre_completo AS director, ev.nombre_completo AS evaluador,
         (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
          FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante
          WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes
  ${desdeProyectos}
  ORDER BY (pr.id_director IS NULL OR pr.id_evaluador IS NULL) DESC, pr.id_proyecto DESC
  LIMIT ? OFFSET ?
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" /><sql:param value="${filtroAsignacion}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<%-- Docentes activos que se pueden asignar --%>
<sql:query var="docentes" dataSource="${bd}">
  SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1
  ORDER BY u.nombre_completo
</sql:query>

<c:url var="pagBase" value="/modulos/proyectos/asignacion.jsp"><c:param name="q" value="${q}" /><c:param name="asignacion" value="${filtroAsignacion}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Asignación de proyectos</h1>
    <p class="descripcion-pagina mb-3">Asigna el director y el evaluador de cada proyecto. Deben ser docentes distintos.</p>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none ${filtroAsignacion == '' ? 'resumen-activa' : ''}" href="${ctx}/modulos/proyectos/asignacion.jsp" title="Ver todos los proyectos"><span class="resumen-icono pendiente"><i class="bi bi-folder2-open"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].total}" default="0" /></div><div class="resumen-etiqueta">Proyectos</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none ${filtroAsignacion == 'SIN_DIRECTOR' ? 'resumen-activa' : ''}" href="${ctx}/modulos/proyectos/asignacion.jsp?asignacion=SIN_DIRECTOR" title="Ver solo los proyectos sin director"><span class="resumen-icono rechazado"><i class="bi bi-person-x"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].sin_director}" default="0" /></div><div class="resumen-etiqueta">Sin director</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none ${filtroAsignacion == 'SIN_EVALUADOR' ? 'resumen-activa' : ''}" href="${ctx}/modulos/proyectos/asignacion.jsp?asignacion=SIN_EVALUADOR" title="Ver solo los proyectos sin evaluador"><span class="resumen-icono aplazado"><i class="bi bi-person-dash"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].sin_evaluador}" default="0" /></div><div class="resumen-etiqueta">Sin evaluador</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none ${filtroAsignacion == 'COMPLETOS' ? 'resumen-activa' : ''}" href="${ctx}/modulos/proyectos/asignacion.jsp?asignacion=COMPLETOS" title="Ver solo los proyectos con director y evaluador"><span class="resumen-icono aprobado"><i class="bi bi-people"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].completos}" default="0" /></div><div class="resumen-etiqueta">Con director y evaluador</div></div></a></div>
</div>

<form method="get" action="${ctx}/modulos/proyectos/asignacion.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, título, estudiante (nombre o documento), director o evaluador" maxlength="120">
  </div>
  <div class="col-6 col-md-auto">
    <label for="asignacion" class="form-label">Asignación</label>
    <select class="form-select" id="asignacion" name="asignacion" data-autoenviar>
      <option value="">Todos</option>
      <option value="SIN_DIRECTOR" ${filtroAsignacion == 'SIN_DIRECTOR' ? 'selected' : ''}>Sin director</option>
      <option value="SIN_EVALUADOR" ${filtroAsignacion == 'SIN_EVALUADOR' ? 'selected' : ''}>Sin evaluador</option>
      <option value="COMPLETOS" ${filtroAsignacion == 'COMPLETOS' ? 'selected' : ''}>Con director y evaluador</option>
    </select>
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${proyectos.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-folder2-open"></i></span>
      <h3>No hay proyectos para mostrar</h3>
      <p>Los proyectos aparecen cuando apruebas una propuesta de estudiantes. También puedes cambiar los filtros.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>Código</th><th>Proyecto</th><th>Fase</th><th>Director</th><th>Evaluador</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="p" items="${proyectos.rows}">
            <tr>
              <td class="fw-bold"><c:out value="${p.codigo}" /></td>
              <td style="min-width: 240px"><div><c:out value="${p.titulo}" /></div><div class="texto-sec"><c:out value="${p.estudiantes}" /></div></td>
              <td><c:choose>
                <c:when test="${p.estado_general == 'APTO_GRADUACION'}"><span class="insignia insignia-aprobado">Listo para sustentación</span></c:when>
                <c:when test="${p.estado_general == 'CERRADO'}"><span class="insignia insignia-rechazado">Proyecto cerrado</span></c:when>
                <c:otherwise><span class="insignia insignia-pendiente">Fase <c:out value="${p.fase_actual}" /> · <c:out value="${p.fase}" /></span></c:otherwise>
              </c:choose></td>
              <td><c:choose><c:when test="${empty p.director}"><span class="insignia insignia-rechazado">Sin asignar</span></c:when><c:otherwise><c:out value="${p.director}" /></c:otherwise></c:choose></td>
              <td><c:choose><c:when test="${empty p.evaluador}"><span class="insignia insignia-aplazado">Sin asignar</span></c:when><c:otherwise><c:out value="${p.evaluador}" /></c:otherwise></c:choose></td>
              <td class="acciones">
                <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${p.id_proyecto}" title="Ver el seguimiento de ${fn:escapeXml(p.codigo)}" aria-label="Ver el seguimiento de ${fn:escapeXml(p.codigo)}"><i class="bi bi-eye"></i></a>
                <span class="d-inline-block" ${p.estado_general == 'EN_CURSO' ? 'title="Asignar director y evaluador"' : (p.estado_general == 'CERRADO' ? 'title="Proyecto cerrado: no se puede reasignar"' : 'title="Proyecto terminado: no se puede reasignar"')}><button type="button" class="btn btn-outline-uts btn-icono" ${p.estado_general == 'EN_CURSO' ? '' : 'disabled'} data-bs-toggle="modal" data-bs-target="#modalAsignar" aria-label="Asignar director y evaluador de ${fn:escapeXml(p.codigo)}"
                        data-id="${p.id_proyecto}" data-codigo="${fn:escapeXml(p.codigo)}" data-titulo="${fn:escapeXml(p.titulo)}" data-estudiantes="${fn:escapeXml(p.estudiantes)}"
                        data-director="${empty p.id_director ? '' : p.id_director}" data-evaluador="${empty p.id_evaluador ? '' : p.id_evaluador}"><i class="bi bi-pencil"></i></button></span>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalAsignar" tabindex="-1" aria-labelledby="tituloAsignar" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="post" action="${ctx}/proceso/asignacion_proc.jsp" data-asignacion novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="id" value="" data-llenar-valor="id">
        <div class="modal-header border-0">
          <h2 class="modal-title fs-5" id="tituloAsignar">Asignar <span data-llenar="codigo"></span></h2>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
        </div>
        <div class="modal-body pt-0">
          <div class="dato-etiqueta">Proyecto</div><div class="dato-valor" data-llenar="titulo"></div>
          <div class="dato-etiqueta">Estudiantes</div><div class="dato-valor" data-llenar="estudiantes"></div>
          <c:choose>
            <c:when test="${docentes.rowCount < 2}">
              <div class="alert alert-warning" role="alert"><i class="bi bi-exclamation-triangle me-1"></i>Se necesitan al menos dos docentes activos para asignar director y evaluador.</div>
            </c:when>
          </c:choose>
          <div class="mb-3">
            <label for="director" class="form-label">Director</label>
            <select class="form-select" id="director" name="director" data-llenar-valor="director">
              <option value="">Sin asignar</option>
              <c:forEach var="d" items="${docentes.rows}"><option value="${d.id_usuario}"><c:out value="${d.nombre_completo}" /></option></c:forEach>
            </select>
          </div>
          <div class="mb-1">
            <label for="evaluador" class="form-label">Evaluador</label>
            <select class="form-select" id="evaluador" name="evaluador" data-llenar-valor="evaluador">
              <option value="">Sin asignar</option>
              <c:forEach var="d" items="${docentes.rows}"><option value="${d.id_usuario}"><c:out value="${d.nombre_completo}" /></option></c:forEach>
            </select>
            <div class="invalid-feedback">El director y el evaluador deben ser docentes distintos.</div>
          </div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <button type="button" class="btn btn-outline-uts" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-uts"><i class="bi bi-check-lg me-1"></i>Guardar asignación</button>
        </div>
      </form>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

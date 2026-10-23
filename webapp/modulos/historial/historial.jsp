<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE,DOCENTE,COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Historial de versiones del proyecto (RF-58, RF-59): lista cronológica de entregas, decisiones y cambios de estado,
     solo lectura. El coordinador ve todos los proyectos; el docente, los suyos; el estudiante, el propio. --%>
<c:set var="titulo" value="Historial de versiones" scope="request" />
<c:set var="menuActivo" value="${sessionScope.rol == 'ESTUDIANTE' ? '/modulos/propuestas/propuestas_banco.jsp' : (sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : '/modulos/docente_director/docente_director.jsp')}" scope="request" />

<c:catch var="idInvalido"><c:set var="idProyecto" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:if test="${not empty idInvalido}"><c:set var="idProyecto" value="${0}" /></c:if>
<c:if test="${idProyecto < 1 and sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="propio" dataSource="${bd}">
    SELECT pr.id_proyecto FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta
    WHERE pe.id_estudiante = ? ORDER BY pr.id_proyecto DESC LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:if test="${propio.rowCount == 1}"><c:set var="idProyecto" value="${propio.rows[0].id_proyecto}" /></c:if>
</c:if>

<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>
<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />

<%-- ============ Con proyecto: línea de tiempo ============ --%>
<c:if test="${idProyecto > 0}">
  <sql:query var="consulta" dataSource="${bd}">
    SELECT pr.id_proyecto, pr.id_propuesta, pr.id_director, pr.id_evaluador, pr.fase_actual, pr.estado_general, p.codigo, p.titulo,
           (SELECT COUNT(*) FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.id_estudiante = ?) AS es_miembro
    FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta WHERE pr.id_proyecto = ?
    <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" />
  </sql:query>
  <c:if test="${consulta.rowCount != 1}">
    <c:set var="flashTipo" value="warning" scope="session" />
    <c:set var="flashMsg" value="El proyecto indicado no existe." scope="session" />
    <c:redirect url="/modulos/historial/historial.jsp" />
  </c:if>
  <c:set var="py" value="${consulta.rows[0]}" />
  <c:set var="permitido" value="${sessionScope.rol == 'COORDINADOR' or (sessionScope.rol == 'ESTUDIANTE' and py.es_miembro > 0) or (sessionScope.rol == 'DOCENTE' and (py.id_director == sessionScope.usuarioId or py.id_evaluador == sessionScope.usuarioId))}" />
  <c:if test="${not permitido}"><c:redirect url="/acceso_denegado.jsp" /></c:if>

  <c:set var="filtroEntidad" value="${fn:contains(',DOCUMENTO,FASE,PROYECTO,PROPUESTA,PQRS,', ',' += param.entidad += ',') ? param.entidad : ''}" />
  <c:set var="eventosProyecto">
    FROM historial_version h
    JOIN usuario u ON u.id_usuario = h.id_usuario
    LEFT JOIN documento d ON d.id_documento = h.id_documento
    WHERE (h.id_proyecto = ? OR (h.entidad = 'PROPUESTA' AND h.id_entidad = ?))
      AND (? = '' OR h.entidad = ?)
  </c:set>
  <sql:query var="conteo" dataSource="${bd}">
    SELECT COUNT(*) AS total ${eventosProyecto}
    <sql:param value="${idProyecto}" /><sql:param value="${py.id_propuesta}" /><sql:param value="${filtroEntidad}" /><sql:param value="${filtroEntidad}" />
  </sql:query>
  <c:set var="totalRegistros" value="${conteo.rows[0].total}" />
  <c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
  <c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
  <c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />
  <sql:query var="eventos" dataSource="${bd}">
    SELECT h.entidad, h.estado_anterior, h.estado_nuevo, h.version_num, h.detalle, u.nombre_completo AS usuario,
           DATE_FORMAT(h.fecha_evento, '%d/%m/%Y %H:%i') AS fecha, d.enlace_url, d.nombre AS documento,
           CASE h.accion WHEN 'CREAR' THEN 'Creación' WHEN 'DECIDIR' THEN 'Decisión' WHEN 'REENVIAR' THEN 'Reenvío corregido'
             WHEN 'ASIGNAR' THEN 'Asignación de director y evaluador' WHEN 'ENTREGAR' THEN 'Entrega de documento' WHEN 'REVISAR' THEN 'Revisión'
             WHEN 'EDITAR_REVISION' THEN 'Revisión editada' WHEN 'APROBAR_FASE' THEN 'Fase aprobada' WHEN 'APLAZAR_FASE' THEN 'Fase aplazada'
             WHEN 'CERRAR_PROYECTO' THEN 'Proyecto cerrado' WHEN 'APTO_GRADUACION' THEN 'Listo para sustentación' WHEN 'RADICAR' THEN 'PQRS radicada'
             WHEN 'RESOLVER' THEN 'PQRS resuelta' WHEN 'CAMBIAR_DIRECTOR' THEN 'Cambio de director' ELSE h.accion END AS accion_texto
    ${eventosProyecto}
    ORDER BY h.fecha_evento DESC, h.id_historial DESC
    LIMIT ? OFFSET ?
    <sql:param value="${idProyecto}" /><sql:param value="${py.id_propuesta}" /><sql:param value="${filtroEntidad}" /><sql:param value="${filtroEntidad}" />
    <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
  </sql:query>
  <c:url var="pagBase" value="/modulos/historial/historial.jsp"><c:param name="id" value="${idProyecto}" /><c:param name="entidad" value="${filtroEntidad}" /></c:url>
</c:if>

<%-- ============ Sin proyecto: lista de proyectos visibles ============ --%>
<c:if test="${idProyecto < 1}">
  <c:set var="proyectosVisibles">
    FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
    WHERE (? = 'COORDINADOR'
           OR (? = 'DOCENTE' AND (pr.id_director = ? OR pr.id_evaluador = ?))
           OR (? = 'ESTUDIANTE' AND EXISTS (SELECT 1 FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.id_estudiante = ?)))
      AND (? = '' OR p.codigo LIKE ? OR p.titulo LIKE ?
           OR EXISTS (SELECT 1 FROM propuesta_estudiante pe2 JOIN usuario e2 ON e2.id_usuario = pe2.id_estudiante
                      WHERE pe2.id_propuesta = p.id_propuesta AND e2.nombre_completo LIKE ?))
  </c:set>
  <sql:query var="conteo" dataSource="${bd}">
    SELECT COUNT(*) AS total ${proyectosVisibles}
    <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  </sql:query>
  <c:set var="totalRegistros" value="${conteo.rows[0].total}" />
  <c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
  <c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
  <c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />
  <sql:query var="proyectos" dataSource="${bd}">
    SELECT pr.id_proyecto, p.codigo, p.titulo, pr.fase_actual, pr.estado_general,
           (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
            FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes
    ${proyectosVisibles}
    ORDER BY pr.id_proyecto DESC LIMIT ? OFFSET ?
    <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
    <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
  </sql:query>
  <c:url var="pagBase" value="/modulos/historial/historial.jsp"><c:param name="q" value="${q}" /></c:url>
</c:if>

<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />
<c:if test="${idProyecto > 0}"><c:set var="volverA" value="/modulos/proyectos/seguimiento.jsp?id=${idProyecto}" scope="request" /></c:if>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Historial de versiones</h1>

<c:choose>
  <%-- ======== Línea de tiempo de un proyecto ======== --%>
  <c:when test="${idProyecto > 0}">
    <p class="descripcion-pagina">Proyecto <strong><c:out value="${py.codigo}" /></strong> · <c:out value="${py.titulo}" />. Se conservan todas las versiones y decisiones; no se puede editar.</p>
    <form method="get" action="${ctx}/modulos/historial/historial.jsp" class="row g-3 align-items-end mb-3">
      <input type="hidden" name="id" value="${idProyecto}">
      <input type="hidden" name="pp" value="${pp}">
      <input type="hidden" name="pag" value="1">
      <div class="col-12 col-md-auto">
        <label for="entidad" class="form-label">Mostrar</label>
        <select class="form-select" id="entidad" name="entidad" data-autoenviar>
          <option value="">Todo</option>
          <option value="DOCUMENTO" ${filtroEntidad == 'DOCUMENTO' ? 'selected' : ''}>Documentos y revisiones</option>
          <option value="FASE" ${filtroEntidad == 'FASE' ? 'selected' : ''}>Cambios de fase</option>
          <option value="PROYECTO" ${filtroEntidad == 'PROYECTO' ? 'selected' : ''}>Proyecto</option>
          <option value="PROPUESTA" ${filtroEntidad == 'PROPUESTA' ? 'selected' : ''}>Propuesta</option>
          <option value="PQRS" ${filtroEntidad == 'PQRS' ? 'selected' : ''}>PQRS</option>
        </select>
      </div>
    </form>
    <c:choose>
      <c:when test="${eventos.rowCount == 0}">
        <div class="vacio"><span class="icono-circulo"><i class="bi bi-clock-history"></i></span><h3>Sin movimientos</h3><p>Aún no hay eventos registrados para este filtro.</p></div>
      </c:when>
      <c:otherwise>
        <div class="tabla-envoltorio table-responsive">
          <table class="table tabla-uts">
            <thead><tr><th>Fecha</th><th>Usuario</th><th>Acción</th><th>Estado</th><th>Versión</th><th>Detalle y enlace</th></tr></thead>
            <tbody>
              <c:forEach var="e" items="${eventos.rows}">
                <tr>
                  <td style="white-space: nowrap"><c:out value="${e.fecha}" /></td>
                  <td><c:out value="${e.usuario}" /></td>
                  <td><div class="fw-semibold"><c:out value="${e.accion_texto}" /></div><div class="texto-sec"><c:choose><c:when test="${e.entidad == 'PQRS'}">PQRS</c:when><c:otherwise><c:out value="${fn:substring(e.entidad, 0, 1)}" /><c:out value="${fn:toLowerCase(fn:substring(e.entidad, 1, 20))}" /></c:otherwise></c:choose></div></td>
                  <td>
                    <c:if test="${not empty e.estado_anterior}"><span class="texto-sec"><c:out value="${fn:replace(fn:toLowerCase(e.estado_anterior), '_', ' ')}" /> →</span></c:if>
                    <c:if test="${not empty e.estado_nuevo}"><strong><c:out value="${fn:replace(fn:toLowerCase(e.estado_nuevo), '_', ' ')}" /></strong></c:if>
                    <c:if test="${empty e.estado_anterior and empty e.estado_nuevo}">—</c:if>
                  </td>
                  <td><c:choose><c:when test="${not empty e.version_num}">v<c:out value="${e.version_num}" /></c:when><c:otherwise>—</c:otherwise></c:choose></td>
                  <td style="min-width: 240px; white-space: pre-line"><c:out value="${empty e.detalle ? '—' : e.detalle}" />
                    <c:if test="${not empty e.enlace_url}"><div><a class="fw-semibold" href="<c:out value='${e.enlace_url}' />" target="_blank" rel="noopener noreferrer">Abrir <c:out value="${e.documento}" /> <i class="bi bi-box-arrow-up-right"></i></a></div></c:if>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
      </c:otherwise>
    </c:choose>
  </c:when>

  <%-- ======== Elegir un proyecto ======== --%>
  <c:otherwise>
    <p class="descripcion-pagina">Elige un proyecto para ver su línea de tiempo de versiones, decisiones y cambios de estado.</p>
    <form method="get" action="${ctx}/modulos/historial/historial.jsp" class="row g-3 align-items-end mb-3">
      <input type="hidden" name="pp" value="${pp}">
      <input type="hidden" name="pag" value="1">
      <div class="col-12 col-md">
        <label for="q" class="form-label">Buscar</label>
        <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, título o estudiante" maxlength="120">
      </div>
      <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
    </form>
    <c:choose>
      <c:when test="${proyectos.rowCount == 0}">
        <div class="vacio"><span class="icono-circulo"><i class="bi bi-folder2-open"></i></span><h3>No hay proyectos para mostrar</h3><p>El historial aparece cuando existe un proyecto.</p></div>
      </c:when>
      <c:otherwise>
        <div class="tabla-envoltorio table-responsive">
          <table class="table tabla-uts">
            <thead><tr><th>Código</th><th>Proyecto</th><th>Fase</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
            <tbody>
              <c:forEach var="p" items="${proyectos.rows}">
                <tr>
                  <td class="fw-bold"><c:out value="${p.codigo}" /></td>
                  <td style="min-width: 240px"><div><c:out value="${p.titulo}" /></div><div class="texto-sec"><c:out value="${p.estudiantes}" /></div></td>
                  <td>Fase <c:out value="${p.fase_actual}" /></td>
                  <td><span class="insignia insignia-${p.estado_general == 'EN_CURSO' ? 'pendiente' : (p.estado_general == 'CERRADO' ? 'rechazado' : 'aprobado')}"><c:out value="${p.estado_general == 'EN_CURSO' ? 'En curso' : (p.estado_general == 'CERRADO' ? 'Cerrado' : 'Listo para sustentación')}" /></span></td>
                  <td class="acciones"><a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/historial/historial.jsp?id=${p.id_proyecto}" aria-label="Ver el historial de ${fn:escapeXml(p.codigo)}"><i class="bi bi-eye"></i></a></td>
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

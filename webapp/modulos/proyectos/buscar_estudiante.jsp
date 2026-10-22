<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Consulta del proyecto o anteproyecto de un estudiante (RF-36): por documento, nombre o código de la propuesta. --%>
<c:set var="titulo" value="Buscar estudiante" scope="request" />
<c:set var="menuActivo" value="/modulos/proyectos/asignacion.jsp" scope="request" />
<c:set var="volverA" value="/modulos/proyectos/asignacion.jsp" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<c:set var="desdeEstudiantes">
  FROM usuario u
  JOIN rol r ON r.id_rol = u.id_rol AND r.nombre = 'ESTUDIANTE'
  LEFT JOIN propuesta_estudiante pe ON pe.id_estudiante = u.id_usuario
  LEFT JOIN propuesta p ON p.id_propuesta = pe.id_propuesta
  LEFT JOIN proyecto pr ON pr.id_propuesta = p.id_propuesta
  LEFT JOIN fase f ON f.id_fase = pr.fase_actual
  LEFT JOIN usuario d ON d.id_usuario = pr.id_director
  LEFT JOIN usuario ev ON ev.id_usuario = pr.id_evaluador
  WHERE u.estado_cuenta = 'APROBADA' AND u.activo = 1
    AND (? = '' OR u.nombre_completo LIKE ? OR u.numero_documento LIKE ? OR u.correo LIKE ? OR p.codigo LIKE ?)
</c:set>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total ${desdeEstudiantes}
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="estudiantes" dataSource="${bd}">
  SELECT u.nombre_completo, u.tipo_documento, u.numero_documento, u.nivel,
         p.codigo, p.titulo, p.estado_decision, pe.es_responsable,
         pr.id_proyecto, pr.fase_actual, f.nombre AS fase, d.nombre_completo AS director, ev.nombre_completo AS evaluador
  ${desdeEstudiantes}
  ORDER BY u.nombre_completo, p.id_propuesta
  LIMIT ? OFFSET ?
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:url var="pagBase" value="/modulos/proyectos/buscar_estudiante.jsp"><c:param name="q" value="${q}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Buscar estudiante</h1>
<p class="descripcion-pagina">Consulta el proyecto o anteproyecto de un estudiante por documento, nombre o código de la propuesta.</p>

<form method="get" action="${ctx}/modulos/proyectos/buscar_estudiante.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Documento, nombre, correo o código (PG-0001)" maxlength="120" autofocus>
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${estudiantes.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-person-search"></i></span>
      <h3>No se encontraron estudiantes</h3>
      <p>Revisa el documento, el nombre o el código. Solo aparecen estudiantes con cuenta aprobada.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>Estudiante</th><th>Propuesta</th><th>Estado</th><th>Fase</th><th>Director</th><th>Evaluador</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="e" items="${estudiantes.rows}">
            <tr>
              <td><div class="fw-semibold"><c:out value="${e.nombre_completo}" /></div><div class="texto-sec"><c:out value="${e.tipo_documento}" /> <c:out value="${e.numero_documento}" /><c:if test="${not empty e.nivel}"> · <c:out value="${e.nivel == 'TECNOLOGICO' ? 'Tecnológico' : 'Profesional'}" /></c:if></div></td>
              <c:choose>
                <c:when test="${empty e.codigo}">
                  <td colspan="5" class="texto-sec">Aún no tiene propuesta.</td>
                </c:when>
                <c:otherwise>
                  <td style="min-width: 200px"><div class="fw-semibold"><c:out value="${e.codigo}" /></div><div class="texto-sec"><c:out value="${e.titulo}" /><c:if test="${not e.es_responsable}"> · compañero</c:if></div></td>
                  <td><span class="insignia insignia-${e.estado_decision == 'APROBADO' ? 'aprobado' : (e.estado_decision == 'APLAZADO' ? 'aplazado' : (e.estado_decision == 'RECHAZADO' ? 'rechazado' : 'pendiente'))}"><c:out value="${e.estado_decision == 'APROBADO' ? 'Aprobado' : (e.estado_decision == 'APLAZADO' ? 'Aplazado' : (e.estado_decision == 'RECHAZADO' ? 'Rechazado' : 'Pendiente'))}" /></span></td>
                  <td><c:choose><c:when test="${empty e.id_proyecto}"><span class="texto-sec">Anteproyecto</span></c:when><c:otherwise>Fase <c:out value="${e.fase_actual}" /> · <c:out value="${e.fase}" /></c:otherwise></c:choose></td>
                  <td><c:out value="${empty e.director ? (empty e.id_proyecto ? '—' : 'Sin asignar') : e.director}" /></td>
                  <td><c:out value="${empty e.evaluador ? (empty e.id_proyecto ? '—' : 'Sin asignar') : e.evaluador}" /></td>
                </c:otherwise>
              </c:choose>
              <td class="acciones">
                <c:if test="${not empty e.id_proyecto}">
                  <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${e.id_proyecto}" aria-label="Ver el seguimiento de ${fn:escapeXml(e.codigo)}"><i class="bi bi-eye"></i></a>
                </c:if>
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

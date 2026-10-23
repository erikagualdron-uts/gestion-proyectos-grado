<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Radicar una PQRS (RF-53, RF-54). Solo el estudiante responsable; el compañero solo consulta. --%>
<c:set var="titulo" value="Radicar PQRS" scope="request" />
<c:set var="menuActivo" value="/modulos/propuestas/propuestas_banco.jsp" scope="request" />
<c:set var="volverA" value="/modulos/pqrs/pqrs.jsp" scope="request" />

<sql:query var="membresia" dataSource="${bd}">
  SELECT SUM(pe.es_responsable = 1) AS como_responsable, COUNT(*) AS total
  FROM propuesta_estudiante pe JOIN propuesta p ON p.id_propuesta = pe.id_propuesta
  WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO'
  <sql:param value="${sessionScope.usuarioId}" />
</sql:query>
<c:if test="${membresia.rows[0].total > 0 and membresia.rows[0].como_responsable == 0}">
  <c:set var="flashTipo" value="warning" scope="session" />
  <c:set var="flashMsg" value="Solo el estudiante responsable del proyecto puede radicar una PQRS." scope="session" />
  <c:redirect url="/modulos/pqrs/pqrs.jsp" />
</c:if>

<%-- Proyecto del responsable (si ya existe) --%>
<sql:query var="proyecto" dataSource="${bd}">
  SELECT pr.id_proyecto, p.codigo FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta
  JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  WHERE pe.id_estudiante = ? AND pe.es_responsable = 1 ORDER BY pr.id_proyecto DESC LIMIT 1
  <sql:param value="${sessionScope.usuarioId}" />
</sql:query>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Radicar PQRS</h1>
<p class="descripcion-pagina">Envía una prórroga, un cambio de director, una petición, una queja, un reclamo o una sugerencia. El comité te responderá aquí mismo.</p>

<div class="row">
  <div class="col-12 col-xl-8">
    <div class="tarjeta">
      <c:if test="${proyecto.rowCount > 0}"><div class="mb-3"><span class="etiqueta-sup">Proyecto</span> <span class="fw-bold"><c:out value="${proyecto.rows[0].codigo}" /></span></div></c:if>
      <form method="post" action="${ctx}/proceso/pqrs_proc.jsp" class="needs-validation" data-pqrs novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="accion" value="radicar">
        <div class="mb-3">
          <label for="tipo" class="form-label">Tipo de solicitud</label>
          <select class="form-select" id="tipo" name="tipo" required>
            <c:set var="tiposForm" value="PRORROGA=Prórroga;CAMBIO_DIRECTOR=Cambio de director;PETICION=Petición;QUEJA=Queja;RECLAMO=Reclamo;SUGERENCIA=Sugerencia" />
            <c:forEach var="t" items="${fn:split(tiposForm, ';')}">
              <c:set var="tp" value="${fn:split(t, '=')}" />
              <option value="${tp[0]}" ${sessionScope.vqTipo == tp[0] ? 'selected' : ''} ${(proyecto.rowCount == 0 and (tp[0] == 'PRORROGA' or tp[0] == 'CAMBIO_DIRECTOR')) ? 'disabled' : ''}>${tp[1]}${(proyecto.rowCount == 0 and (tp[0] == 'PRORROGA' or tp[0] == 'CAMBIO_DIRECTOR')) ? ' (requiere un proyecto)' : ''}</option>
            </c:forEach>
          </select>
        </div>
        <div class="mb-3">
          <label for="asunto" class="form-label">Asunto</label>
          <input type="text" class="form-control" id="asunto" name="asunto" maxlength="150" minlength="5" value="<c:out value='${sessionScope.vqAsunto}' />" required>
          <div class="invalid-feedback">Escribe el asunto (mínimo 5 caracteres).</div>
        </div>
        <div class="mb-3">
          <label for="descripcion" class="form-label">Descripción</label>
          <textarea class="form-control" id="descripcion" name="descripcion" rows="5" maxlength="2000" minlength="10" required><c:out value="${sessionScope.vqDescripcion}" /></textarea>
          <div class="invalid-feedback">Describe tu solicitud (mínimo 10 caracteres).</div>
        </div>
        <div class="mb-4">
          <label for="soporte" class="form-label">Enlace del soporte</label>
          <input type="url" class="form-control" id="soporte" name="soporte" maxlength="500" placeholder="https://..." value="<c:out value='${sessionScope.vqSoporte}' />">
          <div class="form-text" data-ayuda-soporte>Opcional: enlace a un soporte (documento, captura, etc.).</div>
          <div class="invalid-feedback">Ingresa un enlace que empiece por http:// o https://.</div>
        </div>
        <div class="d-flex flex-wrap gap-2">
          <button type="submit" class="btn btn-uts px-4"><i class="bi bi-send me-1"></i>Radicar</button>
          <a class="btn btn-outline-uts px-4" href="${ctx}/modulos/pqrs/pqrs.jsp">Cancelar</a>
        </div>
      </form>
    </div>
  </div>
</div>
<c:remove var="vqTipo" scope="session" />
<c:remove var="vqAsunto" scope="session" />
<c:remove var="vqDescripcion" scope="session" />
<c:remove var="vqSoporte" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />

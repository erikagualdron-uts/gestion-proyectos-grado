<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="DOCENTE" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Proponer una idea de trabajo de grado (RF-21). Queda pendiente en Propuestas Banco. --%>
<c:set var="titulo" value="Proponer idea" scope="request" />
<c:set var="menuActivo" value="/modulos/banco_ideas/banco_ideas.jsp" scope="request" />
<c:set var="volverA" value="/modulos/banco_ideas/banco_ideas.jsp" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Proponer idea</h1>
<p class="descripcion-pagina">Aporta un tema al banco de ideas. El coordinador la revisará y, si la aprueba, quedará disponible para los estudiantes.</p>

<div class="row">
  <div class="col-12 col-xl-8">
    <div class="tarjeta">
      <form method="post" action="${ctx}/proceso/idea_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="accion" value="crear">
        <div class="mb-3">
          <label for="titulo" class="form-label">Título</label>
          <input type="text" class="form-control" id="titulo" name="titulo" maxlength="200" minlength="5" value="<c:out value='${sessionScope.viTitulo}' />" required>
          <div class="invalid-feedback">Ingresa el título (mínimo 5 caracteres).</div>
        </div>
        <div class="mb-3">
          <label for="descripcion" class="form-label">Descripción</label>
          <textarea class="form-control" id="descripcion" name="descripcion" rows="4" maxlength="2000" required><c:out value="${sessionScope.viDescripcion}" /></textarea>
          <div class="invalid-feedback">Describe la idea.</div>
        </div>
        <div class="mb-3">
          <label for="objetivo" class="form-label">Objetivo</label>
          <textarea class="form-control" id="objetivo" name="objetivo" rows="3" maxlength="2000" required><c:out value="${sessionScope.viObjetivo}" /></textarea>
          <div class="invalid-feedback">Escribe el objetivo.</div>
        </div>
        <div class="mb-4">
          <label for="alcance" class="form-label">Alcance</label>
          <textarea class="form-control" id="alcance" name="alcance" rows="3" maxlength="2000" required><c:out value="${sessionScope.viAlcance}" /></textarea>
          <div class="invalid-feedback">Escribe el alcance.</div>
        </div>
        <div class="d-flex flex-wrap gap-2">
          <button type="submit" class="btn btn-uts px-4"><i class="bi bi-send me-1"></i>Enviar idea</button>
          <a class="btn btn-outline-uts px-4" href="${ctx}/modulos/banco_ideas/banco_ideas.jsp">Cancelar</a>
        </div>
      </form>
    </div>
  </div>
</div>
<c:remove var="viTitulo" scope="session" />
<c:remove var="viDescripcion" scope="session" />
<c:remove var="viObjetivo" scope="session" />
<c:remove var="viAlcance" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />

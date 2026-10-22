<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="paginaPublica" value="true" scope="request" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<c:if test="${not empty sessionScope.usuarioId}"><c:redirect url="/inicio.jsp" /></c:if>
<c:set var="titulo" value="Crear cuenta" scope="request" />
<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="tarjeta-form ancha">
  <h2>Crear cuenta</h2>
  <p class="sub">Registro de estudiantes. Tu cuenta quedará pendiente hasta que el administrador la apruebe.</p>
  <jsp:include page="/WEB-INF/includes/mensaje.jsp" />
  <form method="post" action="${ctx}/proceso/registro_proc.jsp" class="needs-validation" novalidate>
    <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
    <div class="mb-3">
      <label for="nombre" class="form-label">Nombre completo</label>
      <input type="text" class="form-control" id="nombre" name="nombre" maxlength="120" minlength="5" autocomplete="name" value="<c:out value='${sessionScope.viejoNombre}' />" required>
      <div class="invalid-feedback">Ingresa tu nombre completo.</div>
    </div>
    <div class="row g-3 mb-3">
      <div class="col-sm-5">
        <label for="tipo" class="form-label">Tipo de documento</label>
        <select class="form-select" id="tipo" name="tipo" required>
          <c:forEach var="t" items="${fn:split('CC,TI,CE,PASAPORTE,OTRO', ',')}">
            <option value="${t}" ${sessionScope.viejoTipo == t ? 'selected' : ''}>${t}</option>
          </c:forEach>
        </select>
      </div>
      <div class="col-sm-7">
        <label for="documento" class="form-label">Número de documento</label>
        <input type="text" class="form-control" id="documento" name="documento" pattern="[0-9A-Za-z]{5,20}" maxlength="20" inputmode="numeric" value="<c:out value='${sessionScope.viejoDocumento}' />" required>
        <div class="invalid-feedback">Entre 5 y 20 letras o números, sin espacios.</div>
      </div>
    </div>
    <div class="mb-3">
      <label for="correo" class="form-label">Correo institucional</label>
      <input type="email" class="form-control" id="correo" name="correo" placeholder="usuario@uts.edu.co" maxlength="120" pattern="[A-Za-z0-9._%+\-]+@uts\.edu\.co" autocomplete="email" value="<c:out value='${sessionScope.viejoCorreo}' />" required>
      <div class="invalid-feedback">Usa tu correo institucional de estudiante (@uts.edu.co).</div>
    </div>
    <div class="row g-3 mb-4">
      <div class="col-sm-6">
        <label for="clave" class="form-label">Contraseña</label>
        <div class="campo-clave">
          <input type="password" class="form-control" id="clave" name="clave" minlength="8" maxlength="64" autocomplete="new-password" required>
          <button type="button" class="ver-clave" data-target="clave" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
          <div class="invalid-feedback">Mínimo 8 caracteres.</div>
        </div>
      </div>
      <div class="col-sm-6">
        <label for="confirmar" class="form-label">Confirmar contraseña</label>
        <div class="campo-clave">
          <input type="password" class="form-control" id="confirmar" name="confirmar" minlength="8" maxlength="64" autocomplete="new-password" required>
          <button type="button" class="ver-clave" data-target="confirmar" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
          <div class="invalid-feedback">Las contraseñas no coinciden.</div>
        </div>
      </div>
    </div>
    <button type="submit" class="btn btn-uts w-100 py-2">Crear cuenta</button>
  </form>
  <p class="text-center small text-secondary mt-4 mb-0">¿Ya tienes cuenta? <a href="${ctx}/index.jsp">Iniciar sesión</a></p>
</div>
<c:remove var="viejoNombre" scope="session" />
<c:remove var="viejoTipo" scope="session" />
<c:remove var="viejoDocumento" scope="session" />
<c:remove var="viejoCorreo" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />

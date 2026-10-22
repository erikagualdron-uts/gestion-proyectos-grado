<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="paginaPublica" value="true" scope="request" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<c:if test="${not empty sessionScope.usuarioId}"><c:redirect url="/inicio.jsp" /></c:if>
<c:if test="${param.salio == '1'}">
  <c:set var="flashTipo" value="success" scope="session" />
  <c:set var="flashMsg" value="Cerraste sesión correctamente." scope="session" />
</c:if>
<c:set var="titulo" value="Iniciar sesión" scope="request" />
<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="tarjeta-form">
  <h2>Iniciar sesión</h2>
  <p class="sub">Ingresa con tu correo institucional.</p>
  <jsp:include page="/WEB-INF/includes/mensaje.jsp" />
  <form method="post" action="${ctx}/proceso/login_proc.jsp" class="needs-validation" novalidate>
    <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
    <div class="mb-3">
      <label for="correo" class="form-label">Correo institucional</label>
      <input type="email" class="form-control" id="correo" name="correo" placeholder="usuario@correo.uts.edu.co" maxlength="120" autocomplete="username" required>
      <div class="invalid-feedback">Ingresa un correo válido.</div>
    </div>
    <div class="mb-3">
      <label for="clave" class="form-label">Contraseña</label>
      <div class="campo-clave">
        <input type="password" class="form-control" id="clave" name="clave" placeholder="••••••••" maxlength="64" autocomplete="current-password" required>
        <button type="button" class="ver-clave" data-target="clave" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
        <div class="invalid-feedback">Ingresa tu contraseña.</div>
      </div>
    </div>
    <div class="form-check mb-4">
      <input class="form-check-input" type="checkbox" id="recordar" name="recordar" checked>
      <label class="form-check-label small" for="recordar">Mantener sesión activa</label>
    </div>
    <button type="submit" class="btn btn-uts w-100 py-2">Ingresar</button>
  </form>
  <p class="text-center small text-secondary mt-4 mb-0">¿Aún no tienes cuenta? <a href="${ctx}/registro.jsp">Crear cuenta</a></p>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

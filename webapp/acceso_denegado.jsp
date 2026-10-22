<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="paginaPublica" value="true" scope="request" />
<c:set var="titulo" value="Acceso no autorizado" scope="request" />
<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="tarjeta-form text-center">
  <div class="vacio border-0 p-0 mb-3 bg-transparent">
    <span class="icono-circulo"><i class="bi bi-shield-lock"></i></span>
    <h2 class="h4 mb-1">Acceso no autorizado</h2>
    <p>Tu rol no tiene permiso para abrir esta página.</p>
  </div>
  <a class="btn btn-uts w-100 py-2" href="${ctx}/inicio.jsp">Volver al inicio</a>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

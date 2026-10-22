<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="paginaPublica" value="true" scope="request" />
<c:set var="titulo" value="Página no disponible" scope="request" />
<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="tarjeta-form text-center">
  <div class="vacio border-0 p-0 mb-3 bg-transparent">
    <span class="icono-circulo"><i class="bi bi-exclamation-triangle"></i></span>
    <h2 class="h4 mb-1">Página no disponible</h2>
    <p>La página no existe o ocurrió un problema. Intenta de nuevo o vuelve al inicio.</p>
  </div>
  <a class="btn btn-uts w-100 py-2" href="${pageContext.request.contextPath}/inicio.jsp">Volver al inicio</a>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

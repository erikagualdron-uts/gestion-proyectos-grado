<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Base documental (RF-19): tarjetas con los enlaces activos; cada una abre su enlace en otra pestaña. --%>
<c:set var="titulo" value="Base documental" scope="request" />
<sql:query var="enlaces" dataSource="${bd}">
  SELECT nombre, descripcion, url, icono FROM enlace_documental WHERE activo = 1 ORDER BY orden, id_enlace
</sql:query>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Base documental</h1>
    <p class="descripcion-pagina mb-3">Calendario, formatos y reglamentos de la universidad.</p>
  </div>
  <c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
    <a class="btn btn-uts mb-3" href="${ctx}/modulos/base_documental/enlaces_admin.jsp"><i class="bi bi-pencil-square me-1"></i>Administrar enlaces</a>
  </c:if>
</div>

<c:choose>
  <c:when test="${enlaces.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-journal-text"></i></span>
      <h3>Aún no hay enlaces</h3>
      <p>El administrador publicará aquí los documentos de la universidad.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="row g-3">
      <c:forEach var="e" items="${enlaces.rows}">
        <c:set var="disponible" value="${fn:startsWith(e.url, 'http://') or fn:startsWith(e.url, 'https://')}" />
        <div class="col-12 col-md-6 col-xl-4">
          <a class="tarjeta tarjeta-modulo" ${disponible ? 'target="_blank" rel="noopener noreferrer"' : 'aria-disabled="true"'} href="${disponible ? e.url : '#'}" ${disponible ? '' : 'style="opacity:.6;pointer-events:none"'}>
            <span class="icono-caja"><i class="bi ${empty e.icono ? 'bi-journal-text' : e.icono}"></i></span>
            <h3><c:out value="${e.nombre}" /> <c:if test="${disponible}"><i class="bi bi-box-arrow-up-right fs-6 text-secondary"></i></c:if></h3>
            <p><c:out value="${e.descripcion}" /></p>
            <c:if test="${not disponible}"><span class="insignia insignia-pendiente mt-2">Enlace por configurar</span></c:if>
          </a>
        </div>
      </c:forEach>
    </div>
  </c:otherwise>
</c:choose>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Guardar un enlace de la base documental (RF-20): crear o editar. Desactivar es cambiar "activo". --%>
<c:set var="nombreIngresado" value="${fn:trim(param.nombre)}" />
<c:set var="descripcionIngresada" value="${fn:trim(param.descripcion)}" />
<c:set var="urlIngresada" value="${fn:trim(param.url)}" />
<c:catch var="idInvalido"><c:set var="idEnlace" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:catch var="ordenInvalido"><c:set var="ordenEnlace" value="${param.orden + 0}" /></c:catch>

<c:choose>
  <c:when test="${not empty idInvalido or not empty ordenInvalido}">
    <c:set var="errorEnlace" value="Datos no válidos." />
  </c:when>
  <c:when test="${empty nombreIngresado or fn:length(nombreIngresado) > 80}">
    <c:set var="errorEnlace" value="Ingresa el nombre del enlace (máximo 80 caracteres)." />
  </c:when>
  <c:when test="${fn:length(descripcionIngresada) > 200}">
    <c:set var="errorEnlace" value="La descripción puede tener máximo 200 caracteres." />
  </c:when>
  <c:when test="${fn:length(urlIngresada) > 500 or fn:contains(urlIngresada, ' ') or not (fn:startsWith(urlIngresada, 'https://') or fn:startsWith(urlIngresada, 'http://'))}">
    <c:set var="errorEnlace" value="El enlace debe empezar por http:// o https://, sin espacios (máximo 500 caracteres)." />
  </c:when>
  <c:when test="${not fn:contains(',bi-calendar-event,bi-file-earmark-text,bi-easel,bi-mortarboard,bi-award,bi-journal-text,bi-book,bi-link-45deg,', ',' += param.icono += ',')}">
    <c:set var="errorEnlace" value="Selecciona un icono válido." />
  </c:when>
  <c:when test="${ordenEnlace < 1 or ordenEnlace > 250}">
    <c:set var="errorEnlace" value="El orden debe ser un número entre 1 y 250." />
  </c:when>
  <c:when test="${param.activo != '0' and param.activo != '1'}">
    <c:set var="errorEnlace" value="Estado no válido." />
  </c:when>
</c:choose>

<c:if test="${empty errorEnlace}">
  <c:catch var="falloEnlace">
    <sql:transaction dataSource="${bd}">
      <c:choose>
        <c:when test="${idEnlace > 0}">
          <sql:update var="filas">
            UPDATE enlace_documental SET nombre = ?, descripcion = NULLIF(?, ''), url = ?, icono = ?, orden = ?, activo = ? WHERE id_enlace = ?
            <sql:param value="${nombreIngresado}" /><sql:param value="${descripcionIngresada}" /><sql:param value="${urlIngresada}" />
            <sql:param value="${param.icono}" /><sql:param value="${ordenEnlace}" /><sql:param value="${param.activo}" /><sql:param value="${idEnlace}" />
          </sql:update>
        </c:when>
        <c:otherwise>
          <sql:update var="filas">
            INSERT INTO enlace_documental (nombre, descripcion, url, icono, orden, activo) VALUES (?, NULLIF(?, ''), ?, ?, ?, ?)
            <sql:param value="${nombreIngresado}" /><sql:param value="${descripcionIngresada}" /><sql:param value="${urlIngresada}" />
            <sql:param value="${param.icono}" /><sql:param value="${ordenEnlace}" /><sql:param value="${param.activo}" />
          </sql:update>
        </c:otherwise>
      </c:choose>
    </sql:transaction>
  </c:catch>
  <c:if test="${not empty falloEnlace}"><c:set var="errorEnlace" value="No se pudo guardar el enlace." /></c:if>
</c:if>

<c:set var="flashTipo" value="${empty errorEnlace ? 'success' : 'danger'}" scope="session" />
<c:set var="flashMsg" value="${empty errorEnlace ? 'Enlace guardado.' : errorEnlace}" scope="session" />
<c:redirect url="/modulos/base_documental/enlaces_admin.jsp" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Marcar avisos como leídos (RF-57). Solo se tocan los avisos del propio usuario. --%>
<c:choose>
  <c:when test="${param.accion == 'todas'}">
    <sql:update dataSource="${bd}">
      UPDATE notificacion SET leida = 1 WHERE id_usuario = ? AND leida = 0
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:update>
  </c:when>
  <c:when test="${param.accion == 'marcar'}">
    <c:catch var="idInvalido">
      <sql:update dataSource="${bd}">
        UPDATE notificacion SET leida = 1 WHERE id_notificacion = ? AND id_usuario = ?
        <sql:param value="${param.id + 0}" /><sql:param value="${sessionScope.usuarioId}" />
      </sql:update>
    </c:catch>
  </c:when>
</c:choose>
<c:redirect url="/modulos/notificaciones/notificaciones.jsp" />

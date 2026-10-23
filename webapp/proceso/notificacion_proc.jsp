<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Avisos de la campana (RF-57): "abrir" marca el aviso como leído y lleva al módulo que corresponde; "todas" marca todos.
     Solo se tocan los avisos del propio usuario. Después de "todas" se vuelve a la página donde estaba (solo rutas internas). --%>
<c:set var="destinoVolver" value="/inicio.jsp" />
<c:if test="${not empty param.volver and param.volver.matches('^/[A-Za-z0-9_./?=&%-]*$') and not fn:startsWith(param.volver, '//') and fn:length(param.volver) < 300}">
  <c:set var="destinoVolver" value="${param.volver}" />
</c:if>

<c:choose>
  <c:when test="${param.accion == 'todas'}">
    <sql:update dataSource="${bd}">
      UPDATE notificacion SET leida = 1 WHERE id_usuario = ? AND leida = 0
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:update>
  </c:when>
  <c:when test="${param.accion == 'abrir'}">
    <c:catch var="idInvalidoAbrir">
      <sql:query var="aviso" dataSource="${bd}">
        SELECT tipo, id_proyecto FROM notificacion WHERE id_notificacion = ? AND id_usuario = ?
        <sql:param value="${param.id + 0}" /><sql:param value="${sessionScope.usuarioId}" />
      </sql:query>
      <c:if test="${aviso.rowCount == 1}">
        <sql:update dataSource="${bd}">
          UPDATE notificacion SET leida = 1 WHERE id_notificacion = ? AND id_usuario = ?
          <sql:param value="${param.id + 0}" /><sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
        <%-- Destino según el tipo de aviso; si no hay uno propio, el proyecto o la página donde estaba --%>
        <c:set var="tipoAviso" value="${aviso.rows[0].tipo}" />
        <c:choose>
          <c:when test="${fn:startsWith(tipoAviso, 'PQRS')}"><c:set var="destinoVolver" value="/modulos/pqrs/pqrs.jsp" /></c:when>
          <c:when test="${tipoAviso == 'IDEA_DECISION'}"><c:set var="destinoVolver" value="/modulos/banco_ideas/banco_ideas.jsp" /></c:when>
          <c:when test="${fn:startsWith(tipoAviso, 'PROPUESTA') or fn:startsWith(tipoAviso, 'IDEA') or tipoAviso == 'COMPANERO_AGREGADO'}"><c:set var="destinoVolver" value="/modulos/propuestas/propuestas_banco.jsp" /></c:when>
          <c:when test="${not empty aviso.rows[0].id_proyecto}"><c:set var="destinoVolver" value="/modulos/proyectos/seguimiento.jsp?id=${aviso.rows[0].id_proyecto}" /></c:when>
        </c:choose>
      </c:if>
    </c:catch>
  </c:when>
</c:choose>
<c:redirect url="${destinoVolver}" />

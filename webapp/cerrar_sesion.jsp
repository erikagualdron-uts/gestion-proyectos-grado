<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%-- Cerrar sesión (RF-06): borra la sesión recordada, la cookie y la sesión actual. --%>
<c:if test="${not empty cookie.recordar.value}">
  <sql:update dataSource="${bd}">
    DELETE FROM sesion_persistente WHERE token_hash = SHA2(?, 256)
    <sql:param value="${cookie.recordar.value}" />
  </sql:update>
  <c:set var="ignorar" value="${pageContext.response.addHeader('Set-Cookie', 'recordar=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax')}" />
</c:if>
<c:set var="ignorar" value="${pageContext.session.invalidate()}" />
<c:redirect url="/index.jsp?salio=1" />

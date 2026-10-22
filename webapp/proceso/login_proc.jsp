<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="paginaPublica" value="true" scope="request" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Inicio de sesión (RF-05). Los mensajes de error no revelan si el correo existe. --%>
<c:set var="correoIngresado" value="${fn:toLowerCase(fn:trim(param.correo))}" />

<c:if test="${empty correoIngresado or empty param.clave}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Ingresa tu correo y tu contraseña." scope="session" />
  <c:redirect url="/index.jsp" />
</c:if>

<sql:query var="resultado" dataSource="${bd}">
  SELECT u.id_usuario, u.nombre_completo, u.correo, u.nivel, u.estado_cuenta,
         IF(u.activo = 1, 'SI', 'NO') AS habilitado, r.nombre AS rol,
         SUBSTRING_INDEX(TRIM(u.nombre_completo), ' ', 1) AS primer_nombre,
         UPPER(CONCAT(LEFT(TRIM(u.nombre_completo), 1),
           IF(LOCATE(' ', TRIM(u.nombre_completo)) > 0,
              LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(u.nombre_completo), ' ', 2), ' ', -1), 1), ''))) AS iniciales
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE u.correo = ? AND u.contrasena_hash = SHA2(CONCAT(u.sal, ?), 256)
  <sql:param value="${correoIngresado}" />
  <sql:param value="${param.clave}" />
</sql:query>

<c:if test="${resultado.rowCount != 1}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Correo o contraseña incorrectos." scope="session" />
  <c:redirect url="/index.jsp" />
</c:if>

<c:set var="u" value="${resultado.rows[0]}" />
<c:if test="${u.estado_cuenta == 'PENDIENTE'}">
  <c:set var="flashTipo" value="warning" scope="session" />
  <c:set var="flashMsg" value="Tu cuenta está pendiente de aprobación. Podrás ingresar cuando el administrador la apruebe." scope="session" />
  <c:redirect url="/index.jsp" />
</c:if>
<c:if test="${u.estado_cuenta == 'RECHAZADA'}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Tu solicitud de cuenta fue rechazada. Comunícate con el administrador." scope="session" />
  <c:redirect url="/index.jsp" />
</c:if>
<c:if test="${u.habilitado != 'SI'}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Tu cuenta está inactiva. Comunícate con el administrador." scope="session" />
  <c:redirect url="/index.jsp" />
</c:if>

<%@ include file="/WEB-INF/includes/iniciar_sesion.jsp" %>

<%-- Casilla "Mantener sesión activa": token aleatorio en cookie; en la base solo se guarda su hash --%>
<c:if test="${param.recordar == 'on'}">
  <sql:query var="tokenRecordar" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(32))) AS t</sql:query>
  <sql:update dataSource="${bd}">DELETE FROM sesion_persistente WHERE fecha_expira < NOW()</sql:update>
  <sql:update dataSource="${bd}">
    INSERT INTO sesion_persistente (id_usuario, token_hash, fecha_expira)
    VALUES (?, SHA2(?, 256), DATE_ADD(NOW(), INTERVAL 30 DAY))
    <sql:param value="${u.id_usuario}" />
    <sql:param value="${tokenRecordar.rows[0].t}" />
  </sql:update>
  <c:set var="galleta">recordar=${tokenRecordar.rows[0].t}; Path=/; Max-Age=2592000; HttpOnly; SameSite=Lax</c:set>
  <c:set var="ignorar" value="${pageContext.response.addHeader('Set-Cookie', galleta)}" />
</c:if>

<c:redirect url="/inicio.jsp" />

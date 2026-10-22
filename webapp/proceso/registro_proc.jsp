<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="paginaPublica" value="true" scope="request" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Registro de cuenta de estudiante (RF-01, RF-02, RF-03). Validación en el servidor (RNF-06). --%>
<c:set var="nombreIngresado" value="${fn:trim(param.nombre)}" />
<c:set var="documentoIngresado" value="${fn:trim(param.documento)}" />
<c:set var="correoIngresado" value="${fn:toLowerCase(fn:trim(param.correo))}" />

<sql:query var="docValido" dataSource="${bd}">
  SELECT (? REGEXP '^[0-9A-Za-z]{5,20}$') AS ok
  <sql:param value="${documentoIngresado}" />
</sql:query>
<sql:query var="repetido" dataSource="${bd}">
  SELECT COUNT(*) AS total FROM usuario WHERE correo = ? OR numero_documento = ?
  <sql:param value="${correoIngresado}" />
  <sql:param value="${documentoIngresado}" />
</sql:query>

<c:choose>
  <c:when test="${fn:length(nombreIngresado) < 5 or fn:length(nombreIngresado) > 120 or not fn:contains(nombreIngresado, ' ')}">
    <c:set var="errorRegistro" value="Ingresa tu nombre completo (nombre y apellido)." />
  </c:when>
  <c:when test="${not fn:contains(',CC,TI,CE,PASAPORTE,OTRO,', ',' += param.tipo += ',')}">
    <c:set var="errorRegistro" value="Selecciona un tipo de documento válido." />
  </c:when>
  <c:when test="${docValido.rows[0].ok != 1}">
    <c:set var="errorRegistro" value="El número de documento debe tener entre 5 y 20 letras o números, sin espacios." />
  </c:when>
  <c:when test="${fn:length(correoIngresado) > 120 or fn:indexOf(correoIngresado, '@') < 1 or fn:length(fn:split(correoIngresado, '@')) != 2 or fn:contains(correoIngresado, ' ') or not fn:endsWith(correoIngresado, '@uts.edu.co')}">
    <c:set var="errorRegistro" value="Usa tu correo institucional de estudiante (@uts.edu.co)." />
  </c:when>
  <c:when test="${fn:length(param.clave) < 8 or fn:length(param.clave) > 64}">
    <c:set var="errorRegistro" value="La contraseña debe tener entre 8 y 64 caracteres." />
  </c:when>
  <c:when test="${param.clave != param.confirmar}">
    <c:set var="errorRegistro" value="Las contraseñas no coinciden." />
  </c:when>
  <c:when test="${repetido.rows[0].total > 0}">
    <c:set var="errorRegistro" value="Ya existe una cuenta con ese correo o número de documento." />
  </c:when>
</c:choose>

<c:if test="${not empty errorRegistro}">
  <c:set var="viejoNombre" value="${nombreIngresado}" scope="session" />
  <c:set var="viejoTipo" value="${param.tipo}" scope="session" />
  <c:set var="viejoDocumento" value="${documentoIngresado}" scope="session" />
  <c:set var="viejoCorreo" value="${correoIngresado}" scope="session" />
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="${errorRegistro}" scope="session" />
  <c:redirect url="/registro.jsp" />
</c:if>

<%-- Hash con sal (RNF-01): SHA2(sal + contraseña). La cuenta queda PENDIENTE hasta que el administrador la apruebe. --%>
<sql:query var="salNueva" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(16))) AS sal</sql:query>
<c:catch var="falloRegistro">
  <sql:transaction dataSource="${bd}">
    <sql:update>
      INSERT INTO usuario (id_rol, tipo_documento, numero_documento, nombre_completo, correo,
                           contrasena_hash, sal, estado_cuenta)
      VALUES ((SELECT id_rol FROM rol WHERE nombre = 'ESTUDIANTE'), ?, ?, ?, ?, SHA2(CONCAT(?, ?), 256), ?, 'PENDIENTE')
      <sql:param value="${param.tipo}" />
      <sql:param value="${documentoIngresado}" />
      <sql:param value="${nombreIngresado}" />
      <sql:param value="${correoIngresado}" />
      <sql:param value="${salNueva.rows[0].sal}" />
      <sql:param value="${param.clave}" />
      <sql:param value="${salNueva.rows[0].sal}" />
    </sql:update>
    <sql:query var="nuevo">SELECT LAST_INSERT_ID() AS id</sql:query>
    <sql:update>
      INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_nuevo, detalle)
      VALUES (?, 'USUARIO', ?, 'REGISTRO', 'PENDIENTE', 'Registro de cuenta de estudiante')
      <sql:param value="${nuevo.rows[0].id}" />
      <sql:param value="${nuevo.rows[0].id}" />
    </sql:update>
  </sql:transaction>
</c:catch>

<c:choose>
  <c:when test="${not empty falloRegistro}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="No se pudo crear la cuenta. Verifica los datos e inténtalo de nuevo." scope="session" />
    <c:redirect url="/registro.jsp" />
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="warning" scope="session" />
    <c:set var="flashMsg" value="Cuenta creada. Queda pendiente de aprobación: podrás ingresar cuando el administrador la apruebe." scope="session" />
    <c:redirect url="/index.jsp" />
  </c:otherwise>
</c:choose>

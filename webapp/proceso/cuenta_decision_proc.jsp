<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Aprobar (con nivel) o rechazar (con observación) una cuenta de estudiante (RF-04). --%>
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:catch var="idInvalido"><c:set var="idCuenta" value="${param.id + 0}" /></c:catch>

<c:choose>
  <c:when test="${not empty idInvalido or empty param.id}">
    <c:set var="errorDecision" value="La solicitud indicada no es válida." />
  </c:when>
  <c:when test="${param.decision != 'APROBAR' and param.decision != 'RECHAZAR'}">
    <c:set var="errorDecision" value="Decisión no válida." />
  </c:when>
  <c:when test="${param.decision == 'APROBAR' and param.nivel != 'TECNOLOGICO' and param.nivel != 'PROFESIONAL'}">
    <c:set var="errorDecision" value="Para aprobar la cuenta debes asignar el nivel (Tecnológico o Profesional)." />
  </c:when>
  <c:when test="${param.decision == 'RECHAZAR' and (empty observacion or fn:length(observacion) > 400)}">
    <c:set var="errorDecision" value="Para rechazar la cuenta escribe el motivo (máximo 400 caracteres)." />
  </c:when>
</c:choose>

<c:if test="${empty errorDecision}">
  <sql:query var="cuenta" dataSource="${bd}">
    SELECT u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE u.id_usuario = ? AND r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE' AND u.activo = 1
    <sql:param value="${idCuenta}" />
  </sql:query>
  <c:if test="${cuenta.rowCount != 1}">
    <c:set var="errorDecision" value="La solicitud ya fue gestionada o no existe." />
  </c:if>
</c:if>

<c:if test="${not empty errorDecision}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="${errorDecision}" scope="session" />
  <c:redirect url="/modulos/usuarios/cuentas_pendientes.jsp" />
</c:if>

<c:set var="aprobar" value="${param.decision == 'APROBAR'}" />
<c:catch var="falloDecision">
  <sql:transaction dataSource="${bd}">
    <sql:update var="filas">
      UPDATE usuario SET estado_cuenta = ?, nivel = ?, id_aprobador = ?, fecha_decision = NOW()
      WHERE id_usuario = ? AND estado_cuenta = 'PENDIENTE'
      <sql:param value="${aprobar ? 'APROBADA' : 'RECHAZADA'}" />
      <sql:param value="${aprobar ? param.nivel : null}" />
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${idCuenta}" />
    </sql:update>
    <c:if test="${filas == 1}">
      <sql:update>
        INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
        VALUES (?, 'USUARIO', ?, ?, 'PENDIENTE', ?, ?)
        <sql:param value="${sessionScope.usuarioId}" />
        <sql:param value="${idCuenta}" />
        <sql:param value="${aprobar ? 'APROBAR_CUENTA' : 'RECHAZAR_CUENTA'}" />
        <sql:param value="${aprobar ? 'APROBADA' : 'RECHAZADA'}" />
        <sql:param value="${aprobar ? ('Nivel asignado: ' += param.nivel) : observacion}" />
      </sql:update>
    </c:if>
  </sql:transaction>
</c:catch>

<c:choose>
  <c:when test="${not empty falloDecision or filas != 1}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="No se pudo registrar la decisión. Inténtalo de nuevo." scope="session" />
  </c:when>
  <c:when test="${aprobar}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Cuenta aprobada: ${cuenta.rows[0].nombre_completo} ingresa con nivel ${param.nivel == 'TECNOLOGICO' ? 'Tecnológico' : 'Profesional'}." scope="session" />
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Cuenta rechazada: ${cuenta.rows[0].nombre_completo}." scope="session" />
  </c:otherwise>
</c:choose>
<c:redirect url="/modulos/usuarios/cuentas_pendientes.jsp" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Asignar director y evaluador a un proyecto (RF-34, RF-35). Solo docentes activos y distintos entre sí.
     Registra el historial y avisa a los docentes asignados y a los estudiantes del proyecto. --%>
<c:catch var="idInvalido">
  <c:set var="idProyecto" value="${param.id + 0}" />
  <c:set var="idDirector" value="${empty param.director ? 0 : param.director + 0}" />
  <c:set var="idEvaluador" value="${empty param.evaluador ? 0 : param.evaluador + 0}" />
</c:catch>

<c:if test="${not empty idInvalido or empty param.id}">
  <c:set var="errorAsignacion" value="Los datos de la asignación no son válidos." />
</c:if>

<c:if test="${empty errorAsignacion}">
  <sql:query var="proyecto" dataSource="${bd}">
    SELECT pr.id_proyecto, pr.estado_general, pr.id_director, pr.id_evaluador, p.codigo
    FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta WHERE pr.id_proyecto = ?
    <sql:param value="${idProyecto}" />
  </sql:query>
  <c:choose>
    <c:when test="${proyecto.rowCount != 1 or proyecto.rows[0].estado_general != 'EN_CURSO'}">
      <c:set var="errorAsignacion" value="El proyecto no existe o ya no admite cambios de asignación." />
    </c:when>
    <c:when test="${idDirector > 0 and idDirector == idEvaluador}">
      <c:set var="errorAsignacion" value="El director y el evaluador deben ser docentes distintos." />
    </c:when>
  </c:choose>
</c:if>

<%-- Los elegidos deben ser docentes activos y con cuenta aprobada --%>
<c:if test="${empty errorAsignacion}">
  <sql:query var="validos" dataSource="${bd}">
    SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1 AND u.id_usuario IN (?, ?)
    <sql:param value="${idDirector}" /><sql:param value="${idEvaluador}" />
  </sql:query>
  <c:set var="esperados" value="${(idDirector > 0 ? 1 : 0) + (idEvaluador > 0 ? 1 : 0)}" />
  <c:if test="${validos.rowCount != esperados}">
    <c:set var="errorAsignacion" value="Solo se pueden asignar docentes activos." />
  </c:if>
</c:if>

<c:if test="${empty errorAsignacion}">
  <c:set var="directorActual" value="${empty proyecto.rows[0].id_director ? 0 : proyecto.rows[0].id_director}" />
  <c:set var="evaluadorActual" value="${empty proyecto.rows[0].id_evaluador ? 0 : proyecto.rows[0].id_evaluador}" />
  <c:set var="cambiaDirector" value="${idDirector != directorActual}" />
  <c:set var="cambiaEvaluador" value="${idEvaluador != evaluadorActual}" />
  <c:if test="${not cambiaDirector and not cambiaEvaluador}">
    <c:set var="flashTipo" value="warning" scope="session" />
    <c:set var="flashMsg" value="No hay cambios en la asignación de ${proyecto.rows[0].codigo}." scope="session" />
    <c:redirect url="/modulos/proyectos/asignacion.jsp" />
  </c:if>

  <c:set var="nombreDirector" value="Sin asignar" />
  <c:set var="nombreEvaluador" value="Sin asignar" />
  <c:forEach var="v" items="${validos.rows}">
    <c:if test="${v.id_usuario == idDirector}"><c:set var="nombreDirector" value="${v.nombre_completo}" /></c:if>
    <c:if test="${v.id_usuario == idEvaluador}"><c:set var="nombreEvaluador" value="${v.nombre_completo}" /></c:if>
  </c:forEach>
  <c:set var="codigoProyecto" value="${proyecto.rows[0].codigo}" />

  <c:catch var="falloAsignacion">
    <sql:transaction dataSource="${bd}">
      <sql:update>
        UPDATE proyecto SET id_director = NULLIF(?, 0), id_evaluador = NULLIF(?, 0) WHERE id_proyecto = ?
        <sql:param value="${idDirector}" /><sql:param value="${idEvaluador}" /><sql:param value="${idProyecto}" />
      </sql:update>
      <sql:update>
        INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, detalle)
        VALUES (?, ?, 'PROYECTO', ?, 'ASIGNAR', ?)
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" /><sql:param value="${idProyecto}" />
        <sql:param value="${fn:substring('Director: ' += nombreDirector += ' | Evaluador: ' += nombreEvaluador, 0, 490)}" />
      </sql:update>
      <c:if test="${cambiaDirector and idDirector > 0}">
        <sql:update>
          INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'ASIGNACION', ?)
          <sql:param value="${idDirector}" /><sql:param value="${idProyecto}" />
          <sql:param value="${'Fuiste asignado como director del proyecto ' += codigoProyecto += '.'}" />
        </sql:update>
      </c:if>
      <c:if test="${cambiaEvaluador and idEvaluador > 0}">
        <sql:update>
          INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'ASIGNACION', ?)
          <sql:param value="${idEvaluador}" /><sql:param value="${idProyecto}" />
          <sql:param value="${'Fuiste asignado como evaluador del proyecto ' += codigoProyecto += '.'}" />
        </sql:update>
      </c:if>
      <sql:update>
        INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
        SELECT pe.id_estudiante, ?, 'ASIGNACION', ?
        FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta WHERE pr.id_proyecto = ?
        <sql:param value="${idProyecto}" />
        <sql:param value="${fn:substring('Asignación actualizada en tu proyecto ' += codigoProyecto += '. Director: ' += nombreDirector += '. Evaluador: ' += nombreEvaluador += '.', 0, 250)}" />
        <sql:param value="${idProyecto}" />
      </sql:update>
    </sql:transaction>
  </c:catch>
  <c:if test="${not empty falloAsignacion}"><c:set var="errorAsignacion" value="No se pudo guardar la asignación. Inténtalo de nuevo." /></c:if>
</c:if>

<c:choose>
  <c:when test="${empty errorAsignacion}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Asignación guardada para ${codigoProyecto}: director ${nombreDirector}, evaluador ${nombreEvaluador}." scope="session" />
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="${errorAsignacion}" scope="session" />
  </c:otherwise>
</c:choose>
<c:redirect url="/modulos/proyectos/asignacion.jsp" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE,COORDINADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%--
  PQRS (RF-53 a RF-56):
    radicar   (estudiante responsable) tipo, asunto, descripción y, para la prórroga, el enlace del soporte de pago
    resolver  (coordinador) aprobar, aplazar o rechazar con respuesta; si aprueba un cambio de director, lo aplica al proyecto
  Todo queda en el historial y genera avisos internos.
--%>
<c:set var="accion" value="${param.accion}" />
<c:set var="asuntoIngresado" value="${fn:trim(param.asunto)}" />
<c:set var="descripcionIngresada" value="${fn:trim(param.descripcion)}" />
<c:set var="soporteIngresado" value="${fn:trim(param.soporte)}" />
<c:set var="respuesta" value="${fn:trim(param.observacion)}" />
<c:set var="destinoError" value="${accion == 'radicar' ? '/modulos/pqrs/pqrs_form.jsp' : '/modulos/pqrs/pqrs.jsp'}" />

<c:choose>
  <c:when test="${accion != 'radicar' and accion != 'resolver'}"><c:set var="errorPqrs" value="Solicitud no válida." /></c:when>
  <c:when test="${(accion == 'radicar' and sessionScope.rol != 'ESTUDIANTE') or (accion == 'resolver' and sessionScope.rol != 'COORDINADOR')}">
    <c:set var="errorPqrs" value="Tu rol no puede realizar esta acción." />
  </c:when>
</c:choose>

<%-- ===================== RADICAR ===================== --%>
<c:if test="${empty errorPqrs and accion == 'radicar'}">
  <sql:query var="membresia" dataSource="${bd}">
    SELECT SUM(pe.es_responsable = 1) AS como_responsable, COUNT(*) AS total
    FROM propuesta_estudiante pe JOIN propuesta p ON p.id_propuesta = pe.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO'
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <sql:query var="proyecto" dataSource="${bd}">
    SELECT pr.id_proyecto, p.codigo FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta
    JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
    WHERE pe.id_estudiante = ? AND pe.es_responsable = 1 ORDER BY pr.id_proyecto DESC LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:choose>
    <c:when test="${membresia.rows[0].total > 0 and membresia.rows[0].como_responsable == 0}">
      <c:set var="errorPqrs" value="Solo el estudiante responsable del proyecto puede radicar una PQRS." />
    </c:when>
    <c:when test="${not fn:contains(',PRORROGA,CAMBIO_DIRECTOR,PETICION,QUEJA,RECLAMO,SUGERENCIA,', ',' += param.tipo += ',')}">
      <c:set var="errorPqrs" value="Selecciona un tipo de solicitud válido." />
    </c:when>
    <c:when test="${(param.tipo == 'PRORROGA' or param.tipo == 'CAMBIO_DIRECTOR') and proyecto.rowCount == 0}">
      <c:set var="errorPqrs" value="La prórroga y el cambio de director requieren un proyecto en curso." />
    </c:when>
    <c:when test="${fn:length(asuntoIngresado) < 5 or fn:length(asuntoIngresado) > 150}">
      <c:set var="errorPqrs" value="El asunto debe tener entre 5 y 150 caracteres." />
    </c:when>
    <c:when test="${fn:length(descripcionIngresada) < 10 or fn:length(descripcionIngresada) > 2000}">
      <c:set var="errorPqrs" value="La descripción debe tener entre 10 y 2000 caracteres." />
    </c:when>
    <c:when test="${param.tipo == 'PRORROGA' and empty soporteIngresado}">
      <c:set var="errorPqrs" value="La prórroga exige el enlace del soporte de pago." />
    </c:when>
    <c:when test="${not empty soporteIngresado and (fn:length(soporteIngresado) > 500 or fn:contains(soporteIngresado, ' ') or not (fn:startsWith(soporteIngresado, 'https://') or fn:startsWith(soporteIngresado, 'http://')))}">
      <c:set var="errorPqrs" value="El enlace del soporte debe empezar por http:// o https://, sin espacios (máximo 500 caracteres)." />
    </c:when>
  </c:choose>

  <c:if test="${empty errorPqrs}">
    <c:set var="idProyectoPqrs" value="${proyecto.rowCount > 0 ? proyecto.rows[0].id_proyecto : null}" />
    <c:catch var="falloPqrs">
      <sql:transaction dataSource="${bd}">
        <sql:update>
          INSERT INTO pqrs (codigo, id_proyecto, id_solicitante, tipo, asunto, descripcion, enlace_soporte)
          VALUES (CONCAT('T', LEFT(HEX(RANDOM_BYTES(7)), 14)), ?, ?, ?, ?, ?, NULLIF(?, ''))
          <sql:param value="${idProyectoPqrs}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${param.tipo}" />
          <sql:param value="${asuntoIngresado}" /><sql:param value="${descripcionIngresada}" /><sql:param value="${soporteIngresado}" />
        </sql:update>
        <sql:query var="nueva">SELECT LAST_INSERT_ID() AS id</sql:query>
        <sql:update>
          UPDATE pqrs SET codigo = CONCAT('PQ-', LPAD(id_pqrs, 5, '0')) WHERE id_pqrs = ?
          <sql:param value="${nueva.rows[0].id}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_nuevo, detalle)
          VALUES (?, ?, 'PQRS', ?, 'RADICAR', 'PENDIENTE', ?)
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyectoPqrs}" /><sql:param value="${nueva.rows[0].id}" />
          <sql:param value="${fn:substring(param.tipo += ': ' += asuntoIngresado, 0, 490)}" />
        </sql:update>
        <sql:update>
          INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
          SELECT u.id_usuario, ?, 'PQRS_NUEVA', ?
          FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
          <sql:param value="${idProyectoPqrs}" />
          <sql:param value="${fn:substring('Nueva PQRS por resolver: ' += asuntoIngresado, 0, 250)}" />
        </sql:update>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPqrs}"><c:set var="errorPqrs" value="No se pudo radicar la PQRS. Inténtalo de nuevo." /></c:if>
  </c:if>

  <c:choose>
    <c:when test="${empty errorPqrs}">
      <c:set var="flashTipo" value="success" scope="session" />
      <c:set var="flashMsg" value="PQRS radicada. Queda pendiente de respuesta del comité." scope="session" />
      <c:redirect url="/modulos/pqrs/pqrs.jsp" />
    </c:when>
    <c:otherwise>
      <c:set var="vqTipo" value="${param.tipo}" scope="session" />
      <c:set var="vqAsunto" value="${asuntoIngresado}" scope="session" />
      <c:set var="vqDescripcion" value="${descripcionIngresada}" scope="session" />
      <c:set var="vqSoporte" value="${soporteIngresado}" scope="session" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- ===================== RESOLVER ===================== --%>
<c:if test="${empty errorPqrs and accion == 'resolver'}">
  <c:catch var="idInvalido"><c:set var="idPqrs" value="${param.id + 0}" /></c:catch>
  <c:catch var="directorInvalido"><c:set var="idNuevoDirector" value="${empty param.nuevoDirector ? 0 : param.nuevoDirector + 0}" /></c:catch>
  <c:choose>
    <c:when test="${not empty idInvalido or empty param.id or not empty directorInvalido}"><c:set var="errorPqrs" value="La PQRS indicada no es válida." /></c:when>
    <c:when test="${param.decision != 'APROBAR' and param.decision != 'APLAZAR' and param.decision != 'RECHAZAR'}"><c:set var="errorPqrs" value="Decisión no válida." /></c:when>
    <c:when test="${param.decision != 'APROBAR' and empty respuesta}"><c:set var="errorPqrs" value="Para aplazar o rechazar escribe la respuesta." /></c:when>
    <c:when test="${fn:length(respuesta) > 2000}"><c:set var="errorPqrs" value="La respuesta puede tener máximo 2000 caracteres." /></c:when>
  </c:choose>
  <c:if test="${empty errorPqrs}">
    <sql:query var="pqrs" dataSource="${bd}">
      SELECT q.id_pqrs, q.codigo, q.tipo, q.estado, q.id_proyecto, q.id_solicitante, pr.id_director, pr.id_evaluador, pr.estado_general
      FROM pqrs q LEFT JOIN proyecto pr ON pr.id_proyecto = q.id_proyecto WHERE q.id_pqrs = ?
      <sql:param value="${idPqrs}" />
    </sql:query>
    <c:if test="${pqrs.rowCount != 1 or pqrs.rows[0].estado != 'PENDIENTE'}"><c:set var="errorPqrs" value="La PQRS ya fue resuelta o no existe." /></c:if>
  </c:if>
  <c:set var="cambiaDirector" value="${empty errorPqrs and param.decision == 'APROBAR' and pqrs.rows[0].tipo == 'CAMBIO_DIRECTOR'}" />
  <c:if test="${empty errorPqrs and cambiaDirector}">
    <sql:query var="nuevoDir" dataSource="${bd}">
      SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
      WHERE r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1 AND u.id_usuario = ?
      <sql:param value="${idNuevoDirector}" />
    </sql:query>
    <c:choose>
      <c:when test="${empty pqrs.rows[0].id_proyecto or pqrs.rows[0].estado_general != 'EN_CURSO'}"><c:set var="errorPqrs" value="El proyecto no existe o ya no está en curso." /></c:when>
      <c:when test="${nuevoDir.rowCount != 1}"><c:set var="errorPqrs" value="Para aprobar el cambio selecciona un docente activo como nuevo director." /></c:when>
      <c:when test="${idNuevoDirector == pqrs.rows[0].id_evaluador}"><c:set var="errorPqrs" value="El nuevo director no puede ser el evaluador del mismo proyecto." /></c:when>
      <c:when test="${idNuevoDirector == pqrs.rows[0].id_director}"><c:set var="errorPqrs" value="Ese docente ya es el director del proyecto." /></c:when>
    </c:choose>
  </c:if>

  <c:if test="${empty errorPqrs}">
    <c:set var="nuevoEstado" value="${param.decision == 'APROBAR' ? 'APROBADO' : (param.decision == 'APLAZAR' ? 'APLAZADO' : 'RECHAZADO')}" />
    <c:set var="textoEstado" value="${param.decision == 'APROBAR' ? 'aprobada' : (param.decision == 'APLAZAR' ? 'aplazada' : 'rechazada')}" />
    <c:catch var="falloPqrs">
      <sql:transaction dataSource="${bd}">
        <sql:update var="filas">
          UPDATE pqrs SET estado = ?, respuesta = NULLIF(?, ''), id_resuelto_por = ?, fecha_resolucion = NOW(), id_nuevo_director = ?
          WHERE id_pqrs = ? AND estado = 'PENDIENTE'
          <sql:param value="${nuevoEstado}" /><sql:param value="${respuesta}" /><sql:param value="${sessionScope.usuarioId}" />
          <sql:param value="${cambiaDirector ? idNuevoDirector : null}" /><sql:param value="${idPqrs}" />
        </sql:update>
        <c:if test="${filas == 1}">
          <sql:update>
            INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
            VALUES (?, ?, 'PQRS', ?, 'RESOLVER', 'PENDIENTE', ?, ?)
            <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${pqrs.rows[0].id_proyecto}" /><sql:param value="${idPqrs}" /><sql:param value="${nuevoEstado}" />
            <sql:param value="${empty respuesta ? 'Sin respuesta escrita' : fn:substring(respuesta, 0, 490)}" />
          </sql:update>
          <c:if test="${cambiaDirector}">
            <sql:update>
              UPDATE proyecto SET id_director = ? WHERE id_proyecto = ?
              <sql:param value="${idNuevoDirector}" /><sql:param value="${pqrs.rows[0].id_proyecto}" />
            </sql:update>
            <sql:update>
              INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
              VALUES (?, ?, 'PROYECTO', ?, 'CAMBIAR_DIRECTOR', NULL, NULL, ?)
              <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${pqrs.rows[0].id_proyecto}" /><sql:param value="${pqrs.rows[0].id_proyecto}" />
              <sql:param value="${'Nuevo director: ' += nuevoDir.rows[0].nombre_completo += ' (PQRS ' += pqrs.rows[0].codigo += ')'}" />
            </sql:update>
            <sql:update>
              INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'ASIGNACION', ?)
              <sql:param value="${idNuevoDirector}" /><sql:param value="${pqrs.rows[0].id_proyecto}" />
              <sql:param value="${'Fuiste asignado como director del proyecto por la PQRS ' += pqrs.rows[0].codigo += '.'}" />
            </sql:update>
            <c:if test="${not empty pqrs.rows[0].id_evaluador}">
              <sql:update>
                INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'ASIGNACION', ?)
                <sql:param value="${pqrs.rows[0].id_evaluador}" /><sql:param value="${pqrs.rows[0].id_proyecto}" />
                <sql:param value="${'Cambió el director del proyecto (PQRS ' += pqrs.rows[0].codigo += '): ahora es ' += nuevoDir.rows[0].nombre_completo += '.'}" />
              </sql:update>
            </c:if>
          </c:if>
          <sql:update>
            INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'PQRS_RESPUESTA', ?)
            <sql:param value="${pqrs.rows[0].id_solicitante}" /><sql:param value="${pqrs.rows[0].id_proyecto}" />
            <sql:param value="${'Tu PQRS ' += pqrs.rows[0].codigo += ' fue ' += textoEstado += '.'}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPqrs or filas != 1}"><c:set var="errorPqrs" value="No se pudo registrar la respuesta. Inténtalo de nuevo." /></c:if>
  </c:if>
  <c:if test="${empty errorPqrs}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="PQRS ${pqrs.rows[0].codigo} ${textoEstado}.${cambiaDirector ? ' El nuevo director quedó asignado al proyecto.' : ''}" scope="session" />
    <c:redirect url="/modulos/pqrs/pqrs.jsp" />
  </c:if>
</c:if>

<c:set var="flashTipo" value="danger" scope="session" />
<c:set var="flashMsg" value="${errorPqrs}" scope="session" />
<c:redirect url="${destinoError}" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/fases.jsp" %>
<%-- Entrega de un documento por enlace (RF-39, RF-40, RF-42, RF-47, RF-59). Solo el estudiante responsable entrega
     (el compañero solo visualiza). Cada entrega crea una nueva versión vigente y conserva las anteriores. --%>
<c:set var="enlaceIngresado" value="${fn:trim(param.enlace)}" />
<c:set var="comentarioIngresado" value="${fn:trim(param.comentario)}" />
<c:catch var="idInvalido"><c:set var="idProyecto" value="${param.id + 0}" /></c:catch>
<c:set var="destino" value="/modulos/proyectos/seguimiento.jsp" />

<c:if test="${not empty idInvalido or empty param.id}">
  <c:set var="errorEntrega" value="El proyecto indicado no es válido." />
</c:if>

<c:if test="${empty errorEntrega}">
  <sql:query var="consulta" dataSource="${bd}">
    SELECT pr.id_proyecto, pr.fase_actual, pr.estado_general, pr.id_director, pr.id_evaluador, p.codigo,
           (SELECT pe.id_estudiante FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.es_responsable = 1 LIMIT 1) AS id_responsable,
           (SELECT IF(e.activo = 1, 'SI', 'NO') FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante
            WHERE pe.id_propuesta = p.id_propuesta AND pe.es_responsable = 1 LIMIT 1) AS responsable_activo,
           pf.id_proyecto_fase, pf.estado AS estado_fase
    FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
    JOIN proyecto_fase pf ON pf.id_proyecto = pr.id_proyecto AND pf.id_fase = pr.fase_actual
    WHERE pr.id_proyecto = ?
    <sql:param value="${idProyecto}" />
  </sql:query>
  <c:if test="${consulta.rowCount != 1}"><c:set var="errorEntrega" value="El proyecto no existe." /></c:if>
</c:if>

<c:if test="${empty errorEntrega}">
  <c:set var="py" value="${consulta.rows[0]}" />
  <c:set var="fase" value="${py.fase_actual}" />
  <c:set var="nombreDocumento" value="${nombresDocumento[fase - 1]}" />
  <sql:query var="existente" dataSource="${bd}">
    SELECT id_documento, version_num FROM documento
    WHERE id_proyecto_fase = ? AND nombre = ? AND vigente = 1 ORDER BY version_num DESC LIMIT 1
    <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${nombreDocumento}" />
  </sql:query>
  <c:choose>
    <c:when test="${py.id_responsable != sessionScope.usuarioId}">
      <c:set var="errorEntrega" value="Solo el estudiante responsable del proyecto puede entregar documentos." />
    </c:when>
    <c:when test="${py.responsable_activo != 'SI'}">
      <c:set var="errorEntrega" value="El responsable del proyecto está inactivo; el proyecto no recibe documentos." />
    </c:when>
    <c:when test="${py.estado_general != 'EN_CURSO'}">
      <c:set var="errorEntrega" value="El proyecto ya no admite entregas." />
    </c:when>
    <c:when test="${(fase == 2 or fase == 3 or fase == 4 or fase == 5) and empty py.id_director}">
      <c:set var="errorEntrega" value="El coordinador aún no ha asignado un director al proyecto." />
    </c:when>
    <c:when test="${py.estado_fase != 'APLAZADA' and not (py.estado_fase == 'EN_CURSO' and (fase == 1 or fase == 2 or fase == 4) and existente.rowCount == 0)}">
      <c:set var="errorEntrega" value="Ahora no puedes entregar un documento: el actual está en revisión o la fase no admite entregas." />
    </c:when>
    <c:when test="${empty enlaceIngresado or fn:length(enlaceIngresado) > 500 or fn:contains(enlaceIngresado, ' ') or not (fn:startsWith(enlaceIngresado, 'https://') or fn:startsWith(enlaceIngresado, 'http://'))}">
      <c:set var="errorEntrega" value="Ingresa un enlace válido: debe empezar por http:// o https://, sin espacios (máximo 500 caracteres)." />
    </c:when>
    <c:when test="${fn:length(comentarioIngresado) > 300}">
      <c:set var="errorEntrega" value="El comentario puede tener máximo 300 caracteres." />
    </c:when>
  </c:choose>
</c:if>

<c:if test="${empty errorEntrega}">
  <c:set var="versionNueva" value="${existente.rowCount == 0 ? 1 : existente.rows[0].version_num + 1}" />
  <c:set var="notaHistorial" value="${fn:substring(nombreDocumento += ' v' += versionNueva += ': ' += enlaceIngresado, 0, 490)}" />
  <c:catch var="falloEntrega">
    <sql:transaction dataSource="${bd}">
      <sql:update>
        UPDATE documento SET vigente = 0 WHERE id_proyecto_fase = ? AND nombre = ?
        <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${nombreDocumento}" />
      </sql:update>
      <sql:update>
        INSERT INTO documento (id_proyecto_fase, nombre, version_num, enlace_url, id_subido_por, vigente, comentario)
        VALUES (?, ?, ?, ?, ?, 1, NULLIF(?, ''))
        <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${nombreDocumento}" /><sql:param value="${versionNueva}" />
        <sql:param value="${enlaceIngresado}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${comentarioIngresado}" />
      </sql:update>
      <sql:query var="nuevoDoc">SELECT LAST_INSERT_ID() AS id</sql:query>
      <c:if test="${py.estado_fase == 'APLAZADA'}">
        <sql:update>
          UPDATE proyecto_fase SET estado = 'EN_CURSO' WHERE id_proyecto_fase = ?
          <sql:param value="${py.id_proyecto_fase}" />
        </sql:update>
      </c:if>
      <sql:update>
        INSERT INTO historial_version (id_usuario, id_proyecto, id_documento, entidad, id_entidad, accion, estado_anterior, estado_nuevo, version_num, detalle)
        VALUES (?, ?, ?, 'DOCUMENTO', ?, 'ENTREGAR', ?, 'EN_REVISION', ?, ?)
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" /><sql:param value="${nuevoDoc.rows[0].id}" />
        <sql:param value="${nuevoDoc.rows[0].id}" /><sql:param value="${py.estado_fase == 'APLAZADA' ? 'APLAZADO' : null}" />
        <sql:param value="${versionNueva}" /><sql:param value="${notaHistorial}" />
      </sql:update>
      <%-- Aviso al revisor: coordinador (fase 1), director (fases 2 a 5) o evaluador y comité (fase 6) --%>
      <c:choose>
        <c:when test="${fase == 1}">
          <sql:update>
            INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
            SELECT u.id_usuario, ?, 'ENTREGA', ?
            FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
            <sql:param value="${idProyecto}" />
            <sql:param value="${'Pago por validar en el proyecto ' += py.codigo += '.'}" />
          </sql:update>
        </c:when>
        <c:otherwise>
          <sql:update>
            INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'ENTREGA', ?)
            <sql:param value="${py.id_director}" /><sql:param value="${idProyecto}" />
            <sql:param value="${'Nueva versión de ' += nombreDocumento += ' por revisar en el proyecto ' += py.codigo += '.'}" />
          </sql:update>
        </c:otherwise>
      </c:choose>
    </sql:transaction>
  </c:catch>
  <c:if test="${not empty falloEntrega}"><c:set var="errorEntrega" value="No se pudo registrar la entrega. Inténtalo de nuevo." /></c:if>
</c:if>

<c:choose>
  <c:when test="${empty errorEntrega}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Entrega registrada: ${nombreDocumento} v${versionNueva}. Quedó pendiente de revisión." scope="session" />
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="${errorEntrega}" scope="session" />
  </c:otherwise>
</c:choose>
<c:choose>
  <c:when test="${idProyecto > 0}"><c:redirect url="${destino}"><c:param name="id" value="${idProyecto}" /></c:redirect></c:when>
  <c:otherwise><c:redirect url="/inicio.jsp" /></c:otherwise>
</c:choose>

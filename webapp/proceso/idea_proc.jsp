<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="DOCENTE,COORDINADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Ideas de docentes: crear (docente, RF-21) y decidir (coordinador, RF-22). Todo queda en el historial. --%>
<c:set var="accion" value="${param.accion}" />
<c:set var="tituloIngresado" value="${fn:trim(param.titulo)}" />
<c:set var="descripcionIngresada" value="${fn:trim(param.descripcion)}" />
<c:set var="objetivoIngresado" value="${fn:trim(param.objetivo)}" />
<c:set var="alcanceIngresado" value="${fn:trim(param.alcance)}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="destino" value="${accion == 'crear' ? '/modulos/banco_ideas/idea_form.jsp' : '/modulos/propuestas/propuestas_banco.jsp'}" />

<c:choose>
  <c:when test="${accion == 'crear' and sessionScope.rol != 'DOCENTE'}">
    <c:set var="errorIdea" value="Solo los docentes pueden proponer ideas." />
  </c:when>
  <c:when test="${accion == 'decidir' and sessionScope.rol != 'COORDINADOR'}">
    <c:set var="errorIdea" value="Solo el coordinador puede decidir sobre las ideas." />
  </c:when>
  <c:when test="${accion != 'crear' and accion != 'decidir'}">
    <c:set var="errorIdea" value="Solicitud no válida." />
  </c:when>
</c:choose>

<%-- ===== Crear idea ===== --%>
<c:if test="${empty errorIdea and accion == 'crear'}">
  <c:choose>
    <c:when test="${fn:length(tituloIngresado) < 5 or fn:length(tituloIngresado) > 200}">
      <c:set var="errorIdea" value="El título debe tener entre 5 y 200 caracteres." />
    </c:when>
    <c:when test="${empty descripcionIngresada or empty objetivoIngresado or empty alcanceIngresado}">
      <c:set var="errorIdea" value="Título, descripción, objetivo y alcance son obligatorios." />
    </c:when>
    <c:when test="${fn:length(descripcionIngresada) > 2000 or fn:length(objetivoIngresado) > 2000 or fn:length(alcanceIngresado) > 2000}">
      <c:set var="errorIdea" value="Cada campo puede tener máximo 2000 caracteres." />
    </c:when>
  </c:choose>
  <c:if test="${empty errorIdea}">
    <c:catch var="falloIdea">
      <sql:transaction dataSource="${bd}">
        <sql:update>
          INSERT INTO idea_banco (codigo, id_docente, titulo, descripcion, objetivo, alcance)
          VALUES (CONCAT('T', LEFT(HEX(RANDOM_BYTES(7)), 14)), ?, ?, ?, ?, ?)
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${tituloIngresado}" />
          <sql:param value="${descripcionIngresada}" /><sql:param value="${objetivoIngresado}" /><sql:param value="${alcanceIngresado}" />
        </sql:update>
        <sql:query var="nueva">SELECT LAST_INSERT_ID() AS id</sql:query>
        <sql:update>
          UPDATE idea_banco SET codigo = CONCAT('ID-', LPAD(id_idea, 4, '0')) WHERE id_idea = ?
          <sql:param value="${nueva.rows[0].id}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_nuevo, detalle)
          VALUES (?, 'IDEA', ?, 'CREAR', 'PENDIENTE', ?)
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${nueva.rows[0].id}" /><sql:param value="${fn:substring(tituloIngresado, 0, 200)}" />
        </sql:update>
        <sql:update>
          INSERT INTO notificacion (id_usuario, tipo, mensaje)
          SELECT u.id_usuario, 'IDEA_NUEVA', ?
          FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
          WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
          <sql:param value="${fn:substring('Nueva idea de docente por revisar: ' += tituloIngresado, 0, 250)}" />
        </sql:update>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloIdea}"><c:set var="errorIdea" value="No se pudo registrar la idea. Inténtalo de nuevo." /></c:if>
  </c:if>
  <c:choose>
    <c:when test="${empty errorIdea}">
      <c:set var="flashTipo" value="success" scope="session" />
      <c:set var="flashMsg" value="Idea enviada. Queda pendiente de revisión en Propuestas Banco." scope="session" />
      <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
    </c:when>
    <c:otherwise>
      <c:set var="viTitulo" value="${tituloIngresado}" scope="session" />
      <c:set var="viDescripcion" value="${descripcionIngresada}" scope="session" />
      <c:set var="viObjetivo" value="${objetivoIngresado}" scope="session" />
      <c:set var="viAlcance" value="${alcanceIngresado}" scope="session" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- ===== Decidir sobre una idea ===== --%>
<c:if test="${empty errorIdea and accion == 'decidir'}">
  <c:catch var="idInvalido"><c:set var="idIdea" value="${param.id + 0}" /></c:catch>
  <c:choose>
    <c:when test="${not empty idInvalido or empty param.id}">
      <c:set var="errorIdea" value="La idea indicada no es válida." />
    </c:when>
    <c:when test="${param.decision != 'APROBAR' and param.decision != 'APLAZAR' and param.decision != 'RECHAZAR'}">
      <c:set var="errorIdea" value="Decisión no válida." />
    </c:when>
    <c:when test="${param.decision != 'APROBAR' and (empty observacion or fn:length(observacion) > 500)}">
      <c:set var="errorIdea" value="Para aplazar o rechazar escribe la observación (máximo 500 caracteres)." />
    </c:when>
    <c:when test="${fn:length(observacion) > 500}">
      <c:set var="errorIdea" value="La observación puede tener máximo 500 caracteres." />
    </c:when>
  </c:choose>
  <c:if test="${empty errorIdea}">
    <sql:query var="idea" dataSource="${bd}">
      SELECT id_idea, codigo, id_docente, estado_decision FROM idea_banco WHERE id_idea = ?
      <sql:param value="${idIdea}" />
    </sql:query>
    <c:if test="${idea.rowCount != 1 or idea.rows[0].estado_decision != 'PENDIENTE'}">
      <c:set var="errorIdea" value="La idea ya fue decidida o no existe." />
    </c:if>
  </c:if>
  <c:if test="${empty errorIdea}">
    <c:set var="nuevoEstado" value="${param.decision == 'APROBAR' ? 'APROBADO' : (param.decision == 'APLAZAR' ? 'APLAZADO' : 'RECHAZADO')}" />
    <c:set var="textoEstado" value="${param.decision == 'APROBAR' ? 'aprobada' : (param.decision == 'APLAZAR' ? 'aplazada' : 'rechazada')}" />
    <c:catch var="falloIdea">
      <sql:transaction dataSource="${bd}">
        <sql:update var="filas">
          UPDATE idea_banco SET estado_decision = ?, observacion = NULLIF(?, ''), id_revisor = ?, fecha_decision = NOW()
          WHERE id_idea = ? AND estado_decision = 'PENDIENTE'
          <sql:param value="${nuevoEstado}" /><sql:param value="${observacion}" />
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idIdea}" />
        </sql:update>
        <c:if test="${filas == 1}">
          <sql:update>
            INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
            VALUES (?, 'IDEA', ?, 'DECIDIR', 'PENDIENTE', ?, ?)
            <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idIdea}" /><sql:param value="${nuevoEstado}" />
            <sql:param value="${empty observacion ? 'Sin observación' : fn:substring(observacion, 0, 500)}" />
          </sql:update>
          <sql:update>
            INSERT INTO notificacion (id_usuario, tipo, mensaje) VALUES (?, 'IDEA_DECISION', ?)
            <sql:param value="${idea.rows[0].id_docente}" />
            <sql:param value="${'Tu idea ' += idea.rows[0].codigo += ' fue ' += textoEstado += '.'}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloIdea or filas != 1}"><c:set var="errorIdea" value="No se pudo registrar la decisión. Inténtalo de nuevo." /></c:if>
  </c:if>
  <c:if test="${empty errorIdea}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Idea ${idea.rows[0].codigo} ${textoEstado}." scope="session" />
    <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
  </c:if>
</c:if>

<c:set var="flashTipo" value="danger" scope="session" />
<c:set var="flashMsg" value="${errorIdea}" scope="session" />
<c:redirect url="${destino}" />

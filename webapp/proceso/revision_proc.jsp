<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="DOCENTE,COORDINADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/fases.jsp" %>
<%--
  Registrar o editar la decisión de un revisor sobre el documento de la fase actual (RF-41, RF-43, RF-44, RF-45, RF-46, RF-52).
  Fase 1: comité (coordinador). Fases 2 y 4: director. Fases 3 y 5: el director aprueba el envío y luego deciden evaluador y comité.
  Fase 6: evaluador y comité. Resultado de la fase: cualquier RECHAZADO la cierra; cualquier APLAZADO la devuelve al estudiante;
  cuando todos los requeridos aprueban, avanza (la fase 6 deja el proyecto apto para graduación).
--%>
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="rejillaIngresada" value="${fn:trim(param.rejilla)}" />
<c:set var="turnitinIngresado" value="${fn:trim(param.turnitin)}" />
<c:catch var="idInvalido">
  <c:set var="idProyecto" value="${param.id + 0}" />
  <c:set var="idDocumento" value="${param.documento + 0}" />
</c:catch>
<c:set var="destinoError" value="${sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : '/modulos/docente_director/docente_director.jsp'}" />

<c:if test="${not empty idInvalido or empty param.id or empty param.documento}">
  <c:set var="errorRevision" value="La solicitud no es válida." />
</c:if>
<c:if test="${empty errorRevision and param.decision != 'APROBAR' and param.decision != 'APLAZAR' and param.decision != 'RECHAZAR'}">
  <c:set var="errorRevision" value="Decisión no válida." />
</c:if>

<c:if test="${empty errorRevision}">
  <sql:query var="consulta" dataSource="${bd}">
    SELECT pr.id_proyecto, pr.fase_actual, pr.estado_general, pr.id_director, pr.id_evaluador, p.codigo,
           pf.id_proyecto_fase, pf.estado AS estado_fase
    FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
    JOIN proyecto_fase pf ON pf.id_proyecto = pr.id_proyecto AND pf.id_fase = pr.fase_actual
    WHERE pr.id_proyecto = ?
    <sql:param value="${idProyecto}" />
  </sql:query>
  <c:if test="${consulta.rowCount != 1}"><c:set var="errorRevision" value="El proyecto no existe." /></c:if>
</c:if>

<c:if test="${empty errorRevision}">
  <c:set var="py" value="${consulta.rows[0]}" />
  <c:set var="fase" value="${py.fase_actual}" />
  <c:set var="nombrePrincipal" value="${nombresDocumento[fase - 1]}" />
  <c:choose>
    <c:when test="${sessionScope.rol == 'COORDINADOR'}"><c:set var="rolRevision" value="COMITE" /></c:when>
    <c:when test="${py.id_director == sessionScope.usuarioId}"><c:set var="rolRevision" value="DIRECTOR" /></c:when>
    <c:when test="${py.id_evaluador == sessionScope.usuarioId}"><c:set var="rolRevision" value="EVALUADOR" /></c:when>
  </c:choose>
  <sql:query var="doc" dataSource="${bd}">
    SELECT id_documento, version_num, enlace_url FROM documento
    WHERE id_proyecto_fase = ? AND nombre = ? AND vigente = 1 ORDER BY version_num DESC LIMIT 1
    <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${nombrePrincipal}" />
  </sql:query>
  <sql:query var="previas" dataSource="${bd}">
    SELECT id_revision, rol_revisor, decision FROM revision WHERE id_documento = ?
    <sql:param value="${idDocumento}" />
  </sql:query>
  <c:if test="${rolRevision == 'EVALUADOR' and fase == 3}">
    <sql:query var="rejillaRonda" dataSource="${bd}">
      SELECT COUNT(*) AS total FROM documento
      WHERE id_proyecto_fase = ? AND nombre = 'Rejilla de evaluación'
        AND fecha_subida >= (SELECT fecha_subida FROM documento WHERE id_documento = ?)
      <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${idDocumento}" />
    </sql:query>
  </c:if>
  <c:set var="miPrevia" value="${0}" />
  <c:set var="directorAprobo" value="${false}" />
  <c:set var="otrosDecidieron" value="${false}" />
  <c:forEach var="r" items="${previas.rows}">
    <c:if test="${r.rol_revisor != 'DIRECTOR'}"><c:set var="otrosDecidieron" value="${true}" /></c:if>
    <c:if test="${r.rol_revisor == rolRevision}"><c:set var="miPrevia" value="${r.id_revision}" /></c:if>
    <c:if test="${r.rol_revisor == 'DIRECTOR' and r.decision == 'APROBADO'}"><c:set var="directorAprobo" value="${true}" /></c:if>
  </c:forEach>
  <c:set var="faseCorresponde" value="${rolRevision == 'COMITE' ? (fase == 1 or fase == 3 or fase == 5 or fase == 6) : (rolRevision == 'DIRECTOR' ? (fase == 2 or fase == 3 or fase == 4 or fase == 5) : (rolRevision == 'EVALUADOR' and (fase == 3 or fase == 5 or fase == 6)))}" />

  <c:choose>
    <c:when test="${empty rolRevision}"><c:set var="errorRevision" value="No eres revisor de este proyecto." /></c:when>
    <c:when test="${py.estado_general != 'EN_CURSO'}"><c:set var="errorRevision" value="El proyecto ya no está en curso." /></c:when>
    <c:when test="${not faseCorresponde}"><c:set var="errorRevision" value="En esta fase no te corresponde revisar con tu rol." /></c:when>
    <c:when test="${py.estado_fase != 'EN_CURSO'}"><c:set var="errorRevision" value="La fase no está esperando una revisión." /></c:when>
    <c:when test="${doc.rowCount != 1 or doc.rows[0].id_documento != idDocumento}"><c:set var="errorRevision" value="El documento cambió o no existe: recarga la página y revisa la versión vigente." /></c:when>
    <c:when test="${rolRevision != 'DIRECTOR' and (fase == 3 or fase == 5) and not directorAprobo}"><c:set var="errorRevision" value="Primero el director debe aprobar el envío del documento." /></c:when>
    <c:when test="${rolRevision == 'DIRECTOR' and (fase == 3 or fase == 5) and otrosDecidieron}"><c:set var="errorRevision" value="El evaluador o el comité ya decidieron sobre esta versión: tu decisión quedó cerrada." /></c:when>
    <c:when test="${param.decision == 'APROBAR' and rolRevision == 'EVALUADOR' and fase == 3 and empty rejillaIngresada and rejillaRonda.rows[0].total == 0}">
      <c:set var="errorRevision" value="Para aprobar la Fase 3 adjunta el enlace de la rejilla de evaluación diligenciada (formato F-DC-124)." />
    </c:when>
    <c:when test="${param.decision != 'APROBAR' and (empty observacion or fn:length(observacion) > 2000)}"><c:set var="errorRevision" value="Para aplazar o rechazar escribe las observaciones (máximo 2000 caracteres)." /></c:when>
    <c:when test="${fn:length(observacion) > 2000}"><c:set var="errorRevision" value="Las observaciones pueden tener máximo 2000 caracteres." /></c:when>
    <c:when test="${(not empty rejillaIngresada and (fn:length(rejillaIngresada) > 500 or fn:contains(rejillaIngresada, ' ') or not (fn:startsWith(rejillaIngresada, 'https://') or fn:startsWith(rejillaIngresada, 'http://'))))
                   or (not empty turnitinIngresado and (fn:length(turnitinIngresado) > 500 or fn:contains(turnitinIngresado, ' ') or not (fn:startsWith(turnitinIngresado, 'https://') or fn:startsWith(turnitinIngresado, 'http://'))))}">
      <c:set var="errorRevision" value="Los enlaces de rejilla y Turnitin deben empezar por http:// o https://, sin espacios." />
    </c:when>
  </c:choose>
</c:if>

<c:if test="${empty errorRevision}">
  <c:set var="decisionBd" value="${param.decision == 'APROBAR' ? 'APROBADO' : (param.decision == 'APLAZAR' ? 'APLAZADO' : 'RECHAZADO')}" />
  <c:set var="textoDecision" value="${param.decision == 'APROBAR' ? 'aprobó' : (param.decision == 'APLAZAR' ? 'aplazó' : 'rechazó')}" />
  <c:set var="rolTexto" value="${rolRevision == 'COMITE' ? 'El comité' : (rolRevision == 'DIRECTOR' ? 'El director' : 'El evaluador')}" />
  <c:set var="resultadoFase" value="EN_CURSO" />
  <c:set var="proximaFase" value="${fase + 1}" />

  <c:catch var="falloRevision">
    <sql:transaction dataSource="${bd}">
      <%-- 1. Guardar (crear o editar) mi revisión --%>
      <c:choose>
        <c:when test="${miPrevia > 0}">
          <sql:update>
            UPDATE revision SET decision = ?, observaciones = NULLIF(?, ''), fecha_revision = NOW() WHERE id_revision = ?
            <sql:param value="${decisionBd}" /><sql:param value="${observacion}" /><sql:param value="${miPrevia}" />
          </sql:update>
        </c:when>
        <c:otherwise>
          <sql:update>
            INSERT INTO revision (id_proyecto_fase, id_documento, id_revisor, rol_revisor, decision, observaciones)
            VALUES (?, ?, ?, ?, ?, NULLIF(?, ''))
            <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${idDocumento}" /><sql:param value="${sessionScope.usuarioId}" />
            <sql:param value="${rolRevision}" /><sql:param value="${decisionBd}" /><sql:param value="${observacion}" />
          </sql:update>
        </c:otherwise>
      </c:choose>
      <sql:update>
        INSERT INTO historial_version (id_usuario, id_proyecto, id_documento, entidad, id_entidad, accion, estado_anterior, estado_nuevo, version_num, detalle)
        VALUES (?, ?, ?, 'DOCUMENTO', ?, ?, ?, ?, ?, ?)
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" /><sql:param value="${idDocumento}" /><sql:param value="${idDocumento}" />
        <sql:param value="${miPrevia > 0 ? 'EDITAR_REVISION' : 'REVISAR'}" /><sql:param value="${miPrevia > 0 ? 'REVISADO' : 'PENDIENTE'}" /><sql:param value="${decisionBd}" />
        <sql:param value="${doc.rows[0].version_num}" />
        <sql:param value="${fn:substring(rolRevision += ': ' += (empty observacion ? 'Sin observación' : observacion), 0, 490)}" />
      </sql:update>

      <%-- 2. Documentos de apoyo opcionales: rejilla (evaluador) y Turnitin (director) --%>
      <c:if test="${rolRevision == 'EVALUADOR' and not empty rejillaIngresada}">
        <sql:query var="verRejilla">
          SELECT IFNULL(MAX(version_num), 0) AS v FROM documento WHERE id_proyecto_fase = ? AND nombre = 'Rejilla de evaluación'
          <sql:param value="${py.id_proyecto_fase}" />
        </sql:query>
        <sql:update>
          UPDATE documento SET vigente = 0 WHERE id_proyecto_fase = ? AND nombre = 'Rejilla de evaluación'
          <sql:param value="${py.id_proyecto_fase}" />
        </sql:update>
        <sql:update>
          INSERT INTO documento (id_proyecto_fase, nombre, version_num, enlace_url, id_subido_por, vigente) VALUES (?, 'Rejilla de evaluación', ?, ?, ?, 1)
          <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${verRejilla.rows[0].v + 1}" /><sql:param value="${rejillaIngresada}" /><sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
      </c:if>
      <c:if test="${rolRevision == 'DIRECTOR' and fase == 5 and not empty turnitinIngresado}">
        <sql:query var="verTurnitin">
          SELECT IFNULL(MAX(version_num), 0) AS v FROM documento WHERE id_proyecto_fase = ? AND nombre = 'Turnitin'
          <sql:param value="${py.id_proyecto_fase}" />
        </sql:query>
        <sql:update>
          UPDATE documento SET vigente = 0 WHERE id_proyecto_fase = ? AND nombre = 'Turnitin'
          <sql:param value="${py.id_proyecto_fase}" />
        </sql:update>
        <sql:update>
          INSERT INTO documento (id_proyecto_fase, nombre, version_num, enlace_url, id_subido_por, vigente) VALUES (?, 'Turnitin', ?, ?, ?, 1)
          <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${verTurnitin.rows[0].v + 1}" /><sql:param value="${turnitinIngresado}" /><sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
      </c:if>

      <%-- 3. Resultado de la fase a partir de todas las decisiones sobre esta versión --%>
      <sql:query var="todas">
        SELECT rol_revisor, decision FROM revision WHERE id_documento = ?
        <sql:param value="${idDocumento}" />
      </sql:query>
      <c:set var="decDir" value="" /><c:set var="decEva" value="" /><c:set var="decCom" value="" />
      <c:forEach var="x" items="${todas.rows}">
        <c:if test="${x.rol_revisor == 'DIRECTOR'}"><c:set var="decDir" value="${x.decision}" /></c:if>
        <c:if test="${x.rol_revisor == 'EVALUADOR'}"><c:set var="decEva" value="${x.decision}" /></c:if>
        <c:if test="${x.rol_revisor == 'COMITE'}"><c:set var="decCom" value="${x.decision}" /></c:if>
      </c:forEach>
      <c:set var="hayRechazo" value="${decDir == 'RECHAZADO' or decEva == 'RECHAZADO' or decCom == 'RECHAZADO'}" />
      <c:set var="hayAplazo" value="${decDir == 'APLAZADO' or decEva == 'APLAZADO' or decCom == 'APLAZADO'}" />
      <c:set var="todosAprueban" value="${fase == 1 ? decCom == 'APROBADO' : ((fase == 2 or fase == 4) ? decDir == 'APROBADO' : (fase == 6 ? (decEva == 'APROBADO' and decCom == 'APROBADO') : (decDir == 'APROBADO' and decEva == 'APROBADO' and decCom == 'APROBADO')))}" />
      <c:set var="resultadoFase" value="${hayRechazo ? 'RECHAZADA' : (hayAplazo ? 'APLAZADA' : (todosAprueban ? 'APROBADA' : 'EN_CURSO'))}" />

      <c:if test="${resultadoFase != 'EN_CURSO'}">
        <sql:update>
          UPDATE proyecto_fase SET estado = ?, fecha_fin = IF(? = 'APROBADA', NOW(), NULL) WHERE id_proyecto_fase = ?
          <sql:param value="${resultadoFase}" /><sql:param value="${resultadoFase}" /><sql:param value="${py.id_proyecto_fase}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
          VALUES (?, ?, 'FASE', ?, ?, 'EN_CURSO', ?, ?)
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" /><sql:param value="${py.id_proyecto_fase}" />
          <sql:param value="${resultadoFase == 'APROBADA' ? 'APROBAR_FASE' : (resultadoFase == 'APLAZADA' ? 'APLAZAR_FASE' : 'CERRAR_PROYECTO')}" />
          <sql:param value="${resultadoFase}" /><sql:param value="${'Fase ' += fase += ': ' += nombrePrincipal}" />
        </sql:update>
      </c:if>
      <c:if test="${resultadoFase == 'RECHAZADA'}">
        <sql:update>
          UPDATE proyecto SET estado_general = 'CERRADO' WHERE id_proyecto = ?
          <sql:param value="${idProyecto}" />
        </sql:update>
      </c:if>
      <c:if test="${resultadoFase == 'APROBADA' and fase == 6}">
        <sql:update>
          UPDATE proyecto SET estado_general = 'APTO_GRADUACION' WHERE id_proyecto = ?
          <sql:param value="${idProyecto}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
          VALUES (?, ?, 'PROYECTO', ?, 'APTO_GRADUACION', 'EN_CURSO', 'APTO_GRADUACION', 'Revisión final aprobada: el proyecto queda apto para graduación')
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" /><sql:param value="${idProyecto}" />
        </sql:update>
      </c:if>

      <%-- 4. Avance a la siguiente fase (y copia del documento aprobado en las fases 3 y 5) --%>
      <c:if test="${resultadoFase == 'APROBADA' and fase < 6}">
        <sql:update>
          UPDATE proyecto_fase SET estado = 'EN_CURSO', fecha_inicio = NOW() WHERE id_proyecto = ? AND id_fase = ?
          <sql:param value="${idProyecto}" /><sql:param value="${proximaFase}" />
        </sql:update>
        <sql:update>
          UPDATE proyecto SET fase_actual = ? WHERE id_proyecto = ?
          <sql:param value="${proximaFase}" /><sql:param value="${idProyecto}" />
        </sql:update>
        <c:if test="${proximaFase == 3 or proximaFase == 5}">
          <sql:update>
            INSERT INTO documento (id_proyecto_fase, nombre, version_num, enlace_url, id_subido_por, vigente, comentario)
            SELECT pf.id_proyecto_fase, ?, 1, ?, ?, 1, 'Documento aprobado en la fase anterior, enviado por el director'
            FROM proyecto_fase pf WHERE pf.id_proyecto = ? AND pf.id_fase = ?
            <sql:param value="${nombresDocumento[proximaFase - 1]}" /><sql:param value="${doc.rows[0].enlace_url}" />
            <sql:param value="${py.id_director}" /><sql:param value="${idProyecto}" /><sql:param value="${proximaFase}" />
          </sql:update>
        </c:if>
      </c:if>

      <%-- 5. Avisos --%>
      <sql:update>
        INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
        SELECT pe.id_estudiante, ?, 'REVISION', ?
        FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta WHERE pr.id_proyecto = ?
        <sql:param value="${idProyecto}" />
        <sql:param value="${fn:substring(rolTexto += ' ' += textoDecision += ' ' += nombrePrincipal += ' (fase ' += fase += ') del proyecto ' += py.codigo += '.' += (resultadoFase == 'APROBADA' ? (fase == 6 ? ' El proyecto queda apto para graduación.' : ' La fase fue aprobada.') : (resultadoFase == 'APLAZADA' ? ' Corrige y entrega una nueva versión.' : (resultadoFase == 'RECHAZADA' ? ' El proyecto se cerró.' : ''))), 0, 250)}" />
        <sql:param value="${idProyecto}" />
      </sql:update>
      <c:if test="${rolRevision == 'DIRECTOR' and decisionBd == 'APROBADO' and resultadoFase == 'EN_CURSO' and (fase == 3 or fase == 5)}">
        <sql:update>
          INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
          SELECT u.id_usuario, ?, 'REVISION', ?
          FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
          WHERE (r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA') OR u.id_usuario = ?
          <sql:param value="${idProyecto}" />
          <sql:param value="${'El director aprobó el envío de ' += nombrePrincipal += ' del proyecto ' += py.codigo += ': pendiente tu decisión.'}" />
          <sql:param value="${empty py.id_evaluador ? 0 : py.id_evaluador}" />
        </sql:update>
      </c:if>
      <c:if test="${resultadoFase == 'APROBADA' and fase < 6 and (proximaFase == 3 or proximaFase == 5)}">
        <sql:update>
          INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje) VALUES (?, ?, 'REVISION', ?)
          <sql:param value="${py.id_director}" /><sql:param value="${idProyecto}" />
          <sql:param value="${'Fase ' += proximaFase += ' habilitada en ' += py.codigo += ': revisa y aprueba el envío al evaluador y al comité.'}" />
        </sql:update>
      </c:if>
    </sql:transaction>
  </c:catch>
  <c:if test="${not empty falloRevision}"><c:set var="errorRevision" value="No se pudo registrar la decisión. Inténtalo de nuevo." /></c:if>
</c:if>

<c:choose>
  <c:when test="${empty errorRevision}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Decisión registrada: ${decisionBd == 'APROBADO' ? 'aprobado' : (decisionBd == 'APLAZADO' ? 'aplazado' : 'rechazado')}.${resultadoFase == 'APROBADA' ? (fase == 6 ? ' El proyecto queda apto para graduación.' : ' La fase fue aprobada y avanzó a la siguiente.') : (resultadoFase == 'APLAZADA' ? ' La fase se devolvió al estudiante.' : (resultadoFase == 'RECHAZADA' ? ' El proyecto se cerró.' : ' Falta la decisión de los demás revisores.'))}" scope="session" />
    <c:redirect url="/modulos/proyectos/seguimiento.jsp"><c:param name="id" value="${idProyecto}" /></c:redirect>
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="${errorRevision}" scope="session" />
    <c:set var="vrObservacion" value="${observacion}" scope="session" />
    <c:choose>
      <c:when test="${idProyecto > 0}"><c:redirect url="/modulos/proyectos/revision_form.jsp"><c:param name="id" value="${idProyecto}" /></c:redirect></c:when>
      <c:otherwise><c:redirect url="${destinoError}" /></c:otherwise>
    </c:choose>
  </c:otherwise>
</c:choose>

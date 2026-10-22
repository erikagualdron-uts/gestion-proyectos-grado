<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE,COORDINADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%--
  Propuestas de estudiantes:
    elegir   (estudiante)  elegir una idea del banco y crear la propuesta (RF-24)
    crear    (estudiante)  propuesta propia con segundo estudiante opcional (RF-25, RF-26)
    editar   (estudiante)  pendiente: cambiar compañero; aplazada: corregir y reenviar (RF-26, RF-28)
    decidir  (coordinador) aprobar, aplazar o rechazar; al aprobar crea el proyecto con sus seis fases (RF-27)
  Cada cambio queda en el historial (RNF-13). Las operaciones sobre varias tablas usan transacción (RNF-11).
--%>
<c:set var="accion" value="${param.accion}" />
<c:set var="rolAccion" value="${accion == 'decidir' ? 'COORDINADOR' : 'ESTUDIANTE'}" />
<c:set var="tituloIngresado" value="${fn:trim(param.titulo)}" />
<c:set var="descripcionIngresada" value="${fn:trim(param.descripcion)}" />
<c:set var="objetivoIngresado" value="${fn:trim(param.objetivo)}" />
<c:set var="alcanceIngresado" value="${fn:trim(param.alcance)}" />
<c:set var="companeroIngresado" value="${fn:trim(param.companero)}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:catch var="idInvalido"><c:set var="idObj" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:set var="destino" value="${(accion == 'crear' or accion == 'editar') ? '/modulos/propuestas/propuesta_form.jsp' : (accion == 'elegir' ? '/modulos/banco_ideas/banco_ideas.jsp' : '/modulos/propuestas/propuestas_banco.jsp')}" />

<c:choose>
  <c:when test="${accion != 'elegir' and accion != 'crear' and accion != 'editar' and accion != 'decidir'}">
    <c:set var="errorPropuesta" value="Solicitud no válida." />
  </c:when>
  <c:when test="${sessionScope.rol != rolAccion}">
    <c:set var="errorPropuesta" value="Tu rol no puede realizar esta acción." />
  </c:when>
  <c:when test="${not empty idInvalido}">
    <c:set var="errorPropuesta" value="El identificador no es válido." />
  </c:when>
</c:choose>

<%-- Estudiante: propuesta activa y validación del compañero --%>
<c:if test="${empty errorPropuesta and sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="activa" dataSource="${bd}">
    SELECT p.id_propuesta, p.codigo FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO' AND p.id_propuesta <> ? LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${accion == 'editar' ? idObj : 0}" />
  </sql:query>
  <c:if test="${(accion == 'crear' or accion == 'elegir') and activa.rowCount > 0}">
    <c:set var="errorPropuesta" value="Ya participas en la propuesta ${activa.rows[0].codigo}. Solo puedes tener una propuesta activa." />
  </c:if>
</c:if>

<%-- ====================== ELEGIR IDEA DEL BANCO ====================== --%>
<c:if test="${empty errorPropuesta and accion == 'elegir'}">
  <sql:query var="idea" dataSource="${bd}">
    SELECT id_idea, codigo, id_docente, titulo, descripcion, IFNULL(objetivo, '') AS objetivo, IFNULL(alcance, '') AS alcance
    FROM idea_banco WHERE id_idea = ? AND estado_decision = 'APROBADO' AND disponible = 1
    <sql:param value="${idObj}" />
  </sql:query>
  <c:if test="${idea.rowCount != 1}">
    <c:set var="errorPropuesta" value="La idea ya no está disponible." />
  </c:if>
  <c:if test="${empty errorPropuesta}">
    <c:catch var="falloPropuesta">
      <sql:transaction dataSource="${bd}">
        <sql:update var="filas">
          UPDATE idea_banco SET disponible = 0 WHERE id_idea = ? AND disponible = 1 AND estado_decision = 'APROBADO'
          <sql:param value="${idObj}" />
        </sql:update>
        <c:if test="${filas == 1}">
          <sql:update>
            INSERT INTO propuesta (codigo, id_idea, origen, titulo, descripcion, objetivo, alcance)
            VALUES (CONCAT('T', LEFT(HEX(RANDOM_BYTES(7)), 14)), ?, 'BANCO', ?, ?, ?, ?)
            <sql:param value="${idObj}" /><sql:param value="${idea.rows[0].titulo}" /><sql:param value="${idea.rows[0].descripcion}" />
            <sql:param value="${idea.rows[0].objetivo}" /><sql:param value="${idea.rows[0].alcance}" />
          </sql:update>
          <sql:query var="nueva">SELECT LAST_INSERT_ID() AS id</sql:query>
          <sql:update>
            UPDATE propuesta SET codigo = CONCAT('PG-', LPAD(id_propuesta, 4, '0')) WHERE id_propuesta = ?
            <sql:param value="${nueva.rows[0].id}" />
          </sql:update>
          <sql:update>
            INSERT INTO propuesta_estudiante (id_propuesta, id_estudiante, es_responsable) VALUES (?, ?, 1)
            <sql:param value="${nueva.rows[0].id}" /><sql:param value="${sessionScope.usuarioId}" />
          </sql:update>
          <sql:update>
            INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_nuevo, version_num, detalle)
            VALUES (?, 'PROPUESTA', ?, 'CREAR', 'PENDIENTE', 1, ?)
            <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${nueva.rows[0].id}" />
            <sql:param value="${'Propuesta creada desde la idea ' += idea.rows[0].codigo}" />
          </sql:update>
          <sql:update>
            INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
            VALUES (?, 'IDEA', ?, 'RESERVAR', 'DISPONIBLE', 'NO_DISPONIBLE', 'Idea elegida por un estudiante')
            <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idObj}" />
          </sql:update>
          <sql:update>
            INSERT INTO notificacion (id_usuario, tipo, mensaje)
            SELECT u.id_usuario, 'PROPUESTA_NUEVA', ?
            FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
            WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
            <sql:param value="${fn:substring('Nueva propuesta por revisar: ' += idea.rows[0].titulo, 0, 250)}" />
          </sql:update>
          <sql:update>
            INSERT INTO notificacion (id_usuario, tipo, mensaje) VALUES (?, 'IDEA_ELEGIDA', ?)
            <sql:param value="${idea.rows[0].id_docente}" />
            <sql:param value="${'Un estudiante eligió tu idea ' += idea.rows[0].codigo += '.'}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPropuesta or filas != 1}"><c:set var="errorPropuesta" value="No se pudo elegir la idea (puede que otro estudiante la haya elegido antes)." /></c:if>
  </c:if>
  <c:if test="${empty errorPropuesta}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Idea elegida. Tu propuesta quedó pendiente de aprobación; aquí puedes agregar a tu compañero." scope="session" />
    <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
  </c:if>
</c:if>

<%-- ====================== CREAR / EDITAR (estudiante) ====================== --%>
<c:if test="${empty errorPropuesta and (accion == 'crear' or accion == 'editar')}">
  <c:if test="${accion == 'editar'}">
    <sql:query var="actual" dataSource="${bd}">
      SELECT p.id_propuesta, p.codigo, p.id_idea, p.titulo, p.objetivo, p.estado_decision
      FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
      WHERE p.id_propuesta = ? AND pe.id_estudiante = ? AND pe.es_responsable = 1
      <sql:param value="${idObj}" /><sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
    <c:if test="${actual.rowCount != 1 or (actual.rows[0].estado_decision != 'PENDIENTE' and actual.rows[0].estado_decision != 'APLAZADO')}">
      <c:set var="errorPropuesta" value="La propuesta no existe o ya no se puede modificar." />
    </c:if>
  </c:if>
  <c:set var="editaContenido" value="${accion == 'crear' or (accion == 'editar' and empty errorPropuesta and actual.rows[0].estado_decision == 'APLAZADO')}" />
  <%-- Una vez agregado, el compañero queda fijo: no se quita ni se cambia --%>
  <c:set var="companeroFijo" value="${false}" />
  <c:if test="${accion == 'editar' and empty errorPropuesta}">
    <sql:query var="tieneCompa" dataSource="${bd}">
      SELECT COUNT(*) AS total FROM propuesta_estudiante WHERE id_propuesta = ? AND es_responsable = 0
      <sql:param value="${idObj}" />
    </sql:query>
    <c:set var="companeroFijo" value="${tieneCompa.rows[0].total > 0}" />
  </c:if>

  <c:if test="${empty errorPropuesta and editaContenido}">
    <c:choose>
      <c:when test="${fn:length(tituloIngresado) < 5 or fn:length(tituloIngresado) > 200}">
        <c:set var="errorPropuesta" value="El título debe tener entre 5 y 200 caracteres." />
      </c:when>
      <c:when test="${empty objetivoIngresado or empty alcanceIngresado}">
        <c:set var="errorPropuesta" value="El objetivo y el alcance son obligatorios." />
      </c:when>
      <c:when test="${fn:length(descripcionIngresada) > 2000 or fn:length(objetivoIngresado) > 2000 or fn:length(alcanceIngresado) > 2000}">
        <c:set var="errorPropuesta" value="Cada campo puede tener máximo 2000 caracteres." />
      </c:when>
    </c:choose>
  </c:if>

  <%-- Segundo estudiante: debe existir, estar aprobado y activo, ser otra persona y estar libre --%>
  <c:if test="${empty errorPropuesta and not empty companeroIngresado and not companeroFijo}">
    <sql:query var="compa" dataSource="${bd}">
      SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
      WHERE u.numero_documento = ? AND r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1
      <sql:param value="${companeroIngresado}" />
    </sql:query>
    <c:choose>
      <c:when test="${compa.rowCount != 1}">
        <c:set var="errorPropuesta" value="No se encontró un estudiante con cuenta aprobada con ese número de documento." />
      </c:when>
      <c:when test="${compa.rows[0].id_usuario == sessionScope.usuarioId}">
        <c:set var="errorPropuesta" value="No puedes agregarte a ti mismo como compañero." />
      </c:when>
      <c:otherwise>
        <sql:query var="ocupado" dataSource="${bd}">
          SELECT COUNT(*) AS total FROM propuesta_estudiante pe JOIN propuesta p ON p.id_propuesta = pe.id_propuesta
          WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO' AND p.id_propuesta <> ?
          <sql:param value="${compa.rows[0].id_usuario}" /><sql:param value="${idObj}" />
        </sql:query>
        <c:if test="${ocupado.rows[0].total > 0}">
          <c:set var="errorPropuesta" value="Ese estudiante ya participa en otra propuesta activa." />
        </c:if>
      </c:otherwise>
    </c:choose>
  </c:if>

  <c:if test="${empty errorPropuesta}">
    <c:set var="descripcionFinal" value="${empty descripcionIngresada ? tituloIngresado : descripcionIngresada}" />
    <c:if test="${accion == 'editar'}">
      <sql:query var="versiones" dataSource="${bd}">
        SELECT COUNT(*) AS total FROM historial_version WHERE entidad = 'PROPUESTA' AND id_entidad = ? AND accion = 'REENVIAR'
        <sql:param value="${idObj}" />
      </sql:query>
    </c:if>
    <c:catch var="falloPropuesta">
      <sql:transaction dataSource="${bd}">
        <c:choose>
          <c:when test="${accion == 'crear'}">
            <sql:update>
              INSERT INTO propuesta (codigo, origen, titulo, descripcion, objetivo, alcance)
              VALUES (CONCAT('T', LEFT(HEX(RANDOM_BYTES(7)), 14)), 'PROPIA', ?, ?, ?, ?)
              <sql:param value="${tituloIngresado}" /><sql:param value="${descripcionFinal}" />
              <sql:param value="${objetivoIngresado}" /><sql:param value="${alcanceIngresado}" />
            </sql:update>
            <sql:query var="nueva">SELECT LAST_INSERT_ID() AS id</sql:query>
            <c:set var="idPropuesta" value="${nueva.rows[0].id}" />
            <sql:update>
              UPDATE propuesta SET codigo = CONCAT('PG-', LPAD(id_propuesta, 4, '0')) WHERE id_propuesta = ?
              <sql:param value="${idPropuesta}" />
            </sql:update>
            <sql:update>
              INSERT INTO propuesta_estudiante (id_propuesta, id_estudiante, es_responsable) VALUES (?, ?, 1)
              <sql:param value="${idPropuesta}" /><sql:param value="${sessionScope.usuarioId}" />
            </sql:update>
            <sql:update>
              INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_nuevo, version_num, detalle)
              VALUES (?, 'PROPUESTA', ?, 'CREAR', 'PENDIENTE', 1, ?)
              <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idPropuesta}" />
              <sql:param value="${fn:substring('Propuesta propia: ' += tituloIngresado, 0, 490)}" />
            </sql:update>
            <sql:update>
              INSERT INTO notificacion (id_usuario, tipo, mensaje)
              SELECT u.id_usuario, 'PROPUESTA_NUEVA', ?
              FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
              WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
              <sql:param value="${fn:substring('Nueva propuesta por revisar: ' += tituloIngresado, 0, 250)}" />
            </sql:update>
          </c:when>
          <c:otherwise>
            <c:set var="idPropuesta" value="${idObj}" />
            <c:if test="${editaContenido}">
              <sql:update>
                UPDATE propuesta SET titulo = ?, descripcion = ?, objetivo = ?, alcance = ?, estado_decision = 'PENDIENTE',
                       observacion = NULL, id_revisor = NULL, fecha_decision = NULL
                WHERE id_propuesta = ?
                <sql:param value="${tituloIngresado}" /><sql:param value="${descripcionFinal}" />
                <sql:param value="${objetivoIngresado}" /><sql:param value="${alcanceIngresado}" /><sql:param value="${idPropuesta}" />
              </sql:update>
              <sql:update>
                INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, version_num, detalle)
                VALUES (?, 'PROPUESTA', ?, 'REENVIAR', 'APLAZADO', 'PENDIENTE', ?, ?)
                <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idPropuesta}" />
                <sql:param value="${versiones.rows[0].total + 2}" />
                <sql:param value="${fn:substring('Versión anterior. Título: ' += actual.rows[0].titulo += ' | Objetivo: ' += actual.rows[0].objetivo, 0, 490)}" />
              </sql:update>
              <sql:update>
                INSERT INTO notificacion (id_usuario, tipo, mensaje)
                SELECT u.id_usuario, 'PROPUESTA_REENVIADA', ?
                FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
                WHERE r.nombre = 'COORDINADOR' AND u.activo = 1 AND u.estado_cuenta = 'APROBADA'
                <sql:param value="${'La propuesta ' += actual.rows[0].codigo += ' fue corregida y reenviada.'}" />
              </sql:update>
            </c:if>
            <c:if test="${not companeroFijo}">
              <sql:update>
                DELETE FROM propuesta_estudiante WHERE id_propuesta = ? AND es_responsable = 0
                <sql:param value="${idPropuesta}" />
              </sql:update>
            </c:if>
          </c:otherwise>
        </c:choose>
        <c:if test="${not empty companeroIngresado and not companeroFijo}">
          <sql:update>
            INSERT INTO propuesta_estudiante (id_propuesta, id_estudiante, es_responsable) VALUES (?, ?, 0)
            <sql:param value="${idPropuesta}" /><sql:param value="${compa.rows[0].id_usuario}" />
          </sql:update>
          <sql:update>
            INSERT INTO notificacion (id_usuario, tipo, mensaje) VALUES (?, 'COMPANERO_AGREGADO', ?)
            <sql:param value="${compa.rows[0].id_usuario}" />
            <sql:param value="${sessionScope.nombre += ' te agregó como compañero en una propuesta de trabajo de grado.'}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPropuesta}"><c:set var="errorPropuesta" value="No se pudo guardar la propuesta. Verifica los datos e inténtalo de nuevo." /></c:if>
  </c:if>

  <c:choose>
    <c:when test="${empty errorPropuesta}">
      <c:set var="flashTipo" value="success" scope="session" />
      <c:set var="flashMsg" value="${accion == 'crear' ? 'Propuesta enviada. Queda pendiente de aprobación del coordinador.' : (editaContenido ? 'Propuesta corregida y reenviada. Queda pendiente de aprobación.' : 'Compañero agregado.')}" scope="session" />
      <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
    </c:when>
    <c:otherwise>
      <c:set var="vpTitulo" value="${tituloIngresado}" scope="session" />
      <c:set var="vpDescripcion" value="${descripcionIngresada}" scope="session" />
      <c:set var="vpObjetivo" value="${objetivoIngresado}" scope="session" />
      <c:set var="vpAlcance" value="${alcanceIngresado}" scope="session" />
      <c:set var="vpCompanero" value="${companeroIngresado}" scope="session" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- ====================== DECIDIR (coordinador) ====================== --%>
<c:if test="${empty errorPropuesta and accion == 'decidir'}">
  <c:choose>
    <c:when test="${idObj < 1}">
      <c:set var="errorPropuesta" value="La propuesta indicada no es válida." />
    </c:when>
    <c:when test="${param.decision != 'APROBAR' and param.decision != 'APLAZAR' and param.decision != 'RECHAZAR'}">
      <c:set var="errorPropuesta" value="Decisión no válida." />
    </c:when>
    <c:when test="${param.decision != 'APROBAR' and empty observacion}">
      <c:set var="errorPropuesta" value="Para aplazar o rechazar escribe la observación." />
    </c:when>
    <c:when test="${fn:length(observacion) > 500}">
      <c:set var="errorPropuesta" value="La observación puede tener máximo 500 caracteres." />
    </c:when>
  </c:choose>
  <c:if test="${empty errorPropuesta}">
    <sql:query var="propuesta" dataSource="${bd}">
      SELECT p.id_propuesta, p.codigo, p.id_idea, p.estado_decision, i.codigo AS codigo_idea
      FROM propuesta p LEFT JOIN idea_banco i ON i.id_idea = p.id_idea WHERE p.id_propuesta = ?
      <sql:param value="${idObj}" />
    </sql:query>
    <c:if test="${propuesta.rowCount != 1 or propuesta.rows[0].estado_decision != 'PENDIENTE'}">
      <c:set var="errorPropuesta" value="La propuesta ya fue decidida o no existe." />
    </c:if>
  </c:if>
  <c:if test="${empty errorPropuesta}">
    <c:set var="nuevoEstado" value="${param.decision == 'APROBAR' ? 'APROBADO' : (param.decision == 'APLAZAR' ? 'APLAZADO' : 'RECHAZADO')}" />
    <c:set var="textoEstado" value="${param.decision == 'APROBAR' ? 'aprobada' : (param.decision == 'APLAZAR' ? 'aplazada' : 'rechazada')}" />
    <c:set var="liberaIdea" value="${param.decision == 'RECHAZAR' and not empty propuesta.rows[0].id_idea}" />
    <c:catch var="falloPropuesta">
      <sql:transaction dataSource="${bd}">
        <sql:update var="filas">
          UPDATE propuesta SET estado_decision = ?, observacion = NULLIF(?, ''), id_revisor = ?, fecha_decision = NOW()
          <c:if test="${liberaIdea}">, id_idea = NULL</c:if>
          WHERE id_propuesta = ? AND estado_decision = 'PENDIENTE'
          <sql:param value="${nuevoEstado}" /><sql:param value="${observacion}" />
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idObj}" />
        </sql:update>
        <c:if test="${filas == 1}">
          <c:if test="${liberaIdea}">
            <sql:update>
              UPDATE idea_banco SET disponible = 1 WHERE id_idea = ?
              <sql:param value="${propuesta.rows[0].id_idea}" />
            </sql:update>
          </c:if>
          <c:if test="${param.decision == 'APROBAR'}">
            <sql:update>
              INSERT INTO proyecto (id_propuesta, fase_actual, estado_general, fecha_inicio) VALUES (?, 1, 'EN_CURSO', CURDATE())
              <sql:param value="${idObj}" />
            </sql:update>
            <sql:query var="proyecto">SELECT LAST_INSERT_ID() AS id</sql:query>
            <sql:update>
              INSERT INTO proyecto_fase (id_proyecto, id_fase, estado, fecha_inicio)
              SELECT ?, f.id_fase, IF(f.numero = 1, 'EN_CURSO', 'PENDIENTE'), IF(f.numero = 1, NOW(), NULL) FROM fase f ORDER BY f.numero
              <sql:param value="${proyecto.rows[0].id}" />
            </sql:update>
            <sql:update>
              INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_nuevo, detalle)
              VALUES (?, ?, 'PROYECTO', ?, 'CREAR', 'EN_CURSO', 'Proyecto creado al aprobar la propuesta (Fase 1: Pago)')
              <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${proyecto.rows[0].id}" /><sql:param value="${proyecto.rows[0].id}" />
            </sql:update>
          </c:if>
          <sql:update>
            INSERT INTO historial_version (id_usuario, id_proyecto, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
            VALUES (?, ?, 'PROPUESTA', ?, 'DECIDIR', 'PENDIENTE', ?, ?)
            <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${param.decision == 'APROBAR' ? proyecto.rows[0].id : null}" />
            <sql:param value="${idObj}" /><sql:param value="${nuevoEstado}" />
            <sql:param value="${empty observacion ? 'Sin observación' : fn:substring(observacion, 0, 490)}" />
          </sql:update>
          <sql:update>
            INSERT INTO notificacion (id_usuario, id_proyecto, tipo, mensaje)
            SELECT pe.id_estudiante, ?, 'PROPUESTA_DECISION', ?
            FROM propuesta_estudiante pe WHERE pe.id_propuesta = ?
            <sql:param value="${param.decision == 'APROBAR' ? proyecto.rows[0].id : null}" />
            <sql:param value="${'Tu propuesta ' += propuesta.rows[0].codigo += ' fue ' += textoEstado += '.' += (param.decision == 'APROBAR' ? ' Ya puedes iniciar la Fase 1 (Pago).' : '')}" />
            <sql:param value="${idObj}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPropuesta or filas != 1}"><c:set var="errorPropuesta" value="No se pudo registrar la decisión. Inténtalo de nuevo." /></c:if>
  </c:if>
  <c:if test="${empty errorPropuesta}">
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="Propuesta ${propuesta.rows[0].codigo} ${textoEstado}.${param.decision == 'APROBAR' ? ' Se creó el proyecto en la Fase 1.' : ''}" scope="session" />
    <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
  </c:if>
</c:if>

<c:set var="flashTipo" value="danger" scope="session" />
<c:set var="flashMsg" value="${errorPropuesta}" scope="session" />
<c:choose>
  <c:when test="${accion == 'editar' and idObj > 0}">
    <c:redirect url="/modulos/propuestas/propuesta_form.jsp"><c:param name="id" value="${idObj}" /></c:redirect>
  </c:when>
  <c:otherwise><c:redirect url="${destino}" /></c:otherwise>
</c:choose>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/fases.jsp" %>
<%-- Seguimiento del proyecto (RF-38 a RF-48): seis tarjetas de fase (verdes las superadas y la actual, grises las pendientes),
     detalle de la fase con sus documentos y versiones, revisiones y, según el rol, entrega o calificación. --%>
<c:set var="titulo" value="Seguimiento del proyecto" scope="request" />
<c:set var="menuActivo" value="${sessionScope.rol == 'ESTUDIANTE' ? '/modulos/propuestas/propuestas_banco.jsp' : (sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : (sessionScope.rol == 'DOCENTE' ? '/modulos/docente_director/docente_director.jsp' : '/modulos/propuestas/propuestas_banco.jsp'))}" scope="request" />
<c:set var="volverA" value="${sessionScope.rol == 'ESTUDIANTE' ? '/inicio.jsp' : (sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : (sessionScope.rol == 'DOCENTE' ? '/modulos/docente_director/docente_director.jsp' : '/modulos/propuestas/propuestas_banco.jsp'))}" scope="request" />

<c:catch var="idInvalido"><c:set var="idProyecto" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:if test="${not empty idInvalido}"><c:set var="idProyecto" value="${0}" /></c:if>

<%-- El estudiante entra sin id: se abre su propio proyecto --%>
<c:if test="${idProyecto < 1 and sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="propio" dataSource="${bd}">
    SELECT pr.id_proyecto FROM propuesta_estudiante pe JOIN proyecto pr ON pr.id_propuesta = pe.id_propuesta
    WHERE pe.id_estudiante = ? ORDER BY pr.id_proyecto DESC LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:if test="${propio.rowCount == 1}"><c:set var="idProyecto" value="${propio.rows[0].id_proyecto}" /></c:if>
</c:if>

<sql:query var="consulta" dataSource="${bd}">
  SELECT pr.id_proyecto, pr.fase_actual, pr.estado_general, pr.id_director, pr.id_evaluador, p.codigo, p.titulo,
         p.descripcion, p.objetivo, p.alcance, DATE_FORMAT(pr.fecha_inicio, '%d/%m/%Y') AS inicio_texto,
         (SELECT DATE_FORMAT(MAX(h.fecha_evento), '%d/%m/%Y %H:%i') FROM historial_version h WHERE h.id_proyecto = pr.id_proyecto) AS ultimo_movimiento,
         d.nombre_completo AS director, ev.nombre_completo AS evaluador, d.correo AS director_correo, ev.correo AS evaluador_correo,
         (SELECT GROUP_CONCAT(CONCAT(e.nombre_completo, IF(pe.es_responsable = 1, ' (responsable)', ' (compañero)')) ORDER BY pe.es_responsable DESC SEPARATOR ', ')
          FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS integrantes,
         (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
          FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes,
         (SELECT pe.id_estudiante FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.es_responsable = 1 LIMIT 1) AS id_responsable,
         (SELECT IF(e.activo = 1, 'SI', 'NO') FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante
          WHERE pe.id_propuesta = p.id_propuesta AND pe.es_responsable = 1 LIMIT 1) AS responsable_activo,
         (SELECT COUNT(*) FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.id_estudiante = ?) AS es_miembro
  FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  LEFT JOIN usuario d ON d.id_usuario = pr.id_director LEFT JOIN usuario ev ON ev.id_usuario = pr.id_evaluador
  WHERE pr.id_proyecto = ?
  <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idProyecto}" />
</sql:query>

<c:if test="${consulta.rowCount != 1}">
  <c:set var="flashTipo" value="warning" scope="session" />
  <c:set var="flashMsg" value="${sessionScope.rol == 'ESTUDIANTE' ? 'Aún no tienes un proyecto. Se crea cuando el coordinador aprueba tu propuesta.' : 'El proyecto indicado no existe.'}" scope="session" />
  <c:redirect url="${sessionScope.rol == 'ESTUDIANTE' ? '/modulos/propuestas/propuestas_banco.jsp' : volverA}" />
</c:if>
<c:set var="py" value="${consulta.rows[0]}" />
<c:set var="permitido" value="${sessionScope.rol == 'COORDINADOR' or (sessionScope.rol == 'ESTUDIANTE' and py.es_miembro > 0) or (sessionScope.rol == 'DOCENTE' and (py.id_director == sessionScope.usuarioId or py.id_evaluador == sessionScope.usuarioId))}" />
<c:if test="${not permitido}"><c:redirect url="/acceso_denegado.jsp" /></c:if>

<c:set var="soyResponsable" value="${sessionScope.rol == 'ESTUDIANTE' and py.id_responsable == sessionScope.usuarioId}" />
<c:set var="soyDirector" value="${sessionScope.rol == 'DOCENTE' and py.id_director == sessionScope.usuarioId}" />
<c:set var="soyEvaluador" value="${sessionScope.rol == 'DOCENTE' and py.id_evaluador == sessionScope.usuarioId}" />

<%-- Fase que se está mirando --%>
<c:catch var="faseInvalida"><c:set var="faseSel" value="${empty param.fase ? py.fase_actual : param.fase + 0}" /></c:catch>
<c:if test="${not empty faseInvalida or faseSel < 1 or faseSel > 6}"><c:set var="faseSel" value="${py.fase_actual}" /></c:if>

<sql:query var="fases" dataSource="${bd}">
  SELECT pf.id_proyecto_fase, pf.id_fase, f.numero, f.nombre, pf.estado,
         DATE_FORMAT(pf.fecha_inicio, '%d/%m/%Y') AS inicio, DATE_FORMAT(pf.fecha_fin, '%d/%m/%Y') AS fin
  FROM proyecto_fase pf JOIN fase f ON f.id_fase = pf.id_fase WHERE pf.id_proyecto = ? ORDER BY f.numero
  <sql:param value="${idProyecto}" />
</sql:query>
<c:forEach var="f" items="${fases.rows}">
  <c:if test="${f.numero == faseSel}"><c:set var="pf" value="${f}" /></c:if>
</c:forEach>

<sql:query var="documentos" dataSource="${bd}">
  SELECT d.id_documento, d.nombre, d.version_num, d.enlace_url, IF(d.vigente = 1, 'SI', 'NO') AS vigente_txt, d.comentario,
         u.nombre_completo AS subido, DATE_FORMAT(d.fecha_subida, '%d/%m/%Y %H:%i') AS fecha,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = d.id_documento AND r.decision = 'RECHAZADO') AS n_rech,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = d.id_documento AND r.decision = 'APLAZADO') AS n_apl,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = d.id_documento AND r.rol_revisor = 'DIRECTOR' AND r.decision = 'APROBADO') AS dir_ok,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = d.id_documento AND r.rol_revisor = 'EVALUADOR' AND r.decision = 'APROBADO') AS eva_ok,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = d.id_documento AND r.rol_revisor = 'COMITE' AND r.decision = 'APROBADO') AS com_ok
  FROM documento d JOIN usuario u ON u.id_usuario = d.id_subido_por
  WHERE d.id_proyecto_fase = ?
  ORDER BY d.nombre, d.version_num DESC
  <sql:param value="${pf.id_proyecto_fase}" />
</sql:query>

<sql:query var="revisiones" dataSource="${bd}">
  SELECT r.rol_revisor, r.decision, r.observaciones, u.nombre_completo AS revisor, d.nombre AS documento, d.version_num,
         IF(d.vigente = 1, 'SI', 'NO') AS vigente_txt, DATE_FORMAT(r.fecha_revision, '%d/%m/%Y %H:%i') AS fecha
  FROM revision r JOIN usuario u ON u.id_usuario = r.id_revisor LEFT JOIN documento d ON d.id_documento = r.id_documento
  WHERE r.id_proyecto_fase = ? ORDER BY r.fecha_revision, r.id_revision
  <sql:param value="${pf.id_proyecto_fase}" />
</sql:query>

<%-- Documento principal vigente de la fase mostrada --%>
<c:set var="nombrePrincipal" value="${nombresDocumento[faseSel - 1]}" />
<c:forEach var="d" items="${documentos.rows}">
  <c:if test="${d.nombre == nombrePrincipal and d.vigente_txt == 'SI' and empty docVigente}"><c:set var="docVigente" value="${d}" /></c:if>
</c:forEach>

<%-- Última observación que devolvió o rechazó la versión vigente --%>
<c:forEach var="r" items="${revisiones.rows}">
  <c:if test="${(r.decision == 'APLAZADO' or r.decision == 'RECHAZADO') and r.vigente_txt == 'SI'}"><c:set var="ultimaObservacion" value="${r}" /></c:if>
</c:forEach>

<c:set var="primerDocRevision" value="" /><c:set var="variosDocsRevision" value="${false}" />
<c:forEach var="r" items="${revisiones.rows}">
  <c:choose>
    <c:when test="${empty primerDocRevision}"><c:set var="primerDocRevision" value="${r.documento}" /></c:when>
    <c:when test="${r.documento != primerDocRevision}"><c:set var="variosDocsRevision" value="${true}" /></c:when>
  </c:choose>
</c:forEach>
<c:set var="fasesAprobadas" value="${0}" />
<c:forEach var="f" items="${fases.rows}"><c:if test="${f.estado == 'APROBADA'}"><c:set var="fasesAprobadas" value="${fasesAprobadas + 1}" /></c:if></c:forEach>
<%-- Nombre de la fase actual (para el detalle del proyecto) --%>
<c:forEach var="f" items="${fases.rows}"><c:if test="${f.numero == py.fase_actual}"><c:set var="nombreFaseActual" value="${f.nombre}" /></c:if></c:forEach>

<c:set var="esFaseActual" value="${faseSel == py.fase_actual and py.estado_general == 'EN_CURSO'}" />
<c:set var="faseEnCurso" value="${pf.estado == 'EN_CURSO'}" />
<c:set var="faseAplazada" value="${pf.estado == 'APLAZADA'}" />

<%-- ¿Puede el responsable entregar una versión ahora? --%>
<c:set var="puedeEntregar" value="${false}" />
<c:set var="motivoEntrega" value="" />
<c:if test="${soyResponsable and esFaseActual}">
  <c:choose>
    <c:when test="${py.responsable_activo != 'SI'}"><c:set var="motivoEntrega" value="El responsable del proyecto está inactivo; mientras tanto el proyecto no recibe documentos." /></c:when>
    <c:when test="${(faseSel == 2 or faseSel == 4 or faseSel == 3 or faseSel == 5) and empty py.id_director}"><c:set var="motivoEntrega" value="El coordinador aún no ha asignado un director a tu proyecto." /></c:when>
    <c:when test="${faseAplazada}"><c:set var="puedeEntregar" value="${true}" /></c:when>
    <c:when test="${faseEnCurso and (faseSel == 1 or faseSel == 2 or faseSel == 4) and empty docVigente}"><c:set var="puedeEntregar" value="${true}" /></c:when>
    <c:when test="${faseEnCurso}"><c:set var="motivoEntrega" value="Tu documento está en revisión. Cuando haya una decisión lo verás aquí." /></c:when>
  </c:choose>
</c:if>

<%-- ¿Puede este usuario calificar la fase? (director, evaluador o comité según la fase) --%>
<c:set var="puedeCalificar" value="${esFaseActual and faseEnCurso and not empty docVigente and (
    (sessionScope.rol == 'COORDINADOR' and (faseSel == 1 or faseSel == 3 or faseSel == 5)) or
    (soyDirector and faseSel != 1 and faseSel != 6) or
    (soyEvaluador and (faseSel == 3 or faseSel == 5)))}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Seguimiento del proyecto</h1>
    <p class="descripcion-pagina mb-3"><strong><c:out value="${py.codigo}" /></strong> · <c:out value="${py.titulo}" /><c:if test="${py.estado_general != 'APTO_GRADUACION'}"><br><span class="small">Verde: fase superada o actual. Gris: fase pendiente.</span></c:if></p>
  </div>
  <div class="d-flex flex-wrap gap-2 mb-3">
    <button type="button" class="btn btn-outline-uts btn-sm" data-bs-toggle="modal" data-bs-target="#modalProyecto"><i class="bi bi-info-circle me-1"></i>Detalles del proyecto</button>
  </div>
</div>

<c:choose>
  <c:when test="${py.estado_general == 'CERRADO'}"><div class="alert alert-danger" role="alert"><i class="bi bi-x-octagon me-1"></i><strong>Proyecto cerrado.</strong> El proceso se cerró por una decisión de rechazo.</div></c:when>
</c:choose>

<div class="tabla-envoltorio mb-4">
  <div class="linea-fases">
    <c:forEach var="f" items="${fases.rows}">
      <c:set var="claseFase" value="${f.estado == 'APROBADA' ? 'superada' : (f.estado == 'RECHAZADA' ? 'rechazada' : ((f.numero == py.fase_actual and (f.estado == 'EN_CURSO' or f.estado == 'APLAZADA')) ? 'actual' : 'pendiente'))}" />
      <a class="fase-col ${claseFase} ${f.numero == faseSel ? 'elegida' : ''}" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${idProyecto}&fase=${f.numero}" aria-label="Fase ${f.numero}: ${fn:escapeXml(f.nombre)}">
        <div class="fase-arriba"><span class="fase-circulo"><c:choose><c:when test="${claseFase == 'superada'}"><i class="bi bi-check-lg"></i></c:when><c:when test="${claseFase == 'rechazada'}"><i class="bi bi-x-lg"></i></c:when><c:otherwise><c:out value="${f.numero}" /></c:otherwise></c:choose></span></div>
        <div class="fase-tarjeta">
          <small><c:out value="${claseFase == 'superada' ? (f.numero == 6 ? 'Listo para sustentación' : 'Aprobada') : (claseFase == 'actual' ? 'Fase actual' : (claseFase == 'rechazada' ? 'Rechazada' : 'Pendiente'))}" /></small>
          <strong><c:out value="${f.nombre}" /></strong>
        </div>
      </a>
    </c:forEach>
  </div>
</div>

<div class="tabla-envoltorio mb-4">
  <div class="panel-detalle-cabecera">
    <h2>Detalles · Fase <c:out value="${faseSel}" /> <c:out value="${pf.nombre}" /></h2>
    <c:choose>
      <c:when test="${pf.estado == 'APROBADA'}"><span class="insignia insignia-aprobado">Aprobada<c:if test="${not empty pf.fin}"> el <c:out value="${pf.fin}" /></c:if></span></c:when>
      <c:when test="${pf.estado == 'APLAZADA'}"><span class="insignia insignia-aplazado">Aplazada · pendiente de corrección</span></c:when>
      <c:when test="${pf.estado == 'RECHAZADA'}"><span class="insignia insignia-rechazado">Rechazada</span></c:when>
      <c:when test="${pf.estado == 'EN_CURSO'}"><span class="insignia insignia-pendiente">En curso</span></c:when>
      <c:otherwise><span class="insignia insignia-pendiente">Pendiente</span></c:otherwise>
    </c:choose>
  </div>

  <c:choose>
    <c:when test="${pf.estado == 'PENDIENTE'}">
      <div class="p-4"><div class="vacio"><span class="icono-circulo"><i class="bi bi-hourglass-split"></i></span><h3>Fase aún no habilitada</h3><p>Se habilita cuando se apruebe la fase anterior.</p></div></div>
    </c:when>
    <c:otherwise>
      <%-- Observación completa cuando la fase fue aplazada o rechazada --%>
      <c:if test="${(pf.estado == 'APLAZADA' or pf.estado == 'RECHAZADA') and not empty ultimaObservacion}">
        <div class="mx-4 mb-3 alert ${pf.estado == 'APLAZADA' ? 'alert-warning' : 'alert-danger'}" role="alert">
          <div class="fw-bold mb-1"><i class="bi bi-chat-left-text me-1"></i>Observación del <c:out value="${ultimaObservacion.rol_revisor == 'DIRECTOR' ? 'director' : (ultimaObservacion.rol_revisor == 'EVALUADOR' ? 'evaluador' : 'comité')}" /> (<c:out value="${ultimaObservacion.revisor}" />) <span class="fw-normal">· <c:out value="${ultimaObservacion.fecha}" /></span></div>
          <div style="white-space: pre-line"><c:out value="${ultimaObservacion.observaciones}" /></div>
          <c:choose>
            <c:when test="${pf.estado == 'APLAZADA' and soyResponsable and esFaseActual}"><div class="mt-2">Corrige el documento y envía una nueva versión con el formulario de abajo.</div></c:when>
            <c:when test="${pf.estado == 'APLAZADA' and esFaseActual}"><div class="mt-2"><i class="bi bi-hourglass-split me-1"></i>Esperando que <strong><c:out value="${fn:substringBefore(py.estudiantes, ',')}" /></strong> envíe una nueva versión.</div></c:when>
          </c:choose>
          <c:if test="${pf.estado == 'APLAZADA' and esFaseActual}"><div class="small mt-1">Con la nueva versión, quienes deben decidir vuelven a revisar.</div></c:if>
        </div>
      </c:if>
      <%-- Quién falta por decidir --%>
      <c:set var="faltan" value="" />
      <c:if test="${esFaseActual and faseEnCurso and not empty docVigente}">
        <c:if test="${faseSel == 1 and docVigente.com_ok == 0}"><c:set var="faltan" value="el coordinador" /></c:if>
        <c:if test="${(faseSel == 2 or faseSel == 4) and docVigente.dir_ok == 0}"><c:set var="faltan" value="el director" /></c:if>
        <c:if test="${faseSel == 3 or faseSel == 5}">
          <c:if test="${docVigente.dir_ok == 0}"><c:set var="faltan" value="${faltan += (empty faltan ? 'el director' : ', el director')}" /></c:if>
          <c:if test="${docVigente.eva_ok == 0}"><c:set var="faltan" value="${faltan += (empty faltan ? 'el evaluador' : ', el evaluador')}" /></c:if>
          <c:if test="${docVigente.com_ok == 0}"><c:set var="faltan" value="${faltan += (empty faltan ? 'el comité' : ', el comité')}" /></c:if>
        </c:if>
      </c:if>
      <c:if test="${not empty faltan}">
        <div class="px-4 pb-3 texto-sec"><i class="bi bi-hourglass-split me-1"></i>Falta la decisión de: <strong><c:out value="${faltan}" /></strong>.</div>
      </c:if>

      <c:choose>
        <c:when test="${faseSel == 6}">
          <div class="px-4 pb-4">
            <div class="d-flex align-items-start gap-3 mb-3">
              <span class="icono-circulo flex-shrink-0" style="width:48px;height:48px;border-radius:50%;background:var(--verde-claro);color:var(--verde-esmeralda);display:inline-flex;align-items:center;justify-content:center;font-size:1.3rem"><i class="bi bi-mortarboard"></i></span>
              <div>
                <h3 class="fs-6 fw-bold mb-1">Listo para sustentación</h3>
                <p class="texto-sec mb-0">Se aprobaron todas las fases. En esta fase no se entregan documentos: <c:out value="${sessionScope.rol == 'ESTUDIANTE' ? 'ya puedes preparar la sustentación de tu trabajo de grado.' : 'el estudiante ya puede preparar la sustentación de su trabajo de grado.'}" /></p>
              </div>
            </div>
            <div class="row g-3">
              <div class="col-md-6">
                <div class="dato-etiqueta">Director</div><div class="dato-valor"><c:out value="${empty py.director ? 'Sin asignar' : py.director}" /></div>
                <div class="dato-etiqueta">Evaluador</div><div class="dato-valor"><c:out value="${empty py.evaluador ? 'Sin asignar' : py.evaluador}" /></div>
              </div>
              <div class="col-md-6">
                <div class="dato-etiqueta">Fases aprobadas</div>
                <ul class="list-unstyled mb-0">
                  <c:forEach var="f" items="${fases.rows}">
                    <c:if test="${f.estado == 'APROBADA'}"><li class="py-1"><i class="bi bi-check-circle-fill me-2" style="color: var(--verde-esmeralda)"></i>Fase <c:out value="${f.numero}" /> · <c:out value="${f.nombre}" /><c:if test="${not empty f.fin}"> <span class="texto-sec">· <c:out value="${f.fin}" /></span></c:if></li></c:if>
                  </c:forEach>
                </ul>
              </div>
            </div>
          </div>
        </c:when>
        <c:when test="${documentos.rowCount == 0 and soyResponsable and esFaseActual and puedeEntregar}"><%-- el formulario de abajo hace de llamada a la acción --%></c:when>
        <c:when test="${documentos.rowCount == 0}">
          <div class="px-4 pb-4"><div class="vacio"><span class="icono-circulo"><i class="bi bi-file-earmark"></i></span><c:choose><c:when test="${pf.estado == 'APROBADA'}"><h3>Fase aprobada sin documentos registrados</h3><p>El proyecto avanzó a la siguiente fase; esta fase no tiene documentos asociados.</p></c:when><c:otherwise><h3>Aún no hay documentos</h3><p><c:out value="${soyResponsable and esFaseActual ? 'Entrega tu documento con el formulario de abajo y aparecerá aquí con su enlace.' : 'Cuando se entregue el primero, aparecerá aquí con su enlace.'}" /></p></c:otherwise></c:choose></div></div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table tabla-uts">
              <thead><tr><th>Documento</th><th>Versión</th><th>Estado</th><th>Subido por</th><th>Enlace</th></tr></thead>
              <tbody>
                <c:forEach var="d" items="${documentos.rows}">
                  <c:set var="esApoyo" value="${d.nombre == 'Rejilla de evaluación' or d.nombre == 'Turnitin'}" />
                  <c:set var="completo" value="${faseSel == 1 ? d.com_ok > 0 : ((faseSel == 2 or faseSel == 4) ? d.dir_ok > 0 : (d.dir_ok > 0 and d.eva_ok > 0 and d.com_ok > 0))}" />
                  <c:set var="estadoDoc" value="${d.n_rech > 0 ? 'Rechazado' : (d.n_apl > 0 ? 'Aplazado' : (completo ? 'Aprobado' : 'Pendiente'))}" />
                  <tr class="${d.vigente_txt == 'SI' ? '' : 'doc-anterior'}">
                    <td><div class="fw-semibold"><c:out value="${d.nombre}" /></div><c:if test="${not empty d.comentario}"><div class="texto-sec"><c:out value="${fn:startsWith(d.comentario, 'Documento aprobado en la fase anterior') ? 'Aprobado en la fase anterior' : d.comentario}" /></div></c:if></td>
                    <td>v<c:out value="${d.version_num}" /> <c:choose><c:when test="${d.vigente_txt == 'SI'}"><span class="texto-sec">· vigente</span></c:when><c:otherwise><span class="texto-sec">· anterior</span></c:otherwise></c:choose></td>
                    <td>
                      <c:choose>
                        <c:when test="${esApoyo}"><span class="texto-sec">Adjunto del <c:out value="${d.nombre == 'Turnitin' ? 'director' : 'evaluador'}" /></span></c:when>
                        <c:otherwise><span class="insignia insignia-${estadoDoc == 'Aprobado' ? 'aprobado' : (estadoDoc == 'Aplazado' ? 'aplazado' : (estadoDoc == 'Rechazado' ? 'rechazado' : 'pendiente'))}"><c:out value="${estadoDoc}" /></span></c:otherwise>
                      </c:choose>
                    </td>
                    <td><div><c:out value="${d.subido}" /></div><div class="texto-sec"><c:out value="${d.fecha}" /></div></td>
                    <td><a class="fw-semibold" href="<c:out value='${d.enlace_url}' />" target="_blank" rel="noopener noreferrer">Abrir enlace <i class="bi bi-box-arrow-up-right"></i></a></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>

      <c:if test="${revisiones.rowCount > 0}">
        <div class="px-4 pt-4"><h3 class="h6 titulo" style="color: var(--verde-bosque)">Revisiones</h3></div>
        <div class="table-responsive pb-2">
          <table class="table tabla-uts">
            <thead><tr><th>Revisor</th><th>Decisión</th><th>Observaciones</th><th><c:out value="${variosDocsRevision ? 'Documento' : 'Versión'}" /></th><th>Fecha</th></tr></thead>
            <tbody>
              <c:forEach var="r" items="${revisiones.rows}">
                <tr>
                  <td><div class="fw-semibold"><c:out value="${r.revisor}" /></div><div class="texto-sec"><c:out value="${r.rol_revisor == 'DIRECTOR' ? 'Director' : (r.rol_revisor == 'EVALUADOR' ? 'Evaluador' : 'Comité')}" /></div></td>
                  <td><span class="insignia insignia-${r.decision == 'APROBADO' ? 'aprobado' : (r.decision == 'APLAZADO' ? 'aplazado' : 'rechazado')}"><c:out value="${r.decision == 'APROBADO' ? 'Aprobado' : (r.decision == 'APLAZADO' ? 'Aplazado' : 'Rechazado')}" /></span></td>
                  <td style="min-width: 220px; white-space: pre-line"><c:choose><c:when test="${empty r.observaciones}"><span class="texto-sec">Sin observaciones</span></c:when><c:otherwise><c:out value="${r.observaciones}" /></c:otherwise></c:choose></td>
                  <td><c:if test="${variosDocsRevision}"><c:out value="${r.documento}" /> </c:if>v<c:out value="${r.version_num}" /></td>
                  <td><c:out value="${r.fecha}" /></td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </c:if>

      <%-- Entrega del responsable --%>
      <c:if test="${soyResponsable and esFaseActual}">
        <div class="panel-entrega">
          <c:choose>
            <c:when test="${puedeEntregar}">
              <form method="post" action="${ctx}/proceso/entrega_proc.jsp" class="needs-validation" novalidate>
                <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
                <input type="hidden" name="id" value="${idProyecto}">
                <h3 class="h6 fw-bold mb-3" style="color: var(--verde-bosque)"><i class="bi bi-upload me-1"></i><c:out value="${faseAplazada ? 'Envía una nueva versión: ' : 'Entrega: '}" /><c:out value="${nombrePrincipal}" /></h3>
                <label for="enlace" class="form-label">Enlace al documento</label>
                <div class="row g-2">
                  <div class="col-12 col-lg">
                    <input type="url" class="form-control" id="enlace" name="enlace" maxlength="500" placeholder="https://drive.google.com/..." required>
                    <div class="invalid-feedback">Ingresa un enlace que empiece por http:// o https://.</div>
                  </div>
                  <div class="col-12 col-lg-4">
                    <input type="text" class="form-control" name="comentario" maxlength="300" placeholder="${faseAplazada ? '¿Qué cambió? (opcional)' : 'Comentario (opcional)'}">
                  </div>
                  <div class="col-12 col-lg-auto">
                    <button type="submit" class="btn btn-uts w-100"><c:out value="${faseSel == 1 ? 'Enviar al coordinador' : 'Enviar al director'}" /></button>
                  </div>
                </div>
                <div class="form-text">Los documentos se entregan solo como enlace (Drive, OneDrive, etc.). Comprueba que cualquier persona con el enlace pueda abrirlo.</div>
                <div class="form-text"><i class="bi bi-arrow-right-circle me-1"></i><c:out value="${faseSel == 1 ? 'El coordinador validará tu pago y avanzarás a la Fase 2.' : 'El director revisará tu documento y te avisaremos con su decisión.'}" /></div>
              </form>
            </c:when>
            <c:when test="${not empty motivoEntrega}"><div class="texto-sec"><i class="bi bi-info-circle me-1"></i><c:out value="${motivoEntrega}" /></div></c:when>
          </c:choose>
        </div>
      </c:if>
      <c:if test="${sessionScope.rol == 'ESTUDIANTE' and not soyResponsable and esFaseActual}">
        <div class="panel-entrega"><div class="texto-sec"><i class="bi bi-eye me-1"></i>Eres compañero en este proyecto: puedes ver el seguimiento, pero solo el responsable (<strong><c:out value="${fn:substringBefore(py.estudiantes, ',')}" /></strong>) entrega los documentos.</div></div>
      </c:if>

      <%-- Calificación --%>
      <c:if test="${puedeCalificar}">
        <div class="panel-entrega d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div class="texto-sec"><i class="bi bi-clipboard-check me-1"></i>Hay un documento por revisar en esta fase.</div>
          <a class="btn btn-uts" href="${ctx}/modulos/proyectos/revision_form.jsp?id=${idProyecto}"><i class="bi bi-pencil-square me-1"></i>Calificar documento</a>
        </div>
      </c:if>
    </c:otherwise>
  </c:choose>
</div>

<div class="modal fade" id="modalProyecto" tabindex="-1" aria-labelledby="tituloProyecto" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloProyecto">Detalles del proyecto</h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="fw-bold titulo" style="color: var(--verde-bosque)"><c:out value="${py.codigo}" /> · <c:out value="${py.titulo}" /></div>
        <div class="d-flex flex-wrap align-items-center gap-2 mt-2 mb-3">
          <span class="insignia insignia-${py.estado_general == 'EN_CURSO' ? 'pendiente' : (py.estado_general == 'CERRADO' ? 'rechazado' : 'aprobado')}"><c:out value="${py.estado_general == 'EN_CURSO' ? 'En curso' : (py.estado_general == 'APTO_GRADUACION' ? 'Listo para sustentación' : 'Cerrado')}" /></span>
          <span class="texto-sec small"><c:out value="${fasesAprobadas}" /> de 6 fases aprobadas · Fase <c:out value="${py.fase_actual}" /> · <c:out value="${nombreFaseActual}" /></span>
        </div>
        <div class="progreso-fases mb-3" role="img" aria-label="${fasesAprobadas} de 6 fases aprobadas">
          <c:forEach var="f" items="${fases.rows}"><span class="paso ${f.estado == 'APROBADA' ? 'hecho' : (f.estado == 'PENDIENTE' ? '' : 'actual')}"></span></c:forEach>
        </div>

        <c:choose>
          <c:when test="${soyResponsable}"><div class="alert alert-info py-2 small"><i class="bi bi-person-check me-1"></i>Eres el <strong>responsable</strong>: solo tú entregas los documentos.</div></c:when>
          <c:when test="${sessionScope.rol == 'ESTUDIANTE'}"><div class="alert alert-info py-2 small"><i class="bi bi-eye me-1"></i>Eres <strong>compañero</strong>: puedes ver el proyecto, pero solo el responsable entrega los documentos.</div></c:when>
          <c:when test="${soyDirector}"><div class="alert alert-info py-2 small"><i class="bi bi-person-check me-1"></i>Eres el <strong>director</strong> de este proyecto.</div></c:when>
          <c:when test="${soyEvaluador}"><div class="alert alert-info py-2 small"><i class="bi bi-clipboard-check me-1"></i>Eres el <strong>evaluador</strong> de este proyecto.</div></c:when>
        </c:choose>

        <div class="dato-etiqueta">Estudiantes</div><div class="dato-valor"><c:out value="${fn:contains(py.integrantes, ',') ? py.integrantes : py.estudiantes}" /></div>
        <div class="row">
          <div class="col-sm-6">
            <div class="dato-etiqueta">Director</div>
            <div class="dato-valor"><c:out value="${empty py.director ? 'Sin asignar' : py.director}" /><c:if test="${not empty py.director_correo}"><div class="texto-sec small fw-normal"><a href="mailto:${fn:escapeXml(py.director_correo)}"><c:out value="${py.director_correo}" /></a></div></c:if></div>
          </div>
          <div class="col-sm-6">
            <div class="dato-etiqueta">Evaluador</div>
            <div class="dato-valor"><c:out value="${empty py.evaluador ? 'Sin asignar' : py.evaluador}" /><c:if test="${not empty py.evaluador_correo}"><div class="texto-sec small fw-normal"><a href="mailto:${fn:escapeXml(py.evaluador_correo)}"><c:out value="${py.evaluador_correo}" /></a></div></c:if></div>
          </div>
          <div class="col-sm-6"><div class="dato-etiqueta">Fecha de inicio</div><div class="dato-valor"><c:out value="${py.inicio_texto}" /></div></div>
          <div class="col-sm-6"><div class="dato-etiqueta">Último movimiento</div><div class="dato-valor"><c:out value="${empty py.ultimo_movimiento ? '—' : py.ultimo_movimiento}" /></div></div>
        </div>

        <details class="mt-1">
          <summary class="fw-semibold" style="color: var(--verde-esmeralda); cursor: pointer">Ver descripción, objetivo y alcance</summary>
          <div class="mt-3">
            <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line"><c:out value="${empty py.descripcion ? '—' : py.descripcion}" /></div>
            <div class="dato-etiqueta">Objetivo</div><div class="dato-valor" style="white-space: pre-line"><c:out value="${empty py.objetivo ? '—' : py.objetivo}" /></div>
            <div class="dato-etiqueta">Alcance</div><div class="dato-valor" style="white-space: pre-line"><c:out value="${empty py.alcance ? '—' : py.alcance}" /></div>
          </div>
        </details>
      </div>
      <div class="modal-footer border-0 pt-0">
        <button type="button" class="btn btn-uts" data-bs-dismiss="modal">Cerrar</button>
      </div>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

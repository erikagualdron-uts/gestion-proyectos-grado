<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="DOCENTE,COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/fases.jsp" %>
<%-- Calificar el documento de la fase actual (RF-52): crear, editar y consultar la revisión con observaciones.
     Aprobado avanza (o habilita al evaluador y al comité), aplazado lo devuelve al estudiante, rechazado cierra el proceso. --%>
<c:set var="titulo" value="Calificar documento" scope="request" />
<c:set var="menuActivo" value="${sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : '/modulos/docente_director/docente_director.jsp'}" scope="request" />

<c:catch var="idInvalido"><c:set var="idProyecto" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:if test="${not empty idInvalido}"><c:set var="idProyecto" value="${0}" /></c:if>
<sql:query var="consulta" dataSource="${bd}">
  SELECT pr.id_proyecto, pr.fase_actual, pr.estado_general, pr.id_director, pr.id_evaluador, p.codigo, p.titulo,
         (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
          FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes,
         pf.id_proyecto_fase, pf.estado AS estado_fase, f.nombre AS fase
  FROM proyecto pr JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  JOIN proyecto_fase pf ON pf.id_proyecto = pr.id_proyecto AND pf.id_fase = pr.fase_actual
  JOIN fase f ON f.id_fase = pr.fase_actual
  WHERE pr.id_proyecto = ?
  <sql:param value="${idProyecto}" />
</sql:query>
<c:set var="destinoLista" value="${sessionScope.rol == 'COORDINADOR' ? '/modulos/proyectos/asignacion.jsp' : '/modulos/docente_director/docente_director.jsp'}" />
<c:set var="volverA" value="${destinoLista}" scope="request" />
<c:if test="${consulta.rowCount != 1}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="El proyecto indicado no existe." scope="session" />
  <c:redirect url="${destinoLista}" />
</c:if>
<c:set var="py" value="${consulta.rows[0]}" />
<c:set var="fase" value="${py.fase_actual}" />

<%-- Rol con el que revisa este usuario en este proyecto --%>
<c:choose>
  <c:when test="${sessionScope.rol == 'COORDINADOR'}"><c:set var="rolRevision" value="COMITE" /></c:when>
  <c:when test="${py.id_director == sessionScope.usuarioId}"><c:set var="rolRevision" value="DIRECTOR" /></c:when>
  <c:when test="${py.id_evaluador == sessionScope.usuarioId}"><c:set var="rolRevision" value="EVALUADOR" /></c:when>
  <c:otherwise><c:redirect url="/acceso_denegado.jsp" /></c:otherwise>
</c:choose>
<c:set var="rolTexto" value="${rolRevision == 'COMITE' ? 'Comité (coordinador)' : (rolRevision == 'DIRECTOR' ? 'Director' : 'Evaluador')}" />

<c:set var="nombrePrincipal" value="${nombresDocumento[fase - 1]}" />
<sql:query var="documentos" dataSource="${bd}">
  SELECT d.id_documento, d.nombre, d.version_num, d.enlace_url, d.comentario, IF(d.vigente = 1, 'SI', 'NO') AS vigente_txt, u.nombre_completo AS subido,
         DATE_FORMAT(d.fecha_subida, '%d/%m/%Y %H:%i') AS fecha
  FROM documento d JOIN usuario u ON u.id_usuario = d.id_subido_por
  WHERE d.id_proyecto_fase = ? AND d.vigente = 1 ORDER BY d.nombre
  <sql:param value="${py.id_proyecto_fase}" />
</sql:query>
<c:forEach var="d" items="${documentos.rows}">
  <c:if test="${d.nombre == nombrePrincipal and empty docVigente}"><c:set var="docVigente" value="${d}" /></c:if>
</c:forEach>

<c:set var="esCopia" value="${not empty docVigente and fn:startsWith(docVigente.comentario, 'Documento aprobado en la fase anterior')}" />
<c:if test="${not empty docVigente}">
  <sql:query var="revisiones" dataSource="${bd}">
    SELECT r.rol_revisor, r.decision, r.observaciones, u.nombre_completo AS revisor, DATE_FORMAT(r.fecha_revision, '%d/%m/%Y %H:%i') AS fecha
    FROM revision r JOIN usuario u ON u.id_usuario = r.id_revisor WHERE r.id_documento = ? ORDER BY r.fecha_revision, r.id_revision
    <sql:param value="${docVigente.id_documento}" />
  </sql:query>
  <c:forEach var="r" items="${revisiones.rows}">
    <c:if test="${r.rol_revisor == rolRevision}"><c:set var="miRevision" value="${r}" /></c:if>
    <c:if test="${r.rol_revisor == 'DIRECTOR' and r.decision == 'APROBADO'}"><c:set var="directorAprobo" value="${true}" /></c:if>
    <c:if test="${r.rol_revisor != 'DIRECTOR'}"><c:set var="otrosDecidieron" value="${true}" /></c:if>
    <c:if test="${r.rol_revisor == 'DIRECTOR'}"><c:set var="decDir" value="${r.decision}" /></c:if>
    <c:if test="${r.rol_revisor == 'EVALUADOR'}"><c:set var="decEva" value="${r.decision}" /></c:if>
    <c:if test="${r.rol_revisor == 'COMITE'}"><c:set var="decCom" value="${r.decision}" /></c:if>
  </c:forEach>
</c:if>

<%-- Fases 3 y 5: el evaluador debe adjuntar su rejilla diligenciada para aprobar (F-DC-124 en la fase 3, F-DC-129 en la 5), salvo que ya la haya adjuntado para esta versión --%>
<c:if test="${rolRevision == 'EVALUADOR' and (fase == 3 or fase == 5) and not empty docVigente}">
  <sql:query var="rejillaRonda" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM documento
    WHERE id_proyecto_fase = ? AND nombre = 'Rejilla de evaluación'
      AND fecha_subida >= (SELECT fecha_subida FROM documento WHERE id_documento = ?)
    <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${docVigente.id_documento}" />
  </sql:query>
  <c:set var="rejillaObligatoria" value="${rejillaRonda.rows[0].total == 0}" />
</c:if>

<%-- Fase 5: el director adjunta el informe de similitud (Turnitin) como evidencia en cualquier decisión, una vez por versión --%>
<c:if test="${rolRevision == 'DIRECTOR' and fase == 5 and not empty docVigente}">
  <sql:query var="turnitinRonda" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM documento
    WHERE id_proyecto_fase = ? AND nombre = 'Turnitin'
      AND fecha_subida >= (SELECT fecha_subida FROM documento WHERE id_documento = ?)
    <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${docVigente.id_documento}" />
  </sql:query>
  <c:set var="turnitinObligatorio" value="${turnitinRonda.rows[0].total == 0}" />
</c:if>

<%-- Observaciones que recibieron las versiones anteriores del documento (para comprobar que se corrigieron) --%>
<sql:query var="anteriores" dataSource="${bd}">
  SELECT r.rol_revisor, r.decision, r.observaciones, d.version_num, u.nombre_completo AS revisor, DATE_FORMAT(r.fecha_revision, '%d/%m/%Y %H:%i') AS fecha
  FROM revision r JOIN documento d ON d.id_documento = r.id_documento JOIN usuario u ON u.id_usuario = r.id_revisor
  WHERE d.id_proyecto_fase = ? AND d.nombre = ? AND d.vigente = 0 AND r.decision <> 'APROBADO' AND r.observaciones IS NOT NULL
  ORDER BY r.fecha_revision DESC, r.id_revision DESC
  <sql:param value="${py.id_proyecto_fase}" /><sql:param value="${nombrePrincipal}" />
</sql:query>

<%-- ¿Le toca revisar en esta fase? --%>
<c:set var="faseCorresponde" value="${rolRevision == 'COMITE' ? (fase == 1 or fase == 3 or fase == 5) : (rolRevision == 'DIRECTOR' ? (fase == 2 or fase == 3 or fase == 4 or fase == 5) : (fase == 3 or fase == 5))}" />
<c:set var="esperaDirector" value="${rolRevision != 'DIRECTOR' and (fase == 3 or fase == 5) and empty directorAprobo}" />
<c:choose>
  <c:when test="${py.estado_general != 'EN_CURSO'}"><c:set var="motivo" value="El proyecto ya no está en curso." /></c:when>
  <c:when test="${not faseCorresponde}"><c:set var="motivo" value="En la fase ${fase} (${py.fase}) no te corresponde revisar con el rol de ${rolTexto}." /></c:when>
  <c:when test="${py.estado_fase != 'EN_CURSO'}"><c:set var="motivo" value="La fase no está esperando una revisión (estado: ${py.estado_fase == 'APLAZADA' ? 'aplazada, esperando una nueva versión del estudiante' : py.estado_fase})." /></c:when>
  <c:when test="${empty docVigente}"><c:set var="motivo" value="Aún no hay un documento entregado en esta fase." /></c:when>
  <c:when test="${esperaDirector}"><c:set var="motivo" value="Primero el director debe aprobar el envío del documento al evaluador y al comité." /></c:when>
  <c:when test="${rolRevision == 'DIRECTOR' and (fase == 3 or fase == 5) and otrosDecidieron}"><c:set var="motivo" value="El evaluador o el comité ya decidieron sobre esta versión, así que tu decisión quedó cerrada. Puedes consultarla en la tabla de revisiones." /></c:when>
</c:choose>
<c:set var="puedeRevisar" value="${empty motivo}" />
<c:set var="etiquetaAprobar" value="${(rolRevision == 'DIRECTOR' and (fase == 3 or fase == 5)) ? 'Aprobar envío' : 'Aprobar'}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina"><c:out value="${fase == 1 ? 'Validar pago' : 'Calificar documento'}" /></h1>
<p class="descripcion-pagina">Proyecto <strong><c:out value="${py.codigo}" /></strong> · Fase <c:out value="${fase}" /> (<c:out value="${py.fase}" />) · <c:choose><c:when test="${fase == 1}">Validas el pago como <strong>coordinador</strong>.</c:when><c:otherwise>Revisas como <strong><c:out value="${rolTexto}" /></strong>.</c:otherwise></c:choose></p>

<div class="row g-4">
  <div class="col-12 col-xl-7">
    <div class="tarjeta mb-4">
      <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
        <span class="insignia insignia-aprobado">Fase <c:out value="${fase}" /> · <c:out value="${py.fase}" /></span>
        <span class="insignia insignia-${py.estado_fase == 'EN_CURSO' ? 'pendiente' : (py.estado_fase == 'APLAZADA' ? 'aplazado' : 'aprobado')}"><c:out value="${py.estado_fase == 'EN_CURSO' ? 'En revisión' : (py.estado_fase == 'APLAZADA' ? 'Aplazada' : 'Cerrada')}" /></span>
      </div>
      <c:if test="${not empty docVigente}">
        <c:set var="rolesFase" value="${fase == 1 ? 'COMITE' : ((fase == 2 or fase == 4) ? 'DIRECTOR' : 'DIRECTOR,EVALUADOR,COMITE')}" />
        <div class="dato-etiqueta">Revisión de esta versión</div>
        <div class="d-flex flex-wrap gap-2 mb-3">
          <c:forEach var="rr" items="${fn:split(rolesFase, ',')}">
            <c:set var="decRol" value="${rr == 'DIRECTOR' ? decDir : (rr == 'EVALUADOR' ? decEva : decCom)}" />
            <span class="insignia insignia-${decRol == 'APROBADO' ? 'aprobado' : (decRol == 'APLAZADO' ? 'aplazado' : (decRol == 'RECHAZADO' ? 'rechazado' : 'pendiente'))}">
              <c:out value="${rr == 'DIRECTOR' ? 'Director' : (rr == 'EVALUADOR' ? 'Evaluador' : 'Comité')}" />:
              <c:out value="${decRol == 'APROBADO' ? 'aprobó' : (decRol == 'APLAZADO' ? 'aplazó' : (decRol == 'RECHAZADO' ? 'rechazó' : 'pendiente'))}" />
            </span>
          </c:forEach>
        </div>
      </c:if>
      <div class="dato-etiqueta">Proyecto</div><div class="dato-valor"><c:out value="${py.titulo}" /></div>
      <div class="dato-etiqueta">Estudiantes</div><div class="dato-valor"><c:out value="${py.estudiantes}" /></div>
      <c:choose>
        <c:when test="${not empty docVigente}">
          <div class="dato-etiqueta">Documento por revisar</div>
          <div class="dato-valor">
            <c:choose>
              <c:when test="${esCopia}"><c:out value="${docVigente.nombre}" /> · v<c:out value="${docVigente.version_num}" /> · versión aprobada en la Fase <c:out value="${fase - 1}" /> y enviada por el director (<c:out value="${docVigente.fecha}" />)</c:when>
              <c:otherwise><c:out value="${docVigente.nombre}" /> · v<c:out value="${docVigente.version_num}" /> · entregó <c:out value="${docVigente.subido}" /> (<c:out value="${docVigente.fecha}" />)</c:otherwise>
            </c:choose>
          </div>
          <c:if test="${not empty docVigente.comentario and not esCopia}">
            <div class="dato-etiqueta">Comentario de la entrega</div>
            <div class="dato-valor" style="white-space: pre-line"><c:out value="${docVigente.comentario}" /></div>
          </c:if>
          <div class="d-flex flex-wrap gap-2">
            <c:forEach var="d" items="${documentos.rows}">
              <a class="btn ${d.id_documento == docVigente.id_documento ? 'btn-uts' : 'btn-outline-uts'} btn-sm" href="<c:out value='${d.enlace_url}' />" target="_blank" rel="noopener noreferrer"><i class="bi bi-box-arrow-up-right me-1"></i><c:choose><c:when test="${d.id_documento == docVigente.id_documento}">Abrir documento</c:when><c:otherwise>Abrir <c:out value="${d.nombre}" /></c:otherwise></c:choose></a>
            </c:forEach>
          </div>
        </c:when>
        <c:otherwise><div class="texto-sec">No hay documento en esta fase todavía.</div></c:otherwise>
      </c:choose>
    </div>

    <c:if test="${anteriores.rowCount > 0}">
      <div class="alert alert-warning" role="alert">
        <div class="fw-bold mb-2"><i class="bi bi-clock-history me-1"></i>Observaciones de versiones anteriores</div>
        <c:forEach var="a" items="${anteriores.rows}">
          <div class="mb-2"><span class="fw-semibold"><c:out value="${a.rol_revisor == 'DIRECTOR' ? 'Director' : (a.rol_revisor == 'EVALUADOR' ? 'Evaluador' : 'Comité')}" /> sobre la v<c:out value="${a.version_num}" /></span>
            (<c:out value="${a.decision == 'APLAZADO' ? 'aplazado' : 'rechazado'}" />, <c:out value="${a.fecha}" />):
            <span style="white-space: pre-line"><c:out value="${a.observaciones}" /></span></div>
        </c:forEach>
        <div class="small">Comprueba que la nueva versión corrige lo anterior.</div>
      </div>
    </c:if>

    <c:if test="${not empty docVigente and revisiones.rowCount > 0}">
      <div class="tabla-envoltorio table-responsive">
        <table class="table tabla-uts">
          <thead><tr><th>Revisor</th><th>Decisión</th><th>Observaciones</th><th>Fecha</th></tr></thead>
          <tbody>
            <c:forEach var="r" items="${revisiones.rows}">
              <tr>
                <td><div class="fw-semibold"><c:out value="${r.revisor}" /></div><div class="texto-sec"><c:out value="${r.rol_revisor == 'DIRECTOR' ? 'Director' : (r.rol_revisor == 'EVALUADOR' ? 'Evaluador' : 'Comité')}" /></div></td>
                <td><span class="insignia insignia-${r.decision == 'APROBADO' ? 'aprobado' : (r.decision == 'APLAZADO' ? 'aplazado' : 'rechazado')}"><c:out value="${r.decision == 'APROBADO' ? 'Aprobado' : (r.decision == 'APLAZADO' ? 'Aplazado' : 'Rechazado')}" /></span></td>
                <td style="white-space: pre-line"><c:choose><c:when test="${empty r.observaciones}"><span class="texto-sec">Sin observaciones</span></c:when><c:otherwise><c:out value="${r.observaciones}" /></c:otherwise></c:choose></td>
                <td><c:out value="${r.fecha}" /></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </c:if>
  </div>

  <div class="col-12 col-xl-5">
    <div class="tarjeta">
      <c:choose>
        <c:when test="${puedeRevisar}">
          <h2 class="h5 titulo mb-3" style="color: var(--verde-bosque)"><c:out value="${empty miRevision ? 'Registrar mi decisión' : 'Editar mi decisión'}" /></h2>
          <form method="post" action="${ctx}/proceso/revision_proc.jsp" data-decisiones data-mensaje-rechazo="¿Rechazar y cerrar el proyecto ${fn:escapeXml(py.codigo)}? Los estudiantes no podrán continuar. Esta decisión es extrema y queda registrada." novalidate>
            <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
            <input type="hidden" name="id" value="${idProyecto}">
            <input type="hidden" name="documento" value="${docVigente.id_documento}">
            <c:if test="${rolRevision == 'EVALUADOR' and (fase == 3 or fase == 5)}">
              <div class="mb-3">
                <label for="rejilla" class="form-label">Rejilla de evaluación diligenciada (formato <c:out value="${fase == 3 ? 'F-DC-124, sección Rejilla de evaluación' : 'F-DC-129'}" />)
                  <span class="texto-sec"><c:out value="${rejillaObligatoria ? '(enlace, obligatorio para aprobar)' : '(ya adjuntada para esta versión)'}" /></span></label>
                <c:choose>
                  <c:when test="${rejillaObligatoria}">
                    <input type="url" class="form-control" id="rejilla" name="rejilla" maxlength="500" placeholder="https://..." data-obligatoria-aprobar>
                    <div class="form-text">Pega el enlace a tu copia diligenciada, con tus marcas <c:out value="${fase == 3 ? 'SI/NO' : 'SI/NO/N/A'}" />, el concepto final y la firma.</div>
                    <div class="invalid-feedback">Para aprobar adjunta el enlace de la rejilla diligenciada (http:// o https://).</div>
                  </c:when>
                  <c:otherwise><div class="form-text"><i class="bi bi-check-circle me-1"></i>Ya quedó adjunta para esta versión; puedes abrirla en el botón de documentos.</div></c:otherwise>
                </c:choose>
              </div>
            </c:if>
            <c:if test="${rolRevision == 'DIRECTOR' and fase == 5}">
              <div class="mb-3">
                <label for="turnitin" class="form-label">Informe de similitud (Turnitin)
                  <span class="texto-sec"><c:out value="${turnitinObligatorio ? '(enlace, obligatorio en cualquier decisión)' : '(ya adjuntado para esta versión)'}" /></span></label>
                <c:choose>
                  <c:when test="${turnitinObligatorio}">
                    <input type="url" class="form-control" id="turnitin" name="turnitin" maxlength="500" placeholder="https://..." required>
                    <div class="form-text">Es la evidencia del reporte de la herramienta antiplagio institucional para esta versión del informe.</div>
                    <div class="invalid-feedback">Adjunta el enlace del informe de similitud (http:// o https://).</div>
                  </c:when>
                  <c:otherwise><div class="form-text"><i class="bi bi-check-circle me-1"></i>Ya quedó adjunto para esta versión; puedes abrirlo con el botón "Abrir Turnitin".</div></c:otherwise>
                </c:choose>
              </div>
            </c:if>
            <div class="mb-3">
              <label for="observacion" class="form-label">Observaciones <span class="texto-sec">(obligatorias para aplazar o rechazar)</span></label>
              <textarea class="form-control" id="observacion" name="observacion" rows="5" maxlength="2000" placeholder="${fase == 1 ? 'Ej.: El comprobante no se ve completo.' : 'Escribe tus observaciones'}"><c:out value="${not empty sessionScope.vrObservacion ? sessionScope.vrObservacion : miRevision.observaciones}" /></textarea>
              <div class="invalid-feedback">Escribe las observaciones.</div>
            </div>
            <c:if test="${not empty miRevision}"><div class="alert alert-info small" role="alert">Ya registraste una decisión (<strong><c:out value="${miRevision.decision == 'APROBADO' ? 'aprobado' : (miRevision.decision == 'APLAZADO' ? 'aplazado' : 'rechazado')}" /></strong>). Puedes cambiarla <c:out value="${(rolRevision == 'DIRECTOR' and (fase == 3 or fase == 5)) ? 'hasta que el evaluador o el comité decidan' : 'mientras la fase siga en revisión'}" />; al guardar de nuevo se reemplaza.</div></c:if>
            <div class="d-flex flex-wrap gap-2 justify-content-end">
              <button type="submit" name="decision" value="RECHAZAR" class="btn btn-rechazar"><i class="bi bi-x-circle me-1"></i>Rechazar</button>
              <button type="submit" name="decision" value="APLAZAR" class="btn btn-aplazar"><i class="bi bi-pause-circle me-1"></i>Aplazar</button>
              <button type="submit" name="decision" value="APROBAR" class="btn btn-uts"><i class="bi bi-check-circle me-1"></i><c:out value="${etiquetaAprobar}" /></button>
            </div>
            <ul class="small texto-sec mt-3 mb-0 ps-3">
              <c:set var="faltanOtros" value="" />
              <c:if test="${fase == 3 or fase == 5}">
                <c:if test="${rolRevision != 'DIRECTOR' and decDir != 'APROBADO'}"><c:set var="faltanOtros" value="${faltanOtros += (empty faltanOtros ? 'el director' : ', el director')}" /></c:if>
                <c:if test="${rolRevision != 'EVALUADOR' and decEva != 'APROBADO'}"><c:set var="faltanOtros" value="${faltanOtros += (empty faltanOtros ? 'el evaluador' : ', el evaluador')}" /></c:if>
                <c:if test="${rolRevision != 'COMITE' and decCom != 'APROBADO'}"><c:set var="faltanOtros" value="${faltanOtros += (empty faltanOtros ? 'el comité' : ', el comité')}" /></c:if>
              </c:if>
              <li><strong><c:out value="${etiquetaAprobar}" />:</strong> <c:choose>
                <c:when test="${etiquetaAprobar == 'Aprobar envío'}">envía el documento a revisión del evaluador y del comité.</c:when>
                <c:when test="${fase == 1}">valida el pago y el proyecto pasa a la Fase 2.</c:when>
                <c:when test="${(fase == 3 or fase == 5) and not empty faltanOtros}">registra tu aprobación. Aún falta la decisión de: <c:out value="${faltanOtros}" />.</c:when>
                <c:when test="${fase == 5}">registra tu aprobación; con ella la fase queda aprobada y el proyecto queda listo para sustentación.</c:when>
                <c:when test="${fase == 3}">registra tu aprobación; con ella la fase queda aprobada.</c:when>
                <c:otherwise>aprueba la fase y el proyecto avanza.</c:otherwise>
              </c:choose></li>
              <li><strong>Aplazar:</strong> el estudiante corrige y envía una nueva versión (la observación es obligatoria).</li>
              <li><strong>Rechazar:</strong> cierra el proyecto. Es un caso extremo y pide confirmación.</li>
            </ul>
          </form>
        </c:when>
        <c:otherwise>
          <div class="vacio"><span class="icono-circulo"><i class="bi bi-info-circle"></i></span><h3>No puedes calificar ahora</h3><p><c:out value="${motivo}" /></p></div>
        </c:otherwise>
      </c:choose>
      <div class="mt-3"><a class="btn btn-outline-uts btn-sm" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${idProyecto}"><i class="bi bi-list-check me-1"></i>Ver seguimiento</a></div>
    </div>
  </div>
</div>
<c:remove var="vrObservacion" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE,COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- PQRS (RF-53 a RF-56): el estudiante responsable radica; el coordinador resuelve; el administrador consulta.
     El compañero de una propuesta ve las PQRS del proyecto pero no radica. --%>
<c:set var="titulo" value="PQRS" scope="request" />
<c:set var="esCoordinador" value="${sessionScope.rol == 'COORDINADOR'}" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="filtroTipo" value="${fn:contains(',PRORROGA,CAMBIO_DIRECTOR,PETICION,QUEJA,RECLAMO,SUGERENCIA,', ',' += param.tipo += ',') ? param.tipo : ''}" />
<c:set var="filtroEstado" value="${fn:contains(',PENDIENTE,APROBADO,RECHAZADO,', ',' += param.estado += ',') ? param.estado : ''}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<c:set var="desdePqrs">
  FROM pqrs q
  JOIN usuario s ON s.id_usuario = q.id_solicitante
  LEFT JOIN proyecto pr ON pr.id_proyecto = q.id_proyecto
  LEFT JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  LEFT JOIN usuario rv ON rv.id_usuario = q.id_resuelto_por
  LEFT JOIN usuario nd ON nd.id_usuario = q.id_nuevo_director
  WHERE (? <> 'ESTUDIANTE' OR q.id_solicitante = ?
         OR EXISTS (SELECT 1 FROM propuesta_estudiante pe WHERE pe.id_propuesta = p.id_propuesta AND pe.id_estudiante = ?))
</c:set>
<c:set var="filtrosPqrs">
    AND (? = '' OR q.codigo LIKE ? OR q.asunto LIKE ? OR s.nombre_completo LIKE ?)
    AND (? = '' OR q.tipo = ?) AND (? = '' OR q.estado = ?)
</c:set>

<sql:query var="resumen" dataSource="${bd}">
  SELECT SUM(q.estado = 'PENDIENTE') AS pendientes, SUM(q.estado = 'APROBADO') AS aprobadas,
         SUM(q.estado = 'RECHAZADO') AS rechazadas
  ${desdePqrs}
  <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
</sql:query>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total ${desdePqrs} ${filtrosPqrs}
  <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroTipo}" /><sql:param value="${filtroTipo}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="solicitudes" dataSource="${bd}">
  SELECT pr.id_director, pr.id_evaluador, q.id_pqrs, q.codigo, q.tipo, q.asunto, q.descripcion, q.enlace_soporte, q.estado, q.respuesta, q.id_proyecto,
         s.nombre_completo AS solicitante, p.codigo AS codigo_proyecto, rv.nombre_completo AS resuelto_por, nd.nombre_completo AS nuevo_director,
         DATE_FORMAT(q.fecha_creacion, '%d/%m/%Y %H:%i') AS fecha, DATE_FORMAT(q.fecha_resolucion, '%d/%m/%Y %H:%i') AS fecha_resolucion
  ${desdePqrs} ${filtrosPqrs}
  ORDER BY q.fecha_creacion DESC, q.id_pqrs DESC
  LIMIT ? OFFSET ?
  <sql:param value="${sessionScope.rol}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroTipo}" /><sql:param value="${filtroTipo}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<%-- Estudiante: ¿puede radicar? El compañero (no responsable) solo consulta --%>
<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="membresia" dataSource="${bd}">
    SELECT SUM(pe.es_responsable = 1) AS como_responsable, COUNT(*) AS total
    FROM propuesta_estudiante pe JOIN propuesta p ON p.id_propuesta = pe.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO'
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:set var="soloCompanero" value="${membresia.rows[0].total > 0 and membresia.rows[0].como_responsable == 0}" />
</c:if>

<%-- Coordinador: docentes activos para el cambio de director --%>
<c:if test="${esCoordinador}">
  <sql:query var="docentes" dataSource="${bd}">
    SELECT u.id_usuario, u.nombre_completo FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1 ORDER BY u.nombre_completo
  </sql:query>
</c:if>

<c:url var="pagBase" value="/modulos/pqrs/pqrs.jsp"><c:param name="q" value="${q}" /><c:param name="tipo" value="${filtroTipo}" /><c:param name="estado" value="${filtroEstado}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />
<c:set var="tiposTexto" value="PRORROGA=Prórroga;CAMBIO_DIRECTOR=Cambio de director;PETICION=Petición;QUEJA=Queja;RECLAMO=Reclamo;SUGERENCIA=Sugerencia" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">PQRS</h1>
    <p class="descripcion-pagina mb-3">
      <c:choose>
        <c:when test="${esCoordinador}">Resuelve las solicitudes (aprobar o rechazar con respuesta): prórrogas, cambios de director, peticiones, quejas, reclamos y sugerencias.</c:when>
        <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">Consulta el estado y la respuesta de tus solicitudes, o radica una nueva.</c:when>
        <c:otherwise>Consulta las solicitudes radicadas y su estado.</c:otherwise>
      </c:choose>
    </p>
  </div>
  <c:if test="${sessionScope.rol == 'ESTUDIANTE' and not soloCompanero}">
    <a class="btn btn-uts mb-3" href="${ctx}/modulos/pqrs/pqrs_form.jsp"><i class="bi bi-plus-lg me-1"></i>Radicar PQRS</a>
  </c:if>
</div>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and soloCompanero}">
  <div class="alert alert-warning" role="alert"><i class="bi bi-eye me-1"></i>Eres compañero en tu propuesta: puedes consultar las PQRS del proyecto, pero solo el responsable las radica.</div>
</c:if>

<c:if test="${sessionScope.rol != 'ESTUDIANTE'}">
<div class="row g-3 mb-4">
  <div class="col-12 col-md-4"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-clock"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].pendientes}" default="0" /></div><div class="resumen-etiqueta">Pendientes</div></div></div></div>
  <div class="col-6 col-md-4"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-check-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].aprobadas}" default="0" /></div><div class="resumen-etiqueta">Aprobadas</div></div></div></div>
  <div class="col-6 col-md-4"><div class="tarjeta resumen"><span class="resumen-icono rechazado"><i class="bi bi-x-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].rechazadas}" default="0" /></div><div class="resumen-etiqueta">Rechazadas</div></div></div></div>
</div>
</c:if>

<form method="get" action="${ctx}/modulos/pqrs/pqrs.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="${sessionScope.rol == 'ESTUDIANTE' ? 'Código o asunto' : 'Código, asunto o solicitante'}" maxlength="120">
  </div>
  <div class="col-6 col-md-auto">
    <label for="tipo" class="form-label">Tipo</label>
    <select class="form-select" id="tipo" name="tipo" data-autoenviar>
      <option value="">Todos</option>
      <c:forEach var="t" items="${fn:split(tiposTexto, ';')}"><c:set var="tp" value="${fn:split(t, '=')}" /><option value="${tp[0]}" ${filtroTipo == tp[0] ? 'selected' : ''}>${tp[1]}</option></c:forEach>
    </select>
  </div>
  <div class="col-6 col-md-auto">
    <label for="estado" class="form-label">Estado</label>
    <select class="form-select" id="estado" name="estado" data-autoenviar>
      <option value="">Todos</option>
      <option value="PENDIENTE" ${filtroEstado == 'PENDIENTE' ? 'selected' : ''}>Pendiente</option>
      <option value="APROBADO" ${filtroEstado == 'APROBADO' ? 'selected' : ''}>Aprobada</option>
      <option value="RECHAZADO" ${filtroEstado == 'RECHAZADO' ? 'selected' : ''}>Rechazada</option>
    </select>
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${solicitudes.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-chat"></i></span>
      <c:choose>
        <c:when test="${empty q and empty filtroTipo and empty filtroEstado}">
          <h3>Aún no hay PQRS radicadas</h3>
          <p><c:out value="${sessionScope.rol == 'ESTUDIANTE' ? 'Cuando radiques una solicitud aparecerá aquí con su estado y respuesta.' : (esCoordinador ? 'Cuando un estudiante radique una solicitud, aparecerá aquí para que la resuelvas.' : 'Cuando se radique una solicitud, aparecerá aquí.')}" /></p>
        </c:when>
        <c:otherwise>
          <h3>No hay PQRS que coincidan</h3>
          <p>Cambia la búsqueda o los filtros.</p>
        </c:otherwise>
      </c:choose>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>Código</th><th>Asunto</th><c:choose><c:when test="${sessionScope.rol == 'ESTUDIANTE'}"><th>Tipo</th><th>Fecha</th></c:when><c:otherwise><th>Solicitante</th></c:otherwise></c:choose><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="s" items="${solicitudes.rows}">
            <c:set var="tipoTexto" value="${s.tipo == 'PRORROGA' ? 'Prórroga' : (s.tipo == 'CAMBIO_DIRECTOR' ? 'Cambio de director' : (s.tipo == 'PETICION' ? 'Petición' : (s.tipo == 'QUEJA' ? 'Queja' : (s.tipo == 'RECLAMO' ? 'Reclamo' : 'Sugerencia'))))}" />
            <c:set var="estadoTexto" value="${s.estado == 'APROBADO' ? 'Aprobada' : (s.estado == 'APLAZADO' ? 'Aplazada' : (s.estado == 'RECHAZADO' ? 'Rechazada' : 'Pendiente'))}" />
            <tr>
              <td class="fw-bold"><c:out value="${s.codigo}" /></td>
              <c:choose>
                <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">
                  <td style="min-width: 220px"><div><c:out value="${s.asunto}" /></div><c:if test="${not empty s.codigo_proyecto}"><div class="texto-sec"><c:out value="${s.codigo_proyecto}" /></div></c:if></td>
                  <td><c:out value="${tipoTexto}" /></td>
                  <td style="white-space: nowrap"><c:out value="${s.fecha}" /></td>
                </c:when>
                <c:otherwise>
                  <td style="min-width: 240px"><div><c:out value="${s.asunto}" /></div><div class="texto-sec"><c:out value="${tipoTexto}" /><c:if test="${not empty s.codigo_proyecto}"> · <c:out value="${s.codigo_proyecto}" /></c:if></div></td>
                  <td><div><c:out value="${s.solicitante}" /></div><div class="texto-sec"><c:out value="${s.fecha}" /></div></td>
                </c:otherwise>
              </c:choose>
              <td><span class="insignia insignia-${s.estado == 'APROBADO' ? 'aprobado' : (s.estado == 'APLAZADO' ? 'aplazado' : (s.estado == 'RECHAZADO' ? 'rechazado' : 'pendiente'))}"><c:out value="${estadoTexto}" /></span>
                <c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
                  <div class="texto-sec small mt-1"><c:choose>
                    <c:when test="${s.estado == 'PENDIENTE'}">Sin respuesta aún</c:when>
                    <c:otherwise>Respondida el <c:out value="${fn:substring(s.fecha_resolucion, 0, 10)}" /><c:if test="${not empty s.respuesta}"> · con observación</c:if></c:otherwise>
                  </c:choose></div>
                </c:if>
              </td>
              <td class="acciones">
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalPqrs" aria-label="Visualizar ${fn:escapeXml(s.codigo)}"
                        data-codigo="${fn:escapeXml(s.codigo)}" data-tipo-texto="${tipoTexto}" data-asunto="${fn:escapeXml(s.asunto)}" data-descripcion="${fn:escapeXml(s.descripcion)}"
                        data-solicitante="${fn:escapeXml(s.solicitante)}" data-proyecto="${fn:escapeXml(s.codigo_proyecto)}" data-estado="${estadoTexto}" data-fecha="${s.fecha}"
                        data-respuesta="${fn:escapeXml(s.respuesta)}" data-resuelto="${fn:escapeXml(s.resuelto_por)}" data-fecha-resolucion="${s.fecha_resolucion}"
                        data-soporte="${fn:escapeXml(s.enlace_soporte)}" data-nuevo-director="${fn:escapeXml(s.nuevo_director)}"><i class="bi bi-eye"></i></button>
                <c:if test="${esCoordinador}">
                  <button type="button" class="btn btn-outline-uts btn-icono" ${s.estado == 'PENDIENTE' ? '' : 'disabled'} data-bs-toggle="modal" data-bs-target="#modalResolver" aria-label="Gestionar ${fn:escapeXml(s.codigo)}"
                          data-id="${s.id_pqrs}" data-tipo="${s.tipo}" data-codigo="${fn:escapeXml(s.codigo)}" data-tipo-texto="${tipoTexto}" data-asunto="${fn:escapeXml(s.asunto)}"
                          data-descripcion="${fn:escapeXml(s.descripcion)}" data-solicitante="${fn:escapeXml(s.solicitante)}" data-soporte="${fn:escapeXml(s.enlace_soporte)}" data-director-actual="${s.id_director}" data-evaluador-actual="${s.id_evaluador}"><i class="bi bi-pencil"></i></button>
                </c:if>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <c:if test="${totalRegistros > 5}"><jsp:include page="/WEB-INF/includes/paginacion.jsp" /></c:if>
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalPqrs" tabindex="-1" aria-labelledby="tituloPqrs" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloPqrs"><span data-llenar="codigo"></span> · <span data-llenar="tipoTexto"></span></h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="dato-etiqueta">Asunto</div><div class="dato-valor" data-llenar="asunto"></div>
        <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line" data-llenar="descripcion"></div>
        <div class="row">
          <div class="col-sm-4"><div class="dato-etiqueta">Solicitante</div><div class="dato-valor" data-llenar="solicitante"></div></div>
          <div class="col-sm-4"><div class="dato-etiqueta">Proyecto</div><div class="dato-valor" data-llenar="proyecto"></div></div>
          <div class="col-sm-4"><div class="dato-etiqueta">Radicada</div><div class="dato-valor" data-llenar="fecha"></div></div>
        </div>
        <div class="dato-etiqueta">Enlace del soporte</div><div class="dato-valor" style="word-break: break-all" data-llenar="soporte"></div>
        <div class="dato-etiqueta">Estado</div><div class="dato-valor" data-llenar="estado"></div>
        <div class="dato-etiqueta">Respuesta del comité</div><div class="dato-valor" style="white-space: pre-line" data-llenar="respuesta"></div>
        <div class="row">
          <div class="col-sm-4"><div class="dato-etiqueta">Resuelta por</div><div class="dato-valor" data-llenar="resuelto"></div></div>
          <div class="col-sm-4"><div class="dato-etiqueta">Fecha de respuesta</div><div class="dato-valor" data-llenar="fechaResolucion"></div></div>
          <div class="col-sm-4"><div class="dato-etiqueta">Nuevo director</div><div class="dato-valor" data-llenar="nuevoDirector"></div></div>
        </div>
      </div>
    </div>
  </div>
</div>

<c:if test="${esCoordinador}">
  <div class="modal fade" id="modalResolver" tabindex="-1" aria-labelledby="tituloResolver" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
      <div class="modal-content">
        <form method="post" action="${ctx}/proceso/pqrs_proc.jsp" data-decisiones novalidate>
          <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
          <input type="hidden" name="accion" value="resolver">
          <input type="hidden" name="id" value="" data-llenar-valor="id">
          <div class="modal-header border-0">
            <h2 class="modal-title fs-5" id="tituloResolver">Resolver <span data-llenar="codigo"></span> · <span data-llenar="tipoTexto"></span></h2>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body pt-0">
            <div class="dato-etiqueta">Asunto</div><div class="dato-valor" data-llenar="asunto"></div>
            <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line" data-llenar="descripcion"></div>
            <div class="dato-etiqueta">Solicitante</div><div class="dato-valor" data-llenar="solicitante"></div>
            <div class="dato-etiqueta">Enlace del soporte</div><div class="dato-valor" style="word-break: break-all" data-llenar="soporte"></div>
            <div class="mb-3" data-mostrar-si="tipo:CAMBIO_DIRECTOR" hidden>
              <label for="nuevoDirector" class="form-label">Nuevo director <span class="texto-sec">(obligatorio para aprobar el cambio)</span></label>
              <select class="form-select" id="nuevoDirector" name="nuevoDirector" data-obligatoria-aprobar data-excluir="directorActual,evaluadorActual">
                <option value="">Selecciona un docente</option>
                <c:forEach var="d" items="${docentes.rows}"><option value="${d.id_usuario}"><c:out value="${d.nombre_completo}" /></option></c:forEach>
              </select>
              <div class="form-text">No se puede elegir al director actual ni al evaluador del proyecto.</div>
              <div class="invalid-feedback">Selecciona el nuevo director.</div>
            </div>
            <div class="mb-1">
              <label for="observacion" class="form-label">Respuesta (obligatoria para rechazar)</label>
              <textarea class="form-control" id="observacion" name="observacion" rows="4" maxlength="2000"></textarea>
              <div class="invalid-feedback">Escribe la respuesta.</div>
            </div>
          </div>
          <div class="modal-footer border-0 pt-0">
            <button type="submit" name="decision" value="RECHAZAR" class="btn btn-rechazar"><i class="bi bi-x-circle me-1"></i>Rechazar</button>
            <button type="submit" name="decision" value="APROBAR" class="btn btn-uts"><i class="bi bi-check-circle me-1"></i>Aprobar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</c:if>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

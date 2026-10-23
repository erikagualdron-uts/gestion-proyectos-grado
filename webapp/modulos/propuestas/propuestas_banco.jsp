<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%--
  Propuestas Banco (RF-22, RF-27, RF-29 a RF-32): ideas de docentes y propuestas de estudiantes en una sola tabla.
  Coordinador: ve todo, visualiza y gestiona (aprobar, aplazar o rechazar). Docente y administrador: solo visualizan.
  Estudiante: ve las suyas y corrige las aplazadas.
--%>
<c:set var="titulo" value="${sessionScope.rol == 'ESTUDIANTE' ? 'Mis propuestas' : 'Propuestas Banco'}" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="filtroEstado" value="${fn:contains(',PENDIENTE,APROBADO,APLAZADO,RECHAZADO,', ',' += param.estado += ',') ? param.estado : ''}" />
<c:set var="filtroTipo" value="${param.tipo == 'IDEA' or param.tipo == 'PROPUESTA' ? param.tipo : ''}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>
<c:set var="esCoordinador" value="${sessionScope.rol == 'COORDINADOR'}" />

<%-- Ideas de docentes + propuestas de estudiantes, con una sola definición para el resumen, el conteo y la lista --%>
<c:set var="origenDatos">
  (SELECT 'IDEA' AS tipo, i.id_idea AS id, i.codigo, i.titulo, i.descripcion, i.objetivo, i.alcance,
          d.nombre_completo AS autor, i.estado_decision AS estado, i.observacion, i.fecha_creacion AS fecha,
          '' AS miembros, 0 AS id_responsable, 'Idea de docente' AS origen_texto, 0 AS id_proyecto
   FROM idea_banco i JOIN usuario d ON d.id_usuario = i.id_docente
   UNION ALL
   SELECT 'PROPUESTA', p.id_propuesta, p.codigo, p.titulo, p.descripcion, p.objetivo, p.alcance,
          GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', '), p.estado_decision, p.observacion, p.fecha_creacion,
          GROUP_CONCAT(pe.id_estudiante), MAX(IF(pe.es_responsable = 1, pe.id_estudiante, 0)),
          IF(p.origen = 'BANCO', 'Propuesta desde el banco de ideas', 'Propuesta propia'), IFNULL(MAX(pr.id_proyecto), 0)
   FROM propuesta p
   JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
   JOIN usuario e ON e.id_usuario = pe.id_estudiante
   LEFT JOIN proyecto pr ON pr.id_propuesta = p.id_propuesta
   GROUP BY p.id_propuesta) t
</c:set>
<c:set var="rolConsulta" value="${sessionScope.rol}" />

<sql:query var="resumen" dataSource="${bd}">
  SELECT SUM(estado = 'PENDIENTE') AS pendientes, SUM(estado = 'APROBADO') AS aprobadas,
         SUM(estado = 'APLAZADO') AS aplazadas, SUM(estado = 'RECHAZADO') AS rechazadas
  FROM ${origenDatos}
  WHERE (? <> 'ESTUDIANTE' OR (tipo = 'PROPUESTA' AND FIND_IN_SET(?, miembros) > 0))
  <sql:param value="${rolConsulta}" /><sql:param value="${sessionScope.usuarioId}" />
</sql:query>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total FROM ${origenDatos}
  WHERE (? <> 'ESTUDIANTE' OR (tipo = 'PROPUESTA' AND FIND_IN_SET(?, miembros) > 0))
    AND (? = '' OR codigo LIKE ? OR titulo LIKE ? OR descripcion LIKE ? OR autor LIKE ?)
    AND (? = '' OR estado = ?) AND (? = '' OR tipo = ?)
  <sql:param value="${rolConsulta}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroTipo}" /><sql:param value="${filtroTipo}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="filas" dataSource="${bd}">
  SELECT tipo, id, codigo, titulo, descripcion, objetivo, alcance, autor, estado, observacion, origen_texto, id_responsable, id_proyecto,
         DATE_FORMAT(fecha, '%d/%m/%Y') AS fecha_texto
  FROM ${origenDatos}
  WHERE (? <> 'ESTUDIANTE' OR (tipo = 'PROPUESTA' AND FIND_IN_SET(?, miembros) > 0))
    AND (? = '' OR codigo LIKE ? OR titulo LIKE ? OR descripcion LIKE ? OR autor LIKE ?)
    AND (? = '' OR estado = ?) AND (? = '' OR tipo = ?)
  ORDER BY fecha DESC, id DESC
  LIMIT ? OFFSET ?
  <sql:param value="${rolConsulta}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroTipo}" /><sql:param value="${filtroTipo}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="activa" dataSource="${bd}">
    SELECT p.codigo FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO' LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:if>

<c:url var="pagBase" value="/modulos/propuestas/propuestas_banco.jsp">
  <c:param name="q" value="${q}" /><c:param name="estado" value="${filtroEstado}" /><c:param name="tipo" value="${filtroTipo}" />
</c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina"><c:out value="${titulo}" /></h1>
    <p class="descripcion-pagina mb-3">
      <c:choose>
        <c:when test="${esCoordinador}">Visualiza el detalle y gestiona cada solicitud: aprobar, aplazar o rechazar.</c:when>
        <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">Consulta el estado de tu propuesta y corrígela si fue aplazada.</c:when>
        <c:otherwise>Consulta las ideas de docentes y las propuestas de estudiantes con su estado.</c:otherwise>
      </c:choose>
    </p>
  </div>
  <div class="d-flex flex-wrap gap-2 mb-3">
    <c:if test="${sessionScope.rol == 'ESTUDIANTE'}"><a class="btn btn-outline-uts" href="${ctx}/modulos/pqrs/pqrs.jsp"><i class="bi bi-chat me-1"></i>PQRS</a></c:if>
    <c:if test="${sessionScope.rol == 'DOCENTE'}"><a class="btn btn-uts" href="${ctx}/modulos/banco_ideas/idea_form.jsp"><i class="bi bi-plus-lg me-1"></i>Proponer idea</a></c:if>
    <c:if test="${sessionScope.rol == 'ESTUDIANTE' and activa.rowCount == 0}">
      <a class="btn btn-outline-uts" href="${ctx}/modulos/banco_ideas/banco_ideas.jsp"><i class="bi bi-lightbulb me-1"></i>Elegir del banco</a>
      <a class="btn btn-uts" href="${ctx}/modulos/propuestas/propuesta_form.jsp"><i class="bi bi-plus-lg me-1"></i>Nueva propuesta</a>
    </c:if>
  </div>
</div>

<%-- Las tarjetas de resumen no se muestran al estudiante: solo tiene una propuesta activa y el estado ya se ve en la tabla --%>
<c:if test="${sessionScope.rol != 'ESTUDIANTE'}">
<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-clock"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].pendientes}" default="0" /></div><div class="resumen-etiqueta">Pendientes</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-check-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].aprobadas}" default="0" /></div><div class="resumen-etiqueta">Aprobadas</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aplazado"><i class="bi bi-pause-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].aplazadas}" default="0" /></div><div class="resumen-etiqueta">Aplazadas</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono rechazado"><i class="bi bi-x-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].rechazadas}" default="0" /></div><div class="resumen-etiqueta">Rechazadas</div></div></div></div>
</div>
</c:if>

<form method="get" action="${ctx}/modulos/propuestas/propuestas_banco.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, descripción, estado o estudiante" maxlength="120">
  </div>
  <c:if test="${sessionScope.rol != 'ESTUDIANTE'}">
    <div class="col-6 col-md-auto">
      <label for="tipo" class="form-label">Tipo</label>
      <select class="form-select" id="tipo" name="tipo" data-autoenviar>
        <option value="">Todos</option>
        <option value="IDEA" ${filtroTipo == 'IDEA' ? 'selected' : ''}>Ideas de docentes</option>
        <option value="PROPUESTA" ${filtroTipo == 'PROPUESTA' ? 'selected' : ''}>Propuestas de estudiantes</option>
      </select>
    </div>
  </c:if>
  <div class="col-6 col-md-auto">
    <label for="estado" class="form-label">Estado</label>
    <select class="form-select" id="estado" name="estado" data-autoenviar>
      <option value="">Todos</option>
      <option value="PENDIENTE" ${filtroEstado == 'PENDIENTE' ? 'selected' : ''}>Pendiente</option>
      <option value="APROBADO" ${filtroEstado == 'APROBADO' ? 'selected' : ''}>Aprobado</option>
      <option value="APLAZADO" ${filtroEstado == 'APLAZADO' ? 'selected' : ''}>Aplazado</option>
      <option value="RECHAZADO" ${filtroEstado == 'RECHAZADO' ? 'selected' : ''}>Rechazado</option>
    </select>
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${filas.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-file-earmark-text"></i></span>
      <h3><c:out value="${sessionScope.rol == 'ESTUDIANTE' ? 'Aún no tienes propuestas' : 'No hay solicitudes para mostrar'}" /></h3>
      <p><c:out value="${sessionScope.rol == 'ESTUDIANTE' ? 'Elige una idea del banco o crea una propuesta propia para empezar.' : 'Cambia la búsqueda o los filtros.'}" /></p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead>
          <tr><th>Código</th><th>Descripción</th><th><c:out value="${sessionScope.rol == 'ESTUDIANTE' ? 'Integrantes' : 'Autor'}" /></th><th>Estado</th><th class="text-end">Acciones</th></tr>
        </thead>
        <tbody>
          <c:forEach var="f" items="${filas.rows}">
            <c:set var="estadoTexto" value="${f.estado == 'APROBADO' ? 'Aprobado' : (f.estado == 'APLAZADO' ? 'Aplazado' : (f.estado == 'RECHAZADO' ? 'Rechazado' : 'Pendiente'))}" />
            <tr>
              <td class="fw-bold"><c:out value="${f.codigo}" /></td>
              <td style="min-width: 240px"><div><c:out value="${f.titulo}" /></div><div class="texto-sec"><c:out value="${f.origen_texto}" /></div></td>
              <td><c:out value="${f.autor}" /></td>
              <td><span class="insignia insignia-${f.estado == 'APROBADO' ? 'aprobado' : (f.estado == 'APLAZADO' ? 'aplazado' : (f.estado == 'RECHAZADO' ? 'rechazado' : 'pendiente'))}"><c:out value="${estadoTexto}" /></span></td>
              <td class="acciones">
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalDetalle" aria-label="Visualizar ${fn:escapeXml(f.codigo)}"
                        data-codigo="${fn:escapeXml(f.codigo)}" data-titulo="${fn:escapeXml(f.titulo)}" data-descripcion="${fn:escapeXml(f.descripcion)}"
                        data-objetivo="${fn:escapeXml(f.objetivo)}" data-alcance="${fn:escapeXml(f.alcance)}" data-autor="${fn:escapeXml(f.autor)}"
                        data-origen="${fn:escapeXml(f.origen_texto)}" data-estado="${estadoTexto}" data-fecha="${f.fecha_texto}"
                        data-observacion="${fn:escapeXml(f.observacion)}"><i class="bi bi-eye"></i></button>
                <c:if test="${f.id_proyecto > 0}">
                  <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${f.id_proyecto}" aria-label="Ver el seguimiento de ${fn:escapeXml(f.codigo)}"><i class="bi bi-list-check"></i></a>
                </c:if>
                <c:choose>
                  <c:when test="${esCoordinador}">
                    <button type="button" class="btn btn-outline-uts btn-icono" ${f.estado == 'PENDIENTE' ? '' : 'disabled'} data-bs-toggle="modal" data-bs-target="#modalGestionar"
                            aria-label="${f.estado == 'PENDIENTE' ? 'Gestionar' : 'Ya decidida:'} ${fn:escapeXml(f.codigo)}"
                            data-id="${f.id}" data-accion-url="${ctx}/proceso/${f.tipo == 'IDEA' ? 'idea_proc.jsp' : 'propuesta_proc.jsp'}"
                            data-codigo="${fn:escapeXml(f.codigo)}" data-titulo="${fn:escapeXml(f.titulo)}" data-autor="${fn:escapeXml(f.autor)}"
                            data-descripcion="${fn:escapeXml(f.descripcion)}" data-objetivo="${fn:escapeXml(f.objetivo)}" data-alcance="${fn:escapeXml(f.alcance)}"><i class="bi bi-pencil"></i></button>
                  </c:when>
                  <c:when test="${sessionScope.rol == 'ESTUDIANTE' and (f.estado == 'PENDIENTE' or f.estado == 'APLAZADO') and f.id_responsable == sessionScope.usuarioId}">
                    <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/propuestas/propuesta_form.jsp?id=${f.id}" aria-label="${f.estado == 'APLAZADO' ? 'Corregir y reenviar' : 'Editar compañero de'} ${fn:escapeXml(f.codigo)}"><i class="bi bi-pencil"></i></a>
                  </c:when>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalDetalle" tabindex="-1" aria-labelledby="tituloDetalle" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloDetalle"><span data-llenar="codigo"></span> · <span data-llenar="titulo"></span></h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="row">
          <div class="col-sm-6"><div class="dato-etiqueta">Origen</div><div class="dato-valor" data-llenar="origen"></div></div>
          <div class="col-sm-3"><div class="dato-etiqueta">Estado</div><div class="dato-valor" data-llenar="estado"></div></div>
          <div class="col-sm-3"><div class="dato-etiqueta">Fecha</div><div class="dato-valor" data-llenar="fecha"></div></div>
        </div>
        <div class="dato-etiqueta">Autor / integrantes</div><div class="dato-valor" data-llenar="autor"></div>
        <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line" data-llenar="descripcion"></div>
        <div class="dato-etiqueta">Objetivo</div><div class="dato-valor" style="white-space: pre-line" data-llenar="objetivo"></div>
        <div class="dato-etiqueta">Alcance</div><div class="dato-valor" style="white-space: pre-line" data-llenar="alcance"></div>
        <div class="dato-etiqueta">Observación del coordinador</div><div class="dato-valor" style="white-space: pre-line" data-llenar="observacion"></div>
      </div>
    </div>
  </div>
</div>

<c:if test="${esCoordinador}">
  <div class="modal fade" id="modalGestionar" tabindex="-1" aria-labelledby="tituloGestionar" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
      <div class="modal-content">
        <form method="post" action="${ctx}/proceso/propuesta_proc.jsp" data-decisiones data-llenar-accion novalidate>
          <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
          <input type="hidden" name="accion" value="decidir">
          <input type="hidden" name="id" value="" data-llenar-valor="id">
          <div class="modal-header border-0">
            <h2 class="modal-title fs-5" id="tituloGestionar">Gestionar <span data-llenar="codigo"></span></h2>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body pt-0">
            <div class="dato-etiqueta">Título</div><div class="dato-valor" data-llenar="titulo"></div>
            <div class="dato-etiqueta">Autor / integrantes</div><div class="dato-valor" data-llenar="autor"></div>
            <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line" data-llenar="descripcion"></div>
            <div class="dato-etiqueta">Objetivo</div><div class="dato-valor" style="white-space: pre-line" data-llenar="objetivo"></div>
            <div class="dato-etiqueta">Alcance</div><div class="dato-valor" style="white-space: pre-line" data-llenar="alcance"></div>
            <div class="mb-1">
              <label for="observacion" class="form-label">Observación (obligatoria para aplazar o rechazar)</label>
              <textarea class="form-control" id="observacion" name="observacion" rows="3" maxlength="500"></textarea>
              <div class="invalid-feedback">Escribe la observación.</div>
            </div>
          </div>
          <div class="modal-footer border-0 pt-0">
            <button type="submit" name="decision" value="RECHAZAR" class="btn btn-rechazar"><i class="bi bi-x-circle me-1"></i>Rechazar</button>
            <button type="submit" name="decision" value="APLAZAR" class="btn btn-aplazar"><i class="bi bi-pause-circle me-1"></i>Aplazar</button>
            <button type="submit" name="decision" value="APROBAR" class="btn btn-uts"><i class="bi bi-check-circle me-1"></i>Aprobar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</c:if>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

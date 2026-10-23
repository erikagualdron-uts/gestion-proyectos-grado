<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE,COORDINADOR,DOCENTE" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Banco de ideas (RF-23, RF-24): solo ideas aprobadas y disponibles, en solo lectura, con búsqueda y paginación.
     El estudiante puede elegir una idea para crear su propuesta; el docente puede proponer ideas. --%>
<c:set var="titulo" value="Banco de ideas" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="pp" value="${param.pp == '12' ? 12 : (param.pp == '24' ? 24 : 6)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total
  FROM idea_banco i JOIN usuario d ON d.id_usuario = i.id_docente
  WHERE i.estado_decision = 'APROBADO' AND i.disponible = 1
    AND (? = '' OR i.codigo LIKE ? OR i.titulo LIKE ? OR i.descripcion LIKE ? OR d.nombre_completo LIKE ?)
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="ideas" dataSource="${bd}">
  SELECT i.id_idea, i.codigo, i.titulo, i.descripcion, i.objetivo, i.alcance, d.nombre_completo AS docente
  FROM idea_banco i JOIN usuario d ON d.id_usuario = i.id_docente
  WHERE i.estado_decision = 'APROBADO' AND i.disponible = 1
    AND (? = '' OR i.codigo LIKE ? OR i.titulo LIKE ? OR i.descripcion LIKE ? OR d.nombre_completo LIKE ?)
  ORDER BY i.fecha_decision DESC, i.id_idea DESC
  LIMIT ? OFFSET ?
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<%-- Estudiante: ¿ya tiene una propuesta activa? (una idea no se puede elegir si ya participa en otra propuesta) --%>
<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="activa" dataSource="${bd}">
    SELECT p.codigo FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO' LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:if>

<c:url var="pagBase" value="/modulos/banco_ideas/banco_ideas.jsp"><c:param name="q" value="${q}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />
<c:set var="pagOpciones" value="6,12,24" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Banco de ideas</h1>
    <p class="descripcion-pagina mb-3">Ideas aprobadas por la coordinación y disponibles para trabajo de grado.</p>
  </div>
  <c:if test="${sessionScope.rol == 'DOCENTE'}">
    <a class="btn btn-uts mb-3" href="${ctx}/modulos/banco_ideas/idea_form.jsp"><i class="bi bi-plus-lg me-1"></i>Proponer idea</a>
  </c:if>
  <c:if test="${sessionScope.rol == 'ESTUDIANTE' and activa.rowCount == 0}">
    <a class="btn btn-outline-uts mb-3" href="${ctx}/modulos/propuestas/propuesta_form.jsp"><i class="bi bi-pencil-square me-1"></i>Proponer una idea propia</a>
  </c:if>
</div>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and activa.rowCount > 0}">
  <div class="alert alert-info d-flex flex-wrap align-items-center justify-content-between gap-2" role="alert">
    <span><i class="bi bi-info-circle me-1"></i>Ya participas en la propuesta <strong><c:out value="${activa.rows[0].codigo}" /></strong>. Mientras esté activa no puedes elegir otra idea, pero puedes consultar el banco.</span>
    <a class="btn btn-outline-uts btn-sm" href="${ctx}/modulos/propuestas/propuestas_banco.jsp">Ver mi propuesta</a>
  </div>
</c:if>

<form method="get" action="${ctx}/modulos/banco_ideas/banco_ideas.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, título, descripción o docente" maxlength="120">
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${ideas.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-lightbulb"></i></span>
      <h3>No hay ideas disponibles</h3>
      <p>Cuando la coordinación apruebe nuevas ideas de los docentes, aparecerán aquí.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="row g-3">
      <c:forEach var="i" items="${ideas.rows}">
        <div class="col-12 col-md-6 col-xl-4">
          <div class="tarjeta h-100 d-flex flex-column">
            <div class="d-flex align-items-center justify-content-between mb-2">
              <span class="icono-caja mb-0"><i class="bi bi-lightbulb"></i></span>
              <span class="etiqueta-sup"><c:out value="${i.codigo}" /></span>
            </div>
            <h3 class="h6 titulo fw-bold" style="color: var(--verde-bosque)"><c:out value="${i.titulo}" /></h3>
            <p class="texto-sec mb-2"><c:out value="${fn:substring(i.descripcion, 0, 140)}" /><c:if test="${fn:length(i.descripcion) > 140}">…</c:if></p>
            <p class="texto-sec mb-3"><i class="bi bi-person me-1"></i><c:out value="${i.docente}" /></p>
            <div class="mt-auto d-flex flex-wrap gap-2">
              <button type="button" class="btn btn-outline-uts btn-sm" data-bs-toggle="modal" data-bs-target="#modalIdea" aria-label="Visualizar la idea ${fn:escapeXml(i.codigo)}"
                      data-id="${i.id_idea}" data-codigo="${fn:escapeXml(i.codigo)}" data-titulo="${fn:escapeXml(i.titulo)}" data-descripcion="${fn:escapeXml(i.descripcion)}"
                      data-objetivo="${fn:escapeXml(i.objetivo)}" data-alcance="${fn:escapeXml(i.alcance)}" data-docente="${fn:escapeXml(i.docente)}"><i class="bi bi-eye me-1"></i>Ver</button>
              <c:if test="${sessionScope.rol == 'ESTUDIANTE' and activa.rowCount == 0}">
                <form method="post" action="${ctx}/proceso/propuesta_proc.jsp" data-confirmar="¿Elegir la idea ${fn:escapeXml(i.codigo)} para tu propuesta? Quedará pendiente de aprobación.">
                  <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
                  <input type="hidden" name="accion" value="elegir">
                  <input type="hidden" name="id" value="${i.id_idea}">
                  <button type="submit" class="btn btn-uts btn-sm"><i class="bi bi-check2-circle me-1"></i>Elegir idea</button>
                </form>
              </c:if>
            </div>
          </div>
        </div>
      </c:forEach>
    </div>
    <c:if test="${totalRegistros > 6}"><jsp:include page="/WEB-INF/includes/paginacion.jsp" /></c:if>
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalIdea" tabindex="-1" aria-labelledby="tituloModalIdea" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloModalIdea"><span data-llenar="codigo"></span> · <span data-llenar="titulo"></span></h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="mb-3"><span class="insignia insignia-aprobado"><i class="bi bi-check-circle me-1"></i>Aprobada · disponible</span></div>
        <div class="dato-etiqueta">Propuesta por</div><div class="dato-valor" data-llenar="docente"></div>
        <div class="dato-etiqueta">Descripción</div><div class="dato-valor" style="white-space: pre-line" data-llenar="descripcion"></div>
        <div class="dato-etiqueta">Objetivo</div><div class="dato-valor" style="white-space: pre-line" data-llenar="objetivo"></div>
        <div class="dato-etiqueta">Alcance</div><div class="dato-valor" style="white-space: pre-line" data-llenar="alcance"></div>
      </div>
      <div class="modal-footer border-0 pt-0">
        <c:if test="${sessionScope.rol == 'ESTUDIANTE' and activa.rowCount == 0}">
          <form method="post" action="${ctx}/proceso/propuesta_proc.jsp" class="m-0" data-confirmar="¿Elegir esta idea para tu propuesta? Quedará pendiente de aprobación.">
            <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
            <input type="hidden" name="accion" value="elegir">
            <input type="hidden" name="id" value="" data-llenar-valor="id">
            <button type="submit" class="btn btn-uts"><i class="bi bi-check2-circle me-1"></i>Elegir esta idea</button>
          </form>
        </c:if>
        <button type="button" class="btn btn-outline-uts" data-bs-dismiss="modal">Cerrar</button>
      </div>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

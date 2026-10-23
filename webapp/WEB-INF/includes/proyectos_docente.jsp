<%-- Módulo Docente Director / Docente Evaluador (RF-49, RF-50, RF-51). Se incluye con <%@ include %> desde
     docente_director.jsp y docente_evaluador.jsp, que definen modoDocente = 'DIRECTOR' | 'EVALUADOR' y la ruta de la página (rutaDocente).
     Un docente solo ve aquí los proyectos donde ocupa ese papel; el sistema nunca lo asigna como director y evaluador del mismo proyecto. --%>
<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>
<c:catch var="faseInvalida"><c:set var="filtroFase" value="${empty param.fase ? 0 : param.fase + 0}" /></c:catch>
<c:if test="${not empty faseInvalida or filtroFase < 0 or filtroFase > 6}"><c:set var="filtroFase" value="${0}" /></c:if>
<c:set var="esDirector" value="${modoDocente == 'DIRECTOR'}" />

<%-- Proyectos del docente en este papel --%>
<c:set var="misProyectos">
  FROM proyecto pr
  JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  JOIN proyecto_fase pf ON pf.id_proyecto = pr.id_proyecto AND pf.id_fase = pr.fase_actual
  JOIN fase f ON f.id_fase = pr.fase_actual
  WHERE ((? = 'DIRECTOR' AND pr.id_director = ?) OR (? = 'EVALUADOR' AND pr.id_evaluador = ?))
    AND (? = 0 OR pr.fase_actual = ?)
    AND (? = '' OR p.codigo LIKE ? OR p.titulo LIKE ?
         OR EXISTS (SELECT 1 FROM propuesta_estudiante pe2 JOIN usuario e2 ON e2.id_usuario = pe2.id_estudiante
                    WHERE pe2.id_propuesta = p.id_propuesta AND e2.nombre_completo LIKE ?))
</c:set>

<sql:query var="porFase" dataSource="${bd}">
  SELECT SUM(pr.fase_actual = 1) AS f1, SUM(pr.fase_actual = 2) AS f2, SUM(pr.fase_actual = 3) AS f3,
         SUM(pr.fase_actual = 4) AS f4, SUM(pr.fase_actual = 5) AS f5, SUM(pr.fase_actual = 6) AS f6
  FROM proyecto pr
  WHERE (? = 'DIRECTOR' AND pr.id_director = ?) OR (? = 'EVALUADOR' AND pr.id_evaluador = ?)
  <sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" />
</sql:query>
<c:set var="conteoFases" value="${porFase.rows[0]}" />

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total ${misProyectos}
  <sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="proyectos" dataSource="${bd}">
  SELECT x.*,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = x.doc_vigente AND r.rol_revisor = 'DIRECTOR') AS dir_rev,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = x.doc_vigente AND r.rol_revisor = 'DIRECTOR' AND r.decision = 'APROBADO') AS dir_ok,
         (SELECT COUNT(*) FROM revision r WHERE r.id_documento = x.doc_vigente AND r.rol_revisor = 'EVALUADOR') AS eva_rev
  FROM (
    SELECT pr.id_proyecto, pr.fase_actual, pr.estado_general, p.codigo, p.titulo, f.nombre AS fase, pf.estado AS estado_fase,
           (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
            FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes,
           (SELECT d.id_documento FROM documento d
            WHERE d.id_proyecto_fase = pf.id_proyecto_fase AND d.vigente = 1
              AND d.nombre = CASE pr.fase_actual WHEN 1 THEN 'Comprobante de pago' WHEN 2 THEN 'Anteproyecto (F-DC-124)' WHEN 3 THEN 'Anteproyecto (F-DC-124)'
                                                WHEN 4 THEN 'Informe (F-DC-125)' WHEN 5 THEN 'Informe (F-DC-125)' ELSE 'Revisión final' END
            ORDER BY d.version_num DESC LIMIT 1) AS doc_vigente
    ${misProyectos}
    ORDER BY pr.id_proyecto DESC LIMIT ? OFFSET ?
  ) x
  ORDER BY x.id_proyecto DESC
  <sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" /><sql:param value="${modoDocente}" /><sql:param value="${sessionScope.usuarioId}" />
  <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" />
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:url var="pagBase" value="${rutaDocente}"><c:param name="q" value="${q}" /><c:param name="fase" value="${filtroFase}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />
<c:set var="nombresFase" value="${fn:split('Pago|Propuesta I|Propuesta II|Informe I|Informe II|Revisión final', '|')}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Docente <c:out value="${esDirector ? 'Director' : 'Evaluador'}" /></h1>
<p class="descripcion-pagina">Proyectos donde eres <c:out value="${esDirector ? 'director' : 'evaluador'}" />. Elige una fase para filtrar la tabla.</p>

<div class="tabla-envoltorio mb-4">
  <div class="linea-fases">
    <c:forEach var="n" begin="1" end="6">
      <a class="fase-col ${filtroFase == n ? 'elegida' : ''} ${filtroFase == n ? 'actual' : 'pendiente'}" href="${ctx}${rutaDocente}?fase=${filtroFase == n ? 0 : n}" aria-label="Filtrar por la fase ${n}: ${nombresFase[n - 1]}">
        <div class="fase-arriba"><span class="fase-circulo"><c:out value="${n}" /></span></div>
        <div class="fase-tarjeta">
          <small>Fase <c:out value="${n}" /></small>
          <strong><c:out value="${nombresFase[n - 1]}" /></strong>
          <span class="d-block mt-1" style="font-size: .8rem; opacity: .85"><c:out value="${empty conteoFases['f' += n] ? 0 : conteoFases['f' += n]}" /> proyecto(s)</span>
        </div>
      </a>
    </c:forEach>
  </div>
</div>

<form method="get" action="${ctx}${rutaDocente}" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <input type="hidden" name="fase" value="${filtroFase}">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Código, título o estudiante" maxlength="120">
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
  <c:if test="${filtroFase > 0}"><div class="col-12 col-md-auto"><a class="btn btn-outline-uts w-100" href="${ctx}${rutaDocente}">Quitar filtro de fase</a></div></c:if>
</form>

<c:choose>
  <c:when test="${proyectos.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-folder2-open"></i></span>
      <h3>No tienes proyectos para mostrar</h3>
      <p>Los proyectos aparecen cuando el coordinador te asigna como <c:out value="${esDirector ? 'director' : 'evaluador'}" />.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>ID</th><th>Descripción</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="p" items="${proyectos.rows}">
            <c:set var="porRevisar" value="${p.estado_general == 'EN_CURSO' and p.estado_fase == 'EN_CURSO' and not empty p.doc_vigente and (esDirector ? ((p.fase_actual == 2 or p.fase_actual == 3 or p.fase_actual == 4 or p.fase_actual == 5) and p.dir_rev == 0) : ((p.fase_actual == 3 or p.fase_actual == 5) and p.dir_ok > 0 and p.eva_rev == 0))}" />
            <tr>
              <td class="fw-bold"><c:out value="${p.codigo}" /></td>
              <td style="min-width: 220px"><c:out value="${p.titulo}" /></td>
              <td>
                <div class="fw-semibold">Fase <c:out value="${p.fase_actual}" /> · <c:out value="${p.fase}" /></div>
                <div class="texto-sec mb-1"><c:out value="${p.estudiantes}" /></div>
                <c:choose>
                  <c:when test="${p.estado_general == 'APTO_GRADUACION'}"><span class="insignia insignia-aprobado">Listo para sustentación</span></c:when>
                  <c:when test="${p.estado_general == 'CERRADO'}"><span class="insignia insignia-rechazado">Cerrado</span></c:when>
                  <c:when test="${porRevisar}"><span class="insignia insignia-aplazado">Por revisar</span></c:when>
                  <c:when test="${p.estado_fase == 'APLAZADA'}"><span class="insignia insignia-aplazado">Aplazado · espera al estudiante</span></c:when>
                  <c:otherwise><span class="insignia insignia-pendiente">En espera</span></c:otherwise>
                </c:choose>
              </td>
              <td class="acciones">
                <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${p.id_proyecto}" aria-label="Ver el seguimiento de ${fn:escapeXml(p.codigo)}"><i class="bi bi-eye"></i></a>
                <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/revision_form.jsp?id=${p.id_proyecto}" aria-label="Calificar el documento de ${fn:escapeXml(p.codigo)}"><i class="bi bi-pencil"></i></a>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

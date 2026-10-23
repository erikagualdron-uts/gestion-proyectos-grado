<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Notificaciones internas (RF-57): listado de avisos del usuario con la opción de marcarlos como leídos. Sin correos. --%>
<c:set var="titulo" value="Notificaciones" scope="request" />
<c:set var="menuActivo" value="/inicio.jsp" scope="request" />

<c:set var="soloNuevas" value="${param.estado == 'NUEVAS'}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>

<sql:query var="resumen" dataSource="${bd}">
  SELECT SUM(leida = 0) AS nuevas, SUM(leida = 1) AS leidas FROM notificacion WHERE id_usuario = ?
  <sql:param value="${sessionScope.usuarioId}" />
</sql:query>
<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total FROM notificacion WHERE id_usuario = ? AND (? = 0 OR leida = 0)
  <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${soloNuevas ? 1 : 0}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="avisos" dataSource="${bd}">
  SELECT n.id_notificacion, n.id_proyecto, n.tipo, n.mensaje, IF(n.leida = 1, 'SI', 'NO') AS leida_txt,
         DATE_FORMAT(n.fecha_creacion, '%d/%m/%Y %H:%i') AS fecha, p.codigo AS codigo_proyecto
  FROM notificacion n
  LEFT JOIN proyecto pr ON pr.id_proyecto = n.id_proyecto
  LEFT JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  WHERE n.id_usuario = ? AND (? = 0 OR n.leida = 0)
  ORDER BY n.fecha_creacion DESC, n.id_notificacion DESC
  LIMIT ? OFFSET ?
  <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${soloNuevas ? 1 : 0}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:url var="pagBase" value="/modulos/notificaciones/notificaciones.jsp"><c:param name="estado" value="${soloNuevas ? 'NUEVAS' : ''}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Notificaciones</h1>
    <p class="descripcion-pagina mb-3">Avisos internos sobre tus solicitudes, proyectos y revisiones.</p>
  </div>
  <c:if test="${resumen.rows[0].nuevas > 0}">
    <form method="post" action="${ctx}/proceso/notificacion_proc.jsp" class="mb-3">
      <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
      <input type="hidden" name="accion" value="todas">
      <button type="submit" class="btn btn-outline-uts"><i class="bi bi-check2-all me-1"></i>Marcar todas como leídas</button>
    </form>
  </c:if>
</div>

<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aplazado"><i class="bi bi-bell"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].nuevas}" default="0" /></div><div class="resumen-etiqueta">Sin leer</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-check2-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].leidas}" default="0" /></div><div class="resumen-etiqueta">Leídas</div></div></div></div>
</div>

<form method="get" action="${ctx}/modulos/notificaciones/notificaciones.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md-auto">
    <label for="estado" class="form-label">Mostrar</label>
    <select class="form-select" id="estado" name="estado" data-autoenviar>
      <option value="">Todas</option>
      <option value="NUEVAS" ${soloNuevas ? 'selected' : ''}>Solo sin leer</option>
    </select>
  </div>
</form>

<c:choose>
  <c:when test="${avisos.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-bell"></i></span>
      <h3><c:out value="${soloNuevas ? 'No tienes avisos sin leer' : 'Aún no tienes notificaciones'}" /></h3>
      <p>Aquí aparecerán los avisos sobre tus propuestas, revisiones, asignaciones y solicitudes.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>Aviso</th><th>Fecha</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="a" items="${avisos.rows}">
            <tr>
              <td style="min-width: 280px">
                <div class="${a.leida_txt == 'NO' ? 'fw-semibold' : ''}"><c:out value="${a.mensaje}" /></div>
                <c:if test="${not empty a.codigo_proyecto}"><div class="texto-sec">Proyecto <c:out value="${a.codigo_proyecto}" /></div></c:if>
              </td>
              <td><c:out value="${a.fecha}" /></td>
              <td><span class="insignia insignia-${a.leida_txt == 'NO' ? 'aplazado' : 'pendiente'}"><c:out value="${a.leida_txt == 'NO' ? 'Nueva' : 'Leída'}" /></span></td>
              <td class="acciones">
                <c:if test="${not empty a.id_proyecto}">
                  <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${a.id_proyecto}" aria-label="Ver el proyecto ${fn:escapeXml(a.codigo_proyecto)}"><i class="bi bi-eye"></i></a>
                </c:if>
                <c:if test="${a.leida_txt == 'NO'}">
                  <form method="post" action="${ctx}/proceso/notificacion_proc.jsp" class="d-inline">
                    <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
                    <input type="hidden" name="accion" value="marcar">
                    <input type="hidden" name="id" value="${a.id_notificacion}">
                    <button type="submit" class="btn btn-outline-uts btn-icono" aria-label="Marcar como leída"><i class="bi bi-check2"></i></button>
                  </form>
                </c:if>
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

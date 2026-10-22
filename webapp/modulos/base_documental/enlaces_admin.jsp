<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Administrar los enlaces de la base documental (RF-20): crear, editar, ordenar y desactivar. --%>
<c:set var="titulo" value="Administrar enlaces" scope="request" />
<c:set var="menuActivo" value="/modulos/base_documental/base_documental.jsp" scope="request" />
<c:set var="volverA" value="/modulos/base_documental/base_documental.jsp" scope="request" />
<sql:query var="enlaces" dataSource="${bd}">
  SELECT id_enlace, nombre, descripcion, url, icono, orden, IF(activo = 1, 'SI', 'NO') AS activo_txt
  FROM enlace_documental ORDER BY orden, id_enlace
</sql:query>
<c:set var="iconos" value="bi-calendar-event|Calendario;bi-file-earmark-text|Documento;bi-easel|Presentación;bi-mortarboard|Grado;bi-award|Estímulos;bi-journal-text|Reglamento;bi-book|Libro;bi-link-45deg|Enlace" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Administrar enlaces</h1>
    <p class="descripcion-pagina mb-3">Crea, edita, ordena (por número) o desactiva los enlaces de la base documental.</p>
  </div>
  <button type="button" class="btn btn-uts mb-3" data-bs-toggle="modal" data-bs-target="#modalEnlace" data-id="" data-nombre="" data-descripcion="" data-url="" data-icono="bi-journal-text" data-orden="${enlaces.rowCount + 1}" data-activo="1" data-titulo="Nuevo enlace">
    <i class="bi bi-plus-lg me-1"></i>Nuevo enlace
  </button>
</div>

<c:choose>
  <c:when test="${enlaces.rowCount == 0}">
    <div class="vacio"><span class="icono-circulo"><i class="bi bi-link-45deg"></i></span><h3>No hay enlaces</h3><p>Crea el primero con el botón "Nuevo enlace".</p></div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead><tr><th>Orden</th><th>Nombre</th><th>Enlace</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
          <c:forEach var="e" items="${enlaces.rows}">
            <tr>
              <td class="fw-semibold"><c:out value="${e.orden}" /></td>
              <td><div class="fw-semibold"><i class="bi ${empty e.icono ? 'bi-journal-text' : e.icono} me-1"></i><c:out value="${e.nombre}" /></div><div class="texto-sec"><c:out value="${e.descripcion}" /></div></td>
              <td style="max-width: 320px; word-break: break-all"><c:out value="${e.url}" /></td>
              <td><c:choose>
                <c:when test="${e.activo_txt == 'SI'}"><span class="insignia insignia-aprobado">Activo</span></c:when>
                <c:otherwise><span class="insignia insignia-pendiente">Inactivo</span></c:otherwise>
              </c:choose></td>
              <td class="acciones">
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalEnlace" aria-label="Gestionar el enlace ${fn:escapeXml(e.nombre)}"
                        data-id="${e.id_enlace}" data-nombre="${fn:escapeXml(e.nombre)}" data-descripcion="${fn:escapeXml(e.descripcion)}" data-url="${fn:escapeXml(e.url)}"
                        data-icono="${fn:escapeXml(e.icono)}" data-orden="${e.orden}" data-activo="${e.activo_txt == 'SI' ? '1' : '0'}" data-titulo="Editar enlace"><i class="bi bi-pencil"></i></button>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalEnlace" tabindex="-1" aria-labelledby="tituloEnlace" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="post" action="${ctx}/proceso/enlace_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="id" value="" data-llenar-valor="id">
        <div class="modal-header border-0">
          <h2 class="modal-title fs-5" id="tituloEnlace" data-llenar="titulo">Enlace</h2>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
        </div>
        <div class="modal-body pt-0">
          <div class="mb-3">
            <label for="enNombre" class="form-label">Nombre</label>
            <input type="text" class="form-control" id="enNombre" name="nombre" maxlength="80" required data-llenar-valor="nombre">
            <div class="invalid-feedback">Ingresa el nombre.</div>
          </div>
          <div class="mb-3">
            <label for="enDescripcion" class="form-label">Descripción corta</label>
            <input type="text" class="form-control" id="enDescripcion" name="descripcion" maxlength="200" data-llenar-valor="descripcion">
          </div>
          <div class="mb-3">
            <label for="enUrl" class="form-label">Enlace (URL)</label>
            <input type="url" class="form-control" id="enUrl" name="url" maxlength="500" placeholder="https://..." required data-llenar-valor="url">
            <div class="invalid-feedback">Ingresa un enlace que empiece por http:// o https://.</div>
          </div>
          <div class="row g-3">
            <div class="col-sm-6">
              <label for="enIcono" class="form-label">Icono</label>
              <select class="form-select" id="enIcono" name="icono" data-llenar-valor="icono">
                <c:forEach var="i" items="${fn:split(iconos, ';')}">
                  <c:set var="p" value="${fn:split(i, '|')}" />
                  <option value="${p[0]}"><c:out value="${p[1]}" /></option>
                </c:forEach>
              </select>
            </div>
            <div class="col-6 col-sm-3">
              <label for="enOrden" class="form-label">Orden</label>
              <input type="number" class="form-control" id="enOrden" name="orden" min="1" max="250" required data-llenar-valor="orden">
            </div>
            <div class="col-6 col-sm-3">
              <label for="enActivo" class="form-label">Estado</label>
              <select class="form-select" id="enActivo" name="activo" data-llenar-valor="activo">
                <option value="1">Activo</option>
                <option value="0">Inactivo</option>
              </select>
            </div>
          </div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <button type="button" class="btn btn-outline-uts" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-uts"><i class="bi bi-check-lg me-1"></i>Guardar</button>
        </div>
      </form>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

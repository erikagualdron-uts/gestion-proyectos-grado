<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Paginación y selector de registros por página. Se incluye con <jsp:include>.
  La página define en ámbito request:
    pagBase          URL de la lista con los filtros (c:url), sin pag ni pp
    pagActual        página actual (1, 2, ...)
    pagPorPagina     registros por página (5, 10 o 20)
    pagOpciones      (opcional) opciones del selector separadas por coma, por defecto 5,10,20
    pagTotalPaginas  total de páginas (mínimo 1)
--%>
<c:set var="desde" value="${pagActual - 2 < 1 ? 1 : pagActual - 2}" />
<c:set var="hasta" value="${pagActual + 2 > pagTotalPaginas ? pagTotalPaginas : pagActual + 2}" />
<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mt-3">
  <label class="d-flex align-items-center gap-2 texto-sec mb-0">
    Registros por página
    <select class="form-select form-select-sm-uts" data-por-pagina aria-label="Registros por página">
      <c:forEach var="opcion" items="${empty pagOpciones ? '5,10,20' : pagOpciones}">
        <option value="${opcion}" ${pagPorPagina == opcion ? 'selected' : ''}>${opcion}</option>
      </c:forEach>
    </select>
  </label>
  <nav aria-label="Paginación">
    <ul class="pagination mb-0">
      <li class="page-item ${pagActual <= 1 ? 'disabled' : ''}">
        <a class="page-link" href="${pagBase}&pp=${pagPorPagina}&pag=${pagActual - 1}" aria-label="Página anterior"><i class="bi bi-chevron-left"></i></a>
      </li>
      <c:forEach var="n" begin="${desde}" end="${hasta}">
        <li class="page-item ${n == pagActual ? 'active' : ''}">
          <a class="page-link" href="${pagBase}&pp=${pagPorPagina}&pag=${n}" ${n == pagActual ? 'aria-current="page"' : ''}>${n}</a>
        </li>
      </c:forEach>
      <li class="page-item ${pagActual >= pagTotalPaginas ? 'disabled' : ''}">
        <a class="page-link" href="${pagBase}&pp=${pagPorPagina}&pag=${pagActual + 1}" aria-label="Página siguiente"><i class="bi bi-chevron-right"></i></a>
      </li>
    </ul>
  </nav>
</div>

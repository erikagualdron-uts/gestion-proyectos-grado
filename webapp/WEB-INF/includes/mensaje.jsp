<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%-- Muestra una sola vez el mensaje guardado en sesión (flashMsg / flashTipo: success, danger, warning). --%>
<c:if test="${not empty sessionScope.flashMsg}">
  <c:set var="tipoAlerta" value="${empty sessionScope.flashTipo ? 'success' : sessionScope.flashTipo}" />
  <div class="alert alert-${tipoAlerta} d-flex align-items-start gap-2" role="alert">
    <i class="bi ${tipoAlerta == 'success' ? 'bi-check-circle' : (tipoAlerta == 'danger' ? 'bi-x-circle' : 'bi-exclamation-triangle')}"></i>
    <div><c:out value="${sessionScope.flashMsg}" /></div>
  </div>
  <c:remove var="flashMsg" scope="session" />
  <c:remove var="flashTipo" scope="session" />
</c:if>

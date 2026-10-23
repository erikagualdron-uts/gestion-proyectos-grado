<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%-- Cierre de la página y scripts. Se incluye con <jsp:include> al final de cada página. --%>
<c:choose>
  <c:when test="${not empty paginaPublica}">
      </main>
    </div>
  </c:when>
  <c:otherwise>
    </div>
  </c:otherwise>
</c:choose>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<c:if test="${not empty usarGraficos}">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script src="${ctx}/js/graficos.js"></script>
</c:if>
<script src="${ctx}/js/validaciones.js"></script>
<script src="${ctx}/js/tablas.js"></script>
</body>
</html>

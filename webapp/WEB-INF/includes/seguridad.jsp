<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%--
  Seguridad común (RF-07, RNF-03, RNF-05). Se incluye con <%@ include %> DESPUÉS de conexion.jsp.
  Variables que la página puede definir antes de incluirlo:
    paginaPublica = true     página sin sesión (login, registro y sus procesos)
    rolesPermitidos          roles separados por coma (vacío: cualquier usuario con sesión)
    soloPost = true          páginas de proceso: solo aceptan POST
  Un <c:redirect> detiene el resto de la página (SKIP_PAGE), así no se ejecuta nada más.
--%>
<fmt:requestEncoding value="UTF-8" />
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />
<c:set var="destinoInicio" value="${empty paginaPublica ? '/inicio.jsp' : '/index.jsp'}" />

<%-- Token anti-CSRF por sesión --%>
<c:if test="${empty sessionScope.csrf}">
  <sql:query var="tokenNuevo" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(16))) AS t</sql:query>
  <c:set var="csrf" value="${tokenNuevo.rows[0].t}" scope="session" />
</c:if>

<%-- Sesión recordada ("Mantener sesión activa") --%>
<c:if test="${empty sessionScope.usuarioId and not empty cookie.recordar.value}">
  <sql:query var="recordada" dataSource="${bd}">
    SELECT u.id_usuario, u.nombre_completo, u.correo, u.nivel, r.nombre AS rol,
           SUBSTRING_INDEX(TRIM(u.nombre_completo), ' ', 1) AS primer_nombre,
           UPPER(CONCAT(LEFT(TRIM(u.nombre_completo), 1),
             IF(LOCATE(' ', TRIM(u.nombre_completo)) > 0,
                LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(u.nombre_completo), ' ', 2), ' ', -1), 1), ''))) AS iniciales
    FROM sesion_persistente s
    JOIN usuario u ON u.id_usuario = s.id_usuario
    JOIN rol r ON r.id_rol = u.id_rol
    WHERE s.token_hash = SHA2(?, 256) AND s.fecha_expira > NOW()
      AND u.estado_cuenta = 'APROBADA' AND u.activo = 1
    <sql:param value="${cookie.recordar.value}" />
  </sql:query>
  <c:choose>
    <c:when test="${recordada.rowCount == 1}">
      <c:set var="u" value="${recordada.rows[0]}" />
      <%@ include file="/WEB-INF/includes/iniciar_sesion.jsp" %>
    </c:when>
    <c:otherwise>
      <c:set var="ignorar" value="${pageContext.response.addHeader('Set-Cookie', 'recordar=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax')}" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Páginas protegidas: sesión, cuenta vigente y rol --%>
<c:if test="${empty paginaPublica}">
  <c:if test="${empty sessionScope.usuarioId}">
    <c:set var="flashTipo" value="warning" scope="session" />
    <c:set var="flashMsg" value="Inicia sesión para continuar." scope="session" />
    <c:redirect url="/index.jsp" />
  </c:if>
  <sql:query var="vigente" dataSource="${bd}">
    SELECT u.nivel, r.nombre AS rol
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE u.id_usuario = ? AND u.estado_cuenta = 'APROBADA' AND u.activo = 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:if test="${vigente.rowCount != 1}">
    <c:remove var="usuarioId" scope="session" />
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="Tu cuenta ya no está habilitada para ingresar." scope="session" />
    <c:redirect url="/index.jsp" />
  </c:if>
  <c:set var="rol" value="${vigente.rows[0].rol}" scope="session" />
  <c:set var="nivel" value="${vigente.rows[0].nivel}" scope="session" />
  <c:if test="${not empty rolesPermitidos and not fn:contains(rolesPermitidos, sessionScope.rol)}">
    <c:redirect url="/acceso_denegado.jsp" />
  </c:if>
</c:if>

<%-- Páginas de proceso: solo POST y token CSRF válido --%>
<c:if test="${not empty soloPost and pageContext.request.method != 'POST'}">
  <c:redirect url="${destinoInicio}" />
</c:if>
<c:if test="${pageContext.request.method == 'POST' and param.csrf != sessionScope.csrf}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="El formulario expiró o no es válido. Inténtalo de nuevo." scope="session" />
  <c:redirect url="${destinoInicio}" />
</c:if>

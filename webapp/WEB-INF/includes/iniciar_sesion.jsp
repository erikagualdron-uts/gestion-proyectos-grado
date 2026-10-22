<%-- Abre la sesión del usuario. Espera la variable "u" (fila de usuario con id_usuario,
     nombre_completo, primer_nombre, iniciales, correo, nivel y rol). Se incluye con
     <%@ include %> desde login_proc.jsp y seguridad.jsp. --%>
<c:set var="ignorar" value="${pageContext.request.changeSessionId()}" />
<sql:query var="tokenCsrf" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(16))) AS t</sql:query>
<c:set var="usuarioId" value="${u.id_usuario}" scope="session" />
<c:set var="rol" value="${u.rol}" scope="session" />
<c:set var="nombre" value="${u.nombre_completo}" scope="session" />
<c:set var="primerNombre" value="${u.primer_nombre}" scope="session" />
<c:set var="iniciales" value="${u.iniciales}" scope="session" />
<c:set var="correo" value="${u.correo}" scope="session" />
<c:set var="nivel" value="${u.nivel}" scope="session" />
<c:set var="csrf" value="${tokenCsrf.rows[0].t}" scope="session" />

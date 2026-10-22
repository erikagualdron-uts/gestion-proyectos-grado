<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sistema de Gestión de Proyectos de Grado</title>
</head>
<body style="font-family: sans-serif; padding: 2rem;">
  <h1>Sistema de Gestión de Proyectos de Grado</h1>
  <p>Página mínima de despliegue (se reemplazará por el inicio de sesión).</p>
  <c:catch var="errorBd">
    <sql:query var="roles" dataSource="${bd}">SELECT nombre FROM rol ORDER BY id_rol</sql:query>
  </c:catch>
  <c:choose>
    <c:when test="${empty errorBd}">
      <p style="color:#0B5B3A"><strong>Conexión a la base de datos: correcta.</strong> Roles encontrados: ${roles.rowCount}.</p>
    </c:when>
    <c:otherwise>
      <p style="color:#9A2A22"><strong>No se pudo conectar a la base de datos.</strong></p>
    </c:otherwise>
  </c:choose>
</body>
</html>

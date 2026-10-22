<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<c:set var="titulo" value="Inicio" scope="request" />

<%-- Tarjetas de módulos según el rol (RF-06). Cada una: icono|título|descripción|ruta, separadas por punto y coma. --%>
<c:choose>
  <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para tu proyecto de grado." />
    <c:set var="tarjetas" value="bi-lightbulb|Banco de ideas|Explora las ideas aprobadas por los docentes y elige una.|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Propuesta Banco|Registra o corrige tu propuesta y accede a tu seguimiento, historial, PQRS e informe de estado.|/modulos/propuestas/propuestas_banco.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp;bi-person|Mi perfil|Revisa y actualiza tus datos personales.|/modulos/perfil/perfil.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'DOCENTE'}">
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para docentes." />
    <c:set var="tarjetas" value="bi-lightbulb|Banco de ideas|Consulta las ideas aprobadas y propón nuevas ideas.|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Propuestas Banco|Consulta las propuestas de los estudiantes.|/modulos/propuestas/propuestas_banco.jsp;bi-person-check|Docente Director|Proyectos que diriges: revisa y califica documentos.|/modulos/docente_director/docente_director.jsp;bi-clipboard-check|Docente Evaluador|Proyectos que evalúas: revisa y decide en tus fases.|/modulos/docente_evaluador/docente_evaluador.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp;bi-person|Mi perfil|Revisa y actualiza tus datos personales.|/modulos/perfil/perfil.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'COORDINADOR'}">
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para la coordinación." />
    <c:set var="tarjetas" value="bi-file-earmark-text|Propuestas Banco|Decide sobre ideas de docentes y propuestas de estudiantes.|/modulos/propuestas/propuestas_banco.jsp;bi-people|Asignación de proyectos|Asigna director y evaluador a cada proyecto aprobado.|/modulos/proyectos/asignacion.jsp;bi-chat|PQRS|Resuelve las solicitudes radicadas por los estudiantes.|/modulos/pqrs/pqrs.jsp;bi-bar-chart|Informes de estado|Consulta el avance de los proyectos.|/modulos/informes/informe_coordinador.jsp;bi-lightbulb|Banco de ideas|Consulta las ideas aprobadas por los docentes.|/modulos/banco_ideas/banco_ideas.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp" />
  </c:when>
  <c:otherwise>
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para la administración." />
    <c:set var="tarjetas" value="bi-people|Usuarios|Crea y administra coordinadores, docentes y administradores.|/modulos/usuarios/usuarios.jsp;bi-person-check|Solicitudes de cuenta|Aprueba o rechaza las cuentas de estudiantes.|/modulos/usuarios/cuentas_pendientes.jsp;bi-file-earmark-text|Propuestas Banco|Consulta las propuestas y su estado.|/modulos/propuestas/propuestas_banco.jsp;bi-chat|PQRS|Consulta las solicitudes radicadas.|/modulos/pqrs/pqrs.jsp;bi-clock-history|Historial de versiones|Revisa los cambios registrados en el sistema.|/modulos/historial/historial.jsp;bi-journal-text|Base documental|Administra los enlaces de la base documental.|/modulos/base_documental/base_documental.jsp" />
  </c:otherwise>
</c:choose>

<%-- Proyecto del estudiante (si ya tiene uno) --%>
<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="proyecto" dataSource="${bd}">
    SELECT f.numero, f.nombre AS fase, pf.estado
    FROM propuesta_estudiante pe
    JOIN proyecto p ON p.id_propuesta = pe.id_propuesta
    JOIN fase f ON f.id_fase = p.fase_actual
    LEFT JOIN proyecto_fase pf ON pf.id_proyecto = p.id_proyecto AND pf.id_fase = p.fase_actual
    WHERE pe.id_estudiante = ?
    ORDER BY p.id_proyecto DESC LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:if>

<sql:query var="calendario" dataSource="${bd}">
  SELECT url FROM enlace_documental WHERE nombre LIKE 'Calendario%' AND activo = 1 ORDER BY orden LIMIT 1
</sql:query>

<%-- Administrador: solicitudes de cuenta por revisar --%>
<c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
  <sql:query var="pendientesCuenta" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE' AND u.activo = 1
  </sql:query>
</c:if>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Hola, <c:out value="${sessionScope.primerNombre}" /></h1>
<p class="descripcion-pagina"><c:out value="${descripcionInicio}" /></p>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and proyecto.rowCount > 0}">
  <c:set var="py" value="${proyecto.rows[0]}" />
  <div class="tarjeta d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
    <div>
      <div class="etiqueta-sup">Tu proyecto</div>
      <div class="fw-bold fs-5 titulo">Fase <c:out value="${py.numero}" /> · <c:out value="${py.fase}" /></div>
    </div>
    <div class="d-flex flex-wrap align-items-center gap-3">
      <c:choose>
        <c:when test="${py.estado == 'APROBADA'}"><span class="insignia insignia-aprobado">Aprobado</span></c:when>
        <c:when test="${py.estado == 'APLAZADA'}"><span class="insignia insignia-aplazado">Aplazado · corregir y reenviar</span></c:when>
        <c:when test="${py.estado == 'RECHAZADA'}"><span class="insignia insignia-rechazado">Rechazado</span></c:when>
        <c:otherwise><span class="insignia insignia-pendiente">En curso</span></c:otherwise>
      </c:choose>
      <a class="btn btn-uts" href="${ctx}/modulos/proyectos/seguimiento.jsp">Ver seguimiento</a>
    </div>
  </div>
</c:if>

<div class="row g-3 mb-4">
  <c:forEach var="tarjeta" items="${fn:split(tarjetas, ';')}">
    <c:set var="p" value="${fn:split(tarjeta, '|')}" />
    <div class="col-12 col-md-6 col-xl-4">
      <a class="tarjeta tarjeta-modulo" href="${ctx}${p[3]}">
        <span class="icono-caja"><i class="bi ${p[0]}"></i></span>
        <h3><c:out value="${p[1]}" /></h3>
        <p><c:out value="${p[2]}" /></p>
      </a>
    </div>
  </c:forEach>
  <%-- Calendario académico (RF-18): abre el enlace externo configurado en la base documental --%>
  <c:if test="${calendario.rowCount > 0 and (fn:startsWith(calendario.rows[0].url, 'https://') or fn:startsWith(calendario.rows[0].url, 'http://'))}">
    <div class="col-12 col-md-6 col-xl-4">
      <a class="tarjeta tarjeta-modulo" href="<c:out value='${calendario.rows[0].url}' />" target="_blank" rel="noopener noreferrer">
        <span class="icono-caja"><i class="bi bi-calendar-event"></i></span>
        <h3>Calendario académico <i class="bi bi-box-arrow-up-right fs-6 text-secondary"></i></h3>
        <p>Consulta las fechas del semestre.</p>
      </a>
    </div>
  </c:if>
</div>

<c:if test="${sessionScope.rol == 'ADMINISTRADOR' and pendientesCuenta.rows[0].total > 0}">
  <div class="tarjeta d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
    <div class="d-flex align-items-center gap-3">
      <span class="resumen-icono pendiente"><i class="bi bi-clock"></i></span>
      <div><span class="fw-bold"><c:out value="${pendientesCuenta.rows[0].total}" /> solicitud(es) de cuenta pendiente(s)</span><div class="texto-sec">Estudiantes esperando aprobación.</div></div>
    </div>
    <a class="btn btn-uts" href="${ctx}/modulos/usuarios/cuentas_pendientes.jsp">Ver solicitudes</a>
  </div>
</c:if>

<c:choose>
  <c:when test="${notifCount > 0}">
    <div class="tarjeta d-flex flex-wrap align-items-center justify-content-between gap-3">
      <div><span class="fw-bold">Tienes <c:out value="${notifCount}" /> notificación(es) sin leer.</span></div>
      <a class="btn btn-outline-uts" href="${ctx}/modulos/notificaciones/notificaciones.jsp">Ver notificaciones</a>
    </div>
  </c:when>
  <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-file-earmark"></i></span>
      <h3>Aún no hay revisiones nuevas</h3>
      <p>Cuando tu director revise un documento, lo verás aquí.</p>
    </div>
  </c:when>
</c:choose>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

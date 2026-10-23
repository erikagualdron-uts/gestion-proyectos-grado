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
    <c:set var="tarjetas" value="bi-lightbulb|Banco de ideas|Explora las ideas aprobadas por los docentes y elige una.|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Mis propuestas|Registra o corrige tu propuesta y accede a tu seguimiento, historial y PQRS.|/modulos/propuestas/propuestas_banco.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp;bi-person|Mi perfil|Revisa y actualiza tus datos personales.|/modulos/perfil/perfil.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'DOCENTE'}">
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para docentes." />
    <c:set var="tarjetas" value="bi-lightbulb|Banco de ideas|Consulta las ideas aprobadas y propón nuevas ideas.|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Propuestas Banco|Consulta las propuestas de los estudiantes.|/modulos/propuestas/propuestas_banco.jsp;bi-person-check|Docente Director|Proyectos que diriges: revisa y califica documentos.|/modulos/docente_director/docente_director.jsp;bi-clipboard-check|Docente Evaluador|Proyectos que evalúas: revisa y decide en tus fases.|/modulos/docente_evaluador/docente_evaluador.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp;bi-person|Mi perfil|Revisa y actualiza tus datos personales.|/modulos/perfil/perfil.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'COORDINADOR'}">
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para la coordinación." />
    <c:set var="tarjetas" value="bi-file-earmark-text|Propuestas Banco|Decide sobre ideas de docentes y propuestas de estudiantes.|/modulos/propuestas/propuestas_banco.jsp;bi-people|Asignación de proyectos|Asigna director y evaluador a cada proyecto aprobado.|/modulos/proyectos/asignacion.jsp;bi-chat|PQRS|Resuelve las solicitudes radicadas por los estudiantes.|/modulos/pqrs/pqrs.jsp;bi-bar-chart|Panel de control|Gráficos y avance de los proyectos.|/modulos/informes/informe_coordinador.jsp;bi-lightbulb|Banco de ideas|Consulta las ideas aprobadas por los docentes.|/modulos/banco_ideas/banco_ideas.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp" />
  </c:when>
  <c:otherwise>
    <c:set var="descripcionInicio" value="Resumen de las cuentas y de la base documental." />
  </c:otherwise>
</c:choose>

<%-- Proyecto del estudiante (si ya tiene uno) --%>
<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <sql:query var="proyecto" dataSource="${bd}">
    SELECT p.id_proyecto, p.estado_general, f.numero, f.nombre AS fase, pf.estado, d.nombre_completo AS director, ev.nombre_completo AS evaluador
    FROM propuesta_estudiante pe
    JOIN proyecto p ON p.id_propuesta = pe.id_propuesta
    JOIN fase f ON f.id_fase = p.fase_actual
    LEFT JOIN usuario d ON d.id_usuario = p.id_director
    LEFT JOIN usuario ev ON ev.id_usuario = p.id_evaluador
    LEFT JOIN proyecto_fase pf ON pf.id_proyecto = p.id_proyecto AND pf.id_fase = p.fase_actual
    WHERE pe.id_estudiante = ?
    ORDER BY p.id_proyecto DESC LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:if>

<sql:query var="calendario" dataSource="${bd}">
  SELECT url FROM enlace_documental WHERE nombre LIKE 'Calendario%' AND activo = 1 ORDER BY orden LIMIT 1
</sql:query>

<%-- Administrador: resumen de cuentas y enlaces por configurar --%>
<c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
  <sql:query var="resumenAdmin" dataSource="${bd}">
    SELECT COALESCE(SUM(r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE'), 0) AS pendientes,
           COALESCE(SUM(r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'APROBADA'), 0) AS estudiantes,
           COALESCE(SUM(r.nombre = 'DOCENTE' AND u.estado_cuenta = 'APROBADA'), 0) AS docentes
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE u.activo = 1
  </sql:query>
  <sql:query var="enlacesPendientes" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM enlace_documental WHERE activo = 1 AND (url = '#' OR url = '')
  </sql:query>
  <c:set var="ra" value="${resumenAdmin.rows[0]}" />
</c:if>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Hola, <c:out value="${sessionScope.primerNombre}" /></h1>
<p class="descripcion-pagina"><c:out value="${descripcionInicio}" /></p>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and proyecto.rowCount > 0}">
  <c:set var="py" value="${proyecto.rows[0]}" />
  <div class="tarjeta d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
    <div>
      <div class="etiqueta-sup">Tu proyecto</div>
      <div class="fw-bold fs-5 titulo"><c:choose><c:when test="${py.estado_general == 'APTO_GRADUACION'}">Todas las fases aprobadas</c:when><c:otherwise>Fase <c:out value="${py.numero}" /> · <c:out value="${py.fase}" /></c:otherwise></c:choose></div>
      <div class="texto-sec mt-1">
        <i class="bi bi-person-check me-1"></i>Director: <strong><c:out value="${empty py.director ? 'Por asignar' : py.director}" /></strong>
        <span class="mx-1">·</span>
        <i class="bi bi-clipboard-check me-1"></i>Evaluador: <strong><c:out value="${empty py.evaluador ? 'Por asignar' : py.evaluador}" /></strong>
      </div>
    </div>
    <div class="d-flex flex-wrap align-items-center gap-3">
      <c:choose>
        <c:when test="${py.estado_general == 'APTO_GRADUACION'}"><span class="insignia insignia-aprobado">Listo para sustentación</span></c:when>
        <c:when test="${py.estado_general == 'CERRADO'}"><span class="insignia insignia-rechazado">Proyecto cerrado</span></c:when>
        <c:when test="${py.estado == 'APROBADA'}"><span class="insignia insignia-aprobado">Aprobado</span></c:when>
        <c:when test="${py.estado == 'APLAZADA'}"><span class="insignia insignia-aplazado">Aplazado · corregir y reenviar</span></c:when>
        <c:when test="${py.estado == 'RECHAZADA'}"><span class="insignia insignia-rechazado">Rechazado</span></c:when>
        <c:otherwise><span class="insignia insignia-pendiente">En curso</span></c:otherwise>
      </c:choose>
      <a class="btn btn-outline-uts" href="${ctx}/modulos/pqrs/pqrs.jsp"><i class="bi bi-chat me-1"></i>PQRS</a>
      <a class="btn btn-uts" href="${ctx}/modulos/proyectos/seguimiento.jsp?id=${py.id_proyecto}">Ver seguimiento</a>
    </div>
  </div>
</c:if>

<c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none" href="${ctx}/modulos/usuarios/cuentas_pendientes.jsp"><span class="resumen-icono pendiente"><i class="bi bi-person-check"></i></span><div><div class="resumen-numero"><c:out value="${ra.pendientes}" /></div><div class="resumen-etiqueta">Cuentas por aprobar</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none" href="${ctx}/modulos/usuarios/usuarios.jsp"><span class="resumen-icono aprobado"><i class="bi bi-mortarboard"></i></span><div><div class="resumen-numero"><c:out value="${ra.estudiantes}" /></div><div class="resumen-etiqueta">Estudiantes activos</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none" href="${ctx}/modulos/usuarios/usuarios.jsp"><span class="resumen-icono aprobado"><i class="bi bi-person-workspace"></i></span><div><div class="resumen-numero"><c:out value="${ra.docentes}" /></div><div class="resumen-etiqueta">Docentes activos</div></div></a></div>
  <div class="col-6 col-xl-3"><a class="tarjeta resumen text-decoration-none" href="${ctx}/modulos/base_documental/base_documental.jsp"><span class="resumen-icono aplazado"><i class="bi bi-link-45deg"></i></span><div><div class="resumen-numero"><c:out value="${enlacesPendientes.rows[0].total}" /></div><div class="resumen-etiqueta">Enlaces sin configurar</div></div></a></div>
</div>
</c:if>

<c:if test="${sessionScope.rol != 'ADMINISTRADOR'}">
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

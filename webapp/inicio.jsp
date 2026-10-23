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
    <c:set var="tarjetas" value="bi-lightbulb|Banco de ideas|Explora las ideas aprobadas por los docentes y elige una.|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Mis propuestas|Registra o corrige tu propuesta y accede a tu seguimiento.|/modulos/propuestas/propuestas_banco.jsp;bi-chat|PQRS|Radica una prórroga, cambio de director, petición, queja, reclamo o sugerencia y consulta su respuesta.|/modulos/pqrs/pqrs.jsp;bi-journal-text|Base documental|Calendario, formatos y reglamentos de la universidad.|/modulos/base_documental/base_documental.jsp" />
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
    <c:set var="descripcionInicio" value="Estos son los módulos disponibles para la administración." />
    <c:set var="tarjetas" value="bi-people|Usuarios|Crea y administra coordinadores, docentes y administradores.|/modulos/usuarios/usuarios.jsp;bi-person-check|Solicitudes de cuenta|Aprueba o rechaza las cuentas de estudiantes.|/modulos/usuarios/cuentas_pendientes.jsp;bi-journal-text|Base documental|Administra los enlaces de la base documental.|/modulos/base_documental/base_documental.jsp" />
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

<%-- Administrador: avisos de las tarjetas (cuentas por aprobar y enlaces sin configurar) --%>
<c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
  <sql:query var="resumenAdmin" dataSource="${bd}">
    SELECT COUNT(*) AS pendientes FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE' AND u.activo = 1
  </sql:query>
  <sql:query var="enlacesPendientes" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM enlace_documental WHERE activo = 1 AND (url = '#' OR url = '')
  </sql:query>
  <c:set var="ra" value="${resumenAdmin.rows[0]}" />
</c:if>

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Hola, <c:out value="${sessionScope.primerNombre}" /></h1>
<p class="descripcion-pagina"><c:out value="${descripcionInicio}" /></p>

<c:if test="${notifCount > 0}">
  <div class="tarjeta d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3 py-3">
    <div><i class="bi bi-bell me-2"></i><span class="fw-bold">Tienes <c:out value="${notifCount}" /> notificación(es) sin leer.</span></div>
    <a class="btn btn-outline-uts btn-sm" href="${ctx}/modulos/notificaciones/notificaciones.jsp">Ver notificaciones</a>
  </div>
</c:if>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and proyecto.rowCount > 0}">
  <c:set var="py" value="${proyecto.rows[0]}" />
  <c:set var="faseListo" value="${py.estado_general == 'APTO_GRADUACION'}" />
  <div class="tarjeta mb-4">
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-3">
    <div>
      <div class="etiqueta-sup">Tu proyecto</div>
      <div class="fw-bold fs-5 titulo"><c:choose><c:when test="${py.estado_general == 'APTO_GRADUACION'}">Listo para sustentación</c:when><c:otherwise>Fase <c:out value="${py.numero}" /> · <c:out value="${py.fase}" /></c:otherwise></c:choose></div>
      <div class="texto-sec mt-1">
        <i class="bi bi-person-check me-1"></i>Director: <strong><c:out value="${empty py.director ? 'Sin asignar' : py.director}" /></strong>
        <span class="mx-1">·</span>
        <i class="bi bi-clipboard-check me-1"></i>Evaluador: <strong><c:out value="${empty py.evaluador ? 'Sin asignar' : py.evaluador}" /></strong>
      </div>
    </div>
    <div class="d-flex flex-wrap align-items-center gap-3">
      <c:choose>
        <c:when test="${py.estado_general == 'APTO_GRADUACION'}"><span class="insignia insignia-aprobado"><i class="bi bi-check-circle me-1"></i>Todas las fases aprobadas</span></c:when>
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
  <div class="progreso-fases mt-3" role="img" aria-label="Avance: ${faseListo ? 6 : py.numero} de 6 fases">
    <c:forEach var="n" begin="1" end="6"><span class="paso ${faseListo or n < py.numero or (n == py.numero and py.estado == 'APROBADA') ? 'hecho' : (n == py.numero ? 'actual' : '')}"></span></c:forEach>
  </div>
  <div class="texto-sec small mt-2"><c:choose><c:when test="${faseListo}">6 de 6 fases aprobadas</c:when><c:otherwise>Fase <c:out value="${py.numero}" /> de 6</c:otherwise></c:choose></div>
  </div>
</c:if>

<c:set var="hayCalendario" value="${calendario.rowCount > 0 and (fn:startsWith(calendario.rows[0].url, 'https://') or fn:startsWith(calendario.rows[0].url, 'http://'))}" />
<c:set var="columnasTarjeta" value="${fn:length(fn:split(tarjetas, ';')) + (hayCalendario ? 1 : 0) == 4 ? 'col-xl-3' : 'col-xl-4'}" />
<div class="row g-3 mb-4">
  <c:forEach var="tarjeta" items="${fn:split(tarjetas, ';')}">
    <c:set var="p" value="${fn:split(tarjeta, '|')}" />
    <div class="col-12 col-md-6 ${columnasTarjeta}">
      <a class="tarjeta tarjeta-modulo" href="${ctx}${p[3]}">
        <span class="icono-caja"><i class="bi ${p[0]}"></i></span>
        <h3><c:out value="${p[1]}" /></h3>
        <p><c:out value="${p[2]}" /></p>
        <c:if test="${sessionScope.rol == 'ADMINISTRADOR' and p[1] == 'Solicitudes de cuenta'}">
          <c:choose>
            <c:when test="${ra.pendientes > 0}"><span class="insignia insignia-pendiente mt-3"><c:out value="${ra.pendientes}" /> por aprobar</span></c:when>
            <c:otherwise><span class="insignia insignia-aprobado mt-3">Al día</span></c:otherwise>
          </c:choose>
        </c:if>
        <c:if test="${sessionScope.rol == 'ADMINISTRADOR' and p[1] == 'Base documental' and enlacesPendientes.rows[0].total > 0}">
          <span class="insignia insignia-aplazado mt-3"><c:out value="${enlacesPendientes.rows[0].total}" /> enlace(s) sin configurar</span>
        </c:if>
      </a>
    </div>
  </c:forEach>
  <%-- Calendario académico (RF-18): abre el enlace externo configurado en la base documental --%>
  <c:if test="${calendario.rowCount > 0 and (fn:startsWith(calendario.rows[0].url, 'https://') or fn:startsWith(calendario.rows[0].url, 'http://'))}">
    <div class="col-12 col-md-6 ${columnasTarjeta}">
      <a class="tarjeta tarjeta-modulo" href="<c:out value='${calendario.rows[0].url}' />" target="_blank" rel="noopener noreferrer">
        <span class="icono-caja"><i class="bi bi-calendar-event"></i></span>
        <h3>Calendario académico <i class="bi bi-box-arrow-up-right fs-6 text-secondary"></i></h3>
        <p>Consulta las fechas del semestre.</p>
      </a>
    </div>
  </c:if>
</div>

<c:if test="${sessionScope.rol == 'ESTUDIANTE' and notifCount == 0}">
  <div class="vacio">
    <span class="icono-circulo"><i class="bi bi-file-earmark"></i></span>
    <h3>Aún no hay revisiones nuevas</h3>
    <p>Cuando tu director revise un documento, lo verás aquí.</p>
  </div>
</c:if>

<jsp:include page="/WEB-INF/includes/pie.jsp" />

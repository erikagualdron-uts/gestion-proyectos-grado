<%-- Filtros y consulta comunes de la bitácora de auditoría (informe_coordinador.jsp e informe_excel.jsp).
     Define: aDesde, aHasta, aUsuario, aEntidad, aAccion, aq, aqLike, el fragmento casoAccion y los textos SQL
     desdeAuditoria y columnasAuditoria.
     Parámetros de desdeAuditoria, en orden: desde x2, hasta x2, usuario x2, entidad x2, acción x2, aq, aqLike x3. --%>
<c:set var="aq" value="${fn:trim(param.aq)}" />
<c:set var="aqLike" value="%${aq}%" />
<c:set var="aDesde" value="${not empty param.desde and param.desde.matches('\\d{4}-\\d{2}-\\d{2}') ? param.desde : ''}" />
<c:set var="aHasta" value="${not empty param.hasta and param.hasta.matches('\\d{4}-\\d{2}-\\d{2}') ? param.hasta : ''}" />
<c:catch var="errorUsuarioAud"><c:set var="aUsuario" value="${empty param.usuario ? 0 : param.usuario + 0}" /></c:catch>
<c:if test="${not empty errorUsuarioAud or aUsuario < 0}"><c:set var="aUsuario" value="${0}" /></c:if>
<c:set var="aEntidad" value="${fn:contains(',USUARIO,IDEA,PROPUESTA,PROYECTO,FASE,DOCUMENTO,PQRS,', ',' += param.entidad += ',') ? param.entidad : ''}" />
<c:set var="aAccion" value="${not empty param.accion and param.accion.matches('[A-Z_]{1,40}') ? param.accion : ''}" />

<c:set var="casoAccion">
  CASE h.accion WHEN 'CREAR' THEN 'Creación' WHEN 'REGISTRO' THEN 'Registro de cuenta' WHEN 'EDITAR' THEN 'Edición de datos'
    WHEN 'EDITAR_PERFIL' THEN 'Perfil editado' WHEN 'CAMBIAR_CLAVE' THEN 'Cambio de contraseña' WHEN 'INACTIVAR' THEN 'Inactivación'
    WHEN 'REACTIVAR' THEN 'Reactivación' WHEN 'DECIDIR' THEN 'Decisión' WHEN 'REENVIAR' THEN 'Reenvío corregido'
    WHEN 'RESERVAR' THEN 'Idea reservada' WHEN 'ASIGNAR' THEN 'Asignación de director y evaluador' WHEN 'ENTREGAR' THEN 'Entrega de documento'
    WHEN 'REVISAR' THEN 'Revisión' WHEN 'EDITAR_REVISION' THEN 'Revisión editada' WHEN 'APROBAR_FASE' THEN 'Fase aprobada'
    WHEN 'APLAZAR_FASE' THEN 'Fase aplazada' WHEN 'CERRAR_PROYECTO' THEN 'Proyecto cerrado' WHEN 'APTO_GRADUACION' THEN 'Listo para sustentación'
    WHEN 'RADICAR' THEN 'PQRS radicada' WHEN 'RESOLVER' THEN 'PQRS resuelta' WHEN 'CAMBIAR_DIRECTOR' THEN 'Cambio de director'
    WHEN 'APROBAR' THEN 'Cuenta aprobada' WHEN 'RECHAZAR' THEN 'Cuenta rechazada' ELSE h.accion END
</c:set>
<c:set var="referenciaAud">
  CASE h.entidad
    WHEN 'PQRS' THEN (SELECT q2.codigo FROM pqrs q2 WHERE q2.id_pqrs = h.id_entidad)
    WHEN 'IDEA' THEN (SELECT i2.codigo FROM idea_banco i2 WHERE i2.id_idea = h.id_entidad)
    WHEN 'USUARIO' THEN (SELECT u2.nombre_completo FROM usuario u2 WHERE u2.id_usuario = h.id_entidad)
    WHEN 'PROPUESTA' THEN (SELECT pp2.codigo FROM propuesta pp2 WHERE pp2.id_propuesta = h.id_entidad)
    ELSE (SELECT pp3.codigo FROM proyecto pr3 JOIN propuesta pp3 ON pp3.id_propuesta = pr3.id_propuesta WHERE pr3.id_proyecto = h.id_proyecto)
  END
</c:set>
<c:set var="desdeAuditoria">
  FROM historial_version h
  JOIN usuario u ON u.id_usuario = h.id_usuario
  JOIN rol r ON r.id_rol = u.id_rol
  WHERE (? = '' OR h.fecha_evento >= ?)
    AND (? = '' OR h.fecha_evento < DATE_ADD(?, INTERVAL 1 DAY))
    AND (? = 0 OR h.id_usuario = ?)
    AND (? = '' OR h.entidad = ?)
    AND (? = '' OR h.accion = ?)
    AND (? = '' OR h.detalle LIKE ? OR u.nombre_completo LIKE ? OR (${referenciaAud}) LIKE ?)
</c:set>
<c:set var="columnasAuditoria">
  h.id_historial, h.id_proyecto, h.entidad, h.estado_anterior, h.estado_nuevo, h.version_num, h.detalle,
  DATE_FORMAT(h.fecha_evento, '%d/%m/%Y %H:%i') AS fecha, u.nombre_completo AS usuario,
  CASE r.nombre WHEN 'ADMINISTRADOR' THEN 'Administrador' WHEN 'COORDINADOR' THEN 'Coordinador' WHEN 'DOCENTE' THEN 'Docente' ELSE 'Estudiante' END AS rol_texto,
  CASE h.entidad WHEN 'USUARIO' THEN 'Usuario' WHEN 'IDEA' THEN 'Idea' WHEN 'PROPUESTA' THEN 'Propuesta' WHEN 'PROYECTO' THEN 'Proyecto'
    WHEN 'FASE' THEN 'Fase' WHEN 'DOCUMENTO' THEN 'Documento' ELSE 'PQRS' END AS entidad_texto,
  ${casoAccion} AS accion_texto,
  ${referenciaAud} AS referencia
</c:set>

-- Datos de PRUEBA para demostración. No usar en producción. Personas ficticias.
-- Contraseña de todas las cuentas de prueba: Prueba2026*
-- Ejecutar después de schema.sql y datos_iniciales.sql.
SET NAMES utf8mb4;

INSERT INTO usuario (id_rol, tipo_documento, numero_documento, nombre_completo, correo,
                     contrasena_hash, sal, nivel, estado_cuenta, id_aprobador, fecha_decision) VALUES
  ((SELECT id_rol FROM rol WHERE nombre = 'COORDINADOR'), 'CC', '1000000001', 'María Rojas Prueba',
   'coordinador.prueba@correo.uts.edu.co', SHA2(CONCAT('a1b2c3d4e5f60718', 'Prueba2026*'), 256), 'a1b2c3d4e5f60718',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'DOCENTE'), 'CC', '1000000002', 'Carlos Docente Uno',
   'docente1.prueba@correo.uts.edu.co', SHA2(CONCAT('b2c3d4e5f6071829', 'Prueba2026*'), 256), 'b2c3d4e5f6071829',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'DOCENTE'), 'CC', '1000000003', 'Laura Docente Dos',
   'docente2.prueba@correo.uts.edu.co', SHA2(CONCAT('c3d4e5f60718293a', 'Prueba2026*'), 256), 'c3d4e5f60718293a',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'ESTUDIANTE'), 'CC', '1000000004', 'Erika Estudiante Prueba',
   'estudiante.prueba@uts.edu.co', SHA2(CONCAT('d4e5f60718293a4b', 'Prueba2026*'), 256), 'd4e5f60718293a4b',
   'TECNOLOGICO', 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'ESTUDIANTE'), 'CC', '1000000005', 'Camilo Pendiente Prueba',
   'pendiente.prueba@uts.edu.co', SHA2(CONCAT('e5f60718293a4b5c', 'Prueba2026*'), 256), 'e5f60718293a4b5c',
   NULL, 'PENDIENTE', NULL, NULL);

SET @coordinador := (SELECT id_usuario FROM usuario WHERE correo = 'coordinador.prueba@correo.uts.edu.co');
SET @docente1    := (SELECT id_usuario FROM usuario WHERE correo = 'docente1.prueba@correo.uts.edu.co');
SET @docente2    := (SELECT id_usuario FROM usuario WHERE correo = 'docente2.prueba@correo.uts.edu.co');
SET @estudiante  := (SELECT id_usuario FROM usuario WHERE correo = 'estudiante.prueba@uts.edu.co');

-- Dos ideas aprobadas del banco
INSERT INTO idea_banco (codigo, id_docente, titulo, descripcion, objetivo, alcance, estado_decision, id_revisor, disponible, fecha_decision) VALUES
  ('ID-0001', @docente1, 'Sistema web para el control de inventario de laboratorios',
   'Aplicación web para registrar y consultar los equipos de los laboratorios.',
   'Controlar el préstamo y el estado de los equipos.', 'Módulos de inventario, préstamos y reportes.',
   'APROBADO', @coordinador, 0, NOW()),
  ('ID-0002', @docente2, 'Aplicación móvil para el reporte de residuos en el campus',
   'Aplicación para reportar puntos críticos de residuos en el campus.',
   'Facilitar el reporte y seguimiento de residuos.', 'Reporte con foto, mapa y seguimiento.',
   'APROBADO', @coordinador, 1, NOW());

-- Una propuesta aprobada (tomada de la idea ID-0001) y su proyecto en Fase 2 (Propuesta I) aplazada
INSERT INTO propuesta (codigo, id_idea, origen, titulo, descripcion, objetivo, alcance, estado_decision, id_revisor, fecha_decision)
VALUES ('PG-0001', (SELECT id_idea FROM idea_banco WHERE codigo = 'ID-0001'), 'BANCO',
        'Sistema web para el control de inventario de laboratorios',
        'Aplicación web para registrar y consultar los equipos de los laboratorios.',
        'Controlar el préstamo y el estado de los equipos.', 'Módulos de inventario, préstamos y reportes.',
        'APROBADO', @coordinador, NOW());
SET @propuesta := (SELECT id_propuesta FROM propuesta WHERE codigo = 'PG-0001');

INSERT INTO propuesta_estudiante (id_propuesta, id_estudiante, es_responsable) VALUES (@propuesta, @estudiante, 1);

INSERT INTO proyecto (id_propuesta, id_director, id_evaluador, fase_actual, estado_general, fecha_inicio)
VALUES (@propuesta, @docente1, @docente2, 2, 'EN_CURSO', CURDATE());
SET @proyecto := (SELECT id_proyecto FROM proyecto WHERE id_propuesta = @propuesta);

INSERT INTO proyecto_fase (id_proyecto, id_fase, estado, fecha_inicio, fecha_fin) VALUES
  (@proyecto, 1, 'APROBADA', NOW(), NOW()),
  (@proyecto, 2, 'APLAZADA', NOW(), NULL),
  (@proyecto, 3, 'PENDIENTE', NULL, NULL),
  (@proyecto, 4, 'PENDIENTE', NULL, NULL),
  (@proyecto, 5, 'PENDIENTE', NULL, NULL),
  (@proyecto, 6, 'PENDIENTE', NULL, NULL);

-- Comprobante de pago de la Fase 1, ya validado por el coordinador (dato de ejemplo)
SET @pf1 := (SELECT id_proyecto_fase FROM proyecto_fase WHERE id_proyecto = @proyecto AND id_fase = 1);
INSERT INTO documento (id_proyecto_fase, nombre, version_num, enlace_url, id_subido_por, vigente, comentario)
VALUES (@pf1, 'Comprobante de pago', 1, 'https://example.com/comprobante-pago-ejemplo', @estudiante, 1, 'Comprobante de ejemplo');
INSERT INTO revision (id_proyecto_fase, id_documento, id_revisor, rol_revisor, decision, observaciones)
VALUES (@pf1, (SELECT id_documento FROM documento WHERE id_proyecto_fase = @pf1 AND nombre = 'Comprobante de pago' AND version_num = 1),
        @coordinador, 'COMITE', 'APROBADO', NULL);

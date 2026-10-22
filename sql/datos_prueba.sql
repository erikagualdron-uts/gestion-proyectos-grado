-- Datos de PRUEBA para demostración. No usar en producción. Personas ficticias.
-- Contraseña de todas las cuentas de prueba: Prueba2026*
-- Ejecutar después de schema.sql y datos_iniciales.sql.
SET NAMES utf8mb4;

INSERT INTO usuario (id_rol, tipo_documento, numero_documento, nombre_completo, correo,
                     contrasena_hash, sal, nivel, estado_cuenta, id_aprobador, fecha_decision) VALUES
  ((SELECT id_rol FROM rol WHERE nombre = 'COORDINADOR'), 'CC', '1000000001', 'María Rojas Prueba',
   'coordinador.prueba@uts.edu.co', SHA2(CONCAT('a1b2c3d4e5f60718', 'Prueba2026*'), 256), 'a1b2c3d4e5f60718',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'DOCENTE'), 'CC', '1000000002', 'Carlos Director Prueba',
   'director.prueba@uts.edu.co', SHA2(CONCAT('b2c3d4e5f6071829', 'Prueba2026*'), 256), 'b2c3d4e5f6071829',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'DOCENTE'), 'CC', '1000000003', 'Laura Evaluadora Prueba',
   'evaluador.prueba@uts.edu.co', SHA2(CONCAT('c3d4e5f60718293a', 'Prueba2026*'), 256), 'c3d4e5f60718293a',
   NULL, 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'ESTUDIANTE'), 'CC', '1000000004', 'Erika Estudiante Prueba',
   'estudiante.prueba@correo.uts.edu.co', SHA2(CONCAT('d4e5f60718293a4b', 'Prueba2026*'), 256), 'd4e5f60718293a4b',
   'TECNOLOGICO', 'APROBADA', NULL, NOW()),
  ((SELECT id_rol FROM rol WHERE nombre = 'ESTUDIANTE'), 'CC', '1000000005', 'Camilo Pendiente Prueba',
   'pendiente.prueba@correo.uts.edu.co', SHA2(CONCAT('e5f60718293a4b5c', 'Prueba2026*'), 256), 'e5f60718293a4b5c',
   NULL, 'PENDIENTE', NULL, NULL);

SET @coordinador := (SELECT id_usuario FROM usuario WHERE correo = 'coordinador.prueba@uts.edu.co');
SET @director    := (SELECT id_usuario FROM usuario WHERE correo = 'director.prueba@uts.edu.co');
SET @evaluador   := (SELECT id_usuario FROM usuario WHERE correo = 'evaluador.prueba@uts.edu.co');
SET @estudiante  := (SELECT id_usuario FROM usuario WHERE correo = 'estudiante.prueba@correo.uts.edu.co');

-- Dos ideas aprobadas del banco
INSERT INTO idea_banco (codigo, id_docente, titulo, descripcion, objetivo, alcance, estado_decision, id_revisor, disponible, fecha_decision) VALUES
  ('ID-0001', @director, 'Sistema web para el control de inventario de laboratorios',
   'Aplicación web para registrar y consultar los equipos de los laboratorios.',
   'Controlar el préstamo y el estado de los equipos.', 'Módulos de inventario, préstamos y reportes.',
   'APROBADO', @coordinador, 0, NOW()),
  ('ID-0002', @evaluador, 'Aplicación móvil para el reporte de residuos en el campus',
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
VALUES (@propuesta, @director, @evaluador, 2, 'EN_CURSO', CURDATE());
SET @proyecto := (SELECT id_proyecto FROM proyecto WHERE id_propuesta = @propuesta);

INSERT INTO proyecto_fase (id_proyecto, id_fase, estado, fecha_inicio, fecha_fin) VALUES
  (@proyecto, 1, 'APROBADA', NOW(), NOW()),
  (@proyecto, 2, 'APLAZADA', NOW(), NULL),
  (@proyecto, 3, 'PENDIENTE', NULL, NULL),
  (@proyecto, 4, 'PENDIENTE', NULL, NULL),
  (@proyecto, 5, 'PENDIENTE', NULL, NULL),
  (@proyecto, 6, 'PENDIENTE', NULL, NULL);

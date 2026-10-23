SET NAMES utf8mb4;
-- Datos iniciales
INSERT INTO rol (nombre, descripcion) VALUES
  ('ADMINISTRADOR','Comité: gestiona usuarios'),
  ('COORDINADOR','Comité: aprueba y asigna'),
  ('ESTUDIANTE','Desarrolla el trabajo de grado'),
  ('DOCENTE','Puede ser director y evaluador');
INSERT INTO fase (id_fase, numero, nombre, descripcion) VALUES
  (1,1,'Pago','El estudiante sube el comprobante; se notifica al comité'),
  (2,2,'Propuesta I','El estudiante envía el anteproyecto al director'),
  (3,3,'Propuesta II','El director envía la propuesta al evaluador y al comité'),
  (4,4,'Informe I','El estudiante envía el informe al director'),
  (5,5,'Informe II','El director envía el informe al evaluador y al comité'),
  (6,6,'Revisión final','Evaluador y comité aprueban o aplazan');
INSERT INTO enlace_documental (nombre, descripcion, url, icono, orden) VALUES
  ('Calendario académico','Fechas del semestre','#','bi-calendar-event',1),
  ('Formatos institucionales','Formatos de grado','#','bi-file-earmark-text',2),
  ('Presentación de propuesta','Guía para la propuesta','#','bi-easel',3),
  ('Presentación de informe final','Guía del informe final','#','bi-mortarboard',4),
  ('Reglamento de estímulos','Estímulos para trabajos de grado','#','bi-award',5),
  ('Reglamento de trabajos de grado','Reglamento vigente','#','bi-journal-text',6);
-- Administrador inicial (cambiar la contraseña tras el primer ingreso)
INSERT INTO usuario (id_rol, tipo_documento, numero_documento, nombre_completo,
                     correo, contrasena_hash, sal, estado_cuenta)
VALUES (1,'CC','1000000000','Administrador del sistema','admin@correo.uts.edu.co',
        SHA2(CONCAT('3f9a1c7e5b2d4a60','CambiarClave*1'),256),'3f9a1c7e5b2d4a60','APROBADA');

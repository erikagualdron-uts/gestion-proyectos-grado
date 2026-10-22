-- Sistema de Gestión de Proyectos de Grado - MySQL 8.x (la base la crea Clever Cloud; no incluye CREATE DATABASE)
SET NAMES utf8mb4;
CREATE TABLE rol (
  id_rol TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(30) NOT NULL,
  descripcion VARCHAR(120) NULL,
  PRIMARY KEY (id_rol),
  UNIQUE KEY uq_rol_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE usuario (
  id_usuario INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_rol TINYINT UNSIGNED NOT NULL,
  tipo_documento ENUM('CC','TI','CE','PASAPORTE','OTRO') NOT NULL DEFAULT 'CC',
  numero_documento VARCHAR(20) NOT NULL,
  nombre_completo VARCHAR(120) NOT NULL,
  correo VARCHAR(120) NOT NULL,
  contrasena_hash CHAR(64) NOT NULL,
  sal CHAR(32) NOT NULL,
  foto_url VARCHAR(300) NULL,
  nivel ENUM('TECNOLOGICO','PROFESIONAL') NULL,
  estado_cuenta ENUM('PENDIENTE','APROBADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  activo TINYINT(1) NOT NULL DEFAULT 1,
  id_aprobador INT UNSIGNED NULL,
  fecha_decision DATETIME NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuario_numero_documento (numero_documento),
  UNIQUE KEY uq_usuario_correo (correo),
  CONSTRAINT ck_usuario_nivel CHECK (estado_cuenta <> 'RECHAZADA' OR nivel IS NULL),
  CONSTRAINT fk_usuario_id_rol
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
  CONSTRAINT fk_usuario_id_aprobador
    FOREIGN KEY (id_aprobador) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE sesion_persistente (
  id_sesion INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expira DATETIME NOT NULL,
  PRIMARY KEY (id_sesion),
  UNIQUE KEY uq_sesion_persistente_token_hash (token_hash),
  CONSTRAINT fk_sesion_persistente_id_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE idea_banco (
  id_idea INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(15) NOT NULL,
  id_docente INT UNSIGNED NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  descripcion TEXT NOT NULL,
  objetivo TEXT NULL,
  alcance TEXT NULL,
  estado_decision ENUM('PENDIENTE','APROBADO','APLAZADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
  observacion TEXT NULL,
  id_revisor INT UNSIGNED NULL,
  disponible TINYINT(1) NOT NULL DEFAULT 1,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_decision DATETIME NULL,
  PRIMARY KEY (id_idea),
  UNIQUE KEY uq_idea_banco_codigo (codigo),
  CONSTRAINT fk_idea_banco_id_docente
    FOREIGN KEY (id_docente) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_idea_banco_id_revisor

    FOREIGN KEY (id_revisor) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE propuesta (
  id_propuesta INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(15) NOT NULL,
  id_idea INT UNSIGNED NULL,
  origen ENUM('BANCO','PROPIA') NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  descripcion TEXT NOT NULL,
  objetivo TEXT NOT NULL,
  alcance TEXT NOT NULL,
  estado_decision ENUM('PENDIENTE','APROBADO','APLAZADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
  observacion TEXT NULL,
  id_revisor INT UNSIGNED NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_decision DATETIME NULL,
  PRIMARY KEY (id_propuesta),
  UNIQUE KEY uq_propuesta_codigo (codigo),
  UNIQUE KEY uq_propuesta_id_idea (id_idea),
  CONSTRAINT fk_propuesta_id_idea
    FOREIGN KEY (id_idea) REFERENCES idea_banco(id_idea),
  CONSTRAINT fk_propuesta_id_revisor
    FOREIGN KEY (id_revisor) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE propuesta_estudiante (
  id_propuesta INT UNSIGNED NOT NULL,
  id_estudiante INT UNSIGNED NOT NULL,
  es_responsable TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id_propuesta, id_estudiante),
  CONSTRAINT fk_propuesta_estudiante_id_propuesta
    FOREIGN KEY (id_propuesta) REFERENCES propuesta(id_propuesta) ON DELETE CASCADE,
  CONSTRAINT fk_propuesta_estudiante_id_estudiante
    FOREIGN KEY (id_estudiante) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE fase (
  id_fase TINYINT UNSIGNED NOT NULL,
  numero TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(40) NOT NULL,
  descripcion VARCHAR(200) NULL,
  PRIMARY KEY (id_fase),
  UNIQUE KEY uq_fase_numero (numero)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE proyecto (
  id_proyecto INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_propuesta INT UNSIGNED NOT NULL,
  id_director INT UNSIGNED NULL,
  id_evaluador INT UNSIGNED NULL,
  fase_actual TINYINT UNSIGNED NOT NULL DEFAULT 1,
  estado_general ENUM('EN_CURSO','APTO_GRADUACION','CERRADO') NOT NULL DEFAULT 'EN_CURSO',
  fecha_inicio DATE NOT NULL,
  PRIMARY KEY (id_proyecto),
  UNIQUE KEY uq_proyecto_id_propuesta (id_propuesta),
  CONSTRAINT ck_proyecto_dir_eval
    CHECK (id_director IS NULL OR id_evaluador IS NULL OR id_director <> id_evaluador),
  CONSTRAINT fk_proyecto_id_propuesta
    FOREIGN KEY (id_propuesta) REFERENCES propuesta(id_propuesta),
  CONSTRAINT fk_proyecto_id_director
    FOREIGN KEY (id_director) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_proyecto_id_evaluador
    FOREIGN KEY (id_evaluador) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_proyecto_fase_actual
    FOREIGN KEY (fase_actual) REFERENCES fase(id_fase)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE proyecto_fase (
  id_proyecto_fase INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_proyecto INT UNSIGNED NOT NULL,
  id_fase TINYINT UNSIGNED NOT NULL,
  estado ENUM('PENDIENTE','EN_CURSO','APROBADA','APLAZADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  fecha_inicio DATETIME NULL,
  fecha_fin DATETIME NULL,
  PRIMARY KEY (id_proyecto_fase),
  UNIQUE KEY uq_proyecto_fase (id_proyecto, id_fase),
  CONSTRAINT fk_proyecto_fase_id_proyecto

    FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto),
  CONSTRAINT fk_proyecto_fase_id_fase
    FOREIGN KEY (id_fase) REFERENCES fase(id_fase)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE documento (
  id_documento INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_proyecto_fase INT UNSIGNED NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  version_num SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  enlace_url VARCHAR(500) NOT NULL,
  id_subido_por INT UNSIGNED NOT NULL,
  vigente TINYINT(1) NOT NULL DEFAULT 1,
  comentario VARCHAR(300) NULL,
  fecha_subida DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_documento),
  UNIQUE KEY uq_doc_version (id_proyecto_fase, nombre, version_num),
  CONSTRAINT fk_documento_id_proyecto_fase
    FOREIGN KEY (id_proyecto_fase) REFERENCES proyecto_fase(id_proyecto_fase),
  CONSTRAINT fk_documento_id_subido_por
    FOREIGN KEY (id_subido_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE revision (
  id_revision INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_proyecto_fase INT UNSIGNED NOT NULL,
  id_documento INT UNSIGNED NULL,
  id_revisor INT UNSIGNED NOT NULL,
  rol_revisor ENUM('DIRECTOR','EVALUADOR','COMITE') NOT NULL,
  decision ENUM('APROBADO','APLAZADO','RECHAZADO') NOT NULL,
  observaciones TEXT NULL,
  fecha_revision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_revision),
  CONSTRAINT fk_revision_id_proyecto_fase
    FOREIGN KEY (id_proyecto_fase) REFERENCES proyecto_fase(id_proyecto_fase),
  CONSTRAINT fk_revision_id_documento
    FOREIGN KEY (id_documento) REFERENCES documento(id_documento),
  CONSTRAINT fk_revision_id_revisor
    FOREIGN KEY (id_revisor) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE pqrs (
  id_pqrs INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(15) NOT NULL,
  id_proyecto INT UNSIGNED NULL,
  id_solicitante INT UNSIGNED NOT NULL,
  tipo ENUM('PRORROGA','CAMBIO_DIRECTOR','PETICION','QUEJA','RECLAMO','SUGERENCIA') NOT NULL,
  asunto VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  enlace_soporte VARCHAR(500) NULL,
  id_nuevo_director INT UNSIGNED NULL,
  estado ENUM('PENDIENTE','APROBADO','APLAZADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
  respuesta TEXT NULL,
  id_resuelto_por INT UNSIGNED NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion DATETIME NULL,
  PRIMARY KEY (id_pqrs),
  UNIQUE KEY uq_pqrs_codigo (codigo),
  CONSTRAINT fk_pqrs_id_proyecto
    FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto),
  CONSTRAINT fk_pqrs_id_solicitante
    FOREIGN KEY (id_solicitante) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_pqrs_id_nuevo_director
    FOREIGN KEY (id_nuevo_director) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_pqrs_id_resuelto_por
    FOREIGN KEY (id_resuelto_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE notificacion (
  id_notificacion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario INT UNSIGNED NOT NULL,
  id_proyecto INT UNSIGNED NULL,
  tipo VARCHAR(30) NOT NULL,
  mensaje VARCHAR(255) NOT NULL,
  leida TINYINT(1) NOT NULL DEFAULT 0,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_notificacion),
  CONSTRAINT fk_notificacion_id_usuario

    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_notificacion_id_proyecto
    FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE historial_version (
  id_historial BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario INT UNSIGNED NOT NULL,
  id_proyecto INT UNSIGNED NULL,
  id_documento INT UNSIGNED NULL,
  entidad ENUM('USUARIO','IDEA','PROPUESTA','PROYECTO','FASE','DOCUMENTO','PQRS') NOT NULL,
  id_entidad INT UNSIGNED NOT NULL,
  accion VARCHAR(40) NOT NULL,
  estado_anterior VARCHAR(20) NULL,
  estado_nuevo VARCHAR(20) NULL,
  version_num SMALLINT UNSIGNED NULL,
  detalle VARCHAR(500) NULL,
  fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_historial),
  KEY ix_hist_proyecto (id_proyecto, fecha_evento),
  CONSTRAINT fk_historial_version_id_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  CONSTRAINT fk_historial_version_id_proyecto
    FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto),
  CONSTRAINT fk_historial_version_id_documento
    FOREIGN KEY (id_documento) REFERENCES documento(id_documento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE enlace_documental (
  id_enlace TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  descripcion VARCHAR(200) NULL,
  url VARCHAR(500) NOT NULL,
  icono VARCHAR(30) NULL,
  orden TINYINT UNSIGNED NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_enlace)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

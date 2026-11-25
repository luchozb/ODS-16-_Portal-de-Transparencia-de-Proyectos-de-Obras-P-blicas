CREATE DATABASE BD_PTOP_Huancayo;
GO
USE BD_PTOP_Huancayo;
GO


-- ==========================================================
-- 1. TABLAS CATÁLOGO Y SEGURIDAD
-- ==========================================================
CREATE TABLE ROL (
    id_rol INT IDENTITY(1,1) NOT NULL,
    nombre_rol VARCHAR(30) NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    CONSTRAINT PK_ROL PRIMARY KEY CLUSTERED (id_rol),
    CONSTRAINT UQ_ROL_nombre UNIQUE (nombre_rol),
    CONSTRAINT CK_ROL_nombre CHECK (nombre_rol IN ('Ciudadano', 'Inspector', 'Administrador'))
);

CREATE TABLE USUARIO (
    id_usuario INT IDENTITY(1,1) NOT NULL,
    id_rol INT NOT NULL,
    dni CHAR(8) NOT NULL,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Cifrado con bcrypt (RNF02)
    activo BIT NOT NULL CONSTRAINT DF_USUARIO_activo DEFAULT (1),
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_USUARIO_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_USUARIO PRIMARY KEY CLUSTERED (id_usuario),
    CONSTRAINT FK_USUARIO_ROL FOREIGN KEY (id_rol) REFERENCES ROL(id_rol),
    CONSTRAINT UQ_USUARIO_dni UNIQUE (dni),
    CONSTRAINT UQ_USUARIO_email UNIQUE (email),
    CONSTRAINT CK_USUARIO_dni CHECK (LEN(dni) = 8 AND dni NOT LIKE '%[^0-9]%') -- ODS-15
);


CREATE TABLE ENTIDAD_EJECUTORA (
    id_entidad INT IDENTITY(1,1) NOT NULL,
    ruc CHAR(11) NOT NULL,
    nombre_entidad VARCHAR(150) NOT NULL,
    sigla VARCHAR(20) NOT NULL,
    nivel_gobierno VARCHAR(30) NOT NULL,
    CONSTRAINT PK_ENTIDAD_EJECUTORA PRIMARY KEY CLUSTERED (id_entidad),
    CONSTRAINT UQ_ENTIDAD_ruc UNIQUE (ruc),
    CONSTRAINT CK_ENTIDAD_ruc CHECK (LEN(ruc) = 11 AND ruc NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_ENTIDAD_nivel CHECK (nivel_gobierno IN ('Gobierno Local', 'Gobierno Regional'))
);


CREATE TABLE DISTRITO (
    id_distrito INT IDENTITY(1,1) NOT NULL,
    nombre_distrito VARCHAR(60) NOT NULL,
    provincia VARCHAR(60) NOT NULL CONSTRAINT DF_DISTRITO_prov DEFAULT ('Huancayo'),
    departamento VARCHAR(60) NOT NULL CONSTRAINT DF_DISTRITO_dep DEFAULT ('Junín'),
    CONSTRAINT PK_DISTRITO PRIMARY KEY CLUSTERED (id_distrito),
    CONSTRAINT UQ_DISTRITO_nombre UNIQUE (nombre_distrito, provincia)
);


CREATE TABLE SECTOR (
    id_sector INT IDENTITY(1,1) NOT NULL,
    nombre_sector VARCHAR(60) NOT NULL,
    CONSTRAINT PK_SECTOR PRIMARY KEY CLUSTERED (id_sector),
    CONSTRAINT UQ_SECTOR_nombre UNIQUE (nombre_sector)
);


CREATE TABLE CONTRATISTA (
    id_contratista INT IDENTITY(1,1) NOT NULL,
    ruc CHAR(11) NOT NULL,
    razon_social VARCHAR(150) NOT NULL,
    representante_legal VARCHAR(120) NOT NULL,
    telefono VARCHAR(15) NULL,
    CONSTRAINT PK_CONTRATISTA PRIMARY KEY CLUSTERED (id_contratista),
    CONSTRAINT UQ_CONTRATISTA_ruc UNIQUE (ruc),
    CONSTRAINT CK_CONTRATISTA_ruc CHECK (LEN(ruc) = 11 AND ruc NOT LIKE '%[^0-9]%')
);


CREATE TABLE EMPRESA_SUPERVISORA (
    id_supervisora INT IDENTITY(1,1) NOT NULL,
    ruc CHAR(11) NOT NULL,
    razon_social VARCHAR(150) NOT NULL,
    jefe_supervision VARCHAR(120) NOT NULL,
    telefono VARCHAR(15) NULL,
    CONSTRAINT PK_EMPRESA_SUPERVISORA PRIMARY KEY CLUSTERED (id_supervisora),
    CONSTRAINT UQ_SUPERVISORA_ruc UNIQUE (ruc),
    CONSTRAINT CK_SUPERVISORA_ruc CHECK (LEN(ruc) = 11 AND ruc NOT LIKE '%[^0-9]%')
);


-- ==========================================================
-- 2. NÚCLEO DE PROYECTOS DE OBRA PÚBLICA
-- ==========================================================
CREATE TABLE OBRA_PUBLICA (
    cui VARCHAR(7) NOT NULL, -- Código Único de Inversión Invierte.pe (RD01)
    id_entidad INT NOT NULL,
    id_distrito INT NOT NULL,
    id_sector INT NOT NULL,
    id_contratista INT NOT NULL,
    id_supervisora INT NOT NULL,
    nombre_obra VARCHAR(250) NOT NULL,
    descripcion VARCHAR(MAX) NOT NULL,
    presupuesto_inicial DECIMAL(14,2) NOT NULL,
    presupuesto_vigente DECIMAL(14,2) NOT NULL,
    monto_devengado DECIMAL(14,2) NOT NULL CONSTRAINT DF_OBRA_devengado DEFAULT (0.00),
    plazo_dias INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin_programada DATE NOT NULL,
    estado_obra VARCHAR(20) NOT NULL CONSTRAINT DF_OBRA_estado DEFAULT ('Adjudicada'),
    resolucion_estado_pdf_url VARCHAR(500) NULL, -- Sustento obligatorio para cambio de estado (RD04)
    latitud_gps DECIMAL(10,7) NOT NULL,
    longitud_gps DECIMAL(10,7) NOT NULL,
    CONSTRAINT PK_OBRA_PUBLICA PRIMARY KEY CLUSTERED (cui),
    CONSTRAINT FK_OBRA_ENTIDAD FOREIGN KEY (id_entidad) REFERENCES ENTIDAD_EJECUTORA(id_entidad),
    CONSTRAINT FK_OBRA_DISTRITO FOREIGN KEY (id_distrito) REFERENCES DISTRITO(id_distrito),
    CONSTRAINT FK_OBRA_SECTOR FOREIGN KEY (id_sector) REFERENCES SECTOR(id_sector),
    CONSTRAINT FK_OBRA_CONTRATISTA FOREIGN KEY (id_contratista) REFERENCES CONTRATISTA(id_contratista),
    CONSTRAINT FK_OBRA_SUPERVISORA FOREIGN KEY (id_supervisora) REFERENCES EMPRESA_SUPERVISORA(id_supervisora),
    CONSTRAINT CK_OBRA_cui CHECK (LEN(cui) = 7 AND cui NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_OBRA_presupuestos CHECK (presupuesto_inicial > 0 AND presupuesto_vigente >= presupuesto_inicial AND monto_devengado >= 0),
    CONSTRAINT CK_OBRA_plazo CHECK (plazo_dias > 0 AND fecha_fin_programada >= fecha_inicio),
    CONSTRAINT CK_OBRA_estado CHECK (estado_obra IN ('Adjudicada', 'En ejecución', 'Paralizada', 'Concluida')),
    CONSTRAINT CK_OBRA_gps CHECK (latitud_gps BETWEEN -90.0 AND 90.0 AND longitud_gps BETWEEN -180.0 AND 180.0)
);


CREATE TABLE AVANCE_FISICO (
    id_avance INT IDENTITY(1,1) NOT NULL,
    cui VARCHAR(7) NOT NULL,
    id_usuario_inspector INT NOT NULL,
    periodo_mes TINYINT NOT NULL,
    periodo_anio SMALLINT NOT NULL,
    porcentaje_avance DECIMAL(5,2) NOT NULL,
    cuaderno_obra_pdf_url VARCHAR(500) NOT NULL,
    observaciones VARCHAR(1000) NULL,
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_AVANCE_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_AVANCE_FISICO PRIMARY KEY CLUSTERED (id_avance),
    CONSTRAINT FK_AVANCE_OBRA FOREIGN KEY (cui) REFERENCES OBRA_PUBLICA(cui),
    CONSTRAINT FK_AVANCE_INSPECTOR FOREIGN KEY (id_usuario_inspector) REFERENCES USUARIO(id_usuario),
    CONSTRAINT UQ_AVANCE_periodo UNIQUE (cui, periodo_anio, periodo_mes),
    CONSTRAINT CK_AVANCE_periodo CHECK (periodo_mes BETWEEN 1 AND 12 AND periodo_anio >= 2020),
    CONSTRAINT CK_AVANCE_porcentaje CHECK (porcentaje_avance BETWEEN 0.00 AND 100.00) -- RD02
);


CREATE TABLE VALORIZACION (
    id_valorizacion INT IDENTITY(1,1) NOT NULL,
    cui VARCHAR(7) NOT NULL,
    id_avance INT NOT NULL, -- Garantiza existencia de avance físico previo (RD03)
    id_usuario_inspector INT NOT NULL,
    numero_valorizacion INT NOT NULL,
    periodo_mes TINYINT NOT NULL,
    periodo_anio SMALLINT NOT NULL,
    monto_valorizado DECIMAL(14,2) NOT NULL,
    ficha_pdf_url VARCHAR(500) NOT NULL,
    fecha_aprobacion DATE NOT NULL,
    CONSTRAINT PK_VALORIZACION PRIMARY KEY CLUSTERED (id_valorizacion),
    CONSTRAINT FK_VAL_OBRA FOREIGN KEY (cui) REFERENCES OBRA_PUBLICA(cui),
    CONSTRAINT FK_VAL_AVANCE FOREIGN KEY (id_avance) REFERENCES AVANCE_FISICO(id_avance),
    CONSTRAINT FK_VAL_INSPECTOR FOREIGN KEY (id_usuario_inspector) REFERENCES USUARIO(id_usuario),
    CONSTRAINT UQ_VAL_avance UNIQUE (id_avance),
    CONSTRAINT UQ_VAL_numero UNIQUE (cui, numero_valorizacion),
    CONSTRAINT CK_VAL_monto CHECK (monto_valorizado > 0)
);


CREATE TABLE ADENDA (
    id_adenda INT IDENTITY(1,1) NOT NULL,
    cui VARCHAR(7) NOT NULL,
    id_usuario_responsable INT NOT NULL,
    tipo_adenda VARCHAR(30) NOT NULL,
    numero_resolucion VARCHAR(60) NOT NULL,
    monto_adicional DECIMAL(14,2) NOT NULL CONSTRAINT DF_ADENDA_monto DEFAULT (0.00),
    dias_ampliacion INT NOT NULL CONSTRAINT DF_ADENDA_dias DEFAULT (0),
    resolucion_pdf_url VARCHAR(500) NOT NULL,
    motivo VARCHAR(1000) NOT NULL,
    fecha_aprobacion DATE NOT NULL,
    CONSTRAINT PK_ADENDA PRIMARY KEY CLUSTERED (id_adenda),
    CONSTRAINT FK_ADENDA_OBRA FOREIGN KEY (cui) REFERENCES OBRA_PUBLICA(cui),
    CONSTRAINT FK_ADENDA_USUARIO FOREIGN KEY (id_usuario_responsable) REFERENCES USUARIO(id_usuario),
    CONSTRAINT CK_ADENDA_tipo CHECK (tipo_adenda IN ('Ampliación de Plazo', 'Adicional Presupuestal', 'Mixta')),
    CONSTRAINT CK_ADENDA_valores CHECK (monto_adicional >= 0 AND dias_ampliacion >= 0 AND (monto_adicional > 0 OR dias_ampliacion > 0))
);


-- ==========================================================
-- 3. PARTICIPACIÓN CIUDADANA Y AUDITORÍA INMUTABLE
-- ==========================================================
CREATE TABLE ALERTA_CIUDADANA (
    id_alerta INT IDENTITY(1,1) NOT NULL,
    cui VARCHAR(7) NOT NULL,
    id_usuario_ciudadano INT NULL, -- Permite denuncias anónimas (RF03)
    codigo_seguimiento VARCHAR(20) NOT NULL,
    descripcion VARCHAR(1500) NOT NULL,
    latitud_gps DECIMAL(10,7) NOT NULL,
    longitud_gps DECIMAL(10,7) NOT NULL,
    estado_alerta VARCHAR(25) NOT NULL CONSTRAINT DF_ALERTA_estado DEFAULT ('Recibida'),
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_ALERTA_fecha DEFAULT (SYSDATETIME()),
    fecha_limite_respuesta DATE NULL, -- 10 días hábiles tras derivación (RD05)
    CONSTRAINT PK_ALERTA_CIUDADANA PRIMARY KEY CLUSTERED (id_alerta),
    CONSTRAINT FK_ALERTA_OBRA FOREIGN KEY (cui) REFERENCES OBRA_PUBLICA(cui),
    CONSTRAINT FK_ALERTA_CIUDADANO FOREIGN KEY (id_usuario_ciudadano) REFERENCES USUARIO(id_usuario),
    CONSTRAINT UQ_ALERTA_codigo UNIQUE (codigo_seguimiento),
    CONSTRAINT CK_ALERTA_estado CHECK (estado_alerta IN ('Recibida', 'En Inspección', 'Respondida', 'Desestimada'))
);


CREATE TABLE EVIDENCIA_ALERTA (
    id_evidencia INT IDENTITY(1,1) NOT NULL,
    id_alerta INT NOT NULL,
    archivo_url VARCHAR(500) NOT NULL,
    tipo_archivo VARCHAR(10) NOT NULL,
    tamano_kb INT NOT NULL,
    fecha_carga DATETIME2 NOT NULL CONSTRAINT DF_EVIDENCIA_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_EVIDENCIA_ALERTA PRIMARY KEY CLUSTERED (id_evidencia),
    CONSTRAINT FK_EVIDENCIA_ALERTA FOREIGN KEY (id_alerta) REFERENCES ALERTA_CIUDADANA(id_alerta),
    CONSTRAINT CK_EVIDENCIA_tipo CHECK (tipo_archivo IN ('JPG', 'JPEG', 'PNG')),
    CONSTRAINT CK_EVIDENCIA_tamano CHECK (tamano_kb > 0 AND tamano_kb <= 5120) -- Máx 5 MB (RF03)
);


CREATE TABLE RESPUESTA_ALERTA (
    id_respuesta INT IDENTITY(1,1) NOT NULL,
    id_alerta INT NOT NULL,
    id_usuario_inspector INT NOT NULL,
    informe_tecnico VARCHAR(MAX) NOT NULL,
    acta_pdf_url VARCHAR(500) NOT NULL,
    fecha_respuesta DATETIME2 NOT NULL CONSTRAINT DF_RESPUESTA_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RESPUESTA_ALERTA PRIMARY KEY CLUSTERED (id_respuesta),
    CONSTRAINT FK_RESPUESTA_ALERTA FOREIGN KEY (id_alerta) REFERENCES ALERTA_CIUDADANA(id_alerta),
    CONSTRAINT FK_RESPUESTA_INSPECTOR FOREIGN KEY (id_usuario_inspector) REFERENCES USUARIO(id_usuario),
    CONSTRAINT UQ_RESPUESTA_alerta UNIQUE (id_alerta)
);


CREATE TABLE HISTORIAL_AUDITORIA (
    id_auditoria INT IDENTITY(1,1) NOT NULL,
    tabla_afectada VARCHAR(50) NOT NULL,
    registro_id VARCHAR(30) NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior VARCHAR(500) NULL,
    valor_nuevo VARCHAR(500) NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    sustento_pdf_url VARCHAR(500) NULL,
    id_usuario_responsable INT NULL,
    fecha_evento DATETIME2 NOT NULL CONSTRAINT DF_AUDITORIA_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_HISTORIAL_AUDITORIA PRIMARY KEY CLUSTERED (id_auditoria),
    CONSTRAINT FK_AUDITORIA_USUARIO FOREIGN KEY (id_usuario_responsable) REFERENCES USUARIO(id_usuario)
);
GO

-- Índice compuesto de cobertura para filtros públicos del catálogo y mapa GIS (RF01, RNF01)
CREATE NONCLUSTERED INDEX IX_OBRA_FiltroMapa_DistritoEstado
ON OBRA_PUBLICA (id_distrito, estado_obra, id_sector)
INCLUDE (nombre_obra, presupuesto_vigente, monto_devengado, latitud_gps, longitud_gps);

-- Índice para consultas cronológicas de avances físicos y curvas S (ODS-9)
CREATE NONCLUSTERED INDEX IX_AVANCE_CuiPeriodo
ON AVANCE_FISICO (cui, periodo_anio DESC, periodo_mes DESC)
INCLUDE (porcentaje_avance, fecha_registro);

-- Índice para bandeja de moderación y control de plazos de alertas ciudadanas (RF09, RD05)
CREATE NONCLUSTERED INDEX IX_ALERTA_EstadoFechaLimite
ON ALERTA_CIUDADANA (estado_alerta, fecha_limite_respuesta)
INCLUDE (cui, codigo_seguimiento, fecha_registro);
GO


CREATE PROCEDURE sp_RegistrarAvanceYValorizacion
    @cui VARCHAR(7),
    @id_usuario_inspector INT,
    @periodo_mes TINYINT,
    @periodo_anio SMALLINT,
    @porcentaje_avance DECIMAL(5,2),
    @cuaderno_obra_pdf_url VARCHAR(500),
    @observaciones VARCHAR(1000),
    @numero_valorizacion INT,
    @monto_valorizado DECIMAL(14,2),
    @ficha_pdf_url VARCHAR(500),
    @fecha_aprobacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ultimo_avance DECIMAL(5,2) = 0.00;
        DECLARE @nuevo_id_avance INT;

        -- 1. Obtener el avance físico máximo registrado previamente para la obra (RD02)
        SELECT @ultimo_avance = ISNULL(MAX(porcentaje_avance), 0.00)
        FROM AVANCE_FISICO
        WHERE cui = @cui;

        IF @porcentaje_avance < @ultimo_avance
        BEGIN
            THROW 50002, 'Error RD02: El porcentaje de avance físico no puede ser menor al periodo anterior.', 1;
        END

        -- 2. Insertar el avance físico del periodo
        INSERT INTO AVANCE_FISICO (
            cui, id_usuario_inspector, periodo_mes, periodo_anio,
            porcentaje_avance, cuaderno_obra_pdf_url, observaciones
        )
        VALUES (
            @cui, @id_usuario_inspector, @periodo_mes, @periodo_anio,
            @porcentaje_avance, @cuaderno_obra_pdf_url, @observaciones
        );

        SET @nuevo_id_avance = SCOPE_IDENTITY();

        -- 3. Registrar la valorización mensual respaldada por el avance recién creado (RD03)
        INSERT INTO VALORIZACION (
            cui, id_avance, id_usuario_inspector, numero_valorizacion,
            periodo_mes, periodo_anio, monto_valorizado, ficha_pdf_url, fecha_aprobacion
        )
        VALUES (
            @cui, @nuevo_id_avance, @id_usuario_inspector, @numero_valorizacion,
            @periodo_mes, @periodo_anio, @monto_valorizado, @ficha_pdf_url, @fecha_aprobacion
        );

        -- 4. Actualizar el monto devengado acumulado en la obra pública
        UPDATE OBRA_PUBLICA
        SET monto_devengado = monto_devengado + @monto_valorizado
        WHERE cui = @cui;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


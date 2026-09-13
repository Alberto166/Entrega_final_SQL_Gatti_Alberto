-- ============================================================
-- ARCHIVO: estructura.sql
-- PROYECTO: Capstone Project - Análisis Exploratorio de Datos
-- OBJETIVO: Creación de tablas para el modelo transaccional
-- ============================================================

-- 1. Tablas Maestras e Independientes
DROP TABLE IF EXISTS paises CASCADE;
CREATE TABLE paises (
    pais_id     SERIAL PRIMARY KEY,
    codigo_pais CHAR(2)      NOT NULL UNIQUE,
    nombre_pais VARCHAR(50)  NOT NULL UNIQUE,
    continente  VARCHAR(50)  NOT NULL
);

DROP TABLE IF EXISTS categorias CASCADE;
CREATE TABLE categorias (
    categoria_id       SERIAL PRIMARY KEY,
    nombre_categoria   VARCHAR(50)  NOT NULL UNIQUE,
    descripcion        TEXT         NOT NULL
);

DROP TABLE IF EXISTS tipos_cliente CASCADE;
CREATE TABLE tipos_cliente (
    tipo_cliente_id SERIAL PRIMARY KEY,
    nombre_tipo     VARCHAR(50)  NOT NULL UNIQUE,
    descripcion     TEXT         NOT NULL
);

-- 2. Estructura Organizacional
DROP TABLE IF EXISTS sucursales CASCADE;
CREATE TABLE sucursales (
    sucursal_id        SERIAL PRIMARY KEY,
    nombre_sucursal    VARCHAR(150) NOT NULL,
    ciudad             VARCHAR(100) NOT NULL,
    pais_id            INT          NOT NULL,
    direccion_completa TEXT         NOT NULL,
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_sucursales_paises FOREIGN KEY (pais_id) REFERENCES paises(pais_id)
);

DROP TABLE IF EXISTS empleados CASCADE;
CREATE TABLE empleados (
    empleado_id   SERIAL PRIMARY KEY,
    nombre        VARCHAR(30)  NOT NULL,
    apellido      VARCHAR(30)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    sucursal_id   INT          NOT NULL,
    fecha_ingreso DATE         NULL,          -- Columna crítica que puede contener nulos
    cargo         VARCHAR(50)  NOT NULL,
    salario       NUMERIC(10, 2) NULL,        -- Integrado aquí (puede ser nulo en pasantías/externos)
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_empleados_sucursales FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id)
);

-- 3. Entidades de Negocio
DROP TABLE IF EXISTS clientes CASCADE;
CREATE TABLE clientes ( 
    cliente_id       SERIAL PRIMARY KEY, 
    nombre           VARCHAR(30)  NOT NULL, 
    apellido         VARCHAR(30)  NOT NULL, 
    email            VARCHAR(100) NOT NULL UNIQUE, 
    telefono         VARCHAR(50)  NOT NULL, 
    pais_id          INT          NOT NULL, 
    ciudad           VARCHAR(50)  NOT NULL, 
    tipo_cliente_id  INT          NOT NULL, 
    fecha_registro   DATE         NULL,          -- Columna crítica que puede contener nulos
    fecha_nacimiento DATE         NULL,          -- Integrado aquí
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,     
    CONSTRAINT fk_clientes_paises FOREIGN KEY (pais_id) REFERENCES paises(pais_id), 
    CONSTRAINT fk_clientes_tipos_cliente FOREIGN KEY (tipo_cliente_id) REFERENCES tipos_cliente(tipo_cliente_id) 
);

DROP TABLE IF EXISTS productos CASCADE;
CREATE TABLE productos (
    producto_id      SERIAL PRIMARY KEY,
    codigo_producto  VARCHAR(30)   NOT NULL UNIQUE,
    nombre_producto  VARCHAR(100)  NOT NULL,
    categoria_id     INT           NOT NULL,
    precio           DECIMAL(6,2)  NOT NULL,
    stock            INT           NULL,          -- Puede contener nulos si es un servicio digital o sin stock controlado
    peso_kg          DECIMAL(6, 3) NULL,          -- Integrado aquí
    descripcion      TEXT          NULL,
    activo           BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_precio_positivo CHECK (precio > 0),
    CONSTRAINT chk_stock_valido    CHECK (stock >= 0),
    CONSTRAINT fk_productos_categorias FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)
);

-- 4. Operaciones y Transacciones
DROP TABLE IF EXISTS pedidos CASCADE;
CREATE TABLE pedidos (
    pedido_id   SERIAL PRIMARY KEY,
    cliente_id  INT           NOT NULL,
    sucursal_id INT           NOT NULL,
    empleado_id INT           NULL,          -- Nulo si la compra fue puramente online sin vendedor asignado
    fecha_pedido TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado      VARCHAR(20)   NOT NULL DEFAULT 'En proceso',
    total       DECIMAL(10,2) NOT NULL,
    notas       TEXT          NULL,
    CONSTRAINT fk_pedidos_clientes FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id),
    CONSTRAINT fk_pedidos_sucursales FOREIGN KEY (sucursal_id) REFERENCES sucursales(sucursal_id),
    CONSTRAINT fk_pedidos_empleados FOREIGN KEY (empleado_id) REFERENCES empleados(empleado_id),
    CONSTRAINT chk_estado_pedido_valido CHECK (estado IN ('Cancelado', 'Enviado', 'En proceso', 'Completado')),
    CONSTRAINT chk_total_pedido_valido CHECK (total > 0)
);

DROP TABLE IF EXISTS detalle_pedidos;
CREATE TABLE detalle_pedidos (
    detalle_id      SERIAL PRIMARY KEY,
    pedido_id       INT           NOT NULL,
    producto_id     INT           NOT NULL,
    cantidad        INT           NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT chk_cantidad_valido    CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unit_valido CHECK (precio_unitario > 0),
    CONSTRAINT fk_detalle_pedidos_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id),
    CONSTRAINT fk_detalle_pedidos_productos FOREIGN KEY (producto_id) REFERENCES productos(producto_id),
    CONSTRAINT uq_pedido_producto UNIQUE (pedido_id, producto_id)
);



-- ============================================================
-- 5. Carga de Datos desde Archivos CSV
-- INSTRUCCIONES: Asegúrese de modificar la ruta local de los archivos 
-- si ejecuta este script en un entorno diferente.
-- ============================================================

-- Tabla: paises
COPY paises (pais_id, codigo_pais, nombre_pais, continente)
FROM 'C:\Archivos_csv_proyecto_final_sql\paises.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: categorias
COPY categorias(categoria_id, nombre_categoria, descripcion)
FROM 'C:\Archivos_csv_proyecto_final_sql\categorias.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: tipos_cliente (Corregido: nombre de tabla, campos y CSV correcto)
COPY tipos_cliente (tipo_cliente_id, nombre_tipo, descripcion)
FROM 'C:\Archivos_csv_proyecto_final_sql\tipos_cliente.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: sucursales
COPY sucursales(sucursal_id, nombre_sucursal, ciudad, pais_id, direccion_completa, activo)
FROM 'C:\Archivos_csv_proyecto_final_sql\sucursales.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: empleados
COPY empleados(empleado_id, nombre, apellido, email, sucursal_id, fecha_ingreso, cargo, activo, salario)
FROM 'C:\Archivos_csv_proyecto_final_sql\empleados.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: clientes
COPY clientes(cliente_id, nombre, apellido, email, telefono, pais_id, ciudad, tipo_cliente_id, fecha_registro, activo, fecha_nacimiento)
FROM 'C:\Archivos_csv_proyecto_final_sql\clientes.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: productos
COPY productos(producto_id, codigo_producto, nombre_producto, categoria_id, precio, stock, descripcion, activo, peso_kg)
FROM 'C:\Archivos_csv_proyecto_final_sql\productos.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: pedidos
COPY pedidos(pedido_id, cliente_id, sucursal_id, empleado_id, fecha_pedido, estado, total, notas)
FROM 'C:\Archivos_csv_proyecto_final_sql\pedidos.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- Tabla: detalle_pedidos (Nota: usa DELIMITER ';')
COPY detalle_pedidos(detalle_id, pedido_id, producto_id, cantidad, precio_unitario)
FROM 'C:\Archivos_csv_proyecto_final_sql\detalle_pedidos.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '', ENCODING 'UTF8');

-- 6. Actualización de Secuencias (Reinicia los contadores SERIAL post-carga masiva)
SELECT setval(pg_get_serial_sequence('paises', 'pais_id'), COALESCE(MAX(pais_id), 1)) FROM paises;
SELECT setval(pg_get_serial_sequence('categorias', 'categoria_id'), COALESCE(MAX(categoria_id), 1)) FROM categorias;
SELECT setval(pg_get_serial_sequence('tipos_cliente', 'tipo_cliente_id'), COALESCE(MAX(tipo_cliente_id), 1)) FROM tipos_cliente;
SELECT setval(pg_get_serial_sequence('sucursales', 'sucursal_id'), COALESCE(MAX(sucursal_id), 1)) FROM sucursales;
SELECT setval(pg_get_serial_sequence('empleados', 'empleado_id'), COALESCE(MAX(empleado_id), 1)) FROM empleados;
SELECT setval(pg_get_serial_sequence('clientes', 'cliente_id'), COALESCE(MAX(cliente_id), 1)) FROM clientes;
SELECT setval(pg_get_serial_sequence('productos', 'producto_id'), COALESCE(MAX(producto_id), 1)) FROM productos;
SELECT setval(pg_get_serial_sequence('pedidos', 'pedido_id'), COALESCE(MAX(pedido_id), 1)) FROM pedidos;
SELECT setval(pg_get_serial_sequence('detalle_pedidos', 'detalle_id'), COALESCE(MAX(detalle_id), 1)) FROM detalle_pedidos;


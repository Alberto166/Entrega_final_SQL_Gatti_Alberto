-- ============================================================
-- ARCHIVO: analisis.sql
-- PROYECTO: Capstone Project - Análisis Exploratorio de Datos
-- OBJETIVO: Limpieza de datos y consultas de negocio para toma de decisiones
-- ============================================================
-- ============================================================
-- AUDITORÍA DE TIPOS DE DATOS (REQUERIDO POR CONSIGNA)
-- ============================================================
-- Consultamos el catálogo de metadatos de PostgreSQL para verificar 
-- que las columnas críticas tengan asignados tipos de datos correctos (DATE, NUMERIC).
SELECT 
    table_name AS tabla,
    column_name AS columna,
    data_type AS tipo_de_dato
FROM information_schema.columns
WHERE table_name IN ('productos', 'pedidos', 'clientes')
  AND column_name IN ('precio', 'total', 'fecha_pedido', 'fecha_registro', 'fecha_nacimiento')
ORDER BY table_name, column_name;


-- ============================================================
-- 1. FASE DE LIMPIEZA: TRATAMIENTO DE NULOS CON COALESCE
-- ============================================================

-- Explicación de negocio: Identificamos que las compras online no asignan un empleado_id 
-- en la tabla de pedidos, y que algunos productos no tienen stock cargado (nulo) o notas. 
-- Para evitar errores de cálculo en los reportes directivos, estandarizamos los nulos.

SELECT 
    pedido_id,
    cliente_id,
    -- Reemplazamos empleado nulo por 0 para identificar transacciones del canal puramente digital (E-commerce)
    COALESCE(empleado_id, 0) AS empleado_asignado,
    fecha_pedido,
    estado,
    total,
    -- Evitamos visualizaciones vacías en los reportes de atención al cliente estandarizando las notas
    COALESCE(notas, 'Sin observaciones comerciales') AS notas_gestionadas
FROM pedidos;

SELECT 
    producto_id,
    nombre_producto,
    precio,
    -- El stock nulo se gestiona como 0 disponible para proteger la experiencia del usuario y evitar quiebres de inventario ficticios
    COALESCE(stock, 0) AS stock_disponible
FROM productos;


-- ============================================================
-- 2. CONSULTAS ANALÍTICAS (ENFOQUE ESTRATÉGICO)
-- ============================================================

-- ------------------------------------------------------------
-- Consulta 1: Top 5 clientes por gasto total
-- ------------------------------------------------------------
-- Filtramos y agrupamos los pedidos completados y enviados para identificar a nuestros 
-- clientes de mayor valor (VIP). Este dato permite al equipo de Marketing dirigir 
-- campañas de fidelización exclusivas y optimizar el costo de adquisición de clientes.
SELECT 
    c.cliente_id,
    c.nombre || ' ' || c.apellido AS cliente,
    c.email,
    SUM(p.total) AS gasto_total,
    COUNT(p.pedido_id) AS cantidad_pedidos
FROM pedidos p
INNER JOIN clientes c ON p.cliente_id = c.cliente_id
WHERE p.estado IN ('Completado', 'Enviado') -- Excluimos pedidos cancelados que no generan ingresos reales
GROUP BY c.cliente_id, c.nombre, c.apellido, c.email
ORDER BY gasto_total DESC
LIMIT 5;


-- ------------------------------------------------------------
-- Consulta 2: Ventas totales por mes
-- ------------------------------------------------------------
-- Agrupamos la facturación histórica por periodos mensuales. Esta perspectiva temporal 
-- es clave para que la dirección financiera evalúe la estacionalidad del negocio, 
-- planifique el flujo de caja y compare el rendimiento comercial mes a mes.
SELECT 
    TO_CHAR(fecha_pedido, 'YYYY-MM') AS periodo_mes,
    SUM(total) AS facturacion_total,
    COUNT(pedido_id) AS volumen_pedidos,
    ROUND(AVG(total), 2) AS ticket_promedio
FROM pedidos
WHERE estado IN ('Completado', 'Enviado')
GROUP BY TO_CHAR(fecha_pedido, 'YYYY-MM')
ORDER BY periodo_mes ASC;


-- ------------------------------------------------------------
-- Consulta 3: Los 3 productos menos vendidos
-- ------------------------------------------------------------
-- Identificamos aquellos artículos con menor salida comercial en el mercado. 
-- Esta consulta alerta al equipo de Operaciones sobre "inventario muerto" o stock 
-- inmovilizado, permitiendo tomar medidas de liquidación o revisar la estrategia de precios.
SELECT 
    pr.producto_id,
    pr.nombre_producto,
    cat.nombre_categoria,
    COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas
FROM productos pr
INNER JOIN categorias cat ON pr.categoria_id = cat.categoria_id
LEFT JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
GROUP BY pr.producto_id, pr.nombre_producto, cat.nombre_categoria
ORDER BY unidades_vendidas ASC
LIMIT 3;


-- ------------------------------------------------------------
-- Consulta 4: Ranking de pedidos por categoría con RANK()
-- ------------------------------------------------------------
-- Empleamos funciones de ventana para rankear los productos más vendidos dentro de cada 
-- categoría de negocio. Ayuda a los Category Managers a entender qué subproductos lideran 
-- cada unidad de negocio y cuáles necesitan mayor exposición en la plataforma.
WITH productos_rankeados AS (
    SELECT 
        cat.nombre_categoria,
        pr.nombre_producto,
        SUM(dp.cantidad) AS total_unidades,
        RANK() OVER(PARTITION BY cat.categoria_id ORDER BY SUM(dp.cantidad) DESC) AS posicion_ranking
    FROM detalle_pedidos dp
    INNER JOIN productos pr ON dp.producto_id = pr.producto_id
    INNER JOIN categorias cat ON pr.categoria_id = cat.categoria_id
    GROUP BY cat.categoria_id, cat.nombre_categoria, pr.nombre_producto
)
SELECT 
    nombre_categoria,
    nombre_producto,
    total_unidades,
    posicion_ranking
FROM productos_rankeados
WHERE posicion_ranking <= 3 -- Mostramos el top 3 de cada categoría para un reporte ejecutivo conciso
ORDER BY nombre_categoria ASC, posicion_ranking ASC;




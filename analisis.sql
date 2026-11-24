-- =====================================================
-- Proyecto Capstone: EDA en PostgreSQL
-- Archivo: analisis.sql
-- Ejecutar después de estructura.sql
-- =====================================================


-- =====================================================
-- ETAPA 1: LIMPIEZA DE DATOS
-- =====================================================

-- Diagnóstico: antes de analizar, medimos cuántos huecos hay en las
-- columnas críticas, porque un precio o cantidad nulos harían que
-- SUM() ignore esas ventas y subestime los ingresos.
SELECT
    COUNT(*) AS total_pedidos,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS sin_precio,
    COUNT(*) FILTER (WHERE cantidad IS NULL) AS sin_cantidad,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL) AS sin_fecha
FROM pedidos;

-- Resultado: 17 pedidos, 3 sin precio, 1 sin cantidad, 1 sin fecha.

-- Vista limpia: todos los análisis se hacen sobre esta vista para
-- aplicar las mismas reglas de limpieza en un solo lugar.
-- Reglas:
--   * Sin precio en el pedido -> usamos el precio de lista del producto,
--     porque la tienda no aplica descuentos y es el valor más confiable.
--   * Sin cantidad -> asumimos 1 unidad, porque todo pedido registrado
--     implica al menos una venta.
--   * Sin fecha -> se conserva para totales por cliente y producto,
--     pero se excluye del análisis mensual (no se puede ubicar en un mes).
CREATE VIEW pedidos_limpios AS
SELECT
    pe.id AS pedido_id,
    pe.cliente_id,
    pe.producto_id,
    pe.fecha_pedido,
    COALESCE(pe.cantidad, 1) AS cantidad,
    COALESCE(pe.precio_unitario, pr.precio) AS precio_unitario,
    COALESCE(pe.cantidad, 1) * COALESCE(pe.precio_unitario, pr.precio) AS importe
FROM pedidos pe
JOIN productos pr ON pr.id = pe.producto_id;


-- =====================================================
-- ETAPA 2: ANÁLISIS
-- =====================================================

-- PREGUNTA 1: ¿Quiénes son los 5 clientes que más gastan?
-- Sirve para identificar a los clientes de mayor valor y priorizarlos
-- en acciones de fidelización. La ciudad faltante se muestra como
-- 'Sin dato' para no dejar celdas vacías en el reporte.
SELECT
    c.nombre,
    COALESCE(c.ciudad, 'Sin dato') AS ciudad,
    COUNT(pl.pedido_id) AS cantidad_pedidos,
    SUM(pl.importe) AS gasto_total
FROM clientes c
JOIN pedidos_limpios pl ON pl.cliente_id = c.id
GROUP BY c.id, c.nombre, c.ciudad
ORDER BY gasto_total DESC
LIMIT 5;


-- PREGUNTA 2: ¿Cuánto se vende cada mes?
-- Permite detectar meses fuertes y débiles para planificar stock y
-- promociones. Se excluyen pedidos sin fecha porque no pueden
-- asignarse a ningún mes.
SELECT
    TO_CHAR(DATE_TRUNC('month', fecha_pedido), 'YYYY-MM') AS mes,
    COUNT(*) AS cantidad_pedidos,
    SUM(importe) AS ventas_totales
FROM pedidos_limpios
WHERE fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY DATE_TRUNC('month', fecha_pedido);


-- PREGUNTA 3: ¿Cuáles son los 3 productos menos vendidos?
-- Usamos LEFT JOIN para incluir productos que nunca se vendieron
-- (con un JOIN común desaparecerían del resultado). COALESCE los
-- muestra con 0 en vez de NULL. Mostramos también los ingresos para
-- no confundir "pocas unidades" con "poco rentable".
SELECT
    pr.nombre,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas,
    COALESCE(SUM(pl.importe), 0) AS ingresos
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.id
GROUP BY pr.id, pr.nombre, pr.categoria
ORDER BY unidades_vendidas ASC, ingresos ASC
LIMIT 3;


-- PREGUNTA 4: ¿Cuáles son los pedidos más importantes de cada categoría?
-- RANK() numera los pedidos dentro de cada categoría según su importe,
-- sin perder el detalle de cada pedido. Si dos pedidos empatan,
-- comparten el puesto.
SELECT
    pr.categoria,
    pl.pedido_id,
    c.nombre AS cliente,
    pr.nombre AS producto,
    pl.importe,
    RANK() OVER (PARTITION BY pr.categoria ORDER BY pl.importe DESC) AS ranking
FROM pedidos_limpios pl
JOIN productos pr ON pr.id = pl.producto_id
JOIN clientes c ON c.id = pl.cliente_id
ORDER BY pr.categoria, ranking;


-- PREGUNTA 5: ¿Cómo se reparten los clientes según su nivel de gasto?
-- Segmentamos con CASE para que el equipo comercial pueda tratar
-- distinto a cada grupo. Los cortes (1.000.000 y 300.000) se eligieron
-- porque separan a quienes compraron instrumentos de alta gama de
-- quienes compraron principalmente accesorios o instrumentos de entrada.
WITH gasto_por_cliente AS (
    SELECT
        c.nombre,
        SUM(pl.importe) AS gasto_total
    FROM clientes c
    JOIN pedidos_limpios pl ON pl.cliente_id = c.id
    GROUP BY c.id, c.nombre
)
SELECT
    nombre,
    gasto_total,
    CASE
        WHEN gasto_total >= 1000000 THEN 'Premium'
        WHEN gasto_total >= 300000 THEN 'Medio'
        ELSE 'Bajo'
    END AS segmento
FROM gasto_por_cliente
ORDER BY gasto_total DESC;


-- EXTRA: ¿Cuánto aporta cada categoría en unidades y en ingresos?
-- Ayuda a entender si las categorías que más rotan son también
-- las que más dinero generan.
SELECT
    pr.categoria,
    SUM(pl.cantidad) AS unidades,
    SUM(pl.importe) AS ingresos,
    ROUND(100.0 * SUM(pl.importe) / (SELECT SUM(importe) FROM pedidos_limpios), 1) AS porcentaje_ingresos
FROM pedidos_limpios pl
JOIN productos pr ON pr.id = pl.producto_id
GROUP BY pr.categoria
ORDER BY ingresos DESC;
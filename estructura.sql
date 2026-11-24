-- =====================================================
-- Proyecto Capstone: EDA en PostgreSQL
-- =====================================================
DROP TABLE IF EXISTS pedidos, productos, clientes CASCADE;


-- =====================================================
-- CREACIÓN DE TABLAS
-- =====================================================

-- Tabla de clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50),
    fecha_registro DATE NOT NULL
);

-- Tabla de productos
-- precio en NUMERIC para no perder precisión con montos de dinero
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    precio NUMERIC(12,2) NOT NULL
);

-- Tabla de pedidos
-- cantidad, precio_unitario y fecha_pedido aceptan NULL porque el
-- sistema de ventas a veces no los registra (se limpian en analisis.sql)
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    producto_id INTEGER NOT NULL REFERENCES productos(id),
    fecha_pedido DATE,
    cantidad INTEGER,
    precio_unitario NUMERIC(12,2)
);


-- =====================================================
-- INSERCIÓN DE DATOS
-- Orden: clientes -> productos -> pedidos, porque pedidos
-- depende de las otras dos tablas (claves foráneas).
-- =====================================================

-- Clientes: Tomás Díaz no tiene ciudad cargada (dato faltante en un
-- campo no crítico; se muestra como 'Sin dato' en el análisis).
INSERT INTO clientes (nombre, ciudad, fecha_registro) VALUES
    ('Martina López',     'Buenos Aires',  '2025-03-10'),
    ('Juan Pérez',        'Córdoba',       '2025-04-22'),
    ('Lucía Fernández',   'Rosario',       '2025-05-15'),
    ('Diego Romero',      'Buenos Aires',  '2025-06-01'),
    ('Sofía Gómez',       'Mendoza',       '2025-07-19'),
    ('Tomás Díaz',        NULL,            '2025-08-05'),
    ('Valentina Ruiz',    'La Plata',      '2025-09-12'),
    ('Nicolás Sosa',      'Mar del Plata', '2025-10-03');

-- Productos: la funda (id 10) nunca se vendió, para verificar que
-- el análisis de productos menos vendidos no la pierda.
INSERT INTO productos (nombre, categoria, precio) VALUES
    ('Guitarra eléctrica Stratocaster', 'Guitarras',   1850000.00),
    ('Guitarra criolla de estudio',     'Guitarras',    180000.00),
    ('Teclado 61 teclas',               'Teclados',     420000.00),
    ('Piano digital 88 teclas',         'Teclados',    1350000.00),
    ('Batería acústica 5 cuerpos',      'Percusión',   1600000.00),
    ('Cajón peruano',                   'Percusión',    120000.00),
    ('Juego de cuerdas',                'Accesorios',    15000.00),
    ('Púas x12',                        'Accesorios',     6000.00),
    ('Afinador digital',                'Accesorios',    25000.00),
    ('Funda acolchada para guitarra',   'Accesorios',    45000.00);

-- Pedidos: incluyen a propósito los problemas que trata la etapa de limpieza:
--   * 3 pedidos sin precio_unitario (ids 3, 10 y 16)
--   * 1 pedido sin cantidad (id 7)
--   * 1 pedido sin fecha (id 15)
INSERT INTO pedidos (cliente_id, producto_id, fecha_pedido, cantidad, precio_unitario) VALUES
    (1, 1, '2026-01-08', 1,    1850000.00),
    (1, 7, '2026-01-08', 3,      15000.00),
    (2, 5, '2026-01-20', 1,          NULL),
    (3, 3, '2026-02-03', 1,     420000.00),
    (3, 8, '2026-02-03', 2,       6000.00),
    (4, 2, '2026-02-14', 1,     180000.00),
    (4, 7, '2026-02-14', NULL,   15000.00),
    (5, 4, '2026-03-02', 1,    1350000.00),
    (6, 6, '2026-03-18', 1,     120000.00),
    (6, 9, '2026-03-18', 1,          NULL),
    (7, 2, '2026-04-05', 2,     180000.00),
    (7, 8, '2026-04-05', 1,       6000.00),
    (8, 7, '2026-04-22', 2,      15000.00),
    (2, 7, '2026-05-10', 2,      15000.00),
    (5, 9, NULL,         1,      25000.00),
    (1, 3, '2026-05-27', 1,          NULL),
    (8, 6, '2026-06-15', 1,     120000.00);
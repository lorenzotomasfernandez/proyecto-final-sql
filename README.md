# Proyecto Capstone: Análisis exploratorio de ventas en PostgreSQL

## Problema de negocio
Una tienda de instrumentos musicales quiere entender sus ventas del primer semestre
de 2026 para tomar mejores decisiones comerciales. El análisis busca responder:

- ¿Quiénes son los clientes de mayor valor?
- ¿Qué meses venden más y cuáles menos, para planificar stock y promociones?
- ¿Qué productos casi no se venden?
- ¿Cuáles son los pedidos más importantes de cada categoría?
- ¿Cómo se segmentan los clientes según su nivel de gasto?

## Dataset
Dataset propio con 3 tablas relacionadas:

| Tabla | Registros | Descripción |
|---|---|---|
| `clientes` | 8 | Nombre, ciudad y fecha de registro |
| `productos` | 10 | Nombre, categoría y precio de lista (NUMERIC) |
| `pedidos` | 17 | Cliente, producto, fecha, cantidad y precio unitario |

Los montos están en pesos argentinos.

## Limpieza de datos
El diagnóstico inicial detectó que, de 17 pedidos, 3 no tenían precio, 1 no tenía
cantidad y 1 no tenía fecha. Si no se tratan, `SUM()` ignora esas ventas y los
ingresos quedan subestimados. Se creó la vista `pedidos_limpios` con estas reglas:

- **Precio faltante** → se usa el precio de lista del producto, porque la tienda no aplica descuentos.
- **Cantidad faltante** → se asume 1 unidad, porque todo pedido registrado implica al menos una venta.
- **Fecha faltante** → el pedido cuenta para totales por cliente y producto, pero se excluye del análisis mensual.

Además, la ciudad faltante de un cliente se muestra como "Sin dato" en los reportes.
Todos los análisis se hacen sobre esta vista para aplicar las mismas reglas en todas las consultas.

## Hallazgos principales

Ingresos totales del período: **$6.608.000**.

### 1. Los 5 clientes que más gastan concentran el 93% de los ingresos

| Cliente | Ciudad | Pedidos | Gasto total |
|---|---|---|---|
| Martina López | Buenos Aires | 3 | $2.315.000 |
| Juan Pérez | Córdoba | 2 | $1.630.000 |
| Sofía Gómez | Mendoza | 2 | $1.375.000 |
| Lucía Fernández | Rosario | 2 | $432.000 |
| Valentina Ruiz | La Plata | 2 | $366.000 |

Martina López sola representa el 35% de la facturación. El negocio depende de muy
pocos clientes: perder a uno de los tres primeros tendría un impacto fuerte.
**Recomendación:** armar un programa de fidelización para estos clientes
(service gratuito de instrumentos, preventas, descuentos en accesorios).

### 2. Las ventas dependen de compras grandes puntuales, no de un flujo estable

| Mes | Pedidos | Ventas |
|---|---|---|
| 2026-01 | 3 | $3.495.000 |
| 2026-02 | 4 | $627.000 |
| 2026-03 | 3 | $1.495.000 |
| 2026-04 | 3 | $396.000 |
| 2026-05 | 2 | $450.000 |
| 2026-06 | 1 | $120.000 |

Enero fue el mes más fuerte por dos ventas de alta gama (una guitarra eléctrica y
una batería). Febrero tuvo más pedidos que enero pero vendió 5 veces menos, porque
fueron compras chicas. Desde abril las ventas caen y junio es el peor mes.
**Recomendación:** lanzar promociones a partir de abril para frenar la caída y
asegurar stock de instrumentos de alta gama para el comienzo del año.

### 3. Productos menos vendidos: pocas unidades no siempre significa poco rentable

| Producto | Categoría | Unidades | Ingresos |
|---|---|---|---|
| Funda acolchada para guitarra | Accesorios | 0 | $0 |
| Piano digital 88 teclas | Teclados | 1 | $1.350.000 |
| Batería acústica 5 cuerpos | Percusión | 1 | $1.600.000 |

La funda nunca se vendió, aunque se vendieron 4 guitarras.
**Recomendación:** ofrecerla en combo con cada guitarra.
El piano y la batería vendieron una sola unidad cada uno, pero juntos aportan el
45% de los ingresos: son productos de baja rotación y alto valor, que no deben discontinuarse.

### 4. Pedidos más importantes por categoría

| Categoría | Pedido #1 | Importe |
|---|---|---|
| Guitarras | Martina López – Guitarra eléctrica Stratocaster | $1.850.000 |
| Percusión | Juan Pérez – Batería acústica 5 cuerpos | $1.600.000 |
| Teclados | Sofía Gómez – Piano digital 88 teclas | $1.350.000 |
| Accesorios | Martina López – Juego de cuerdas (x3) | $45.000 |

En Guitarras, Percusión y Teclados, un solo pedido explica la mayor parte de lo que
vende la categoría. En Accesorios hay empates en el ranking (pedidos de $30.000
y de $25.000), lo que muestra compras chicas y repetidas.

### 5. Segmentación de clientes

| Segmento | Criterio | Clientes | % de ingresos |
|---|---|---|---|
| Premium | ≥ $1.000.000 | 3 (Martina, Juan, Sofía) | 80,5% |
| Medio | $300.000 – $999.999 | 2 (Lucía, Valentina) | 12,1% |
| Bajo | < $300.000 | 3 (Diego, Nicolás, Tomás) | 7,4% |

3 de 8 clientes generan el 80% de los ingresos. Los clientes del segmento Bajo
compraron instrumentos de entrada (guitarra criolla, cajón) y accesorios: son
candidatos a subir de segmento cuando quieran mejorar su instrumento.
**Recomendación:** ofrecerles planes de financiación o un "plan canje".

### Extra: aporte por categoría

| Categoría | Unidades | Ingresos | % ingresos |
|---|---|---|---|
| Guitarras | 4 | $2.390.000 | 36,2% |
| Teclados | 3 | $2.190.000 | 33,1% |
| Percusión | 3 | $1.840.000 | 27,8% |
| Accesorios | 13 | $188.000 | 2,8% |

Los accesorios son más de la mitad de las unidades vendidas, pero solo el 2,8% de
los ingresos. Su valor no está en lo que facturan sino en que hacen volver al
cliente a la tienda.

## Conclusión general
La facturación depende de pocos clientes y de pocas ventas de instrumentos de alta
gama. Las tres acciones prioritarias son:

1. Fidelizar a los clientes Premium.
2. Convertir a los clientes de segmento Bajo en compradores de instrumentos de mayor valor.
3. Usar los accesorios (y combos como guitarra + funda) para generar visitas
   frecuentes y suavizar la caída de ventas de mitad de año.

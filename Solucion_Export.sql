create database exportaciones;
use exportaciones;
-- converios a tipo fehca 
UPDATE promperuexportaciones
-- Conversion a fechas, los que tienen fechas 
SET fechaInicio = STR_TO_DATE(fechaInicio, '%d/%m/%Y');
UPDATE promperuexportaciones
SET fechaFinal = STR_TO_DATE(fechaFinal, '%d/%m/%Y');
ALTER TABLE promperuexportaciones
MODIFY COLUMN `fechaInicio` DATE;
ALTER TABLE promperuexportaciones
MODIFY COLUMN `fechaFinal` DATE;

-- 1 Pais con mayores esportaciones de cualquier tipo de aceituna  2022
select * from promperuexportaciones;
SELECT País, sum(`Valor FOB USD.`) as totalExportadoFOB
from promperuexportaciones 
where  Descripción Like '%aceituna%' and YEAR(`fechaInicio`) = 2022
group by País
ORDER BY totalExportadoFOB DESC
LIMIT 1; 

-- 2 Misma pregunta nro 1, para el 2023
select * from promperuexportaciones;
SELECT País, sum(`Valor FOB USD.`) as totalExportadoFOB
from promperuexportaciones 
where  Descripción Like '%aceituna%' and YEAR(`fechaInicio`) = 2023
group by País
ORDER BY totalExportadoFOB DESC
LIMIT 1; 

-- 3.- Compara para cada país, a donde se exporte aceituna (FOB), el que tuvo 
-- menos variación respecto al año anterior

select  sub.País ,
		anio,
        sub.totalExportadoFOB, 
        -- Hacemos un particion por pais y ordenamos por año,
        -- Significa que tomaremos el valor anterior de año con la funcion Lag Y la depositaremos como el valor ExpoAnioFobAnte
		LAG(totalExportadoFOB) OVER(PARTITION BY sub.País order by anio) ExpoAnioFobAnte,
        -- Hacemos la misma particion para hallar la resta y la dividimos por el valor del año anteior 
		((sub.totalExportadoFOB - LAG(sub.totalExportadoFOB) OVER (PARTITION BY sub.País ORDER BY anio)) / LAG(sub.totalExportadoFOB) OVER (PARTITION BY sub.País ORDER BY anio)) AS Variación
FROM(
	SELECT 	País, 
			sum(`Valor FOB USD.`) as totalExportadoFOB,
            year(`fechaInicio`) as anio
	from 
		promperuexportaciones 
	where 
    Descripción like '%aceituna%'
    
	group by 
	País, anio) as sub;
    
 
 --  4.- Compara TODAS las exportaciones totales de los países del periodo del 2022 y
--  del 2023 y ve cuales de los tres son los que tienen menos variación respecto al año 
-- anterior tuvo
 select sub2.País, sub2.Variación
 from
 (select  sub.País ,
		anio,
        sub.totalExportadoFOB, 
        -- Hacemos un particion por pais y ordenamos por año,
        -- Significa que tomaremos el valor anterior de año con la funcion Lag Y la depositaremos como el valor ExpoAnioFobAnte
		LAG(totalExportadoFOB) OVER(PARTITION BY sub.País order by anio) ExpoAnioFobAnte,
        -- Hacemos la misma particion para hallar la resta y la dividimos por el valor del año anteior 
		((sub.totalExportadoFOB - LAG(sub.totalExportadoFOB) OVER (PARTITION BY sub.País ORDER BY anio)) / LAG(sub.totalExportadoFOB) OVER (PARTITION BY sub.País ORDER BY anio)) AS Variación

FROM(
	SELECT 	País, 
			sum(`Valor FOB USD.`) as totalExportadoFOB,
            year(`fechaInicio`) as anio
	from 
		promperuexportaciones 
       
	group by 
	País, anio) as sub  ) as sub2
WHERE sub2.Variación IS NOT NULL
order by  sub2.Variación DESC
LIMIT 3;

-- 5 Del país que vendido más aceituna, cual es el tipo de aceituna que se vendido más 
-- dentro de ese país y cuál fue su variación respecto al año anterior en ese tipo de aceituna

-- 5.1  Creacion de tablas temporales 
-- 5.1.1 Creacion de las ventas Totales por pais
select sub.País,
	sub.Descripción,
	sub.TotalPorTipo,
	sub.TotalPorTipoAñoAnterior,
	sub.Variación
FROM
(SELECT
        País,
        Descripción,
        SUM(`Valor FOB USD.`) AS TotalPorTipo,
        year (fechaInicio) as anio,
    LAG(SUM(`Valor FOB USD.`), 1, 0) OVER (PARTITION BY País, Descripción ORDER BY YEAR(fechaInicio)) AS TotalPorTipoAñoAnterior,
    (SUM(`Valor FOB USD.`) - LAG(SUM(`Valor FOB USD.`), 1, 0) OVER (PARTITION BY País, Descripción ORDER BY YEAR(fechaInicio))) / LAG(SUM(`Valor FOB USD.`), 1, 0) OVER (PARTITION BY País, Descripción ORDER BY YEAR(fechaInicio)) AS Variación

   FROM
        promperuexportaciones
    WHERE
        Descripción LIKE '%aceituna%'
        
    GROUP BY
        País, Descripción,  anio )as sub
	where sub.Variación IS NOT NULL
    ORDER BY
	sub.TotalPorTipo DESC
	
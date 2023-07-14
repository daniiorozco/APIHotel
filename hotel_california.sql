-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-07-2023 a las 22:55:01
-- Versión del servidor: 10.4.27-MariaDB
-- Versión de PHP: 8.2.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `hotel_california`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `spi_cliente` (IN `usuario` VARCHAR(60), IN `clave` VARCHAR(60), IN `nombre` VARCHAR(60), IN `apellido` VARCHAR(60))   BEGIN
    insert INTO usuario (usuario,clave,rol) VALUES (usuario,clave,"cliente");
  
   -- Obtener el último ID insertado en la tabla de usuario
    SELECT LAST_INSERT_ID() INTO @ultimo_id;
    
    INSERT into cliente (nombre,apellido,id_usuario) VALUES (nombre,apellido,@ultimo_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spi_habitacion` (IN `numero_habitacion` INT, IN `precio` DOUBLE, IN `estado` TINYINT)   BEGIN
  INSERT INTO habitacion (numero_habitacion,precio,estado) VALUES (numero_habitacion,precio,estado);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spi_reserva` (IN `p_id_cliente` INT, IN `p_id_habitacion` INT, IN `p_fecha_inicio_hospedaje` DATE, IN `p_fecha_fin_hospedaje` DATE)   BEGIN
     DECLARE habitacion_disponible INT;

    -- Verificar si la habitación está disponible para el período especificado
    SELECT COUNT(*) INTO habitacion_disponible
    FROM reserva r
    WHERE r.id_habitacion = p_id_habitacion
        AND (p_fecha_inicio_hospedaje BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje
            OR p_fecha_fin_hospedaje BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje);

    -- Si la habitación está disponible, realizar la reserva
    IF habitacion_disponible = 0 THEN
        -- Insertar la reserva en la tabla de reservas
        INSERT INTO reserva (id_cliente, id_habitacion, fecha_inicio_hospedaje, fecha_fin_hospedaje) 
        VALUES (p_id_cliente, p_id_habitacion, p_fecha_inicio_hospedaje, p_fecha_fin_hospedaje); 
        
        SELECT 'Reserva realizada correctamente' AS mensaje ;
    ELSE
        SELECT 'La habitación no está disponible para el período especificado'AS mensaje;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_habitaciones` (IN `fecha` DATE)   BEGIN
   IF EXISTS(SELECT * FROM reserva r WHERE fecha BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje)
   THEN
       UPDATE habitacion h INNER JOIN reserva r ON h.id = r.id_habitacion SET estado = 0  WHERE fecha BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje;
    
   END IF;
 SELECT numero_habitacion,precio,estado FROM habitacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_habitaciones_x_busqueda` (IN `fecha_inicio` DATE, IN `fecha_fin` DATE, IN `precio` DOUBLE, IN `id_habitacion` INT)   BEGIN
-- Búsqueda de habitaciones disponibles en un rango de fechas
  IF fecha_inicio IS NOT NULL AND fecha_fin IS NOT NULL THEN
   IF EXISTS(SELECT 1 FROM reserva r WHERE fecha_inicio BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje 
             OR fecha_fin BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje)
   THEN
       UPDATE habitacion h INNER JOIN reserva r ON h.id = r.id_habitacion SET estado = 0  WHERE fecha_inicio BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje
        OR fecha_fin BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje;
       
       SELECT * FROM habitacion h WHERE h.estado = 1;
       
  -- Búsqueda de habitaciones con un precio menor al elegido
  ELSEIF precio IS NOT NULL THEN
    SELECT h.numero_habitacion, h.precio
    FROM habitacion h
    WHERE h.precio < precio;
    
    -- Búsqueda de una habitación en particular y sus reservas
    ELSEIF id_habitacion IS NOT NULL THEN
      SELECT h.numero_habitacion,h.precio,r.fecha_inicio_hospedaje,r.fecha_fin_hospedaje FROM habitacion h INNER JOIN reserva r
      ON h.id = r.id_habitacion
      WHERE h.id = id_habitacion;
   END IF;
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_habitaciones_x_fechas` (IN `fecha_inicio` DATE, IN `fecha_fin` DATE)   BEGIN
-- Búsqueda de habitaciones disponibles en un rango de fechas
 
  SELECT h.numero_habitacion,h.precio  FROM habitacion h
  WHERE h.id NOT IN(
    SELECT r.id_habitacion FROM reserva r
    WHERE (fecha_inicio BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje)
            OR (fecha_fin BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_habitaciones_x_numero` (IN `id_habitacion` INT)   BEGIN

    SELECT h.numero_habitacion, h.precio, r.id_cliente,r.fecha_inicio_hospedaje,r.fecha_fin_hospedaje 
    FROM reserva r INNER JOIN habitacion h
    ON h.id = r.id_habitacion
    WHERE h.id = id_habitacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_habitaciones_x_precio` (IN `precio_habitacion` DOUBLE)   BEGIN
      select numero_habitacion,precio FROM habitacion h where h.precio < precio_habitacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_reservas` ()   BEGIN
   SELECT * FROM reserva;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sps_reserva_x_fecha` (IN `fecha` DATE)   BEGIN
   SELECT * FROM reserva r WHERE fecha BETWEEN r.fecha_inicio_hospedaje AND r.fecha_fin_hospedaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spu_estado_habitacion` (IN `numHabitacion` INT, IN `estado` TINYINT)   BEGIN
  UPDATE habitacion h SET h.estado = estado 
  WHERE h.numero_habitacion = numHabitacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spu_habitacion` (IN `id` INT, IN `precio` DOUBLE, IN `estado` TINYINT)   BEGIN

 UPDATE habitacion SET precio = precio, estado = estado WHERE id = id;
  
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spu_precio_habitacion` (IN `num_habitacion` INT, IN `precio` DOUBLE)   BEGIN
   UPDATE habitacion h SET h.precio = precio 
   WHERE h.numero_habitacion = 
      num_habitacion;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `id` int(11) NOT NULL,
  `nombre` varchar(60) NOT NULL,
  `apellido` varchar(60) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `alta_fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `baja_fecha` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`id`, `nombre`, `apellido`, `id_usuario`, `alta_fecha`, `baja_fecha`) VALUES
(1, 'Daniela', 'Londoño', 1, '2023-07-06 20:16:23', NULL),
(2, 'Pedro', 'Perez', 2, '2023-07-06 20:37:38', NULL),
(3, 'Tony', 'orozco', 3, '2023-07-12 01:19:35', NULL),
(4, 'alma', 'villa', 5, '2023-07-14 19:50:16', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleado`
--

CREATE TABLE `empleado` (
  `id` int(11) NOT NULL,
  `nombre` varchar(60) NOT NULL,
  `apellido` varchar(60) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `alta_fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `baja_fecha` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `empleado`
--

INSERT INTO `empleado` (`id`, `nombre`, `apellido`, `id_usuario`, `alta_fecha`, `baja_fecha`) VALUES
(1, 'admin', 'admin', 4, '2023-07-13 18:06:52', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `habitacion`
--

CREATE TABLE `habitacion` (
  `id` int(11) NOT NULL,
  `precio` double NOT NULL,
  `numero_habitacion` int(11) NOT NULL,
  `estado` tinyint(1) NOT NULL,
  `alta_fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `baja_fecha` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `habitacion`
--

INSERT INTO `habitacion` (`id`, `precio`, `numero_habitacion`, `estado`, `alta_fecha`, `baja_fecha`) VALUES
(1, 3500, 1, 1, '2023-07-06 20:21:17', NULL),
(2, 4500, 2, 1, '2023-07-06 20:38:50', NULL),
(3, 2800, 3, 1, '2023-07-07 16:26:51', NULL),
(4, 4000, 4, 1, '2023-07-10 16:02:32', NULL),
(5, 3000, 5, 1, '2023-07-12 18:22:05', NULL),
(6, 3000, 6, 1, '2023-07-13 18:13:08', NULL),
(8, 3800, 7, 1, '2023-07-13 20:55:18', NULL),
(9, 3800, 8, 1, '2023-07-14 19:32:00', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reserva`
--

CREATE TABLE `reserva` (
  `id` int(11) NOT NULL,
  `id_habitacion` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `alta_fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `fecha_inicio_hospedaje` date DEFAULT NULL,
  `fecha_fin_hospedaje` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `reserva`
--

INSERT INTO `reserva` (`id`, `id_habitacion`, `id_cliente`, `alta_fecha`, `fecha_inicio_hospedaje`, `fecha_fin_hospedaje`) VALUES
(1, 1, 1, '2023-07-06 20:31:39', '2023-07-10', '2023-07-14'),
(2, 1, 2, '2023-07-07 14:49:33', '2023-07-15', '2023-07-17'),
(5, 4, 2, '2023-07-10 19:28:57', '2023-07-15', '2023-07-18'),
(6, 2, 2, '2023-07-12 18:24:13', '2023-07-19', '2023-07-21'),
(7, 2, 3, '2023-07-12 18:46:51', '2023-07-22', '2023-07-24'),
(8, 3, 3, '2023-07-12 19:50:17', '2023-07-18', '2023-07-21'),
(9, 3, 2, '2023-07-13 18:18:32', '2023-07-24', '2023-07-26'),
(10, 4, 2, '2023-07-13 18:26:06', '2023-07-23', '2023-07-25'),
(11, 3, 1, '2023-07-14 19:43:03', '2023-07-29', '2023-07-30');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id` int(11) NOT NULL,
  `usuario` varchar(60) NOT NULL,
  `clave` varchar(60) NOT NULL,
  `rol` varchar(60) NOT NULL,
  `alta_fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `baja_fecha` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id`, `usuario`, `clave`, `rol`, `alta_fecha`, `baja_fecha`) VALUES
(1, 'dani9997', '12345', 'cliente', '2023-07-06 20:16:23', NULL),
(2, 'pepe', '12345', 'cliente', '2023-07-06 20:37:38', NULL),
(3, 'Tony02', '12345', 'cliente', '2023-07-12 01:19:35', NULL),
(4, 'admisin', 'admisin', 'empleado', '2023-07-13 18:06:39', NULL),
(5, 'almita01', '12345', 'cliente', '2023-07-14 19:50:16', NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `habitacion`
--
ALTER TABLE `habitacion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `numero_habitacion` (`numero_habitacion`);

--
-- Indices de la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_habitacion` (`id_habitacion`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `empleado`
--
ALTER TABLE `empleado`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `habitacion`
--
ALTER TABLE `habitacion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `reserva`
--
ALTER TABLE `reserva`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD CONSTRAINT `id_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `id_habitacion` FOREIGN KEY (`id_habitacion`) REFERENCES `habitacion` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

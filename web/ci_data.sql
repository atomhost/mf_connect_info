-- phpMyAdmin SQL Dump
-- version 3.4.11.1deb2
-- http://www.phpmyadmin.net
--
-- Хост: localhost
-- Время создания: Мар 06 2015 г., 00:11
-- Версия сервера: 5.5.37
-- Версия PHP: 5.4.4-14+deb7u9

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- База данных: `_connect`
--

-- --------------------------------------------------------

--
-- Структура таблицы `ci_data`
--

CREATE TABLE IF NOT EXISTS `ci_data` (
  `id64` bigint(20) NOT NULL,
  `steam` tinyint(1) NOT NULL,
  `name` varchar(254) CHARACTER SET utf8 NOT NULL,
  `provider` varchar(254) CHARACTER SET utf8 NOT NULL,
  `vac_banned` tinyint(1) NOT NULL,
  `vac_ban_count` int(11) NOT NULL,
  `last_update` int(11) NOT NULL,
  UNIQUE KEY `id64` (`id64`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

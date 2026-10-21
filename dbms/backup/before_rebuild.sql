-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: skyroute_db
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `skyroute_db`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `skyroute_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `skyroute_db`;

--
-- Table structure for table `aircraft`
--

DROP TABLE IF EXISTS `aircraft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aircraft` (
  `aircraft_id` int NOT NULL AUTO_INCREMENT,
  `tail_number` varchar(12) NOT NULL,
  `model` varchar(60) NOT NULL,
  `capacity` int NOT NULL,
  `airline_id` int NOT NULL,
  PRIMARY KEY (`aircraft_id`),
  UNIQUE KEY `uq_aircraft_tail` (`tail_number`),
  KEY `fk_aircraft_airline` (`airline_id`),
  CONSTRAINT `fk_aircraft_airline` FOREIGN KEY (`airline_id`) REFERENCES `airlines` (`airline_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `aircraft_chk_1` CHECK (((`capacity` > 0) and (`capacity` <= 850)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `aircraft`
--

LOCK TABLES `aircraft` WRITE;
/*!40000 ALTER TABLE `aircraft` DISABLE KEYS */;
/*!40000 ALTER TABLE `aircraft` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `airlines`
--

DROP TABLE IF EXISTS `airlines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airlines` (
  `airline_id` int NOT NULL AUTO_INCREMENT,
  `airline_name` varchar(80) NOT NULL,
  `iata_code` char(2) NOT NULL,
  `country` varchar(50) NOT NULL DEFAULT 'India',
  PRIMARY KEY (`airline_id`),
  UNIQUE KEY `uq_airlines_name` (`airline_name`),
  UNIQUE KEY `uq_airlines_iata` (`iata_code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `airlines`
--

LOCK TABLES `airlines` WRITE;
/*!40000 ALTER TABLE `airlines` DISABLE KEYS */;
/*!40000 ALTER TABLE `airlines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `airports`
--

DROP TABLE IF EXISTS `airports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airports` (
  `airport_id` int NOT NULL AUTO_INCREMENT,
  `iata_code` char(3) NOT NULL,
  `airport_name` varchar(100) NOT NULL,
  `city` varchar(50) NOT NULL,
  `country` varchar(50) NOT NULL DEFAULT 'India',
  PRIMARY KEY (`airport_id`),
  UNIQUE KEY `uq_airports_iata` (`iata_code`),
  UNIQUE KEY `uq_airports_name` (`airport_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `airports`
--

LOCK TABLES `airports` WRITE;
/*!40000 ALTER TABLE `airports` DISABLE KEYS */;
/*!40000 ALTER TABLE `airports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `baggage`
--

DROP TABLE IF EXISTS `baggage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `baggage` (
  `booking_id` int NOT NULL,
  `baggage_seq` int NOT NULL,
  `weight_kg` decimal(5,2) NOT NULL,
  PRIMARY KEY (`booking_id`,`baggage_seq`),
  CONSTRAINT `fk_baggage_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `baggage_chk_1` CHECK (((`weight_kg` > 0) and (`weight_kg` <= 100)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `baggage`
--

LOCK TABLES `baggage` WRITE;
/*!40000 ALTER TABLE `baggage` DISABLE KEYS */;
/*!40000 ALTER TABLE `baggage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookings` (
  `booking_id` int NOT NULL AUTO_INCREMENT,
  `passenger_id` int NOT NULL,
  `departure_id` int NOT NULL,
  `seat_number` varchar(5) NOT NULL,
  `travel_class` enum('Economy','Premium Economy','Business','First') NOT NULL DEFAULT 'Economy',
  `price` decimal(10,2) NOT NULL,
  `booking_status` enum('Pending','Confirmed','Cancelled','Refunded') NOT NULL DEFAULT 'Confirmed',
  `booked_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`booking_id`),
  UNIQUE KEY `uq_booking_seat` (`departure_id`,`seat_number`),
  KEY `fk_booking_passenger` (`passenger_id`),
  CONSTRAINT `fk_booking_departure` FOREIGN KEY (`departure_id`) REFERENCES `departures` (`departure_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_booking_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bookings_chk_1` CHECK ((`price` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookings`
--

LOCK TABLES `bookings` WRITE;
/*!40000 ALTER TABLE `bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_ins`
--

DROP TABLE IF EXISTS `check_ins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `check_ins` (
  `checkin_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `checkin_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `boarding_status` enum('Not Boarded','Boarding','Boarded','No Show') NOT NULL DEFAULT 'Not Boarded',
  PRIMARY KEY (`checkin_id`),
  UNIQUE KEY `uq_checkin_booking` (`booking_id`),
  CONSTRAINT `fk_checkin_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_ins`
--

LOCK TABLES `check_ins` WRITE;
/*!40000 ALTER TABLE `check_ins` DISABLE KEYS */;
/*!40000 ALTER TABLE `check_ins` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departures`
--

DROP TABLE IF EXISTS `departures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departures` (
  `departure_id` int NOT NULL AUTO_INCREMENT,
  `flight_id` int NOT NULL,
  `scheduled_departure` datetime NOT NULL,
  `scheduled_arrival` datetime NOT NULL,
  `actual_departure` datetime DEFAULT NULL,
  `actual_arrival` datetime DEFAULT NULL,
  `departure_status` enum('Scheduled','Boarding','Departed','Arrived','Delayed','Cancelled') NOT NULL DEFAULT 'Scheduled',
  `aircraft_id` int DEFAULT NULL,
  `gate_id` int DEFAULT NULL,
  PRIMARY KEY (`departure_id`),
  UNIQUE KEY `uq_departure` (`flight_id`,`scheduled_departure`),
  KEY `fk_departure_aircraft` (`aircraft_id`),
  KEY `fk_departure_gate` (`gate_id`),
  CONSTRAINT `fk_departure_aircraft` FOREIGN KEY (`aircraft_id`) REFERENCES `aircraft` (`aircraft_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_departure_flight` FOREIGN KEY (`flight_id`) REFERENCES `flights` (`flight_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_departure_gate` FOREIGN KEY (`gate_id`) REFERENCES `gates` (`gate_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_departure_times` CHECK ((`scheduled_arrival` > `scheduled_departure`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departures`
--

LOCK TABLES `departures` WRITE;
/*!40000 ALTER TABLE `departures` DISABLE KEYS */;
/*!40000 ALTER TABLE `departures` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `flights`
--

DROP TABLE IF EXISTS `flights`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `flights` (
  `flight_id` int NOT NULL AUTO_INCREMENT,
  `flight_number` varchar(10) NOT NULL,
  `airline_id` int NOT NULL,
  `departure_airport_id` int NOT NULL,
  `arrival_airport_id` int NOT NULL,
  `sched_departure` time NOT NULL,
  `sched_arrival` time NOT NULL,
  `flight_status` enum('Active','Suspended') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`flight_id`),
  UNIQUE KEY `uq_flights_number` (`flight_number`),
  KEY `fk_flights_airline` (`airline_id`),
  KEY `fk_flights_departure` (`departure_airport_id`),
  KEY `fk_flights_arrival` (`arrival_airport_id`),
  CONSTRAINT `fk_flights_airline` FOREIGN KEY (`airline_id`) REFERENCES `airlines` (`airline_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_flights_arrival` FOREIGN KEY (`arrival_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_flights_departure` FOREIGN KEY (`departure_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `flights`
--

LOCK TABLES `flights` WRITE;
/*!40000 ALTER TABLE `flights` DISABLE KEYS */;
/*!40000 ALTER TABLE `flights` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_flights_route` BEFORE INSERT ON `flights` FOR EACH ROW BEGIN
  IF NEW.departure_airport_id = NEW.arrival_airport_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Route must differ: same-airport flight refused';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_flights_route_upd` BEFORE UPDATE ON `flights` FOR EACH ROW BEGIN
  IF NEW.departure_airport_id = NEW.arrival_airport_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Route must differ: same-airport flight refused';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `gates`
--

DROP TABLE IF EXISTS `gates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gates` (
  `gate_id` int NOT NULL AUTO_INCREMENT,
  `terminal_id` int NOT NULL,
  `gate_number` varchar(6) NOT NULL,
  `gate_status` enum('Open','Closed','Maintenance') NOT NULL DEFAULT 'Open',
  PRIMARY KEY (`gate_id`),
  UNIQUE KEY `uq_gate` (`terminal_id`,`gate_number`),
  CONSTRAINT `fk_gate_terminal` FOREIGN KEY (`terminal_id`) REFERENCES `terminals` (`terminal_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gates`
--

LOCK TABLES `gates` WRITE;
/*!40000 ALTER TABLE `gates` DISABLE KEYS */;
/*!40000 ALTER TABLE `gates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passengers`
--

DROP TABLE IF EXISTS `passengers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `passengers` (
  `passenger_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(60) NOT NULL,
  `last_name` varchar(60) NOT NULL,
  `passport_number` varchar(20) DEFAULT NULL,
  `nationality` varchar(50) NOT NULL DEFAULT 'India',
  `phone` varchar(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  PRIMARY KEY (`passenger_id`),
  UNIQUE KEY `uq_passenger_email` (`email`),
  UNIQUE KEY `uq_passenger_passport` (`passport_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passengers`
--

LOCK TABLES `passengers` WRITE;
/*!40000 ALTER TABLE `passengers` DISABLE KEYS */;
/*!40000 ALTER TABLE `passengers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `pay_method` enum('UPI','Credit Card','Debit Card','Net Banking','Cash') NOT NULL,
  `pay_status` enum('Pending','Paid','Failed','Refunded') NOT NULL DEFAULT 'Pending',
  `txn_reference` varchar(50) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `uq_payment_booking` (`booking_id`),
  UNIQUE KEY `uq_payment_txn` (`txn_reference`),
  CONSTRAINT `fk_payment_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payments_chk_1` CHECK ((`amount` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `terminals`
--

DROP TABLE IF EXISTS `terminals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `terminals` (
  `terminal_id` int NOT NULL AUTO_INCREMENT,
  `airport_id` int NOT NULL,
  `terminal_code` varchar(4) NOT NULL,
  `terminal_name` varchar(100) NOT NULL,
  `terminal_status` enum('Operational','Under Construction','Closed') NOT NULL DEFAULT 'Operational',
  PRIMARY KEY (`terminal_id`),
  UNIQUE KEY `uq_terminal` (`airport_id`,`terminal_code`),
  CONSTRAINT `fk_terminal_airport` FOREIGN KEY (`airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `terminals`
--

LOCK TABLES `terminals` WRITE;
/*!40000 ALTER TABLE `terminals` DISABLE KEYS */;
/*!40000 ALTER TABLE `terminals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'skyroute_db'
--

--
-- Current Database: `skyroute_app`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `skyroute_app` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `skyroute_app`;

--
-- Table structure for table `aircraft`
--

DROP TABLE IF EXISTS `aircraft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aircraft` (
  `aircraft_id` int NOT NULL AUTO_INCREMENT,
  `tail_number` varchar(16) NOT NULL,
  `model` varchar(80) NOT NULL,
  `capacity` int NOT NULL,
  `airline_id` int NOT NULL,
  PRIMARY KEY (`aircraft_id`),
  UNIQUE KEY `tail_number` (`tail_number`),
  KEY `airline_id` (`airline_id`),
  CONSTRAINT `aircraft_ibfk_1` FOREIGN KEY (`airline_id`) REFERENCES `airlines` (`airline_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `aircraft_chk_1` CHECK (((`capacity` > 0) and (`capacity` <= 850)))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `aircraft`
--

LOCK TABLES `aircraft` WRITE;
/*!40000 ALTER TABLE `aircraft` DISABLE KEYS */;
INSERT INTO `aircraft` VALUES (1,'VT-SK101','Airbus A320neo',180,1),(2,'VT-SK102','Airbus A321neo',222,1),(3,'VT-SK201','Airbus A321',182,2),(4,'VT-SK301','Boeing 737-8',189,3),(5,'VT-SK103','ATR 72-600',78,1);
/*!40000 ALTER TABLE `aircraft` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `airlines`
--

DROP TABLE IF EXISTS `airlines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airlines` (
  `airline_id` int NOT NULL AUTO_INCREMENT,
  `airline_name` varchar(80) NOT NULL,
  `iata_code` varchar(8) NOT NULL,
  `country` varchar(80) NOT NULL DEFAULT 'India',
  PRIMARY KEY (`airline_id`),
  UNIQUE KEY `airline_name` (`airline_name`),
  UNIQUE KEY `iata_code` (`iata_code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `airlines`
--

LOCK TABLES `airlines` WRITE;
/*!40000 ALTER TABLE `airlines` DISABLE KEYS */;
INSERT INTO `airlines` VALUES (1,'IndiGo','6E','India'),(2,'Air India','AI','India'),(3,'SpiceJet','SG','India');
/*!40000 ALTER TABLE `airlines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `airports`
--

DROP TABLE IF EXISTS `airports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airports` (
  `airport_id` int NOT NULL AUTO_INCREMENT,
  `iata_code` varchar(8) NOT NULL,
  `airport_name` varchar(120) NOT NULL,
  `city` varchar(80) NOT NULL,
  `country` varchar(80) NOT NULL DEFAULT 'India',
  PRIMARY KEY (`airport_id`),
  UNIQUE KEY `iata_code` (`iata_code`),
  UNIQUE KEY `airport_name` (`airport_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `airports`
--

LOCK TABLES `airports` WRITE;
/*!40000 ALTER TABLE `airports` DISABLE KEYS */;
INSERT INTO `airports` VALUES (1,'HYD','Rajiv Gandhi International Airport','Hyderabad','India'),(2,'BLR','Kempegowda International Airport','Bengaluru','India'),(3,'BOM','Chhatrapati Shivaji Maharaj International Airport','Mumbai','India'),(4,'DEL','Indira Gandhi International Airport','New Delhi','India'),(5,'MAA','Chennai International Airport','Chennai','India');
/*!40000 ALTER TABLE `airports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `baggage`
--

DROP TABLE IF EXISTS `baggage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `baggage` (
  `booking_id` int NOT NULL,
  `baggage_seq` int NOT NULL,
  `weight_kg` double NOT NULL,
  PRIMARY KEY (`booking_id`,`baggage_seq`),
  CONSTRAINT `baggage_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `baggage_chk_1` CHECK (((`weight_kg` > 0) and (`weight_kg` <= 100)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `baggage`
--

LOCK TABLES `baggage` WRITE;
/*!40000 ALTER TABLE `baggage` DISABLE KEYS */;
INSERT INTO `baggage` VALUES (1,1,9.42),(2,1,18.45),(3,1,14.98),(4,1,21.13),(5,1,22.13),(6,1,7.76),(7,1,30.66),(8,1,31.21),(9,1,14.79),(10,1,5.48),(11,1,31.83),(12,1,5.04),(13,1,11.3),(14,1,16.38),(15,1,17.32),(16,1,15.58),(17,1,18.79),(18,1,16.06),(19,1,11.16),(20,1,5.52),(21,1,21.21),(22,1,18.48),(23,1,10.02),(24,1,15.75),(25,1,23.92),(26,1,8.51),(27,1,11.99),(28,1,18.7),(29,1,12.45),(30,1,28.99),(31,1,9.41),(32,1,14.01),(33,1,6.13),(34,1,25.66),(35,1,14.97),(36,1,13.94),(37,1,10.53),(38,1,20),(39,1,14.77),(40,1,29.92),(41,1,7.78),(42,1,5.47),(43,1,5.95),(44,1,14.96),(45,1,6.37),(46,1,9.07),(47,1,11.27),(48,1,13.5),(49,1,5.27),(50,1,10.86),(51,1,5.09),(52,1,17.31),(53,1,10.47),(54,1,5.78),(55,1,18.65),(56,1,18.91),(57,1,10.22),(58,1,18.88),(59,1,16.3),(60,1,17.56),(61,1,26.05),(62,1,14.55),(63,1,27.63),(64,1,17.85),(65,1,7.94),(66,1,8.27),(67,1,16.28),(68,1,16.76),(69,1,31.96),(70,1,19.73),(71,1,17.16),(72,1,15.82),(73,1,10.26),(74,1,18.45),(75,1,25.75),(76,1,18.8),(77,1,14.24),(78,1,5.55),(79,1,14.55),(80,1,18.43),(81,1,8.97),(82,1,17.87),(83,1,13.7),(84,1,13.04),(85,1,10.57),(86,1,27.14),(87,1,6.22),(88,1,16.15),(89,1,12.74),(90,1,19.76),(91,1,30.8),(92,1,8.32),(93,1,11.48),(94,1,11.76),(95,1,18.07),(96,1,8.96),(97,1,17.31),(98,1,13.68),(99,1,8.73),(100,1,12.97),(101,1,7.39),(102,1,13.26),(103,1,7.99),(104,1,11.23),(105,1,5.96),(106,1,13.86),(107,1,19.32),(108,1,21.26),(109,1,8.09),(110,1,19.24),(111,1,27.76),(112,1,6.99),(113,1,10.05),(114,1,8.85),(115,1,16.4),(116,1,14.03),(117,1,27.61),(118,1,5.47),(119,1,10.2),(120,1,8.25),(121,1,9.31),(122,1,8.03),(123,1,12.36),(124,1,17.38),(125,1,19.36),(126,1,19.16),(127,1,31.29),(128,1,6.65),(129,1,19.87),(130,1,14.42),(131,1,18.93),(132,1,14.69),(133,1,8.95),(134,1,10.69),(135,1,21.96),(136,1,9.9),(137,1,25.68),(138,1,7.54),(139,1,8.86),(140,1,11.93),(141,1,9.01),(142,1,19.62),(143,1,10.23),(144,1,28.32),(145,1,9.7),(146,1,23.29),(147,1,14.44),(148,1,26.05),(149,1,11.14),(150,1,24.27),(151,1,12.35),(152,1,13.15),(153,1,19.27),(154,1,6.52),(155,1,8.07),(156,1,14.59),(157,1,11.16),(158,1,15.27),(159,1,18.99),(160,1,8.79),(161,1,5.2),(162,1,27.73),(163,1,6.64),(164,1,19.1),(165,1,31.93),(166,1,7.47),(167,1,27.79),(168,1,15.81),(169,1,14.58),(170,1,9.42),(171,1,16.7),(172,1,11.04),(173,1,18.37),(174,1,18.41),(175,1,15.39),(176,1,17.59),(177,1,8.97),(178,1,25.94),(179,1,12.01),(180,1,8.7),(181,1,17.94),(182,1,9.81),(183,1,9.45),(184,1,11.28),(185,1,10.41),(186,1,5.69),(187,1,21.58),(188,1,18.46),(189,1,11.23),(190,1,17.93),(191,1,16.68),(192,1,8.16),(193,1,8.77),(194,1,23.87),(195,1,12.56),(196,1,24.47),(197,1,16.88),(198,1,15.7),(199,1,14.52),(200,1,18.78),(201,1,15.2),(202,1,11.19),(203,1,12.08),(204,1,11.4),(205,1,6.83),(206,1,6.82),(207,1,15.79),(208,1,16.16),(209,1,16.21),(210,1,6.26),(211,1,11.91),(212,1,21.11),(213,1,5.22),(214,1,9.69),(215,1,30.1),(216,1,19.23),(217,1,7.5),(218,1,14.67),(219,1,16.67),(220,1,29.52),(221,1,9.2),(222,1,28.85),(223,1,27.41),(224,1,19.65),(225,1,15.27),(226,1,23.76),(227,1,9.02),(228,1,17.24),(229,1,7.11),(230,1,19.63),(231,1,18.71),(232,1,13.1),(233,1,8.01),(234,1,18.88),(235,1,19.2),(236,1,5.57),(237,1,24.85),(238,1,13.36),(239,1,17.68),(240,1,27.86),(241,1,6.35),(242,1,14.61),(243,1,11.73),(244,1,8.53),(245,1,19.13),(246,1,13.29),(247,1,21.04),(248,1,14.7),(249,1,7.17),(250,1,28.28),(251,1,11.62),(252,1,10.58),(253,1,12.22),(254,1,17.11),(255,1,18.69),(256,1,17.49),(257,1,30.47),(258,1,19.37),(259,1,27.73),(260,1,24.21),(261,1,14.42),(262,1,16.04),(263,1,13.3),(264,1,7.24),(265,1,7.34),(266,1,9.45),(267,1,6.64),(268,1,15.9),(269,1,14.6),(270,1,24.42),(271,1,16.84),(272,1,10.4),(273,1,23.01),(274,1,17.65),(275,1,15.67),(276,1,17.43),(277,1,7.63),(278,1,15.62),(279,1,8.03),(280,1,31.47),(281,1,5.38),(282,1,8.65),(283,1,7.74),(284,1,13.33),(285,1,18.89),(286,1,17.56),(287,1,8.58),(288,1,18.04),(289,1,6.85),(290,1,16.42),(291,1,11.08),(292,1,8.41),(293,1,13.59),(294,1,17.39),(295,1,13.96),(296,1,19.56),(297,1,10.08),(298,1,28.73),(299,1,31),(300,1,21.12),(301,1,15.2),(302,1,11.33),(303,1,9.31),(304,1,13.55),(305,1,15.66),(306,1,23.99),(307,1,9.66),(308,1,7.83),(309,1,13.79),(310,1,22.37),(311,1,9.88),(312,1,19.81),(313,1,5.33),(314,1,18.07),(315,1,12.75),(316,1,16.44),(317,1,19.39),(318,1,15.02),(319,1,14.24),(320,1,26.45),(321,1,14.46),(322,1,6.55),(323,1,13.79),(324,1,19.89),(325,1,16.76),(326,1,11.78),(327,1,10.29),(328,1,13.33),(329,1,5.1),(330,1,9.5),(331,1,7.17),(332,1,8.48),(333,1,17.65),(334,1,22.85),(335,1,31.89),(336,1,12.86),(337,1,18.4),(338,1,14.45),(339,1,19.91),(340,1,5.16),(341,1,15.36),(342,1,25.07),(343,1,15.02),(344,1,16.53),(345,1,14.7),(346,1,7.16),(347,1,6.82),(348,1,12.64),(349,1,7.56),(350,1,12.01),(351,1,21.21),(352,1,13.68),(353,1,10.31),(354,1,14.43),(355,1,7.87),(356,1,8.3),(357,1,19.39),(358,1,8.57),(359,1,18.96),(360,1,18.48),(361,1,14.04),(362,1,10.81),(363,1,8.56),(364,1,5.38),(365,1,6.95),(366,1,17.53),(367,1,12.01),(368,1,10.29),(369,1,19.38),(370,1,12.14),(371,1,11.79),(372,1,31.98),(373,1,10.52),(374,1,12.65),(375,1,21.91),(376,1,17.78),(377,1,15.77),(378,1,15.75),(379,1,17.67),(380,1,18.24),(381,1,22.53),(382,1,14.95),(383,1,20.79),(384,1,17.7),(385,1,21.62),(386,1,18.69),(387,1,5.89),(388,1,6.39),(389,1,15.29),(390,1,8.57),(391,1,15.37),(392,1,24.54),(393,1,15.62),(394,1,14.44),(395,1,16.41),(396,1,7.32),(397,1,25.17),(398,1,9.34),(399,1,5.65),(400,1,6.66),(401,1,6.69),(402,1,13.54),(403,1,6.08),(404,1,19.7),(405,1,15.76),(406,1,14.68),(407,1,16.76),(408,1,18.79),(409,1,19.03),(410,1,6.17),(411,1,10.93),(412,1,7.79),(413,1,31.16),(414,1,15.78),(415,1,9.9),(416,1,10.34),(417,1,13.27),(418,1,23.42),(419,1,13.5),(420,1,19.29),(421,1,7.05),(422,1,14.51),(423,1,16.1),(424,1,13.69),(425,1,11.25),(426,1,11.62),(427,1,7.71),(428,1,6.68),(429,1,7.81),(430,1,8.4),(431,1,13.59),(432,1,18.64),(433,1,11.12),(434,1,22.04),(435,1,15.72),(436,1,19.41),(437,1,17.45),(438,1,19.52),(439,1,16.62),(440,1,14.28),(441,1,10.59),(442,1,19.33),(443,1,15.61),(444,1,21.51),(445,1,18.76),(446,1,16.18),(447,1,28.96),(448,1,21.91),(449,1,12.87),(450,1,5.65),(451,1,13.23),(452,1,18.65),(453,1,19.37),(454,1,9.94),(455,1,6.96),(456,1,17.29),(457,1,12.03),(458,1,10.03),(459,1,5.31),(460,1,27.5),(461,1,7.15),(462,1,12.5),(463,1,13.6),(464,1,31.91),(465,1,30.88),(466,1,29.4),(467,1,10.44),(468,1,8.57),(469,1,9.56),(470,1,12.63),(471,1,13.26),(472,1,15.56),(473,1,29.5),(474,1,8.65),(475,1,22.23),(476,1,27.21),(477,1,9.56),(478,1,24.61),(479,1,18.83),(480,1,7.63),(481,1,16.38),(482,1,5.3),(483,1,8.01),(484,1,27.95),(485,1,9.9),(486,1,11.08),(487,1,17.95),(488,1,14.19),(489,1,25.09),(490,1,20.8),(491,1,19.81),(492,1,15.65),(493,1,5.28),(494,1,6.83),(495,1,13.33),(496,1,14.09),(497,1,30.51),(498,1,10.26),(499,1,17.9),(500,1,10.16),(501,1,9.86),(502,1,16),(503,1,31.01),(504,1,13.46),(505,1,24.82),(506,1,5.31),(507,1,10.31),(508,1,14.64),(509,1,26.23),(510,1,12.16),(511,1,22.07),(512,1,9.97),(513,1,23.37),(514,1,13.96),(515,1,5.78),(516,1,28.96),(517,1,17.95),(518,1,7.1),(519,1,17.08),(520,1,20.61),(521,1,6.66),(522,1,26.54),(523,1,15.28),(524,1,13.18),(525,1,17.59),(526,1,8.23),(527,1,9.09),(528,1,9.04),(529,1,5.72),(530,1,23.57),(531,1,14.8),(532,1,9.96),(533,1,30.55),(534,1,9.77),(535,1,7.27),(536,1,29.74),(537,1,10.43),(538,1,7.31),(539,1,10.47),(540,1,11.79),(541,1,9.36),(542,1,11.74),(543,1,7.62),(544,1,15.2),(545,1,14.9),(546,1,17.02),(547,1,8.01),(548,1,13.86),(549,1,9.12),(550,1,8.98),(551,1,14.54),(552,1,11.35),(553,1,10.57),(554,1,10.64),(555,1,9.43),(556,1,14.11),(557,1,10.78),(558,1,14.28),(559,1,14.98),(560,1,21.42),(561,1,12.89),(562,1,27.89),(563,1,13.45),(564,1,11.54),(565,1,5.98),(566,1,12.68),(567,1,16.11),(568,1,18.89),(569,1,16.54),(570,1,8.31),(571,1,5.23),(572,1,16.3),(573,1,17.36),(574,1,15.6),(575,1,5.13),(576,1,13.47),(577,1,8.3),(578,1,15.66),(579,1,15.92),(580,1,21.16),(581,1,21.93),(582,1,21.33),(583,1,18.84),(584,1,7.46),(585,1,15.12),(586,1,26.65),(587,1,18.77),(588,1,11.98),(589,1,19.26),(590,1,17.5),(591,1,7.32),(592,1,22.03),(593,1,23.88),(594,1,29.67),(595,1,9.64),(596,1,17.62),(597,1,28.15),(598,1,5.49),(599,1,9.37),(600,1,7.97),(601,1,8.71),(602,1,16.82),(603,1,28.82),(604,1,13.27),(605,1,11.92),(606,1,13.69),(607,1,6.98),(608,1,21.38),(609,1,14.94),(610,1,17.63),(611,1,8.92),(612,1,21.85),(613,1,13.12),(614,1,7.46),(615,1,8.84),(616,1,13.33),(617,1,28.86),(618,1,18.36),(619,1,5.8),(620,1,16.16),(621,1,7.3),(622,1,16.55),(623,1,8.29),(624,1,6),(625,1,12.2),(626,1,9.95),(627,1,14.55),(628,1,21.08),(629,1,6.39),(630,1,17.05),(631,1,16.18),(632,1,15.41),(633,1,29.07),(634,1,17.38),(635,1,19.41),(636,1,14.49),(637,1,29.56),(638,1,17.71),(639,1,11.87),(640,1,27.11),(641,1,16.76),(642,1,25.17),(643,1,15.08),(644,1,18.56),(645,1,15.14),(646,1,16.3),(647,1,16.3),(648,1,6.14),(649,1,19.37),(650,1,15.64),(651,1,29.8),(652,1,26.23),(653,1,5.27),(654,1,11.72),(655,1,28.88),(656,1,9.88),(657,1,19.05),(658,1,13.81),(659,1,19.97),(660,1,14.62),(661,1,8.63),(662,1,13.22),(663,1,17.07),(664,1,19.62),(665,1,9.16),(666,1,26.2),(667,1,10.21),(668,1,17.11),(669,1,16.08),(670,1,18.61),(671,1,29.44),(672,1,22.65),(673,1,25.96),(674,1,25.14),(675,1,9.79),(676,1,8.06),(677,1,11.12),(678,1,19.11),(679,1,12.5),(680,1,7.79),(681,1,12.82),(682,1,10.08),(683,1,21.27),(684,1,28.18),(685,1,8.21),(686,1,15.19),(687,1,15.07),(688,1,18.48),(689,1,17.31),(690,1,22.01),(691,1,9.13),(692,1,14.07),(693,1,8.2),(694,1,10.4),(695,1,29.72),(696,1,12.76),(697,1,24.24),(698,1,16.46),(699,1,11.81),(700,1,14.24),(701,1,9.24),(702,1,18.46),(703,1,7.97),(704,1,8.02),(705,1,19.22),(706,1,8.08),(707,1,27.88),(708,1,10.33),(709,1,9.74),(710,1,5.66),(711,1,11.32),(712,1,25.73),(713,1,17.87),(714,1,12.07),(715,1,29.64),(716,1,31.73),(717,1,8.77),(718,1,8.78),(719,1,22.72),(720,1,31.78),(721,1,15.89),(722,1,30.18),(723,1,6.67),(724,1,5.41),(725,1,5.65);
/*!40000 ALTER TABLE `baggage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookings` (
  `booking_id` int NOT NULL AUTO_INCREMENT,
  `passenger_id` int NOT NULL,
  `departure_id` int NOT NULL,
  `seat_number` varchar(8) NOT NULL,
  `travel_class` varchar(24) NOT NULL DEFAULT 'Economy',
  `price` double NOT NULL,
  `booking_status` varchar(16) NOT NULL DEFAULT 'Confirmed',
  `booked_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`booking_id`),
  UNIQUE KEY `departure_id` (`departure_id`,`seat_number`),
  KEY `passenger_id` (`passenger_id`),
  CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`departure_id`) REFERENCES `departures` (`departure_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bookings_chk_1` CHECK ((`travel_class` in (_utf8mb4'Economy',_utf8mb4'Premium Economy',_utf8mb4'Business',_utf8mb4'First'))),
  CONSTRAINT `bookings_chk_2` CHECK ((`price` >= 0)),
  CONSTRAINT `bookings_chk_3` CHECK ((`booking_status` in (_utf8mb4'Pending',_utf8mb4'Confirmed',_utf8mb4'Cancelled',_utf8mb4'Refunded')))
) ENGINE=InnoDB AUTO_INCREMENT=726 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookings`
--

LOCK TABLES `bookings` WRITE;
/*!40000 ALTER TABLE `bookings` DISABLE KEYS */;
INSERT INTO `bookings` VALUES (1,450,23,'22B','Economy',4742,'Confirmed','2026-10-12 21:53:08'),(2,115,23,'29E','Economy',5215,'Confirmed','2026-10-12 21:53:08'),(3,102,23,'28D','Economy',5193,'Confirmed','2026-10-12 21:53:08'),(4,73,23,'18F','Economy',4499,'Confirmed','2026-10-12 21:53:08'),(5,308,23,'4C','Economy',4248,'Confirmed','2026-10-12 21:53:08'),(6,540,23,'11F','Economy',4306,'Confirmed','2026-10-12 21:53:08'),(7,599,23,'10E','Economy',5120,'Confirmed','2026-10-12 21:53:08'),(8,197,23,'29C','Economy',4431,'Confirmed','2026-10-12 21:53:08'),(9,398,23,'19A','Economy',4874,'Confirmed','2026-10-12 21:53:08'),(10,268,23,'16E','Economy',5274,'Confirmed','2026-10-12 21:53:08'),(11,229,23,'31C','Economy',4975,'Confirmed','2026-10-12 21:53:08'),(12,2,23,'22A','Economy',5106,'Confirmed','2026-10-12 21:53:08'),(13,11,23,'2C','Economy',4773,'Confirmed','2026-10-12 21:53:08'),(14,553,23,'15C','Economy',4453,'Confirmed','2026-10-12 21:53:08'),(15,309,23,'31F','Economy',4978,'Confirmed','2026-10-12 21:53:08'),(16,474,23,'16C','Economy',5085,'Confirmed','2026-10-12 21:53:08'),(17,286,23,'17F','Economy',4600,'Confirmed','2026-10-12 21:53:08'),(18,324,23,'9C','Economy',4595,'Confirmed','2026-10-12 21:53:08'),(19,249,23,'1B','Economy',5171,'Confirmed','2026-10-12 21:53:08'),(20,489,23,'13C','Economy',5028,'Confirmed','2026-10-12 21:53:08'),(21,541,23,'22D','Economy',4328,'Confirmed','2026-10-12 21:53:08'),(22,241,23,'3F','Economy',4599,'Confirmed','2026-10-12 21:53:08'),(23,563,23,'9E','Economy',4894,'Confirmed','2026-10-12 21:53:08'),(24,253,23,'30D','Economy',4289,'Confirmed','2026-10-12 21:53:08'),(25,30,23,'9D','Economy',4848,'Confirmed','2026-10-12 21:53:08'),(26,424,23,'14B','Economy',4333,'Confirmed','2026-10-12 21:53:08'),(27,315,23,'9B','Economy',5173,'Confirmed','2026-10-12 21:53:08'),(28,57,23,'10F','Economy',4991,'Confirmed','2026-10-12 21:53:08'),(29,23,23,'20F','Economy',5210,'Confirmed','2026-10-12 21:53:08'),(30,199,23,'10C','Economy',4217,'Confirmed','2026-10-12 21:53:08'),(31,162,26,'29C','Economy',4965,'Confirmed','2026-10-12 21:53:08'),(32,252,26,'6B','Economy',4444,'Confirmed','2026-10-12 21:53:08'),(33,350,26,'13D','Economy',5394,'Confirmed','2026-10-12 21:53:08'),(34,342,26,'30F','Economy',5249,'Confirmed','2026-10-12 21:53:08'),(35,491,26,'12F','Economy',4732,'Confirmed','2026-10-12 21:53:08'),(36,385,26,'25B','Economy',4212,'Confirmed','2026-10-12 21:53:08'),(37,86,26,'12C','Economy',4916,'Confirmed','2026-10-12 21:53:08'),(38,545,26,'16F','Economy',4489,'Confirmed','2026-10-12 21:53:08'),(39,211,26,'11F','Economy',4278,'Confirmed','2026-10-12 21:53:08'),(40,418,26,'12A','Economy',4616,'Confirmed','2026-10-12 21:53:08'),(41,171,26,'9C','Economy',5037,'Confirmed','2026-10-12 21:53:08'),(42,265,26,'19E','Economy',4839,'Confirmed','2026-10-12 21:53:08'),(43,434,26,'11D','Economy',5215,'Confirmed','2026-10-12 21:53:08'),(44,72,26,'8F','Economy',4407,'Confirmed','2026-10-12 21:53:08'),(45,39,26,'11C','Economy',4516,'Confirmed','2026-10-12 21:53:08'),(46,513,26,'11A','Economy',4535,'Confirmed','2026-10-12 21:53:08'),(47,588,26,'7D','Economy',4780,'Confirmed','2026-10-12 21:53:08'),(48,580,26,'13A','Economy',4305,'Confirmed','2026-10-12 21:53:08'),(49,348,26,'25E','Economy',4931,'Confirmed','2026-10-12 21:53:08'),(50,172,26,'9A','Economy',4945,'Confirmed','2026-10-12 21:53:08'),(51,454,26,'14F','Economy',5029,'Confirmed','2026-10-12 21:53:08'),(52,114,26,'3E','Economy',4520,'Confirmed','2026-10-12 21:53:08'),(53,79,26,'17F','Economy',5031,'Confirmed','2026-10-12 21:53:08'),(54,284,26,'11E','Economy',4532,'Confirmed','2026-10-12 21:53:08'),(55,92,26,'28F','Economy',4491,'Confirmed','2026-10-12 21:53:08'),(56,222,26,'22D','Economy',4382,'Confirmed','2026-10-12 21:53:08'),(57,105,26,'23C','Economy',5233,'Confirmed','2026-10-12 21:53:08'),(58,448,26,'10F','Economy',4531,'Confirmed','2026-10-12 21:53:08'),(59,530,26,'5B','Economy',4422,'Confirmed','2026-10-12 21:53:08'),(60,476,26,'20E','Economy',4604,'Confirmed','2026-10-12 21:53:08'),(61,185,26,'2D','Economy',4289,'Confirmed','2026-10-12 21:53:08'),(62,250,26,'5C','Economy',4309,'Confirmed','2026-10-12 21:53:08'),(63,144,26,'1B','Economy',4376,'Confirmed','2026-10-12 21:53:08'),(64,443,26,'21B','Economy',4528,'Confirmed','2026-10-12 21:53:08'),(65,251,26,'26E','Economy',5028,'Confirmed','2026-10-12 21:53:08'),(66,574,26,'20A','Economy',5168,'Confirmed','2026-10-12 21:53:08'),(67,578,6,'27C','Economy',5247,'Confirmed','2026-10-12 21:53:08'),(68,174,6,'21F','Economy',4973,'Confirmed','2026-10-12 21:53:08'),(69,426,6,'20F','Economy',4252,'Confirmed','2026-10-12 21:53:08'),(70,399,6,'11A','Economy',4424,'Confirmed','2026-10-12 21:53:08'),(71,137,6,'20A','Economy',5207,'Confirmed','2026-10-12 21:53:08'),(72,166,6,'32C','Economy',4538,'Confirmed','2026-10-12 21:53:08'),(73,278,6,'20D','Economy',4652,'Confirmed','2026-10-12 21:53:08'),(74,214,6,'8D','Economy',4716,'Confirmed','2026-10-12 21:53:08'),(75,47,6,'21B','Economy',4763,'Confirmed','2026-10-12 21:53:08'),(76,44,6,'18A','Economy',4720,'Confirmed','2026-10-12 21:53:08'),(77,362,6,'5D','Economy',4626,'Confirmed','2026-10-12 21:53:08'),(78,131,6,'3F','Economy',4686,'Confirmed','2026-10-12 21:53:08'),(79,433,6,'6C','Economy',4572,'Confirmed','2026-10-12 21:53:08'),(80,507,6,'16B','Economy',4769,'Confirmed','2026-10-12 21:53:08'),(81,343,6,'19C','Economy',4545,'Confirmed','2026-10-12 21:53:08'),(82,469,6,'16D','Economy',5286,'Confirmed','2026-10-12 21:53:08'),(83,345,6,'4F','Economy',5127,'Confirmed','2026-10-12 21:53:08'),(84,281,6,'19F','Economy',4414,'Confirmed','2026-10-12 21:53:08'),(85,475,6,'22D','Economy',5007,'Confirmed','2026-10-12 21:53:08'),(86,432,6,'22E','Economy',4969,'Confirmed','2026-10-12 21:53:08'),(87,410,6,'29A','Economy',4937,'Confirmed','2026-10-12 21:53:08'),(88,498,6,'2E','Economy',4671,'Confirmed','2026-10-12 21:53:08'),(89,561,6,'28F','Economy',4298,'Confirmed','2026-10-12 21:53:08'),(90,488,6,'28A','Economy',4835,'Confirmed','2026-10-12 21:53:08'),(91,199,6,'6D','Economy',5399,'Confirmed','2026-10-12 21:53:08'),(92,27,6,'4D','Economy',4203,'Confirmed','2026-10-12 21:53:08'),(93,5,6,'14C','Economy',4795,'Confirmed','2026-10-12 21:53:08'),(94,56,21,'12C','Economy',4698,'Confirmed','2026-10-12 21:53:08'),(95,151,21,'5E','Economy',4330,'Confirmed','2026-10-12 21:53:08'),(96,566,21,'9E','Economy',4752,'Confirmed','2026-10-12 21:53:08'),(97,262,21,'13C','Economy',4223,'Confirmed','2026-10-12 21:53:08'),(98,54,21,'7C','Economy',4917,'Confirmed','2026-10-12 21:53:08'),(99,28,21,'3F','Economy',5260,'Confirmed','2026-10-12 21:53:08'),(100,64,21,'5C','Economy',4200,'Confirmed','2026-10-12 21:53:08'),(101,4,21,'8E','Economy',5031,'Confirmed','2026-10-12 21:53:08'),(102,407,21,'11A','Economy',4414,'Confirmed','2026-10-12 21:53:08'),(103,352,21,'4C','Economy',4603,'Confirmed','2026-10-12 21:53:08'),(104,122,21,'13A','Economy',5238,'Confirmed','2026-10-12 21:53:08'),(105,411,21,'1B','Economy',4557,'Confirmed','2026-10-12 21:53:08'),(106,559,16,'36E','Economy',4295,'Confirmed','2026-10-12 21:53:08'),(107,9,16,'23D','Economy',4944,'Confirmed','2026-10-12 21:53:08'),(108,440,16,'30E','Economy',5293,'Confirmed','2026-10-12 21:53:08'),(109,512,16,'1B','Economy',4986,'Confirmed','2026-10-12 21:53:08'),(110,544,16,'2A','Economy',4429,'Confirmed','2026-10-12 21:53:08'),(111,95,16,'19D','Economy',4379,'Confirmed','2026-10-12 21:53:08'),(112,529,16,'31F','Economy',4788,'Confirmed','2026-10-12 21:53:08'),(113,204,16,'10F','Economy',4619,'Confirmed','2026-10-12 21:53:08'),(114,266,16,'25C','Economy',4734,'Confirmed','2026-10-12 21:53:08'),(115,123,16,'14A','Economy',4778,'Confirmed','2026-10-12 21:53:08'),(116,306,16,'34E','Economy',4857,'Confirmed','2026-10-12 21:53:08'),(117,273,16,'10A','Economy',5175,'Confirmed','2026-10-12 21:53:08'),(118,48,16,'17E','Economy',4263,'Confirmed','2026-10-12 21:53:08'),(119,143,16,'27D','Economy',5262,'Confirmed','2026-10-12 21:53:08'),(120,390,16,'25F','Economy',4298,'Confirmed','2026-10-12 21:53:08'),(121,308,16,'4B','Economy',4386,'Confirmed','2026-10-12 21:53:08'),(122,64,16,'25A','Economy',5093,'Confirmed','2026-10-12 21:53:08'),(123,312,16,'8B','Economy',4310,'Confirmed','2026-10-12 21:53:08'),(124,511,16,'7B','Economy',5206,'Confirmed','2026-10-12 21:53:08'),(125,311,16,'2C','Economy',5212,'Confirmed','2026-10-12 21:53:08'),(126,346,16,'37B','Economy',5255,'Confirmed','2026-10-12 21:53:08'),(127,255,16,'5E','Economy',4781,'Confirmed','2026-10-12 21:53:08'),(128,100,16,'5D','Economy',4674,'Confirmed','2026-10-12 21:53:08'),(129,594,16,'35E','Economy',4365,'Confirmed','2026-10-12 21:53:08'),(130,19,16,'7F','Economy',5349,'Confirmed','2026-10-12 21:53:08'),(131,196,16,'15E','Economy',4928,'Confirmed','2026-10-12 21:53:08'),(132,305,16,'7A','Economy',4376,'Confirmed','2026-10-12 21:53:08'),(133,277,16,'30F','Economy',4961,'Confirmed','2026-10-12 21:53:08'),(134,235,16,'2B','Economy',5316,'Confirmed','2026-10-12 21:53:08'),(135,186,16,'33B','Economy',4678,'Confirmed','2026-10-12 21:53:08'),(136,380,16,'2E','Economy',4269,'Confirmed','2026-10-12 21:53:08'),(137,223,16,'6F','Economy',4518,'Confirmed','2026-10-12 21:53:08'),(138,458,16,'30D','Economy',5334,'Confirmed','2026-10-12 21:53:08'),(139,382,16,'28C','Economy',5098,'Confirmed','2026-10-12 21:53:08'),(140,282,16,'28A','Economy',4673,'Confirmed','2026-10-12 21:53:08'),(141,445,16,'32F','Economy',4687,'Confirmed','2026-10-12 21:53:08'),(142,549,16,'37D','Economy',4516,'Confirmed','2026-10-12 21:53:08'),(143,552,16,'3F','Economy',4868,'Confirmed','2026-10-12 21:53:08'),(144,602,24,'1D','Economy',5395,'Confirmed','2026-10-12 21:53:08'),(145,119,24,'18A','Economy',4454,'Confirmed','2026-10-12 21:53:08'),(146,160,24,'37C','Economy',4400,'Confirmed','2026-10-12 21:53:08'),(147,601,24,'34E','Economy',5019,'Confirmed','2026-10-12 21:53:08'),(148,462,24,'19D','Economy',4712,'Confirmed','2026-10-12 21:53:08'),(149,67,24,'30D','Economy',4240,'Confirmed','2026-10-12 21:53:08'),(150,106,24,'10C','Economy',4574,'Confirmed','2026-10-12 21:53:08'),(151,414,24,'22C','Economy',4221,'Confirmed','2026-10-12 21:53:08'),(152,124,24,'27F','Economy',4417,'Confirmed','2026-10-12 21:53:08'),(153,237,24,'13D','Economy',4529,'Confirmed','2026-10-12 21:53:08'),(154,96,24,'20E','Economy',4609,'Confirmed','2026-10-12 21:53:08'),(155,93,24,'1F','Economy',5376,'Confirmed','2026-10-12 21:53:08'),(156,499,24,'7A','Economy',5174,'Confirmed','2026-10-12 21:53:08'),(157,187,24,'11F','Economy',4957,'Confirmed','2026-10-12 21:53:08'),(158,464,24,'26E','Economy',5135,'Confirmed','2026-10-12 21:53:08'),(159,183,24,'32C','Economy',5003,'Confirmed','2026-10-12 21:53:08'),(160,274,24,'18B','Economy',4928,'Confirmed','2026-10-12 21:53:08'),(161,169,24,'1B','Economy',4982,'Confirmed','2026-10-12 21:53:08'),(162,70,24,'32D','Economy',5057,'Confirmed','2026-10-12 21:53:08'),(163,400,24,'11C','Economy',4921,'Confirmed','2026-10-12 21:53:08'),(164,575,24,'19C','Economy',4821,'Confirmed','2026-10-12 21:53:08'),(165,69,24,'30F','Economy',5279,'Confirmed','2026-10-12 21:53:08'),(166,173,24,'25C','Economy',5002,'Confirmed','2026-10-12 21:53:08'),(167,129,24,'26A','Economy',4341,'Confirmed','2026-10-12 21:53:08'),(168,558,24,'32F','Economy',5160,'Confirmed','2026-10-12 21:53:08'),(169,239,24,'28D','Economy',4499,'Confirmed','2026-10-12 21:53:08'),(170,294,24,'18F','Economy',5046,'Confirmed','2026-10-12 21:53:08'),(171,24,24,'10E','Economy',5322,'Confirmed','2026-10-12 21:53:08'),(172,517,14,'29A','Economy',4512,'Confirmed','2026-10-12 21:53:08'),(173,562,14,'16C','Economy',5294,'Confirmed','2026-10-12 21:53:08'),(174,152,14,'7D','Economy',4385,'Confirmed','2026-10-12 21:53:08'),(175,176,14,'13F','Economy',4808,'Confirmed','2026-10-12 21:53:08'),(176,467,14,'17C','Economy',5287,'Confirmed','2026-10-12 21:53:08'),(177,247,14,'3C','Economy',4439,'Confirmed','2026-10-12 21:53:08'),(178,455,14,'4D','Economy',4679,'Confirmed','2026-10-12 21:53:08'),(179,166,14,'25A','Economy',5341,'Confirmed','2026-10-12 21:53:08'),(180,288,14,'14F','Economy',4495,'Confirmed','2026-10-12 21:53:08'),(181,449,14,'6F','Economy',4537,'Confirmed','2026-10-12 21:53:08'),(182,125,14,'23D','Economy',4213,'Confirmed','2026-10-12 21:53:08'),(183,324,14,'15E','Economy',5352,'Confirmed','2026-10-12 21:53:08'),(184,3,14,'28A','Economy',5153,'Confirmed','2026-10-12 21:53:08'),(185,528,14,'25F','Economy',4354,'Confirmed','2026-10-12 21:53:08'),(186,478,14,'1D','Economy',4258,'Confirmed','2026-10-12 21:53:08'),(187,525,14,'1C','Economy',4876,'Confirmed','2026-10-12 21:53:08'),(188,184,14,'9F','Economy',5191,'Confirmed','2026-10-12 21:53:08'),(189,236,14,'4A','Economy',4269,'Confirmed','2026-10-12 21:53:08'),(190,161,14,'13D','Economy',4459,'Confirmed','2026-10-12 21:53:08'),(191,430,14,'11E','Economy',4949,'Confirmed','2026-10-12 21:53:08'),(192,201,14,'26F','Economy',5334,'Confirmed','2026-10-12 21:53:08'),(193,213,14,'5B','Economy',5091,'Confirmed','2026-10-12 21:53:08'),(194,323,14,'25E','Economy',4307,'Confirmed','2026-10-12 21:53:08'),(195,326,14,'7A','Economy',5211,'Confirmed','2026-10-12 21:53:08'),(196,289,14,'10F','Economy',4756,'Confirmed','2026-10-12 21:53:08'),(197,412,14,'8F','Economy',4616,'Confirmed','2026-10-12 21:53:08'),(198,420,14,'20B','Economy',4877,'Confirmed','2026-10-12 21:53:08'),(199,58,14,'30F','Economy',4461,'Confirmed','2026-10-12 21:53:08'),(200,32,13,'2E','Economy',5062,'Confirmed','2026-10-12 21:53:08'),(201,286,13,'29C','Economy',5114,'Confirmed','2026-10-12 21:53:08'),(202,506,13,'28A','Economy',4518,'Confirmed','2026-10-12 21:53:08'),(203,387,13,'20D','Economy',4408,'Confirmed','2026-10-12 21:53:08'),(204,291,13,'27E','Economy',4510,'Confirmed','2026-10-12 21:53:08'),(205,381,13,'8C','Economy',4219,'Confirmed','2026-10-12 21:53:08'),(206,398,13,'5B','Economy',4380,'Confirmed','2026-10-12 21:53:08'),(207,37,13,'29B','Economy',5167,'Confirmed','2026-10-12 21:53:08'),(208,210,13,'8E','Economy',4696,'Confirmed','2026-10-12 21:53:08'),(209,76,13,'2D','Economy',4302,'Confirmed','2026-10-12 21:53:08'),(210,7,13,'18F','Economy',4496,'Confirmed','2026-10-12 21:53:08'),(211,35,13,'29F','Economy',5341,'Confirmed','2026-10-12 21:53:08'),(212,131,13,'28F','Economy',4720,'Confirmed','2026-10-12 21:53:08'),(213,578,13,'1D','Economy',4265,'Confirmed','2026-10-12 21:53:08'),(214,338,13,'16E','Economy',4363,'Confirmed','2026-10-12 21:53:08'),(215,424,13,'6F','Economy',4539,'Confirmed','2026-10-12 21:53:08'),(216,537,13,'14B','Economy',4322,'Confirmed','2026-10-12 21:53:08'),(217,465,13,'24F','Economy',5098,'Confirmed','2026-10-12 21:53:08'),(218,42,13,'12A','Economy',4439,'Confirmed','2026-10-12 21:53:08'),(219,554,13,'13F','Economy',5055,'Confirmed','2026-10-12 21:53:08'),(220,357,13,'8F','Economy',5127,'Confirmed','2026-10-12 21:53:08'),(221,379,13,'29E','Economy',5360,'Confirmed','2026-10-12 21:53:08'),(222,427,13,'2C','Economy',4880,'Confirmed','2026-10-12 21:53:08'),(223,267,13,'14D','Economy',4231,'Confirmed','2026-10-12 21:53:08'),(224,429,13,'1F','Economy',4832,'Confirmed','2026-10-12 21:53:08'),(225,101,13,'19C','Economy',4704,'Confirmed','2026-10-12 21:53:08'),(226,438,13,'25A','Economy',4679,'Confirmed','2026-10-12 21:53:08'),(227,476,13,'25E','Economy',4203,'Confirmed','2026-10-12 21:53:08'),(228,490,13,'3B','Economy',4522,'Confirmed','2026-10-12 21:53:08'),(229,485,13,'22B','Economy',4286,'Confirmed','2026-10-12 21:53:08'),(230,417,13,'25B','Economy',5371,'Confirmed','2026-10-12 21:53:08'),(231,481,13,'23B','Economy',5321,'Confirmed','2026-10-12 21:53:08'),(232,59,13,'30F','Economy',4910,'Confirmed','2026-10-12 21:53:08'),(233,145,13,'6A','Economy',5192,'Confirmed','2026-10-12 21:53:08'),(234,171,1,'9A','Economy',5361,'Confirmed','2026-10-12 21:53:08'),(235,224,1,'10A','Economy',4773,'Confirmed','2026-10-12 21:53:08'),(236,428,1,'9B','Economy',4468,'Confirmed','2026-10-12 21:53:08'),(237,46,1,'4F','Economy',4611,'Confirmed','2026-10-12 21:53:08'),(238,484,1,'8E','Economy',4256,'Confirmed','2026-10-12 21:53:08'),(239,287,1,'13C','Economy',5138,'Confirmed','2026-10-12 21:53:08'),(240,334,1,'16C','Economy',4331,'Confirmed','2026-10-12 21:53:08'),(241,504,1,'25D','Economy',4445,'Confirmed','2026-10-12 21:53:08'),(242,153,1,'25A','Economy',4852,'Confirmed','2026-10-12 21:53:08'),(243,188,1,'16B','Economy',5237,'Confirmed','2026-10-12 21:53:08'),(244,415,1,'18B','Economy',4527,'Confirmed','2026-10-12 21:53:08'),(245,533,1,'23A','Economy',4654,'Confirmed','2026-10-12 21:53:08'),(246,10,1,'7C','Economy',4920,'Confirmed','2026-10-12 21:53:08'),(247,566,1,'11D','Economy',4256,'Confirmed','2026-10-12 21:53:08'),(248,279,1,'2F','Economy',5251,'Confirmed','2026-10-12 21:53:08'),(249,331,1,'22A','Economy',5190,'Confirmed','2026-10-12 21:53:08'),(250,380,1,'16F','Economy',4211,'Confirmed','2026-10-12 21:53:08'),(251,68,1,'5D','Economy',4811,'Confirmed','2026-10-12 21:53:08'),(252,377,1,'28B','Economy',4415,'Confirmed','2026-10-12 21:53:08'),(253,573,1,'20E','Economy',4998,'Confirmed','2026-10-12 21:53:08'),(254,257,1,'4C','Economy',4545,'Confirmed','2026-10-12 21:53:08'),(255,547,1,'7D','Economy',4225,'Confirmed','2026-10-12 21:53:08'),(256,50,1,'14C','Economy',4273,'Confirmed','2026-10-12 21:53:08'),(257,288,1,'26C','Economy',4359,'Confirmed','2026-10-12 21:53:08'),(258,408,1,'2B','Economy',4486,'Confirmed','2026-10-12 21:53:08'),(259,369,1,'15E','Economy',4988,'Confirmed','2026-10-12 21:53:08'),(260,190,1,'12F','Economy',5126,'Confirmed','2026-10-12 21:53:08'),(261,592,1,'29A','Economy',4678,'Confirmed','2026-10-12 21:53:08'),(262,370,1,'1F','Economy',4492,'Confirmed','2026-10-12 21:53:08'),(263,231,1,'5A','Economy',4569,'Confirmed','2026-10-12 21:53:08'),(264,341,1,'2C','Economy',4496,'Confirmed','2026-10-12 21:53:08'),(265,362,1,'9E','Economy',5056,'Confirmed','2026-10-12 21:53:08'),(266,416,1,'29D','Economy',4755,'Confirmed','2026-10-12 21:53:08'),(267,149,1,'21E','Economy',4543,'Confirmed','2026-10-12 21:53:08'),(268,367,11,'3D','Economy',4532,'Confirmed','2026-10-12 21:53:08'),(269,90,11,'6C','Economy',4801,'Confirmed','2026-10-12 21:53:08'),(270,120,11,'5B','Economy',5105,'Confirmed','2026-10-12 21:53:08'),(271,390,11,'8E','Economy',4487,'Confirmed','2026-10-12 21:53:08'),(272,49,11,'10B','Economy',5278,'Confirmed','2026-10-12 21:53:08'),(273,484,11,'6D','Economy',4283,'Confirmed','2026-10-12 21:53:08'),(274,598,11,'6A','Economy',5370,'Confirmed','2026-10-12 21:53:08'),(275,509,11,'12F','Economy',5268,'Confirmed','2026-10-12 21:53:08'),(276,163,11,'3A','Economy',4602,'Confirmed','2026-10-12 21:53:08'),(277,423,11,'9B','Economy',5214,'Confirmed','2026-10-12 21:53:08'),(278,364,11,'7B','Economy',4480,'Confirmed','2026-10-12 21:53:08'),(279,217,11,'9F','Economy',4593,'Confirmed','2026-10-12 21:53:08'),(280,577,10,'2D','Economy',4797,'Confirmed','2026-10-12 21:53:08'),(281,404,10,'7F','Economy',5213,'Confirmed','2026-10-12 21:53:08'),(282,320,10,'30F','Economy',5300,'Confirmed','2026-10-12 21:53:08'),(283,568,10,'16F','Economy',4381,'Confirmed','2026-10-12 21:53:08'),(284,47,10,'25D','Economy',4410,'Confirmed','2026-10-12 21:53:08'),(285,403,10,'26C','Economy',4261,'Confirmed','2026-10-12 21:53:08'),(286,272,10,'1B','Economy',4599,'Confirmed','2026-10-12 21:53:08'),(287,263,10,'16B','Economy',5380,'Confirmed','2026-10-12 21:53:08'),(288,220,10,'23B','Economy',5109,'Confirmed','2026-10-12 21:53:08'),(289,502,10,'20A','Economy',4566,'Confirmed','2026-10-12 21:53:08'),(290,386,10,'23A','Economy',5210,'Confirmed','2026-10-12 21:53:08'),(291,78,10,'4A','Economy',4425,'Confirmed','2026-10-12 21:53:08'),(292,15,10,'6A','Economy',4480,'Confirmed','2026-10-12 21:53:08'),(293,321,10,'36E','Economy',4664,'Confirmed','2026-10-12 21:53:08'),(294,596,10,'31C','Economy',5012,'Confirmed','2026-10-12 21:53:08'),(295,373,10,'11C','Economy',4996,'Confirmed','2026-10-12 21:53:08'),(296,110,10,'14E','Economy',5276,'Confirmed','2026-10-12 21:53:08'),(297,521,10,'34B','Economy',4306,'Confirmed','2026-10-12 21:53:08'),(298,209,10,'35D','Economy',4692,'Confirmed','2026-10-12 21:53:08'),(299,198,10,'17B','Economy',5355,'Confirmed','2026-10-12 21:53:08'),(300,148,10,'37B','Economy',5020,'Confirmed','2026-10-12 21:53:08'),(301,444,10,'33A','Economy',5259,'Confirmed','2026-10-12 21:53:08'),(302,292,10,'3D','Economy',4923,'Confirmed','2026-10-12 21:53:08'),(303,300,5,'6B','Economy',4379,'Confirmed','2026-10-12 21:53:08'),(304,89,5,'23B','Economy',5130,'Confirmed','2026-10-12 21:53:08'),(305,435,5,'1D','Economy',4991,'Confirmed','2026-10-12 21:53:08'),(306,154,5,'19D','Economy',5143,'Confirmed','2026-10-12 21:53:08'),(307,62,5,'11A','Economy',5178,'Confirmed','2026-10-12 21:53:08'),(308,264,5,'2E','Economy',4696,'Confirmed','2026-10-12 21:53:08'),(309,354,5,'13B','Economy',5318,'Confirmed','2026-10-12 21:53:08'),(310,164,5,'5E','Economy',4224,'Confirmed','2026-10-12 21:53:08'),(311,412,5,'14A','Economy',4688,'Confirmed','2026-10-12 21:53:08'),(312,542,5,'15E','Economy',4752,'Confirmed','2026-10-12 21:53:08'),(313,18,5,'28D','Economy',4805,'Confirmed','2026-10-12 21:53:08'),(314,182,5,'8A','Economy',5328,'Confirmed','2026-10-12 21:53:08'),(315,116,5,'6A','Economy',5101,'Confirmed','2026-10-12 21:53:08'),(316,344,5,'3D','Economy',5100,'Confirmed','2026-10-12 21:53:08'),(317,325,5,'26C','Economy',5266,'Confirmed','2026-10-12 21:53:08'),(318,368,5,'22F','Economy',4516,'Confirmed','2026-10-12 21:53:08'),(319,518,5,'12C','Economy',4487,'Confirmed','2026-10-12 21:53:08'),(320,39,5,'4D','Economy',4766,'Confirmed','2026-10-12 21:53:08'),(321,36,5,'20F','Economy',5173,'Confirmed','2026-10-12 21:53:08'),(322,31,5,'26B','Economy',4460,'Confirmed','2026-10-12 21:53:08'),(323,522,5,'23E','Economy',5040,'Confirmed','2026-10-12 21:53:08'),(324,506,5,'7B','Economy',5219,'Confirmed','2026-10-12 21:53:08'),(325,216,5,'19E','Economy',4506,'Confirmed','2026-10-12 21:53:08'),(326,550,5,'31B','Economy',4427,'Confirmed','2026-10-12 21:53:08'),(327,510,5,'22E','Economy',5137,'Confirmed','2026-10-12 21:53:08'),(328,219,5,'6D','Economy',4922,'Confirmed','2026-10-12 21:53:08'),(329,515,5,'13D','Economy',4987,'Confirmed','2026-10-12 21:53:08'),(330,442,5,'18C','Economy',5223,'Confirmed','2026-10-12 21:53:08'),(331,33,5,'25D','Economy',5299,'Confirmed','2026-10-12 21:53:08'),(332,508,5,'30B','Economy',5378,'Confirmed','2026-10-12 21:53:08'),(333,85,5,'12E','Economy',4876,'Confirmed','2026-10-12 21:53:08'),(334,205,5,'11C','Economy',4696,'Confirmed','2026-10-12 21:53:08'),(335,13,9,'16F','Economy',4903,'Confirmed','2026-10-12 21:53:08'),(336,26,9,'22C','Economy',5061,'Confirmed','2026-10-12 21:53:08'),(337,51,9,'18A','Economy',5247,'Confirmed','2026-10-12 21:53:08'),(338,230,9,'28E','Economy',5044,'Confirmed','2026-10-12 21:53:08'),(339,497,9,'24F','Economy',4418,'Confirmed','2026-10-12 21:53:08'),(340,446,9,'25C','Economy',4286,'Confirmed','2026-10-12 21:53:08'),(341,269,9,'7D','Economy',4205,'Confirmed','2026-10-12 21:53:08'),(342,477,9,'9A','Economy',4208,'Confirmed','2026-10-12 21:53:08'),(343,276,9,'18F','Economy',4401,'Confirmed','2026-10-12 21:53:08'),(344,479,9,'21E','Economy',4602,'Confirmed','2026-10-12 21:53:08'),(345,551,9,'30F','Economy',5361,'Confirmed','2026-10-12 21:53:08'),(346,384,9,'19E','Economy',5288,'Confirmed','2026-10-12 21:53:08'),(347,460,9,'27D','Economy',4606,'Confirmed','2026-10-12 21:53:08'),(348,377,9,'26A','Economy',4521,'Confirmed','2026-10-12 21:53:08'),(349,348,9,'15D','Economy',4259,'Confirmed','2026-10-12 21:53:08'),(350,411,9,'23D','Economy',5270,'Confirmed','2026-10-12 21:53:08'),(351,319,9,'4F','Economy',5081,'Confirmed','2026-10-12 21:53:08'),(352,40,9,'8B','Economy',4225,'Confirmed','2026-10-12 21:53:08'),(353,531,9,'16C','Economy',4494,'Confirmed','2026-10-12 21:53:08'),(354,601,9,'14D','Economy',4546,'Confirmed','2026-10-12 21:53:08'),(355,314,9,'16D','Economy',5392,'Confirmed','2026-10-12 21:53:08'),(356,396,9,'4B','Economy',4989,'Confirmed','2026-10-12 21:53:08'),(357,71,9,'14B','Economy',5010,'Confirmed','2026-10-12 21:53:08'),(358,468,9,'22F','Economy',5100,'Confirmed','2026-10-12 21:53:08'),(359,205,9,'8C','Economy',4656,'Confirmed','2026-10-12 21:53:08'),(360,94,9,'5E','Economy',4555,'Confirmed','2026-10-12 21:53:08'),(361,360,9,'13D','Economy',5132,'Confirmed','2026-10-12 21:53:08'),(362,471,25,'4F','Economy',4919,'Confirmed','2026-10-12 21:53:08'),(363,77,25,'1A','Economy',5156,'Confirmed','2026-10-12 21:53:08'),(364,232,25,'7B','Economy',4271,'Confirmed','2026-10-12 21:53:08'),(365,368,25,'9C','Economy',4519,'Confirmed','2026-10-12 21:53:08'),(366,557,25,'12F','Economy',4602,'Confirmed','2026-10-12 21:53:08'),(367,210,25,'8E','Economy',4461,'Confirmed','2026-10-12 21:53:08'),(368,393,25,'3C','Economy',4691,'Confirmed','2026-10-12 21:53:08'),(369,299,25,'8A','Economy',5029,'Confirmed','2026-10-12 21:53:08'),(370,376,25,'12C','Economy',4626,'Confirmed','2026-10-12 21:53:08'),(371,461,25,'9B','Economy',4618,'Confirmed','2026-10-12 21:53:08'),(372,22,25,'12E','Economy',4468,'Confirmed','2026-10-12 21:53:08'),(373,91,25,'9D','Economy',5101,'Confirmed','2026-10-12 21:53:08'),(374,168,25,'2C','Economy',4704,'Confirmed','2026-10-12 21:53:08'),(375,167,25,'3D','Economy',4457,'Confirmed','2026-10-12 21:53:08'),(376,339,25,'10A','Economy',5250,'Confirmed','2026-10-12 21:53:08'),(377,359,25,'9E','Economy',4988,'Confirmed','2026-10-12 21:53:08'),(378,16,29,'12F','Economy',4790,'Confirmed','2026-10-12 21:53:08'),(379,375,29,'8E','Economy',4778,'Confirmed','2026-10-12 21:53:08'),(380,98,29,'11E','Economy',5151,'Confirmed','2026-10-12 21:53:08'),(381,178,29,'7C','Economy',4470,'Confirmed','2026-10-12 21:53:08'),(382,227,29,'5A','Economy',4950,'Confirmed','2026-10-12 21:53:08'),(383,313,29,'2C','Economy',4919,'Confirmed','2026-10-12 21:53:08'),(384,189,29,'7D','Economy',5147,'Confirmed','2026-10-12 21:53:08'),(385,118,29,'2F','Economy',4921,'Confirmed','2026-10-12 21:53:08'),(386,78,29,'5E','Economy',4796,'Confirmed','2026-10-12 21:53:08'),(387,53,18,'15E','Economy',4733,'Confirmed','2026-10-12 21:53:08'),(388,404,18,'4E','Economy',4932,'Confirmed','2026-10-12 21:53:08'),(389,600,18,'18E','Economy',4836,'Confirmed','2026-10-12 21:53:08'),(390,170,18,'17E','Economy',5196,'Confirmed','2026-10-12 21:53:08'),(391,431,18,'27B','Economy',4695,'Confirmed','2026-10-12 21:53:08'),(392,204,18,'10C','Economy',4472,'Confirmed','2026-10-12 21:53:08'),(393,303,18,'12F','Economy',4813,'Confirmed','2026-10-12 21:53:08'),(394,161,18,'23C','Economy',5353,'Confirmed','2026-10-12 21:53:08'),(395,378,18,'4F','Economy',4441,'Confirmed','2026-10-12 21:53:08'),(396,546,18,'15F','Economy',4546,'Confirmed','2026-10-12 21:53:08'),(397,310,18,'19A','Economy',5144,'Confirmed','2026-10-12 21:53:08'),(398,188,18,'19F','Economy',4622,'Confirmed','2026-10-12 21:53:08'),(399,565,18,'15D','Economy',4938,'Confirmed','2026-10-12 21:53:08'),(400,233,18,'22C','Economy',4775,'Confirmed','2026-10-12 21:53:08'),(401,569,18,'27E','Economy',4832,'Confirmed','2026-10-12 21:53:08'),(402,494,18,'28D','Economy',4864,'Confirmed','2026-10-12 21:53:08'),(403,521,18,'20B','Economy',4792,'Confirmed','2026-10-12 21:53:08'),(404,256,18,'22E','Economy',4222,'Confirmed','2026-10-12 21:53:08'),(405,437,18,'3B','Economy',5194,'Confirmed','2026-10-12 21:53:08'),(406,572,18,'9E','Economy',5354,'Confirmed','2026-10-12 21:53:08'),(407,349,18,'19B','Economy',5089,'Confirmed','2026-10-12 21:53:08'),(408,1,18,'22F','Economy',4859,'Confirmed','2026-10-12 21:53:08'),(409,127,18,'6C','Economy',4785,'Confirmed','2026-10-12 21:53:08'),(410,290,18,'21F','Economy',4714,'Confirmed','2026-10-12 21:53:08'),(411,55,18,'9A','Economy',4256,'Confirmed','2026-10-12 21:53:08'),(412,583,18,'2F','Economy',4497,'Confirmed','2026-10-12 21:53:08'),(413,597,18,'24F','Economy',5276,'Confirmed','2026-10-12 21:53:08'),(414,63,18,'12A','Economy',4545,'Confirmed','2026-10-12 21:53:08'),(415,246,18,'8C','Economy',4835,'Confirmed','2026-10-12 21:53:08'),(416,126,18,'24B','Economy',4577,'Confirmed','2026-10-12 21:53:08'),(417,52,18,'7F','Economy',4671,'Confirmed','2026-10-12 21:53:08'),(418,320,18,'11A','Economy',4956,'Confirmed','2026-10-12 21:53:08'),(419,214,18,'26A','Economy',4318,'Confirmed','2026-10-12 21:53:08'),(420,449,27,'3E','Economy',5357,'Confirmed','2026-10-12 21:53:08'),(421,73,27,'19E','Economy',5184,'Confirmed','2026-10-12 21:53:08'),(422,245,27,'1C','Economy',4903,'Confirmed','2026-10-12 21:53:08'),(423,540,27,'29C','Economy',4586,'Confirmed','2026-10-12 21:53:08'),(424,468,27,'8D','Economy',4374,'Confirmed','2026-10-12 21:53:08'),(425,544,27,'8A','Economy',5336,'Confirmed','2026-10-12 21:53:08'),(426,180,27,'17A','Economy',5285,'Confirmed','2026-10-12 21:53:08'),(427,332,27,'13D','Economy',4734,'Confirmed','2026-10-12 21:53:08'),(428,107,27,'1B','Economy',4615,'Confirmed','2026-10-12 21:53:08'),(429,164,27,'19F','Economy',4719,'Confirmed','2026-10-12 21:53:08'),(430,258,27,'25A','Economy',4715,'Confirmed','2026-10-12 21:53:08'),(431,191,27,'29E','Economy',5138,'Confirmed','2026-10-12 21:53:08'),(432,158,27,'15F','Economy',4431,'Confirmed','2026-10-12 21:53:08'),(433,487,27,'25B','Economy',5360,'Confirmed','2026-10-12 21:53:08'),(434,447,27,'9C','Economy',4350,'Confirmed','2026-10-12 21:53:08'),(435,112,27,'21A','Economy',5230,'Confirmed','2026-10-12 21:53:08'),(436,56,27,'4D','Economy',4434,'Confirmed','2026-10-12 21:53:08'),(437,486,27,'24A','Economy',5255,'Confirmed','2026-10-12 21:53:08'),(438,527,27,'14E','Economy',5002,'Confirmed','2026-10-12 21:53:08'),(439,217,27,'23A','Economy',4592,'Confirmed','2026-10-12 21:53:08'),(440,246,27,'20D','Economy',4480,'Confirmed','2026-10-12 21:53:08'),(441,415,27,'19B','Economy',5028,'Confirmed','2026-10-12 21:53:08'),(442,6,27,'23E','Economy',4231,'Confirmed','2026-10-12 21:53:08'),(443,41,27,'27E','Economy',5141,'Confirmed','2026-10-12 21:53:08'),(444,564,27,'7D','Economy',5072,'Confirmed','2026-10-12 21:53:08'),(445,470,27,'18A','Economy',4612,'Confirmed','2026-10-12 21:53:08'),(446,165,27,'26F','Economy',4926,'Confirmed','2026-10-12 21:53:08'),(447,318,27,'27C','Economy',4899,'Confirmed','2026-10-12 21:53:08'),(448,93,27,'4C','Economy',4223,'Confirmed','2026-10-12 21:53:08'),(449,77,27,'3D','Economy',4963,'Confirmed','2026-10-12 21:53:08'),(450,570,27,'15A','Economy',4931,'Confirmed','2026-10-12 21:53:08'),(451,466,27,'28A','Economy',4923,'Confirmed','2026-10-12 21:53:08'),(452,371,27,'13E','Economy',4431,'Confirmed','2026-10-12 21:53:08'),(453,420,2,'7A','Economy',5005,'Confirmed','2026-10-12 21:53:08'),(454,238,2,'26A','Economy',5258,'Confirmed','2026-10-12 21:53:08'),(455,526,2,'11E','Economy',4643,'Confirmed','2026-10-12 21:53:08'),(456,31,2,'23F','Economy',4289,'Confirmed','2026-10-12 21:53:08'),(457,523,2,'12C','Economy',5157,'Confirmed','2026-10-12 21:53:08'),(458,84,2,'19F','Economy',4924,'Confirmed','2026-10-12 21:53:08'),(459,472,2,'1D','Economy',5190,'Confirmed','2026-10-12 21:53:08'),(460,17,2,'2A','Economy',5140,'Confirmed','2026-10-12 21:53:08'),(461,296,2,'15D','Economy',4498,'Confirmed','2026-10-12 21:53:08'),(462,83,2,'7C','Economy',4987,'Confirmed','2026-10-12 21:53:08'),(463,60,2,'21E','Economy',4736,'Confirmed','2026-10-12 21:53:08'),(464,475,2,'22C','Economy',5396,'Confirmed','2026-10-12 21:53:08'),(465,159,2,'21D','Economy',4269,'Confirmed','2026-10-12 21:53:08'),(466,128,2,'2C','Economy',4395,'Confirmed','2026-10-12 21:53:08'),(467,109,2,'2D','Economy',5370,'Confirmed','2026-10-12 21:53:08'),(468,329,2,'4B','Economy',4776,'Confirmed','2026-10-12 21:53:08'),(469,550,2,'8E','Economy',4489,'Confirmed','2026-10-12 21:53:08'),(470,184,2,'27C','Economy',4899,'Confirmed','2026-10-12 21:53:08'),(471,519,2,'26D','Economy',4702,'Confirmed','2026-10-12 21:53:08'),(472,403,2,'17E','Economy',5031,'Confirmed','2026-10-12 21:53:08'),(473,397,2,'21B','Economy',4861,'Confirmed','2026-10-12 21:53:08'),(474,237,2,'7E','Economy',5231,'Confirmed','2026-10-12 21:53:08'),(475,495,2,'20A','Economy',4680,'Confirmed','2026-10-12 21:53:08'),(476,584,22,'7C','Economy',4350,'Confirmed','2026-10-12 21:53:08'),(477,571,22,'4D','Economy',4363,'Confirmed','2026-10-12 21:53:08'),(478,439,22,'13D','Economy',4923,'Confirmed','2026-10-12 21:53:08'),(479,302,22,'2C','Economy',5077,'Confirmed','2026-10-12 21:53:08'),(480,274,22,'4A','Economy',5192,'Confirmed','2026-10-12 21:53:08'),(481,299,22,'13F','Economy',4727,'Confirmed','2026-10-12 21:53:08'),(482,271,22,'7D','Economy',4748,'Confirmed','2026-10-12 21:53:08'),(483,365,22,'6C','Economy',4297,'Confirmed','2026-10-12 21:53:08'),(484,500,22,'8B','Economy',4778,'Confirmed','2026-10-12 21:53:08'),(485,491,12,'13B','Economy',4256,'Confirmed','2026-10-12 21:53:08'),(486,45,12,'8B','Economy',4255,'Confirmed','2026-10-12 21:53:08'),(487,109,12,'3F','Economy',4891,'Confirmed','2026-10-12 21:53:08'),(488,395,12,'1A','Economy',4293,'Confirmed','2026-10-12 21:53:08'),(489,38,12,'5A','Economy',5212,'Confirmed','2026-10-12 21:53:08'),(490,74,12,'6E','Economy',5148,'Confirmed','2026-10-12 21:53:08'),(491,66,12,'12C','Economy',4848,'Confirmed','2026-10-12 21:53:08'),(492,539,12,'1B','Economy',4314,'Confirmed','2026-10-12 21:53:08'),(493,543,12,'7F','Economy',4874,'Confirmed','2026-10-12 21:53:08'),(494,357,3,'14B','Economy',4257,'Confirmed','2026-10-12 21:53:08'),(495,531,3,'28E','Economy',5312,'Confirmed','2026-10-12 21:53:08'),(496,587,3,'33F','Economy',4572,'Confirmed','2026-10-12 21:53:08'),(497,87,3,'24C','Economy',4505,'Confirmed','2026-10-12 21:53:08'),(498,249,3,'31A','Economy',4531,'Confirmed','2026-10-12 21:53:08'),(499,576,3,'20C','Economy',4696,'Confirmed','2026-10-12 21:53:08'),(500,254,3,'24F','Economy',4636,'Confirmed','2026-10-12 21:53:08'),(501,297,3,'12F','Economy',4996,'Confirmed','2026-10-12 21:53:08'),(502,244,3,'16C','Economy',4254,'Confirmed','2026-10-12 21:53:08'),(503,359,3,'23B','Economy',4334,'Confirmed','2026-10-12 21:53:08'),(504,459,3,'23D','Economy',4918,'Confirmed','2026-10-12 21:53:08'),(505,401,3,'12E','Economy',5039,'Confirmed','2026-10-12 21:53:08'),(506,374,3,'6D','Economy',4658,'Confirmed','2026-10-12 21:53:08'),(507,132,3,'11E','Economy',5088,'Confirmed','2026-10-12 21:53:08'),(508,451,3,'1C','Economy',4867,'Confirmed','2026-10-12 21:53:08'),(509,417,3,'24E','Economy',4811,'Confirmed','2026-10-12 21:53:08'),(510,392,3,'21B','Economy',5366,'Confirmed','2026-10-12 21:53:08'),(511,234,3,'5B','Economy',4747,'Confirmed','2026-10-12 21:53:08'),(512,175,3,'28F','Economy',4814,'Confirmed','2026-10-12 21:53:08'),(513,505,3,'34A','Economy',5194,'Confirmed','2026-10-12 21:53:08'),(514,422,3,'36D','Economy',4854,'Confirmed','2026-10-12 21:53:08'),(515,193,3,'7C','Economy',5127,'Confirmed','2026-10-12 21:53:08'),(516,488,3,'27E','Economy',4629,'Confirmed','2026-10-12 21:53:08'),(517,330,3,'10E','Economy',4294,'Confirmed','2026-10-12 21:53:08'),(518,525,3,'18A','Economy',4573,'Confirmed','2026-10-12 21:53:08'),(519,29,3,'33B','Economy',4809,'Confirmed','2026-10-12 21:53:08'),(520,444,3,'4F','Economy',4511,'Confirmed','2026-10-12 21:53:08'),(521,133,17,'9C','Economy',4848,'Confirmed','2026-10-12 21:53:08'),(522,383,17,'8A','Economy',5198,'Confirmed','2026-10-12 21:53:08'),(523,590,17,'1E','Economy',4205,'Confirmed','2026-10-12 21:53:08'),(524,270,17,'13C','Economy',4502,'Confirmed','2026-10-12 21:53:08'),(525,99,17,'6A','Economy',4430,'Confirmed','2026-10-12 21:53:08'),(526,595,17,'5B','Economy',4358,'Confirmed','2026-10-12 21:53:08'),(527,139,17,'1B','Economy',4658,'Confirmed','2026-10-12 21:53:08'),(528,351,17,'13D','Economy',4562,'Confirmed','2026-10-12 21:53:08'),(529,538,17,'3F','Economy',4288,'Confirmed','2026-10-12 21:53:08'),(530,301,17,'11E','Economy',5339,'Confirmed','2026-10-12 21:53:08'),(531,97,17,'5F','Economy',4867,'Confirmed','2026-10-12 21:53:08'),(532,318,17,'10B','Economy',5314,'Confirmed','2026-10-12 21:53:08'),(533,259,17,'3B','Economy',5040,'Confirmed','2026-10-12 21:53:08'),(534,503,17,'1C','Economy',4750,'Confirmed','2026-10-12 21:53:08'),(535,532,17,'2A','Economy',5058,'Confirmed','2026-10-12 21:53:08'),(536,582,17,'10D','Economy',4989,'Confirmed','2026-10-12 21:53:08'),(537,514,19,'3E','Economy',4288,'Confirmed','2026-10-12 21:53:08'),(538,12,19,'17E','Economy',5076,'Confirmed','2026-10-12 21:53:08'),(539,195,19,'23C','Economy',4715,'Confirmed','2026-10-12 21:53:08'),(540,485,19,'12C','Economy',5270,'Confirmed','2026-10-12 21:53:08'),(541,400,19,'27A','Economy',4380,'Confirmed','2026-10-12 21:53:08'),(542,206,19,'29A','Economy',5113,'Confirmed','2026-10-12 21:53:08'),(543,570,19,'29F','Economy',5179,'Confirmed','2026-10-12 21:53:08'),(544,487,19,'14E','Economy',5259,'Confirmed','2026-10-12 21:53:08'),(545,297,19,'4A','Economy',4951,'Confirmed','2026-10-12 21:53:08'),(546,592,19,'27E','Economy',4959,'Confirmed','2026-10-12 21:53:08'),(547,158,19,'24B','Economy',4717,'Confirmed','2026-10-12 21:53:08'),(548,535,19,'29C','Economy',5368,'Confirmed','2026-10-12 21:53:08'),(549,117,19,'10D','Economy',4827,'Confirmed','2026-10-12 21:53:08'),(550,99,19,'30D','Economy',4863,'Confirmed','2026-10-12 21:53:08'),(551,493,19,'12B','Economy',5097,'Confirmed','2026-10-12 21:53:08'),(552,34,19,'28F','Economy',4381,'Confirmed','2026-10-12 21:53:08'),(553,45,19,'21B','Economy',4794,'Confirmed','2026-10-12 21:53:08'),(554,322,19,'15F','Economy',4289,'Confirmed','2026-10-12 21:53:08'),(555,446,19,'23B','Economy',4285,'Confirmed','2026-10-12 21:53:08'),(556,260,19,'26A','Economy',5035,'Confirmed','2026-10-12 21:53:08'),(557,520,19,'21C','Economy',4725,'Confirmed','2026-10-12 21:53:08'),(558,347,19,'25C','Economy',5385,'Confirmed','2026-10-12 21:53:08'),(559,440,19,'10C','Economy',5388,'Confirmed','2026-10-12 21:53:08'),(560,243,19,'7A','Economy',4874,'Confirmed','2026-10-12 21:53:08'),(561,355,19,'31B','Economy',5112,'Confirmed','2026-10-12 21:53:08'),(562,456,19,'23D','Economy',5217,'Confirmed','2026-10-12 21:53:08'),(563,8,19,'16D','Economy',4252,'Confirmed','2026-10-12 21:53:08'),(564,366,19,'30F','Economy',5146,'Confirmed','2026-10-12 21:53:08'),(565,363,19,'9E','Economy',5169,'Confirmed','2026-10-12 21:53:08'),(566,402,19,'30C','Economy',5014,'Confirmed','2026-10-12 21:53:08'),(567,273,19,'8B','Economy',4219,'Confirmed','2026-10-12 21:53:08'),(568,473,19,'26F','Economy',5022,'Confirmed','2026-10-12 21:53:08'),(569,436,19,'11B','Economy',4802,'Confirmed','2026-10-12 21:53:08'),(570,298,19,'8C','Economy',5141,'Confirmed','2026-10-12 21:53:08'),(571,194,19,'7D','Economy',4357,'Confirmed','2026-10-12 21:53:08'),(572,579,19,'20D','Economy',5217,'Confirmed','2026-10-12 21:53:08'),(573,282,19,'8D','Economy',5355,'Confirmed','2026-10-12 21:53:08'),(574,316,20,'18F','Economy',4610,'Confirmed','2026-10-12 21:53:08'),(575,472,20,'30A','Economy',4304,'Confirmed','2026-10-12 21:53:08'),(576,81,20,'3B','Economy',4338,'Confirmed','2026-10-12 21:53:08'),(577,556,20,'14A','Economy',4862,'Confirmed','2026-10-12 21:53:08'),(578,397,20,'13F','Economy',5099,'Confirmed','2026-10-12 21:53:08'),(579,141,20,'11D','Economy',5131,'Confirmed','2026-10-12 21:53:08'),(580,391,20,'17B','Economy',4617,'Confirmed','2026-10-12 21:53:08'),(581,75,20,'35B','Economy',5088,'Confirmed','2026-10-12 21:53:08'),(582,146,20,'19D','Economy',4480,'Confirmed','2026-10-12 21:53:08'),(583,304,20,'24A','Economy',5218,'Confirmed','2026-10-12 21:53:08'),(584,595,20,'11F','Economy',5349,'Confirmed','2026-10-12 21:53:08'),(585,181,20,'37C','Economy',4652,'Confirmed','2026-10-12 21:53:08'),(586,517,20,'9D','Economy',4803,'Confirmed','2026-10-12 21:53:08'),(587,15,20,'6D','Economy',4525,'Confirmed','2026-10-12 21:53:08'),(588,179,20,'37D','Economy',4623,'Confirmed','2026-10-12 21:53:08'),(589,247,20,'9F','Economy',4612,'Confirmed','2026-10-12 21:53:08'),(590,523,20,'23F','Economy',5049,'Confirmed','2026-10-12 21:53:08'),(591,234,20,'28E','Economy',5106,'Confirmed','2026-10-12 21:53:08'),(592,113,20,'16F','Economy',4316,'Confirmed','2026-10-12 21:53:08'),(593,295,20,'20E','Economy',4527,'Confirmed','2026-10-12 21:53:08'),(594,356,20,'29A','Economy',4676,'Confirmed','2026-10-12 21:53:08'),(595,227,20,'21F','Economy',5348,'Confirmed','2026-10-12 21:53:08'),(596,280,20,'31B','Economy',4728,'Confirmed','2026-10-12 21:53:08'),(597,248,20,'25F','Economy',4511,'Confirmed','2026-10-12 21:53:08'),(598,191,20,'7A','Economy',4672,'Confirmed','2026-10-12 21:53:08'),(599,496,20,'16D','Economy',4978,'Confirmed','2026-10-12 21:53:08'),(600,423,20,'15D','Economy',5317,'Confirmed','2026-10-12 21:53:08'),(601,176,8,'26D','Economy',4917,'Confirmed','2026-10-12 21:53:08'),(602,452,8,'25F','Economy',4945,'Confirmed','2026-10-12 21:53:08'),(603,333,8,'24A','Economy',4810,'Confirmed','2026-10-12 21:53:08'),(604,413,8,'4E','Economy',5131,'Confirmed','2026-10-12 21:53:08'),(605,132,8,'9D','Economy',4530,'Confirmed','2026-10-12 21:53:08'),(606,55,8,'6F','Economy',4269,'Confirmed','2026-10-12 21:53:08'),(607,349,8,'21A','Economy',5045,'Confirmed','2026-10-12 21:53:08'),(608,135,8,'12D','Economy',5383,'Confirmed','2026-10-12 21:53:08'),(609,200,8,'10E','Economy',4535,'Confirmed','2026-10-12 21:53:08'),(610,581,8,'25E','Economy',4384,'Confirmed','2026-10-12 21:53:08'),(611,103,8,'13E','Economy',5183,'Confirmed','2026-10-12 21:53:08'),(612,290,8,'2C','Economy',4418,'Confirmed','2026-10-12 21:53:08'),(613,534,8,'5B','Economy',5216,'Confirmed','2026-10-12 21:53:08'),(614,340,8,'1A','Economy',4864,'Confirmed','2026-10-12 21:53:08'),(615,21,8,'15E','Economy',5296,'Confirmed','2026-10-12 21:53:08'),(616,536,8,'9B','Economy',4604,'Confirmed','2026-10-12 21:53:08'),(617,117,8,'7C','Economy',4460,'Confirmed','2026-10-12 21:53:08'),(618,193,8,'29A','Economy',5295,'Confirmed','2026-10-12 21:53:08'),(619,524,8,'3A','Economy',4230,'Confirmed','2026-10-12 21:53:08'),(620,275,8,'8C','Economy',5368,'Confirmed','2026-10-12 21:53:08'),(621,296,8,'15B','Economy',4378,'Confirmed','2026-10-12 21:53:08'),(622,20,7,'26D','Economy',4509,'Confirmed','2026-10-12 21:53:08'),(623,226,7,'15C','Economy',4617,'Confirmed','2026-10-12 21:53:08'),(624,215,7,'5B','Economy',4878,'Confirmed','2026-10-12 21:53:08'),(625,358,7,'2E','Economy',4205,'Confirmed','2026-10-12 21:53:08'),(626,306,7,'10B','Economy',5218,'Confirmed','2026-10-12 21:53:08'),(627,86,7,'27C','Economy',4341,'Confirmed','2026-10-12 21:53:08'),(628,156,7,'8C','Economy',4607,'Confirmed','2026-10-12 21:53:08'),(629,328,7,'13F','Economy',4948,'Confirmed','2026-10-12 21:53:08'),(630,88,7,'15D','Economy',4915,'Confirmed','2026-10-12 21:53:08'),(631,72,7,'4D','Economy',5208,'Confirmed','2026-10-12 21:53:08'),(632,394,7,'20E','Economy',4476,'Confirmed','2026-10-12 21:53:08'),(633,336,7,'26B','Economy',4820,'Confirmed','2026-10-12 21:53:08'),(634,138,7,'8E','Economy',4537,'Confirmed','2026-10-12 21:53:08'),(635,140,7,'1C','Economy',5250,'Confirmed','2026-10-12 21:53:08'),(636,142,7,'14D','Economy',5288,'Confirmed','2026-10-12 21:53:08'),(637,353,7,'18D','Economy',4339,'Confirmed','2026-10-12 21:53:08'),(638,482,7,'18C','Economy',4716,'Confirmed','2026-10-12 21:53:08'),(639,483,7,'2C','Economy',4691,'Confirmed','2026-10-12 21:53:08'),(640,295,7,'4E','Economy',4684,'Confirmed','2026-10-12 21:53:08'),(641,425,7,'11C','Economy',4302,'Confirmed','2026-10-12 21:53:08'),(642,43,7,'7B','Economy',4901,'Confirmed','2026-10-12 21:53:08'),(643,516,7,'22E','Economy',4378,'Confirmed','2026-10-12 21:53:08'),(644,65,7,'8A','Economy',4895,'Confirmed','2026-10-12 21:53:08'),(645,209,28,'10B','Economy',4713,'Confirmed','2026-10-12 21:53:08'),(646,4,28,'30A','Economy',5331,'Confirmed','2026-10-12 21:53:08'),(647,208,28,'27E','Economy',4971,'Confirmed','2026-10-12 21:53:08'),(648,328,28,'2E','Economy',4718,'Confirmed','2026-10-12 21:53:08'),(649,421,28,'17A','Economy',4878,'Confirmed','2026-10-12 21:53:08'),(650,17,28,'36A','Economy',4941,'Confirmed','2026-10-12 21:53:08'),(651,111,28,'8F','Economy',4969,'Confirmed','2026-10-12 21:53:08'),(652,325,28,'17D','Economy',4322,'Confirmed','2026-10-12 21:53:08'),(653,269,28,'12D','Economy',4944,'Confirmed','2026-10-12 21:53:08'),(654,267,28,'15B','Economy',4443,'Confirmed','2026-10-12 21:53:08'),(655,586,28,'7C','Economy',5249,'Confirmed','2026-10-12 21:53:08'),(656,591,28,'16C','Economy',5139,'Confirmed','2026-10-12 21:53:08'),(657,317,28,'8A','Economy',4480,'Confirmed','2026-10-12 21:53:08'),(658,130,28,'10D','Economy',4755,'Confirmed','2026-10-12 21:53:08'),(659,218,28,'15F','Economy',5381,'Confirmed','2026-10-12 21:53:08'),(660,358,28,'27A','Economy',4555,'Confirmed','2026-10-12 21:53:08'),(661,150,28,'17E','Economy',4775,'Confirmed','2026-10-12 21:53:08'),(662,80,28,'14A','Economy',5314,'Confirmed','2026-10-12 21:53:08'),(663,226,28,'22B','Economy',5034,'Confirmed','2026-10-12 21:53:08'),(664,260,28,'14D','Economy',4979,'Confirmed','2026-10-12 21:53:08'),(665,323,28,'22D','Economy',4937,'Confirmed','2026-10-12 21:53:08'),(666,430,28,'26F','Economy',4531,'Confirmed','2026-10-12 21:53:08'),(667,21,28,'9A','Economy',4298,'Confirmed','2026-10-12 21:53:08'),(668,207,28,'7F','Economy',4486,'Confirmed','2026-10-12 21:53:08'),(669,535,28,'35B','Economy',4326,'Confirmed','2026-10-12 21:53:08'),(670,82,28,'23C','Economy',4549,'Confirmed','2026-10-12 21:53:08'),(671,195,28,'1C','Economy',4809,'Confirmed','2026-10-12 21:53:08'),(672,141,28,'1A','Economy',4937,'Confirmed','2026-10-12 21:53:08'),(673,293,28,'8C','Economy',4833,'Confirmed','2026-10-12 21:53:08'),(674,560,28,'5C','Economy',4857,'Confirmed','2026-10-12 21:53:08'),(675,355,28,'11C','Economy',4732,'Confirmed','2026-10-12 21:53:08'),(676,170,28,'20C','Economy',5167,'Confirmed','2026-10-12 21:53:08'),(677,121,28,'25A','Economy',5122,'Confirmed','2026-10-12 21:53:08'),(678,307,4,'23E','Economy',5027,'Confirmed','2026-10-12 21:53:08'),(679,75,4,'30E','Economy',4899,'Confirmed','2026-10-12 21:53:08'),(680,155,4,'25B','Economy',4889,'Confirmed','2026-10-12 21:53:08'),(681,248,4,'14A','Economy',4493,'Confirmed','2026-10-12 21:53:08'),(682,534,4,'16A','Economy',4791,'Confirmed','2026-10-12 21:53:08'),(683,463,4,'26E','Economy',4335,'Confirmed','2026-10-12 21:53:08'),(684,555,4,'16C','Economy',4206,'Confirmed','2026-10-12 21:53:08'),(685,418,4,'12B','Economy',5383,'Confirmed','2026-10-12 21:53:08'),(686,118,4,'11C','Economy',4760,'Confirmed','2026-10-12 21:53:08'),(687,586,4,'3F','Economy',4471,'Confirmed','2026-10-12 21:53:08'),(688,401,4,'24C','Economy',4688,'Confirmed','2026-10-12 21:53:08'),(689,361,4,'5A','Economy',4268,'Confirmed','2026-10-12 21:53:08'),(690,548,4,'29F','Economy',4980,'Confirmed','2026-10-12 21:53:08'),(691,524,4,'18D','Economy',4987,'Confirmed','2026-10-12 21:53:08'),(692,261,4,'5E','Economy',4337,'Confirmed','2026-10-12 21:53:08'),(693,140,4,'8A','Economy',5242,'Confirmed','2026-10-12 21:53:08'),(694,240,4,'28D','Economy',4658,'Confirmed','2026-10-12 21:53:08'),(695,453,4,'8D','Economy',5365,'Confirmed','2026-10-12 21:53:08'),(696,389,4,'28A','Economy',4936,'Confirmed','2026-10-12 21:53:08'),(697,14,4,'30D','Economy',4449,'Confirmed','2026-10-12 21:53:08'),(698,25,4,'6A','Economy',4207,'Confirmed','2026-10-12 21:53:08'),(699,293,15,'2B','Economy',5378,'Confirmed','2026-10-12 21:53:08'),(700,61,15,'10D','Economy',5131,'Confirmed','2026-10-12 21:53:08'),(701,242,15,'8C','Economy',4429,'Confirmed','2026-10-12 21:53:08'),(702,340,15,'31B','Economy',4597,'Confirmed','2026-10-12 21:53:08'),(703,336,15,'22D','Economy',4233,'Confirmed','2026-10-12 21:53:08'),(704,354,15,'12C','Economy',4602,'Confirmed','2026-10-12 21:53:08'),(705,501,15,'19A','Economy',4806,'Confirmed','2026-10-12 21:53:08'),(706,36,15,'16F','Economy',4232,'Confirmed','2026-10-12 21:53:08'),(707,556,15,'3E','Economy',4226,'Confirmed','2026-10-12 21:53:08'),(708,335,15,'27F','Economy',5301,'Confirmed','2026-10-12 21:53:08'),(709,261,15,'12E','Economy',4535,'Confirmed','2026-10-12 21:53:08'),(710,122,15,'4E','Economy',4926,'Confirmed','2026-10-12 21:53:08'),(711,283,15,'25F','Economy',4558,'Confirmed','2026-10-12 21:53:08'),(712,155,15,'5E','Economy',4260,'Confirmed','2026-10-12 21:53:08'),(713,189,15,'18A','Economy',4409,'Confirmed','2026-10-12 21:53:08'),(714,388,15,'17D','Economy',4945,'Confirmed','2026-10-12 21:53:08'),(715,203,15,'22F','Economy',4369,'Confirmed','2026-10-12 21:53:08'),(716,447,15,'26A','Economy',5175,'Confirmed','2026-10-12 21:53:08'),(717,327,15,'18C','Economy',4422,'Confirmed','2026-10-12 21:53:08'),(718,337,15,'31A','Economy',4996,'Confirmed','2026-10-12 21:53:08'),(719,480,15,'3C','Economy',4243,'Confirmed','2026-10-12 21:53:08'),(720,149,15,'30A','Economy',4769,'Confirmed','2026-10-12 21:53:08'),(721,583,15,'23E','Economy',5094,'Confirmed','2026-10-12 21:53:08'),(722,453,15,'15A','Economy',4529,'Confirmed','2026-10-12 21:53:08'),(723,457,15,'11E','Economy',4474,'Confirmed','2026-10-12 21:53:08'),(724,419,15,'4A','Economy',5398,'Confirmed','2026-10-12 21:53:08'),(725,514,15,'21C','Economy',4376,'Confirmed','2026-10-12 21:53:08');
/*!40000 ALTER TABLE `bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `check_ins`
--

DROP TABLE IF EXISTS `check_ins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `check_ins` (
  `checkin_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `checkin_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `boarding_status` varchar(16) NOT NULL DEFAULT 'Not Boarded',
  PRIMARY KEY (`checkin_id`),
  UNIQUE KEY `booking_id` (`booking_id`),
  CONSTRAINT `check_ins_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `check_ins_chk_1` CHECK ((`boarding_status` in (_utf8mb4'Not Boarded',_utf8mb4'Boarding',_utf8mb4'Boarded',_utf8mb4'No Show')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `check_ins`
--

LOCK TABLES `check_ins` WRITE;
/*!40000 ALTER TABLE `check_ins` DISABLE KEYS */;
/*!40000 ALTER TABLE `check_ins` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departures`
--

DROP TABLE IF EXISTS `departures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departures` (
  `departure_id` int NOT NULL AUTO_INCREMENT,
  `flight_id` int NOT NULL,
  `scheduled_departure` datetime NOT NULL,
  `scheduled_arrival` datetime NOT NULL,
  `departure_status` varchar(16) NOT NULL DEFAULT 'Scheduled',
  `aircraft_id` int DEFAULT NULL,
  `gate_id` int DEFAULT NULL,
  PRIMARY KEY (`departure_id`),
  UNIQUE KEY `flight_id` (`flight_id`,`scheduled_departure`),
  KEY `aircraft_id` (`aircraft_id`),
  KEY `gate_id` (`gate_id`),
  CONSTRAINT `departures_ibfk_1` FOREIGN KEY (`flight_id`) REFERENCES `flights` (`flight_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `departures_ibfk_2` FOREIGN KEY (`aircraft_id`) REFERENCES `aircraft` (`aircraft_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `departures_ibfk_3` FOREIGN KEY (`gate_id`) REFERENCES `gates` (`gate_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `departures_chk_1` CHECK ((`departure_status` in (_utf8mb4'Scheduled',_utf8mb4'Boarding',_utf8mb4'Departed',_utf8mb4'Arrived',_utf8mb4'Delayed',_utf8mb4'Cancelled'))),
  CONSTRAINT `departures_chk_2` CHECK ((`scheduled_arrival` > `scheduled_departure`))
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departures`
--

LOCK TABLES `departures` WRITE;
/*!40000 ALTER TABLE `departures` DISABLE KEYS */;
INSERT INTO `departures` VALUES (1,1,'2026-11-01 08:00:00','2026-11-01 09:20:00','Scheduled',1,2),(2,2,'2026-11-01 10:10:00','2026-11-01 11:30:00','Scheduled',1,6),(3,5,'2026-11-01 18:05:00','2026-11-01 19:35:00','Scheduled',2,3),(4,2,'2026-11-02 10:10:00','2026-11-02 11:30:00','Scheduled',1,4),(5,3,'2026-11-02 07:15:00','2026-11-02 09:25:00','Scheduled',3,11),(6,4,'2026-11-02 06:30:00','2026-11-02 09:10:00','Scheduled',4,6),(7,1,'2026-11-03 08:00:00','2026-11-03 09:20:00','Scheduled',1,1),(8,2,'2026-11-03 10:10:00','2026-11-03 11:30:00','Scheduled',1,5),(9,3,'2026-11-03 07:15:00','2026-11-03 09:25:00','Scheduled',3,12),(10,5,'2026-11-03 18:05:00','2026-11-03 19:35:00','Scheduled',2,2),(11,6,'2026-11-03 07:30:00','2026-11-03 08:45:00','Scheduled',5,15),(12,7,'2026-11-03 19:20:00','2026-11-03 20:35:00','Scheduled',5,1),(13,1,'2026-11-04 08:00:00','2026-11-04 09:20:00','Scheduled',1,2),(14,2,'2026-11-04 10:10:00','2026-11-04 11:30:00','Scheduled',1,6),(15,3,'2026-11-04 07:15:00','2026-11-04 09:25:00','Scheduled',3,10),(16,5,'2026-11-04 18:05:00','2026-11-04 19:35:00','Scheduled',2,3),(17,6,'2026-11-04 07:30:00','2026-11-04 08:45:00','Scheduled',5,13),(18,1,'2026-11-05 08:00:00','2026-11-05 09:20:00','Scheduled',1,3),(19,3,'2026-11-05 07:15:00','2026-11-05 09:25:00','Scheduled',3,11),(20,5,'2026-11-05 18:05:00','2026-11-05 19:35:00','Scheduled',2,1),(21,6,'2026-11-05 07:30:00','2026-11-05 08:45:00','Scheduled',5,14),(22,7,'2026-11-05 19:20:00','2026-11-05 20:35:00','Scheduled',5,3),(23,4,'2026-11-06 06:30:00','2026-11-06 09:10:00','Scheduled',4,4),(24,5,'2026-11-06 18:05:00','2026-11-06 19:35:00','Scheduled',2,2),(25,6,'2026-11-06 07:30:00','2026-11-06 08:45:00','Scheduled',5,15),(26,3,'2026-11-07 07:15:00','2026-11-07 09:25:00','Scheduled',3,10),(27,4,'2026-11-07 06:30:00','2026-11-07 09:10:00','Scheduled',4,5),(28,5,'2026-11-07 18:05:00','2026-11-07 19:35:00','Scheduled',2,3),(29,7,'2026-11-07 19:20:00','2026-11-07 20:35:00','Scheduled',5,2);
/*!40000 ALTER TABLE `departures` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `flights`
--

DROP TABLE IF EXISTS `flights`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `flights` (
  `flight_id` int NOT NULL AUTO_INCREMENT,
  `flight_number` varchar(16) NOT NULL,
  `airline_id` int NOT NULL,
  `departure_airport_id` int NOT NULL,
  `arrival_airport_id` int NOT NULL,
  `sched_departure` varchar(16) NOT NULL,
  `sched_arrival` varchar(16) NOT NULL,
  `flight_status` varchar(16) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`flight_id`),
  UNIQUE KEY `flight_number` (`flight_number`),
  KEY `airline_id` (`airline_id`),
  KEY `departure_airport_id` (`departure_airport_id`),
  KEY `arrival_airport_id` (`arrival_airport_id`),
  CONSTRAINT `flights_ibfk_1` FOREIGN KEY (`airline_id`) REFERENCES `airlines` (`airline_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `flights_ibfk_2` FOREIGN KEY (`departure_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `flights_ibfk_3` FOREIGN KEY (`arrival_airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `flights_chk_1` CHECK ((`flight_status` in (_utf8mb4'Active',_utf8mb4'Suspended')))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `flights`
--

LOCK TABLES `flights` WRITE;
/*!40000 ALTER TABLE `flights` DISABLE KEYS */;
INSERT INTO `flights` VALUES (1,'6E-501',1,1,2,'08:00:00','09:20:00','Active'),(2,'6E-502',1,2,1,'10:10:00','11:30:00','Active'),(3,'AI-654',2,4,3,'07:15:00','09:25:00','Active'),(4,'SG-893',3,2,4,'06:30:00','09:10:00','Active'),(5,'6E-511',1,1,3,'18:05:00','19:35:00','Active'),(6,'6E-561',1,5,1,'07:30:00','08:45:00','Active'),(7,'6E-562',1,1,5,'19:20:00','20:35:00','Active');
/*!40000 ALTER TABLE `flights` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gates`
--

DROP TABLE IF EXISTS `gates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gates` (
  `gate_id` int NOT NULL AUTO_INCREMENT,
  `terminal_id` int NOT NULL,
  `gate_number` varchar(8) NOT NULL,
  `gate_status` varchar(16) NOT NULL DEFAULT 'Open',
  PRIMARY KEY (`gate_id`),
  UNIQUE KEY `terminal_id` (`terminal_id`,`gate_number`),
  CONSTRAINT `gates_ibfk_1` FOREIGN KEY (`terminal_id`) REFERENCES `terminals` (`terminal_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gates_chk_1` CHECK ((`gate_status` in (_utf8mb4'Open',_utf8mb4'Closed',_utf8mb4'Maintenance')))
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gates`
--

LOCK TABLES `gates` WRITE;
/*!40000 ALTER TABLE `gates` DISABLE KEYS */;
INSERT INTO `gates` VALUES (1,1,'G1','Open'),(2,1,'G2','Open'),(3,1,'G3','Open'),(4,2,'G1','Open'),(5,2,'G2','Open'),(6,2,'G3','Open'),(7,3,'G1','Open'),(8,3,'G2','Open'),(9,3,'G3','Open'),(10,4,'G1','Open'),(11,4,'G2','Open'),(12,4,'G3','Open'),(13,5,'G1','Open'),(14,5,'G2','Open'),(15,5,'G3','Open');
/*!40000 ALTER TABLE `gates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passengers`
--

DROP TABLE IF EXISTS `passengers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `passengers` (
  `passenger_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(60) NOT NULL,
  `last_name` varchar(60) NOT NULL,
  `passport_number` varchar(24) DEFAULT NULL,
  `nationality` varchar(60) NOT NULL DEFAULT 'India',
  `phone` varchar(24) NOT NULL,
  `email` varchar(120) NOT NULL,
  PRIMARY KEY (`passenger_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `passport_number` (`passport_number`)
) ENGINE=InnoDB AUTO_INCREMENT=603 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passengers`
--

LOCK TABLES `passengers` WRITE;
/*!40000 ALTER TABLE `passengers` DISABLE KEYS */;
INSERT INTO `passengers` VALUES (1,'Atharv','Mendonsa','D200001','India','8711017088','atharv.mendonsa@example.com'),(2,'Karan','Sheikh','D200002','India','7247098795','karan.sheikh@example.com'),(3,'Shivansh','Chavare','D200003','India','8298860200','shivansh.chavare@example.com'),(4,'Donita','Shah','D200004','India','8489700427','donita.shah@example.com'),(5,'Harshil','Rajesh','D200005','India','9809017327','harshil.rajesh@example.com'),(6,'Navami','Bansal','D200006','India','8984494269','navami.bansal@example.com'),(7,'Rishaan','Saniel','D200007','India','7289284712','rishaan.saniel@example.com'),(8,'Teerth','Patil','D200008','India','7268555637','teerth.patil@example.com'),(9,'Bhoomika','Acharya','D200009','India','8470446574','bhoomika.acharya@example.com'),(10,'Charan','Raval','D200010','India','7258797056','charan.raval@example.com'),(11,'Chaithra','Shayana','D200011','India','7123656121','chaithra.shayana@example.com'),(12,'Daksh','Thampy','D200012','India','7751876353','daksh.thampy@example.com'),(13,'Kahaan','Prabhu','D200013','India','9869045392','kahaan.prabhu@example.com'),(14,'Kabir','Bansal','D200014','India','8907120748','kabir.bansal@example.com'),(15,'Nirav','Kini','D200015','India','7650407066','nirav.kini@example.com'),(16,'Warinder','Mendonsa','D200016','India','7567241214','warinder.mendonsa@example.com'),(17,'Karan','Prajapati','D200017','India','9874999664','karan.prajapati@example.com'),(18,'Harini','Bharanya','D200018','India','7338331047','harini.bharanya@example.com'),(19,'Veena','Raval','D200019','India','8615960489','veena.raval@example.com'),(20,'Ved','Salian','D200020','India','9750744680','ved.salian@example.com'),(21,'Archana','Taj','D200021','India','9970152293','archana.taj@example.com'),(22,'Niva','Jain','D200022','India','9711635101','niva.jain@example.com'),(23,'Dharmesh','Taj','D200023','India','8362763831','dharmesh.taj@example.com'),(24,'Divya','Almeida','D200024','India','8689583308','divya.almeida@example.com'),(25,'Sahana','Ramesh','D200025','India','9593374130','sahana.ramesh@example.com'),(26,'Zayan','Banerjee','D200026','India','8517666730','zayan.banerjee@example.com'),(27,'Bhoomika','Dalvi','D200027','India','9293707022','bhoomika.dalvi@example.com'),(28,'Kahaan','Sullad','D200028','India','9499101620','kahaan.sullad@example.com'),(29,'Lohit','Kaur','D200029','India','8212916401','lohit.kaur@example.com'),(30,'Malathy','Dhamdhame','D200030','India','7917404096','malathy.dhamdhame@example.com'),(31,'Rushali','Shetty','D200031','India','9599117774','rushali.shetty@example.com'),(32,'Shubha','Prabhakaran','D200032','India','9456622201','shubha.prabhakaran@example.com'),(33,'Ranjani','Bhoja','D200033','India','8038928821','ranjani.bhoja@example.com'),(34,'Bakhshi','Bhoja','D200034','India','9874188188','bakhshi.bhoja@example.com'),(35,'Praneel','Holla','D200035','India','8925773576','praneel.holla@example.com'),(36,'Vaishnavi','Namnaik','D200036','India','9981366319','vaishnavi.namnaik@example.com'),(37,'Rashmitha','Pai','D200037','India','9778784774','rashmitha.pai@example.com'),(38,'Monali','Tipparti','D200038','India','9502948892','monali.tipparti@example.com'),(39,'Sowjanya','Saniel','D200039','India','9735661314','sowjanya.saniel@example.com'),(40,'Hitesh','Tipparti','D200040','India','7540188389','hitesh.tipparti@example.com'),(41,'Nagraj','Kouser','D200041','India','8537875159','nagraj.kouser@example.com'),(42,'Abhinav','Pai','D200042','India','7381790555','abhinav.pai@example.com'),(43,'Shaurya','Naik','D200043','India','8815015922','shaurya.naik@example.com'),(44,'Rishi','Shroff','D200044','India','7443125148','rishi.shroff@example.com'),(45,'Yash','Thampy','D200045','India','8791261401','yash.thampy@example.com'),(46,'Aparna','Kumar','D200046','India','8229384578','aparna.kumar@example.com'),(47,'Lakshit','Dsouza','D200047','India','8002433252','lakshit.dsouza@example.com'),(48,'Sonali','Shetty','D200048','India','7101426135','sonali.shetty@example.com'),(49,'Laksh','Sheikh','D200049','India','9972407203','laksh.sheikh@example.com'),(50,'Alolika','Shet','D200050','India','9355705318','alolika.shet@example.com'),(51,'Javeria','Gupta','D200051','India','7849241493','javeria.gupta@example.com'),(52,'Sandhya','Shroff','D200052','India','9479442756','sandhya.shroff@example.com'),(53,'Anika','Prabhu','D200053','India','8187869855','anika.prabhu@example.com'),(54,'Girindra','Patil','D200054','India','8475836393','girindra.patil@example.com'),(55,'Aarush','Kaur','D200055','India','9237602562','aarush.kaur@example.com'),(56,'Shrinidhi','Chiplunkar','D200056','India','7357348162','shrinidhi.chiplunkar@example.com'),(57,'Chandran','Belligatti','D200057','India','7260667441','chandran.belligatti@example.com'),(58,'Namitha','Chatterjee','D200058','India','8799759628','namitha.chatterjee@example.com'),(59,'Savitha','Bhoja','D200059','India','8856458432','savitha.bhoja@example.com'),(60,'Reema','Mugeraya','D200060','India','7254222399','reema.mugeraya@example.com'),(61,'Yuvraj','Patil','D200061','India','7358085937','yuvraj.patil@example.com'),(62,'Saloni','Anand','D200062','India','8497648497','saloni.anand@example.com'),(63,'Shrishti','Ramesh','D200063','India','7387270041','shrishti.ramesh@example.com'),(64,'Suraksha','Hiremath','D200064','India','8782790933','suraksha.hiremath@example.com'),(65,'Parimala','Rajesh','D200065','India','9800831119','parimala.rajesh@example.com'),(66,'Ravi','Raval','D200066','India','8048836089','ravi.raval@example.com'),(67,'Pranay','Rajesh','D200067','India','8455194096','pranay.rajesh@example.com'),(68,'Kavya','Thampy','D200068','India','9736614543','kavya.thampy@example.com'),(69,'Lohit','Prabhu','D200069','India','8353979817','lohit.prabhu@example.com'),(70,'Ayush','Prabhakaran','D200070','India','8656652734','ayush.prabhakaran@example.com'),(71,'Deeksha','Kumari','D200071','India','7947650795','deeksha.kumari@example.com'),(72,'Suhasini','Shetty','D200072','India','7701388484','suhasini.shetty@example.com'),(73,'Charan','Prajapati','D200073','India','8529141109','charan.prajapati@example.com'),(74,'Gunbir','Das','D200074','India','7023139944','gunbir.das@example.com'),(75,'Rushil','Kamath','D200075','India','8934609624','rushil.kamath@example.com'),(76,'Namitha','Shetty','D200076','India','9863793301','namitha.shetty@example.com'),(77,'Anusree','Tipparti','D200077','India','7696521172','anusree.tipparti@example.com'),(78,'Balvan','Saha','D200078','India','7175727557','balvan.saha@example.com'),(79,'Upkaar','Tipparti','D200079','India','9925381543','upkaar.tipparti@example.com'),(80,'Tanmay','Belligatti','D200080','India','7652147048','tanmay.belligatti@example.com'),(81,'Anmol','Kumari','D200081','India','9543862873','anmol.kumari@example.com'),(82,'Yash','Sullad','D200082','India','7636989071','yash.sullad@example.com'),(83,'Akshatha','Shenoy','D200083','India','9616125897','akshatha.shenoy@example.com'),(84,'Girindra','Bangera','D200084','India','8234244723','girindra.bangera@example.com'),(85,'Hema','Suvarna','D200085','India','7180633647','hema.suvarna@example.com'),(86,'Richa','Bharanya','D200086','India','9613714102','richa.bharanya@example.com'),(87,'Mayra','Nagane','D200087','India','7993206452','mayra.nagane@example.com'),(88,'Aadi','Taj','D200088','India','7883170891','aadi.taj@example.com'),(89,'Upkaar','Prabhakaran','D200089','India','8891175102','upkaar.prabhakaran@example.com'),(90,'Chaitanya','Moolya','D200090','India','7857863353','chaitanya.moolya@example.com'),(91,'Ananth','Anand','D200091','India','8382467605','ananth.anand@example.com'),(92,'Sonali','Dhamdhame','D200092','India','7415727004','sonali.dhamdhame@example.com'),(93,'Keya','Adiga','D200093','India','9250789775','keya.adiga@example.com'),(94,'Ananth','Gupta','D200094','India','8529025902','ananth.gupta@example.com'),(95,'Ekansh','Holla','D200095','India','8590611127','ekansh.holla@example.com'),(96,'Abhinav','Andrade','D200096','India','8903279610','abhinav.andrade@example.com'),(97,'Monisha','Shroff','D200097','India','9888793140','monisha.shroff@example.com'),(98,'Ranveer','Shet','D200098','India','9023149965','ranveer.shet@example.com'),(99,'Tanish','Thampy','D200099','India','9715555596','tanish.thampy@example.com'),(100,'Manthan','Kini','D200100','India','7442666107','manthan.kini@example.com'),(101,'Dhanush','Manjunath','D200101','India','8745294028','dhanush.manjunath@example.com'),(102,'Sapthashree','Padmanabha','D200102','India','8860360091','sapthashree.padmanabha@example.com'),(103,'Vidya','Uchil','D200103','India','9007990239','vidya.uchil@example.com'),(104,'Chandresh','Moolya','D200104','India','8593520457','chandresh.moolya@example.com'),(105,'Advaith','Kumar','D200105','India','7168690310','advaith.kumar@example.com'),(106,'Malathy','Belligatti','D200106','India','7683127134','malathy.belligatti@example.com'),(107,'Fitan','Chavare','D200107','India','9179326061','fitan.chavare@example.com'),(108,'Abhijith','Vernekar','D200108','India','7849549461','abhijith.vernekar@example.com'),(109,'Hemang','Shetty','D200109','India','7239027884','hemang.shetty@example.com'),(110,'Grishma','Bangera','D200110','India','8685032791','grishma.bangera@example.com'),(111,'Aditya','Manjunath','D200111','India','9124574314','aditya.manjunath@example.com'),(112,'Ekansh','Babu','D200112','India','9824334675','ekansh.babu@example.com'),(113,'Falan','Chavare','D200113','India','8976184338','falan.chavare@example.com'),(114,'Karan','Shet','D200114','India','9283558848','karan.shet@example.com'),(115,'Ajith','Chatterjee','D200115','India','8563055589','ajith.chatterjee@example.com'),(116,'Donita','Thampy','D200116','India','7838823945','donita.thampy@example.com'),(117,'Teerth','Chiplunkar','D200117','India','8081406556','teerth.chiplunkar@example.com'),(118,'Likhitha','Kamath','D200118','India','7090913627','likhitha.kamath@example.com'),(119,'Sarthak','Bhat','D200119','India','7831999399','sarthak.bhat@example.com'),(120,'Dileep','Patil','D200120','India','7518317760','dileep.patil@example.com'),(121,'Sayali','Dhamdhame','D200121','India','8612748515','sayali.dhamdhame@example.com'),(122,'Chaitanya','Naik','D200122','India','7341900318','chaitanya.naik@example.com'),(123,'Trupti','Jain','D200123','India','7072558521','trupti.jain@example.com'),(124,'Hetal','Gupta','D200124','India','8869513264','hetal.gupta@example.com'),(125,'Ishita','Saniel','D200125','India','7951147801','ishita.saniel@example.com'),(126,'Kabir','Ramesh','D200126','India','7867437754','kabir.ramesh@example.com'),(127,'Divyesh','Taj','D200127','India','8013770801','divyesh.taj@example.com'),(128,'Lakshit','Chavare','D200128','India','9227697181','lakshit.chavare@example.com'),(129,'Samesh','Bangera','D200129','India','8539579175','samesh.bangera@example.com'),(130,'Nagesh','Shenoy','D200130','India','8153401731','nagesh.shenoy@example.com'),(131,'Gagan','Bhardwaj','D200131','India','8643909286','gagan.bhardwaj@example.com'),(132,'Shambhavi','Pai','D200132','India','9623798214','shambhavi.pai@example.com'),(133,'Kavyashri','Nair','D200133','India','7916671220','kavyashri.nair@example.com'),(134,'Sapthashree','Shroff','D200134','India','7483258539','sapthashree.shroff@example.com'),(135,'Neel','Gugale','D200135','India','7005146583','neel.gugale@example.com'),(136,'Nehrika','Nagane','D200136','India','8872302701','nehrika.nagane@example.com'),(137,'Hitesh','Shroff','D200137','India','7705609951','hitesh.shroff@example.com'),(138,'Umang','Dalvi','D200138','India','9512740948','umang.dalvi@example.com'),(139,'Anmol','Nagane','D200139','India','7347461692','anmol.nagane@example.com'),(140,'Kashvi','Saniel','D200140','India','9294518620','kashvi.saniel@example.com'),(141,'Madhumita','Mardhekar','D200141','India','8926045644','madhumita.mardhekar@example.com'),(142,'Niva','Kulkarni','D200142','India','9930440884','niva.kulkarni@example.com'),(143,'Raksha','Mendonsa','D200143','India','7188689197','raksha.mendonsa@example.com'),(144,'Idhant','Adiga','D200144','India','7056091665','idhant.adiga@example.com'),(145,'Anand','Rai','D200145','India','9242841401','anand.rai@example.com'),(146,'Yatan','Manjunath','D200146','India','8854339739','yatan.manjunath@example.com'),(147,'Sarita','Ramesh','D200147','India','9953356805','sarita.ramesh@example.com'),(148,'Arjun','Sullad','D200148','India','8901290652','arjun.sullad@example.com'),(149,'Monali','Rajesh','D200149','India','9535450063','monali.rajesh@example.com'),(150,'Guneet','Fernandes','D200150','India','9584464677','guneet.fernandes@example.com'),(151,'Indrajit','Dawangave','D200151','India','8798514798','indrajit.dawangave@example.com'),(152,'Renuka','Sullad','D200152','India','8665869394','renuka.sullad@example.com'),(153,'Siddharth','Namnaik','D200153','India','9680129866','siddharth.namnaik@example.com'),(154,'Archana','Naik','D200154','India','8747905279','archana.naik@example.com'),(155,'Avi','Suvarna','D200155','India','9736202558','avi.suvarna@example.com'),(156,'Fitan','Rai','D200156','India','7017338103','fitan.rai@example.com'),(157,'Amol','Keshri','D200157','India','9019876033','amol.keshri@example.com'),(158,'Utkarsh','Mardhekar','D200158','India','9791005301','utkarsh.mardhekar@example.com'),(159,'Manvitha','Vernekar','D200159','India','8327208630','manvitha.vernekar@example.com'),(160,'Nikhitha','Bal','D200160','India','9971282852','nikhitha.bal@example.com'),(161,'Shylaja','Naik','D200161','India','7736642529','shylaja.naik@example.com'),(162,'Upkaar','Pai','D200162','India','7292367097','upkaar.pai@example.com'),(163,'Pavati','Vernekar','D200163','India','8843170478','pavati.vernekar@example.com'),(164,'Dwarakanath','Prabhu','D200164','India','7809245057','dwarakanath.prabhu@example.com'),(165,'Umang','Kavser','D200165','India','8049193266','umang.kavser@example.com'),(166,'Kimaya','Belligatti','D200166','India','9679202817','kimaya.belligatti@example.com'),(167,'Navya','Chatterjee','D200167','India','8116543523','navya.chatterjee@example.com'),(168,'Rachana','Pai','D200168','India','8923499456','rachana.pai@example.com'),(169,'Aishwarya','Banerjee','D200169','India','7781490090','aishwarya.banerjee@example.com'),(170,'Lohit','Gamskar','D200170','India','8017822083','lohit.gamskar@example.com'),(171,'Vaishnavi','Bal','D200171','India','9660080306','vaishnavi.bal@example.com'),(172,'Gopal','Gupta','D200172','India','8133329716','gopal.gupta@example.com'),(173,'Kripa','Ramesh','D200173','India','9986377023','kripa.ramesh@example.com'),(174,'Ved','Jain','D200174','India','7932806472','ved.jain@example.com'),(175,'Samaksh','Andrade','D200175','India','8648748882','samaksh.andrade@example.com'),(176,'Sagar','Prajapati','D200176','India','9931283655','sagar.prajapati@example.com'),(177,'Jeet','Das','D200177','India','7793213759','jeet.das@example.com'),(178,'Hitesh','Bangera','D200178','India','8158557759','hitesh.bangera@example.com'),(179,'Tejaswi','Anand','D200179','India','8831137812','tejaswi.anand@example.com'),(180,'Shreya','Raval','D200180','India','9258137497','shreya.raval@example.com'),(181,'Bhoomika','Shet','D200181','India','9276559777','bhoomika.shet@example.com'),(182,'Aarush','Fernandes','D200182','India','9493993215','aarush.fernandes@example.com'),(183,'Dhipu','Gupta','D200183','India','7476309300','dhipu.gupta@example.com'),(184,'Renuka','Holla','D200184','India','8324369345','renuka.holla@example.com'),(185,'Kairav','Uchil','D200185','India','9226607971','kairav.uchil@example.com'),(186,'Warinder','Padmanabha','D200186','India','7904829393','warinder.padmanabha@example.com'),(187,'Sangeetha','Thampy','D200187','India','9135788742','sangeetha.thampy@example.com'),(188,'Ishita','Kumar','D200188','India','8973449546','ishita.kumar@example.com'),(189,'Jayaraj','Kumar','D200189','India','9208299280','jayaraj.kumar@example.com'),(190,'Sonika','Kouser','D200190','India','9684901511','sonika.kouser@example.com'),(191,'Shraddha','Saha','D200191','India','7696400928','shraddha.saha@example.com'),(192,'Yagnesh','Acharya','D200192','India','9939055916','yagnesh.acharya@example.com'),(193,'Sanchitha','Mathew','D200193','India','9679162008','sanchitha.mathew@example.com'),(194,'Chaitra','Mardhekar','D200194','India','9866353753','chaitra.mardhekar@example.com'),(195,'Kahaan','Raval','D200195','India','7005448673','kahaan.raval@example.com'),(196,'Sudha','Ramesh','D200196','India','8400303274','sudha.ramesh@example.com'),(197,'Sarthak','Vernekar','D200197','India','7184530738','sarthak.vernekar@example.com'),(198,'Sanjana','Kaur','D200198','India','8698136770','sanjana.kaur@example.com'),(199,'Guneet','Anchan','D200199','India','9611896501','guneet.anchan@example.com'),(200,'Deepika','Saniel','D200200','India','9426171747','deepika.saniel@example.com'),(201,'Saanvi','Fernandes','D200201','India','9954238358','saanvi.fernandes@example.com'),(202,'Mayra','Mugeraya','D200202','India','9879838646','mayra.mugeraya@example.com'),(203,'Jayaraj','Mardhekar','D200203','India','7123296716','jayaraj.mardhekar@example.com'),(204,'Aadi','Kumar','D200204','India','8978188542','aadi.kumar@example.com'),(205,'Shrinidhi','Anchan','D200205','India','8665182585','shrinidhi.anchan@example.com'),(206,'Pranit','Saha','D200206','India','9471512134','pranit.saha@example.com'),(207,'Adhira','Kavser','D200207','India','9686634545','adhira.kavser@example.com'),(208,'Praneetha','Shah','D200208','India','7733361394','praneetha.shah@example.com'),(209,'Dhipu','Chatterjee','D200209','India','7362082733','dhipu.chatterjee@example.com'),(210,'Sonali','Bhardwaj','D200210','India','7432097452','sonali.bhardwaj@example.com'),(211,'Anitha','Almeida','D200211','India','8353728537','anitha.almeida@example.com'),(212,'Dhipu','Manjunath','D200212','India','8009059706','dhipu.manjunath@example.com'),(213,'Omkaar','Shetty','D200213','India','7098890276','omkaar.shetty@example.com'),(214,'Deeksha','Holla','D200214','India','8822213984','deeksha.holla@example.com'),(215,'Saisha','Fernandes','D200215','India','9249737545','saisha.fernandes@example.com'),(216,'Nimit','Kulkarni','D200216','India','9687627804','nimit.kulkarni@example.com'),(217,'Jenisha','Naik','D200217','India','9560692141','jenisha.naik@example.com'),(218,'Shubha','Rajesh','D200218','India','7371473812','shubha.rajesh@example.com'),(219,'Mahika','Kumari','D200219','India','8286214574','mahika.kumari@example.com'),(220,'Krish','Prabhakaran','D200220','India','8150642495','krish.prabhakaran@example.com'),(221,'Kashvi','Bhardwaj','D200221','India','8977772267','kashvi.bhardwaj@example.com'),(222,'Rushil','Nair','D200222','India','8932604348','rushil.nair@example.com'),(223,'Ranjani','Shayana','D200223','India','8653301263','ranjani.shayana@example.com'),(224,'Arnav','Bhoja','D200224','India','7773541581','arnav.bhoja@example.com'),(225,'Falan','Patil','D200225','India','7078537663','falan.patil@example.com'),(226,'Dharmesh','Manjunath','D200226','India','7714510875','dharmesh.manjunath@example.com'),(227,'Praneetha','Ramesh','D200227','India','8656639607','praneetha.ramesh@example.com'),(228,'Supritha','Rai','D200228','India','9931414631','supritha.rai@example.com'),(229,'Viraj','Thampy','D200229','India','9337620555','viraj.thampy@example.com'),(230,'Udarsh','Pujari','D200230','India','8519628745','udarsh.pujari@example.com'),(231,'Saanvi','Holla','D200231','India','9323264642','saanvi.holla@example.com'),(232,'Sudha','Manjunath','D200232','India','9485509881','sudha.manjunath@example.com'),(233,'Parv','Gatty','D200233','India','9808507491','parv.gatty@example.com'),(234,'Abeer','Rai','D200234','India','7017061124','abeer.rai@example.com'),(235,'Utkarsh','Belligatti','D200235','India','8436108527','utkarsh.belligatti@example.com'),(236,'Nikhitha','Kumari','D200236','India','9251385356','nikhitha.kumari@example.com'),(237,'Atiksh','Chatterjee','D200237','India','7208706096','atiksh.chatterjee@example.com'),(238,'Hredhaan','Gatty','D200238','India','9891593632','hredhaan.gatty@example.com'),(239,'Rebecca','Belligatti','D200239','India','8781240577','rebecca.belligatti@example.com'),(240,'Jagat','Kouser','D200240','India','8664942162','jagat.kouser@example.com'),(241,'Vandana','Gatty','D200241','India','8568182617','vandana.gatty@example.com'),(242,'Madhav','Prabhu','D200242','India','9645999299','madhav.prabhu@example.com'),(243,'Yashodha','Nand','D200243','India','7755408594','yashodha.nand@example.com'),(244,'Gunbir','Chatterjee','D200244','India','9477260238','gunbir.chatterjee@example.com'),(245,'Pallavi','Prajapati','D200245','India','8096186339','pallavi.prajapati@example.com'),(246,'Sagar','Gamskar','D200246','India','8031209596','sagar.gamskar@example.com'),(247,'Sapna','Hiremath','D200247','India','8299616277','sapna.hiremath@example.com'),(248,'Tanveer','Kulkarni','D200248','India','8675223145','tanveer.kulkarni@example.com'),(249,'Dwarakanath','Vernekar','D200249','India','8390441153','dwarakanath.vernekar@example.com'),(250,'Faraj','Taj','D200250','India','7787364097','faraj.taj@example.com'),(251,'Ratnakar','Adiga','D200251','India','8757568958','ratnakar.adiga@example.com'),(252,'Anitha','Pai','D200252','India','8120098714','anitha.pai@example.com'),(253,'Rachana','Chatterjee','D200253','India','9012126649','rachana.chatterjee@example.com'),(254,'Chaitanya','Chatterjee','D200254','India','8375668562','chaitanya.chatterjee@example.com'),(255,'Pavati','Dhamdhame','D200255','India','7339161517','pavati.dhamdhame@example.com'),(256,'Madhura','Bansal','D200256','India','7688248075','madhura.bansal@example.com'),(257,'Navami','Chavare','D200257','India','7819464754','navami.chavare@example.com'),(258,'Brijesh','Bhat','D200258','India','9806199364','brijesh.bhat@example.com'),(259,'Krish','Andrade','D200259','India','8469655798','krish.andrade@example.com'),(260,'Pramila','Dhamdhame','D200260','India','9870643293','pramila.dhamdhame@example.com'),(261,'Kahaan','Jain','D200261','India','8554485458','kahaan.jain@example.com'),(262,'Jayaraj','Almeida','D200262','India','9745257252','jayaraj.almeida@example.com'),(263,'Namratha','Kavser','D200263','India','8361629469','namratha.kavser@example.com'),(264,'Yash','Kini','D200264','India','9632174622','yash.kini@example.com'),(265,'Ratnakar','Banerjee','D200265','India','9174822803','ratnakar.banerjee@example.com'),(266,'Ishaan','Chatterjee','D200266','India','7433402594','ishaan.chatterjee@example.com'),(267,'Deepak','Rai','D200267','India','9083781173','deepak.rai@example.com'),(268,'Arnav','Saldanha','D200268','India','9698051162','arnav.saldanha@example.com'),(269,'Ishaan','Anchan','D200269','India','8236251869','ishaan.anchan@example.com'),(270,'Rushali','Kamath','D200270','India','7448556637','rushali.kamath@example.com'),(271,'Manasa','Sheikh','D200271','India','8125759248','manasa.sheikh@example.com'),(272,'Kahaan','Dawangave','D200272','India','7520950278','kahaan.dawangave@example.com'),(273,'Raunak','Dsouza','D200273','India','7596789299','raunak.dsouza@example.com'),(274,'Sowmya','Dsouza','D200274','India','7419404727','sowmya.dsouza@example.com'),(275,'Anjali','Bhardwaj','D200275','India','7122444833','anjali.bhardwaj@example.com'),(276,'Dhipu','Almeida','D200276','India','8677672682','dhipu.almeida@example.com'),(277,'Gautam','Nagane','D200277','India','8168555741','gautam.nagane@example.com'),(278,'Keerthi','Prabhakaran','D200278','India','9665116151','keerthi.prabhakaran@example.com'),(279,'Dinella','Singh','D200279','India','8613377521','dinella.singh@example.com'),(280,'Vibha','Nagane','D200280','India','9250041840','vibha.nagane@example.com'),(281,'Laksh','Kumari','D200281','India','8014808992','laksh.kumari@example.com'),(282,'Sharanya','Sheikh','D200282','India','7952476409','sharanya.sheikh@example.com'),(283,'Viti','Mardhekar','D200283','India','9777259599','viti.mardhekar@example.com'),(284,'Vaani','Patil','D200284','India','7445863528','vaani.patil@example.com'),(285,'Navya','Bhoja','D200285','India','8833760509','navya.bhoja@example.com'),(286,'Anika','Chavare','D200286','India','7541936828','anika.chavare@example.com'),(287,'Falan','Suvarna','D200287','India','9644203451','falan.suvarna@example.com'),(288,'Sonika','Kumar','D200288','India','9713105998','sonika.kumar@example.com'),(289,'Shravya','Patil','D200289','India','8003076381','shravya.patil@example.com'),(290,'Champak','Prabhu','D200290','India','9170084631','champak.prabhu@example.com'),(291,'Siddharth','Moolya','D200291','India','8993498467','siddharth.moolya@example.com'),(292,'Neel','Kulkarni','D200292','India','8575704692','neel.kulkarni@example.com'),(293,'Sandhya','Prabhakaran','D200293','India','9005654741','sandhya.prabhakaran@example.com'),(294,'Priyanka','Dalvi','D200294','India','7085503661','priyanka.dalvi@example.com'),(295,'Champak','Salian','D200295','India','8833903824','champak.salian@example.com'),(296,'Shobha','Bangera','D200296','India','9633377181','shobha.bangera@example.com'),(297,'Samarth','Taj','D200297','India','9065131868','samarth.taj@example.com'),(298,'Javeria','Thampy','D200298','India','7350048646','javeria.thampy@example.com'),(299,'Divyesh','Bhoja','D200299','India','8324101623','divyesh.bhoja@example.com'),(300,'Vaishnavi','Adiga','D200300','India','7653729948','vaishnavi.adiga@example.com'),(301,'Gaurav','Mathew','D200301','India','9448149014','gaurav.mathew@example.com'),(302,'Akash','Saldanha','D200302','India','8163742199','akash.saldanha@example.com'),(303,'Shreya','Banerjee','D200303','India','7884363546','shreya.banerjee@example.com'),(304,'Reema','Dsouza','D200304','India','7613013809','reema.dsouza@example.com'),(305,'Ishita','Prabhu','D200305','India','9809432887','ishita.prabhu@example.com'),(306,'Karan','Kini','D200306','India','8940908991','karan.kini@example.com'),(307,'Tejas','Belligatti','D200307','India','9767724711','tejas.belligatti@example.com'),(308,'Praneel','Kumar','D200308','India','7576773214','praneel.kumar@example.com'),(309,'Arpitha','Holla','D200309','India','7929692497','arpitha.holla@example.com'),(310,'Avni','Vernekar','D200310','India','7528198159','avni.vernekar@example.com'),(311,'Rakshitha','Salian','D200311','India','9407766693','rakshitha.salian@example.com'),(312,'Bachittar','Shayana','D200312','India','8449197890','bachittar.shayana@example.com'),(313,'Pratima','Suvarna','D200313','India','9901057035','pratima.suvarna@example.com'),(314,'Abeer','Prabhu','D200314','India','9977136187','abeer.prabhu@example.com'),(315,'Lavanya','Anand','D200315','India','9870661497','lavanya.anand@example.com'),(316,'Jagdish','Dsouza','D200316','India','8720509702','jagdish.dsouza@example.com'),(317,'Daksh','Prabhu','D200317','India','7757618008','daksh.prabhu@example.com'),(318,'Kahaan','Rajesh','D200318','India','8168885887','kahaan.rajesh@example.com'),(319,'Kairav','Prabhu','D200319','India','9333269184','kairav.prabhu@example.com'),(320,'Malathy','Salian','D200320','India','7969597929','malathy.salian@example.com'),(321,'Surabhi','Shet','D200321','India','9615091316','surabhi.shet@example.com'),(322,'Taara','Shah','D200322','India','9539254181','taara.shah@example.com'),(323,'Rekha','Shet','D200323','India','7302520865','rekha.shet@example.com'),(324,'Anaisha','Mugeraya','D200324','India','9364526378','anaisha.mugeraya@example.com'),(325,'Meenakshi','Taj','D200325','India','7888371100','meenakshi.taj@example.com'),(326,'Madhumita','Rajesh','D200326','India','9714648184','madhumita.rajesh@example.com'),(327,'Mitesh','Bhat','D200327','India','7172947920','mitesh.bhat@example.com'),(328,'Devashree','Bansal','D200328','India','8660614809','devashree.bansal@example.com'),(329,'Sanchitha','Sheikh','D200329','India','8911964251','sanchitha.sheikh@example.com'),(330,'Samaksh','Fernandes','D200330','India','9773499622','samaksh.fernandes@example.com'),(331,'Suhasini','Keshri','D200331','India','7766022542','suhasini.keshri@example.com'),(332,'Kripa','Bhardwaj','D200332','India','8522689129','kripa.bhardwaj@example.com'),(333,'Abhijith','Banerjee','D200333','India','8403005849','abhijith.banerjee@example.com'),(334,'Sanchitha','Manjunath','D200334','India','9091098784','sanchitha.manjunath@example.com'),(335,'Balveer','Banerjee','D200335','India','8541788011','balveer.banerjee@example.com'),(336,'Yagnesh','Bansal','D200336','India','8609437113','yagnesh.bansal@example.com'),(337,'Gaurav','Babu','D200337','India','8749223541','gaurav.babu@example.com'),(338,'Malathy','Kaur','D200338','India','8695108373','malathy.kaur@example.com'),(339,'Dinella','Kumar','D200339','India','7066758128','dinella.kumar@example.com'),(340,'Akshay','Mugeraya','D200340','India','9183278585','akshay.mugeraya@example.com'),(341,'Saksham','Bhardwaj','D200341','India','8619146399','saksham.bhardwaj@example.com'),(342,'Samarth','Pujari','D200342','India','8914388175','samarth.pujari@example.com'),(343,'Sangeetha','Nagane','D200343','India','9050772244','sangeetha.nagane@example.com'),(344,'Pavati','Patil','D200344','India','8363144921','pavati.patil@example.com'),(345,'Manasa','Ramesh','D200345','India','7809404109','manasa.ramesh@example.com'),(346,'Tanveer','Anand','D200346','India','8001209842','tanveer.anand@example.com'),(347,'Soumyashree','Shukla','D200347','India','9912526704','soumyashree.shukla@example.com'),(348,'Manvitha','Chavare','D200348','India','8149695173','manvitha.chavare@example.com'),(349,'Abitha','Nayak','D200349','India','9165933683','abitha.nayak@example.com'),(350,'Bachittar','Dhamdhame','D200350','India','9265965825','bachittar.dhamdhame@example.com'),(351,'Yash','Jain','D200351','India','9045845686','yash.jain@example.com'),(352,'Harsh','Acharya','D200352','India','8440971504','harsh.acharya@example.com'),(353,'Shwetha','Moolya','D200353','India','9072385344','shwetha.moolya@example.com'),(354,'Ishana','Tipparti','D200354','India','9105737159','ishana.tipparti@example.com'),(355,'Meghana','Taj','D200355','India','7878769445','meghana.taj@example.com'),(356,'Darsh','Kumari','D200356','India','9601332184','darsh.kumari@example.com'),(357,'Harshitha','Moolya','D200357','India','7176559788','harshitha.moolya@example.com'),(358,'Tarak','Pujari','D200358','India','7275573410','tarak.pujari@example.com'),(359,'Gunbir','Namnaik','D200359','India','9787503789','gunbir.namnaik@example.com'),(360,'Aparna','Nayak','D200360','India','8659484485','aparna.nayak@example.com'),(361,'Namitha','Fernandes','D200361','India','8636865240','namitha.fernandes@example.com'),(362,'Hrithik','Almeida','D200362','India','7739102577','hrithik.almeida@example.com'),(363,'Mehar','Anand','D200363','India','7591051833','mehar.anand@example.com'),(364,'Vidya','Bhat','D200364','India','9461443592','vidya.bhat@example.com'),(365,'Chaitra','Dawangave','D200365','India','8407045507','chaitra.dawangave@example.com'),(366,'Chinmayee','Prajapati','D200366','India','7436092438','chinmayee.prajapati@example.com'),(367,'Orinder','Shetty','D200367','India','9107557236','orinder.shetty@example.com'),(368,'Madhumita','Bharanya','D200368','India','9443840171','madhumita.bharanya@example.com'),(369,'Atharv','Bangera','D200369','India','9913810350','atharv.bangera@example.com'),(370,'Madhura','Naik','D200370','India','9233844658','madhura.naik@example.com'),(371,'Dhipu','Suvarna','D200371','India','8326293411','dhipu.suvarna@example.com'),(372,'Reshma','Uchil','D200372','India','9982914045','reshma.uchil@example.com'),(373,'Daksh','Nayak','D200373','India','7988080518','daksh.nayak@example.com'),(374,'Savitha','Shah','D200374','India','9058493312','savitha.shah@example.com'),(375,'Rohan','Chatterjee','D200375','India','8033031054','rohan.chatterjee@example.com'),(376,'Yuvraj','Gugale','D200376','India','7967464418','yuvraj.gugale@example.com'),(377,'Dona','Adiga','D200377','India','9852501614','dona.adiga@example.com'),(378,'Utkarsh','Rajesh','D200378','India','8356437764','utkarsh.rajesh@example.com'),(379,'Chaitra','Kamath','D200379','India','8487946820','chaitra.kamath@example.com'),(380,'Asha','Bhardwaj','D200380','India','9256340398','asha.bhardwaj@example.com'),(381,'Tanveer','Kumari','D200381','India','8657638435','tanveer.kumari@example.com'),(382,'Neysa','Bansal','D200382','India','7791435141','neysa.bansal@example.com'),(383,'Shahistha','Vernekar','D200383','India','9702537706','shahistha.vernekar@example.com'),(384,'Yagnesh','Shah','D200384','India','8429590932','yagnesh.shah@example.com'),(385,'Sowmya','Saha','D200385','India','9627776072','sowmya.saha@example.com'),(386,'Vaani','Babu','D200386','India','7419380329','vaani.babu@example.com'),(387,'Shabari','Kini','D200387','India','9082473528','shabari.kini@example.com'),(388,'Nachiket','Kini','D200388','India','7220724567','nachiket.kini@example.com'),(389,'Dileep','Raval','D200389','India','8130631356','dileep.raval@example.com'),(390,'Ravi','Naik','D200390','India','9939579090','ravi.naik@example.com'),(391,'Navya','Thampy','D200391','India','9595665493','navya.thampy@example.com'),(392,'Shrinidhi','Dalvi','D200392','India','8569352771','shrinidhi.dalvi@example.com'),(393,'Monisha','Patil','D200393','India','7974178626','monisha.patil@example.com'),(394,'Manasa','Namnaik','D200394','India','7063251462','manasa.namnaik@example.com'),(395,'Deepika','Kamath','D200395','India','7282005062','deepika.kamath@example.com'),(396,'Mangala','Shayana','D200396','India','8197024518','mangala.shayana@example.com'),(397,'Divya','Salian','D200397','India','9703857055','divya.salian@example.com'),(398,'Ekapad','Pujari','D200398','India','8347918911','ekapad.pujari@example.com'),(399,'Dharmesh','Keshri','D200399','India','7524374868','dharmesh.keshri@example.com'),(400,'Samaksh','Gatty','D200400','India','8494047398','samaksh.gatty@example.com'),(401,'Bharathy','Nagane','D200401','India','8783876126','bharathy.nagane@example.com'),(402,'Vidya','Anand','D200402','India','8844809665','vidya.anand@example.com'),(403,'Savitha','Rai','D200403','India','7003712669','savitha.rai@example.com'),(404,'Akhil','Saha','D200404','India','7644070009','akhil.saha@example.com'),(406,'Sita','Das','D200405','India','9694680138','sita.das@example.com'),(407,'Aloke','Shet','D200406','India','7321545001','aloke.shet@example.com'),(408,'Yuvraj','Chavare','D200407','India','7974615398','yuvraj.chavare@example.com'),(410,'Vidya','Chatterjee','D200408','India','9782652505','vidya.chatterjee@example.com'),(411,'Joseph','Manjunath','D200409','India','9716517765','joseph.manjunath@example.com'),(412,'Anujna','Kini','D200410','India','9930417841','anujna.kini@example.com'),(413,'Likhitha','Shukla','D200411','India','8196652695','likhitha.shukla@example.com'),(414,'Chanakya','Adiga','D200412','India','9184425276','chanakya.adiga@example.com'),(415,'Nakul','Chatterjee','D200413','India','8544055085','nakul.chatterjee@example.com'),(416,'Vivek','Prajapati','D200414','India','9307128098','vivek.prajapati@example.com'),(417,'Chaithra','Kulkarni','D200415','India','7906006914','chaithra.kulkarni@example.com'),(418,'Ishana','Sheikh','D200416','India','8715662776','ishana.sheikh@example.com'),(419,'Pavati','Kamath','D200417','India','7630036170','pavati.kamath@example.com'),(420,'Bachittar','Anchan','D200418','India','9295215404','bachittar.anchan@example.com'),(421,'Balhaar','Saldanha','D200419','India','8579481583','balhaar.saldanha@example.com'),(422,'Karan','Pujari','D200420','India','8969386392','karan.pujari@example.com'),(423,'Asmee','Suvarna','D200421','India','8578319298','asmee.suvarna@example.com'),(424,'Geetha','Raval','D200422','India','8146338343','geetha.raval@example.com'),(425,'Sangeetha','Dsouza','D200423','India','8163732569','sangeetha.dsouza@example.com'),(426,'Gayathri','Fernandes','D200424','India','8705064810','gayathri.fernandes@example.com'),(427,'Kimaya','Sullad','D200425','India','7881939476','kimaya.sullad@example.com'),(428,'Arnav','Bharanya','D200426','India','7157324967','arnav.bharanya@example.com'),(429,'Guneet','Das','D200427','India','9192309690','guneet.das@example.com'),(430,'Swarna','Prajapati','D200428','India','8152728380','swarna.prajapati@example.com'),(431,'Mishka','Raval','D200429','India','7086667417','mishka.raval@example.com'),(432,'Tarak','Bhardwaj','D200430','India','8616895957','tarak.bhardwaj@example.com'),(433,'Yatin','Saldanha','D200431','India','7419108693','yatin.saldanha@example.com'),(434,'Vedant','Singh','D200432','India','9014572314','vedant.singh@example.com'),(435,'Keerthi','Dalvi','D200433','India','9779784784','keerthi.dalvi@example.com'),(436,'Rohan','Kaur','D200434','India','7161018221','rohan.kaur@example.com'),(437,'Chandresh','Shenoy','D200435','India','8906329670','chandresh.shenoy@example.com'),(438,'Prathiksha','Gamskar','D200436','India','8921426921','prathiksha.gamskar@example.com'),(439,'Arpitha','Bal','D200437','India','7103458047','arpitha.bal@example.com'),(440,'Utkarsh','Dalvi','D200438','India','9000317382','utkarsh.dalvi@example.com'),(441,'Sudha','Bangera','D200439','India','9209126702','sudha.bangera@example.com'),(442,'Aashish','Shukla','D200440','India','9807989246','aashish.shukla@example.com'),(443,'Deeksha','Gatty','D200441','India','7164045115','deeksha.gatty@example.com'),(444,'Krishna','Pujari','D200442','India','8314249356','krishna.pujari@example.com'),(445,'Shreya','Gatty','D200443','India','8937876576','shreya.gatty@example.com'),(446,'Lohit','Bal','D200444','India','7049935462','lohit.bal@example.com'),(447,'Pooja','Bhat','D200445','India','7246534335','pooja.bhat@example.com'),(448,'Chaitra','Andrade','D200446','India','7261384797','chaitra.andrade@example.com'),(449,'Jeet','Chiplunkar','D200447','India','8983562873','jeet.chiplunkar@example.com'),(450,'Pramitha','Patil','D200448','India','9261111670','pramitha.patil@example.com'),(451,'Arjun','Saha','D200449','India','8102491854','arjun.saha@example.com'),(452,'Monali','Namnaik','D200450','India','8055033063','monali.namnaik@example.com'),(453,'Shilpa','Padmanabha','D200451','India','9441962743','shilpa.padmanabha@example.com'),(454,'Jayaraj','Kini','D200452','India','9109056654','jayaraj.kini@example.com'),(455,'Pranit','Gatty','D200453','India','7301126638','pranit.gatty@example.com'),(456,'Sushma','Ramesh','D200454','India','9732368012','sushma.ramesh@example.com'),(457,'Ratnakar','Bangera','D200455','India','8750167840','ratnakar.bangera@example.com'),(458,'Gunbir','Vernekar','D200456','India','7601131460','gunbir.vernekar@example.com'),(459,'Rishi','Gamskar','D200457','India','9632362876','rishi.gamskar@example.com'),(460,'Chandresh','Raval','D200458','India','7663301941','chandresh.raval@example.com'),(461,'Baljiwan','Pujari','D200459','India','9048702802','baljiwan.pujari@example.com'),(462,'Zayan','Kouser','D200460','India','8255600706','zayan.kouser@example.com'),(463,'Yatin','Chiplunkar','D200461','India','9297102345','yatin.chiplunkar@example.com'),(464,'Aryan','Bhat','D200462','India','7804309705','aryan.bhat@example.com'),(465,'Chaithra','Tipparti','D200463','India','8206197968','chaithra.tipparti@example.com'),(466,'Shreedevi','Bhoja','D200464','India','8668367549','shreedevi.bhoja@example.com'),(467,'Siddharth','Dsouza','D200465','India','8813355219','siddharth.dsouza@example.com'),(468,'Gagan','Saniel','D200466','India','7431911644','gagan.saniel@example.com'),(469,'Dwarakanath','Bangera','D200467','India','8894822155','dwarakanath.bangera@example.com'),(470,'Darpan','Chatterjee','D200468','India','9772337488','darpan.chatterjee@example.com'),(471,'Abhijith','Belligatti','D200469','India','8986559756','abhijith.belligatti@example.com'),(472,'Vivek','Gamskar','D200470','India','8319937543','vivek.gamskar@example.com'),(473,'Meenakshi','Chavare','D200471','India','7341214644','meenakshi.chavare@example.com'),(474,'Rekha','Prajapati','D200472','India','7990672481','rekha.prajapati@example.com'),(475,'Rushil','Suvarna','D200473','India','7629547829','rushil.suvarna@example.com'),(476,'Gopika','Taj','D200474','India','7989598218','gopika.taj@example.com'),(477,'Pooja','Singh','D200475','India','8333709623','pooja.singh@example.com'),(478,'Vaishnavi','Moolya','D200476','India','9985793261','vaishnavi.moolya@example.com'),(479,'Manisha','Saniel','D200477','India','9844253074','manisha.saniel@example.com'),(480,'Nagraj','Kaur','D200478','India','8710138624','nagraj.kaur@example.com'),(481,'Rishi','Rao','D200479','India','7618757347','rishi.rao@example.com'),(482,'Rahul','Chatterjee','D200480','India','9621766451','rahul.chatterjee@example.com'),(483,'Harshitha','Adiga','D200481','India','9540807432','harshitha.adiga@example.com'),(484,'Pramila','Uchil','D200482','India','9949572148','pramila.uchil@example.com'),(485,'Abhimanyu','Uchil','D200483','India','7907641622','abhimanyu.uchil@example.com'),(486,'Suhasini','Belligatti','D200484','India','9960470105','suhasini.belligatti@example.com'),(487,'Shreedevi','Patil','D200485','India','9523663857','shreedevi.patil@example.com'),(488,'Rekha','Saha','D200486','India','9258574719','rekha.saha@example.com'),(489,'Raj','Shetty','D200487','India','9469329788','raj.shetty@example.com'),(490,'Sushma','Sullad','D200488','India','9781402279','sushma.sullad@example.com'),(491,'Nayana','Gupta','D200489','India','8909919547','nayana.gupta@example.com'),(492,'Krishna','Mardhekar','D200490','India','7416661392','krishna.mardhekar@example.com'),(493,'Shubha','Mathew','D200491','India','7374175747','shubha.mathew@example.com'),(494,'Ryan','Kavser','D200492','India','7207816124','ryan.kavser@example.com'),(495,'Gopika','Gupta','D200493','India','8398661874','gopika.gupta@example.com'),(496,'Divya','Dawangave','D200494','India','8906797398','divya.dawangave@example.com'),(497,'Harish','Kavser','D200495','India','7816082099','harish.kavser@example.com'),(498,'Sowmya','Manjunath','D200496','India','8949322340','sowmya.manjunath@example.com'),(499,'Nitesh','Bal','D200497','India','9280423450','nitesh.bal@example.com'),(500,'Shylaja','Nayak','D200498','India','9681698876','shylaja.nayak@example.com'),(501,'Chinmayee','Saha','D200499','India','9423471127','chinmayee.saha@example.com'),(502,'Aayushi','Acharya','D200500','India','7511049835','aayushi.acharya@example.com'),(503,'Arin','Nair','D200501','India','7434733796','arin.nair@example.com'),(504,'Aaradhya','Pujari','D200502','India','9072367625','aaradhya.pujari@example.com'),(505,'Sethu','Shetty','D200503','India','7944012048','sethu.shetty@example.com'),(506,'Supritha','Raval','D200504','India','9717623613','supritha.raval@example.com'),(507,'Adhira','Kumar','D200505','India','9774584104','adhira.kumar@example.com'),(508,'Prakruthi','Shukla','D200506','India','7683675647','prakruthi.shukla@example.com'),(509,'Sarthak','Mathew','D200507','India','7301565996','sarthak.mathew@example.com'),(510,'Vivek','Rao','D200508','India','7388841045','vivek.rao@example.com'),(511,'Hrithik','Shroff','D200509','India','8211552898','hrithik.shroff@example.com'),(512,'Taara','Anand','D200510','India','7681484698','taara.anand@example.com'),(513,'Saheli','Prajapati','D200511','India','8813811080','saheli.prajapati@example.com'),(514,'Divya','Bangera','D200512','India','8641793468','divya.bangera@example.com'),(515,'Nimit','Kumar','D200513','India','8416676181','nimit.kumar@example.com'),(516,'Tejas','Prabhu','D200514','India','7499118824','tejas.prabhu@example.com'),(517,'Gopika','Nayak','D200515','India','9342454284','gopika.nayak@example.com'),(518,'Aarush','Anand','D200516','India','9786960245','aarush.anand@example.com'),(519,'Dhipu','Kumari','D200517','India','8406824078','dhipu.kumari@example.com'),(520,'Vaibhavi','Gugale','D200518','India','9745340506','vaibhavi.gugale@example.com'),(521,'Shaurya','Holla','D200519','India','9184361550','shaurya.holla@example.com'),(522,'Reyansh','Padmanabha','D200520','India','8377151764','reyansh.padmanabha@example.com'),(523,'Deeksha','Shah','D200521','India','7309597270','deeksha.shah@example.com'),(524,'Dwarakanath','Kumari','D200522','India','9410502843','dwarakanath.kumari@example.com'),(525,'Aishwarya','Anand','D200523','India','9031801155','aishwarya.anand@example.com'),(526,'Swathi','Fernandes','D200524','India','9651343355','swathi.fernandes@example.com'),(527,'Samarth','Raval','D200525','India','8005866227','samarth.raval@example.com'),(528,'Avi','Bhat','D200526','India','9838888618','avi.bhat@example.com'),(529,'Veena','Acharya','D200527','India','9455516577','veena.acharya@example.com'),(530,'Priya','Bal','D200528','India','8448529459','priya.bal@example.com'),(531,'Tejaswi','Namnaik','D200529','India','8896878481','tejaswi.namnaik@example.com'),(532,'Gopal','Acharya','D200530','India','8639393125','gopal.acharya@example.com'),(533,'Tanveer','Shenoy','D200531','India','7311357821','tanveer.shenoy@example.com'),(534,'Darsh','Anchan','D200532','India','9399999681','darsh.anchan@example.com'),(535,'Abhinav','Kumari','D200533','India','8652232444','abhinav.kumari@example.com'),(536,'Javeria','Shet','D200534','India','9760970310','javeria.shet@example.com'),(537,'Chaithra','Raval','D200535','India','9645231497','chaithra.raval@example.com'),(538,'Ananth','Shetty','D200536','India','8691160102','ananth.shetty@example.com'),(539,'Deepika','Shayana','D200537','India','7503497249','deepika.shayana@example.com'),(540,'Rebecca','Adiga','D200538','India','8833680721','rebecca.adiga@example.com'),(541,'Meghana','Shenoy','D200539','India','9243371203','meghana.shenoy@example.com'),(542,'Priyanka','Shenoy','D200540','India','8024320819','priyanka.shenoy@example.com'),(543,'Rekha','Nand','D200541','India','9614259859','rekha.nand@example.com'),(544,'Hetal','Bansal','D200542','India','8715196490','hetal.bansal@example.com'),(545,'Tarak','Bal','D200543','India','8789582647','tarak.bal@example.com'),(546,'Saanvi','Sheikh','D200544','India','7226709045','saanvi.sheikh@example.com'),(547,'Girindra','Banerjee','D200545','India','8371330701','girindra.banerjee@example.com'),(548,'Fitan','Raval','D200546','India','8497492622','fitan.raval@example.com'),(549,'Hredhaan','Shetty','D200547','India','8513393843','hredhaan.shetty@example.com'),(550,'Suraksha','Manjunath','D200548','India','9426053496','suraksha.manjunath@example.com'),(551,'Pranav','Saha','D200549','India','9335241828','pranav.saha@example.com'),(552,'Vedant','Saha','D200550','India','9715108594','vedant.saha@example.com'),(553,'Harini','Suvarna','D200551','India','7545735350','harini.suvarna@example.com'),(554,'Gagan','Mendonsa','D200552','India','8685135343','gagan.mendonsa@example.com'),(555,'Gagan','Gatty','D200553','India','8563381834','gagan.gatty@example.com'),(556,'Dinella','Bhat','D200554','India','8690402477','dinella.bhat@example.com'),(557,'Veer','Prajapati','D200555','India','9147235752','veer.prajapati@example.com'),(558,'Hrithik','Keshri','D200556','India','9593225904','hrithik.keshri@example.com'),(559,'Manisha','Belligatti','D200557','India','7327205252','manisha.belligatti@example.com'),(560,'Prathiksha','Gupta','D200558','India','9956874701','prathiksha.gupta@example.com'),(561,'Anusree','Anand','D200559','India','9761236895','anusree.anand@example.com'),(562,'Anusha','Kini','D200560','India','9160053774','anusha.kini@example.com'),(563,'Anaisha','Dalvi','D200561','India','8723457057','anaisha.dalvi@example.com'),(564,'Manvitha','Bal','D200562','India','7059518813','manvitha.bal@example.com'),(565,'Chaithra','Kini','D200563','India','9880756741','chaithra.kini@example.com'),(566,'Abitha','Nagane','D200564','India','9265591972','abitha.nagane@example.com'),(567,'Grishma','Shayana','D200565','India','8035398698','grishma.shayana@example.com'),(568,'Tarak','Shet','D200566','India','9763565343','tarak.shet@example.com'),(569,'Abhishek','Hiremath','D200567','India','9486265512','abhishek.hiremath@example.com'),(570,'Devansh','Tipparti','D200568','India','7551379747','devansh.tipparti@example.com'),(571,'Prithvi','Nair','D200569','India','7405372337','prithvi.nair@example.com'),(572,'Gautam','Rajesh','D200570','India','8412446221','gautam.rajesh@example.com'),(573,'Navya','Kini','D200571','India','9830129206','navya.kini@example.com'),(574,'Aadi','Nagane','D200572','India','8534726302','aadi.nagane@example.com'),(575,'Prisha','Bal','D200573','India','8781010535','prisha.bal@example.com'),(576,'Maanas','Das','D200574','India','9450012149','maanas.das@example.com'),(577,'Adah','Adiga','D200575','India','9756072877','adah.adiga@example.com'),(578,'Sai','Chavare','D200576','India','9066781728','sai.chavare@example.com'),(579,'Harsh','Adiga','D200577','India','9838960695','harsh.adiga@example.com'),(580,'Nisha','Tipparti','D200578','India','9867878215','nisha.tipparti@example.com'),(581,'Supriya','Kumar','D200579','India','9342612844','supriya.kumar@example.com'),(582,'Meghana','Nair','D200580','India','9187747548','meghana.nair@example.com'),(583,'Pratima','Prabhakaran','D200581','India','7360813774','pratima.prabhakaran@example.com'),(584,'Baljiwan','Holla','D200582','India','8933333167','baljiwan.holla@example.com'),(585,'Rachit','Almeida','D200583','India','8045514078','rachit.almeida@example.com'),(586,'Sushma','Manjunath','D200584','India','7744655176','sushma.manjunath@example.com'),(587,'Mahika','Padmanabha','D200585','India','9576841603','mahika.padmanabha@example.com'),(588,'Dharmesh','Shukla','D200586','India','9617884186','dharmesh.shukla@example.com'),(589,'Samarth','Mathew','D200587','India','7013056365','samarth.mathew@example.com'),(590,'Falan','Mardhekar','D200588','India','7281852160','falan.mardhekar@example.com'),(591,'Yatin','Raval','D200589','India','7022510392','yatin.raval@example.com'),(592,'Nachiket','Adiga','D200590','India','7658945512','nachiket.adiga@example.com'),(593,'Balveer','Shet','D200591','India','9132638691','balveer.shet@example.com'),(594,'Samarth','Gamskar','D200592','India','8229782981','samarth.gamskar@example.com'),(595,'Anusree','Saha','D200593','India','9278265472','anusree.saha@example.com'),(596,'Sethu','Moolya','D200594','India','8850034657','sethu.moolya@example.com'),(597,'Anupama','Shah','D200595','India','7814944911','anupama.shah@example.com'),(598,'Raksha','Kaur','D200596','India','9338394249','raksha.kaur@example.com'),(599,'Deepak','Pai','D200597','India','8146237856','deepak.pai@example.com'),(600,'Sowmya','Chiplunkar','D200598','India','8017284625','sowmya.chiplunkar@example.com'),(601,'Rekha','Almeida','D200599','India','8222065903','rekha.almeida@example.com'),(602,'Atharv','Nand','D200600','India','8940196726','atharv.nand@example.com');
/*!40000 ALTER TABLE `passengers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `amount` double NOT NULL,
  `pay_method` varchar(24) NOT NULL,
  `pay_status` varchar(16) NOT NULL DEFAULT 'Pending',
  `txn_reference` varchar(32) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `booking_id` (`booking_id`),
  UNIQUE KEY `txn_reference` (`txn_reference`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payments_chk_1` CHECK ((`amount` >= 0)),
  CONSTRAINT `payments_chk_2` CHECK ((`pay_status` in (_utf8mb4'Pending',_utf8mb4'Paid',_utf8mb4'Failed',_utf8mb4'Refunded')))
) ENGINE=InnoDB AUTO_INCREMENT=726 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,1,4742,'UPI','Paid','TXNAPP100001',NULL),(2,2,5215,'UPI','Paid','TXNAPP100002',NULL),(3,3,5193,'UPI','Paid','TXNAPP100003',NULL),(4,4,4499,'UPI','Paid','TXNAPP100004',NULL),(5,5,4248,'UPI','Paid','TXNAPP100005',NULL),(6,6,4306,'UPI','Paid','TXNAPP100006',NULL),(7,7,5120,'UPI','Paid','TXNAPP100007',NULL),(8,8,4431,'UPI','Paid','TXNAPP100008',NULL),(9,9,4874,'UPI','Paid','TXNAPP100009',NULL),(10,10,5274,'UPI','Paid','TXNAPP100010',NULL),(11,11,4975,'UPI','Paid','TXNAPP100011',NULL),(12,12,5106,'UPI','Paid','TXNAPP100012',NULL),(13,13,4773,'UPI','Paid','TXNAPP100013',NULL),(14,14,4453,'UPI','Paid','TXNAPP100014',NULL),(15,15,4978,'UPI','Paid','TXNAPP100015',NULL),(16,16,5085,'UPI','Paid','TXNAPP100016',NULL),(17,17,4600,'UPI','Paid','TXNAPP100017',NULL),(18,18,4595,'UPI','Paid','TXNAPP100018',NULL),(19,19,5171,'UPI','Paid','TXNAPP100019',NULL),(20,20,5028,'UPI','Paid','TXNAPP100020',NULL),(21,21,4328,'UPI','Paid','TXNAPP100021',NULL),(22,22,4599,'UPI','Paid','TXNAPP100022',NULL),(23,23,4894,'UPI','Paid','TXNAPP100023',NULL),(24,24,4289,'UPI','Paid','TXNAPP100024',NULL),(25,25,4848,'UPI','Paid','TXNAPP100025',NULL),(26,26,4333,'UPI','Paid','TXNAPP100026',NULL),(27,27,5173,'UPI','Paid','TXNAPP100027',NULL),(28,28,4991,'UPI','Paid','TXNAPP100028',NULL),(29,29,5210,'UPI','Paid','TXNAPP100029',NULL),(30,30,4217,'UPI','Paid','TXNAPP100030',NULL),(31,31,4965,'UPI','Paid','TXNAPP100031',NULL),(32,32,4444,'UPI','Paid','TXNAPP100032',NULL),(33,33,5394,'UPI','Paid','TXNAPP100033',NULL),(34,34,5249,'UPI','Paid','TXNAPP100034',NULL),(35,35,4732,'UPI','Paid','TXNAPP100035',NULL),(36,36,4212,'UPI','Paid','TXNAPP100036',NULL),(37,37,4916,'UPI','Paid','TXNAPP100037',NULL),(38,38,4489,'UPI','Paid','TXNAPP100038',NULL),(39,39,4278,'UPI','Paid','TXNAPP100039',NULL),(40,40,4616,'UPI','Paid','TXNAPP100040',NULL),(41,41,5037,'UPI','Paid','TXNAPP100041',NULL),(42,42,4839,'UPI','Paid','TXNAPP100042',NULL),(43,43,5215,'UPI','Paid','TXNAPP100043',NULL),(44,44,4407,'UPI','Paid','TXNAPP100044',NULL),(45,45,4516,'UPI','Paid','TXNAPP100045',NULL),(46,46,4535,'UPI','Paid','TXNAPP100046',NULL),(47,47,4780,'UPI','Paid','TXNAPP100047',NULL),(48,48,4305,'UPI','Paid','TXNAPP100048',NULL),(49,49,4931,'UPI','Paid','TXNAPP100049',NULL),(50,50,4945,'UPI','Paid','TXNAPP100050',NULL),(51,51,5029,'UPI','Paid','TXNAPP100051',NULL),(52,52,4520,'UPI','Paid','TXNAPP100052',NULL),(53,53,5031,'UPI','Paid','TXNAPP100053',NULL),(54,54,4532,'UPI','Paid','TXNAPP100054',NULL),(55,55,4491,'UPI','Paid','TXNAPP100055',NULL),(56,56,4382,'UPI','Paid','TXNAPP100056',NULL),(57,57,5233,'UPI','Paid','TXNAPP100057',NULL),(58,58,4531,'UPI','Paid','TXNAPP100058',NULL),(59,59,4422,'UPI','Paid','TXNAPP100059',NULL),(60,60,4604,'UPI','Paid','TXNAPP100060',NULL),(61,61,4289,'UPI','Paid','TXNAPP100061',NULL),(62,62,4309,'UPI','Paid','TXNAPP100062',NULL),(63,63,4376,'UPI','Paid','TXNAPP100063',NULL),(64,64,4528,'UPI','Paid','TXNAPP100064',NULL),(65,65,5028,'UPI','Paid','TXNAPP100065',NULL),(66,66,5168,'UPI','Paid','TXNAPP100066',NULL),(67,67,5247,'UPI','Paid','TXNAPP100067',NULL),(68,68,4973,'UPI','Paid','TXNAPP100068',NULL),(69,69,4252,'UPI','Paid','TXNAPP100069',NULL),(70,70,4424,'UPI','Paid','TXNAPP100070',NULL),(71,71,5207,'UPI','Paid','TXNAPP100071',NULL),(72,72,4538,'UPI','Paid','TXNAPP100072',NULL),(73,73,4652,'UPI','Paid','TXNAPP100073',NULL),(74,74,4716,'UPI','Paid','TXNAPP100074',NULL),(75,75,4763,'UPI','Paid','TXNAPP100075',NULL),(76,76,4720,'UPI','Paid','TXNAPP100076',NULL),(77,77,4626,'UPI','Paid','TXNAPP100077',NULL),(78,78,4686,'UPI','Paid','TXNAPP100078',NULL),(79,79,4572,'UPI','Paid','TXNAPP100079',NULL),(80,80,4769,'UPI','Paid','TXNAPP100080',NULL),(81,81,4545,'UPI','Paid','TXNAPP100081',NULL),(82,82,5286,'UPI','Paid','TXNAPP100082',NULL),(83,83,5127,'UPI','Paid','TXNAPP100083',NULL),(84,84,4414,'UPI','Paid','TXNAPP100084',NULL),(85,85,5007,'UPI','Paid','TXNAPP100085',NULL),(86,86,4969,'UPI','Paid','TXNAPP100086',NULL),(87,87,4937,'UPI','Paid','TXNAPP100087',NULL),(88,88,4671,'UPI','Paid','TXNAPP100088',NULL),(89,89,4298,'UPI','Paid','TXNAPP100089',NULL),(90,90,4835,'UPI','Paid','TXNAPP100090',NULL),(91,91,5399,'UPI','Paid','TXNAPP100091',NULL),(92,92,4203,'UPI','Paid','TXNAPP100092',NULL),(93,93,4795,'UPI','Paid','TXNAPP100093',NULL),(94,94,4698,'UPI','Paid','TXNAPP100094',NULL),(95,95,4330,'UPI','Paid','TXNAPP100095',NULL),(96,96,4752,'UPI','Paid','TXNAPP100096',NULL),(97,97,4223,'UPI','Paid','TXNAPP100097',NULL),(98,98,4917,'UPI','Paid','TXNAPP100098',NULL),(99,99,5260,'UPI','Paid','TXNAPP100099',NULL),(100,100,4200,'UPI','Paid','TXNAPP100100',NULL),(101,101,5031,'UPI','Paid','TXNAPP100101',NULL),(102,102,4414,'UPI','Paid','TXNAPP100102',NULL),(103,103,4603,'UPI','Paid','TXNAPP100103',NULL),(104,104,5238,'UPI','Paid','TXNAPP100104',NULL),(105,105,4557,'UPI','Paid','TXNAPP100105',NULL),(106,106,4295,'UPI','Paid','TXNAPP100106',NULL),(107,107,4944,'UPI','Paid','TXNAPP100107',NULL),(108,108,5293,'UPI','Paid','TXNAPP100108',NULL),(109,109,4986,'UPI','Paid','TXNAPP100109',NULL),(110,110,4429,'UPI','Paid','TXNAPP100110',NULL),(111,111,4379,'UPI','Paid','TXNAPP100111',NULL),(112,112,4788,'UPI','Paid','TXNAPP100112',NULL),(113,113,4619,'UPI','Paid','TXNAPP100113',NULL),(114,114,4734,'UPI','Paid','TXNAPP100114',NULL),(115,115,4778,'UPI','Paid','TXNAPP100115',NULL),(116,116,4857,'UPI','Paid','TXNAPP100116',NULL),(117,117,5175,'UPI','Paid','TXNAPP100117',NULL),(118,118,4263,'UPI','Paid','TXNAPP100118',NULL),(119,119,5262,'UPI','Paid','TXNAPP100119',NULL),(120,120,4298,'UPI','Paid','TXNAPP100120',NULL),(121,121,4386,'UPI','Paid','TXNAPP100121',NULL),(122,122,5093,'UPI','Paid','TXNAPP100122',NULL),(123,123,4310,'UPI','Paid','TXNAPP100123',NULL),(124,124,5206,'UPI','Paid','TXNAPP100124',NULL),(125,125,5212,'UPI','Paid','TXNAPP100125',NULL),(126,126,5255,'UPI','Paid','TXNAPP100126',NULL),(127,127,4781,'UPI','Paid','TXNAPP100127',NULL),(128,128,4674,'UPI','Paid','TXNAPP100128',NULL),(129,129,4365,'UPI','Paid','TXNAPP100129',NULL),(130,130,5349,'UPI','Paid','TXNAPP100130',NULL),(131,131,4928,'UPI','Paid','TXNAPP100131',NULL),(132,132,4376,'UPI','Paid','TXNAPP100132',NULL),(133,133,4961,'UPI','Paid','TXNAPP100133',NULL),(134,134,5316,'UPI','Paid','TXNAPP100134',NULL),(135,135,4678,'UPI','Paid','TXNAPP100135',NULL),(136,136,4269,'UPI','Paid','TXNAPP100136',NULL),(137,137,4518,'UPI','Paid','TXNAPP100137',NULL),(138,138,5334,'UPI','Paid','TXNAPP100138',NULL),(139,139,5098,'UPI','Paid','TXNAPP100139',NULL),(140,140,4673,'UPI','Paid','TXNAPP100140',NULL),(141,141,4687,'UPI','Paid','TXNAPP100141',NULL),(142,142,4516,'UPI','Paid','TXNAPP100142',NULL),(143,143,4868,'UPI','Paid','TXNAPP100143',NULL),(144,144,5395,'UPI','Paid','TXNAPP100144',NULL),(145,145,4454,'UPI','Paid','TXNAPP100145',NULL),(146,146,4400,'UPI','Paid','TXNAPP100146',NULL),(147,147,5019,'UPI','Paid','TXNAPP100147',NULL),(148,148,4712,'UPI','Paid','TXNAPP100148',NULL),(149,149,4240,'UPI','Paid','TXNAPP100149',NULL),(150,150,4574,'UPI','Paid','TXNAPP100150',NULL),(151,151,4221,'UPI','Paid','TXNAPP100151',NULL),(152,152,4417,'UPI','Paid','TXNAPP100152',NULL),(153,153,4529,'UPI','Paid','TXNAPP100153',NULL),(154,154,4609,'UPI','Paid','TXNAPP100154',NULL),(155,155,5376,'UPI','Paid','TXNAPP100155',NULL),(156,156,5174,'UPI','Paid','TXNAPP100156',NULL),(157,157,4957,'UPI','Paid','TXNAPP100157',NULL),(158,158,5135,'UPI','Paid','TXNAPP100158',NULL),(159,159,5003,'UPI','Paid','TXNAPP100159',NULL),(160,160,4928,'UPI','Paid','TXNAPP100160',NULL),(161,161,4982,'UPI','Paid','TXNAPP100161',NULL),(162,162,5057,'UPI','Paid','TXNAPP100162',NULL),(163,163,4921,'UPI','Paid','TXNAPP100163',NULL),(164,164,4821,'UPI','Paid','TXNAPP100164',NULL),(165,165,5279,'UPI','Paid','TXNAPP100165',NULL),(166,166,5002,'UPI','Paid','TXNAPP100166',NULL),(167,167,4341,'UPI','Paid','TXNAPP100167',NULL),(168,168,5160,'UPI','Paid','TXNAPP100168',NULL),(169,169,4499,'UPI','Paid','TXNAPP100169',NULL),(170,170,5046,'UPI','Paid','TXNAPP100170',NULL),(171,171,5322,'UPI','Paid','TXNAPP100171',NULL),(172,172,4512,'UPI','Paid','TXNAPP100172',NULL),(173,173,5294,'UPI','Paid','TXNAPP100173',NULL),(174,174,4385,'UPI','Paid','TXNAPP100174',NULL),(175,175,4808,'UPI','Paid','TXNAPP100175',NULL),(176,176,5287,'UPI','Paid','TXNAPP100176',NULL),(177,177,4439,'UPI','Paid','TXNAPP100177',NULL),(178,178,4679,'UPI','Paid','TXNAPP100178',NULL),(179,179,5341,'UPI','Paid','TXNAPP100179',NULL),(180,180,4495,'UPI','Paid','TXNAPP100180',NULL),(181,181,4537,'UPI','Paid','TXNAPP100181',NULL),(182,182,4213,'UPI','Paid','TXNAPP100182',NULL),(183,183,5352,'UPI','Paid','TXNAPP100183',NULL),(184,184,5153,'UPI','Paid','TXNAPP100184',NULL),(185,185,4354,'UPI','Paid','TXNAPP100185',NULL),(186,186,4258,'UPI','Paid','TXNAPP100186',NULL),(187,187,4876,'UPI','Paid','TXNAPP100187',NULL),(188,188,5191,'UPI','Paid','TXNAPP100188',NULL),(189,189,4269,'UPI','Paid','TXNAPP100189',NULL),(190,190,4459,'UPI','Paid','TXNAPP100190',NULL),(191,191,4949,'UPI','Paid','TXNAPP100191',NULL),(192,192,5334,'UPI','Paid','TXNAPP100192',NULL),(193,193,5091,'UPI','Paid','TXNAPP100193',NULL),(194,194,4307,'UPI','Paid','TXNAPP100194',NULL),(195,195,5211,'UPI','Paid','TXNAPP100195',NULL),(196,196,4756,'UPI','Paid','TXNAPP100196',NULL),(197,197,4616,'UPI','Paid','TXNAPP100197',NULL),(198,198,4877,'UPI','Paid','TXNAPP100198',NULL),(199,199,4461,'UPI','Paid','TXNAPP100199',NULL),(200,200,5062,'UPI','Paid','TXNAPP100200',NULL),(201,201,5114,'UPI','Paid','TXNAPP100201',NULL),(202,202,4518,'UPI','Paid','TXNAPP100202',NULL),(203,203,4408,'UPI','Paid','TXNAPP100203',NULL),(204,204,4510,'UPI','Paid','TXNAPP100204',NULL),(205,205,4219,'UPI','Paid','TXNAPP100205',NULL),(206,206,4380,'UPI','Paid','TXNAPP100206',NULL),(207,207,5167,'UPI','Paid','TXNAPP100207',NULL),(208,208,4696,'UPI','Paid','TXNAPP100208',NULL),(209,209,4302,'UPI','Paid','TXNAPP100209',NULL),(210,210,4496,'UPI','Paid','TXNAPP100210',NULL),(211,211,5341,'UPI','Paid','TXNAPP100211',NULL),(212,212,4720,'UPI','Paid','TXNAPP100212',NULL),(213,213,4265,'UPI','Paid','TXNAPP100213',NULL),(214,214,4363,'UPI','Paid','TXNAPP100214',NULL),(215,215,4539,'UPI','Paid','TXNAPP100215',NULL),(216,216,4322,'UPI','Paid','TXNAPP100216',NULL),(217,217,5098,'UPI','Paid','TXNAPP100217',NULL),(218,218,4439,'UPI','Paid','TXNAPP100218',NULL),(219,219,5055,'UPI','Paid','TXNAPP100219',NULL),(220,220,5127,'UPI','Paid','TXNAPP100220',NULL),(221,221,5360,'UPI','Paid','TXNAPP100221',NULL),(222,222,4880,'UPI','Paid','TXNAPP100222',NULL),(223,223,4231,'UPI','Paid','TXNAPP100223',NULL),(224,224,4832,'UPI','Paid','TXNAPP100224',NULL),(225,225,4704,'UPI','Paid','TXNAPP100225',NULL),(226,226,4679,'UPI','Paid','TXNAPP100226',NULL),(227,227,4203,'UPI','Paid','TXNAPP100227',NULL),(228,228,4522,'UPI','Paid','TXNAPP100228',NULL),(229,229,4286,'UPI','Paid','TXNAPP100229',NULL),(230,230,5371,'UPI','Paid','TXNAPP100230',NULL),(231,231,5321,'UPI','Paid','TXNAPP100231',NULL),(232,232,4910,'UPI','Paid','TXNAPP100232',NULL),(233,233,5192,'UPI','Paid','TXNAPP100233',NULL),(234,234,5361,'UPI','Paid','TXNAPP100234',NULL),(235,235,4773,'UPI','Paid','TXNAPP100235',NULL),(236,236,4468,'UPI','Paid','TXNAPP100236',NULL),(237,237,4611,'UPI','Paid','TXNAPP100237',NULL),(238,238,4256,'UPI','Paid','TXNAPP100238',NULL),(239,239,5138,'UPI','Paid','TXNAPP100239',NULL),(240,240,4331,'UPI','Paid','TXNAPP100240',NULL),(241,241,4445,'UPI','Paid','TXNAPP100241',NULL),(242,242,4852,'UPI','Paid','TXNAPP100242',NULL),(243,243,5237,'UPI','Paid','TXNAPP100243',NULL),(244,244,4527,'UPI','Paid','TXNAPP100244',NULL),(245,245,4654,'UPI','Paid','TXNAPP100245',NULL),(246,246,4920,'UPI','Paid','TXNAPP100246',NULL),(247,247,4256,'UPI','Paid','TXNAPP100247',NULL),(248,248,5251,'UPI','Paid','TXNAPP100248',NULL),(249,249,5190,'UPI','Paid','TXNAPP100249',NULL),(250,250,4211,'UPI','Paid','TXNAPP100250',NULL),(251,251,4811,'UPI','Paid','TXNAPP100251',NULL),(252,252,4415,'UPI','Paid','TXNAPP100252',NULL),(253,253,4998,'UPI','Paid','TXNAPP100253',NULL),(254,254,4545,'UPI','Paid','TXNAPP100254',NULL),(255,255,4225,'UPI','Paid','TXNAPP100255',NULL),(256,256,4273,'UPI','Paid','TXNAPP100256',NULL),(257,257,4359,'UPI','Paid','TXNAPP100257',NULL),(258,258,4486,'UPI','Paid','TXNAPP100258',NULL),(259,259,4988,'UPI','Paid','TXNAPP100259',NULL),(260,260,5126,'UPI','Paid','TXNAPP100260',NULL),(261,261,4678,'UPI','Paid','TXNAPP100261',NULL),(262,262,4492,'UPI','Paid','TXNAPP100262',NULL),(263,263,4569,'UPI','Paid','TXNAPP100263',NULL),(264,264,4496,'UPI','Paid','TXNAPP100264',NULL),(265,265,5056,'UPI','Paid','TXNAPP100265',NULL),(266,266,4755,'UPI','Paid','TXNAPP100266',NULL),(267,267,4543,'UPI','Paid','TXNAPP100267',NULL),(268,268,4532,'UPI','Paid','TXNAPP100268',NULL),(269,269,4801,'UPI','Paid','TXNAPP100269',NULL),(270,270,5105,'UPI','Paid','TXNAPP100270',NULL),(271,271,4487,'UPI','Paid','TXNAPP100271',NULL),(272,272,5278,'UPI','Paid','TXNAPP100272',NULL),(273,273,4283,'UPI','Paid','TXNAPP100273',NULL),(274,274,5370,'UPI','Paid','TXNAPP100274',NULL),(275,275,5268,'UPI','Paid','TXNAPP100275',NULL),(276,276,4602,'UPI','Paid','TXNAPP100276',NULL),(277,277,5214,'UPI','Paid','TXNAPP100277',NULL),(278,278,4480,'UPI','Paid','TXNAPP100278',NULL),(279,279,4593,'UPI','Paid','TXNAPP100279',NULL),(280,280,4797,'UPI','Paid','TXNAPP100280',NULL),(281,281,5213,'UPI','Paid','TXNAPP100281',NULL),(282,282,5300,'UPI','Paid','TXNAPP100282',NULL),(283,283,4381,'UPI','Paid','TXNAPP100283',NULL),(284,284,4410,'UPI','Paid','TXNAPP100284',NULL),(285,285,4261,'UPI','Paid','TXNAPP100285',NULL),(286,286,4599,'UPI','Paid','TXNAPP100286',NULL),(287,287,5380,'UPI','Paid','TXNAPP100287',NULL),(288,288,5109,'UPI','Paid','TXNAPP100288',NULL),(289,289,4566,'UPI','Paid','TXNAPP100289',NULL),(290,290,5210,'UPI','Paid','TXNAPP100290',NULL),(291,291,4425,'UPI','Paid','TXNAPP100291',NULL),(292,292,4480,'UPI','Paid','TXNAPP100292',NULL),(293,293,4664,'UPI','Paid','TXNAPP100293',NULL),(294,294,5012,'UPI','Paid','TXNAPP100294',NULL),(295,295,4996,'UPI','Paid','TXNAPP100295',NULL),(296,296,5276,'UPI','Paid','TXNAPP100296',NULL),(297,297,4306,'UPI','Paid','TXNAPP100297',NULL),(298,298,4692,'UPI','Paid','TXNAPP100298',NULL),(299,299,5355,'UPI','Paid','TXNAPP100299',NULL),(300,300,5020,'UPI','Paid','TXNAPP100300',NULL),(301,301,5259,'UPI','Paid','TXNAPP100301',NULL),(302,302,4923,'UPI','Paid','TXNAPP100302',NULL),(303,303,4379,'UPI','Paid','TXNAPP100303',NULL),(304,304,5130,'UPI','Paid','TXNAPP100304',NULL),(305,305,4991,'UPI','Paid','TXNAPP100305',NULL),(306,306,5143,'UPI','Paid','TXNAPP100306',NULL),(307,307,5178,'UPI','Paid','TXNAPP100307',NULL),(308,308,4696,'UPI','Paid','TXNAPP100308',NULL),(309,309,5318,'UPI','Paid','TXNAPP100309',NULL),(310,310,4224,'UPI','Paid','TXNAPP100310',NULL),(311,311,4688,'UPI','Paid','TXNAPP100311',NULL),(312,312,4752,'UPI','Paid','TXNAPP100312',NULL),(313,313,4805,'UPI','Paid','TXNAPP100313',NULL),(314,314,5328,'UPI','Paid','TXNAPP100314',NULL),(315,315,5101,'UPI','Paid','TXNAPP100315',NULL),(316,316,5100,'UPI','Paid','TXNAPP100316',NULL),(317,317,5266,'UPI','Paid','TXNAPP100317',NULL),(318,318,4516,'UPI','Paid','TXNAPP100318',NULL),(319,319,4487,'UPI','Paid','TXNAPP100319',NULL),(320,320,4766,'UPI','Paid','TXNAPP100320',NULL),(321,321,5173,'UPI','Paid','TXNAPP100321',NULL),(322,322,4460,'UPI','Paid','TXNAPP100322',NULL),(323,323,5040,'UPI','Paid','TXNAPP100323',NULL),(324,324,5219,'UPI','Paid','TXNAPP100324',NULL),(325,325,4506,'UPI','Paid','TXNAPP100325',NULL),(326,326,4427,'UPI','Paid','TXNAPP100326',NULL),(327,327,5137,'UPI','Paid','TXNAPP100327',NULL),(328,328,4922,'UPI','Paid','TXNAPP100328',NULL),(329,329,4987,'UPI','Paid','TXNAPP100329',NULL),(330,330,5223,'UPI','Paid','TXNAPP100330',NULL),(331,331,5299,'UPI','Paid','TXNAPP100331',NULL),(332,332,5378,'UPI','Paid','TXNAPP100332',NULL),(333,333,4876,'UPI','Paid','TXNAPP100333',NULL),(334,334,4696,'UPI','Paid','TXNAPP100334',NULL),(335,335,4903,'UPI','Paid','TXNAPP100335',NULL),(336,336,5061,'UPI','Paid','TXNAPP100336',NULL),(337,337,5247,'UPI','Paid','TXNAPP100337',NULL),(338,338,5044,'UPI','Paid','TXNAPP100338',NULL),(339,339,4418,'UPI','Paid','TXNAPP100339',NULL),(340,340,4286,'UPI','Paid','TXNAPP100340',NULL),(341,341,4205,'UPI','Paid','TXNAPP100341',NULL),(342,342,4208,'UPI','Paid','TXNAPP100342',NULL),(343,343,4401,'UPI','Paid','TXNAPP100343',NULL),(344,344,4602,'UPI','Paid','TXNAPP100344',NULL),(345,345,5361,'UPI','Paid','TXNAPP100345',NULL),(346,346,5288,'UPI','Paid','TXNAPP100346',NULL),(347,347,4606,'UPI','Paid','TXNAPP100347',NULL),(348,348,4521,'UPI','Paid','TXNAPP100348',NULL),(349,349,4259,'UPI','Paid','TXNAPP100349',NULL),(350,350,5270,'UPI','Paid','TXNAPP100350',NULL),(351,351,5081,'UPI','Paid','TXNAPP100351',NULL),(352,352,4225,'UPI','Paid','TXNAPP100352',NULL),(353,353,4494,'UPI','Paid','TXNAPP100353',NULL),(354,354,4546,'UPI','Paid','TXNAPP100354',NULL),(355,355,5392,'UPI','Paid','TXNAPP100355',NULL),(356,356,4989,'UPI','Paid','TXNAPP100356',NULL),(357,357,5010,'UPI','Paid','TXNAPP100357',NULL),(358,358,5100,'UPI','Paid','TXNAPP100358',NULL),(359,359,4656,'UPI','Paid','TXNAPP100359',NULL),(360,360,4555,'UPI','Paid','TXNAPP100360',NULL),(361,361,5132,'UPI','Paid','TXNAPP100361',NULL),(362,362,4919,'UPI','Paid','TXNAPP100362',NULL),(363,363,5156,'UPI','Paid','TXNAPP100363',NULL),(364,364,4271,'UPI','Paid','TXNAPP100364',NULL),(365,365,4519,'UPI','Paid','TXNAPP100365',NULL),(366,366,4602,'UPI','Paid','TXNAPP100366',NULL),(367,367,4461,'UPI','Paid','TXNAPP100367',NULL),(368,368,4691,'UPI','Paid','TXNAPP100368',NULL),(369,369,5029,'UPI','Paid','TXNAPP100369',NULL),(370,370,4626,'UPI','Paid','TXNAPP100370',NULL),(371,371,4618,'UPI','Paid','TXNAPP100371',NULL),(372,372,4468,'UPI','Paid','TXNAPP100372',NULL),(373,373,5101,'UPI','Paid','TXNAPP100373',NULL),(374,374,4704,'UPI','Paid','TXNAPP100374',NULL),(375,375,4457,'UPI','Paid','TXNAPP100375',NULL),(376,376,5250,'UPI','Paid','TXNAPP100376',NULL),(377,377,4988,'UPI','Paid','TXNAPP100377',NULL),(378,378,4790,'UPI','Paid','TXNAPP100378',NULL),(379,379,4778,'UPI','Paid','TXNAPP100379',NULL),(380,380,5151,'UPI','Paid','TXNAPP100380',NULL),(381,381,4470,'UPI','Paid','TXNAPP100381',NULL),(382,382,4950,'UPI','Paid','TXNAPP100382',NULL),(383,383,4919,'UPI','Paid','TXNAPP100383',NULL),(384,384,5147,'UPI','Paid','TXNAPP100384',NULL),(385,385,4921,'UPI','Paid','TXNAPP100385',NULL),(386,386,4796,'UPI','Paid','TXNAPP100386',NULL),(387,387,4733,'UPI','Paid','TXNAPP100387',NULL),(388,388,4932,'UPI','Paid','TXNAPP100388',NULL),(389,389,4836,'UPI','Paid','TXNAPP100389',NULL),(390,390,5196,'UPI','Paid','TXNAPP100390',NULL),(391,391,4695,'UPI','Paid','TXNAPP100391',NULL),(392,392,4472,'UPI','Paid','TXNAPP100392',NULL),(393,393,4813,'UPI','Paid','TXNAPP100393',NULL),(394,394,5353,'UPI','Paid','TXNAPP100394',NULL),(395,395,4441,'UPI','Paid','TXNAPP100395',NULL),(396,396,4546,'UPI','Paid','TXNAPP100396',NULL),(397,397,5144,'UPI','Paid','TXNAPP100397',NULL),(398,398,4622,'UPI','Paid','TXNAPP100398',NULL),(399,399,4938,'UPI','Paid','TXNAPP100399',NULL),(400,400,4775,'UPI','Paid','TXNAPP100400',NULL),(401,401,4832,'UPI','Paid','TXNAPP100401',NULL),(402,402,4864,'UPI','Paid','TXNAPP100402',NULL),(403,403,4792,'UPI','Paid','TXNAPP100403',NULL),(404,404,4222,'UPI','Paid','TXNAPP100404',NULL),(405,405,5194,'UPI','Paid','TXNAPP100405',NULL),(406,406,5354,'UPI','Paid','TXNAPP100406',NULL),(407,407,5089,'UPI','Paid','TXNAPP100407',NULL),(408,408,4859,'UPI','Paid','TXNAPP100408',NULL),(409,409,4785,'UPI','Paid','TXNAPP100409',NULL),(410,410,4714,'UPI','Paid','TXNAPP100410',NULL),(411,411,4256,'UPI','Paid','TXNAPP100411',NULL),(412,412,4497,'UPI','Paid','TXNAPP100412',NULL),(413,413,5276,'UPI','Paid','TXNAPP100413',NULL),(414,414,4545,'UPI','Paid','TXNAPP100414',NULL),(415,415,4835,'UPI','Paid','TXNAPP100415',NULL),(416,416,4577,'UPI','Paid','TXNAPP100416',NULL),(417,417,4671,'UPI','Paid','TXNAPP100417',NULL),(418,418,4956,'UPI','Paid','TXNAPP100418',NULL),(419,419,4318,'UPI','Paid','TXNAPP100419',NULL),(420,420,5357,'UPI','Paid','TXNAPP100420',NULL),(421,421,5184,'UPI','Paid','TXNAPP100421',NULL),(422,422,4903,'UPI','Paid','TXNAPP100422',NULL),(423,423,4586,'UPI','Paid','TXNAPP100423',NULL),(424,424,4374,'UPI','Paid','TXNAPP100424',NULL),(425,425,5336,'UPI','Paid','TXNAPP100425',NULL),(426,426,5285,'UPI','Paid','TXNAPP100426',NULL),(427,427,4734,'UPI','Paid','TXNAPP100427',NULL),(428,428,4615,'UPI','Paid','TXNAPP100428',NULL),(429,429,4719,'UPI','Paid','TXNAPP100429',NULL),(430,430,4715,'UPI','Paid','TXNAPP100430',NULL),(431,431,5138,'UPI','Paid','TXNAPP100431',NULL),(432,432,4431,'UPI','Paid','TXNAPP100432',NULL),(433,433,5360,'UPI','Paid','TXNAPP100433',NULL),(434,434,4350,'UPI','Paid','TXNAPP100434',NULL),(435,435,5230,'UPI','Paid','TXNAPP100435',NULL),(436,436,4434,'UPI','Paid','TXNAPP100436',NULL),(437,437,5255,'UPI','Paid','TXNAPP100437',NULL),(438,438,5002,'UPI','Paid','TXNAPP100438',NULL),(439,439,4592,'UPI','Paid','TXNAPP100439',NULL),(440,440,4480,'UPI','Paid','TXNAPP100440',NULL),(441,441,5028,'UPI','Paid','TXNAPP100441',NULL),(442,442,4231,'UPI','Paid','TXNAPP100442',NULL),(443,443,5141,'UPI','Paid','TXNAPP100443',NULL),(444,444,5072,'UPI','Paid','TXNAPP100444',NULL),(445,445,4612,'UPI','Paid','TXNAPP100445',NULL),(446,446,4926,'UPI','Paid','TXNAPP100446',NULL),(447,447,4899,'UPI','Paid','TXNAPP100447',NULL),(448,448,4223,'UPI','Paid','TXNAPP100448',NULL),(449,449,4963,'UPI','Paid','TXNAPP100449',NULL),(450,450,4931,'UPI','Paid','TXNAPP100450',NULL),(451,451,4923,'UPI','Paid','TXNAPP100451',NULL),(452,452,4431,'UPI','Paid','TXNAPP100452',NULL),(453,453,5005,'UPI','Paid','TXNAPP100453',NULL),(454,454,5258,'UPI','Paid','TXNAPP100454',NULL),(455,455,4643,'UPI','Paid','TXNAPP100455',NULL),(456,456,4289,'UPI','Paid','TXNAPP100456',NULL),(457,457,5157,'UPI','Paid','TXNAPP100457',NULL),(458,458,4924,'UPI','Paid','TXNAPP100458',NULL),(459,459,5190,'UPI','Paid','TXNAPP100459',NULL),(460,460,5140,'UPI','Paid','TXNAPP100460',NULL),(461,461,4498,'UPI','Paid','TXNAPP100461',NULL),(462,462,4987,'UPI','Paid','TXNAPP100462',NULL),(463,463,4736,'UPI','Paid','TXNAPP100463',NULL),(464,464,5396,'UPI','Paid','TXNAPP100464',NULL),(465,465,4269,'UPI','Paid','TXNAPP100465',NULL),(466,466,4395,'UPI','Paid','TXNAPP100466',NULL),(467,467,5370,'UPI','Paid','TXNAPP100467',NULL),(468,468,4776,'UPI','Paid','TXNAPP100468',NULL),(469,469,4489,'UPI','Paid','TXNAPP100469',NULL),(470,470,4899,'UPI','Paid','TXNAPP100470',NULL),(471,471,4702,'UPI','Paid','TXNAPP100471',NULL),(472,472,5031,'UPI','Paid','TXNAPP100472',NULL),(473,473,4861,'UPI','Paid','TXNAPP100473',NULL),(474,474,5231,'UPI','Paid','TXNAPP100474',NULL),(475,475,4680,'UPI','Paid','TXNAPP100475',NULL),(476,476,4350,'UPI','Paid','TXNAPP100476',NULL),(477,477,4363,'UPI','Paid','TXNAPP100477',NULL),(478,478,4923,'UPI','Paid','TXNAPP100478',NULL),(479,479,5077,'UPI','Paid','TXNAPP100479',NULL),(480,480,5192,'UPI','Paid','TXNAPP100480',NULL),(481,481,4727,'UPI','Paid','TXNAPP100481',NULL),(482,482,4748,'UPI','Paid','TXNAPP100482',NULL),(483,483,4297,'UPI','Paid','TXNAPP100483',NULL),(484,484,4778,'UPI','Paid','TXNAPP100484',NULL),(485,485,4256,'UPI','Paid','TXNAPP100485',NULL),(486,486,4255,'UPI','Paid','TXNAPP100486',NULL),(487,487,4891,'UPI','Paid','TXNAPP100487',NULL),(488,488,4293,'UPI','Paid','TXNAPP100488',NULL),(489,489,5212,'UPI','Paid','TXNAPP100489',NULL),(490,490,5148,'UPI','Paid','TXNAPP100490',NULL),(491,491,4848,'UPI','Paid','TXNAPP100491',NULL),(492,492,4314,'UPI','Paid','TXNAPP100492',NULL),(493,493,4874,'UPI','Paid','TXNAPP100493',NULL),(494,494,4257,'UPI','Paid','TXNAPP100494',NULL),(495,495,5312,'UPI','Paid','TXNAPP100495',NULL),(496,496,4572,'UPI','Paid','TXNAPP100496',NULL),(497,497,4505,'UPI','Paid','TXNAPP100497',NULL),(498,498,4531,'UPI','Paid','TXNAPP100498',NULL),(499,499,4696,'UPI','Paid','TXNAPP100499',NULL),(500,500,4636,'UPI','Paid','TXNAPP100500',NULL),(501,501,4996,'UPI','Paid','TXNAPP100501',NULL),(502,502,4254,'UPI','Paid','TXNAPP100502',NULL),(503,503,4334,'UPI','Paid','TXNAPP100503',NULL),(504,504,4918,'UPI','Paid','TXNAPP100504',NULL),(505,505,5039,'UPI','Paid','TXNAPP100505',NULL),(506,506,4658,'UPI','Paid','TXNAPP100506',NULL),(507,507,5088,'UPI','Paid','TXNAPP100507',NULL),(508,508,4867,'UPI','Paid','TXNAPP100508',NULL),(509,509,4811,'UPI','Paid','TXNAPP100509',NULL),(510,510,5366,'UPI','Paid','TXNAPP100510',NULL),(511,511,4747,'UPI','Paid','TXNAPP100511',NULL),(512,512,4814,'UPI','Paid','TXNAPP100512',NULL),(513,513,5194,'UPI','Paid','TXNAPP100513',NULL),(514,514,4854,'UPI','Paid','TXNAPP100514',NULL),(515,515,5127,'UPI','Paid','TXNAPP100515',NULL),(516,516,4629,'UPI','Paid','TXNAPP100516',NULL),(517,517,4294,'UPI','Paid','TXNAPP100517',NULL),(518,518,4573,'UPI','Paid','TXNAPP100518',NULL),(519,519,4809,'UPI','Paid','TXNAPP100519',NULL),(520,520,4511,'UPI','Paid','TXNAPP100520',NULL),(521,521,4848,'UPI','Paid','TXNAPP100521',NULL),(522,522,5198,'UPI','Paid','TXNAPP100522',NULL),(523,523,4205,'UPI','Paid','TXNAPP100523',NULL),(524,524,4502,'UPI','Paid','TXNAPP100524',NULL),(525,525,4430,'UPI','Paid','TXNAPP100525',NULL),(526,526,4358,'UPI','Paid','TXNAPP100526',NULL),(527,527,4658,'UPI','Paid','TXNAPP100527',NULL),(528,528,4562,'UPI','Paid','TXNAPP100528',NULL),(529,529,4288,'UPI','Paid','TXNAPP100529',NULL),(530,530,5339,'UPI','Paid','TXNAPP100530',NULL),(531,531,4867,'UPI','Paid','TXNAPP100531',NULL),(532,532,5314,'UPI','Paid','TXNAPP100532',NULL),(533,533,5040,'UPI','Paid','TXNAPP100533',NULL),(534,534,4750,'UPI','Paid','TXNAPP100534',NULL),(535,535,5058,'UPI','Paid','TXNAPP100535',NULL),(536,536,4989,'UPI','Paid','TXNAPP100536',NULL),(537,537,4288,'UPI','Paid','TXNAPP100537',NULL),(538,538,5076,'UPI','Paid','TXNAPP100538',NULL),(539,539,4715,'UPI','Paid','TXNAPP100539',NULL),(540,540,5270,'UPI','Paid','TXNAPP100540',NULL),(541,541,4380,'UPI','Paid','TXNAPP100541',NULL),(542,542,5113,'UPI','Paid','TXNAPP100542',NULL),(543,543,5179,'UPI','Paid','TXNAPP100543',NULL),(544,544,5259,'UPI','Paid','TXNAPP100544',NULL),(545,545,4951,'UPI','Paid','TXNAPP100545',NULL),(546,546,4959,'UPI','Paid','TXNAPP100546',NULL),(547,547,4717,'UPI','Paid','TXNAPP100547',NULL),(548,548,5368,'UPI','Paid','TXNAPP100548',NULL),(549,549,4827,'UPI','Paid','TXNAPP100549',NULL),(550,550,4863,'UPI','Paid','TXNAPP100550',NULL),(551,551,5097,'UPI','Paid','TXNAPP100551',NULL),(552,552,4381,'UPI','Paid','TXNAPP100552',NULL),(553,553,4794,'UPI','Paid','TXNAPP100553',NULL),(554,554,4289,'UPI','Paid','TXNAPP100554',NULL),(555,555,4285,'UPI','Paid','TXNAPP100555',NULL),(556,556,5035,'UPI','Paid','TXNAPP100556',NULL),(557,557,4725,'UPI','Paid','TXNAPP100557',NULL),(558,558,5385,'UPI','Paid','TXNAPP100558',NULL),(559,559,5388,'UPI','Paid','TXNAPP100559',NULL),(560,560,4874,'UPI','Paid','TXNAPP100560',NULL),(561,561,5112,'UPI','Paid','TXNAPP100561',NULL),(562,562,5217,'UPI','Paid','TXNAPP100562',NULL),(563,563,4252,'UPI','Paid','TXNAPP100563',NULL),(564,564,5146,'UPI','Paid','TXNAPP100564',NULL),(565,565,5169,'UPI','Paid','TXNAPP100565',NULL),(566,566,5014,'UPI','Paid','TXNAPP100566',NULL),(567,567,4219,'UPI','Paid','TXNAPP100567',NULL),(568,568,5022,'UPI','Paid','TXNAPP100568',NULL),(569,569,4802,'UPI','Paid','TXNAPP100569',NULL),(570,570,5141,'UPI','Paid','TXNAPP100570',NULL),(571,571,4357,'UPI','Paid','TXNAPP100571',NULL),(572,572,5217,'UPI','Paid','TXNAPP100572',NULL),(573,573,5355,'UPI','Paid','TXNAPP100573',NULL),(574,574,4610,'UPI','Paid','TXNAPP100574',NULL),(575,575,4304,'UPI','Paid','TXNAPP100575',NULL),(576,576,4338,'UPI','Paid','TXNAPP100576',NULL),(577,577,4862,'UPI','Paid','TXNAPP100577',NULL),(578,578,5099,'UPI','Paid','TXNAPP100578',NULL),(579,579,5131,'UPI','Paid','TXNAPP100579',NULL),(580,580,4617,'UPI','Paid','TXNAPP100580',NULL),(581,581,5088,'UPI','Paid','TXNAPP100581',NULL),(582,582,4480,'UPI','Paid','TXNAPP100582',NULL),(583,583,5218,'UPI','Paid','TXNAPP100583',NULL),(584,584,5349,'UPI','Paid','TXNAPP100584',NULL),(585,585,4652,'UPI','Paid','TXNAPP100585',NULL),(586,586,4803,'UPI','Paid','TXNAPP100586',NULL),(587,587,4525,'UPI','Paid','TXNAPP100587',NULL),(588,588,4623,'UPI','Paid','TXNAPP100588',NULL),(589,589,4612,'UPI','Paid','TXNAPP100589',NULL),(590,590,5049,'UPI','Paid','TXNAPP100590',NULL),(591,591,5106,'UPI','Paid','TXNAPP100591',NULL),(592,592,4316,'UPI','Paid','TXNAPP100592',NULL),(593,593,4527,'UPI','Paid','TXNAPP100593',NULL),(594,594,4676,'UPI','Paid','TXNAPP100594',NULL),(595,595,5348,'UPI','Paid','TXNAPP100595',NULL),(596,596,4728,'UPI','Paid','TXNAPP100596',NULL),(597,597,4511,'UPI','Paid','TXNAPP100597',NULL),(598,598,4672,'UPI','Paid','TXNAPP100598',NULL),(599,599,4978,'UPI','Paid','TXNAPP100599',NULL),(600,600,5317,'UPI','Paid','TXNAPP100600',NULL),(601,601,4917,'UPI','Paid','TXNAPP100601',NULL),(602,602,4945,'UPI','Paid','TXNAPP100602',NULL),(603,603,4810,'UPI','Paid','TXNAPP100603',NULL),(604,604,5131,'UPI','Paid','TXNAPP100604',NULL),(605,605,4530,'UPI','Paid','TXNAPP100605',NULL),(606,606,4269,'UPI','Paid','TXNAPP100606',NULL),(607,607,5045,'UPI','Paid','TXNAPP100607',NULL),(608,608,5383,'UPI','Paid','TXNAPP100608',NULL),(609,609,4535,'UPI','Paid','TXNAPP100609',NULL),(610,610,4384,'UPI','Paid','TXNAPP100610',NULL),(611,611,5183,'UPI','Paid','TXNAPP100611',NULL),(612,612,4418,'UPI','Paid','TXNAPP100612',NULL),(613,613,5216,'UPI','Paid','TXNAPP100613',NULL),(614,614,4864,'UPI','Paid','TXNAPP100614',NULL),(615,615,5296,'UPI','Paid','TXNAPP100615',NULL),(616,616,4604,'UPI','Paid','TXNAPP100616',NULL),(617,617,4460,'UPI','Paid','TXNAPP100617',NULL),(618,618,5295,'UPI','Paid','TXNAPP100618',NULL),(619,619,4230,'UPI','Paid','TXNAPP100619',NULL),(620,620,5368,'UPI','Paid','TXNAPP100620',NULL),(621,621,4378,'UPI','Paid','TXNAPP100621',NULL),(622,622,4509,'UPI','Paid','TXNAPP100622',NULL),(623,623,4617,'UPI','Paid','TXNAPP100623',NULL),(624,624,4878,'UPI','Paid','TXNAPP100624',NULL),(625,625,4205,'UPI','Paid','TXNAPP100625',NULL),(626,626,5218,'UPI','Paid','TXNAPP100626',NULL),(627,627,4341,'UPI','Paid','TXNAPP100627',NULL),(628,628,4607,'UPI','Paid','TXNAPP100628',NULL),(629,629,4948,'UPI','Paid','TXNAPP100629',NULL),(630,630,4915,'UPI','Paid','TXNAPP100630',NULL),(631,631,5208,'UPI','Paid','TXNAPP100631',NULL),(632,632,4476,'UPI','Paid','TXNAPP100632',NULL),(633,633,4820,'UPI','Paid','TXNAPP100633',NULL),(634,634,4537,'UPI','Paid','TXNAPP100634',NULL),(635,635,5250,'UPI','Paid','TXNAPP100635',NULL),(636,636,5288,'UPI','Paid','TXNAPP100636',NULL),(637,637,4339,'UPI','Paid','TXNAPP100637',NULL),(638,638,4716,'UPI','Paid','TXNAPP100638',NULL),(639,639,4691,'UPI','Paid','TXNAPP100639',NULL),(640,640,4684,'UPI','Paid','TXNAPP100640',NULL),(641,641,4302,'UPI','Paid','TXNAPP100641',NULL),(642,642,4901,'UPI','Paid','TXNAPP100642',NULL),(643,643,4378,'UPI','Paid','TXNAPP100643',NULL),(644,644,4895,'UPI','Paid','TXNAPP100644',NULL),(645,645,4713,'UPI','Paid','TXNAPP100645',NULL),(646,646,5331,'UPI','Paid','TXNAPP100646',NULL),(647,647,4971,'UPI','Paid','TXNAPP100647',NULL),(648,648,4718,'UPI','Paid','TXNAPP100648',NULL),(649,649,4878,'UPI','Paid','TXNAPP100649',NULL),(650,650,4941,'UPI','Paid','TXNAPP100650',NULL),(651,651,4969,'UPI','Paid','TXNAPP100651',NULL),(652,652,4322,'UPI','Paid','TXNAPP100652',NULL),(653,653,4944,'UPI','Paid','TXNAPP100653',NULL),(654,654,4443,'UPI','Paid','TXNAPP100654',NULL),(655,655,5249,'UPI','Paid','TXNAPP100655',NULL),(656,656,5139,'UPI','Paid','TXNAPP100656',NULL),(657,657,4480,'UPI','Paid','TXNAPP100657',NULL),(658,658,4755,'UPI','Paid','TXNAPP100658',NULL),(659,659,5381,'UPI','Paid','TXNAPP100659',NULL),(660,660,4555,'UPI','Paid','TXNAPP100660',NULL),(661,661,4775,'UPI','Paid','TXNAPP100661',NULL),(662,662,5314,'UPI','Paid','TXNAPP100662',NULL),(663,663,5034,'UPI','Paid','TXNAPP100663',NULL),(664,664,4979,'UPI','Paid','TXNAPP100664',NULL),(665,665,4937,'UPI','Paid','TXNAPP100665',NULL),(666,666,4531,'UPI','Paid','TXNAPP100666',NULL),(667,667,4298,'UPI','Paid','TXNAPP100667',NULL),(668,668,4486,'UPI','Paid','TXNAPP100668',NULL),(669,669,4326,'UPI','Paid','TXNAPP100669',NULL),(670,670,4549,'UPI','Paid','TXNAPP100670',NULL),(671,671,4809,'UPI','Paid','TXNAPP100671',NULL),(672,672,4937,'UPI','Paid','TXNAPP100672',NULL),(673,673,4833,'UPI','Paid','TXNAPP100673',NULL),(674,674,4857,'UPI','Paid','TXNAPP100674',NULL),(675,675,4732,'UPI','Paid','TXNAPP100675',NULL),(676,676,5167,'UPI','Paid','TXNAPP100676',NULL),(677,677,5122,'UPI','Paid','TXNAPP100677',NULL),(678,678,5027,'UPI','Paid','TXNAPP100678',NULL),(679,679,4899,'UPI','Paid','TXNAPP100679',NULL),(680,680,4889,'UPI','Paid','TXNAPP100680',NULL),(681,681,4493,'UPI','Paid','TXNAPP100681',NULL),(682,682,4791,'UPI','Paid','TXNAPP100682',NULL),(683,683,4335,'UPI','Paid','TXNAPP100683',NULL),(684,684,4206,'UPI','Paid','TXNAPP100684',NULL),(685,685,5383,'UPI','Paid','TXNAPP100685',NULL),(686,686,4760,'UPI','Paid','TXNAPP100686',NULL),(687,687,4471,'UPI','Paid','TXNAPP100687',NULL),(688,688,4688,'UPI','Paid','TXNAPP100688',NULL),(689,689,4268,'UPI','Paid','TXNAPP100689',NULL),(690,690,4980,'UPI','Paid','TXNAPP100690',NULL),(691,691,4987,'UPI','Paid','TXNAPP100691',NULL),(692,692,4337,'UPI','Paid','TXNAPP100692',NULL),(693,693,5242,'UPI','Paid','TXNAPP100693',NULL),(694,694,4658,'UPI','Paid','TXNAPP100694',NULL),(695,695,5365,'UPI','Paid','TXNAPP100695',NULL),(696,696,4936,'UPI','Paid','TXNAPP100696',NULL),(697,697,4449,'UPI','Paid','TXNAPP100697',NULL),(698,698,4207,'UPI','Paid','TXNAPP100698',NULL),(699,699,5378,'UPI','Paid','TXNAPP100699',NULL),(700,700,5131,'UPI','Paid','TXNAPP100700',NULL),(701,701,4429,'UPI','Paid','TXNAPP100701',NULL),(702,702,4597,'UPI','Paid','TXNAPP100702',NULL),(703,703,4233,'UPI','Paid','TXNAPP100703',NULL),(704,704,4602,'UPI','Paid','TXNAPP100704',NULL),(705,705,4806,'UPI','Paid','TXNAPP100705',NULL),(706,706,4232,'UPI','Paid','TXNAPP100706',NULL),(707,707,4226,'UPI','Paid','TXNAPP100707',NULL),(708,708,5301,'UPI','Paid','TXNAPP100708',NULL),(709,709,4535,'UPI','Paid','TXNAPP100709',NULL),(710,710,4926,'UPI','Paid','TXNAPP100710',NULL),(711,711,4558,'UPI','Paid','TXNAPP100711',NULL),(712,712,4260,'UPI','Paid','TXNAPP100712',NULL),(713,713,4409,'UPI','Paid','TXNAPP100713',NULL),(714,714,4945,'UPI','Paid','TXNAPP100714',NULL),(715,715,4369,'UPI','Paid','TXNAPP100715',NULL),(716,716,5175,'UPI','Paid','TXNAPP100716',NULL),(717,717,4422,'UPI','Paid','TXNAPP100717',NULL),(718,718,4996,'UPI','Paid','TXNAPP100718',NULL),(719,719,4243,'UPI','Paid','TXNAPP100719',NULL),(720,720,4769,'UPI','Paid','TXNAPP100720',NULL),(721,721,5094,'UPI','Paid','TXNAPP100721',NULL),(722,722,4529,'UPI','Paid','TXNAPP100722',NULL),(723,723,4474,'UPI','Paid','TXNAPP100723',NULL),(724,724,5398,'UPI','Paid','TXNAPP100724',NULL),(725,725,4376,'UPI','Paid','TXNAPP100725',NULL);
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `terminals`
--

DROP TABLE IF EXISTS `terminals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `terminals` (
  `terminal_id` int NOT NULL AUTO_INCREMENT,
  `airport_id` int NOT NULL,
  `terminal_code` varchar(8) NOT NULL,
  `terminal_name` varchar(80) NOT NULL,
  PRIMARY KEY (`terminal_id`),
  UNIQUE KEY `airport_id` (`airport_id`,`terminal_code`),
  CONSTRAINT `terminals_ibfk_1` FOREIGN KEY (`airport_id`) REFERENCES `airports` (`airport_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `terminals`
--

LOCK TABLES `terminals` WRITE;
/*!40000 ALTER TABLE `terminals` DISABLE KEYS */;
INSERT INTO `terminals` VALUES (1,1,'T1','T1 Main'),(2,2,'T1','T2 Main'),(3,3,'T1','T3 Main'),(4,4,'T1','T4 Main'),(5,5,'T1','T5 Main');
/*!40000 ALTER TABLE `terminals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_booking_list`
--

DROP TABLE IF EXISTS `v_booking_list`;
/*!50001 DROP VIEW IF EXISTS `v_booking_list`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_booking_list` AS SELECT 
 1 AS `booking_id`,
 1 AS `passenger_id`,
 1 AS `first_name`,
 1 AS `last_name`,
 1 AS `flight_number`,
 1 AS `scheduled_departure`,
 1 AS `scheduled_arrival`,
 1 AS `from_airport`,
 1 AS `to_airport`,
 1 AS `gate_number`,
 1 AS `seat_number`,
 1 AS `travel_class`,
 1 AS `price`,
 1 AS `booking_status`,
 1 AS `pay_status`,
 1 AS `bags`,
 1 AS `bag_kg`,
 1 AS `fee`,
 1 AS `boarding`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_departure_board`
--

DROP TABLE IF EXISTS `v_departure_board`;
/*!50001 DROP VIEW IF EXISTS `v_departure_board`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_departure_board` AS SELECT 
 1 AS `departure_id`,
 1 AS `flight_number`,
 1 AS `airline_name`,
 1 AS `scheduled_departure`,
 1 AS `scheduled_arrival`,
 1 AS `gate_number`,
 1 AS `departure_status`,
 1 AS `sold`,
 1 AS `capacity`,
 1 AS `model`,
 1 AS `from_airport`,
 1 AS `to_airport`,
 1 AS `from_city`,
 1 AS `to_city`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_departure_detail`
--

DROP TABLE IF EXISTS `v_departure_detail`;
/*!50001 DROP VIEW IF EXISTS `v_departure_detail`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_departure_detail` AS SELECT 
 1 AS `departure_id`,
 1 AS `flight_id`,
 1 AS `flight_number`,
 1 AS `airline_name`,
 1 AS `scheduled_departure`,
 1 AS `scheduled_arrival`,
 1 AS `departure_status`,
 1 AS `gate_number`,
 1 AS `capacity`,
 1 AS `model`,
 1 AS `from_airport`,
 1 AS `to_airport`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_flight_list`
--

DROP TABLE IF EXISTS `v_flight_list`;
/*!50001 DROP VIEW IF EXISTS `v_flight_list`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_flight_list` AS SELECT 
 1 AS `flight_id`,
 1 AS `flight_number`,
 1 AS `airline_id`,
 1 AS `departure_airport_id`,
 1 AS `arrival_airport_id`,
 1 AS `sched_departure`,
 1 AS `sched_arrival`,
 1 AS `flight_status`,
 1 AS `airline_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_manifest`
--

DROP TABLE IF EXISTS `v_manifest`;
/*!50001 DROP VIEW IF EXISTS `v_manifest`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_manifest` AS SELECT 
 1 AS `booking_id`,
 1 AS `seat_number`,
 1 AS `travel_class`,
 1 AS `price`,
 1 AS `booking_status`,
 1 AS `passenger_id`,
 1 AS `first_name`,
 1 AS `last_name`,
 1 AS `pay_status`,
 1 AS `boarding`,
 1 AS `bags`,
 1 AS `bag_kg`,
 1 AS `fee`,
 1 AS `departure_id`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'skyroute_app'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_make_booking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_make_booking`(
  IN p_passenger_id INT,
  IN p_departure_id INT,
  IN p_seat VARCHAR(8),
  IN p_class VARCHAR(24),
  IN p_price DOUBLE,
  OUT p_booking_id INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  DELETE FROM Bookings
   WHERE departure_id = p_departure_id
     AND seat_number = p_seat
     AND booking_status = 'Cancelled';
  INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
  VALUES (p_passenger_id, p_departure_id, p_seat, p_class, p_price);
  SET p_booking_id = LAST_INSERT_ID();
  INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference)
  VALUES (p_booking_id, p_price, 'UPI', 'Pending', CONCAT('TXNAPP', 100000 + p_booking_id));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `skyroute_db`
--

USE `skyroute_db`;

--
-- Current Database: `skyroute_app`
--

USE `skyroute_app`;

--
-- Final view structure for view `v_booking_list`
--

/*!50001 DROP VIEW IF EXISTS `v_booking_list`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_booking_list` AS select `b`.`booking_id` AS `booking_id`,`b`.`passenger_id` AS `passenger_id`,`p`.`first_name` AS `first_name`,`p`.`last_name` AS `last_name`,`f`.`flight_number` AS `flight_number`,`d`.`scheduled_departure` AS `scheduled_departure`,`d`.`scheduled_arrival` AS `scheduled_arrival`,`dep`.`iata_code` AS `from_airport`,`arr`.`iata_code` AS `to_airport`,`g`.`gate_number` AS `gate_number`,`b`.`seat_number` AS `seat_number`,`b`.`travel_class` AS `travel_class`,`b`.`price` AS `price`,`b`.`booking_status` AS `booking_status`,`pay`.`pay_status` AS `pay_status`,(select count(0) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)) AS `bags`,coalesce((select sum(`bg`.`weight_kg`) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)),0) AS `bag_kg`,coalesce((select round((sum(greatest((`bg`.`weight_kg` - 20),0)) * 500),2) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)),0) AS `fee`,(select `ci`.`boarding_status` from `check_ins` `ci` where (`ci`.`booking_id` = `b`.`booking_id`)) AS `boarding` from (((((((`bookings` `b` join `passengers` `p` on((`b`.`passenger_id` = `p`.`passenger_id`))) join `departures` `d` on((`b`.`departure_id` = `d`.`departure_id`))) join `flights` `f` on((`d`.`flight_id` = `f`.`flight_id`))) join `airports` `dep` on((`f`.`departure_airport_id` = `dep`.`airport_id`))) join `airports` `arr` on((`f`.`arrival_airport_id` = `arr`.`airport_id`))) left join `gates` `g` on((`d`.`gate_id` = `g`.`gate_id`))) left join `payments` `pay` on((`b`.`booking_id` = `pay`.`booking_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_departure_board`
--

/*!50001 DROP VIEW IF EXISTS `v_departure_board`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_departure_board` AS select `d`.`departure_id` AS `departure_id`,`f`.`flight_number` AS `flight_number`,`al`.`airline_name` AS `airline_name`,`d`.`scheduled_departure` AS `scheduled_departure`,`d`.`scheduled_arrival` AS `scheduled_arrival`,`g`.`gate_number` AS `gate_number`,`d`.`departure_status` AS `departure_status`,(select count(0) from `bookings` `b` where ((`b`.`departure_id` = `d`.`departure_id`) and (`b`.`booking_status` <> 'Cancelled'))) AS `sold`,`ac`.`capacity` AS `capacity`,`ac`.`model` AS `model`,`dep`.`iata_code` AS `from_airport`,`arr`.`iata_code` AS `to_airport`,`dep`.`city` AS `from_city`,`arr`.`city` AS `to_city` from ((((((`departures` `d` join `flights` `f` on((`d`.`flight_id` = `f`.`flight_id`))) join `airlines` `al` on((`f`.`airline_id` = `al`.`airline_id`))) join `airports` `dep` on((`f`.`departure_airport_id` = `dep`.`airport_id`))) join `airports` `arr` on((`f`.`arrival_airport_id` = `arr`.`airport_id`))) left join `aircraft` `ac` on((`d`.`aircraft_id` = `ac`.`aircraft_id`))) left join `gates` `g` on((`d`.`gate_id` = `g`.`gate_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_departure_detail`
--

/*!50001 DROP VIEW IF EXISTS `v_departure_detail`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_departure_detail` AS select `d`.`departure_id` AS `departure_id`,`d`.`flight_id` AS `flight_id`,`f`.`flight_number` AS `flight_number`,`al`.`airline_name` AS `airline_name`,`d`.`scheduled_departure` AS `scheduled_departure`,`d`.`scheduled_arrival` AS `scheduled_arrival`,`d`.`departure_status` AS `departure_status`,`g`.`gate_number` AS `gate_number`,`ac`.`capacity` AS `capacity`,`ac`.`model` AS `model`,`dep`.`iata_code` AS `from_airport`,`arr`.`iata_code` AS `to_airport` from ((((((`departures` `d` join `flights` `f` on((`d`.`flight_id` = `f`.`flight_id`))) join `airlines` `al` on((`f`.`airline_id` = `al`.`airline_id`))) join `airports` `dep` on((`f`.`departure_airport_id` = `dep`.`airport_id`))) join `airports` `arr` on((`f`.`arrival_airport_id` = `arr`.`airport_id`))) left join `aircraft` `ac` on((`d`.`aircraft_id` = `ac`.`aircraft_id`))) left join `gates` `g` on((`d`.`gate_id` = `g`.`gate_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_flight_list`
--

/*!50001 DROP VIEW IF EXISTS `v_flight_list`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_flight_list` AS select `f`.`flight_id` AS `flight_id`,`f`.`flight_number` AS `flight_number`,`f`.`airline_id` AS `airline_id`,`f`.`departure_airport_id` AS `departure_airport_id`,`f`.`arrival_airport_id` AS `arrival_airport_id`,`f`.`sched_departure` AS `sched_departure`,`f`.`sched_arrival` AS `sched_arrival`,`f`.`flight_status` AS `flight_status`,`al`.`airline_name` AS `airline_name` from (`flights` `f` join `airlines` `al` on((`f`.`airline_id` = `al`.`airline_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_manifest`
--

/*!50001 DROP VIEW IF EXISTS `v_manifest`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_manifest` AS select `b`.`booking_id` AS `booking_id`,`b`.`seat_number` AS `seat_number`,`b`.`travel_class` AS `travel_class`,`b`.`price` AS `price`,`b`.`booking_status` AS `booking_status`,`b`.`passenger_id` AS `passenger_id`,`p`.`first_name` AS `first_name`,`p`.`last_name` AS `last_name`,`pay`.`pay_status` AS `pay_status`,(select `ci`.`boarding_status` from `check_ins` `ci` where (`ci`.`booking_id` = `b`.`booking_id`)) AS `boarding`,(select count(0) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)) AS `bags`,coalesce((select sum(`bg`.`weight_kg`) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)),0) AS `bag_kg`,coalesce((select round((sum(greatest((`bg`.`weight_kg` - 20),0)) * 500),2) from `baggage` `bg` where (`bg`.`booking_id` = `b`.`booking_id`)),0) AS `fee`,`b`.`departure_id` AS `departure_id` from ((`bookings` `b` join `passengers` `p` on((`b`.`passenger_id` = `p`.`passenger_id`))) left join `payments` `pay` on((`b`.`booking_id` = `pay`.`booking_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-21 20:05:05

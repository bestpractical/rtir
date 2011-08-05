-- MySQL dump 10.13  Distrib 5.1.56, for apple-darwin10.7.0 (x86_64)
--
-- Host: localhost    Database: rt4test
-- ------------------------------------------------------
-- Server version	5.1.56-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ACL`
--

DROP TABLE IF EXISTS `ACL`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ACL` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `PrincipalType` varchar(25) CHARACTER SET ascii NOT NULL,
  `PrincipalId` int(11) NOT NULL,
  `RightName` varchar(25) CHARACTER SET ascii NOT NULL,
  `ObjectType` varchar(25) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ACL1` (`RightName`,`ObjectType`,`ObjectId`,`PrincipalType`,`PrincipalId`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ACL`
--

LOCK TABLES `ACL` WRITE;
/*!40000 ALTER TABLE `ACL` DISABLE KEYS */;
INSERT INTO `ACL` VALUES (1,'Group',2,'SuperUser','RT::System',1,0,NULL,0,NULL),(2,'Group',7,'OwnTicket','RT::System',1,0,NULL,0,NULL),(3,'Group',13,'SuperUser','RT::System',1,0,NULL,0,NULL),(4,'Group',4,'ShowApprovalsTab','RT::System',1,0,NULL,0,NULL),(5,'Owner',28,'ModifyTicket','RT::Queue',3,0,NULL,0,NULL),(6,'Group',22,'ShowTemplate','RT::Queue',3,0,NULL,0,NULL),(7,'Group',22,'CreateTicket','RT::Queue',3,0,NULL,0,NULL),(8,'Group',22,'OwnTicket','RT::Queue',3,0,NULL,0,NULL),(9,'Group',22,'CommentOnTicket','RT::Queue',3,0,NULL,0,NULL),(10,'Group',22,'SeeQueue','RT::Queue',3,0,NULL,0,NULL),(11,'Group',22,'ShowTicket','RT::Queue',3,0,NULL,0,NULL),(12,'Group',22,'ShowTicketComments','RT::Queue',3,0,NULL,0,NULL),(13,'Group',22,'StealTicket','RT::Queue',3,0,NULL,0,NULL),(14,'Group',22,'TakeTicket','RT::Queue',3,0,NULL,0,NULL),(15,'Group',22,'Watch','RT::Queue',3,0,NULL,0,NULL),(16,'Owner',32,'ModifyTicket','RT::Queue',4,0,NULL,0,NULL),(17,'Group',22,'ShowTemplate','RT::Queue',4,0,NULL,0,NULL),(18,'Group',22,'CreateTicket','RT::Queue',4,0,NULL,0,NULL),(19,'Group',22,'OwnTicket','RT::Queue',4,0,NULL,0,NULL),(20,'Group',22,'CommentOnTicket','RT::Queue',4,0,NULL,0,NULL),(21,'Group',22,'SeeQueue','RT::Queue',4,0,NULL,0,NULL),(22,'Group',22,'ShowTicket','RT::Queue',4,0,NULL,0,NULL),(23,'Group',22,'ShowTicketComments','RT::Queue',4,0,NULL,0,NULL),(24,'Group',22,'StealTicket','RT::Queue',4,0,NULL,0,NULL),(25,'Group',22,'TakeTicket','RT::Queue',4,0,NULL,0,NULL),(26,'Group',22,'Watch','RT::Queue',4,0,NULL,0,NULL),(27,'Owner',36,'ModifyTicket','RT::Queue',5,0,NULL,0,NULL),(28,'Group',22,'ShowTemplate','RT::Queue',5,0,NULL,0,NULL),(29,'Group',22,'CreateTicket','RT::Queue',5,0,NULL,0,NULL),(30,'Group',22,'OwnTicket','RT::Queue',5,0,NULL,0,NULL),(31,'Group',22,'CommentOnTicket','RT::Queue',5,0,NULL,0,NULL),(32,'Group',22,'SeeQueue','RT::Queue',5,0,NULL,0,NULL),(33,'Group',22,'ShowTicket','RT::Queue',5,0,NULL,0,NULL),(34,'Group',22,'ShowTicketComments','RT::Queue',5,0,NULL,0,NULL),(35,'Group',22,'StealTicket','RT::Queue',5,0,NULL,0,NULL),(36,'Group',22,'TakeTicket','RT::Queue',5,0,NULL,0,NULL),(37,'Group',22,'Watch','RT::Queue',5,0,NULL,0,NULL),(38,'Owner',40,'ModifyTicket','RT::Queue',6,0,NULL,0,NULL),(39,'Group',22,'ShowTemplate','RT::Queue',6,0,NULL,0,NULL),(40,'Group',22,'CreateTicket','RT::Queue',6,0,NULL,0,NULL),(41,'Group',22,'OwnTicket','RT::Queue',6,0,NULL,0,NULL),(42,'Group',22,'CommentOnTicket','RT::Queue',6,0,NULL,0,NULL),(43,'Group',22,'SeeQueue','RT::Queue',6,0,NULL,0,NULL),(44,'Group',22,'ShowTicket','RT::Queue',6,0,NULL,0,NULL),(45,'Group',22,'ShowTicketComments','RT::Queue',6,0,NULL,0,NULL),(46,'Group',22,'StealTicket','RT::Queue',6,0,NULL,0,NULL),(47,'Group',22,'TakeTicket','RT::Queue',6,0,NULL,0,NULL),(48,'Group',22,'Watch','RT::Queue',6,0,NULL,0,NULL),(49,'Group',3,'CreateTicket','RT::Queue',4,0,NULL,0,NULL),(50,'Group',3,'ReplyToTicket','RT::Queue',4,0,NULL,0,NULL),(51,'Group',3,'ReplyToTicket','RT::Queue',5,0,NULL,0,NULL),(52,'Group',3,'ReplyToTicket','RT::Queue',6,0,NULL,0,NULL),(53,'Group',22,'ModifySelf','RT::System',1,0,NULL,0,NULL),(54,'Group',22,'CreateSavedSearch','RT::System',1,0,NULL,0,NULL),(55,'Group',22,'EditSavedSearches','RT::System',1,0,NULL,0,NULL),(56,'Group',22,'LoadSavedSearch','RT::System',1,0,NULL,0,NULL),(57,'Group',22,'ShowSavedSearches','RT::System',1,0,NULL,0,NULL),(58,'Group',22,'SeeCustomField','RT::CustomField',1,0,NULL,0,NULL),(59,'Group',22,'ModifyCustomField','RT::CustomField',1,0,NULL,0,NULL),(60,'Group',22,'SeeCustomField','RT::CustomField',2,0,NULL,0,NULL),(61,'Group',22,'ModifyCustomField','RT::CustomField',2,0,NULL,0,NULL),(62,'Group',22,'SeeCustomField','RT::CustomField',3,0,NULL,0,NULL),(63,'Group',22,'ModifyCustomField','RT::CustomField',3,0,NULL,0,NULL),(64,'Group',22,'SeeCustomField','RT::CustomField',4,0,NULL,0,NULL),(65,'Group',22,'ModifyCustomField','RT::CustomField',4,0,NULL,0,NULL),(66,'Group',22,'SeeCustomField','RT::CustomField',5,0,NULL,0,NULL),(67,'Group',22,'ModifyCustomField','RT::CustomField',5,0,NULL,0,NULL),(68,'Group',22,'SeeCustomField','RT::CustomField',6,0,NULL,0,NULL),(69,'Group',22,'ModifyCustomField','RT::CustomField',6,0,NULL,0,NULL),(70,'Group',22,'SeeCustomField','RT::CustomField',7,0,NULL,0,NULL),(71,'Group',22,'ModifyCustomField','RT::CustomField',7,0,NULL,0,NULL),(72,'Group',22,'SeeCustomField','RT::CustomField',8,0,NULL,0,NULL),(73,'Group',22,'ModifyCustomField','RT::CustomField',8,0,NULL,0,NULL),(74,'Group',22,'SeeCustomField','RT::CustomField',9,0,NULL,0,NULL),(75,'Group',22,'ModifyCustomField','RT::CustomField',9,0,NULL,0,NULL),(76,'Group',22,'SeeCustomField','RT::CustomField',10,0,NULL,0,NULL),(77,'Group',22,'ModifyCustomField','RT::CustomField',10,0,NULL,0,NULL),(78,'Group',22,'SeeCustomField','RT::CustomField',11,0,NULL,0,NULL),(79,'Group',22,'ModifyCustomField','RT::CustomField',11,0,NULL,0,NULL),(80,'Group',22,'SeeCustomField','RT::CustomField',12,0,NULL,0,NULL),(81,'Group',22,'ModifyCustomField','RT::CustomField',12,0,NULL,0,NULL),(82,'Group',22,'SeeCustomField','RT::CustomField',13,0,NULL,0,NULL),(83,'Group',22,'ModifyCustomField','RT::CustomField',13,0,NULL,0,NULL),(84,'Group',22,'SeeCustomField','RT::CustomField',14,0,NULL,0,NULL),(85,'Group',22,'ModifyCustomField','RT::CustomField',14,0,NULL,0,NULL),(86,'Group',22,'SeeCustomField','RT::CustomField',15,0,NULL,0,NULL),(87,'Group',22,'ModifyCustomField','RT::CustomField',15,0,NULL,0,NULL),(88,'Group',22,'SeeCustomField','RT::CustomField',16,0,NULL,0,NULL),(89,'Group',22,'ModifyCustomField','RT::CustomField',16,0,NULL,0,NULL),(90,'Group',22,'SeeCustomField','RT::CustomField',17,0,NULL,0,NULL),(91,'Group',22,'ModifyCustomField','RT::CustomField',17,0,NULL,0,NULL),(92,'Group',22,'SeeCustomField','RT::CustomField',18,0,NULL,0,NULL),(93,'Group',22,'ModifyCustomField','RT::CustomField',18,0,NULL,0,NULL),(94,'Group',22,'SeeCustomField','RT::CustomField',19,0,NULL,0,NULL),(95,'Group',22,'ModifyCustomField','RT::CustomField',19,0,NULL,0,NULL),(96,'Group',22,'AdminClass','RT::FM::Class',1,0,NULL,0,NULL),(97,'Group',22,'AdminTopics','RT::FM::Class',1,0,NULL,0,NULL),(98,'Group',22,'CreateArticle','RT::FM::Class',1,0,NULL,0,NULL),(99,'Group',22,'ModifyArticle','RT::FM::Class',1,0,NULL,0,NULL),(100,'Group',22,'ModifyArticleTopics','RT::FM::Class',1,0,NULL,0,NULL),(101,'Group',22,'SeeClass','RT::FM::Class',1,0,NULL,0,NULL),(102,'Group',22,'ShowArticle','RT::FM::Class',1,0,NULL,0,NULL),(103,'Group',22,'ShowArticleHistory','RT::FM::Class',1,0,NULL,0,NULL),(104,'Group',22,'DeleteArticle','RT::FM::Class',1,0,NULL,0,NULL);
/*!40000 ALTER TABLE `ACL` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Articles`
--

DROP TABLE IF EXISTS `Articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Articles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Summary` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Class` int(11) NOT NULL DEFAULT '0',
  `Parent` int(11) NOT NULL DEFAULT '0',
  `URI` varchar(255) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Articles`
--

LOCK TABLES `Articles` WRITE;
/*!40000 ALTER TABLE `Articles` DISABLE KEYS */;
/*!40000 ALTER TABLE `Articles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Classes`
--

DROP TABLE IF EXISTS `Classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Disabled` int(2) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `HotList` int(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Classes`
--

LOCK TABLES `Classes` WRITE;
/*!40000 ALTER TABLE `Classes` DISABLE KEYS */;
/*!40000 ALTER TABLE `Classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CustomFieldValues`
--

DROP TABLE IF EXISTS `CustomFieldValues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CustomFieldValues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Category` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `CustomFieldValues1` (`CustomField`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomFieldValues`
--

LOCK TABLES `CustomFieldValues` WRITE;
/*!40000 ALTER TABLE `CustomFieldValues` DISABLE KEYS */;
INSERT INTO `CustomFieldValues` VALUES (1,1,'open','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(2,1,'resolved','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(3,1,'abandoned','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(4,2,'EDUNET','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(5,2,'GOVNET','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(6,3,'new','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(7,3,'open','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(8,3,'resolved','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(9,3,'rejected','',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(10,4,'open','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(11,4,'resolved','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(12,5,'pending activation','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(13,5,'active','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(14,5,'pending removal','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(15,5,'removed','',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(16,7,'successfully resolved','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(17,7,'no resolution reached','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(18,7,'no response from customer','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(19,7,'no response from other ISP','',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(20,8,'Full service','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(21,8,'Full service: out of hours','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(22,8,'Reduced service','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(23,9,'AbuseDesk','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(24,9,'IncidentCoord','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(25,10,'Spam','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(26,10,'System Compromise','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(27,10,'Query','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(28,10,'Scan','',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(29,10,'Denial of Service','',5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(30,10,'Piracy','',6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(31,11,'Email','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(32,11,'Telephone','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(33,11,'Other','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(34,12,'customer','',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(35,12,'external individual','',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(36,12,'other ISP','',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(37,12,'police','',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(38,12,'other IRT','',5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL),(39,12,'other','',6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',NULL);
/*!40000 ALTER TABLE `CustomFieldValues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CustomFields`
--

DROP TABLE IF EXISTS `CustomFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CustomFields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Type` varchar(200) CHARACTER SET ascii DEFAULT NULL,
  `MaxValues` int(11) DEFAULT NULL,
  `Pattern` text,
  `Repeated` smallint(6) NOT NULL DEFAULT '0',
  `Description` varchar(255) DEFAULT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `LookupType` varchar(255) CHARACTER SET ascii NOT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  `BasedOn` int(11) DEFAULT NULL,
  `RenderType` varchar(64) DEFAULT NULL,
  `ValuesClass` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomFields`
--

LOCK TABLES `CustomFields` WRITE;
/*!40000 ALTER TABLE `CustomFields` DISABLE KEYS */;
INSERT INTO `CustomFields` VALUES (1,'State','Select',1,'',0,'State for Incidents RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(2,'Constituency','Select',1,'',0,'Constituency for RTIR queues',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(3,'State','Select',1,'',0,'State for Incident Reports RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(4,'State','Select',1,'',0,'State for Investigations RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(5,'State','Select',1,'',0,'State for Blocks RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(6,'Description','Freeform',1,'',0,'Description for Incidents RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(7,'Resolution','Select',1,'',0,'Resolution for Incidents RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(8,'SLA','Select',1,'',0,'SLA for Incident Reports RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(9,'Function','Select',1,'',0,'Function for Incidents RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(10,'Classification','Select',1,'',0,'Classification for Incidents RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(11,'How Reported','Select',1,'',0,'How the incident was reported for Incident Reports RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(12,'Reporter Type','Select',1,'',0,'Reporter type for Incident Reports RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(13,'IP','Freeform',0,'(?-xism:(?#IP/IP-IP/CIDR)^(?:|\\s*(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))(?:\\s*-\\s*(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})))?\\s*|(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]?[0-9])\\.(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]?[0-9])(?:\\.(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]?[0-9]))?(?:\\.(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]?[0-9]))?)\\/(?:3[0-2]|[1-2]?[0-9]))$)',0,'IP address for RTIR queues',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(14,'Netmask','Freeform',1,'',0,'Network mask for Blocks RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(15,'Port','Freeform',1,'',0,'Port for Blocks RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(16,'Where Blocked','Freeform',1,'',0,'Where the block is placed for Blocks RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(17,'Customer','Select',0,'',0,'Customer for Incident Reports RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(18,'Customer','Select',1,'',0,'Customer for Investigations RTIR queue',0,'RT::Queue-RT::Ticket',1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL,NULL),(19,'Response','Text',1,'',0,'Response to be inserted into the ticket',0,'RT::FM::Class-RT::FM::Article',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24',0,NULL,NULL,NULL);
/*!40000 ALTER TABLE `CustomFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FM_Articles`
--

DROP TABLE IF EXISTS `FM_Articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FM_Articles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Summary` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Class` int(11) NOT NULL DEFAULT '0',
  `Parent` int(11) NOT NULL DEFAULT '0',
  `URI` varchar(255) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FM_Articles`
--

LOCK TABLES `FM_Articles` WRITE;
/*!40000 ALTER TABLE `FM_Articles` DISABLE KEYS */;
/*!40000 ALTER TABLE `FM_Articles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FM_Classes`
--

DROP TABLE IF EXISTS `FM_Classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FM_Classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Disabled` int(2) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `HotList` int(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FM_Classes`
--

LOCK TABLES `FM_Classes` WRITE;
/*!40000 ALTER TABLE `FM_Classes` DISABLE KEYS */;
INSERT INTO `FM_Classes` VALUES (1,'Templates','Response templates',0,0,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24',1);
/*!40000 ALTER TABLE `FM_Classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FM_ObjectTopics`
--

DROP TABLE IF EXISTS `FM_ObjectTopics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FM_ObjectTopics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Topic` int(11) NOT NULL DEFAULT '0',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FM_ObjectTopics`
--

LOCK TABLES `FM_ObjectTopics` WRITE;
/*!40000 ALTER TABLE `FM_ObjectTopics` DISABLE KEYS */;
/*!40000 ALTER TABLE `FM_ObjectTopics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FM_Topics`
--

DROP TABLE IF EXISTS `FM_Topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FM_Topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Parent` int(11) NOT NULL DEFAULT '0',
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FM_Topics`
--

LOCK TABLES `FM_Topics` WRITE;
/*!40000 ALTER TABLE `FM_Topics` DISABLE KEYS */;
/*!40000 ALTER TABLE `FM_Topics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `GroupMembers`
--

DROP TABLE IF EXISTS `GroupMembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GroupMembers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `GroupId` int(11) NOT NULL DEFAULT '0',
  `MemberId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `GroupMembers1` (`GroupId`,`MemberId`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `GroupMembers`
--

LOCK TABLES `GroupMembers` WRITE;
/*!40000 ALTER TABLE `GroupMembers` DISABLE KEYS */;
INSERT INTO `GroupMembers` VALUES (1,2,1,0,NULL,0,NULL),(2,7,6,0,NULL,0,NULL),(3,3,6,0,NULL,0,NULL),(4,5,6,0,NULL,0,NULL),(5,13,12,0,NULL,0,NULL),(6,3,12,0,NULL,0,NULL),(7,4,12,0,NULL,0,NULL),(8,42,41,0,NULL,0,NULL),(9,3,41,0,NULL,0,NULL),(10,4,41,0,NULL,0,NULL),(11,22,41,0,NULL,0,NULL),(12,44,41,0,NULL,0,NULL),(13,46,23,0,NULL,0,NULL),(14,48,41,0,NULL,0,NULL),(15,50,23,0,NULL,0,NULL),(16,52,41,0,NULL,0,NULL),(17,54,23,0,NULL,0,NULL),(18,56,12,0,NULL,0,NULL),(19,58,23,0,NULL,0,NULL),(20,60,12,0,NULL,0,NULL),(21,62,23,0,NULL,0,NULL);
/*!40000 ALTER TABLE `GroupMembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Groups`
--

DROP TABLE IF EXISTS `Groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Domain` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `Type` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `Instance` int(11) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Groups1` (`Domain`,`Instance`,`Type`,`id`),
  KEY `Groups2` (`Type`,`Instance`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Groups`
--

LOCK TABLES `Groups` WRITE;
/*!40000 ALTER TABLE `Groups` DISABLE KEYS */;
INSERT INTO `Groups` VALUES (2,'User 1','ACL equiv. for user 1','ACLEquivalence','UserEquiv',1,0,NULL,0,NULL),(3,'','Pseudogroup for internal use','SystemInternal','Everyone',0,0,NULL,0,NULL),(4,'','Pseudogroup for internal use','SystemInternal','Privileged',0,0,NULL,0,NULL),(5,'','Pseudogroup for internal use','SystemInternal','Unprivileged',0,0,NULL,0,NULL),(7,'User 6','ACL equiv. for user 6','ACLEquivalence','UserEquiv',6,0,NULL,0,NULL),(8,'','SystemRolegroup for internal use','RT::System-Role','Owner',0,0,NULL,0,NULL),(9,'','SystemRolegroup for internal use','RT::System-Role','Requestor',0,0,NULL,0,NULL),(10,'','SystemRolegroup for internal use','RT::System-Role','Cc',0,0,NULL,0,NULL),(11,'','SystemRolegroup for internal use','RT::System-Role','AdminCc',0,0,NULL,0,NULL),(13,'User 12','ACL equiv. for user 12','ACLEquivalence','UserEquiv',12,0,NULL,0,NULL),(14,NULL,NULL,'RT::Queue-Role','Cc',1,0,NULL,0,NULL),(15,NULL,NULL,'RT::Queue-Role','AdminCc',1,0,NULL,0,NULL),(16,NULL,NULL,'RT::Queue-Role','Requestor',1,0,NULL,0,NULL),(17,NULL,NULL,'RT::Queue-Role','Owner',1,0,NULL,0,NULL),(18,NULL,NULL,'RT::Queue-Role','Cc',2,0,NULL,0,NULL),(19,NULL,NULL,'RT::Queue-Role','AdminCc',2,0,NULL,0,NULL),(20,NULL,NULL,'RT::Queue-Role','Requestor',2,0,NULL,0,NULL),(21,NULL,NULL,'RT::Queue-Role','Owner',2,0,NULL,0,NULL),(22,'DutyTeam','Duty Team Members','UserDefined','Privileged',0,0,NULL,0,NULL),(23,'DutyTeam EDUNET','Duty Team responsible for EDUNET constituency','UserDefined','Privileged',0,0,NULL,0,NULL),(24,'DutyTeam GOVNET','Duty Team responsible for GOVNET constituency','UserDefined','Privileged',0,0,NULL,0,NULL),(25,NULL,NULL,'RT::Queue-Role','Cc',3,0,NULL,0,NULL),(26,NULL,NULL,'RT::Queue-Role','AdminCc',3,0,NULL,0,NULL),(27,NULL,NULL,'RT::Queue-Role','Requestor',3,0,NULL,0,NULL),(28,NULL,NULL,'RT::Queue-Role','Owner',3,0,NULL,0,NULL),(29,NULL,NULL,'RT::Queue-Role','Cc',4,0,NULL,0,NULL),(30,NULL,NULL,'RT::Queue-Role','AdminCc',4,0,NULL,0,NULL),(31,NULL,NULL,'RT::Queue-Role','Requestor',4,0,NULL,0,NULL),(32,NULL,NULL,'RT::Queue-Role','Owner',4,0,NULL,0,NULL),(33,NULL,NULL,'RT::Queue-Role','Cc',5,0,NULL,0,NULL),(34,NULL,NULL,'RT::Queue-Role','AdminCc',5,0,NULL,0,NULL),(35,NULL,NULL,'RT::Queue-Role','Requestor',5,0,NULL,0,NULL),(36,NULL,NULL,'RT::Queue-Role','Owner',5,0,NULL,0,NULL),(37,NULL,NULL,'RT::Queue-Role','Cc',6,0,NULL,0,NULL),(38,NULL,NULL,'RT::Queue-Role','AdminCc',6,0,NULL,0,NULL),(39,NULL,NULL,'RT::Queue-Role','Requestor',6,0,NULL,0,NULL),(40,NULL,NULL,'RT::Queue-Role','Owner',6,0,NULL,0,NULL),(42,'User 41','ACL equiv. for user 41','ACLEquivalence','UserEquiv',41,0,NULL,0,NULL),(43,NULL,NULL,'RT::Ticket-Role','Requestor',1,0,NULL,0,NULL),(44,NULL,NULL,'RT::Ticket-Role','Owner',1,0,NULL,0,NULL),(45,NULL,NULL,'RT::Ticket-Role','Cc',1,0,NULL,0,NULL),(46,NULL,NULL,'RT::Ticket-Role','AdminCc',1,0,NULL,0,NULL),(47,NULL,NULL,'RT::Ticket-Role','Requestor',2,0,NULL,0,NULL),(48,NULL,NULL,'RT::Ticket-Role','Owner',2,0,NULL,0,NULL),(49,NULL,NULL,'RT::Ticket-Role','Cc',2,0,NULL,0,NULL),(50,NULL,NULL,'RT::Ticket-Role','AdminCc',2,0,NULL,0,NULL),(51,NULL,NULL,'RT::Ticket-Role','Requestor',3,0,NULL,0,NULL),(52,NULL,NULL,'RT::Ticket-Role','Owner',3,0,NULL,0,NULL),(53,NULL,NULL,'RT::Ticket-Role','Cc',3,0,NULL,0,NULL),(54,NULL,NULL,'RT::Ticket-Role','AdminCc',3,0,NULL,0,NULL),(55,NULL,NULL,'RT::Ticket-Role','Requestor',4,0,NULL,0,NULL),(56,NULL,NULL,'RT::Ticket-Role','Owner',4,0,NULL,0,NULL),(57,NULL,NULL,'RT::Ticket-Role','Cc',4,0,NULL,0,NULL),(58,NULL,NULL,'RT::Ticket-Role','AdminCc',4,0,NULL,0,NULL),(59,NULL,NULL,'RT::Ticket-Role','Requestor',5,0,NULL,0,NULL),(60,NULL,NULL,'RT::Ticket-Role','Owner',5,0,NULL,0,NULL),(61,NULL,NULL,'RT::Ticket-Role','Cc',5,0,NULL,0,NULL),(62,NULL,NULL,'RT::Ticket-Role','AdminCc',5,0,NULL,0,NULL);
/*!40000 ALTER TABLE `Groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectClasses`
--

DROP TABLE IF EXISTS `ObjectClasses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectClasses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Class` int(11) NOT NULL DEFAULT '0',
  `ObjectType` varchar(255) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectClasses`
--

LOCK TABLES `ObjectClasses` WRITE;
/*!40000 ALTER TABLE `ObjectClasses` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectClasses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectCustomFields`
--

DROP TABLE IF EXISTS `ObjectCustomFields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectCustomFields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `ObjectId` int(11) NOT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectCustomFields`
--

LOCK TABLES `ObjectCustomFields` WRITE;
/*!40000 ALTER TABLE `ObjectCustomFields` DISABLE KEYS */;
INSERT INTO `ObjectCustomFields` VALUES (1,1,3,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(2,2,3,1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(3,2,4,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(4,2,5,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(5,2,6,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(6,3,4,1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(7,4,5,1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(8,5,6,1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(9,6,3,2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(10,7,3,3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(11,8,4,2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(12,9,3,4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(13,10,3,5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(14,11,4,3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(15,12,4,4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(16,13,3,6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(17,13,4,5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(18,13,5,2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(19,13,6,2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(20,14,6,3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(21,15,6,4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(22,16,6,5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(23,17,4,6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(24,18,5,3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(25,19,1,0,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `ObjectCustomFields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ObjectTopics`
--

DROP TABLE IF EXISTS `ObjectTopics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ObjectTopics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Topic` int(11) NOT NULL DEFAULT '0',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ObjectTopics`
--

LOCK TABLES `ObjectTopics` WRITE;
/*!40000 ALTER TABLE `ObjectTopics` DISABLE KEYS */;
/*!40000 ALTER TABLE `ObjectTopics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Queues`
--

DROP TABLE IF EXISTS `Queues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Queues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `CorrespondAddress` varchar(120) CHARACTER SET ascii DEFAULT NULL,
  `CommentAddress` varchar(120) CHARACTER SET ascii DEFAULT NULL,
  `InitialPriority` int(11) NOT NULL DEFAULT '0',
  `FinalPriority` int(11) NOT NULL DEFAULT '0',
  `DefaultDueIn` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  `SubjectTag` varchar(120) DEFAULT NULL,
  `Lifecycle` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Queues1` (`Name`),
  KEY `Queues2` (`Disabled`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Queues`
--

LOCK TABLES `Queues` WRITE;
/*!40000 ALTER TABLE `Queues` DISABLE KEYS */;
INSERT INTO `Queues` VALUES (1,'General','The default queue','','',0,0,0,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19',0,NULL,NULL),(2,'___Approvals','A system-internal queue for the approvals system','','',0,0,0,1,'2011-08-03 19:34:19',1,'2011-08-03 21:04:13',2,NULL,'approvals'),(3,'Incidents','','','',50,0,0,1,'2011-08-03 19:34:21',1,'2011-08-03 19:34:22',0,NULL,NULL),(4,'Incident Reports','','','',0,0,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL),(5,'Investigations','','','',0,0,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL),(6,'Blocks','','','',0,0,0,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22',0,NULL,NULL);
/*!40000 ALTER TABLE `Queues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ScripActions`
--

DROP TABLE IF EXISTS `ScripActions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ScripActions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `ExecModule` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Argument` varbinary(255) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ScripActions`
--

LOCK TABLES `ScripActions` WRITE;
/*!40000 ALTER TABLE `ScripActions` DISABLE KEYS */;
INSERT INTO `ScripActions` VALUES (1,'Autoreply To Requestors','Always sends a message to the requestors independent of message sender','Autoreply','Requestor',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(2,'Notify Requestors','Sends a message to the requestors','Notify','Requestor',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(3,'Notify Owner as Comment','Sends mail to the owner','NotifyAsComment','Owner',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(4,'Notify Owner','Sends mail to the owner','Notify','Owner',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(5,'Notify Ccs as Comment','Sends mail to the Ccs as a comment','NotifyAsComment','Cc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(6,'Notify Ccs','Sends mail to the Ccs','Notify','Cc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(7,'Notify AdminCcs as Comment','Sends mail to the administrative Ccs as a comment','NotifyAsComment','AdminCc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(8,'Notify AdminCcs','Sends mail to the administrative Ccs','Notify','AdminCc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(9,'Notify Requestors and Ccs as Comment','Send mail to requestors and Ccs as a comment','NotifyAsComment','Requestor,Cc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(10,'Notify Requestors and Ccs','Send mail to requestors and Ccs','Notify','Requestor,Cc',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(11,'Notify Owner, Requestors, Ccs and AdminCcs as Comment','Send mail to owner and all watchers as a \"comment\"','NotifyAsComment','All',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(12,'Notify Owner, Requestors, Ccs and AdminCcs','Send mail to owner and all watchers','Notify','All',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(13,'Notify Other Recipients as Comment','Sends mail to explicitly listed Ccs and Bccs','NotifyAsComment','OtherRecipients',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(14,'Notify Other Recipients','Sends mail to explicitly listed Ccs and Bccs','Notify','OtherRecipients',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(15,'User Defined','Perform a user-defined action','UserDefined',NULL,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(16,'Create Tickets','Create new tickets based on this scrip\'s template','CreateTickets',NULL,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(17,'Open Tickets','Open tickets on correspondence','AutoOpen',NULL,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(18,'Extract Subject Tag','Extract tags from a Transaction\'s subject and add them to the Ticket\'s subject.','ExtractSubjectTag',NULL,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(19,'RTIR Set Due to Now','Set the due date to the current time','RTIR_SetDueToNow',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(20,'RTIR Set Starts to Now','Set the starts date to the current time','RTIR_SetStartsToNow',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(21,'RTIR Set Started to Now','Set the started date to the current time','RTIR_SetStartedToNow',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(22,'RTIR Set Due by SLA','Set the due date according to SLA','RTIR_SetDueBySLA',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(23,'RTIR Set Due Correspond','Set the due date for correspondence','RTIR_SetDueCorrespond',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(24,'RTIR Set Due Reopen','Set the due date for a reopened ticket','RTIR_SetDueReopen',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(25,'RTIR Set Incident Due','Set the due date of parent Incident','RTIR_SetDueIncident',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(26,'RTIR Unset Due','Unset the due date','RTIR_UnsetDue',NULL,1,'2011-08-03 19:34:23',1,'2011-08-03 19:34:23'),(27,'RTIR Set Starts by Business Hours','Set the starts date according to Business Hours','RTIR_SetStartsByBizHours',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(28,'RTIR Set How Reported','Set how the Incident Report was reported','RTIR_SetHowReported',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(29,'RTIR Resolve Children','Resolve an Incident\'s children','RTIR_ResolveChildren',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(30,'RTIR Change Child Ownership','Change the ownership of Incident\'s children','RTIR_ChangeChildOwnership',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(31,'RTIR Change Parent Ownership','Change the ownership of the parent Incident','RTIR_ChangeParentOwnership',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(32,'RTIR Open Parent','Open the parent Incident when a child reopens','RTIR_OpenParent',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(33,'RTIR Set Incident Report State','Set the state of an Incident Report','RTIR_SetIncidentReportState',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(34,'RTIR Set Investigation State','Set the state of an Investigation','RTIR_SetInvestigationState',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(35,'RTIR Set Block State','Set the state of a Block','RTIR_SetBlockState',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(36,'RTIR Set Incident State','Set the state of an Incident','RTIR_SetIncidentState',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(37,'RTIR Set Incident Resolution','Set the default resolution of an Incident','RTIR_SetIncidentResolution',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(38,'RTIR parse message for IPs','Set IP custom field from message content','RTIR_FindIP',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(39,'RTIR merge IPs','Merge multiple IPs on ticket merge','RTIR_MergeIPs',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(40,'RTIR Set Constituency','Set and cascade Constituency custom field','RTIR_SetConstituency',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(41,'RTIR Set Constituency Group','Set group responsible for constituency','RTIR_SetConstituencyGroup',NULL,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `ScripActions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ScripConditions`
--

DROP TABLE IF EXISTS `ScripConditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ScripConditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `ExecModule` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Argument` varbinary(255) DEFAULT NULL,
  `ApplicableTransTypes` varchar(60) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ScripConditions`
--

LOCK TABLES `ScripConditions` WRITE;
/*!40000 ALTER TABLE `ScripConditions` DISABLE KEYS */;
INSERT INTO `ScripConditions` VALUES (1,'On Create','When a ticket is created','AnyTransaction',NULL,'Create',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(2,'On Transaction','When anything happens','AnyTransaction',NULL,'Any',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(3,'On Correspond','Whenever correspondence comes in','AnyTransaction',NULL,'Correspond',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(4,'On Comment','Whenever comments come in','AnyTransaction',NULL,'Comment',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(5,'On Status Change','Whenever a ticket\'s status changes','AnyTransaction',NULL,'Status',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(6,'On Priority Change','Whenever a ticket\'s priority changes','PriorityChange',NULL,'Set',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(7,'On Owner Change','Whenever a ticket\'s owner changes','OwnerChange',NULL,'Any',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(8,'On Queue Change','Whenever a ticket\'s queue changes','QueueChange',NULL,'Set',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(9,'On Resolve','Whenever a ticket is resolved','StatusChange','resolved','Status',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(10,'On Reject','Whenever a ticket is rejected','StatusChange','rejected','Status',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(11,'User Defined','Whenever a user-defined condition occurs','UserDefined',NULL,'Any',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(12,'On Close','Whenever a ticket is closed','CloseTicket',NULL,'Status,Set',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(13,'On Reopen','Whenever a ticket is reopened','ReopenTicket',NULL,'Status,Set',1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19'),(14,'RTIR Customer Response','Detect an external response','RTIR_CustomerResponse',NULL,'Correspond',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(15,'RTIR Staff Response','Detect an internal response','RTIR_StaffResponse',NULL,'Correspond',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(16,'RTIR Close Ticket','A ticket is rejected or resolved','RTIR_CloseTicket',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(17,'RTIR Reopen Ticket','A closed ticket is reopened','RTIR_ReopenTicket',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(18,'RTIR Require State Change','A ticket requires a state change','RTIR_RequireStateChange',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(19,'RTIR Require Due Change','The due date of the parent incident must be changed','RTIR_RequireDueChange',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(20,'RTIR Require Constituency Change','The constituency must be changed','RTIR_RequireConstituencyChange',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(21,'RTIR Require Constituency Group Change','A group responsible for constituency must be changed','RTIR_RequireConstituencyGroupChange',NULL,'Any',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(22,'RTIR Block Activation','A block was activated or created in active state','RTIR_BlockActivation',NULL,'Create,CustomField',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(23,'RTIR Linking To Incident','Whenever ticket is linked to incident or created with link','RTIR_LinkingToIncident',NULL,'Create,AddLink',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(24,'RTIR Merge','Whenever ticket is merged into another one','RTIR_Merge',NULL,'AddLink',1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `ScripConditions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Scrips`
--

DROP TABLE IF EXISTS `Scrips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Scrips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Description` varchar(255) DEFAULT NULL,
  `ScripCondition` int(11) NOT NULL DEFAULT '0',
  `ScripAction` int(11) NOT NULL DEFAULT '0',
  `ConditionRules` text,
  `ActionRules` text,
  `CustomIsApplicableCode` text,
  `CustomPrepareCode` text,
  `CustomCommitCode` text,
  `Stage` varchar(32) CHARACTER SET ascii DEFAULT NULL,
  `Queue` int(11) NOT NULL DEFAULT '0',
  `Template` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Scrips`
--

LOCK TABLES `Scrips` WRITE;
/*!40000 ALTER TABLE `Scrips` DISABLE KEYS */;
INSERT INTO `Scrips` VALUES (1,'On Correspond Open Tickets',3,17,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(2,'On Owner Change Notify Owner',7,4,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,3,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(3,'On Create Autoreply To Requestors',1,1,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,2,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(4,'On Create Notify AdminCcs',1,8,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,3,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(5,'On Correspond Notify AdminCcs',3,8,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,4,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(6,'On Correspond Notify Requestors and Ccs',3,10,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,5,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(7,'On Correspond Notify Other Recipients',3,14,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,5,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(8,'On Comment Notify AdminCcs as Comment',4,7,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,6,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(9,'On Comment Notify Other Recipients as Comment',4,13,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,5,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(10,'On Resolve Notify Requestors',9,2,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,8,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(11,'On transaction, add any tags in the transaction\'s subject to the ticket\'s subject',2,18,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',0,1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(12,'DetectUserResponse',14,19,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(13,'DetectUserResponse',14,19,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(14,'DetectUserResponse',14,19,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(15,'DetectStaffResponse',15,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(16,'DetectStaffResponse',15,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(17,'DetectStaffResponse',15,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(18,'SetStartsDate',1,20,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(19,'SetStarts',1,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(20,'SetStarts',1,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(21,'SetStarts',1,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(22,'SetStartsDateOnQueueChange',8,20,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(23,'SetStartsDateOnQueueChange',8,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(24,'SetStartsDateOnQueueChange',8,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(25,'SetStartsDateOnQueueChange',8,27,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(26,'SetStarted',22,21,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(27,'SetStarted',23,21,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(28,'SetDue',1,22,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(29,'SetDue',1,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(30,'SetDue',1,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(31,'SetDueOnQueueChange',8,22,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(32,'SetDueOnQueueChange',8,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(33,'SetDueOnQueueChange',8,23,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(34,'UnsetDue',16,26,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(35,'UnsetDue',16,26,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(36,'UnsetDue',16,26,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(37,'SetDueReopen',17,24,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(38,'SetDueReopen',17,24,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(39,'SetDueReopen',17,24,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(40,'SetHowReported',1,28,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(41,'SetRTIRState',18,35,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(42,'SetRTIRState',18,33,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(43,'SetRTIRState',18,34,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(44,'SetRTIRState',18,36,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(45,'SetRTIRState',19,25,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(46,'SetRTIRState',19,25,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(47,'SetRTIRState',19,25,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(48,'ResolveAllChildren',5,29,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(49,'FixOwnership',7,30,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(50,'FixOwnership',7,31,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(51,'FixOwnership',7,31,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(52,'FixOwnership',7,31,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(53,'ReopenIncident',5,32,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(54,'ReopenIncident',5,32,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(55,'ReopenIncident',5,32,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(56,'SetDefaultIncidentResolution',5,37,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(57,'NotifyOnClose',16,2,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,24,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(58,'SetIPFromContent',3,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(59,'SetIPFromContent',3,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(60,'SetIPFromContent',3,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(61,'SetIPFromContent',3,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(62,'SetIPFromContent',1,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(63,'SetIPFromContent',1,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(64,'SetIPFromContent',1,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(65,'SetIPFromContent',1,38,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(66,'MergeIPs',24,39,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(67,'MergeIPs',24,39,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(68,'MergeIPs',24,39,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(69,'MergeIPs',24,39,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(70,'SetConstituency',20,40,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(71,'SetConstituency',20,40,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(72,'SetConstituency',20,40,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(73,'SetConstituency',20,40,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(74,'SetConstituencyGroup',21,41,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',3,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(75,'SetConstituencyGroup',21,41,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',4,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(76,'SetConstituencyGroup',21,41,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',5,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(77,'SetConstituencyGroup',21,41,NULL,NULL,NULL,NULL,NULL,'TransactionCreate',6,1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `Scrips` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Templates`
--

DROP TABLE IF EXISTS `Templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Queue` int(11) NOT NULL DEFAULT '0',
  `Name` varchar(200) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Type` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `Language` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `TranslationOf` int(11) NOT NULL DEFAULT '0',
  `Content` text,
  `LastUpdated` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Templates`
--

LOCK TABLES `Templates` WRITE;
/*!40000 ALTER TABLE `Templates` DISABLE KEYS */;
INSERT INTO `Templates` VALUES (1,0,'Blank','A blank template','Perl',NULL,0,'','2011-08-03 21:03:41',1,1,'2011-08-03 19:34:19'),(2,0,'Autoreply','Default Autoresponse template','Perl',NULL,0,'Subject: AutoReply: {$Ticket->Subject}\n\n\nGreetings,\n\nThis message has been automatically generated in response to the\ncreation of a trouble ticket regarding:\n	\"{$Ticket->Subject()}\", \na summary of which appears below.\n\nThere is no need to reply to this message right now.  Your ticket has been\nassigned an ID of [{$Ticket->QueueObj->SubjectTag || $rtname} #{$Ticket->id()}].\n\nPlease include the string:\n\n         [{$Ticket->QueueObj->SubjectTag || $rtname} #{$Ticket->id}]\n\nin the subject line of all future correspondence about this issue. To do so, \nyou may reply to this message.\n\n                        Thank you,\n                        {$Ticket->QueueObj->CorrespondAddress()}\n\n-------------------------------------------------------------------------\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:19'),(3,0,'Transaction','Default transaction template','Perl',NULL,0,'RT-Attach-Message: yes\n\n\n{$Transaction->CreatedAsString}: Request {$Ticket->id} was acted upon.\n Transaction: {$Transaction->Description}\n       Queue: {$Ticket->QueueObj->Name}\n     Subject: {$Transaction->Subject || $Ticket->Subject || \"(No subject given)\"}\n       Owner: {$Ticket->OwnerObj->Name}\n  Requestors: {$Ticket->RequestorAddresses}\n      Status: {$Ticket->Status}\n Ticket <URL: {RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id} >\n\n\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:19'),(4,0,'Admin Correspondence','Default admin correspondence template','Perl',NULL,0,'RT-Attach-Message: yes\n\n\n<URL: {RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id} >\n\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(5,0,'Correspondence','Default correspondence template','Perl',NULL,0,'RT-Attach-Message: yes\n\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(6,0,'Admin Comment','Default admin comment template','Perl',NULL,0,'Subject: [Comment] {my $s=($Transaction->Subject||$Ticket->Subject); $s =~ s/\\[Comment\\]\\s*//g; $s =~ s/^Re:\\s*//i; $s;}\nRT-Attach-Message: yes\n\n\n{RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id}\nThis is a comment.  It is not sent to the Requestor(s):\n\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(7,0,'Status Change','Ticket status changed','Perl',NULL,0,'Subject: Status Changed to: {$Transaction->NewValue}\n\n\n{RT->Config->Get(\'WebURL\')}Ticket/Display.html?id={$Ticket->id}\n\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(8,0,'Resolved','Ticket Resolved','Perl',NULL,0,'Subject: Resolved: {$Ticket->Subject}\n\nAccording to our records, your request has been resolved. If you have any\nfurther questions or concerns, please respond to this message.\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(9,2,'New Pending Approval','Notify Owners and AdminCcs of new items pending their approval','Perl',NULL,0,'Subject: New Pending Approval: {$Ticket->Subject}\n\nGreetings,\n\nThere is a new item pending your approval: \"{$Ticket->Subject()}\", \na summary of which appears below.\n\nPlease visit {RT->Config->Get(\'WebURL\')}Approvals/Display.html?id={$Ticket->id}\nto approve or reject this ticket, or {RT->Config->Get(\'WebURL\')}Approvals/ to\nbatch-process all your pending approvals.\n\n-------------------------------------------------------------------------\n{$Transaction->Content()}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(10,2,'Approval Passed','Notify Requestor of their ticket has been approved by some approver','Perl',NULL,0,'Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been approved by { eval { $Approver->Name } }.\nOther approvals may be pending.\n\nApprover\'s notes: { $Notes }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(11,2,'All Approvals Passed','Notify Requestor of their ticket has been approved by all approvers','Perl',NULL,0,'Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been approved by { eval { $Approver->Name } }.\nIts Owner may now start to act on it.\n\nApprover\'s notes: { $Notes }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(12,2,'Approval Rejected','Notify Owner of their rejected ticket','Perl',NULL,0,'Subject: Ticket Rejected: {$Ticket->Subject}\n\nGreetings,\n\nYour ticket has been rejected by { eval { $Approver->Name } }.\n\nApprover\'s notes: { $Notes }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(13,2,'Approval Ready for Owner','Notify Owner of their ticket has been approved and is ready to be acted on','Perl',NULL,0,'Subject: Ticket Approved: {$Ticket->Subject}\n\nGreetings,\n\nThe ticket has been approved, you may now start to act on it.\n\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(14,0,'Forward','Heading of a forwarded message','Perl',NULL,0,'\nThis is a forward of transaction #{$Transaction->id} of ticket #{ $Ticket->id }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(15,0,'Forward Ticket','Heading of a forwarded Ticket','Perl',NULL,0,'\n\nThis is a forward of ticket #{ $Ticket->id }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(16,0,'Error: public key','Inform user that he has problems with public key and couldn\'t recieve encrypted content','Perl',NULL,0,'Subject: We have no your public key or it\'s wrong\n\nYou received this message as we have no your public PGP key or we have a problem with your key. Inform the administrator about the problem.\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(17,0,'Error to RT owner: public key','Inform RT owner that user(s) have problems with public keys','Perl',NULL,0,'Subject: Some users have problems with public keys\n\nYou received this message as RT has problems with public keys of the following user:\n{\n    foreach my $e ( @BadRecipients ) {\n        $OUT .= \"* \". $e->{\'Message\'} .\"\\n\";\n    }\n}','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(18,0,'Error: no private key','Inform user that we received an encrypted email and we have no private keys to decrypt','Perl',NULL,0,'Subject: we received message we cannot decrypt\n\nYou sent an encrypted message with subject \'{ $Message->head->get(\'Subject\') }\',\nbut we have no private key it\'s encrypted to.\n\nPlease, check that you encrypt messages with correct keys\nor contact the system administrator.','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(19,0,'Error: bad GnuPG data','Inform user that a message he sent has invalid GnuPG data','Perl',NULL,0,'Subject: We received a message we cannot handle\n\nYou sent us a message that we cannot handle due to corrupted GnuPG signature or encrypted block. we get the following error(s):\n{ foreach my $msg ( @Messages ) {\n    $OUT .= \"* $msg\\n\";\n  }\n}','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(20,0,'PasswordChange','Inform user that his password has been reset','Perl',NULL,0,'Subject: [{RT->Config->Get(\'rtname\')}] Password reset\n\nGreetings,\n\nSomeone at {$ENV{\'REMOTE_ADDR\'}} requested a password reset for you on {RT->Config->Get(\'WebURL\')}\n\nYour new password is:\n  {$NewPassword}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(21,0,'Email Digest','Email template for periodic notification digests','Perl',NULL,0,'Subject: RT Email Digest\n\n{ $Argument }\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(22,0,'Error: Missing dashboard','Inform user that a dashboard he subscribed to is missing','Perl',NULL,0,'Subject: [{RT->Config->Get(\'rtname\')}] Missing dashboard!\n\nGreetings,\n\nYou are subscribed to a dashboard that is currently missing. Most likely, the dashboard was deleted.\n\nRT will remove this subscription as it is no longer useful. Here\'s the information RT had about your subscription:\n\nDashboardID:  { $SubscriptionObj->SubValue(\'DashboardId\') }\nFrequency:    { $SubscriptionObj->SubValue(\'Frequency\') }\nHour:         { $SubscriptionObj->SubValue(\'Hour\') }\n{\n    $SubscriptionObj->SubValue(\'Frequency\') eq \'weekly\'\n    ? \"Day of week:  \" . $SubscriptionObj->SubValue(\'Dow\')\n    : $SubscriptionObj->SubValue(\'Frequency\') eq \'monthly\'\n      ? \"Day of month: \" . $SubscriptionObj->SubValue(\'Dom\')\n      : \'\'\n}\n','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:20'),(23,6,'Autoreply','Sent when a block is created','Perl',NULL,0,'RT-Attach-Message: yes\nSubject: { $Ticket->Subject }\n\n{ $Transaction->Content }\n\n{ my $output = \"\";\n  my @mailfields = ( \"IP\", \"Netmask\", \"Port\", \"Where Blocked\" );\n\n  my $CustomFields = $Ticket->QueueObj->TicketCustomFields;\n  while ( my $CustomField = $CustomFields->Next ) {\n    my $name = $CustomField->Name;\n    next unless grep lc $_ eq lc $name, @mailfields;\n\n    my $Values = $Ticket->CustomFieldValues( $CustomField->Id );\n    while ( my $Value = $Values->Next ) {\n      $output .= $name .\": \". $Value->Content .\"\\n\";\n    }\n  }\n  return $output;\n}\n-------------------------------------------------------------------------\nPlease include the string:\n\n         [{ $Ticket->QueueObj->SubjectTag || $rtname } #{ $Ticket->id }]\n\nin the subject line of all future correspondence about this issue. To do so, \nyou may reply to this message.\n\n                        Thank you,\n                        { $Ticket->QueueObj->CorrespondAddress }','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:24'),(24,6,'BlockRemoved','Sent when a block is removed','Perl',NULL,0,'Subject: {$Ticket->Subject}\n\nBlock #{$Ticket->id} was removed.\n\n{ my $output = \"\";\n  my @mailfields = ( \"IP\", \"Netmask\", \"Port\", \"Where Blocked\" );\n\n  my $CustomFields = $Ticket->QueueObj->TicketCustomFields;\n  while ( my $CustomField = $CustomFields->Next ) {\n    my $name = $CustomField->Name;\n    next unless grep lc $_ eq lc $name, @mailfields;\n\n    my $Values = $Ticket->CustomFieldValues( $CustomField->Id );\n    while ( my $Value = $Values->Next ) {\n      $output .= $name .\": \". $Value->Content .\"\\n\";\n    }\n  }\n  return $output;\n}\n-------------------------------------------------------------------------\nPlease include the string:\n\n         [{ $Ticket->QueueObj->SubjectTag || $rtname } #{$Ticket->id}]\n\nin the subject line of all future correspondence about this issue. To do so, \nyou may reply to this message.\n\n                        Thank you,\n                        {$Ticket->QueueObj->CorrespondAddress()}','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:24'),(25,5,'Autoreply','Sent when an investigation is launched','Perl',NULL,0,'RT-Attach-Message: yes\nSubject: {$Ticket->Subject}\n\n{$Transaction->Content()}\n\n-------------------------------------------------------------------------\nPlease include the string:\n\n         [{ $Ticket->QueueObj->SubjectTag || $rtname } #{$Ticket->id}]\n\nin the subject line of all future correspondence about this issue. To do so, \nyou may reply to this message.\n\n                        Thank you,\n                        {$Ticket->QueueObj->CorrespondAddress()}','2011-08-03 21:03:42',1,1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `Templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Tickets`
--

DROP TABLE IF EXISTS `Tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Tickets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `EffectiveId` int(11) NOT NULL DEFAULT '0',
  `Queue` int(11) NOT NULL DEFAULT '0',
  `Type` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `IssueStatement` int(11) NOT NULL DEFAULT '0',
  `Resolution` int(11) NOT NULL DEFAULT '0',
  `Owner` int(11) NOT NULL DEFAULT '0',
  `Subject` varchar(200) DEFAULT '[no subject]',
  `InitialPriority` int(11) NOT NULL DEFAULT '0',
  `FinalPriority` int(11) NOT NULL DEFAULT '0',
  `Priority` int(11) NOT NULL DEFAULT '0',
  `TimeEstimated` int(11) NOT NULL DEFAULT '0',
  `TimeWorked` int(11) NOT NULL DEFAULT '0',
  `Status` varchar(64) DEFAULT NULL,
  `TimeLeft` int(11) NOT NULL DEFAULT '0',
  `Told` datetime DEFAULT NULL,
  `Starts` datetime DEFAULT NULL,
  `Started` datetime DEFAULT NULL,
  `Due` datetime DEFAULT NULL,
  `Resolved` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `Tickets1` (`Queue`,`Status`),
  KEY `Tickets2` (`Owner`),
  KEY `Tickets6` (`EffectiveId`,`Type`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Tickets`
--

LOCK TABLES `Tickets` WRITE;
/*!40000 ALTER TABLE `Tickets` DISABLE KEYS */;
INSERT INTO `Tickets` VALUES (1,1,4,'ticket',0,0,41,'foo 0.879632438606684',0,0,0,0,0,'open',0,NULL,'2011-08-04 05:00:00','2011-08-03 19:34:38','2011-08-04 07:00:00','1970-01-01 00:00:00',41,'2011-08-03 19:34:47',41,'2011-08-03 19:34:32',0),(2,2,3,'ticket',0,0,41,'first incident',50,0,50,0,0,'open',0,NULL,'2011-08-03 19:34:39','2011-08-03 19:34:37','2011-08-04 07:00:00','1970-01-01 00:00:00',1,'2011-08-03 19:34:46',41,'2011-08-03 19:34:37',0),(3,3,3,'ticket',0,0,41,'foo Incident',50,0,50,0,0,'open',0,NULL,'2011-08-03 19:34:45','2011-08-03 19:34:43','2011-08-04 07:00:00','1970-01-01 00:00:00',41,'2011-08-03 19:34:47',41,'2011-08-03 19:34:43',0),(4,4,4,'ticket',0,0,12,'IR for reject',0,0,0,0,0,'rejected',0,NULL,'2011-08-04 05:00:00','2011-08-03 21:00:34','1970-01-01 00:00:00','2011-08-03 21:00:34',12,'2011-08-03 21:00:35',12,'2011-08-03 21:00:17',0),(5,5,3,'ticket',0,0,12,'Inc for abandon',50,0,50,0,0,'rejected',0,NULL,'2011-08-03 21:01:21','2011-08-03 21:01:17','1970-01-01 00:00:00','2011-08-03 21:01:39',12,'2011-08-03 21:01:39',12,'2011-08-03 21:01:17',0);
/*!40000 ALTER TABLE `Tickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Topics`
--

DROP TABLE IF EXISTS `Topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Parent` int(11) NOT NULL DEFAULT '0',
  `Name` varchar(255) NOT NULL DEFAULT '',
  `Description` varchar(255) NOT NULL DEFAULT '',
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Topics`
--

LOCK TABLES `Topics` WRITE;
/*!40000 ALTER TABLE `Topics` DISABLE KEYS */;
/*!40000 ALTER TABLE `Topics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(200) NOT NULL,
  `Password` varchar(256) DEFAULT NULL,
  `Comments` text,
  `Signature` text,
  `EmailAddress` varchar(120) DEFAULT NULL,
  `FreeformContactInfo` text,
  `Organization` varchar(200) DEFAULT NULL,
  `RealName` varchar(120) DEFAULT NULL,
  `NickName` varchar(16) DEFAULT NULL,
  `Lang` varchar(16) DEFAULT NULL,
  `EmailEncoding` varchar(16) DEFAULT NULL,
  `WebEncoding` varchar(16) DEFAULT NULL,
  `ExternalContactInfoId` varchar(100) DEFAULT NULL,
  `ContactInfoSystem` varchar(30) DEFAULT NULL,
  `ExternalAuthId` varchar(100) DEFAULT NULL,
  `AuthSystem` varchar(30) DEFAULT NULL,
  `Gecos` varchar(16) DEFAULT NULL,
  `HomePhone` varchar(30) DEFAULT NULL,
  `WorkPhone` varchar(30) DEFAULT NULL,
  `MobilePhone` varchar(30) DEFAULT NULL,
  `PagerPhone` varchar(30) DEFAULT NULL,
  `Address1` varchar(200) DEFAULT NULL,
  `Address2` varchar(200) DEFAULT NULL,
  `City` varchar(100) DEFAULT NULL,
  `State` varchar(100) DEFAULT NULL,
  `Zip` varchar(16) DEFAULT NULL,
  `Country` varchar(50) DEFAULT NULL,
  `Timezone` varchar(50) DEFAULT NULL,
  `PGPKey` text,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `AuthToken` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Users1` (`Name`),
  KEY `Users4` (`EmailAddress`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Users`
--

LOCK TABLES `Users` WRITE;
/*!40000 ALTER TABLE `Users` DISABLE KEYS */;
INSERT INTO `Users` VALUES (1,'RT_System','*NO-PASSWORD*','Do not delete or modify this user. It is integral to RT\'s internal database structures',NULL,NULL,NULL,NULL,'The RT System itself',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:16',1,'2011-08-03 19:34:16',NULL),(6,'Nobody','*NO-PASSWORD*','Do not delete or modify this user. It is integral to RT\'s internal data structures',NULL,'',NULL,NULL,'Nobody in particular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17',1,'2011-08-03 19:34:17',NULL),(12,'root','Xd/eRr3i3bTblrsRhjNW8gGMB01oA4HjixhW1eMN','SuperUser',NULL,'root@localhost',NULL,NULL,'Enoch Root',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'root',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19',1,'2011-08-03 19:34:19',NULL),(41,'rtir_test_user','BhR69Cex8+4jwRBw/aIbZqy4KqXXGuJoFiGV5asV',NULL,NULL,'rtir_test_user@example.com',NULL,NULL,'rtir_test_user Smith',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:27',1,'2011-08-03 19:34:27',NULL);
/*!40000 ALTER TABLE `Users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attachments`
--

DROP TABLE IF EXISTS `attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `TransactionId` int(11) NOT NULL,
  `Parent` int(11) NOT NULL DEFAULT '0',
  `MessageId` varchar(160) CHARACTER SET ascii DEFAULT NULL,
  `Subject` varchar(255) DEFAULT NULL,
  `Filename` varchar(255) DEFAULT NULL,
  `ContentType` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `ContentEncoding` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `Content` longblob,
  `Headers` longtext,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Attachments2` (`TransactionId`),
  KEY `Attachments3` (`Parent`,`TransactionId`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attachments`
--

LOCK TABLES `attachments` WRITE;
/*!40000 ALTER TABLE `attachments` DISABLE KEYS */;
INSERT INTO `attachments` VALUES (1,48,0,'','foo 0.879632438606684',NULL,'text/plain','none','bla','Subject: foo 0.879632438606684\nMIME-Version: 1.0\nX-Mailer: MIME-tools 5.428 (Entity 5.428)\nX-RT-Original-Encoding: utf-8\nX-RT-Encrypt: 0\nX-RT-Sign: 0\nContent-Type: text/plain; charset=\"UTF-8\"\nContent-Disposition: inline\nContent-Transfer-Encoding: binary\nContent-Length: 3\n',41,'2011-08-03 19:34:32'),(2,61,0,'','first incident',NULL,'text/plain','none','bla\n\n','Subject: first incident\nMIME-Version: 1.0\nX-Mailer: MIME-tools 5.428 (Entity 5.428)\nX-RT-Original-Encoding: utf-8\nX-RT-Encrypt: 0\nX-RT-Sign: 0\nContent-Type: text/plain; charset=\"UTF-8\"\nContent-Disposition: inline\nContent-Transfer-Encoding: binary\nContent-Length: 5\n',41,'2011-08-03 19:34:38'),(3,69,0,'','foo Incident',NULL,'text/plain','none','bar baz quux','Subject: foo Incident\nMIME-Version: 1.0\nX-Mailer: MIME-tools 5.428 (Entity 5.428)\nX-RT-Original-Encoding: utf-8\nX-RT-Encrypt: 0\nX-RT-Sign: 0\nContent-Type: text/plain; charset=\"UTF-8\"\nContent-Disposition: inline\nContent-Transfer-Encoding: binary\nContent-Length: 12\n',41,'2011-08-03 19:34:43'),(4,80,0,'','IR for reject',NULL,'text/plain',NULL,NULL,'MIME-Version: 1.0\nX-Mailer: MIME-tools 5.428 (Entity 5.428)\nSubject: IR for reject\nX-RT-Encrypt: 0\nX-RT-Sign: 0\nContent-Type: text/plain\nContent-Length: 0\n',12,'2011-08-03 21:00:18'),(5,92,0,'','Inc for abandon',NULL,'text/plain',NULL,NULL,'MIME-Version: 1.0\nX-Mailer: MIME-tools 5.428 (Entity 5.428)\nSubject: Inc for abandon\nX-RT-Encrypt: 0\nX-RT-Sign: 0\nContent-Type: text/plain\nContent-Length: 0\n',12,'2011-08-03 21:01:18');
/*!40000 ALTER TABLE `attachments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `attributes`
--

DROP TABLE IF EXISTS `attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Content` blob,
  `ContentType` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `ObjectType` varchar(64) CHARACTER SET ascii DEFAULT NULL,
  `ObjectId` int(11) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Attributes1` (`Name`),
  KEY `Attributes2` (`ObjectType`,`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attributes`
--

LOCK TABLES `attributes` WRITE;
/*!40000 ALTER TABLE `attributes` DISABLE KEYS */;
INSERT INTO `attributes` VALUES (1,'Search - My Tickets','[_1] highest priority tickets I own','BQcDAAAABAoEREVTQwAAAAVPcmRlcgpDIE93bmVyID0gJ19fQ3VycmVudFVzZXJfXycgQU5EICgg\nU3RhdHVzID0gJ25ldycgT1IgU3RhdHVzID0gJ29wZW4nKQAAAAVRdWVyeQoIUHJpb3JpdHkAAAAH\nT3JkZXJCeQrAJzxhIGhyZWY9Il9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19p\nZF9fIj5fX2lkX188L2E+L1RJVExFOiMnLCc8YSBocmVmPSJfX1dlYlBhdGhfXy9UaWNrZXQvRGlz\ncGxheS5odG1sP2lkPV9faWRfXyI+X19TdWJqZWN0X188L2E+L1RJVExFOlN1YmplY3QnLFByaW9y\naXR5LCBRdWV1ZU5hbWUsIEV4dGVuZGVkU3RhdHVzAAAABkZvcm1hdA==\n','storable','RT::System',1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(2,'Search - Unowned Tickets','[_1] newest unowned tickets','BQcDAAAABAoEREVTQwAAAAVPcmRlcgo6IE93bmVyID0gJ05vYm9keScgQU5EICggU3RhdHVzID0g\nJ25ldycgT1IgU3RhdHVzID0gJ29wZW4nKQAAAAVRdWVyeQoHQ3JlYXRlZAAAAAdPcmRlckJ5AQAA\nAScnPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rpc3BsYXkuaHRtbD9pZD1fX2lkX18iPl9f\naWRfXzwvYT4vVElUTEU6IycsJzxhIGhyZWY9Il9fV2ViUGF0aF9fL1RpY2tldC9EaXNwbGF5Lmh0\nbWw/aWQ9X19pZF9fIj5fX1N1YmplY3RfXzwvYT4vVElUTEU6U3ViamVjdCcsUXVldWVOYW1lLCBF\neHRlbmRlZFN0YXR1cywgQ3JlYXRlZFJlbGF0aXZlLCAnPEEgSFJFRj0iX19XZWJQYXRoX18vVGlj\na2V0L0Rpc3BsYXkuaHRtbD9BY3Rpb249VGFrZSZpZD1fX2lkX18iPl9fbG9jKFRha2UpX188L2E+\nL1RJVExFOk5CU1AnAAAABkZvcm1hdA==\n','storable','RT::System',1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(3,'Search - Bookmarked Tickets','Bookmarked Tickets','BQcDAAAABAoEREVTQwAAAAVPcmRlcgoVaWQgPSAnX19Cb29rbWFya2VkX18nAAAABVF1ZXJ5CgtM\nYXN0VXBkYXRlZAAAAAdPcmRlckJ5CsonPGEgaHJlZj0iX19XZWJQYXRoX18vVGlja2V0L0Rpc3Bs\nYXkuaHRtbD9pZD1fX2lkX18iPl9faWRfXzwvYT4vVElUTEU6IycsJzxhIGhyZWY9Il9fV2ViUGF0\naF9fL1RpY2tldC9EaXNwbGF5Lmh0bWw/aWQ9X19pZF9fIj5fX1N1YmplY3RfXzwvYT4vVElUTEU6\nU3ViamVjdCcsUHJpb3JpdHksIFF1ZXVlTmFtZSwgRXh0ZW5kZWRTdGF0dXMsIEJvb2ttYXJrAAAA\nBkZvcm1hdA==\n','storable','RT::System',1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(4,'HomepageSettings','HomepageSettings','BQcDAAAAAgQCAAAABAQDAAAAAgoKTXkgVGlja2V0cwAAAARuYW1lCgZzeXN0ZW0AAAAEdHlwZQQD\nAAAAAgoPVW5vd25lZCBUaWNrZXRzAAAABG5hbWUKBnN5c3RlbQAAAAR0eXBlBAMAAAACChJCb29r\nbWFya2VkIFRpY2tldHMAAAAEbmFtZQoGc3lzdGVtAAAABHR5cGUEAwAAAAIKC1F1aWNrQ3JlYXRl\nAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlAAAABGJvZHkEAgAAAAQEAwAAAAIKC015UmVtaW5k\nZXJzAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlBAMAAAACCgtRdWlja3NlYXJjaAAAAARuYW1l\nCgljb21wb25lbnQAAAAEdHlwZQQDAAAAAgoKRGFzaGJvYXJkcwAAAARuYW1lCgljb21wb25lbnQA\nAAAEdHlwZQQDAAAAAgoPUmVmcmVzaEhvbWVwYWdlAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBl\nAAAAB3N1bW1hcnk=\n','storable','RT::System',1,1,'2011-08-03 19:34:20',1,'2011-08-03 19:34:20'),(5,'LinkValueTo',NULL,'','','RT::CustomField',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(6,'IncludeContentForValue',NULL,'','','RT::CustomField',1,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(7,'LinkValueTo',NULL,'','','RT::CustomField',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(8,'IncludeContentForValue',NULL,'','','RT::CustomField',2,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(9,'LinkValueTo',NULL,'','','RT::CustomField',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(10,'IncludeContentForValue',NULL,'','','RT::CustomField',3,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(11,'LinkValueTo',NULL,'','','RT::CustomField',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(12,'IncludeContentForValue',NULL,'','','RT::CustomField',4,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(13,'LinkValueTo',NULL,'','','RT::CustomField',5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(14,'IncludeContentForValue',NULL,'','','RT::CustomField',5,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(15,'LinkValueTo',NULL,'','','RT::CustomField',6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(16,'IncludeContentForValue',NULL,'','','RT::CustomField',6,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(17,'LinkValueTo',NULL,'','','RT::CustomField',7,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(18,'IncludeContentForValue',NULL,'','','RT::CustomField',7,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(19,'LinkValueTo',NULL,'','','RT::CustomField',8,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(20,'IncludeContentForValue',NULL,'','','RT::CustomField',8,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(21,'LinkValueTo',NULL,'','','RT::CustomField',9,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(22,'IncludeContentForValue',NULL,'','','RT::CustomField',9,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(23,'LinkValueTo',NULL,'','','RT::CustomField',10,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(24,'IncludeContentForValue',NULL,'','','RT::CustomField',10,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(25,'LinkValueTo',NULL,'','','RT::CustomField',11,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(26,'IncludeContentForValue',NULL,'','','RT::CustomField',11,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(27,'LinkValueTo',NULL,'','','RT::CustomField',12,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(28,'IncludeContentForValue',NULL,'','','RT::CustomField',12,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(29,'LinkValueTo',NULL,'','','RT::CustomField',13,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(30,'IncludeContentForValue',NULL,'','','RT::CustomField',13,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(31,'LinkValueTo',NULL,'','','RT::CustomField',14,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(32,'IncludeContentForValue',NULL,'','','RT::CustomField',14,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(33,'LinkValueTo',NULL,'','','RT::CustomField',15,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(34,'IncludeContentForValue',NULL,'','','RT::CustomField',15,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(35,'LinkValueTo',NULL,'','','RT::CustomField',16,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(36,'IncludeContentForValue',NULL,'','','RT::CustomField',16,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(37,'LinkValueTo',NULL,'','','RT::CustomField',17,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(38,'IncludeContentForValue',NULL,'','','RT::CustomField',17,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(39,'LinkValueTo',NULL,'','','RT::CustomField',18,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(40,'IncludeContentForValue',NULL,'','','RT::CustomField',18,1,'2011-08-03 19:34:22',1,'2011-08-03 19:34:22'),(41,'RTIR_HomepageSettings','RTIR homepage settings','BQcDAAAAAgQCAAAABAQDAAAAAgoZL1JUSVIvRWxlbWVudHMvTmV3UmVwb3J0cwAAAARuYW1lCglj\nb21wb25lbnQAAAAEdHlwZQQDAAAAAgofL1JUSVIvRWxlbWVudHMvVXNlckR1ZUluY2lkZW50cwAA\nAARuYW1lCgljb21wb25lbnQAAAAEdHlwZQQDAAAAAgohL1JUSVIvRWxlbWVudHMvTm9ib2R5RHVl\nSW5jaWRlbnRzAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlBAMAAAACChsvUlRJUi9FbGVtZW50\ncy9EdWVJbmNpZGVudHMAAAAEbmFtZQoJY29tcG9uZW50AAAABHR5cGUAAAAEYm9keQQCAAAAAQQD\nAAAAAgoPUmVmcmVzaEhvbWVwYWdlAAAABG5hbWUKCWNvbXBvbmVudAAAAAR0eXBlAAAAB3N1bW1h\ncnk=\n','storable','RT::System',1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(42,'LinkValueTo',NULL,'','','RT::CustomField',19,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(43,'IncludeContentForValue',NULL,'','','RT::CustomField',19,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(44,'Skip-Name',NULL,'1','','RT::FM::Class',1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(45,'Skip-Summary',NULL,'1','','RT::FM::Class',1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24'),(46,'Skip-CF-Title-19',NULL,'1','','RT::FM::Class',1,1,'2011-08-03 19:34:24',1,'2011-08-03 19:34:24');
/*!40000 ALTER TABLE `attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cachedgroupmembers`
--

DROP TABLE IF EXISTS `cachedgroupmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cachedgroupmembers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `GroupId` int(11) DEFAULT NULL,
  `MemberId` int(11) DEFAULT NULL,
  `Via` int(11) DEFAULT NULL,
  `ImmediateParentId` int(11) DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `DisGrouMem` (`GroupId`,`MemberId`,`Disabled`),
  KEY `CachedGroupMembers3` (`MemberId`,`ImmediateParentId`)
) ENGINE=InnoDB AUTO_INCREMENT=80 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cachedgroupmembers`
--

LOCK TABLES `cachedgroupmembers` WRITE;
/*!40000 ALTER TABLE `cachedgroupmembers` DISABLE KEYS */;
INSERT INTO `cachedgroupmembers` VALUES (1,2,2,1,2,0),(2,2,1,2,2,0),(3,3,3,3,3,0),(4,4,4,4,4,0),(5,5,5,5,5,0),(6,7,7,6,7,0),(7,7,6,7,7,0),(8,3,6,8,3,0),(9,5,6,9,5,0),(10,8,8,10,8,0),(11,9,9,11,9,0),(12,10,10,12,10,0),(13,11,11,13,11,0),(14,13,13,14,13,0),(15,13,12,15,13,0),(16,3,12,16,3,0),(17,4,12,17,4,0),(18,14,14,18,14,0),(19,15,15,19,15,0),(20,16,16,20,16,0),(21,17,17,21,17,0),(22,18,18,22,18,0),(23,19,19,23,19,0),(24,20,20,24,20,0),(25,21,21,25,21,0),(26,22,22,26,22,0),(27,23,23,27,23,0),(28,24,24,28,24,0),(29,25,25,29,25,0),(30,26,26,30,26,0),(31,27,27,31,27,0),(32,28,28,32,28,0),(33,29,29,33,29,0),(34,30,30,34,30,0),(35,31,31,35,31,0),(36,32,32,36,32,0),(37,33,33,37,33,0),(38,34,34,38,34,0),(39,35,35,39,35,0),(40,36,36,40,36,0),(41,37,37,41,37,0),(42,38,38,42,38,0),(43,39,39,43,39,0),(44,40,40,44,40,0),(45,42,42,45,42,0),(46,42,41,46,42,0),(47,3,41,47,3,0),(48,4,41,48,4,0),(49,22,41,49,22,0),(50,43,43,50,43,0),(51,44,44,51,44,0),(52,45,45,52,45,0),(53,46,46,53,46,0),(54,44,41,54,44,0),(55,46,23,55,46,0),(56,47,47,56,47,0),(57,48,48,57,48,0),(58,49,49,58,49,0),(59,50,50,59,50,0),(60,48,41,60,48,0),(61,50,23,61,50,0),(62,51,51,62,51,0),(63,52,52,63,52,0),(64,53,53,64,53,0),(65,54,54,65,54,0),(66,52,41,66,52,0),(67,54,23,67,54,0),(68,55,55,68,55,0),(69,56,56,69,56,0),(70,57,57,70,57,0),(71,58,58,71,58,0),(72,56,12,72,56,0),(73,58,23,73,58,0),(74,59,59,74,59,0),(75,60,60,75,60,0),(76,61,61,76,61,0),(77,62,62,77,62,0),(78,60,12,78,60,0),(79,62,23,79,62,0);
/*!40000 ALTER TABLE `cachedgroupmembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `links`
--

DROP TABLE IF EXISTS `links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Base` varchar(240) DEFAULT NULL,
  `Target` varchar(240) DEFAULT NULL,
  `Type` varchar(20) NOT NULL,
  `LocalTarget` int(11) NOT NULL DEFAULT '0',
  `LocalBase` int(11) NOT NULL DEFAULT '0',
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Links2` (`Base`,`Type`),
  KEY `Links3` (`Target`,`Type`),
  KEY `Links4` (`Type`,`LocalBase`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `links`
--

LOCK TABLES `links` WRITE;
/*!40000 ALTER TABLE `links` DISABLE KEYS */;
INSERT INTO `links` VALUES (1,'fsck.com-rt://example.com/ticket/1','fsck.com-rt://example.com/ticket/2','MemberOf',2,1,41,'2011-08-03 19:34:37',41,'2011-08-03 19:34:37'),(2,'fsck.com-rt://example.com/ticket/1','fsck.com-rt://example.com/ticket/3','MemberOf',3,1,41,'2011-08-03 19:34:46',41,'2011-08-03 19:34:46');
/*!40000 ALTER TABLE `links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `objectcustomfieldvalues`
--

DROP TABLE IF EXISTS `objectcustomfieldvalues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `objectcustomfieldvalues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `CustomField` int(11) NOT NULL,
  `ObjectType` varchar(255) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL,
  `SortOrder` int(11) NOT NULL DEFAULT '0',
  `Content` varchar(255) DEFAULT NULL,
  `LargeContent` longblob,
  `ContentType` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `ContentEncoding` varchar(80) CHARACTER SET ascii DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  `LastUpdatedBy` int(11) NOT NULL DEFAULT '0',
  `LastUpdated` datetime DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `ObjectCustomFieldValues1` (`Content`),
  KEY `ObjectCustomFieldValues2` (`CustomField`,`ObjectType`,`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `objectcustomfieldvalues`
--

LOCK TABLES `objectcustomfieldvalues` WRITE;
/*!40000 ALTER TABLE `objectcustomfieldvalues` DISABLE KEYS */;
INSERT INTO `objectcustomfieldvalues` VALUES (1,8,'RT::Ticket',1,0,'Full service: out of hours',NULL,NULL,'',41,'2011-08-03 19:34:32',41,'2011-08-03 19:34:32',0),(2,2,'RT::Ticket',1,0,'EDUNET',NULL,NULL,'',41,'2011-08-03 19:34:32',41,'2011-08-03 19:34:32',0),(3,3,'RT::Ticket',1,0,'new',NULL,NULL,'',1,'2011-08-03 19:34:34',1,'2011-08-03 19:34:38',1),(4,2,'RT::Ticket',2,0,'EDUNET',NULL,NULL,'',41,'2011-08-03 19:34:37',41,'2011-08-03 19:34:37',0),(5,9,'RT::Ticket',2,0,'IncidentCoord',NULL,NULL,'',41,'2011-08-03 19:34:37',41,'2011-08-03 19:34:37',0),(6,3,'RT::Ticket',1,0,'open',NULL,NULL,'',1,'2011-08-03 19:34:38',1,'2011-08-03 19:34:38',0),(7,1,'RT::Ticket',2,0,'open',NULL,NULL,'',1,'2011-08-03 19:34:39',1,'2011-08-03 19:34:39',0),(8,2,'RT::Ticket',3,0,'EDUNET',NULL,NULL,'',41,'2011-08-03 19:34:43',41,'2011-08-03 19:34:43',0),(9,1,'RT::Ticket',3,0,'open',NULL,NULL,'',1,'2011-08-03 19:34:45',1,'2011-08-03 19:34:45',0),(10,8,'RT::Ticket',4,0,'Full service: out of hours',NULL,NULL,'',12,'2011-08-03 21:00:18',12,'2011-08-03 21:00:18',0),(11,2,'RT::Ticket',4,0,'EDUNET',NULL,NULL,'',12,'2011-08-03 21:00:18',12,'2011-08-03 21:00:18',0),(12,3,'RT::Ticket',4,0,'new',NULL,NULL,'',1,'2011-08-03 21:00:20',1,'2011-08-03 21:00:34',1),(13,3,'RT::Ticket',4,0,'rejected',NULL,NULL,'',1,'2011-08-03 21:00:34',1,'2011-08-03 21:00:34',0),(14,2,'RT::Ticket',5,0,'EDUNET',NULL,NULL,'',12,'2011-08-03 21:01:18',12,'2011-08-03 21:01:18',0),(15,1,'RT::Ticket',5,0,'open',NULL,NULL,'',1,'2011-08-03 21:01:20',1,'2011-08-03 21:01:39',1),(16,7,'RT::Ticket',5,0,'no resolution reached',NULL,NULL,'',12,'2011-08-03 21:01:38',12,'2011-08-03 21:01:38',0),(17,1,'RT::Ticket',5,0,'abandoned',NULL,NULL,'',1,'2011-08-03 21:01:39',1,'2011-08-03 21:01:39',0);
/*!40000 ALTER TABLE `objectcustomfieldvalues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `principals`
--

DROP TABLE IF EXISTS `principals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `principals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `PrincipalType` varchar(16) NOT NULL,
  `ObjectId` int(11) DEFAULT NULL,
  `Disabled` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `Principals2` (`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `principals`
--

LOCK TABLES `principals` WRITE;
/*!40000 ALTER TABLE `principals` DISABLE KEYS */;
INSERT INTO `principals` VALUES (1,'User',1,0),(2,'Group',2,0),(3,'Group',3,0),(4,'Group',4,0),(5,'Group',5,0),(6,'User',6,0),(7,'Group',7,0),(8,'Group',8,0),(9,'Group',9,0),(10,'Group',10,0),(11,'Group',11,0),(12,'User',12,0),(13,'Group',13,0),(14,'Group',14,0),(15,'Group',15,0),(16,'Group',16,0),(17,'Group',17,0),(18,'Group',18,0),(19,'Group',19,0),(20,'Group',20,0),(21,'Group',21,0),(22,'Group',22,0),(23,'Group',23,0),(24,'Group',24,0),(25,'Group',25,0),(26,'Group',26,0),(27,'Group',27,0),(28,'Group',28,0),(29,'Group',29,0),(30,'Group',30,0),(31,'Group',31,0),(32,'Group',32,0),(33,'Group',33,0),(34,'Group',34,0),(35,'Group',35,0),(36,'Group',36,0),(37,'Group',37,0),(38,'Group',38,0),(39,'Group',39,0),(40,'Group',40,0),(41,'User',41,0),(42,'Group',42,0),(43,'Group',43,0),(44,'Group',44,0),(45,'Group',45,0),(46,'Group',46,0),(47,'Group',47,0),(48,'Group',48,0),(49,'Group',49,0),(50,'Group',50,0),(51,'Group',51,0),(52,'Group',52,0),(53,'Group',53,0),(54,'Group',54,0),(55,'Group',55,0),(56,'Group',56,0),(57,'Group',57,0),(58,'Group',58,0),(59,'Group',59,0),(60,'Group',60,0),(61,'Group',61,0),(62,'Group',62,0);
/*!40000 ALTER TABLE `principals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` char(32) NOT NULL,
  `a_session` longblob,
  `LastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ObjectType` varchar(64) CHARACTER SET ascii NOT NULL,
  `ObjectId` int(11) NOT NULL DEFAULT '0',
  `TimeTaken` int(11) NOT NULL DEFAULT '0',
  `Type` varchar(20) CHARACTER SET ascii DEFAULT NULL,
  `Field` varchar(40) CHARACTER SET ascii DEFAULT NULL,
  `OldValue` varchar(255) DEFAULT NULL,
  `NewValue` varchar(255) DEFAULT NULL,
  `ReferenceType` varchar(255) CHARACTER SET ascii DEFAULT NULL,
  `OldReference` int(11) DEFAULT NULL,
  `NewReference` int(11) DEFAULT NULL,
  `Data` varchar(255) DEFAULT NULL,
  `Creator` int(11) NOT NULL DEFAULT '0',
  `Created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `Transactions1` (`ObjectType`,`ObjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=99 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES (1,'RT::Group',3,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(2,'RT::Group',4,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(3,'RT::Group',5,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(4,'RT::User',6,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(5,'RT::Group',8,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(6,'RT::Group',9,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(7,'RT::Group',10,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(8,'RT::Group',11,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:17'),(9,'RT::User',12,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(10,'RT::Group',14,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(11,'RT::Group',15,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(12,'RT::Group',16,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(13,'RT::Group',17,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(14,'RT::Queue',1,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(15,'RT::Group',18,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(16,'RT::Group',19,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(17,'RT::Group',20,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(18,'RT::Group',21,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(19,'RT::Queue',2,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:19'),(20,'RT::Group',22,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(21,'RT::Group',23,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(22,'RT::Group',24,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(23,'RT::Group',25,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(24,'RT::Group',26,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(25,'RT::Group',27,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:21'),(26,'RT::Group',28,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(27,'RT::Queue',3,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(28,'RT::Group',29,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(29,'RT::Group',30,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(30,'RT::Group',31,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(31,'RT::Group',32,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(32,'RT::Queue',4,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(33,'RT::Group',33,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(34,'RT::Group',34,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(35,'RT::Group',35,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(36,'RT::Group',36,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(37,'RT::Queue',5,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(38,'RT::Group',37,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(39,'RT::Group',38,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(40,'RT::Group',39,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(41,'RT::Group',40,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(42,'RT::Queue',6,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:22'),(43,'RT::User',41,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:27'),(44,'RT::Group',43,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:32'),(45,'RT::Group',44,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:32'),(46,'RT::Group',45,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:32'),(47,'RT::Group',46,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:32'),(48,'RT::Ticket',1,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:32'),(49,'RT::Ticket',1,0,'AddWatcher','AdminCc',NULL,'23',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:34'),(50,'RT::Ticket',1,0,'Set','Due','1970-01-01 00:00:00','2011-08-04 07:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:34'),(51,'RT::Ticket',1,0,'CustomField','3',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,3,NULL,1,'2011-08-03 19:34:34'),(52,'RT::Ticket',1,0,'Set','Starts','1970-01-01 00:00:00','2011-08-04 05:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:34'),(53,'RT::Group',47,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:37'),(54,'RT::Group',48,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:37'),(55,'RT::Group',49,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:37'),(56,'RT::Group',50,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:37'),(57,'RT::Ticket',1,0,'AddLink','MemberOf',NULL,'fsck.com-rt://example.com/ticket/2',NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:37'),(58,'RT::Ticket',1,0,'CustomField','3',NULL,NULL,'RT::ObjectCustomFieldValue',3,6,NULL,1,'2011-08-03 19:34:38'),(59,'RT::Ticket',2,0,'Set','Due','1970-01-01 00:00:00','2011-08-04 07:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:38'),(60,'RT::Ticket',1,0,'Status','Status','new','open',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:38'),(61,'RT::Ticket',2,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:38'),(62,'RT::Ticket',2,0,'AddWatcher','AdminCc',NULL,'23',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:38'),(63,'RT::Ticket',2,0,'CustomField','1',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,7,NULL,1,'2011-08-03 19:34:39'),(64,'RT::Ticket',2,0,'Set','Starts','1970-01-01 00:00:00','2011-08-03 19:34:39',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:39'),(65,'RT::Group',51,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:43'),(66,'RT::Group',52,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:43'),(67,'RT::Group',53,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:43'),(68,'RT::Group',54,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:43'),(69,'RT::Ticket',3,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:43'),(70,'RT::Ticket',3,0,'AddWatcher','AdminCc',NULL,'23',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:44'),(71,'RT::Ticket',3,0,'CustomField','1',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,9,NULL,1,'2011-08-03 19:34:45'),(72,'RT::Ticket',3,0,'Set','Starts','1970-01-01 00:00:00','2011-08-03 19:34:45',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:45'),(73,'RT::Ticket',1,0,'AddLink','MemberOf',NULL,'fsck.com-rt://example.com/ticket/3',NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:46'),(74,'RT::Ticket',3,0,'Set','Due','1970-01-01 00:00:00','2011-08-04 07:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 19:34:47'),(75,'RT::Ticket',3,0,'AddLink','HasMember',NULL,'fsck.com-rt://example.com/ticket/1',NULL,NULL,NULL,NULL,41,'2011-08-03 19:34:47'),(76,'RT::Group',55,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:17'),(77,'RT::Group',56,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:17'),(78,'RT::Group',57,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:17'),(79,'RT::Group',58,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:17'),(80,'RT::Ticket',4,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:18'),(81,'RT::Ticket',4,0,'AddWatcher','AdminCc',NULL,'23',NULL,NULL,NULL,NULL,1,'2011-08-03 21:00:19'),(82,'RT::Ticket',4,0,'Set','Due','1970-01-01 00:00:00','2011-08-04 07:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 21:00:20'),(83,'RT::Ticket',4,0,'CustomField','3',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,12,NULL,1,'2011-08-03 21:00:20'),(84,'RT::Ticket',4,0,'Set','Starts','1970-01-01 00:00:00','2011-08-04 05:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 21:00:20'),(85,'RT::Ticket',4,0,'Status','Status','new','rejected',NULL,NULL,NULL,NULL,12,'2011-08-03 21:00:34'),(86,'RT::Ticket',4,0,'CustomField','3',NULL,NULL,'RT::ObjectCustomFieldValue',12,13,NULL,1,'2011-08-03 21:00:34'),(87,'RT::Ticket',4,0,'Set','Due','2011-08-04 07:00:00','1970-01-01 00:00:00',NULL,NULL,NULL,NULL,1,'2011-08-03 21:00:34'),(88,'RT::Group',59,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:17'),(89,'RT::Group',60,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:17'),(90,'RT::Group',61,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:17'),(91,'RT::Group',62,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:17'),(92,'RT::Ticket',5,0,'Create',NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:18'),(93,'RT::Ticket',5,0,'AddWatcher','AdminCc',NULL,'23',NULL,NULL,NULL,NULL,1,'2011-08-03 21:01:20'),(94,'RT::Ticket',5,0,'CustomField','1',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,15,NULL,1,'2011-08-03 21:01:20'),(95,'RT::Ticket',5,0,'Set','Starts','1970-01-01 00:00:00','2011-08-03 21:01:21',NULL,NULL,NULL,NULL,1,'2011-08-03 21:01:21'),(96,'RT::Ticket',5,0,'CustomField','7',NULL,NULL,'RT::ObjectCustomFieldValue',NULL,16,NULL,12,'2011-08-03 21:01:38'),(97,'RT::Ticket',5,0,'Status','Status','open','rejected',NULL,NULL,NULL,NULL,12,'2011-08-03 21:01:39'),(98,'RT::Ticket',5,0,'CustomField','1',NULL,NULL,'RT::ObjectCustomFieldValue',15,17,NULL,1,'2011-08-03 21:01:39');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-08-04  1:04:27

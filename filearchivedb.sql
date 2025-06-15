-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 15, 2025 at 07:22 AM
-- Server version: 9.1.0
-- PHP Version: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `filearchivedb`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `AuthenticateUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AuthenticateUser` (IN `p_email` VARCHAR(254))   BEGIN
    SELECT id, username, password, is_active, is_admin
    FROM myapp_user
    WHERE email = p_email
    LIMIT 1;
END$$

DROP PROCEDURE IF EXISTS `delete_file_by_id`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_file_by_id` (IN `p_file_id` INT)   BEGIN
    DELETE FROM myapp_filearchive WHERE id = p_file_id;
END$$

DROP PROCEDURE IF EXISTS `delete_user`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_user` (IN `p_id` INT)   BEGIN
    DELETE FROM auth_user WHERE id = p_id;
END$$

DROP PROCEDURE IF EXISTS `get_all_users`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_users` ()   BEGIN
    SELECT 
        id, username, email, first_name, last_name, is_active, is_admin, created_at, updated_at
    FROM myapp_user  -- replace with your actual table name if different
    ORDER BY id;
END$$

DROP PROCEDURE IF EXISTS `get_category_count`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_category_count` ()   BEGIN
    SELECT COUNT(*) AS total_categories FROM myapp_filecategory;
END$$

DROP PROCEDURE IF EXISTS `get_dashboard_counts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_dashboard_counts` ()   BEGIN
    SELECT 
        (SELECT COUNT(*) FROM myapp_user) AS users_total,
        (SELECT COUNT(*) FROM myapp_filearchive) AS files_total,
        (SELECT COUNT(*) FROM myapp_filecategory) AS categories_total;
END$$

DROP PROCEDURE IF EXISTS `get_file_count`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_file_count` ()   BEGIN
    SELECT COUNT(*) AS total_files FROM myapp_filearchive;
END$$

DROP PROCEDURE IF EXISTS `get_user_count`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_user_count` ()   BEGIN
    SELECT COUNT(*) AS total_users FROM myapp_user;
END$$

DROP PROCEDURE IF EXISTS `insert_user`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_user` (IN `p_username` VARCHAR(100), IN `p_email` VARCHAR(191), IN `p_password` VARCHAR(128), IN `p_first_name` VARCHAR(30), IN `p_last_name` VARCHAR(30), IN `p_is_admin` BOOLEAN)   BEGIN
    INSERT INTO myapp_user (
        username, email, password, first_name, last_name, is_admin, created_at, updated_at
    ) VALUES (
        p_username, p_email, p_password, p_first_name, p_last_name, p_is_admin, NOW(), NOW()
    );
END$$

DROP PROCEDURE IF EXISTS `LogUserLogin`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `LogUserLogin` (IN `p_user_id` INT, IN `p_username` VARCHAR(150), IN `p_email` VARCHAR(255))   BEGIN
    INSERT INTO user_login_logs (user_id, username, email, login_time)
    VALUES (p_user_id, p_username, p_email, NOW());
END$$

DROP PROCEDURE IF EXISTS `log_file_upload`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `log_file_upload` (IN `p_user_id` INT, IN `p_category_id` INT, IN `p_file_path` VARCHAR(255), IN `p_original_filename` VARCHAR(255), IN `p_description` TEXT, IN `p_is_public` BOOLEAN)   BEGIN
    INSERT INTO myapp_filearchive (
        uploaded_by_id,
        category_id,
        file,
        original_filename,
        description,
        is_public,
        uploaded_at,
        updated_at
    ) VALUES (
        p_user_id,
        p_category_id,
        p_file_path,
        p_original_filename,
        p_description,
        p_is_public,
        NOW(),
        NOW()
    );
END$$

DROP PROCEDURE IF EXISTS `RegisterUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `RegisterUser` (IN `p_username` VARCHAR(255), IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255), OUT `p_message` VARCHAR(255))   BEGIN
    DECLARE email_exists INT DEFAULT 0;
    DECLARE username_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO email_exists FROM myapp_user WHERE email = p_email;
    SELECT COUNT(*) INTO username_exists FROM myapp_user WHERE username = p_username;

    IF email_exists > 0 THEN
        SET p_message = 'Email is already registered.';
    ELSEIF username_exists > 0 THEN
        SET p_message = 'Username is already taken.';
    ELSE
        INSERT INTO myapp_user (username, email, password, is_active, created_at, updated_at)
        VALUES (p_username, p_email, p_password, TRUE, NOW(), NOW());
        SET p_message = 'Account created successfully.';
        -- trigger will automatically log the new registration
    END IF;
END$$

DROP PROCEDURE IF EXISTS `update_file_record`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_file_record` (IN `p_file_id` INT, IN `p_category_id` INT, IN `p_original_filename` VARCHAR(255), IN `p_description` TEXT, IN `p_is_public` BOOLEAN)   BEGIN
    UPDATE myapp_filearchive
    SET
        category_id = p_category_id,
        original_filename = p_original_filename,
        description = p_description,
        is_public = p_is_public,
        updated_at = NOW()
    WHERE id = p_file_id;
END$$

DROP PROCEDURE IF EXISTS `update_user`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_user` (IN `p_id` INT, IN `p_username` VARCHAR(150), IN `p_email` VARCHAR(254), IN `p_first_name` VARCHAR(150), IN `p_last_name` VARCHAR(150), IN `p_is_admin` TINYINT)   BEGIN
    UPDATE auth_user
    SET
        username = p_username,
        email = p_email,
        first_name = p_first_name,
        last_name = p_last_name,
        is_staff = p_is_admin,
        is_superuser = p_is_admin
    WHERE id = p_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `archive_deletion_log`
--

DROP TABLE IF EXISTS `archive_deletion_log`;
CREATE TABLE IF NOT EXISTS `archive_deletion_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `file_id` int DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `deleted_by` int DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `archive_deletion_log`
--

INSERT INTO `archive_deletion_log` (`id`, `file_id`, `original_filename`, `deleted_by`, `deleted_at`) VALUES
(1, 35, 'Logo', 1, '2025-06-14 11:13:05');

-- --------------------------------------------------------

--
-- Table structure for table `auth_group`
--

DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE IF NOT EXISTS `auth_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_group_permissions`
--

DROP TABLE IF EXISTS `auth_group_permissions`;
CREATE TABLE IF NOT EXISTS `auth_group_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `group_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissions_group_id_b120cbf9` (`group_id`),
  KEY `auth_group_permissions_permission_id_84c5c92e` (`permission_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE IF NOT EXISTS `auth_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  KEY `auth_permission_content_type_id_2f476e4b` (`content_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `auth_permission`
--

INSERT INTO `auth_permission` (`id`, `name`, `content_type_id`, `codename`) VALUES
(1, 'Can add log entry', 1, 'add_logentry'),
(2, 'Can change log entry', 1, 'change_logentry'),
(3, 'Can delete log entry', 1, 'delete_logentry'),
(4, 'Can view log entry', 1, 'view_logentry'),
(5, 'Can add permission', 2, 'add_permission'),
(6, 'Can change permission', 2, 'change_permission'),
(7, 'Can delete permission', 2, 'delete_permission'),
(8, 'Can view permission', 2, 'view_permission'),
(9, 'Can add group', 3, 'add_group'),
(10, 'Can change group', 3, 'change_group'),
(11, 'Can delete group', 3, 'delete_group'),
(12, 'Can view group', 3, 'view_group'),
(13, 'Can add user', 4, 'add_user'),
(14, 'Can change user', 4, 'change_user'),
(15, 'Can delete user', 4, 'delete_user'),
(16, 'Can view user', 4, 'view_user'),
(17, 'Can add content type', 5, 'add_contenttype'),
(18, 'Can change content type', 5, 'change_contenttype'),
(19, 'Can delete content type', 5, 'delete_contenttype'),
(20, 'Can view content type', 5, 'view_contenttype'),
(21, 'Can add session', 6, 'add_session'),
(22, 'Can change session', 6, 'change_session'),
(23, 'Can delete session', 6, 'delete_session'),
(24, 'Can view session', 6, 'view_session'),
(25, 'Can add file category', 7, 'add_filecategory'),
(26, 'Can change file category', 7, 'change_filecategory'),
(27, 'Can delete file category', 7, 'delete_filecategory'),
(28, 'Can view file category', 7, 'view_filecategory'),
(29, 'Can add user', 8, 'add_user'),
(30, 'Can change user', 8, 'change_user'),
(31, 'Can delete user', 8, 'delete_user'),
(32, 'Can view user', 8, 'view_user'),
(33, 'Can add file archive', 9, 'add_filearchive'),
(34, 'Can change file archive', 9, 'change_filearchive'),
(35, 'Can delete file archive', 9, 'delete_filearchive'),
(36, 'Can view file archive', 9, 'view_filearchive'),
(37, 'Can add public file view', 10, 'add_publicfileview'),
(38, 'Can change public file view', 10, 'change_publicfileview'),
(39, 'Can delete public file view', 10, 'delete_publicfileview'),
(40, 'Can view public file view', 10, 'view_publicfileview');

-- --------------------------------------------------------

--
-- Table structure for table `auth_user`
--

DROP TABLE IF EXISTS `auth_user`;
CREATE TABLE IF NOT EXISTS `auth_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(128) NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(150) NOT NULL,
  `first_name` varchar(150) NOT NULL,
  `last_name` varchar(150) NOT NULL,
  `email` varchar(254) NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `auth_user`
--

INSERT INTO `auth_user` (`id`, `password`, `last_login`, `is_superuser`, `username`, `first_name`, `last_name`, `email`, `is_staff`, `is_active`, `date_joined`) VALUES
(1, 'pbkdf2_sha256$1000000$hxRvBTYxKSsC6OIxOV01lH$FKQ4ZwtD9tmQYBzvHM3RDi99LuxC/nf3iuCtqqGJYd8=', NULL, 0, 'admin', '', '', 'admin@gmail.com', 0, 1, '2025-06-12 07:06:52.644430');

-- --------------------------------------------------------

--
-- Table structure for table `auth_user_groups`
--

DROP TABLE IF EXISTS `auth_user_groups`;
CREATE TABLE IF NOT EXISTS `auth_user_groups` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_groups_user_id_group_id_94350c0c_uniq` (`user_id`,`group_id`),
  KEY `auth_user_groups_user_id_6a12ed8b` (`user_id`),
  KEY `auth_user_groups_group_id_97559544` (`group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_user_user_permissions`
--

DROP TABLE IF EXISTS `auth_user_user_permissions`;
CREATE TABLE IF NOT EXISTS `auth_user_user_permissions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_14a6b632_uniq` (`user_id`,`permission_id`),
  KEY `auth_user_user_permissions_user_id_a95ead1b` (`user_id`),
  KEY `auth_user_user_permissions_permission_id_1fbb5f2c` (`permission_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `django_admin_log`
--

DROP TABLE IF EXISTS `django_admin_log`;
CREATE TABLE IF NOT EXISTS `django_admin_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint UNSIGNED NOT NULL,
  `change_message` longtext NOT NULL,
  `content_type_id` int DEFAULT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `django_admin_log_content_type_id_c4bce8eb` (`content_type_id`),
  KEY `django_admin_log_user_id_c564eba6` (`user_id`)
) ;

-- --------------------------------------------------------

--
-- Table structure for table `django_content_type`
--

DROP TABLE IF EXISTS `django_content_type`;
CREATE TABLE IF NOT EXISTS `django_content_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `django_content_type`
--

INSERT INTO `django_content_type` (`id`, `app_label`, `model`) VALUES
(1, 'admin', 'logentry'),
(2, 'auth', 'permission'),
(3, 'auth', 'group'),
(4, 'auth', 'user'),
(5, 'contenttypes', 'contenttype'),
(6, 'sessions', 'session'),
(7, 'myapp', 'filecategory'),
(8, 'myapp', 'user'),
(9, 'myapp', 'filearchive'),
(10, 'myapp', 'publicfileview');

-- --------------------------------------------------------

--
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
CREATE TABLE IF NOT EXISTS `django_migrations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `django_migrations`
--

INSERT INTO `django_migrations` (`id`, `app`, `name`, `applied`) VALUES
(1, 'contenttypes', '0001_initial', '2025-06-12 07:02:59.526287'),
(2, 'auth', '0001_initial', '2025-06-12 07:02:59.973018'),
(3, 'admin', '0001_initial', '2025-06-12 07:03:00.128343'),
(4, 'admin', '0002_logentry_remove_auto_add', '2025-06-12 07:03:00.137462'),
(5, 'admin', '0003_logentry_add_action_flag_choices', '2025-06-12 07:03:00.145370'),
(6, 'contenttypes', '0002_remove_content_type_name', '2025-06-12 07:03:00.215168'),
(7, 'auth', '0002_alter_permission_name_max_length', '2025-06-12 07:03:00.249790'),
(8, 'auth', '0003_alter_user_email_max_length', '2025-06-12 07:03:00.282877'),
(9, 'auth', '0004_alter_user_username_opts', '2025-06-12 07:03:00.293495'),
(10, 'auth', '0005_alter_user_last_login_null', '2025-06-12 07:03:00.327386'),
(11, 'auth', '0006_require_contenttypes_0002', '2025-06-12 07:03:00.328795'),
(12, 'auth', '0007_alter_validators_add_error_messages', '2025-06-12 07:03:00.337086'),
(13, 'auth', '0008_alter_user_username_max_length', '2025-06-12 07:03:00.373660'),
(14, 'auth', '0009_alter_user_last_name_max_length', '2025-06-12 07:03:00.407167'),
(15, 'auth', '0010_alter_group_name_max_length', '2025-06-12 07:03:00.436252'),
(16, 'auth', '0011_update_proxy_permissions', '2025-06-12 07:03:00.446939'),
(17, 'auth', '0012_alter_user_first_name_max_length', '2025-06-12 07:03:00.482012'),
(18, 'myapp', '0001_initial', '2025-06-12 07:03:00.610912'),
(19, 'sessions', '0001_initial', '2025-06-12 07:03:00.645541'),
(20, 'myapp', '0002_publicfileview', '2025-06-13 09:25:06.483116'),
(21, 'myapp', '0003_delete_publicfileview', '2025-06-13 09:27:22.457064');

-- --------------------------------------------------------

--
-- Table structure for table `django_session`
--

DROP TABLE IF EXISTS `django_session`;
CREATE TABLE IF NOT EXISTS `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_expire_date_a5c62663` (`expire_date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `django_session`
--

INSERT INTO `django_session` (`session_key`, `session_data`, `expire_date`) VALUES
('o49zeveaydvrx9twi9ksrneh9aphdhox', 'eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluQGdtYWlsLmNvbSIsImlzX2FkbWluIjoxfQ:1uQhJi:BG2XgswNUgCMT9ASLwRPwYrOmu9J3H8eOK6IQV1jwgk', '2025-06-29 06:58:10.625430'),
('6lqucamxa4pmo7b8dzy77kya8ag29p9d', 'eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluQGdtYWlsLmNvbSIsImlzX2FkbWluIjoxfQ:1uQ6wo:OJgtUpp-646txiK13YrtSFvWBXpZPYMOk5pqHwtnVsU', '2025-06-27 16:08:06.825442');

-- --------------------------------------------------------

--
-- Table structure for table `file_upload_audit`
--

DROP TABLE IF EXISTS `file_upload_audit`;
CREATE TABLE IF NOT EXISTS `file_upload_audit` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `file_id` int DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `uploaded_by_id` int DEFAULT NULL,
  `upload_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `myapp_filearchive`
--

DROP TABLE IF EXISTS `myapp_filearchive`;
CREATE TABLE IF NOT EXISTS `myapp_filearchive` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file` varchar(100) NOT NULL,
  `original_filename` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `uploaded_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `is_public` tinyint(1) NOT NULL,
  `category_id` bigint DEFAULT NULL,
  `uploaded_by_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `myapp_filearchive_category_id_fbe4aa5e` (`category_id`),
  KEY `myapp_filearchive_uploaded_by_id_9ab99082` (`uploaded_by_id`)
) ENGINE=MyISAM AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `myapp_filearchive`
--

INSERT INTO `myapp_filearchive` (`id`, `file`, `original_filename`, `description`, `uploaded_at`, `updated_at`, `is_public`, `category_id`, `uploaded_by_id`) VALUES
(34, 'archives/Eastern Visayas State University_m4lsmqa.docx', 'Evsu File', 'Evsu File Words', '2025-06-14 00:41:02.000000', '2025-06-15 15:00:22.000000', 0, 1, 1),
(36, 'archives/ChatGPT Image Jun 14, 2025, 12_47_27 AM.png', 'Website Logo', 'This is the image for the website', '2025-06-14 11:41:43.000000', '2025-06-14 11:41:43.000000', 0, 2, 1);

--
-- Triggers `myapp_filearchive`
--
DROP TRIGGER IF EXISTS `after_file_upload`;
DELIMITER $$
CREATE TRIGGER `after_file_upload` AFTER INSERT ON `myapp_filearchive` FOR EACH ROW BEGIN
    CALL log_file_upload(NEW.id, NEW.original_filename, NEW.uploaded_by_id);
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_log_file_deletion`;
DELIMITER $$
CREATE TRIGGER `trg_log_file_deletion` BEFORE DELETE ON `myapp_filearchive` FOR EACH ROW BEGIN
    INSERT INTO archive_deletion_log (
        file_id,
        original_filename,
        deleted_by,
        deleted_at
    ) VALUES (
        OLD.id,
        OLD.original_filename,
        OLD.uploaded_by_id,
        NOW()
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `myapp_filecategory`
--

DROP TABLE IF EXISTS `myapp_filecategory`;
CREATE TABLE IF NOT EXISTS `myapp_filecategory` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `myapp_filecategory`
--

INSERT INTO `myapp_filecategory` (`id`, `name`, `description`) VALUES
(1, 'Document', 'Words, Excel, Notes'),
(2, 'Pictures', 'PNG,JPEG,JPG,GIFF');

-- --------------------------------------------------------

--
-- Table structure for table `myapp_user`
--

DROP TABLE IF EXISTS `myapp_user`;
CREATE TABLE IF NOT EXISTS `myapp_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `email` varchar(191) NOT NULL,
  `password` varchar(128) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `is_admin` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `myapp_user`
--

INSERT INTO `myapp_user` (`id`, `username`, `email`, `password`, `first_name`, `last_name`, `is_active`, `is_admin`, `created_at`, `updated_at`) VALUES
(1, 'admin@gmail.com', 'admin@gmail.com', 'pbkdf2_sha256$1000000$U8hMc1uWkGVB8P8djntypW$7LK+OZbkVZIlOpvu+oJX9QstV0jF/+ZsoVpasCfCDaM=', 'Administrator', 'Administrator', 1, 1, '2025-06-12 07:10:59.758912', '2025-06-12 07:10:59.758952'),
(2, 'staff@gmail.com', 'staff@gmail.com', 'pbkdf2_sha256$1000000$9iEOQ6Wt0QbHwEXJZ4am7c$4ydtyo4YHP9LhvUQF/XEOA50I1h3jxIIXIgd5mazDXc=', 'Staff', 'Staff', 1, 0, '2025-06-13 16:07:14.000000', '2025-06-13 16:07:14.000000'),
(9, 'mathew619', 'mathew@gmail.com', '123', 'Mathew', 'Sacero', 0, 0, '2025-06-14 11:28:47.000000', '2025-06-14 11:28:47.000000');

--
-- Triggers `myapp_user`
--
DROP TRIGGER IF EXISTS `after_user_register`;
DELIMITER $$
CREATE TRIGGER `after_user_register` AFTER INSERT ON `myapp_user` FOR EACH ROW BEGIN
    INSERT INTO user_registration_logs (user_id, username, email, registered_at)
    VALUES (NEW.id, NEW.username, NEW.email, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_login_logs`
--

DROP TABLE IF EXISTS `user_login_logs`;
CREATE TABLE IF NOT EXISTS `user_login_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `username` varchar(150) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `login_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `user_login_logs`
--

INSERT INTO `user_login_logs` (`id`, `user_id`, `username`, `email`, `login_time`) VALUES
(1, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-13 16:51:02'),
(2, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-13 17:10:25'),
(3, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-13 17:10:43'),
(4, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-13 17:12:28'),
(5, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-14 00:08:06'),
(6, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-14 00:34:26'),
(7, 1, 'admin@gmail.com', 'admin@gmail.com', '2025-06-15 14:58:10');

-- --------------------------------------------------------

--
-- Table structure for table `user_registration_logs`
--

DROP TABLE IF EXISTS `user_registration_logs`;
CREATE TABLE IF NOT EXISTS `user_registration_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `username` varchar(150) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `registered_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `user_registration_logs`
--

INSERT INTO `user_registration_logs` (`id`, `user_id`, `username`, `email`, `registered_at`) VALUES
(1, 6, 'Zsedny619', 'zsednyvlogger@gmail.com', '2025-06-13 16:38:09'),
(2, 7, 'kz096', 'kz096@gmail.com', '2025-06-14 11:06:41'),
(3, 8, 'mathew619', 'mathew@gmail.com', '2025-06-14 11:09:55'),
(4, 9, 'mathew619', 'mathew@gmail.com', '2025-06-14 11:28:47');
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

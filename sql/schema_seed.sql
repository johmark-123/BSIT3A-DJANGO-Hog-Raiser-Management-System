-- ============================================================
-- Hog Raiser Management System - Complete Schema & Seed Data
-- MariaDB / MySQL compatible
-- Database: hog_farm
-- Run this ONCE to create all tables and seed data for the SQL exercises
-- ============================================================

USE `hog_farm`;

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- Drop existing tables (child tables first)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `farm_batchfeeddeduction`;
DROP TABLE IF EXISTS `farm_batchfeedingrecord`;
DROP TABLE IF EXISTS `farm_feedinventory`;
DROP TABLE IF EXISTS `farm_hogbatch`;
DROP TABLE IF EXISTS `farm_medicaltreatmentlog`;
DROP TABLE IF EXISTS `farm_healthtriagelog`;
DROP TABLE IF EXISTS `farm_breedingrecord`;
DROP TABLE IF EXISTS `farm_hogmedicine`;
DROP TABLE IF EXISTS `farm_ai_chat`;
DROP TABLE IF EXISTS `farm_alert`;
DROP TABLE IF EXISTS `farm_expense`;
DROP TABLE IF EXISTS `farm_inventory`;
DROP TABLE IF EXISTS `farm_medicine`;
DROP TABLE IF EXISTS `farm_health`;
DROP TABLE IF EXISTS `farm_care`;
DROP TABLE IF EXISTS `farm_feeding`;
DROP TABLE IF EXISTS `farm_weight`;
DROP TABLE IF EXISTS `farm_hog`;
DROP TABLE IF EXISTS `tblinfo`;
DROP TABLE IF EXISTS `core_loginevent`;
DROP TABLE IF EXISTS `auth_user`;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- TABLE CREATIONS
-- ============================================================

-- ------------------------------------------------------------
-- auth_user (Django built-in user table)
-- ------------------------------------------------------------
CREATE TABLE `auth_user` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `password` VARCHAR(128) NOT NULL,
    `last_login` DATETIME(6) DEFAULT NULL,
    `is_superuser` TINYINT(1) NOT NULL DEFAULT 0,
    `username` VARCHAR(150) NOT NULL UNIQUE,
    `first_name` VARCHAR(150) NOT NULL DEFAULT '',
    `last_name` VARCHAR(150) NOT NULL DEFAULT '',
    `email` VARCHAR(254) NOT NULL DEFAULT '',
    `is_staff` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `date_joined` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- core_loginevent
-- ------------------------------------------------------------
CREATE TABLE `core_loginevent` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL,
    `login_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` TEXT DEFAULT NULL,
    CONSTRAINT `fk_core_loginevent_user` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_hog
-- ------------------------------------------------------------
CREATE TABLE `farm_hog` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) DEFAULT NULL,
    `breed` VARCHAR(100) NOT NULL DEFAULT 'Crossbred',
    `sex` VARCHAR(10) NOT NULL DEFAULT 'female',
    `birth_date` DATE NOT NULL,
    `stage` VARCHAR(20) NOT NULL DEFAULT 'piglet',
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `current_weight_kg` DECIMAL(10,2) DEFAULT NULL,
    `target_weight_kg` DECIMAL(10,2) NOT NULL DEFAULT 100.00,
    `purchase_cost` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `sale_price` DECIMAL(12,2) DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_hog_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
    UNIQUE KEY `uk_owner_code` (`owner_id`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_weight
-- ------------------------------------------------------------
CREATE TABLE `farm_weight` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `hog_id` BIGINT NOT NULL,
    `date` DATE NOT NULL,
    `weight_kg` DECIMAL(10,2) NOT NULL,
    `notes` VARCHAR(255) DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_weight_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_feeding
-- ------------------------------------------------------------
CREATE TABLE `farm_feeding` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `hog_id` BIGINT NOT NULL,
    `feed_category` VARCHAR(20) NOT NULL DEFAULT 'grower',
    `feed_name` VARCHAR(120) DEFAULT NULL,
    `amount_kg_per_day` DECIMAL(10,2) NOT NULL DEFAULT 1.50,
    `feeding_date` DATE NOT NULL,
    `notes` VARCHAR(255) DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_feeding_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_care
-- ------------------------------------------------------------
CREATE TABLE `farm_care` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `hog_id` BIGINT DEFAULT NULL,
    `care_type` VARCHAR(20) NOT NULL DEFAULT 'checkup',
    `title` VARCHAR(150) NOT NULL,
    `due_date` DATE NOT NULL,
    `completed` TINYINT(1) NOT NULL DEFAULT 0,
    `completed_at` DATETIME(6) DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_care_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
    CONSTRAINT `fk_farm_care_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_health
-- ------------------------------------------------------------
CREATE TABLE `farm_health` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `hog_id` BIGINT NOT NULL,
    `reported_by_id` BIGINT NOT NULL,
    `symptoms` TEXT NOT NULL,
    `appetite` VARCHAR(20) NOT NULL DEFAULT 'normal',
    `behavior` TEXT DEFAULT NULL,
    `duration_days` INT UNSIGNED NOT NULL DEFAULT 1,
    `affected_count` INT UNSIGNED NOT NULL DEFAULT 1,
    `urgency` VARCHAR(20) NOT NULL DEFAULT 'routine',
    `ai_summary` TEXT DEFAULT NULL,
    `possible_causes` TEXT DEFAULT NULL,
    `recommended_steps` TEXT DEFAULT NULL,
    `vet_referral` TINYINT(1) NOT NULL DEFAULT 0,
    `status` VARCHAR(20) NOT NULL DEFAULT 'open',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_health_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_farm_health_reported_by` FOREIGN KEY (`reported_by_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_medicine
-- ------------------------------------------------------------
CREATE TABLE `farm_medicine` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL UNIQUE,
    `active_ingredient` VARCHAR(200) DEFAULT NULL,
    `intended_use` TEXT NOT NULL,
    `dosage_info` TEXT DEFAULT NULL,
    `precautions` TEXT DEFAULT NULL,
    `withdrawal_days` INT UNSIGNED NOT NULL DEFAULT 0,
    `prescription_required` TINYINT(1) NOT NULL DEFAULT 0,
    `interactions` TEXT DEFAULT NULL,
    `reference_source` VARCHAR(255) DEFAULT NULL,
    `stock_quantity` DOUBLE NOT NULL DEFAULT 0.0,
    `unit` VARCHAR(20) NOT NULL DEFAULT 'Bottles',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_inventory
-- ------------------------------------------------------------
CREATE TABLE `farm_inventory` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(20) NOT NULL DEFAULT 'feed',
    `quantity` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `unit` VARCHAR(30) NOT NULL DEFAULT 'kg',
    `low_stock_threshold` DECIMAL(10,2) NOT NULL DEFAULT 5.00,
    `expiry_date` DATE DEFAULT NULL,
    `unit_cost` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_inventory_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_expense
-- ------------------------------------------------------------
CREATE TABLE `farm_expense` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `hog_id` BIGINT DEFAULT NULL,
    `category` VARCHAR(20) NOT NULL DEFAULT 'feed',
    `amount` DECIMAL(12,2) NOT NULL,
    `expense_date` DATE NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_expense_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
    CONSTRAINT `fk_farm_expense_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_alert
-- ------------------------------------------------------------
CREATE TABLE `farm_alert` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `hog_id` BIGINT DEFAULT NULL,
    `alert_type` VARCHAR(30) NOT NULL DEFAULT 'info',
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `recommended_action` TEXT DEFAULT NULL,
    `severity` VARCHAR(20) NOT NULL DEFAULT 'info',
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `is_resolved` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_alert_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
    CONSTRAINT `fk_farm_alert_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_ai_chat
-- ------------------------------------------------------------
CREATE TABLE `farm_ai_chat` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT NOT NULL,
    `hog_id` BIGINT DEFAULT NULL,
    `question` TEXT NOT NULL,
    `answer` TEXT NOT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_ai_chat_owner` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
    CONSTRAINT `fk_farm_ai_chat_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_hogmedicine
-- ------------------------------------------------------------
CREATE TABLE `farm_hogmedicine` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `hog_id` BIGINT NOT NULL,
    `medicine_id` BIGINT NOT NULL,
    `health_report_id` BIGINT DEFAULT NULL,
    `administered_date` DATE NOT NULL,
    `dosage` VARCHAR(120) DEFAULT NULL,
    `route` VARCHAR(20) NOT NULL DEFAULT 'oral',
    `notes` TEXT DEFAULT NULL,
    `withdrawal_until` DATE DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `administered_by_id` BIGINT DEFAULT NULL,
    CONSTRAINT `fk_farm_hogmedicine_hog` FOREIGN KEY (`hog_id`) REFERENCES `farm_hog` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_farm_hogmedicine_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `farm_medicine` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_farm_hogmedicine_health_report` FOREIGN KEY (`health_report_id`) REFERENCES `farm_health` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_farm_hogmedicine_administered_by` FOREIGN KEY (`administered_by_id`) REFERENCES `auth_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_breedingrecord
-- ------------------------------------------------------------
CREATE TABLE `farm_breedingrecord` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `sow_id` BIGINT NOT NULL,
    `mating_date` DATE NOT NULL,
    `expected_farrowing_date` DATE DEFAULT NULL,
    `actual_farrowing_date` DATE DEFAULT NULL,
    `litter_size` INT DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'Pregnant',
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_breedingrecord_sow` FOREIGN KEY (`sow_id`) REFERENCES `farm_hog` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_healthtriagelog
-- ------------------------------------------------------------
CREATE TABLE `farm_healthtriagelog` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `pig_tag` VARCHAR(50) DEFAULT NULL,
    `symptoms` TEXT NOT NULL,
    `ai_recommendation` TEXT DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `consulted_by_id` BIGINT DEFAULT NULL,
    CONSTRAINT `fk_farm_healthtriagelog_consulted_by` FOREIGN KEY (`consulted_by_id`) REFERENCES `auth_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_hogbatch
-- ------------------------------------------------------------
CREATE TABLE `farm_hogbatch` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `initial_total_weight` DOUBLE NOT NULL,
    `current_total_weight` DOUBLE NOT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_batchfeedingrecord
-- ------------------------------------------------------------
CREATE TABLE `farm_batchfeedingrecord` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `batch_id` BIGINT NOT NULL,
    `date` DATE NOT NULL,
    `quantity_kg` DOUBLE NOT NULL,
    `feed_type` VARCHAR(50) NOT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT `fk_farm_batchfeedingrecord_batch` FOREIGN KEY (`batch_id`) REFERENCES `farm_hogbatch` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_feedinventory
-- ------------------------------------------------------------
CREATE TABLE `farm_feedinventory` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `feed_type` VARCHAR(50) NOT NULL UNIQUE,
    `quantity_kg` DOUBLE NOT NULL DEFAULT 0.0,
    `reorder_level` DOUBLE NOT NULL DEFAULT 50.0,
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_batchfeeddeduction
-- ------------------------------------------------------------
CREATE TABLE `farm_batchfeeddeduction` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `batch_id` BIGINT NOT NULL,
    `feed_inventory_id` BIGINT NOT NULL,
    `quantity_kg` DOUBLE NOT NULL,
    `date` DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT `fk_farm_batchfeeddeduction_batch` FOREIGN KEY (`batch_id`) REFERENCES `farm_hogbatch` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_farm_batchfeeddeduction_feed_inventory` FOREIGN KEY (`feed_inventory_id`) REFERENCES `farm_feedinventory` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- farm_medicaltreatmentlog
-- ------------------------------------------------------------
CREATE TABLE `farm_medicaltreatmentlog` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `pig_or_batch` VARCHAR(100) NOT NULL,
    `medicine_id` BIGINT NOT NULL,
    `quantity_used` DOUBLE NOT NULL,
    `date_administered` DATE NOT NULL,
    `notes` TEXT DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `administered_by_id` BIGINT DEFAULT NULL,
    CONSTRAINT `fk_farm_medicaltreatmentlog_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `farm_medicine` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_farm_medicaltreatmentlog_administered_by` FOREIGN KEY (`administered_by_id`) REFERENCES `auth_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tblinfo
-- ------------------------------------------------------------
CREATE TABLE `tblinfo` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `age` INT UNSIGNED NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) DEFAULT NULL,
    `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    `user_id` BIGINT DEFAULT NULL,
    CONSTRAINT `fk_tblinfo_user` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- SEED DATA
-- ============================================================

-- ------------------------------------------------------------
-- auth_user (ids: 1=admin, 3=farmuser3, 5=farmuser5, plus nohogs user)
-- ------------------------------------------------------------
INSERT INTO `auth_user` (`password`, `last_login`, `is_superuser`, `username`, `first_name`, `last_name`, `email`, `is_staff`, `is_active`, `date_joined`) VALUES
('pbkdf2_sha256$260000$dummy$hashplaceholder', NULL, 1, 'admin', 'Admin', 'User', 'admin@hogfarm.com', 1, 1, NOW()),
('pbkdf2_sha256$260000$dummy$hashplaceholder', NULL, 0, 'farmuser3', 'Juan', 'Dela Cruz', 'juan3@hogfarm.com', 0, 1, NOW()),
('pbkdf2_sha256$260000$dummy$hashplaceholder', NULL, 0, 'farmuser5', 'Maria', 'Santos', 'maria5@hogfarm.com', 0, 1, NOW()),
('pbkdf2_sha256$260000$dummy$hashplaceholder', NULL, 0, 'nohogs', 'No Hogs', 'User', 'nohogs@hogfarm.com', 0, 1, NOW());

-- ------------------------------------------------------------
-- core_loginevent
-- ------------------------------------------------------------
INSERT INTO `core_loginevent` (`user_id`, `login_at`, `ip_address`, `user_agent`) VALUES
(3, '2026-01-10 08:00:00', '192.168.1.10', 'Mozilla/5.0 Chrome'),
(3, '2026-01-11 09:00:00', '192.168.1.10', 'Mozilla/5.0 Chrome'),
(5, '2026-01-10 09:00:00', '192.168.1.20', 'Mozilla/5.0 Firefox'),
(5, '2026-01-12 10:00:00', '192.168.1.20', 'Mozilla/5.0 Firefox'),
(1, '2026-01-09 07:00:00', '192.168.1.30', 'Mozilla/5.0 Safari');

-- ------------------------------------------------------------
-- farm_hog (ids 1-35; includes hog 11 and hog 33)
-- ------------------------------------------------------------
INSERT INTO `farm_hog` (`id`, `owner_id`, `code`, `name`, `breed`, `sex`, `birth_date`, `stage`, `status`, `current_weight_kg`, `target_weight_kg`, `purchase_cost`, `sale_price`, `notes`) VALUES
(1,  3, 'ET-001', 'Piglet One', 'Duroc', 'female', '2026-01-10', 'piglet', 'active', 5.00, 100.00, 500.00, NULL, 'Demo piglet 1'),
(2,  3, 'ET-002', 'Piglet Two', 'Landrace', 'female', '2026-01-12', 'piglet', 'active', 6.00, 100.00, 500.00, NULL, 'Demo piglet 2'),
(3,  3, 'ET-003', 'Piglet Three', 'Yorkshire', 'male', '2026-01-15', 'piglet', 'active', 5.50, 100.00, 500.00, NULL, 'Demo piglet 3'),
(4,  5, 'ET-004', 'Grower A', 'Duroc', 'female', '2025-11-01', 'grower', 'active', 45.00, 100.00, 1200.00, NULL, 'Demo grower A'),
(5,  5, 'ET-005', 'Grower B', 'Crossbred', 'male', '2025-11-05', 'grower', 'active', 48.00, 100.00, 1200.00, NULL, 'Demo grower B'),
(6,  5, 'ET-006', 'Finisher A', 'Duroc', 'female', '2025-09-01', 'finisher', 'active', 90.00, 100.00, 1500.00, NULL, 'Demo finisher A'),
(7,  5, 'ET-007', 'Finisher B', 'Landrace', 'male', '2025-09-10', 'finisher', 'active', 95.00, 100.00, 1500.00, NULL, 'Demo finisher B'),
(8,  3, 'ET-008', 'Sold Hog', 'Yorkshire', 'female', '2025-06-01', 'market_ready', 'sold', 110.00, 100.00, 1000.00, 1800.00, 'Already sold'),
(9,  3, 'ET-009', 'Sold Hog 2', 'Crossbred', 'male', '2025-06-05', 'market_ready', 'sold', 105.00, 100.00, 1000.00, 1700.00, 'Already sold 2'),
(10, 5, 'ET-010', 'Active Hog 10', 'Duroc', 'female', '2025-10-01', 'grower', 'active', 50.00, 100.00, 1300.00, NULL, 'Demo hog 10'),
(11, 5, 'ET-011', 'Demo Hog 11', 'Duroc', 'female', '2025-08-01', 'finisher', 'active', 85.00, 100.00, 1400.00, NULL, 'Referenced in UPDATE/INSERT exercises'),
(12, 3, 'ET-012', 'Hog 12', 'Landrace', 'male', '2026-02-01', 'weaner', 'active', 20.00, 100.00, 600.00, NULL, 'Demo hog 12'),
(13, 3, 'ET-013', 'Hog 13', 'Yorkshire', 'female', '2026-02-05', 'weaner', 'active', 22.00, 100.00, 600.00, NULL, 'Demo hog 13'),
(14, 5, 'ET-014', 'Hog 14', 'Crossbred', 'female', '2025-12-01', 'grower', 'active', 40.00, 100.00, 1100.00, NULL, 'Demo hog 14'),
(15, 5, 'ET-015', 'Hog 15', 'Duroc', 'male', '2025-12-05', 'grower', 'active', 42.00, 100.00, 1100.00, NULL, 'Demo hog 15'),
(16, 3, 'ET-016', 'Hog 16', 'Landrace', 'female', '2026-03-01', 'piglet', 'active', 8.00, 100.00, 550.00, NULL, 'Demo hog 16'),
(17, 3, 'ET-017', 'Hog 17', 'Yorkshire', 'male', '2026-03-05', 'piglet', 'active', 9.00, 100.00, 550.00, NULL, 'Demo hog 17'),
(18, 5, 'ET-018', 'Hog 18', 'Crossbred', 'female', '2026-01-20', 'weaner', 'active', 25.00, 100.00, 650.00, NULL, 'Demo hog 18'),
(19, 5, 'ET-019', 'Hog 19', 'Duroc', 'male', '2026-01-25', 'weaner', 'active', 26.00, 100.00, 650.00, NULL, 'Demo hog 19'),
(20, 3, 'ET-020', 'Hog 20', 'Landrace', 'female', '2026-04-01', 'piglet', 'active', 4.00, 100.00, 500.00, NULL, 'Demo hog 20'),
(21, 3, 'ET-021', 'Hog 21', 'Yorkshire', 'male', '2026-04-05', 'piglet', 'active', 4.50, 100.00, 500.00, NULL, 'Demo hog 21'),
(22, 5, 'ET-022', 'Hog 22', 'Crossbred', 'female', '2025-11-15', 'grower', 'active', 55.00, 100.00, 1250.00, NULL, 'Demo hog 22'),
(23, 5, 'ET-023', 'Hog 23', 'Duroc', 'male', '2025-11-20', 'grower', 'active', 58.00, 100.00, 1250.00, NULL, 'Demo hog 23'),
(24, 3, 'ET-024', 'Hog 24', 'Landrace', 'female', '2026-05-01', 'piglet', 'active', 3.00, 100.00, 480.00, NULL, 'Demo hog 24'),
(25, 3, 'ET-025', 'Hog 25', 'Yorkshire', 'male', '2026-05-05', 'piglet', 'active', 3.50, 100.00, 480.00, NULL, 'Demo hog 25'),
(26, 5, 'ET-026', 'Hog 26', 'Crossbred', 'female', '2025-10-10', 'finisher', 'active', 92.00, 100.00, 1450.00, NULL, 'Demo hog 26'),
(27, 5, 'ET-027', 'Hog 27', 'Duroc', 'male', '2025-10-15', 'finisher', 'active', 94.00, 100.00, 1450.00, NULL, 'Demo hog 27'),
(28, 3, 'ET-028', 'Hog 28', 'Landrace', 'female', '2026-06-01', 'piglet', 'active', 2.50, 100.00, 450.00, NULL, 'Demo hog 28'),
(29, 3, 'ET-029', 'Hog 29', 'Yorkshire', 'male', '2026-06-05', 'piglet', 'active', 2.80, 100.00, 450.00, NULL, 'Demo hog 29'),
(30, 5, 'ET-030', 'Hog 30', 'Crossbred', 'female', '2025-09-20', 'finisher', 'active', 88.00, 100.00, 1380.00, NULL, 'Demo hog 30'),
(31, 5, 'ET-031', 'Hog 31', 'Duroc', 'male', '2025-09-25', 'finisher', 'active', 91.00, 100.00, 1380.00, NULL, 'Demo hog 31'),
(32, 3, 'ET-032', 'Hog 32', 'Landrace', 'female', '2026-07-01', 'piglet', 'active', 1.50, 100.00, 420.00, NULL, 'Demo hog 32'),
(33, 3, 'ET-033', 'Demo Hog 33', 'Yorkshire', 'female', '2026-07-05', 'piglet', 'active', 1.80, 100.00, 420.00, NULL, 'Referenced in INSERT exercises'),
(34, 5, 'ET-034', 'Hog 34', 'Crossbred', 'female', '2025-08-10', 'grower', 'active', 60.00, 100.00, 1300.00, NULL, 'Demo hog 34'),
(35, 5, 'ET-035', 'Hog 35', 'Duroc', 'male', '2025-08-15', 'grower', 'active', 62.00, 100.00, 1300.00, NULL, 'Demo hog 35');

-- ------------------------------------------------------------
-- farm_weight (ids 1-30; id 10 has NULL weight for IFNULL demo; id 25 has NULL date)
-- ------------------------------------------------------------
INSERT INTO `farm_weight` (`id`, `hog_id`, `date`, `weight_kg`, `notes`) VALUES
(1,  1, '2026-01-10', 5.00, 'Initial weight'),
(2,  1, '2026-01-17', 5.50, 'Week 1'),
(3,  4, '2025-11-01', 30.00, 'Initial weight'),
(4,  4, '2025-11-08', 35.00, 'Week 1'),
(5,  6, '2025-09-01', 70.00, 'Initial weight'),
(6,  6, '2025-09-08', 78.00, 'Week 1'),
(7,  8, '2025-06-01', 95.00, 'Initial weight'),
(8,  8, '2025-06-15', 110.00, 'Market weight'),
(9,  10, '2025-10-01', 40.00, 'Initial weight'),
(10, 11, NULL, NULL, 'Weight record 10 - NULL weight for IFNULL demo'),
(11, 11, '2025-08-15', 85.00, 'Week 1'),
(12, 11, '2025-08-22', 90.00, 'Week 2'),
(13, 12, '2026-02-01', 15.00, 'Initial weight'),
(14, 12, '2026-02-08', 18.00, 'Week 1'),
(15, 13, '2026-02-05', 18.00, 'Initial weight'),
(16, 13, '2026-02-12', 20.00, 'Week 1'),
(17, 14, '2025-12-01', 35.00, 'Initial weight'),
(18, 14, '2025-12-08', 40.00, 'Week 1'),
(19, 15, '2025-12-05', 38.00, 'Initial weight'),
(20, 15, '2025-12-12', 42.00, 'Week 1'),
(21, 16, '2026-03-01', 5.00, 'Initial weight'),
(22, 16, '2026-03-08', 6.00, 'Week 1'),
(23, 17, '2026-03-05', 6.00, 'Initial weight'),
(24, 17, '2026-03-12', 7.00, 'Week 1'),
(25, 18, NULL, 20.00, 'Weight record 25 - NULL date for UPDATE demo'),
(26, 18, '2026-01-27', 24.00, 'Week 1'),
(27, 19, '2026-01-25', 22.00, 'Initial weight'),
(28, 19, '2026-02-01', 25.00, 'Week 1'),
(29, 20, '2026-04-01', 3.00, 'Initial weight'),
(30, 20, '2026-04-08', 3.80, 'Week 1');

-- ------------------------------------------------------------
-- farm_care (ids 1-15; includes care log 13)
-- ------------------------------------------------------------
INSERT INTO `farm_care` (`id`, `owner_id`, `hog_id`, `care_type`, `title`, `due_date`, `completed`, `completed_at`, `notes`, `created_at`) VALUES
(1,  3, 1,  'checkup', 'Initial Checkup', '2026-01-15', 1, '2026-01-15 08:00:00', 'Healthy piglet', '2026-01-10 08:00:00'),
(2,  3, 2,  'vaccine', 'First Vaccination', '2026-01-20', 1, '2026-01-20 09:00:00', 'PCV2 vaccine', '2026-01-10 09:00:00'),
(3,  3, 3,  'deworming', 'Deworming Schedule', '2026-01-25', 0, NULL, 'Due soon', '2026-01-10 10:00:00'),
(4,  5, 4,  'feeding', 'Feeding Schedule', '2025-11-05', 1, '2025-11-05 07:00:00', 'Morning feed', '2025-11-01 07:00:00'),
(5,  5, 5,  'feeding', 'Feeding Schedule', '2025-11-06', 1, '2025-11-06 07:00:00', 'Evening feed', '2025-11-01 07:00:00'),
(6,  5, 6,  'checkup', 'Growth Check', '2025-09-05', 1, '2025-09-05 08:00:00', 'Good progress', '2025-09-01 08:00:00'),
(7,  5, 7,  'vaccine', 'Booster Shot', '2025-09-15', 0, NULL, 'Pending', '2025-09-01 09:00:00'),
(8,  3, 8,  'checkup', 'Pre-sale Check', '2025-06-10', 1, '2025-06-10 10:00:00', 'Fit for market', '2025-06-01 10:00:00'),
(9,  3, 9,  'checkup', 'Pre-sale Check', '2025-06-15', 1, '2025-06-15 10:00:00', 'Fit for market', '2025-06-05 10:00:00'),
(10, 5, 10, 'feeding', 'Daily Feed', '2025-10-05', 1, '2025-10-05 07:00:00', 'Starter feed', '2025-10-01 07:00:00'),
(11, 5, 11, 'feeding', 'Daily Feed 11', '2025-08-05', 1, '2025-08-05 07:00:00', 'Finisher feed', '2025-08-01 07:00:00'),
(12, 3, 12, 'vitamin', 'Vitamin Supplement', '2026-02-05', 0, NULL, 'Vitamin B12', '2026-02-01 08:00:00'),
(13, 3, 13, 'checkup', 'Care Log 13', '2026-02-10', 0, NULL, 'Care log 13 for LOWER() demo', '2026-02-05 08:00:00'),
(14, 5, 14, 'deworming', 'Deworming', '2025-12-10', 0, NULL, 'Scheduled', '2025-12-01 09:00:00'),
(15, 5, 15, 'vaccine', 'Vaccination', '2025-12-15', 0, NULL, 'Scheduled', '2025-12-05 09:00:00');

-- ------------------------------------------------------------
-- farm_health (ids 1-15; includes health report 13)
-- ------------------------------------------------------------
INSERT INTO `farm_health` (`id`, `hog_id`, `reported_by_id`, `symptoms`, `appetite`, `behavior`, `duration_days`, `affected_count`, `urgency`, `ai_summary`, `possible_causes`, `recommended_steps`, `vet_referral`, `status`, `created_at`) VALUES
(1,  1, 3, 'Coughing', 'reduced', 'Lethargic', 2, 1, 'needs_attention', 'Possible respiratory infection', 'Bordetella', 'Isolate and monitor', 0, 'open', '2026-01-12 10:00:00'),
(2,  2, 3, 'Diarrhea', 'loss', 'Lethargic', 1, 1, 'urgent', 'Possible digestive issue', 'E. coli', 'Immediate vet care', 1, 'open', '2026-01-13 11:00:00'),
(3,  3, 3, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2026-01-14 09:00:00'),
(4,  4, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-11-03 08:00:00'),
(5,  5, 5, 'Sneezing', 'normal', 'Active', 1, 1, 'routine', 'Mild irritation', 'Dust', 'Improve ventilation', 0, 'monitoring', '2025-11-04 09:00:00'),
(6,  6, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-09-03 10:00:00'),
(7,  7, 5, 'Limping', 'normal', 'Reluctant to move', 3, 1, 'needs_attention', 'Possible leg injury', 'Trauma', 'Rest and observe', 0, 'open', '2025-09-08 10:00:00'),
(8,  8, 3, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'N/A', 0, 'resolved', '2025-06-02 10:00:00'),
(9,  9, 3, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'N/A', 0, 'resolved', '2025-06-06 10:00:00'),
(10, 10, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-10-03 08:00:00'),
(11, 11, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-08-03 08:00:00'),
(12, 12, 3, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2026-02-03 08:00:00'),
(13, 13, 3, 'RESPIRATORY SYMPTOMS DETECTED', 'reduced', 'Lethargic', 2, 1, 'needs_attention', 'Possible respiratory infection', 'Bordetella', 'Isolate and monitor', 0, 'open', '2026-02-07 10:00:00'),
(14, 14, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-12-03 08:00:00'),
(15, 15, 5, 'None', 'normal', 'Active', 0, 1, 'routine', 'Healthy', 'None', 'Continue monitoring', 0, 'resolved', '2025-12-07 08:00:00');

-- ------------------------------------------------------------
-- farm_medicine (ids 1-10; includes medicine 7)
-- ------------------------------------------------------------
INSERT INTO `farm_medicine` (`id`, `name`, `active_ingredient`, `intended_use`, `dosage_info`, `precautions`, `withdrawal_days`, `prescription_required`, `interactions`, `reference_source`, `stock_quantity`, `unit`) VALUES
(1,  'Amoxicillin', 'Amoxicillin trihydrate', 'Antibiotic for bacterial infections', '15 mg/kg IM', 'Observe withdrawal period', 5, 1, 'None', 'Vet Handbook', 100.0, 'Bottles'),
(2,  'Ivermectin', 'Ivermectin', 'Antiparasitic', '0.2 mg/kg oral', 'Do not use in lactating sows', 14, 0, 'None', 'Vet Handbook', 50.0, 'Bottles'),
(3,  'Oxytetracycline', 'Oxytetracycline', 'Broad-spectrum antibiotic', '10 mg/kg IM', 'Withdrawal required', 7, 1, 'None', 'Vet Handbook', 75.0, 'Bottles'),
(4,  'Vitamin B12', 'Cobalamin', 'Vitamin supplement', '1 mL IM', 'None', 0, 0, 'None', 'Supplement Guide', 200.0, 'Vials'),
(5,  'Electrolytes', 'Electrolyte mix', 'Dehydration treatment', 'Add to water', 'None', 0, 0, 'None', 'Supplement Guide', 300.0, 'Packets'),
(6,  'Meloxicam', 'Meloxicam', 'Anti-inflammatory', '0.5 mg/kg IM', 'Withdrawal required', 3, 1, 'None', 'Vet Handbook', 60.0, 'Bottles'),
(7,  'Penicillin', 'Penicillin G', 'Antibiotic', '20,000 IU/kg IM', 'Withdrawal required', 10, 1, 'None', 'Vet Handbook', 80.0, 'Bottles'),
(8,  'Dewormer Plus', 'Fenbendazole', 'Deworming', '5 mg/kg oral', 'None', 7, 0, 'None', 'Vet Handbook', 90.0, 'Bottles'),
(9,  'Iron Dextran', 'Iron dextran', 'Iron supplement for piglets', '200 mg IM', 'None', 0, 0, 'None', 'Supplement Guide', 120.0, 'Vials'),
(10, 'Electro-V', 'Electrolyte + Vitamin C', 'Stress support', 'Add to water', 'None', 0, 0, 'None', 'Supplement Guide', 250.0, 'Packets');

-- ------------------------------------------------------------
-- farm_expense (ids 1-10)
-- ------------------------------------------------------------
INSERT INTO `farm_expense` (`id`, `owner_id`, `hog_id`, `category`, `amount`, `expense_date`, `description`, `created_at`) VALUES
(1,  3, 1, 'feed', 50.00, '2026-01-10', 'Piglet starter feed', '2026-01-10 08:00:00'),
(2,  3, 1, 'medicine', 25.00, '2026-01-12', 'Amoxicillin treatment', '2026-01-12 09:00:00'),
(3,  5, 4, 'feed', 80.00, '2025-11-01', 'Grower feed', '2025-11-01 08:00:00'),
(4,  5, 4, 'veterinary', 100.00, '2025-11-03', 'Vet consultation', '2025-11-03 10:00:00'),
(5,  5, 6, 'feed', 120.00, '2025-09-01', 'Finisher feed', '2025-09-01 08:00:00'),
(6,  5, 6, 'medicine', 35.00, '2025-09-03', 'Vitamin supplement', '2025-09-03 09:00:00'),
(7,  3, 8, 'feed', 90.00, '2025-06-01', 'Market hog feed', '2025-06-01 08:00:00'),
(8,  3, 9, 'feed', 85.00, '2025-06-05', 'Market hog feed', '2025-06-05 08:00:00'),
(9,  5, 10, 'feed', 70.00, '2025-10-01', 'Grower feed', '2025-10-01 08:00:00'),
(10, 5, 11, 'feed', 75.00, '2025-08-01', 'Finisher feed', '2025-08-01 08:00:00');

-- ------------------------------------------------------------
-- farm_inventory (ids 1-6; items 5 and 6 owned by user 3 with no expenses for NOT EXISTS demo)
-- ------------------------------------------------------------
INSERT INTO `farm_inventory` (`id`, `owner_id`, `name`, `category`, `quantity`, `unit`, `low_stock_threshold`, `expiry_date`, `unit_cost`, `updated_at`) VALUES
(1,  3, 'Piglet Starter Feed', 'feed', 100.00, 'kg', 20.00, '2026-12-31', 1.50, '2026-01-10 08:00:00'),
(2,  3, 'Vitamin B12', 'vitamin', 50.00, 'vials', 10.00, '2026-12-31', 5.00, '2026-01-10 09:00:00'),
(3,  5, 'Grower Feed', 'feed', 200.00, 'kg', 30.00, '2026-12-31', 1.40, '2025-11-01 08:00:00'),
(4,  5, 'Finisher Feed', 'feed', 150.00, 'kg', 30.00, '2026-12-31', 1.30, '2025-09-01 08:00:00'),
(5,  3, 'Old Medicine', 'medicine', 0.00, 'bottles', 5.00, '2025-12-31', 10.00, '2025-06-01 08:00:00'),
(6,  3, 'Expired Feed', 'feed', 0.00, 'kg', 10.00, '2025-12-31', 1.00, '2025-06-05 08:00:00');

-- ------------------------------------------------------------
-- farm_alert (ids 1-10 plus 35, 97, 98, 135; completed alerts before 2026-10-20; sold hog alerts)
-- ------------------------------------------------------------
INSERT INTO `farm_alert` (`id`, `owner_id`, `hog_id`, `alert_type`, `title`, `message`, `recommended_action`, `severity`, `is_read`, `is_resolved`, `created_at`) VALUES
(1,  3, 8,  'market_ready', 'Hog Ready for Market', 'Hog ET-008 has reached market weight', 'Prepare for sale', 'info', 1, 1, '2025-06-15 08:00:00'),
(2,  3, 9,  'market_ready', 'Hog Ready for Market', 'Hog ET-009 has reached market weight', 'Prepare for sale', 'info', 1, 1, '2025-06-20 08:00:00'),
(3,  5, 4,  'care_due', 'Care Due', 'Feeding schedule overdue for ET-004', 'Complete feeding record', 'warning', 0, 0, '2025-11-06 08:00:00'),
(4,  5, 6,  'health_concern', 'Limping Detected', 'Hog ET-006 showing signs of leg injury', 'Rest and observe', 'warning', 0, 0, '2025-09-08 10:00:00'),
(5,  3, 1,  'health_concern', 'Respiratory Issue', 'Piglet ET-001 coughing', 'Isolate and monitor', 'critical', 0, 0, '2026-01-12 10:00:00'),
(6,  5, 11, 'growth_slow', 'Slow Growth', 'Hog ET-011 gaining weight slowly', 'Review feed ration', 'warning', 0, 0, '2025-08-10 08:00:00'),
(7,  3, 2,  'health_concern', 'Diarrhea Alert', 'Piglet ET-002 has diarrhea', 'Immediate vet care', 'critical', 0, 0, '2026-01-13 11:00:00'),
(8,  5, 7,  'care_due', 'Vaccine Due', 'Booster shot for ET-007', 'Administer vaccine', 'warning', 0, 0, '2025-09-15 09:00:00'),
(9,  3, NULL, 'low_stock', 'Low Stock Alert', 'Piglet starter feed running low', 'Reorder feed', 'warning', 0, 0, '2026-01-08 08:00:00'),
(10, 5, NULL, 'info', 'General Info', 'Farm management reminder', 'Review dashboard', 'info', 0, 0, '2026-01-05 08:00:00'),
-- Alerts 35, 97, 98, 135 for UPDATE/DELETE exercises
(35, 3, 1, 'health_concern', 'Respiratory Alert', 'The pig shows respiratory symptoms needing attention', 'Isolate and monitor', 'critical', 0, 0, '2026-01-12 10:00:00'),
(97, 3, 2, 'health_concern', 'Pending Alert', 'This is a pending alert for demo purposes', 'Review and resolve', 'warning', 0, 0, '2026-01-13 11:00:00'),
(98, 5, 4, 'care_due', 'Pending Care Alert', 'Care task overdue', 'Complete the task', 'warning', 0, 0, '2025-11-06 08:00:00'),
(135, 5, 6, 'info', 'Demo Consultation', 'AI consultation demo question', 'Review AI answer', 'info', 0, 0, '2025-09-03 10:00:00'),
-- Completed alerts before 2026-10-20 for DELETE 1
(20, 3, NULL, 'info', 'Old Completed Alert 1', 'Completed alert before Oct 20', 'N/A', 'info', 1, 1, '2026-10-15 08:00:00'),
(21, 3, NULL, 'info', 'Old Completed Alert 2', 'Completed alert before Oct 20', 'N/A', 'info', 1, 1, '2026-10-18 08:00:00'),
-- Additional sold hog alerts for DELETE 4
(30, 3, 8, 'info', 'Sold Hog Alert 1', 'Alert for sold hog', 'N/A', 'info', 1, 1, '2025-06-20 08:00:00'),
(31, 3, 9, 'info', 'Sold Hog Alert 2', 'Alert for sold hog', 'N/A', 'info', 1, 1, '2025-06-25 08:00:00'),
(32, 3, 8, 'info', 'Sold Hog Alert A', 'msg', 'info', 1, 1, '2025-06-21 08:00:00'),
(33, 3, 8, 'info', 'Sold Hog Alert B', 'msg', 'info', 1, 1, '2025-06-22 08:00:00'),
(34, 3, 9, 'info', 'Sold Hog Alert C', 'msg', 'info', 1, 1, '2025-06-26 08:00:00'),
(36, 3, 9, 'info', 'Sold Hog Alert D', 'msg', 'info', 1, 1, '2025-06-27 08:00:00');

-- ------------------------------------------------------------
-- farm_ai_chat (ids 1-5 plus 10 (Demo pattern) and 135)
-- ------------------------------------------------------------
INSERT INTO `farm_ai_chat` (`id`, `owner_id`, `hog_id`, `question`, `answer`, `created_at`) VALUES
(1,  3, 1, 'Why is my piglet coughing?', 'Possible respiratory infection. Isolate and consult a vet.', '2026-01-12 10:30:00'),
(2,  3, 2, 'What to do for diarrhea?', 'Provide electrolytes and contact vet immediately.', '2026-01-13 11:30:00'),
(3,  5, 4, 'Best feed for growers?', 'Use grower feed with 16% protein.', '2025-11-01 08:30:00'),
(4,  5, 6, 'When to market finishers?', 'At 100-110 kg live weight.', '2025-09-01 08:30:00'),
(5,  3, NULL, 'Vaccination schedule?', 'Follow your vet\'s recommended schedule.', '2026-01-05 08:30:00'),
-- AI consultations starting with 'Demo' for DELETE 5
(10, 3, NULL, 'Demo question about pigs', 'Demo answer placeholder', '2026-01-01 08:00:00'),
-- AI consultation 135 for UPDATE 10 LPAD demo
(135, 5, 6, 'Why is my finisher growing slowly?', 'Check feed quality and health status.', '2025-09-03 10:30:00');

-- ------------------------------------------------------------
-- farm_hogbatch (ids 1-8; includes batch 3 and batch 8)
-- ------------------------------------------------------------
INSERT INTO `farm_hogbatch` (`id`, `name`, `initial_total_weight`, `current_total_weight`) VALUES
(1,  'Grower Batch 1', 300.0, 340.0),
(2,  'Finisher Batch 1', 400.0, 480.0),
(3,  'Demo Batch 3', 350.0, 380.0),
(4,  'Breeder Batch 1', 500.0, 520.0),
(5,  'Weaner Batch 1', 200.0, 240.0),
(6,  'Grower Batch 2', 320.0, 360.0),
(7,  'Finisher Batch 2', 380.0, 450.0),
(8,  'Demo Batch 8', 360.0, 400.0);

-- ------------------------------------------------------------
-- farm_batchfeedingrecord
-- ------------------------------------------------------------
INSERT INTO `farm_batchfeedingrecord` (`id`, `batch_id`, `date`, `quantity_kg`, `feed_type`) VALUES
(1,  3, '2026-01-01', 50.0, 'Grower'),
(2,  3, '2026-01-02', 50.0, 'Grower'),
(3,  8, '2026-01-01', 60.0, 'Finisher'),
(4,  8, '2026-01-02', 60.0, 'Finisher'),
(5,  1, '2026-01-01', 40.0, 'Starter');

-- ------------------------------------------------------------
-- farm_feedinventory
-- ------------------------------------------------------------
INSERT INTO `farm_feedinventory` (`id`, `feed_type`, `quantity_kg`, `reorder_level`) VALUES
(1,  'Pre-Starter', 100.0, 50.0),
(2,  'Starter', 200.0, 50.0),
(3,  'Grower', 150.0, 50.0),
(4,  'Finisher', 180.0, 50.0),
(5,  'Breeder', 120.0, 50.0);

-- ------------------------------------------------------------
-- farm_batchfeeddeduction
-- ------------------------------------------------------------
INSERT INTO `farm_batchfeeddeduction` (`id`, `batch_id`, `feed_inventory_id`, `quantity_kg`, `date`) VALUES
(1,  3, 3, 25.0, '2026-01-01'),
(2,  8, 4, 30.0, '2026-01-01');

-- ------------------------------------------------------------
-- farm_medicaltreatmentlog
-- ------------------------------------------------------------
INSERT INTO `farm_medicaltreatmentlog` (`id`, `pig_or_batch`, `medicine_id`, `quantity_used`, `date_administered`, `notes`, `administered_by_id`) VALUES
(1,  'ET-001', 1, 5.0, '2026-01-12', 'Antibiotic treatment for piglet', 3),
(2,  'ET-002', 3, 10.0, '2026-01-13', 'Antibiotic for diarrhea', 3),
(3,  'Batch 3', 7, 20.0, '2026-01-15', 'Penicillin for batch', 5);

-- ------------------------------------------------------------
-- farm_hogmedicine
-- ------------------------------------------------------------
INSERT INTO `farm_hogmedicine` (`id`, `hog_id`, `medicine_id`, `health_report_id`, `administered_date`, `dosage`, `route`, `notes`, `administered_by_id`) VALUES
(1,  1, 1, 1, '2026-01-12', '15 mg/kg', 'injection', 'Amoxicillin for respiratory', 3),
(2,  2, 3, 2, '2026-01-13', '10 mg/kg', 'injection', 'Oxytetracycline for diarrhea', 3);

-- ------------------------------------------------------------
-- farm_breedingrecord
-- ------------------------------------------------------------
INSERT INTO `farm_breedingrecord` (`id`, `sow_id`, `mating_date`, `expected_farrowing_date`, `actual_farrowing_date`, `litter_size`, `status`) VALUES
(1,  4, '2025-10-01', '2026-01-23', '2026-01-24', 10, 'Farrowed'),
(2,  14, '2025-12-01', '2026-03-25', NULL, NULL, 'Pregnant');

-- ------------------------------------------------------------
-- farm_healthtriagelog
-- ------------------------------------------------------------
INSERT INTO `farm_healthtriagelog` (`id`, `pig_tag`, `symptoms`, `ai_recommendation`, `consulted_by_id`) VALUES
(1,  'ET-001', 'Coughing, reduced appetite', 'Isolate and monitor for respiratory infection', 3),
(2,  'ET-002', 'Diarrhea, lethargic', 'Immediate vet care recommended', 3);

-- ------------------------------------------------------------
-- tblinfo
-- ------------------------------------------------------------
INSERT INTO `tblinfo` (`id`, `name`, `age`, `address`, `email`, `user_id`) VALUES
(1,  'Juan Dela Cruz', 25, 'Brgy. Tan-aw, Kabankalan City', 'juan3@hogfarm.com', 3),
(2,  'Maria Santos', 28, 'Brgy. Camingawan, Kabankalan City', 'maria5@hogfarm.com', 5);

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'auth_user' AS tbl, COUNT(*) AS cnt FROM auth_user
UNION ALL SELECT 'core_loginevent', COUNT(*) FROM core_loginevent
UNION ALL SELECT 'farm_hog', COUNT(*) FROM farm_hog
UNION ALL SELECT 'farm_weight', COUNT(*) FROM farm_weight
UNION ALL SELECT 'farm_feeding', COUNT(*) FROM farm_feeding
UNION ALL SELECT 'farm_care', COUNT(*) FROM farm_care
UNION ALL SELECT 'farm_health', COUNT(*) FROM farm_health
UNION ALL SELECT 'farm_medicine', COUNT(*) FROM farm_medicine
UNION ALL SELECT 'farm_inventory', COUNT(*) FROM farm_inventory
UNION ALL SELECT 'farm_expense', COUNT(*) FROM farm_expense
UNION ALL SELECT 'farm_alert', COUNT(*) FROM farm_alert
UNION ALL SELECT 'farm_ai_chat', COUNT(*) FROM farm_ai_chat
UNION ALL SELECT 'farm_hogmedicine', COUNT(*) FROM farm_hogmedicine
UNION ALL SELECT 'farm_breedingrecord', COUNT(*) FROM farm_breedingrecord
UNION ALL SELECT 'farm_healthtriagelog', COUNT(*) FROM farm_healthtriagelog
UNION ALL SELECT 'farm_hogbatch', COUNT(*) FROM farm_hogbatch
UNION ALL SELECT 'farm_batchfeedingrecord', COUNT(*) FROM farm_batchfeedingrecord
UNION ALL SELECT 'farm_feedinventory', COUNT(*) FROM farm_feedinventory
UNION ALL SELECT 'farm_batchfeeddeduction', COUNT(*) FROM farm_batchfeeddeduction
UNION ALL SELECT 'farm_medicaltreatmentlog', COUNT(*) FROM farm_medicaltreatmentlog
UNION ALL SELECT 'tblinfo', COUNT(*) FROM tblinfo;

-- ============================================================
-- End of schema
-- ============================================================

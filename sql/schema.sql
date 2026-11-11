-- ============================================================
-- Hog Raiser Management System - Database Schema (Standalone)
-- Dialect: MariaDB / MySQL
-- Import: phpMyAdmin -> SQL tab, or: mysql -u root -p <db> < sql/schema.sql
-- No external dependencies (no auth_user foreign keys).
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- Library / reference tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_medicine` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL UNIQUE,
    `active_ingredient` varchar(200) NOT NULL,
    `intended_use` text NOT NULL,
    `dosage_info` text NOT NULL,
    `precautions` text NOT NULL,
    `withdrawal_days` int unsigned NOT NULL DEFAULT 0,
    `prescription_required` tinyint(1) NOT NULL DEFAULT 0,
    `interactions` text NOT NULL,
    `reference_source` varchar(255) NOT NULL,
    `stock_quantity` double NOT NULL DEFAULT 0.0,
    `unit` varchar(20) NOT NULL DEFAULT 'Bottles',
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_reference` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `title` varchar(200) NOT NULL,
    `category` varchar(20) NOT NULL,
    `content` text NOT NULL,
    `source` varchar(255) NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Core hog lifecycle tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_hog` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `code` varchar(50) NOT NULL,
    `name` varchar(100) NOT NULL,
    `breed` varchar(100) NOT NULL,
    `sex` varchar(10) NOT NULL,
    `birth_date` date NOT NULL,
    `stage` varchar(20) NOT NULL,
    `status` varchar(20) NOT NULL,
    `current_weight_kg` decimal(10,2) NULL DEFAULT NULL,
    `target_weight_kg` decimal(10,2) NOT NULL DEFAULT 100.00,
    `purchase_cost` decimal(12,2) NOT NULL DEFAULT 0.00,
    `sale_price` decimal(12,2) NULL DEFAULT NULL,
    `notes` text NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `farm_hog_owner_id_code_uniq` (`owner_id`, `code`),
    KEY `farm_hog_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_weight` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `date` date NOT NULL,
    `weight_kg` decimal(10,2) NOT NULL,
    `notes` varchar(255) NOT NULL,
    `created_at` datetime NOT NULL,
    `hog_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_weight_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_feeding` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `feed_category` varchar(20) NOT NULL,
    `feed_name` varchar(120) NOT NULL,
    `amount_kg_per_day` decimal(10,2) NOT NULL,
    `feeding_date` date NOT NULL,
    `notes` varchar(255) NOT NULL,
    `created_at` datetime NOT NULL,
    `hog_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_feeding_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_health` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `symptoms` text NOT NULL,
    `appetite` varchar(20) NOT NULL,
    `behavior` text NOT NULL,
    `duration_days` int unsigned NOT NULL DEFAULT 1,
    `affected_count` int unsigned NOT NULL DEFAULT 1,
    `urgency` varchar(20) NOT NULL,
    `ai_summary` text NOT NULL,
    `possible_causes` text NOT NULL,
    `recommended_steps` text NOT NULL,
    `vet_referral` tinyint(1) NOT NULL DEFAULT 0,
    `status` varchar(20) NOT NULL,
    `created_at` datetime NOT NULL,
    `reported_by_id` bigint NOT NULL,
    `hog_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_health_reported_by_id` (`reported_by_id`),
    KEY `farm_health_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_expense` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `category` varchar(20) NOT NULL,
    `amount` decimal(12,2) NOT NULL,
    `expense_date` date NOT NULL,
    `description` varchar(255) NOT NULL,
    `created_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    `hog_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_expense_owner_id` (`owner_id`),
    KEY `farm_expense_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_care` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `care_type` varchar(20) NOT NULL,
    `title` varchar(150) NOT NULL,
    `due_date` date NOT NULL,
    `completed` tinyint(1) NOT NULL DEFAULT 0,
    `completed_at` datetime NULL DEFAULT NULL,
    `notes` text NOT NULL,
    `created_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    `hog_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_care_owner_id` (`owner_id`),
    KEY `farm_care_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_alert` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `alert_type` varchar(30) NOT NULL,
    `title` varchar(200) NOT NULL,
    `message` text NOT NULL,
    `recommended_action` text NOT NULL,
    `severity` varchar(20) NOT NULL,
    `is_read` tinyint(1) NOT NULL DEFAULT 0,
    `is_resolved` tinyint(1) NOT NULL DEFAULT 0,
    `created_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    `hog_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_alert_owner_id` (`owner_id`),
    KEY `farm_alert_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_ai_chat` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `question` text NOT NULL,
    `answer` text NOT NULL,
    `created_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    `hog_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_ai_chat_owner_id` (`owner_id`),
    KEY `farm_ai_chat_hog_id` (`hog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_inventory` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(150) NOT NULL,
    `category` varchar(20) NOT NULL,
    `quantity` decimal(10,2) NOT NULL DEFAULT 0.00,
    `unit` varchar(30) NOT NULL DEFAULT 'kg',
    `low_stock_threshold` decimal(10,2) NOT NULL DEFAULT 5.00,
    `expiry_date` date NULL DEFAULT NULL,
    `unit_cost` decimal(12,2) NOT NULL DEFAULT 0.00,
    `updated_at` datetime NOT NULL,
    `owner_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_inventory_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Medicine administration / linkage tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_hogmedicine` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `administered_date` date NOT NULL,
    `dosage` varchar(120) NOT NULL,
    `route` varchar(20) NOT NULL,
    `notes` text NOT NULL,
    `withdrawal_until` date NULL DEFAULT NULL,
    `created_at` datetime NOT NULL,
    `hog_id` bigint NOT NULL,
    `medicine_id` bigint NOT NULL,
    `health_report_id` bigint NULL DEFAULT NULL,
    `administered_by_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_hogmedicine_hog_id` (`hog_id`),
    KEY `farm_hogmedicine_medicine_id` (`medicine_id`),
    KEY `farm_hogmedicine_health_report_id` (`health_report_id`),
    KEY `farm_hogmedicine_administered_by_id` (`administered_by_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Breeding / batch management tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_hogbatch` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `initial_total_weight` double NOT NULL,
    `current_total_weight` double NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_breedingrecord` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `mating_date` date NOT NULL,
    `expected_farrowing_date` date NULL DEFAULT NULL,
    `actual_farrowing_date` date NULL DEFAULT NULL,
    `litter_size` int NULL DEFAULT NULL,
    `status` varchar(20) NOT NULL DEFAULT 'Pregnant',
    `created_at` datetime NOT NULL,
    `sow_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_breedingrecord_sow_id` (`sow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Health triage log (standalone)
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_healthtriagelog` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `pig_tag` varchar(50) NULL DEFAULT NULL,
    `symptoms` text NOT NULL,
    `ai_recommendation` text NULL DEFAULT NULL,
    `created_at` datetime NOT NULL,
    `consulted_by_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_healthtriagelog_consulted_by_id` (`consulted_by_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Feed inventory / batch feeding tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_feedinventory` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `feed_type` varchar(50) NOT NULL UNIQUE,
    `quantity_kg` double NOT NULL DEFAULT 0.0,
    `reorder_level` double NOT NULL DEFAULT 50.0,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_batchfeedingrecord` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `date` date NOT NULL,
    `quantity_kg` double NOT NULL,
    `feed_type` varchar(50) NOT NULL,
    `created_at` datetime NOT NULL,
    `batch_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_batchfeedingrecord_batch_id` (`batch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_batchfeeddeduction` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `quantity_kg` double NOT NULL,
    `date` date NOT NULL,
    `batch_id` bigint NOT NULL,
    `feed_inventory_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_batchfeeddeduction_batch_id` (`batch_id`),
    KEY `farm_batchfeeddeduction_feed_inventory_id` (`feed_inventory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Medical treatment log
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `farm_medicaltreatmentlog` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `pig_or_batch` varchar(100) NOT NULL,
    `quantity_used` double NOT NULL,
    `date_administered` date NOT NULL,
    `notes` text NULL DEFAULT NULL,
    `created_at` datetime NOT NULL,
    `medicine_id` bigint NOT NULL,
    `administered_by_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `farm_medicaltreatmentlog_medicine_id` (`medicine_id`),
    KEY `farm_medicaltreatmentlog_administered_by_id` (`administered_by_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Info / personal information table
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tblinfo` (
    `id` bigint NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `age` int unsigned NOT NULL DEFAULT 1,
    `address` varchar(255) NOT NULL,
    `email` varchar(255) NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `user_id` bigint NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `tblinfo_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- End of schema (standalone - no foreign key constraints)
-- ============================================================

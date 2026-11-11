-- Hog Raiser Management System - insert-ready schema (MariaDB/MySQL)
-- Run this AFTER `python manage.py migrate` has created auth_user, django_migrations, etc.
-- Then you can INSERT sample rows below to seed your farm database.

USE `bsitcrud`;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. MEDICINE (library) - standalone
-- ============================================================

INSERT INTO `farm_medicine` (
    `name`, `active_ingredient`, `intended_use`, `dosage_info`, `precautions`,
    `withdrawal_days`, `prescription_required`, `interactions`, `reference_source`,
    `stock_quantity`, `unit`, `created_at`, `updated_at`
) VALUES
('Iron Dextran', 'Iron dextran', 'Prevent/treat anemia in piglets', '1-2 mL IM per piglet', 'Do not overdose',
 7, 0, 'None known', 'Veterinary Handbook', 50.0, 'Bottles', NOW(), NOW()),
('Oxytetracycline', 'Oxytetracycline', 'Bacterial infections', '5-10 mg/kg IM/SC', 'Observe withdrawal',
 14, 1, 'Avoid with calcium', 'Veterinary Handbook', 30.0, 'Bottles', NOW(), NOW()),
('Ivermectin', 'Ivermectin', 'Deworming / parasites', '0.3 mg/kg oral', 'Do not use in weak animals',
 7, 0, 'None known', 'Veterinary Handbook', 100.0, 'Bottles', NOW(), NOW());

-- ============================================================
-- 2. REFERENCE ARTICLE - standalone
-- ============================================================

INSERT INTO `farm_reference` (`title`, `category`, `content`, `source`, `updated_at`) VALUES
('Piglet Feeding Guide', 'feeding', 'Feed pre-starter from day 7 to weaning. Gradual transition to starter.', 'Farm Extension Office', NOW()),
('Vaccination Schedule', 'health', 'Vaccinate sow before farrowing. Piglets at 3, 6, 8 weeks.', 'Veterinary Association', NOW()),
('Biosecurity Basics', 'management', 'Quarantine new hogs for 14 days. Disinfect boots between pens.', 'FAO', NOW());

-- ============================================================
-- 3. FEED INVENTORY - standalone
-- ============================================================

INSERT INTO `farm_feedinventory` (`feed_type`, `quantity_kg`, `reorder_level`, `updated_at`) VALUES
('Pre-Starter', 100.0, 20.0, NOW()),
('Starter', 150.0, 30.0, NOW()),
('Grower', 200.0, 50.0, NOW()),
('Finisher', 250.0, 50.0, NOW());

-- ============================================================
-- 4. HOG BATCH - standalone (used by batch feeding records)
-- ============================================================

INSERT INTO `farm_hogbatch` (`name`, `initial_total_weight`, `current_total_weight`, `created_at`, `updated_at`) VALUES
('Grower Batch 1', 500.0, 520.0, NOW(), NOW()),
('Finisher Batch 1', 800.0, 840.0, NOW(), NOW());

-- ============================================================
-- 5. USER / OWNER (references auth_user)
-- Assumes auth_user id = 1 exists (created by migrate + createsuperuser)
-- ============================================================

-- If you want a dedicated farm owner, create one via:
--   python manage.py createsuperuser
-- then note its id and update owner_id below accordingly.

-- ============================================================
-- 6. HOG (owner_id -> auth_user)
-- ============================================================

INSERT INTO `farm_hog` (
    `code`, `name`, `breed`, `sex`, `birth_date`, `stage`, `status`,
    `current_weight_kg`, `target_weight_kg`, `purchase_cost`, `sale_price`, `notes`,
    `created_at`, `updated_at`, `owner_id`
) VALUES
('EAR-001', 'Spotty', 'Duroc', 'female', '2025-10-01', 'grower', 'active', 45.00, 100.00, 1200.00, NULL, 'Healthy grower pig', NOW(), NOW(), 1),
('EAR-002', 'Bacon', 'Yorkshire', 'male', '2025-09-15', 'finisher', 'active', 90.00, 110.00, 1500.00, NULL, 'Market ready soon', NOW(), NOW(), 1),
('EAR-003', 'Daisy', 'Landrace', 'female', '2025-08-20', 'sow', 'active', 160.00, 200.00, 2500.00, NULL, 'Breeding sow', NOW(), NOW(), 1);

-- ============================================================
-- 7. WEIGHT RECORD (hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_weight` (`date`, `weight_kg`, `notes`, `created_at`, `hog_id`) VALUES
('2026-01-01', 45.00, 'Initial weighing', NOW(), 1),
('2026-02-01', 60.00, 'Monthly check', NOW(), 1),
('2026-01-15', 90.00, 'Pre-market check', NOW(), 2);

-- ============================================================
-- 8. FEEDING RECORD (hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_feeding` (
    `feed_category`, `feed_name`, `amount_kg_per_day`, `feeding_date`, `notes`, `created_at`, `hog_id`
) VALUES
('grower', 'Grower Pellets', 1.50, '2026-02-01', 'Morning and evening', NOW(), 1),
('finisher', 'Finisher Mix', 2.00, '2026-02-01', 'Ad libitum', NOW(), 2),
('breeder', 'Breeder Feed', 2.50, '2026-02-01', 'For gestation', NOW(), 3);

-- ============================================================
-- 9. HEALTH REPORT (reported_by_id -> auth_user, hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_health` (
    `symptoms`, `appetite`, `behavior`, `duration_days`, `affected_count`,
    `urgency`, `ai_summary`, `possible_causes`, `recommended_steps`,
    `vet_referral`, `status`, `created_at`, `reported_by_id`, `hog_id`
) VALUES
('Coughing, runny nose', 'reduced', 'Lethargic', 2, 1, 'needs_attention',
 'Possible respiratory infection.', 'Bordetella or PRRS.',
 'Isolate pig, monitor temperature, consult vet if no improvement.', 0, 'open', NOW(), 1, 1);

-- ============================================================
-- 10. CARE SCHEDULE (owner_id -> auth_user, hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_care` (
    `care_type`, `title`, `due_date`, `completed`, `completed_at`, `notes`,
    `created_at`, `owner_id`, `hog_id`
) VALUES
('vaccine', 'PRRS Vaccine', DATE_ADD(NOW(), INTERVAL 7 DAY), 0, NULL, 'Annual booster', NOW(), 1, 1),
('deworming', 'Deworming Round 1', DATE_ADD(NOW(), INTERVAL 14 DAY), 0, NULL, 'Use Ivermectin', NOW(), 1, 1);

-- ============================================================
-- 11. EXPENSE (owner_id -> auth_user, hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_expense` (
    `category`, `amount`, `expense_date`, `description`, `created_at`, `owner_id`, `hog_id`
) VALUES
('feed', 150.00, '2026-02-01', 'Monthly feed supply', NOW(), 1, 1),
('veterinary', 300.00, '2026-02-05', 'Vet consultation for EAR-001', NOW(), 1, 1);

-- ============================================================
-- 12. ALERT (owner_id -> auth_user, hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_alert` (
    `alert_type`, `title`, `message`, `recommended_action`, `severity`,
    `is_read`, `is_resolved`, `created_at`, `owner_id`, `hog_id`
) VALUES
('health_concern', 'EAR-001 Coughing', 'Hog EAR-001 showing respiratory symptoms.', 'Isolate and monitor.', 'warning', 0, 0, NOW(), 1, 1);

-- ============================================================
-- 13. AI CONSULTATION (owner_id -> auth_user, hog_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_ai_chat` (
    `question`, `answer`, `created_at`, `owner_id`, `hog_id`
) VALUES
('Why is my pig coughing?', 'Possible respiratory infection. Isolate and consult a vet.', NOW(), 1, 1);

-- ============================================================
-- 14. HOG MEDICINE (hog_id, medicine_id, health_report_id -> farm_hog/farm_medicine/farm_health, administered_by_id -> auth_user)
-- ============================================================

INSERT INTO `farm_hogmedicine` (
    `administered_date`, `dosage`, `route`, `notes`, `withdrawal_until`,
    `created_at`, `hog_id`, `medicine_id`, `health_report_id`, `administered_by_id`
) VALUES
('2026-02-02', '5 mg/kg', 'injection', 'Given per vet advice', DATE_ADD('2026-02-02', INTERVAL 14 DAY), NOW(), 1, 2, 1, 1);

-- ============================================================
-- 15. BREEDING RECORD (sow_id -> farm_hog)
-- ============================================================

INSERT INTO `farm_breedingrecord` (
    `mating_date`, `expected_farrowing_date`, `actual_farrowing_date`, `litter_size`,
    `status`, `created_at`, `sow_id`
) VALUES
('2026-01-10', DATE_ADD('2026-01-10', INTERVAL 114 DAY), NULL, NULL, 'Pregnant', NOW(), 3);

-- ============================================================
-- 16. HEALTH TRIAGE LOG (consulted_by_id -> auth_user)
-- ============================================================

INSERT INTO `farm_healthtriagelog` (
    `pig_tag`, `symptoms`, `ai_recommendation`, `created_at`, `consulted_by_id`
) VALUES
('EAR-001', 'Coughing, reduced appetite', 'Isolate pig, monitor temp, vet consult if persistent.', NOW(), 1);

-- ============================================================
-- 17. BATCH FEEDING RECORD (batch_id -> farm_hogbatch)
-- ============================================================

INSERT INTO `farm_batchfeedingrecord` (
    `date`, `quantity_kg`, `feed_type`, `created_at`, `batch_id`
) VALUES
('2026-02-01', 25.0, 'Grower', NOW(), 1),
('2026-02-02', 30.0, 'Finisher', NOW(), 2);

-- ============================================================
-- 18. BATCH FEED DEDUCTION (batch_id -> farm_hogbatch, feed_inventory_id -> farm_feedinventory)
-- ============================================================

INSERT INTO `farm_batchfeeddeduction` (
    `quantity_kg`, `date`, `batch_id`, `feed_inventory_id`
) VALUES
(25.0, '2026-02-01', 1, 3),
(30.0, '2026-02-02', 2, 4);

-- ============================================================
-- 19. MEDICAL TREATMENT LOG (medicine_id -> farm_medicine, administered_by_id -> auth_user)
-- ============================================================

INSERT INTO `farm_medicaltreatmentlog` (
    `pig_or_batch`, `quantity_used`, `date_administered`, `notes`,
    `created_at`, `medicine_id`, `administered_by_id`
) VALUES
('EAR-001', 5.0, '2026-02-02', 'IM injection for respiratory infection', NOW(), 2, 1);

-- ============================================================
-- 20. INFO / PERSONAL INFO (user_id -> auth_user)
-- ============================================================

INSERT INTO `tblinfo` (`name`, `age`, `address`, `email`, `created_at`, `updated_at`, `user_id`) VALUES
('Farm Owner', 35, 'Cauayan, Isabela', 'owner@example.com', NOW(), NOW(), 1);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- Verification queries (optional)
-- ============================================================
-- SELECT * FROM farm_hog;
-- SELECT * FROM farm_health;
-- SELECT * FROM farm_medicine;

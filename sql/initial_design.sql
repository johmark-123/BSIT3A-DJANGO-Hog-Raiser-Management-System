-- Hog Raiser Management System - initial database design
-- Dialect: SQLite
-- Source: apps/farm/migrations/0001_initial.py and apps/info/migrations/0001_initial.py
--
-- This file documents the application tables for a fresh database. Django's
-- built-in auth_user table must exist before applying these foreign keys.
-- For normal setup and upgrades, use `python manage.py migrate` instead.
--
-- Table relationships:
--   auth_user 1---many farm_hog, farm_health (reporter), farm_expense,
--                    farm_care, farm_alert, farm_ai_chat, farm_inventory
--   auth_user 1---many tblinfo (optional)
--   farm_hog  1---many farm_weight, farm_feeding, farm_health
--   farm_hog  1---many farm_expense, farm_care, farm_alert, farm_ai_chat
--   farm_medicine and farm_reference are standalone library tables.
--
-- The users and core apps do not define additional application models.

PRAGMA foreign_keys = ON;

BEGIN;
--
-- Create model Medicine
--
CREATE TABLE "farm_medicine" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(150) NOT NULL UNIQUE, "active_ingredient" varchar(200) NOT NULL, "intended_use" text NOT NULL, "dosage_info" text NOT NULL, "precautions" text NOT NULL, "withdrawal_days" integer unsigned NOT NULL CHECK ("withdrawal_days" >= 0), "prescription_required" bool NOT NULL, "interactions" text NOT NULL, "reference_source" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
--
-- Create model ReferenceArticle
--
CREATE TABLE "farm_reference" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "title" varchar(200) NOT NULL, "category" varchar(20) NOT NULL, "content" text NOT NULL, "source" varchar(255) NOT NULL, "updated_at" datetime NOT NULL);
--
-- Create model Hog
--
CREATE TABLE "farm_hog" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "code" varchar(50) NOT NULL, "name" varchar(100) NOT NULL, "breed" varchar(100) NOT NULL, "sex" varchar(10) NOT NULL, "birth_date" date NOT NULL, "stage" varchar(20) NOT NULL, "status" varchar(20) NOT NULL, "current_weight_kg" decimal NULL, "target_weight_kg" decimal NOT NULL, "purchase_cost" decimal NOT NULL, "sale_price" decimal NULL, "notes" text NOT NULL, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model HealthReport
--
CREATE TABLE "farm_health" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "symptoms" text NOT NULL, "appetite" varchar(20) NOT NULL, "behavior" text NOT NULL, "duration_days" integer unsigned NOT NULL CHECK ("duration_days" >= 0), "affected_count" integer unsigned NOT NULL CHECK ("affected_count" >= 0), "urgency" varchar(20) NOT NULL, "ai_summary" text NOT NULL, "possible_causes" text NOT NULL, "recommended_steps" text NOT NULL, "vet_referral" bool NOT NULL, "status" varchar(20) NOT NULL, "created_at" datetime NOT NULL, "reported_by_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "hog_id" bigint NOT NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model FeedingRecord
--
CREATE TABLE "farm_feeding" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "feed_category" varchar(20) NOT NULL, "feed_name" varchar(120) NOT NULL, "amount_kg_per_day" decimal NOT NULL, "feeding_date" date NOT NULL, "notes" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "hog_id" bigint NOT NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model Expense
--
CREATE TABLE "farm_expense" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "category" varchar(20) NOT NULL, "amount" decimal NOT NULL, "expense_date" date NOT NULL, "description" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "hog_id" bigint NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model CareSchedule
--
CREATE TABLE "farm_care" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "care_type" varchar(20) NOT NULL, "title" varchar(150) NOT NULL, "due_date" date NOT NULL, "completed" bool NOT NULL, "completed_at" datetime NULL, "notes" text NOT NULL, "created_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "hog_id" bigint NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model Alert
--
CREATE TABLE "farm_alert" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "alert_type" varchar(30) NOT NULL, "title" varchar(200) NOT NULL, "message" text NOT NULL, "recommended_action" text NOT NULL, "severity" varchar(20) NOT NULL, "is_read" bool NOT NULL, "is_resolved" bool NOT NULL, "created_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "hog_id" bigint NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model AIConsultation
--
CREATE TABLE "farm_ai_chat" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "question" text NOT NULL, "answer" text NOT NULL, "created_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "hog_id" bigint NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model InventoryItem
--
CREATE TABLE "farm_inventory" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(150) NOT NULL, "category" varchar(20) NOT NULL, "quantity" decimal NOT NULL, "unit" varchar(30) NOT NULL, "low_stock_threshold" decimal NOT NULL, "expiry_date" date NULL, "unit_cost" decimal NOT NULL, "updated_at" datetime NOT NULL, "owner_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model WeightRecord
--
CREATE TABLE "farm_weight" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "date" date NOT NULL, "weight_kg" decimal NOT NULL, "notes" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "hog_id" bigint NOT NULL REFERENCES "farm_hog" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE UNIQUE INDEX "farm_hog_owner_id_code_0808ec2e_uniq" ON "farm_hog" ("owner_id", "code");
CREATE INDEX "farm_hog_owner_id_017c3fad" ON "farm_hog" ("owner_id");
CREATE INDEX "farm_health_reported_by_id_f2b0e9d6" ON "farm_health" ("reported_by_id");
CREATE INDEX "farm_health_hog_id_b962b100" ON "farm_health" ("hog_id");
CREATE INDEX "farm_feeding_hog_id_0c282a39" ON "farm_feeding" ("hog_id");
CREATE INDEX "farm_expense_owner_id_d9b31bc8" ON "farm_expense" ("owner_id");
CREATE INDEX "farm_expense_hog_id_0a805f76" ON "farm_expense" ("hog_id");
CREATE INDEX "farm_care_owner_id_ba8dace3" ON "farm_care" ("owner_id");
CREATE INDEX "farm_care_hog_id_35e320cb" ON "farm_care" ("hog_id");
CREATE INDEX "farm_alert_owner_id_bc2f5598" ON "farm_alert" ("owner_id");
CREATE INDEX "farm_alert_hog_id_bd982de0" ON "farm_alert" ("hog_id");
CREATE INDEX "farm_ai_chat_owner_id_e15b4721" ON "farm_ai_chat" ("owner_id");
CREATE INDEX "farm_ai_chat_hog_id_cd91bfc0" ON "farm_ai_chat" ("hog_id");
CREATE INDEX "farm_inventory_owner_id_4af91fc7" ON "farm_inventory" ("owner_id");
CREATE INDEX "farm_weight_hog_id_f4bb9b65" ON "farm_weight" ("hog_id");
COMMIT;

BEGIN;
--
-- Create model Info
--
CREATE TABLE "tblinfo" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "age" integer unsigned NOT NULL CHECK ("age" >= 0), "address" varchar(255) NOT NULL, "email" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "user_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "tblinfo_user_id_4a36749d" ON "tblinfo" ("user_id");
COMMIT;

-- Migration to add _path suffix to document columns
-- Run this in your Supabase SQL Editor

-- Rename columns in application table
ALTER TABLE application 
  RENAME COLUMN school_id TO school_id_path;

ALTER TABLE application 
  RENAME COLUMN id_picture TO id_picture_path;

ALTER TABLE application 
  RENAME COLUMN birth_certificate TO birth_certificate_path;

ALTER TABLE application 
  RENAME COLUMN grades TO grades_path;

ALTER TABLE application 
  RENAME COLUMN cor TO cor_path;

-- Rename columns in renew table
ALTER TABLE renew 
  RENAME COLUMN school_id TO school_id_path;

ALTER TABLE renew 
  RENAME COLUMN id_picture TO id_picture_path;

ALTER TABLE renew 
  RENAME COLUMN birth_certificate TO birth_certificate_path;

ALTER TABLE renew 
  RENAME COLUMN grades TO grades_path;

ALTER TABLE renew 
  RENAME COLUMN cor TO cor_path;

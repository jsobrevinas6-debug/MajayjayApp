-- Delete all existing renewal records to allow fresh submissions with real documents
DELETE FROM renew;

-- Reset the sequence for renewal_id to start from 1
ALTER SEQUENCE renew_renewal_id_seq RESTART WITH 1;

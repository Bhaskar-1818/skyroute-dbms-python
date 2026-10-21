-- T8 : DCL - grants, revoke, restore (Step 7 evidence).
USE skyroute_db;

SHOW GRANTS FOR 'sky_admin'@'localhost';
SHOW GRANTS FOR 'sky_staff'@'localhost';
SHOW GRANTS FOR 'sky_viewer'@'localhost';

-- revoke: staff loses write access, keeps read
REVOKE INSERT, UPDATE ON skyroute_db.* FROM 'sky_staff'@'localhost';
SHOW GRANTS FOR 'sky_staff'@'localhost';

-- restore the working grant
GRANT SELECT, INSERT, UPDATE ON skyroute_db.* TO 'sky_staff'@'localhost';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'sky_staff'@'localhost';

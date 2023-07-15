-- Active: 1687564679455@@127.0.0.1@3306@tinder_profiles_analysis
-- cal_match_ratio = sum(matches)/sum(likes)

--- Basic aggregation of the main tables

ALTER TABLE users
ADD COLUMN agr_total_likes INT;

UPDATE users
JOIN (SELECT id, sum(value) as agr_total_likes_t
FROM likes
GROUP BY id) as j on users.id = j.id
SET users.agr_total_likes = j.agr_total_likes_t;

ALTER TABLE users DROP COLUMN agr_total_likes;

CREATE PROCEDURE calc_sum(
    IN new_column_name VARCHAR(255),
    IN table_name VARCHAR(255)
)
BEGIN
    -- Add the new column
    SET @alter_query = CONCAT('ALTER TABLE users ADD COLUMN ', new_column_name, ' INT');
    PREPARE stmt FROM @alter_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Update the new column with aggregated data from the specified table
    SET @update_query = CONCAT('UPDATE users
        JOIN (
            SELECT id, SUM(value) AS ', new_column_name, '_t
            FROM ', table_name, '
            GROUP BY id
        ) AS j ON users.id = j.id
        SET users.', new_column_name, ' = j.', new_column_name, '_t');
    PREPARE stmt FROM @update_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;

CALL calc_sum('agr_total_likes', 'likes');
CALL calc_sum('agr_total_passes', 'passes');
CALL calc_sum('agr_total_matches', 'matches');
CALL calc_sum('agr_total_app_opens', 'app_opens');
CALL calc_sum('agr_total_messages_sent', 'messages_sent');
CALL calc_sum('agr_total_messages_recieved', 'messages_recieved');

ALTER TABLE users ADD COLUMN active_till DATE;

UPDATE users
JOIN (
    SELECT id, MAX(date) as active_till 
    FROM (
        SELECT * FROM passes WHERE value > 0
    ) as t 
    GROUP BY id
) as t 
ON t.id = users.id
SET users.active_till = t.active_till;

ALTER TABLE users ADD COLUMN days_active INT;
UPDATE users
SET days_active = DATEDIFF(active_till, created_date);

SELECT  * FROM users;

--- PHASE 1 DATA COMPLETE

DROP TABLE IF EXISTS phase_1;

CREATE TABLE phase_1 AS SELECT * FROM users;

SELECT * FROM phase_1;
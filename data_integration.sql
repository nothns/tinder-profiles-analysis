-- Active: 1687564679455@@127.0.0.1@3306@tinder_profiles_analysis
-- Active: 1687564679455@@127.0.0.1@3306@tinder_profiles_analysis

DROP TABLE IF EXISTS matches_raw, messagesreceived_raw, messagessent_raw, swipelikes_raw, swipepasses_raw, users_raw, appopens_raw, conversations_raw;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS matches, app_opens, messages_recieved, messages_sent, likes, passes, users, conversations;
SET FOREIGN_KEY_CHECKS = 1;

-- formatting users

SELECT * FROM users;

CREATE TABLE users AS
SELECT 
    _id AS id, 
    nrOfConversations AS number_of_conversations,
    longestConversation AS longest_conversation,
    longestConversationInDays AS longest_conversation_days,
    averageConversationLength AS average_conversation_length,
    averageConversationLengthInDays AS average_conversation_length_days,
    medianConversationLength AS median_conversation_length,
    medianConversationLengthInDays AS median_conversation_length_days,
    nrOfOneMessageConversations AS number_of_one_message_conversations,
    nrOfGhostingsAfterInitialMessage AS ghostings_after_initial_message,
    STR_TO_DATE(birthDate, '%Y-%m-%dT%H:%i:%s.%fZ') AS birthday,
    ageFilterMin AS age_filter_min,
    ageFilterMax AS age_filter_max,
    cityName as city_name,
    country,
    STR_TO_DATE(createDate, '%Y-%m-%dT%H:%i:%s.%fZ') AS created_date,
    CASE
        WHEN education = 'Has high school and/or college education' THEN 0
        WHEN education = 'Has no high school or college education' THEN 1
    END AS education,
    CASE
        WHEN gender = 'M' THEN 0
        WHEN gender = 'F' THEN 1
        ELSE NULL
    END AS gender,
    CASE
        WHEN interestedIn = 'M' THEN 0
        WHEN interestedIn = 'F' THEN 1
        WHEN interestedIn = 'M and F' THEN 2
        ELSE NULL
    END AS interested_in,
    CASE
        WHEN genderFilter = 'M' THEN 0
        WHEN genderFilter = 'F' THEN 1
        WHEN genderFilter = 'M and F' THEN 2
        ELSE NULL
    END AS gender_filter,
    instagram,
    spotify,
    REGEXP_SUBSTR(jobs, "(?<= 'title': ')(.+?)(?=')") AS job,
    REGEXP_SUBSTR(schools, "(?<= 'name': ')(.+?)(?=')") AS school
FROM users_raw;

ALTER TABLE users
    MODIFY COLUMN id CHAR(32),
    MODIFY COLUMN number_of_conversations INT,
    MODIFY COLUMN longest_conversation INT,
    MODIFY COLUMN median_conversation_length INT,
    MODIFY COLUMN number_of_one_message_conversations INT,
    MODIFY COLUMN ghostings_after_initial_message INT,
    MODIFY COLUMN age_filter_min INT,
    MODIFY COLUMN age_filter_max INT,
    MODIFY COLUMN birthday DATE,
    MODIFY COLUMN city_name VARCHAR(40),
    MODIFY COLUMN country VARCHAR(40),
    MODIFY COLUMN job VARCHAR(128),
    MODIFY COLUMN school VARCHAR(128),
    MODIFY COLUMN education TINYINT,
    MODIFY COLUMN gender TINYINT,
    MODIFY COLUMN interested_in TINYINT,
    MODIFY COLUMN gender_filter TINYINT,
    ADD CONSTRAINT pk_user PRIMARY KEY (id);

-- modify date tables

DROP PROCEDURE ModifyTable;

CREATE PROCEDURE ModifyTable(IN tableName VARCHAR(100))
BEGIN
    SET @sql = CONCAT('
        ALTER TABLE ', tableName, '
        MODIFY COLUMN `date` DATE,
        MODIFY COLUMN _id CHAR(32),
        MODIFY COLUMN value INT;
    ');
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT('
        ALTER TABLE ', tableName, '
        RENAME COLUMN _id to id,
        ADD CONSTRAINT pk_', tableName, ' PRIMARY KEY (id, `date`);
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT('
        ALTER TABLE ', tableName, '
        ADD CONSTRAINT fk_', tableName, '_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE;
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;

CREATE TABLE app_opens AS SELECT * FROM appopens_raw;
CALL `ModifyTable`('app_opens');
CREATE TABLE matches AS SELECT * FROM matches_raw;
CALL `ModifyTable`('matches');
CREATE TABLE messages_recieved AS SELECT * FROM messagesreceived_raw;
CALL `ModifyTable`('messages_recieved');
CREATE TABLE messages_sent AS SELECT * FROM messagessent_raw;
CALL `ModifyTable`('messages_sent');
CREATE TABLE likes AS SELECT * FROM swipelikes_raw;
CALL `ModifyTable`('likes');
CREATE TABLE passes AS SELECT * FROM swipepasses_raw;
CALL `ModifyTable`('passes');

-- modify converations table

DROP TABLE IF EXISTS conversations;

CREATE TABLE conversations AS
SELECT _id AS id, 
    time_sent as time_sent_r,
    conversation_number,
    message
FROM conversations_raw;

ALTER TABLE conversations
    ADD COLUMN time_sent DATETIME,
    MODIFY COLUMN id CHAR(32),
    MODIFY COLUMN conversation_number INT;

-- one date is corrupt, it will be dropped

SELECT * FROM conversations WHERE STR_TO_DATE(time_sent_r, '%a, %d %b %Y %H:%i:%s GMT') IS NULL;

DELETE FROM conversations
WHERE time_sent_r = "Sun, 20 Jul 2014 12:0,49 GMT";

UPDATE conversations SET time_sent = STR_TO_DATE(time_sent_r, '%a, %d %b %Y %H:%i:%s GMT');

ALTER TABLE conversations 
    DROP COLUMN time_sent_r;

ALTER TABLE conversations
    ADD CONSTRAINT fk_conversations_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE;

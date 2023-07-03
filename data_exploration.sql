

SELECT * FROM users WHERE agr_total_likes IS NULL;

-- seems like there are multiple users which no match data, is this a bug? will test

SELECT * FROM conversations WHERE id = '5c30036bcc93502c5ba61e78d64a1e19';

SELECT * FROM conversations WHERE message regexp '[0-9]{10,}';

-- fixed!

SELECT * FROM users


select * from users;

SELECT  school, COUNT(*) as count
FROM users
GROUP BY school
ORDER BY count DESC;
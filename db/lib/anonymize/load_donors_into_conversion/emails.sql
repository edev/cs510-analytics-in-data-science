INSERT INTO email_conversion (email)
SELECT DISTINCT email
FROM donors;

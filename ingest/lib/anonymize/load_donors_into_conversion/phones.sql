INSERT INTO phone_conversion (phone)
SELECT DISTINCT phone
FROM donors;

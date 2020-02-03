UPDATE email_conversion
SET anonymous_email = 
    (SELECT email
    FROM anonymized_emails A
    WHERE A.id = email_conversion.id);


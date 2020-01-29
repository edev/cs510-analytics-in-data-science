UPDATE donors
SET anonymized_email =
    (SELECT anonymous_email
    FROM email_conversion
    WHERE email_conversion.email = donors.email);


UPDATE phone_conversion
SET anonymous_phone = 
    (SELECT phone
    FROM anonymized_phones A
    WHERE A.id = phone_conversion.id);


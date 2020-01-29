UPDATE donors
SET anonymized_phone =
    (SELECT anonymous_phone
    FROM phone_conversion
    WHERE phone_conversion.phone = donors.phone);


UPDATE donors
SET anonymized_name =
    (SELECT anonymous_name
    FROM name_conversion
    WHERE name_conversion.name = donors.name);

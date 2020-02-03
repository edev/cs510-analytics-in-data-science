UPDATE name_conversion
SET anonymous_name = 
    (SELECT name
    FROM anonymized_names A
    WHERE A.id = name_conversion.id);

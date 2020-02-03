CREATE TABLE IF NOT EXISTS email_conversion (
    id              INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    email           VARCHAR(255),
    anonymous_email VARCHAR(255)
);


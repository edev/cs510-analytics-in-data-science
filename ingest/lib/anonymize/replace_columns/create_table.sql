CREATE TABLE anonymized_donors(
    "id"                    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "name"                  varchar(255),
    "phone"                 varchar(255),
    "email"                 varchar(255),
    "quantity"              integer,
    "comment"               text,
    "confirmed"             boolean,
    "created_at"            datetime NOT NULL,
    "updated_at"            datetime NOT NULL,
    "need_id"               integer,
    "permission_to_contact" boolean
);


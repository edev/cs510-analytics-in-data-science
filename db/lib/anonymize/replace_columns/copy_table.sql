INSERT INTO anonymized_donors
    SELECT id,
           anonymized_name,
           anonymized_phone,
           anonymized_email,
           quantity,
           substr('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum sodales tortor lorem, ac aliquet tellus facilisis sit amet. Integer vestibulum risus et venenatis pharetra. Sed non nisl et nisl lacinia finibus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc eu suscipit sapien. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices volutpat.', 0, length(comment)),
           confirmed,
           created_at,
           updated_at,
           need_id,
           permission_to_contact
    FROM donors;


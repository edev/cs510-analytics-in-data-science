function (doc) {
    var id_filter = /^needs\//;
    if (doc._id.match(id_filter) != null) {
        doc.sign_ups.forEach(function (sign_up) {
            emit(
                [sign_up.email, sign_up.created_at],
                {
                    "need_title": doc.title,
                    "name": sign_up.name,
                    "phone": sign_up.phone,
                    "quantity": sign_up.quantity,
                    "comment": sign_up.comment
                }
            );
        });
    }
}


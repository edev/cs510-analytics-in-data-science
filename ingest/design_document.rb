{
    _id: '_design/termproject',
    views: {
        a: {
            map: <<~'END'
                function (doc) {
                    var id_filter = /^needs\//;
                    var year_matcher =  /\d+$/;
                    if (doc._id.match(id_filter) != null) {
                        var year = doc._id.match(year_matcher)[0];
                        emit(
                            [year, doc._id],
                            {
                                "goal": doc.goal,
                                "gathered": doc.gathered
                            }
                        );
                    }
                }
            END
        },
        b: {
            map: <<~'END'
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
            END
        },
        c: {
            map: <<~'END'
                function (doc) {
                    var id_filter = /^needs\//;
                    if (doc._id.match(id_filter) != null) {
                        doc.sign_ups.forEach(function (sign_up) {
                            /* First, replace the space with a T in the
                               timestamp, otherwise ES5.1 JavaScript can't
                               parse it. For details, see:
                               https://www.ecma-international.org
                                      /ecma-262/5.1/#sec-15.9.1.15
                            */
                            var timestamp = sign_up.created_at.replace(" ", "T");
                            var date = new Date(timestamp);

                            emit(
                                [
                                    date.getFullYear(),
                                    date.getMonth() + 1, /* returns 0-11 */
                                    date.getDate(), /* returns 1-31 */
                                    date.getHours(), /* returns 0-23 */
                                    date.getMinutes(), /* returns 0-59 */
                                    date.getSeconds() /* returns 0-59 */
                                ],
                                {
                                    "need_title": doc.title,
                                    "name": sign_up.name,
                                    "quantity": sign_up.quantity,
                                }
                            );
                        });
                    }
                }
            END
        }
    }
}

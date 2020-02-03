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


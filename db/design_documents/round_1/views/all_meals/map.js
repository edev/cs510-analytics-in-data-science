function (doc) {
  if(doc._id
    && doc._id.indexOf("meals/") == 0
    && doc.number_served) {

    var date = doc._id.substring(6);
    var date_components = date.split('-');

    emit(date_components, doc.number_served);
  }
}

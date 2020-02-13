function (doc) {
  if(doc._id
    && doc._id.indexOf("meals/") == 0
    && doc.number_served) {

    var date = doc._id.substring(6);
    var date_components = date.split('-');

    // Emit key:[month, year], value: [day, number_served]
    emit([date_components[1], date_components[0]], [date_components[2], doc.number_served]);
  }
}

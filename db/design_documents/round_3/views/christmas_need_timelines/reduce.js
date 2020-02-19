function (keys, values, rereduce) {
  if(values.length <= 0) {
    return 0;
  }

  var max = values[0];
  for(var i = 1; i < values.length; i++) {
    if(values[i] > max) {
      max = values[i];
    }
  }
  return max;
}

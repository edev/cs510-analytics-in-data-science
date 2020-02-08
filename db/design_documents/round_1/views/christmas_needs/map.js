function (doc) {
  // Emit ([year, need_slug], { goal: goal, sign_ups: [[date, amount], [date, amount], ...] })
  if(doc._id
    && doc._id.indexOf('needs') == 0
    && doc.goal
    && doc.sign_ups) { // NOTE: In production, need to account for adjustments, too!

    var year_matcher = /\d{4}$/;
    var year = doc._id.match(year_matcher)[0];

    // Note: named capture groups are unreliable in JS, so we'll avoid them entirely.
    const start = 6; // Prefix 'needs/' is guaranteed; slice it off.
    var end = doc._id.lastIndexOf('/'); // Slice off the date, leaving just need_slug.
    var need_slug = doc._id.substring(start, end );

    var value = {
      goal: doc.goal,
      sign_ups: doc.sign_ups
    }
    if(doc.adjustments && doc.adjustments.adjustment) {
      value.adjustment = doc.adjustments.adjustment;
    }
    
    emit(
      [year, need_slug],
      value
    );
  }
}

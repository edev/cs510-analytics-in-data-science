function (doc) {
  // For each sign-up for each need, we will emit:
  //    ([need_slug, year, month, day], progress)
  // where progress is the number of sign-ups so far.
  //
  // In the event that there are multiple sign-ups for a need on a given day, we will emit multiple rows with the same
  // key; in this event, the corresponding reduce function will keep only the max.
  //
  // This prototype ignore the adjustments field.

   if(doc._id
     && doc._id.indexOf('needs') == 0
     && doc.sign_ups) {
 
     // Note: named capture groups are unreliable in JS, so we'll avoid them entirely.
     const start = 6; // Prefix 'needs/' is guaranteed; slice it off.
     var end = doc._id.lastIndexOf('/'); // Slice off the date, leaving just need_slug.
     var need_slug = doc._id.substring(start, end );
 
     var sum = 0;
     for(var i = 0; i < doc.sign_ups.length; i++) {
       if(doc.sign_ups[i].quantity && doc.sign_ups[i].created_at) {
         var key = doc.sign_ups[i].created_at.substring(0, 10).split('-', 3);
         key.unshift(need_slug);
         sum += doc.sign_ups[i].quantity;
         emit(key, sum);
       }
     }
   }
}

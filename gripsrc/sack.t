#ifndef MAKESACK
#define MAKESACK

/* 
** Sack.t -- a module which introduces a sack, similar to those found in
**           Inform games, which allows objects to be automagically placed in
**           them to make room for other objects, a la (Putting the elephant in
**           the sack to make room for the flea).  The original idea and large
**           portions of the makeRoom function are due to Dan Shiovitz.  I
**           (Stephen Granade) ironed out the bugs and made a few changes to
**           the implementation.  Here are Dan's original comments on it:

   This basic function suggestions some interesting modifications, which
   I might even get around to making someday:
   * It wouldn't be too hard to have *several* global sack objects, 
     and this function would use the one that you were carrying.
     [Already added, by SRG. To create a global sack object, simply make your
     sack be of class sackItem. makeRoom searches through the list of sack
     objects (made by preinit) and checks each one that you are carrying.]
   * Currently, it has a fairly sketchy use of bulk.  Perhaps makeRoom should
     take a second argument, bulk_to_clear, a number indicating what bulk of
     object needs to be removed from your inventory.
     [Also added, by SRG. I didn't actually use bulk_to_clear; instead, the
     makeRoom function double-checks the bulk every time it places an object
     in the sack.]
   * A magical bag of holding might make things weigh less if you put them
     inside it.  In that case, "(Putting the rock in your bag of holding to
     allow you to lift the frog)" might be perfectly valid behavior.
   * And, of course, if someone would implement this for WorldClass, I'd
     be spared the trouble.
 
   --Dan Shiovitz
   scythe@u.washington.edu

**           While I was mucking about with the doTake() method in thing,
**           I also added a takedesc, which is called when the obj is picked
**           up.  Normally it prints "Taken.", but you could make it whatever
**           you wish.
**
** You are permitted to distribute this module freely, as long as 1) Dan's
** name is left on it, and 2) you keep all files together.  You may also use
** this module in any game you like in any form you like.  Hack away at
** it, if you so desire.  All I ask is that you credit Dan in some way in your
** game.
** I would welcome any comments on or suggestions for this module.  I can be
** reached at:
**  Duke University Physics Department
**  Box 90305
**  Durham, NC  27708-0305
**  U.S.A.
**  sgranade@phy.duke.edu
**
** Version history:
**  25 Aug 96 -- Initial release
**  12 Mar 97 -- v1.2  Changed outhide() calls to use returned status values
**  24 Jun 97 -- v1.3  Compensated for firstobj()/nextobj() bug
*/

#pragma C+

#include "sysfuncs.t"

sackVersion: versionTag, initialization    // Make sure we're called by preinit
    id = "$Id: sack.t,v 1.3 1997/06/25 01:42:58 sgranade Exp $\n"
    author = 'Stephen Granade and Dan Shiovitz'
    func = 'sack of holding'

    sack_list = []
    preinit_phase = {    // Create the sack_list
        local o;

        for (o = firstobj(sackItem); o != nil; o = nextobj(o, sackItem))
            sack_list += o;
        sack_list = distillList(sack_list);
    }
;

// The global sack class. Note that it is an object, allowing you to make most
//  anything be a global sack item.
class sackItem: object
    isGlobalSack = true
;

// The function to make room in the sack
makeRoom: function(actor, newItem)
{
  local obj, i, l, os, sack, num, len, bulkTotal, outhideStatus;

  len = length(sackVersion.sack_list);
  for (num = 1; num <= len; num++) {
      sack = sackVersion.sack_list[num];
      if (!sack.isIn(actor)) continue;    // Make sure I have the sack

      os = sack.isopen;   
      if (!os) { // ie, if the sack object is closed
          outhideStatus = outhide(true);    // hide output for a while
          sack.verDoOpen(actor); // call the *verify* method
          if (outhide(outhideStatus)) {  // if t, there was output which
                              // means the verify failed and we can't
                              // open the sack
              continue;       // try the next sack
          }
          else { // otherwise, if we can open it, do open it.
              outhideStatus = outhide(true);  // (Don't say what we're doing)
              sack.doOpen(Me);
              outhide(outhideStatus);
          }
      }

      // the sack object is now open.  now we try and figure out which
      // object to put in

      for (i = 1; i <= length(actor.contents); i++) {
          local tryThis;

          tryThis = actor.contents[i];
          if (tryThis == sack) continue; // Don't put the sack in the sack

          outhideStatus = outhide(true); // is this a viable storable
          tryThis.verDoPutIn(actor, sack);
          if (!outhide(outhideStatus)) { // if no output, then ok.
              obj = tryThis;
              break;
          }
      }

      if (obj == nil) // if obj never got set to anything
          continue;   // try the next sack

      // we now have an object.  let's put it in the sack.
      outhideStatus = outhide(true);
      obj.doPutIn(actor, sack);
      outhide(outhideStatus);
      "(Putting <<obj.thedesc>> into <<sack.thedesc>> to make
          room for <<newItem.thedesc>>)\n";
      // easy, wasn't that?

      // the only thing left to do is close the sack, if it was closed 
      // originally
      if (!os) {
          outhideStatus = outhide(true); // one last time
          sack.verDoClose(actor);
          if (!outhide(outhideStatus)) { // if the verify succeeded
              outhideStatus = outhide(true);
              sack.doClose(actor);
              outhide(outhideStatus);
          }
          // note that we do *not* try the next sack if this verify fails,
          // because, after all, we did make room for the new object.
      }
      bulkTotal = addbulk(actor.contents); // See if we did our job
      if (bulkTotal + newItem.bulk <= actor.maxbulk) // Ooh, it worked!
          return true;
      num--;   // Try putting something else in this same sack
  }    
  return nil;  // No good. Report abject failure
}

// The modifications to thing
modify thing
  replace doTake(actor) = {
      local totbulk, totweight;

      totbulk = addbulk(actor.contents) + self.bulk;
      totweight = addweight(actor.contents);
      if (!actor.isCarrying(self))
          totweight += self.weight + addweight(self.contents);

      if (totweight > actor.maxweight)
          "%Your% load is too heavy. ";
      else if (totbulk > actor.maxbulk) {
          if (makeRoom(actor, self)) {
              self.moveInto(actor);
              self.takedesc;
          }
          else "%You've% already got %your% hands full. ";
      }
      else {
          self.moveInto(actor);
          self.takedesc;
      }
  }
  takedesc = "Taken. "
;

#endif

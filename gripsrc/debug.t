#ifndef DEBUG
#define DEBUG
#pragma C+

/*
** Debug.t adds debugging commands for playtesting.  The following verbs
** are added:
**
** gimme -- moves any object in the game into your inventory
** whereis -- gives you the sdesc of an item's location
** bamf -- teleports you to the room an item is in.  If you want to bamf
**         directly to a room, just give the room a noun.  You can then
**         "bamf <roomnoun>".  If you don't want to be able to bamf to an
**         object (like a follower), just set noBamf to true in the object
**
** Copyright (c) 1995-1997 Stephen Granade
** You are permitted to distribute this module freely, as long as 1) my name
** is left on it, and 2) you keep all files together.  You may also use
** this module in any game you like in any form you like.  Hack away at
** it, if you so desire.  All I ask is that you credit me in some way in your
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
**  6 July 93 -- Initial release
**  22 Dec 95 -- Added version tracking using Jeff Laing's routines
**  15 Jan 97 -- Added noBamf flag to bamfVerb & follower
**  22 Jan 97 -- Prevented gimme & where from disambiguating follower class
*/

#include "version.t"

debugVersion: versionTag
  id = "$Id: debug.t,v 1.4 1997/01/24 00:44:35 sgranade Exp $\n"
  author = 'Stephen Granade'
  func = 'debugging commands'
;

gimmeVerb: sysverb
  verb = 'gimme'
  sdesc = "gimme"
  doAction = 'Gimme'
  validDo(actor, obj, seqno) = {
    if (obj.noGimme) return nil;
    return true;
  }
  validDoList(actor, prep, dobj) = nil
;

whereVerb: sysverb
  verb = 'where' 'whereis'
  sdesc = "where"
  doAction = 'Where'
  validDo(actor, obj, seqno) = {
    if (obj.noWhere) return nil;
    return true;
  }
  validDoList(actor, prep, dobj) = nil
;

modify thing
  verDoGimme(actor) = {
    if (isclass(self, floatingItem))
      "Not a good idea--<<self.thedesc>> is a floating item.  ";
  }
  doGimme(actor) = {
    self.moveInto(actor);
    "Poof! \^<<self.thedesc>> appears.";
  }
  verDoBamf(actor) = {
    if (self.location == nil and (!isclass(self, room)))
      "\^<<self.thedesc>> is nowhere--you can't go there!  ";
    else if (isclass(self, floatingItem))
      "\^<<self.thedesc>> is a floating item, so you can't bamf to it.  ";
  }
  doBamf( actor ) = {
    local loc;

    loc = self;
    while (loc and (!isclass(loc, room)))
      loc = loc.location;
    if (loc) {
      "Bamf!\b";
      Me.travelTo(loc);
    }
    else "Bamf failed.  ";
  }
  verDoWhere(actor) = {}
  doWhere(actor) = {
    "\^<<self.thedesc>> is ";
    if (self.location == nil)
      "nowhere. ";
    else
      "in <<self.location.sdesc>>.  ";
  }
;

modify fixeditem
  doGimme(actor) = {
    self.moveInto(actor.location);
    "Poof! \^<<self.thedesc>> appears.";
    if (!self.isactor) self.isListed = true;
  }
;

bamfVerb : sysverb
  verb = 'bamf'
  sdesc = "bamf"
  doAction = 'Bamf'
  validDo(actor, obj, seqno) = {
    if (obj == nil || obj.noBamf)
      return nil;
    return true;
  }
  validDoList(actor, prep, dobj) = nil;
;

// Followers should not be subjected to gimme, bamf, or whereis commands
modify follower
  noGimme = true
  noBamf = true
  noWhere = true;
;

#endif

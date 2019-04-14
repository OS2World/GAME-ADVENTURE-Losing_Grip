#ifndef NOTIFY
#define NOTIFY
#pragma C+

/*
** Notify.t --  This is a module which, whenever the player's score changes,
** prints out a message saying how much it changed by.  The notifications
** are in bold type, and a one-time message lets the player know how to
** turn notification on and off.
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
**  18 Jan 95 -- Initial release
**  22 Jun 97 -- v1.2  Modified so that all increases in a score during one
**               turn are announced together
*/

#include "version.t"
#include "heartb.t"

notifyVersion : versionTag
    id="$Id: notify.t,v 1.2 1997/06/23 01:09:37 sgranade Exp $\n"
    author = 'Stephen Granade'
    func = 'score notification'
;

replace incscore: function( amount )
{
    global.score += amount;
    if (scoreWatcher.notifyMe != nil) {
        scoreWatcher.amt += amount;
    }
    scoreStatus( global.score, global.turnsofar );
}

scoreWatcher: object
  warned = nil
  notifyMe = true
  amt = 0
  wantheartbeat = {
      return (self.notifyMe);
  }
  heartbeat = {
    if (self.amt == 0)
      return;
    "\b\([Your score has <<(amt > 0) ? "increased" : "decreased">> by <<
      amt>> point";
    if ((amt > 1) || (amt < -1)) "s";
    if (self.warned == nil) {
// This message is only received the first time
      ".  You can turn these notifications off at any time by typing 'notify'";
      self.warned = true;
    }
    ".]\)\n";
	self.amt = 0;
  }
;

notifyVerb: sysverb
  verb = 'notify'
  sdesc = "notify"
  action( actor ) = {
     "Notification is now ";
     if (scoreWatcher.notifyMe) {
       "off";
       scoreWatcher.notifyMe = nil;
     }
     else {
       "on";
       scoreWatcher.notifyMe = true;
     }
     ".  ";
  }
;

#endif

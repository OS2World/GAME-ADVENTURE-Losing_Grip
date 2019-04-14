#ifndef PARSEERR
#define PARSEERR
#pragma C+

/*
** Parseerr.t -- allows you to make changes to the parseError() and
** preparse() routines without having to replace them each time.  TADS does
** not allow you to use the modify keyword on a function, only replace.
** Therefore, if you have several pieces of code which all want to rewrite
** parseError or preparse (as several of my modules do), all but one will
** lose.  This module defines two new classes: parseErrorItem and
** preparseItem.  All parseErrorItem objects are collected during the
** preinit routine, then parseError (defined in this module) calls the
** myParseError routine in each parseErrorItem.  Similarly, all preparseItem
** objects are collected during preinit; preparse calls myPreparse in each
** item.
**
** To add your own bit of code to parseError:
**   1) Define a parseErrorItem
**   2) In that item, write myParseError.  myParseError is called with the
**      same two arguments as parseError: (errnum, errstr).  Each
**      myParseError routine should return nil if it doesn't want to change
**      the errstr or return a string if it does want to change the errstr.
** To add your own code to preparse:
**   1) Define a preparseItem
**   2) In that item, define parseOn and write myPreparse.  parseOn should be
**      set to true whenever the item wants myPreparse to be called.
**      myPreparse is called with one argument, the string passed to preparse.
**      The function should return true if no processing is to go on, nil if
**      it wants the command aborted, or a string if it wants the string
**      replaced in some way.
** For examples, see plurals.t, misc.t, or askabout.t.
**
** Copyright (c) 1996, 1997 Stephen Granade
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
**   3 Oct 96 -- Initial release
**  24 Jun 97 -- v1.2  Compensated for firstobj()/nextobj() bug
*/

#include "version.t"
#include "sysfuncs.t"
#include "funcs.t"

parseErrVersion: versionTag, initialization
    parseErrList = []
    peListLen = 0
    preparseList = []
    ppListLen = 0
    id="$Id: parseerr.t,v 1.2 1997/06/25 01:42:51 sgranade Exp $\n"

    preinit_phase = {
        local obj;

        for (obj = firstobj(parseErrorItem); obj != nil;
                obj = nextobj(obj, parseErrorItem))
            self.parseErrList += obj;
        self.parseErrList = distillList(self.parseErrList);
        self.peListLen = length(self.parseErrList);
        for (obj = firstobj(preparseItem); obj != nil;
                obj = nextobj(obj, preparseItem))
            self.preparseList += obj;
        self.preparseList = distillList(self.preparseList);
        self.ppListLen = length(self.preparseList);
    }
;

class parseErrorItem: object;

parseError: function(errnum, errstr)
{
    local i, rtn;

    for (i = 1; i <= parseErrVersion.peListLen; i++) {
        rtn = (parseErrVersion.parseErrList[i]).myParseError(errnum, errstr);
        if (rtn != nil) return rtn;
    }
    return nil;
}

class preparseItem: object;

preparse: function(str)
{
    local i, obj, rtn;

    for (i = 1; i <= parseErrVersion.ppListLen; i++) {
        if ((obj = parseErrVersion.preparseList[i]).parseOn)
            rtn = obj.myPreparse(str);
        if (rtn != true) return rtn;
    }
    return true;
}

#endif

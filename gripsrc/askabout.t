#ifndef ASKABOUT
#define ASKABOUT
#pragma C+

/*
** Askabout.t changes TADS' parser's default actions when you say "ask xxx
** about yyy."  It stops TADS from saying "I don't know the word "yyy"."
** This is a horribe, nasty kludge which I'm almost ashamed to take credit
** for.  C'est la vie.
** WARNING: this module replaces preparse and parseError.  It will break
**          previous code involving preparse and/or parseError without some
**          planning.  You have been warned.
** At any rate, Copyright (c) 1996, 1997 Stephen Granade
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
**  21 Feb 96 -- Initial release
**   3 Oct 96 -- Changed to work with parseErr.t
*/

#include "parseerr.t"

askaboutVersion : versionTag
    id = "$Id: askabout.t,v 1.1 1997/01/24 00:36:49 sgranade Exp $\n"
;

modify askVerb
    isAsking = nil
;

askaboutPreparse: preparseItem
    parseOn = true
    myPreparse(str) = {
        local i, mystr;

        mystr = str;
        // Remove leading whitespace
        for (i = 1; substr(mystr, i, 1) == ' '; i++);
        mystr = substr(mystr, i, length(mystr) - i + 1);
        if (find(mystr, 'ask ') == 1 && find(mystr, 'about '))
            askVerb.isAsking = true;
        else askVerb.isAsking = nil;
        return true;
    }
;

// If askverb.isAsking is set to true, the player has typed "ask xxx about
//    yyy."
askaboutParseError: parseErrorItem
    myParseError(errno, str) = {
        if (errno == 2 && askVerb.isAsking) {
            return 'There is no reply. ';
        }
        return nil;
    }
;

#endif

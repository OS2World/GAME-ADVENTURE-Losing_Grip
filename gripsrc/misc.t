#ifndef MYMISC
#define MYMISC
#pragma C+
            
/*
** Misc.t --  a few miscellaneous classes I find useful.  Included are:
**
** {NEW CLASSES}
** moveItem -- calls the method "firstMove" when it is first picked up.
**   treasure -- adds a number of points specified by "worth" when it is
**            first picked up.
**   unlistedItem -- unlisted until the first time it is taken
** platformItem -- somewhere between a bed and a chair.  This object
**            was suggested by Neil deMause.
** complex -- prints a complex description in the room listing (until
**            it is first picked up) along the lines of, "Leaning against
**            one wall is a broom."  The complex description is held in
**            "hdesc".
** dthing -- an object with two long description, held in "firstdesc" and
**            "seconddesc."  When the object is first seen, firstdesc is used.
**            Thereafter, seconddesc is used.
** droom -- a room with two ldesc's.  See dthing above.
** conversationPiece -- an object whose sole purpose in life is to have
**            questions asked about it.  Can have more than one separate noun.
**
** {MODIFIED CLASSES}
** fixeditem, decoration -- both now have a "takedesc" which is printed
**            when the player tries to take the item.
** distantItem -- now allows sysverbs to be used on them.  Mostly useful
**            for my debug commands (see debug.t).
** follower -- it now only follows into rooms.  That way, if an actor sits
**            on a chair, the follower won't move into the room containing
**            the chair.
** openable, doorway -- both now have a "wordDesc" which prints "open" if
**            it is open, "closed" if it is closed; and an "aWordDesc" which
**            appends a/an before open/closed.
** switchItem -- now has a "wordDesc" which prints "on" or "off."
**
** {MISCELLANEOUS CHANGES}
** I changed how doLookIn() works for containers.  You can use "all" only
** with take, drop, and put--if you want other verbs to be able to use
** all, set "allowall = true" in their definition.  You can now use
** "drop xxx in yyy" in place of "put xxx in yyy".  You can "doff" (i.e.
** take off) a garment; you can "drink from" something instead of just
** "drink"ing.  "throw xxx on yyy" now mapped to "put xxx on yyy."
** "q" is now a synonym for "quit". 'inside' is now an acceptable synonym for
** the preposition 'in'.
**
** N.B. This module must be #included AFTER plurals.t and wallpap.t in order
**      for everything to work correctly.
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
**  23 Dec 95 -- Initial release
**  26 Mar 96 -- Allowed use of multiple objects (other than all) with look.
**               Suggested by D.J. Picton, after code by MJR.
**   5 Apr 96 -- Disallowed the use of "ALL" by all verbs other than take,
**               drop, and put.  The idea and most of the code came from
**               Neil deMause, again after code by MJR.
**               Added some modifications to Actor suggested by Neil deMause.
**  31 Jul 96 -- Added droom, dthing (if anyone has better names for
**               these, please please please tell me), switchItem.wordDesc,
**               platformItem, and unlistedItem.
**  24 Aug 96 -- Added aWordDesc to doorway and openable.
**               Added conversationPiece
**   3 Oct 96 -- Changed the handling of "all" to use parseErr.t
**  12 Oct 97 -- v1.4 Added "q" as a synonym for "quit".
**   1 Jan 98 -- v1.5 Added 'inside' as a synonym for 'in'
*/

#include "look.t"
#include "parseerr.t"

miscVersion: versionTag
    id = "$Id: misc.t,v 1.5 1998/01/04 21:45:47 sgranade Exp $\n"
    author = 'Stephen Granade (with help from Neil deMause)'
    func = 'miscellaneous code'
;

/*
** Miscellaneous classes which I find useful.
*/

#define moveItem moveitem
#define unlistedItem unlisteditem
#define platformItem platformitem

// A class which notifies us when it's first moved
class moveitem : item
    firstPick = true
    moveInto( location ) = {
        inherited.moveInto(location);
        if (self.firstPick) {
            self.firstPick = nil;
            self.firstMove;
        }
    }
    firstMove = {}
;

// Treasure, which gives points when it's first picked up.  worth gives the
//  number of points the treasure is worth
class treasure : moveitem
    worth = 0
    firstMove = { incscore(self.worth); }
;

// A class which isn't listed until it is first taken
class unlisteditem : moveitem
    isListed = nil
    firstMove = { self.isListed = true; }
;

// PlatformItem, somewhere between a bed and a chair
class platformitem : chairitem
    statusPrep='on'
    noexit = {
        "%You're% not going anywhere until %you% get%s% off
            of <<self.thedesc>>. ";
        return nil;
    }
;

// Complex, which has a complex description until it is first moved.  Put
//  the complex description in hdesc.
class complex : moveitem
    has_hdesc = { return self.firstPick; }
;

// A thing which has two ldescs, the first of which is only printed once
class dthing : thing
    firstLdesc = true
    ldesc = {
        if (self.firstLdesc == true) {
            self.firstLdesc = nil;
            self.firstdesc;
        }
        else self.seconddesc;
    }
    firstdesc = "It looks like an ordinary <<self.sdesc>> to %you%."
    seconddesc = "It looks like an ordinary <<self.sdesc>> to %you%."
;

// Droom, a room with two ldescs
class droom : room
    ldesc = {
        if (!self.isseen)
            self.firstdesc;
        else self.seconddesc;
    }
;

// To use a conversationPiece, give it any noun you want the player to be
//  able to ask about but don't want to code an object for, like "love."
//  If you use more than one noun with the same conversationPiece, you can
//  pick out which one is being asked about by using find(objwords(2),
//  'word').  If find() doesn't return nil, that's the word being asked about.
class conversationPiece: object
    isCP = true    // For an easy check
    factTold = []  // From actor.t, another module
    verIoAskAbout( actor ) = {}
    ioAskAbout( actor, dobj ) =
    {
        dobj.doAskAbout( actor, self );
    }
;

/*
** Modifications to standard classes which I like.
*/

// Fixed items now display takedesc when you try to take them, for easy
//  customization.
modify fixeditem
    takedesc = "%You% can't have <<self.thedesc>>. "
    replace verDoTake( actor ) = {}
    doTake(actor) = { takedesc; }
;

// Decorations also use a takedesc.  In addition, adding (!v.issysverb) to
//  dobjGen allows my debug commands, such as "bamf xxx", to work.
modify decoration
    replace dobjGen(a, v, i, p) = {
        if ((v != inspectVerb) && (v != takeVerb) && (!v.issysverb))
        {
            "Don't worry about <<self.thedesc>>.  ";
            exit;
        }
    }
    takedesc = "Don't worry about <<self.thedesc>>.  "
;

// This allows my debug commands, such as "bamf xxx", to work.
modify distantItem
    dobjGen(a, v, i, p) = {
        if (!v.issysverb && v != inspectVerb && v != askVerb && v != tellVerb)
            pass dobjGen;
    }
;

// Modifying follower so you only follow into a room
modify follower
    doFollow(actor) = {
        local loc;

        loc = self.myactor.location;
        while (loc.location) loc = loc.location;
        actor.travelTo(loc);
    }
;

// I've added two new methods to class openable--wordDesc and aWordDesc.
//  wordDesc returns "open" if the object is open, "closed" otherwise.
//  aWordDesc appends a/an to the front of open/closed.
modify openable
    wordDesc = {
        self.isopen ? "open" : "closed";
    }
    aWordDesc = {
        "a<<self.isopen ? "n open" : "closed">>";
    }
;

// Ditto for doorways.
modify doorway
    wordDesc = {
        self.isopen ? "open" : "closed";
    }
    aWordDesc = {
        self.isopen ? "an open" : "a closed";
    }
;

// Similarly ditto for switches.
modify switchItem
    wordDesc = {
        self.isActive ? "on" : "off";
    }
;

// container modified to handle "look in" differently
modify container
    doLookin(actor) = {
        if (self.contentsVisible && itemcnt(self.contents) <> 0)
            "In <<self.thedesc>> %you% see%s% <<listcont(self)>>.  ";
        else "There's nothing in <<self.thedesc>>.  ";
    }
;

/*
** Modifications to verbs and prepositions.
*/

// Handle "all"--I don't like how you can use "all" with, well, everything
modify deepverb
    doDefault (actor, prep, iobj) = {
        if (self.allowall == nil && objwords(1) == ['A']) {
            global.allMessage = 'You can\'t use "all" with this verb.';
            return [];
        }
        else pass doDefault;
    }
;

modify takeVerb
    allowall=true
;

// Besides allowing "all" to work with drop, allow "drop xxx in yyy" ==
//  "put xxx in yyy" and "drop xxx on yyy" == "put xxx on yyy".
modify dropVerb
    allowall=true
    ioAction(inPrep) = 'PutIn'
    ioAction(onPrep)='PutOn'
;

modify putVerb
    allowall=true
;

miscParseError: parseErrorItem
    myParseError(num, str) = {
        // If there's an allMessage waiting, use it instead of the default
        if (global.allMessage != nil) {
            local r;

            r = global.allMessage;
            global.allMessage = nil;
            return r;
        }
        return nil;
    }
;

modify removeVerb
    verb = 'doff'
;

modify drinkVerb
    verb = 'drink from'
;

modify throwVerb
    ioAction(onPrep) = 'PutOn'
;

modify quitVerb
    verb = 'q'
;

modify inPrep
    preposition = 'inside'
;

#endif

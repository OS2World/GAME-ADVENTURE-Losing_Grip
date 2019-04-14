#ifndef BUGFIX
#define BUGFIX
#pragma C+

/*
** Bugs.t -- bug fixes for TADS 2.2
**
** Please note that this module is intended to fix library bugs, not
** actual bugs within the TADS runtime itself.
**
** {BUGS FIXED}
** thing.cantReach() no longer quits w/o printing an error message if the
**   player is not in a nestedroom.  This was a problem if contentsReachable
**   was hand-set to nil. cantReach() now also checks to see if the actor
**   passed to it is _not_ an actor, in which case it prints a generic
**   message.
** thing.doUnboard() no longer prints "Okay, you're no longer in xxx"
**   whether or not you're actually IN xxx.  By default, an object's
**   statusPrep is "on", so doUnboard() now prints "Okay, you're no longer
**   on xxx" unless you change statusPrep deliberately.  This fixes a
**   related bug with theFloor.
** thing.verDoTakeOut() now checks whether or not you can actually take
**   the item.
** lockable.verDoUnlockWith() now checks to see if the door requires a key to
**   be unlocked.
** Throwing items at the floor no longer results in the response "You
**   miss."
** Looking at the floor no longer gives the default response "There's
**   nothing on the floor" whether or not there is something in the room.
**   My solution to this was to prevent any description of the floor's
**   "contents" at all.
** vehicle messages now take statusPrep & outOfPrep into account.
** showcontcont() now checks for qsurfaces correctly.
** distantItems now allow you to ask or tell an actor about them without
**   the odd response, "It is too far away."
** container, surface, transparentItem, and openable have had doSearch added,
**   so that searching them does not result in "You find nothing of interest."
** The qsurface class was left out of adv.t. I've added it back in.
** standVerb.action() now checks verDoUnboard() before calling doUnboard()
** thing.circularMessage() always assumed you were putting something _in_
**   something else, despite the fact that circularMessage can be called
**   from doPutOn.
** lightsource.doTurnon() now sets islit in the item _as well as_ isActive.
** reachable added to movableActor so that you can command objects which are
**    in your inventory. This requires a change to visibleList: see below
** visibleList() now takes two arguments. This is to handle an obscure bug
**    which occurs when the player commands an object in his/her inventory
**    to do something to another object in his/her inventory. The change in
**    visibleList() required a cosmetic change in deepverb.validDoList().
** dirPrep now has the abbreviations 'n' for 'north', etc.
** 
**
** {BUGS TOYED WITH}
** There seems to be problems with the random number generator.  To
**   try to avoid such problems, a new function RAND is added.
**
**
** {BUGS REQUIRING WORKAROUNDS}
** If you modify basicMe, you must set noun='', like so:
**   modify basicMe {
**       noun = ''
**       [your code here]
**   If you do not do this, then all previous nouns by which basicMe was known
**   will vanish.
** There is a problem with using firstobj()/lastobj() in preinit(): if you do
**   so, you will get objects TWICE instead of once.
**
**
** This collection of bug fixes was compiled by Stephen Granade.  It
** is public domain--do whatever you like with it.  If you know of any
** other library bugs in TADS, please contact me for their inclusion in this
** module.  I can be reached at sgranade@phy.duke.edu or sgranade@iname.com.
**
** Credits:
**   Unbeknownst to them, Neil deMause, Magnus Olsson, Andrew Pontious, and
**   Patrick Kellum contributed to this file.  Beknownst to him, Cody Sandifer
**   reported the doSearch/lookIn bugs in container, surface, transparentItem,
**   and openable; found the lightsource.islit problem; uncovered a bug when
**   the player commanded an object in his/her inventory; and pointed out that
**   qsurface had gone missing from adv.t.
**
** Version history:
**   2 Aug 96 -- Initial release
**  22 Aug 96 -- lockable bug fix added
**   2 Sep 96 -- cantReach bug fix added
**  20 Sep 96 -- More changes to theFloor, suggested by Magnus Olssen
**  22 Nov 96 -- Patch applied to vehicle, making it use outOfPrep
**  15 Jan 97 -- basicMe modification bug mentioned in docs
**   2 Mar 97 -- container, surface, transparentItem, and openable bugs fixed
**  12 Mar 97 -- v1.4  standVerb bug fix added
**   4 Apr 97 -- v1.5  modification to undo removed, as it was unnecessary
**  15 Apr 97 -- v1.6  thing.circularMessage fix
**  22 Jul 97 -- v1.7  lightsource.doTurnon/islit fix; inanimate object
**               command fix
**  19 Jan 98 -- v1.8  dirPrep fix
**  15 Feb 98 -- v1.9  Changed 'in' to 'on' in surface's doSearch()
**
** Current version: $Id: bugs.t,v 1.8 1998/01/20 01:15:59 sgranade Exp $
*/

modify thing
    statusPrep = "on"        // So that everything has a preposition
    replace cantReach(actor) = {
        // This first line is to handle the (slightly bizarre) case of the
        //  player commanding an inanimate object
        if (!actor.isactor) {
            "\^<<actor.thedesc>> <<actor.isThem ? "do" : "does">> not
                respond. ";
            return;
        }
        if (self.location == nil) {
            if (actor.location.location)
               "%You% can't reach that from <<actor.location.thedesc>>. ";
            else "%You% can't reach that. ";    // Added error message
            return;
        }
        if (!self.location.isopenable || self.location.isopen)
            self.location.cantReach(actor);
        else "%You%'ll have to open <<self.location.thedesc>> first. ";
    }
    replace verDoUnboard(actor) = {
        if (actor.location != self) {
            "%You're% not <<self.statusPrep>> <<self.thedesc>>! ";
        }
        else if (self.location == nil) {
            "%You% can't leave <<self.thedesc>>! ";
        }
    }
    replace doUnboard(actor) = {
        // Trivia: this is the only place "fastenitem" is referred to in adv.t
        if (self.fastenitem) {
            "%You%'ll have to unfasten <<actor.location.fastenitem.thedesc
                >> first. ";
        }
        else {
            "Okay, %you're% no longer <<self.statusPrep>> <<self.thedesc>>. ";
            self.leaveRoom(actor);
            actor.moveInto(self.location);
        }
    }
    replace verDoTakeOut(actor, io) = {
        if (io != nil && !self.isIn(io))
            "\^<<self.thedesc>> isn't in <<io.thedesc>>. ";
        else self.verDoTake(actor);        // Make sure the obj can be taken
    }
    replace circularMessage(io) = {
        local cont, prep;

        // prep is set to 'on' if io.location is a surface, 'in' otherwise
        prep = (io.location.issurface) ? 'on' : 'in';
        "%You% can't put <<thedesc>> <<prep>> <<io.thedesc>>, because <<
            io.thedesc>> <<io.isThem ? "are" : "is">> <<
            io.location == self ? "already" : "">> <<prep>> <<
            io.location.thedesc>>";
        for (cont = io.location; cont != self; cont = cont.location) {
            ", which <<cont.isThem ? "are" : "is">> <<
                cont.location == self ? "already" : "">> <<prep>> <<
                cont.location.thedesc>>";
        }
        ". ";
    }
;

// lockable modified so that trying to unlock a lockable with a key when one
//  isn't needed (i.e. mykey=nil) results in an error message
modify lockable
    replace verDoUnlockWith(actor, io) = {
        if (!self.islocked)
            "<<self.isThem ? "They're" : "It's">> not locked! ";
        else if (self.mykey == nil)
            "%You% %do%n't need anything to unlock <<self.isThem ? "them" :
                "it">>. ";
    }
;

// theFloor modified so that "throw xxx at floor" doesn't result in
//  "you miss," which seems rather silly. Its ldesc is also modified to
//  prevent "There is nothing on the floor" messages
modify theFloor
    ldesc = "It lies beneath you. "
    ioThrowAt(actor, dobj) = {
        "Thrown. ";
            dobj.moveInto(actor.location);
    }
;

// vehicle modified so that messages now take statusPrep & outOfPrep into
// account
modify vehicle
    verDoBoard(actor) = {
        if (actor.location == self)
            "%You're% already <<self.statusPrep>> <<self.thedesc>>! ";
        else if (actor.isCarrying(self))
            "%You%'ll have to drop <<self.thedesc>> first! ";
    }
    doBoard(actor) = {
        "Okay, %you're% now <<self.statusPrep>> <<self.thedesc>>. ";
        actor.moveInto(self);
    }
    noexit = {
        "%You're% not going anywhere until %you% get%s% <<self.outOfPrep>> <<
            self.thedesc>>. ";
        return (nil);
    }
    dobjGen(a, v, i, p) = {
        if (a.isIn(self) && v != inspectVerb && v != getOutVerb &&
            v != outVerb) {
            "%You%'ll have to get <<self.outOfPrep>> <<self.thedesc>> first. ";
            exit;
        }
    }
    iobjGen(a, v, d, p) = {
        if (a.isIn(self) && v != putVerb) {
            "%You%'ll have to get <<self.outOfPrep>> <<self.thedesc>> first. ";
            exit;
        }
    }
;

// container modified so doSearch() doesn't return "You find nothing of
// interest."  doLookin() has also been decoupled from ldesc.
modify container
    verDoSearch(actor) = {}
    doSearch(actor) = {
        if (self.contentsVisible && itemcnt(self.contents) != 0)
            "In <<self.thedesc>> %you% see%s% <<listcont(self)>>. ";
        else "There's nothing in <<self.thedesc>>. ";
    }
    doLookin(actor) = { self.doSearch(actor); }
;

// transparentItem also modified so doSearch() doesn't return "You find
// nothing of interest."  doLookin() has also been decoupled from ldesc.
modify transparentItem
    verDoSearch(actor) = {}
    doSearch(actor) = {
        if (self.contentsVisible && itemcnt(self.contents) != 0)
            "In <<self.thedesc>> %you% see%s% <<listcont(self)>>. ";
        else "There's nothing in <<self.thedesc>>. ";
    }
    doLookin(actor) = { self.doSearch(actor); }
;

// openable modified so doSearch() doesn't return "You find nothing of
// interest."  Also the verDoSearch & verDoLookin functions take into account
// whether or not the openable is opened.
modify openable
    verDoSearch(actor) = {
        if (!self.isopen && !isclass(self, transparentItem))
            "It's closed. ";
    }
    verDoLookin(actor) = { self.verDoSearch(actor); }
;

// surface modified so doSearch() doesn't return "You find nothing of
// interest."
modify surface
    verDoSearch(actor) = {}
    doSearch(actor) = {
        if (itemcnt(self.contents) != 0)
            "On <<self.thedesc>> %you% see%s% <<listcont(self)>>. ";
        else "There's nothing on <<self.thedesc>>. ";
    }
;

modify standVerb
    outhideStatus = 0
    action(actor) = {
        if (actor.location == nil || actor.location.location == nil)
            "%You're% already standing! ";
        else {
            self.outhideStatus = outhide(true);
            actor.location.verDoUnboard(actor);
            if (outhide(self.outhideStatus))
                actor.location.verDoUnboard(actor);
            else
                actor.location.doUnboard(actor);
        }
    }
;

replace showcontcont: function(obj)
{
    if (itemcnt(obj.contents)) {
        if (obj.issurface) {
            if (!obj.isqsurface) {
                "Sitting on <<obj.thedesc>> is <<listcont(obj)>>. ";
            }
        }
        else if (obj.contentsVisible && !obj.isqcontainer) {
            "\^<<obj.thedesc>> seems to contain <<listcont(obj)>>. ";
        }
    }
    if (obj.contentsVisible && !obj.isqcontainer)
        listfixedcontcont( obj );
}

modify distantItem
    dobjGen(a, v, i, p) = {
        if (v != askVerb && v != tellVerb)
            pass dobjGen;
    }
;

// Fix problems w/lightsource
modify lightsource
    islit = nil
    doTurnon(actor) = {
        local waslit = actor.location.islit;

        // turn on the light
        self.isActive = true;
        self.islit = true;    // This should set things to rights
        "You switch on <<self.thedesc>>";

        // if the room wasn't previously lit, and it is now, describe it
        if (actor.location.islit && !waslit) {
            ", lighting the area.\b";
            actor.location.enterRoom(actor);
        }
        else ".";
    }
;

// Add reachable to movableActor so you can address things in your inventory
modify movableActor
    reachable = []
;

// Add qsurface back in to adv.t.
class qsurface: surface
    isqsurface = true
;

// Add 'n' etc. to dirPrep
modify dirPrep
    preposition = 'n' 's' 'e' 'w' 'u' 'd'
;

// visibleList now takes two arguments: the object whose visible contents are
// being returned and the actor who is performing the verb whose validDoList
// called visibleList. This is for two reasons: one, so we don't double-count
// the actor's contents; two, so we can take the player's contents into
// account in the case that the player isn't the actor.
replace visibleList: function(obj, actor)
{
    local ret = [];
    local i, lst, len;
    
    // Don't look in "nil" objects
    if (obj == nil) return ret;
    
    if (!isclass(obj, openable)
        || (isclass(obj, openable) && obj.isopen)
        || obj.contentsVisible)
    {
        lst = obj.contents;
        len = length(lst);
        ret += lst;
        for (i = 1 ; i <= len ; ++i) {
            if (lst[i] != actor)  // Don't recurse into the actor
                ret += visibleList(lst[i], actor);
	}
	// Since the "Me" object never shows up in room.contents, if Me is
	// located in obj and actor != Me, add Me.contents to the list
	if (actor != Me && Me.location == obj)
	    ret += visibleList(Me, actor);
    }

    return(ret);
}

// deepverb.validDoList changed to use new arguments to visibleList
modify deepverb
    validDoList(actor, prep, iobj) = {
	local ret;
	local loc;

	loc = actor.location;
	while (loc.location) loc = loc.location;
	ret = visibleList(actor, actor) + visibleList(loc, actor)
	       + global.floatingList;
	return(ret);
    }
;

RAND: function(x)
{
    return (((rand(16*x)-1)/16)+1);
}

#endif

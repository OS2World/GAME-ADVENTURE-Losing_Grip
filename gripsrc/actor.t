#ifndef ACTOR
#define ACTOR
#pragma C+

/*
** Actor.t -- a module which adds more functionality to the basic TADS
** actor class, as well as introducing several functions which are useful
** in and of themselves.
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
**  18 Oct 95 -- Initial release
**  22 Dec 95 -- Added version tracking using Jeff Laing's routines
**  23 Aug 96 -- Added heartbeat routines rather than timedevents.  Insured
**               that basicMe doesn't use the heartbeat function.  Added
**               askme routine to Actor
**   4 Oct 96 -- Added noAlreadyTold flag to Actor
**  19 Oct 96 -- Split modifications into Actor class and trackActor class
**  20 Oct 96 -- Fixed problem with missing capitalization
**  13 Jan 97 -- Added "tell about" handling (of a sort).  Added arrivedesc and
**               leavedesc to trackActor
**  20 Jan 97 -- Added checkAskAbout routine to Actor class & modified
**               actorAction to take advantage of it
**  12 Mar 97 -- v1.4  Changed outhide() calls to use returned status values
**   4 Apr 97 -- v1.5  Modified thedesc & adesc for Actors & trackActors.
**  20 Jul 97 -- v1.6  Added push/pull/etc. code to Actor and added
**               verification routine to Actor.verDoTellAbout()
*/

#include "version.t"
#include "funcs.t"
#include "heartb.t"

actorVersion : versionTag
    id = "$Id: actor.t,v 1.6 1997/07/20 21:30:57 sgranade Exp $\n"
    author = 'Stephen Granade'
    func = 'advanced actor handling'
;

/*
** Some of the code in this module has been lifted from adv.t.  If any
** changes are made to adv.t in the future, they must be updated as well.
** All such changes are prefaced by "// WARNING:".
*/

// New additions to "global" in adv.t.  dirList is used by the actor
//  wandering functions.  You can add new directions by adding them to
//  the end of dirList and modifying the function wander(), below
modify global
    dirList = [
        ['n' 'north' 'south']  ['s' 'south' 'north']
        ['e' 'east' 'west']    ['w' 'west' 'east']
        ['ne' 'northeast' 'southwest'] ['sw' 'southwest' 'northeast']
        ['nw' 'northwest' 'southeast'] ['se' 'southeast' 'northwest']
        ['u' 'up']  ['d' 'down']
    ]
;


// New additions to "thing" in adv.t
modify thing
    factTold = []
    ioAskAbout(actor, dobj) = {
        if (find(self.factTold, dobj))
            dobj.alreadyTold;
        else pass ioAskAbout;
    }
    verDoAskFor(actor, io) = {
        "\^<<self.thedesc>> ignores you.  ";
    }
    verIoAskFor(actor) = {}
    ioAskFor(actor, dobj) = { dobj.doAskFor(actor, self); }
;

// WARNING: the moveInto code has been taken from adv.t
modify Actor
    actorOuthideStatus = 0
    thedesc = "<<self.sdesc>>"
    adesc = "<<self.sdesc>>"
    alreadyTold = "\"I've told you all I know about that.\"  "
    noAlreadyTold = nil
    askme = nil        // Set to be the property pointer 
    moveInto( obj ) = {
        local loc;

        if (self.myfollower) {
            if (!(obj && uberloc(obj) == uberloc(self)))
                self.myfollower.moveInto( self.location );
        }
        //
        //   For the object containing me, and its container, and so forth,
        //   tell it via a Grab message that I'm going away.
        //
        loc = self.location;
        while (loc) {
            loc.Grab(self);
            loc = loc.location;
        }

        if (self.location)
            self.location.contents -= self;
        self.location = obj;
        if (obj) obj.contents += self;
    }
    doAskAbout(actor, io) = {
        if (!self.noAlreadyTold)
            io.factTold += self;
        if (datatype(self.askme) == 13) {
            setit(io);
            switch (proptype(io, self.askme)) {
                case 3:
                    "\^<<self.thedesc>> says, \"<<io.(self.askme)>>\" ";
                    return;
                case 6:
                case 9:
                    io.(self.askme);
                    return;
                default:
                    self.disavow;
                    return;
            }
        }
        pass doAskAbout;
    }
    verDoAskFor(actor, io) = {
        "\^<<self.thedesc>> doesn't seem to take kindly to any kind of
            requests. ";
    }
    doAskFor(actor, io) = { self.verDoAskFor(actor, io); }
    verDoTellAbout(actor, io) = {
        self.verDoAskAbout(actor, io);
    }
    doTellAbout(actor, io) = {
        self.doAskAbout(actor, io);
    }
    actorAction(v,d,p,i)={
        if (v==tellVerb && d==Me && p==aboutPrep) {
            self.checkAskAbout(i); // See if we can ask about this object
            exit;
        }
        if (v==giveVerb && i==Me && p==toPrep) {
        // Verify that we can give this to us
            self.actorOuthideStatus = outhide(true);
            self.verDoAskFor(Me, d);
            if (outhide(self.actorOuthideStatus)) {
                self.verDoAskFor(Me, d);
                exit;
            }
            self.doAskFor(Me, d);
            exit;
        }
        pass actorAction;
    }
    verDoSearch(actor)={"How rude!";}
    verDoPush(actor)={"How rude!";}
    verDoPull(actor)={"How rude!";}
    verDoMove(actor)={"How rude!";}
    verDoPoke(actor)={"How rude!";}
    verDoTouch(actor)={"How rude!";}
    checkAskAbout(i) = {
    // Don't let the player see this next part
        self.actorOuthideStatus = outhide(true);
        self.verDoAskAbout(Me, i);
        // Oops, we can't ask us about this object
        if (outhide(self.actorOuthideStatus)) {
            self.verDoAskAbout(Me, i);
        }
        else self.doAskAbout(Me, i);
    }
;

// trackActor, the class which allows motion on a track
class trackActor: Actor
    motionList = [[]]
    motionListNum = 1
    motionListListNum = 1
    isMoving = nil
    hasArrived = nil
    moveTurn = -1
    actionTurn = -1

    leavedesc(dirStr) = {
        "\b\^<<self.thedesc>> leaves to the <<dirStr>>. ";
    }
    leaveupdowndesc(dirStr) = {
        "\b\^<<self.thedesc>> climbs <<dirStr>>. ";
    }
    arrivedesc(dirStr) = {
        "\b\^<<self.thedesc>> arrives from the <<dirStr>>. ";
    }
    arriveupdowndesc(dirStr) = {
        "\b\^<<self.thedesc>> arrives from <<dirStr>>. ";
    }
    firstMove = {
        if (self.motionListNum > 1 || self.isMoving) return;
        self.isMoving = true;
    }
    wantheartbeat = true
    heartbeat = {            // Used to be moveDaemon
        local    i, j;

        i = self.motionListNum;
        j = self.motionListListNum;
        if (self.actionTurn == global.turnsofar)
            self.actionDaemon;
        if (!self.isMoving) {
            if (self.hasArrived) {
                self.hasArrived = nil;
                self.arriveDaemon;
            }
            if (self.moveTurn == global.turnsofar)
                self.isMoving = true;
            else return;
        }
        if (!wander(self, self.motionList[i][j])) return;
        self.motionListListNum++;
        if (length(self.motionList[i]) < self.motionListListNum) {
            self.isMoving = nil;
            self.hasArrived = true;
            self.motionListNum++;
            self.motionListListNum = 1;
        }
    }
    arriveDaemon = {}
    actionDaemon = {}
    doorLocked(dest) = {}
;

// Modifying follower so the command "follow" results only in a follow into
//  a room
modify follower
    doFollow( actor ) = {
        actor.travelTo(uberloc(self.myactor));
    }
;

modify basicMe
    noun = ''        // To avoid strange bug in which the nouns associated w/me
    verDoAskAbout(actor, io) = {    // are otherwise erased (?!?)
        "You only know what you know.  ";
    }
;

// New verb: "Ask 'x' for 'y'"
modify askVerb
    ioAction( forPrep ) = 'AskFor'
;

// New preposition: for
forPrep : Prep
    preposition = 'for'
    sdesc = "for"
;

/*
**  New classes of objects, for those of you who just don't like those
**  boring old classes.
*/

// An object which belongs to someone else, and thus can't be taken by the
//  player
class owned : fixeditem
    owner = ""
    isListed = true
    verDoTake(actor) = {
        "It belongs to <<self.owner>>, not you.  ";
    }
;

/*
** A function or two that needs to be available to several modules
*/

// A function which returns the number of actors in a room
actorin : function(obj)
{
    local i, cont, len, amount;

    cont = deepcont(obj);
    len = length(cont);
    amount = 0;
    for (i = 1; i <= len; i++) {
        if (isclass(cont[i], movableActor))
            amount++;
    }
    return amount;
}

// A function to return all actors in a room
actorcont : function(obj)
{
    local i, cont, len, acont;

    cont = deepcont(obj);      // Get the contents
    len = length(cont);
    acont = [];                // Actors in the room

    for (i = 1; i <= len; i++) {
        if (isclass(cont[i], movableActor))
            acont += cont[i];
    }
    return acont;
}

// A function to list all actors in a room
actorlist : function(obj)
{
    local i, len, acont;

    acont = actorcont(obj);
    len = length(acont);
    for (i = 1; i <= len; i++) {
        if (i > 1) {
            if (i == len) {
                if (i == 2) " and ";
                else ", and ";
            }
            else ", ";
        }
        acont[i].thedesc;
    }
}

// Makes an actor wander.  It returns true if we're ok to go to the next
//  wander location, nil if we're not
// To see how to make wander() support new directions, see Actor.doc
wander: function(actor, dir)
{
    local dest, dirNum;

    for (dirNum = 1; dirNum < 11; dirNum++)
        if (global.dirList[dirNum][1] == dir)
            break;
    if (dirNum >= 11)
        return true;
    dest = uberloc(actor);
    switch (dirNum) {
        case 1:
            dest = dest.north;
            break;
        case 2:
            dest = dest.south;
            break;
        case 3:
            dest = dest.east;
            break;
        case 4:
            dest = dest.west;
            break;
        case 5:
            dest = dest.ne;
            break;
        case 6:
            dest = dest.sw;
            break;
        case 7:
            dest = dest.nw;
            break;
        case 8:
            dest = dest.se;
            break;
        case 9:
            dest = dest.up;
            break;
        case 10:
            dest = dest.down;
            break;
    }
    if (isclass(dest, doorway)) {
        if (dest.islocked) {
            actor.doorLocked(dest);
            return nil;
        }
        dest.isopen = true;
        if (dest.otherside)
            dest.otherside.isopen = true;
        dest = dest.doordest;
    }
    if (uberloc(Me) == uberloc(actor)) {
        if (dirNum < 9)
            actor.leavedesc(global.dirList[dirNum][2]);
        else actor.leaveupdowndesc(global.dirList[dirNum][2]);
    }
    actor.moveInto(dest);
    if (uberloc(Me) == uberloc(actor)) {
        if (dirNum < 9)
            actor.arrivedesc(global.dirList[dirNum][3]);
        else actor.arriveupdowndesc(dirNum == 9 ? 'below' : 'above');
    }
    return true;
}

#endif

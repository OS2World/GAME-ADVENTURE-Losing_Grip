#ifndef DETECTOR
#define DETECTOR
#pragma C+

/*
** Detect.t detects when the player has used save, restore, undo, &c. and
**  allows you to rerandomize behavior, &c. so the player can't use these
**  verbs to solve a puzzle.  Put the detector object in the room where you
**  want to watch for players saving/restoring.
** I have recently rewritten it incorporating ideas that I got after seeing
**  Jeff Laing's modules.  His modules are great; I just didn't want to throw
**  away my old code.  I've credited him in the version object below.
** Copyright (c) 1995-1997 Stephen Granade
** You are permitted to distribute this module freely, as long as 1) my name
** is left on it, and 2) you keep all files together.  You may also use
** this module in any game you like in any form you like.  Hack away at
** it, if you so desire.  All I ask is that you credit me and Jeff Laing in
** some way in your game.
** I would welcome any comments on or suggestions for this module.  I can be
** reached at:
**  Duke University Physics Department
**  Box 90305
**  Durham, NC  27708-0305
**  U.S.A.
**  sgranade@phy.duke.edu
**
** Version history:
**   7 Aug 94 -- Initial release
**  23 Dec 95 -- Added version tracking using Jeff Laing's routines and
**               rewrote much of the code using his ideas
**   4 Apr 97 -- Added predetector; added preLoc & postLoc flags to detector.
**  24 Jun 97 -- v1.2  Modified preinit_phase to compensate for TADS bug
*/

#include "sysfuncs.t"
#include "funcs.t"

detectVersion: versionTag,initialization
    id="$Id: detect.t,v 1.2 1997/06/25 01:42:45 sgranade Exp $\n"
    func='sysverb detection'
    author='Jeff Laing and Stephen Granade'

    detectList = []
    preDetectList = []
    preLocation = nil        // To hold where the player started out
    preinit_phase={
        local o;

        self.detectList = [];
        self.preDetectList = [];

        // make a list of all predetectors
        for (o = firstobj(predetector); o != nil; o = nextobj(o, predetector)) {
            self.preDetectList += o;
        }
        // Compensate for TADS firstobj()/nextobj() bug
        self.preDetectList = distillList(self.preDetectList);

        // make a list of all detectors
        for (o = firstobj(detector); o != nil; o = nextobj(o,detector)) {
            self.detectList += o;
        }
        // Compensate for TADS firstobj()/nextobj() bug
        self.detectList = distillList(self.detectList);
    }

    init_phase={}
;

// predetectors are objects which have their methods called _before_
//  save/restore/undo processing.  If you want an object whose methods are
//  called after s/r/u processing, use the detector class.
class predetector: object
    preSaveGame = ""
    preRestoreGame = ""
    preUndoMove = ""
;

// preLoc & postLoc are flags: if preLoc is true, the player was in the room
//  with the detector before save/restore/undo; if postLoc is true, the player
//  was in the room with the detector after s/r/u.
class detector: object
    saveGame(preLoc, postLoc) = ""
    restoreGame(preLoc, postLoc) = ""
    undoMove(preLoc, postLoc) = ""
;

preSysverbDetected: function(method)
{
    local obj,list;

    list = detectVersion.preDetectList;// copy the list
    while (length(list)>0) {           // while it's not empty
        obj = car(list);               // send its leader
        list = cdr(list);              // and then move to the next one
        if (obj.location == Me.location)
            obj.(method);
    }
}

sysverbDetected: function( method )
{
    local obj,list;

    list = detectVersion.detectList;// copy the list
    while (length(list)>0) {        // while it's not empty
        obj = car(list);            // send its leader
        list = cdr(list);           // and then move to the next one
        obj.(method)                // a message (passed as a parameter)
          (obj.location==detectVersion.preLocation, obj.location==Me.location);
    }
}

modify saveVerb
    saveGame(actor) = {
        local retn, loc;

        loc = Me.location;
        preSysverbDetected(&preSaveGame);
        retn = inherited.saveGame(actor);
        detectVersion.preLocation = loc;
        if (retn)
            sysverbDetected(&saveGame);
        return retn;
    }
;

modify restoreVerb
    restoreGame(actor) = {
        local retn, loc;

        loc = Me.location;
        preSysverbDetected(&preRestoreGame);
        retn = inherited.restoreGame(actor);
        detectVersion.preLocation = loc;
        if (retn)
            sysverbDetected(&restoreGame);
        return retn;
    }
;

modify undoVerb
    undoMove(actor) = {
        local loc;

        loc = Me.location;
        preSysverbDetected(&preUndoMove);
        inherited.undoMove(actor);
        detectVersion.preLocation = loc;
        sysverbDetected(&undoMove);
        abort;
    }
;

modify basicStrObj
    doSave( actor ) = {
        local loc;

        loc = Me.location;
        preSysverbDetected(&preSaveGame);
        if (inherited.saveGame(actor)) {
            detectVersion.preLocation = loc;
            sysverbDetected(&saveGame);
        }
        abort;
    }

    doRestore( actor ) = {
        local loc;

        loc = Me.location;
        preSysverbDetected(&preRestoreGame);
        if (inherited.restoreGame(actor)) {
            detectVersion.preLocation = loc;
            sysverbDetected(&restoreGame);
        }
        abort;
    }
;

#endif

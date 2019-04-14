/* ex:set ts=4 sw=4:
 *
 * sysfuncs.t:    customized version of std.t
 *
 * This module contains the standardized functions that I include into all
 * TADS games.  It contains most of the functions provided by the standard
 * <std.t> but also defines the default hook routines for some bug-fixing
 * and for some rearrangement of output.
 *
 * The module also provides a standard initialization mechanism for other
 * modules which are included.  Rather than need to keep track of what
 * needs to be initialized, the user can concentrate on writing the game.
 *
 * Each module which requires initialization should declare an object of
 * class "initialization".  The function "preinit()" will scan for these
 * objects and will call the "prescan_phase" method in them.  It will also
 * collect all initialization objects which have "init_phase" code methods
 * and keep them.  When "init()" is run, it will first invoke each of these
 * methods; when finished, it will call the function "gameinit()" which
 * should perform all remaining game-specific initialization.
 *
 * This module is Copyright (c) 1994 Jeff Laing.  Permission to use any or all
 * of this code in other TADS games is granted provided credit is given in
 * your "CREDITS" command for this code and that you leave this copyright
 * message in the source whenever distributed.  Please make all changes in
 * an backward compatible manner (where possible) and make them available
 * for free (like I did ;-)
 */

#ifndef SYSFUNCS
#define SYSFUNCS
#pragma C+

#include "version.t"

sysfuncsVersion: versionTag
    id="$Id: sysfuncs.t,v 1.4 1997/01/24 00:39:22 sgranade Exp $\n"
;

/*
 * this module provides the following functions as entry points
 */
preinit:     function;        // run at compile time
init:        function;        // run at startup time
gameinit:    function;        // run by init() as last action

/*
 * preinit() will scan all objects of class "initialization".  for each
 * object found, it will call "object->preinit_phase".  It will then check
 * for the existence of a method called "init_phase"; if it is found, the
 * object will be added to "global.init_list" for init() to call later.
 */
class initialization: object ;

/*
 * preinit() is called after compiling the game, before it is written
 * to the binary game file.  It performs all the initialization that can
 * be done statically before storing the game in the file, which speeds
 * loading the game, since all this work has been done ahead of time.
 */
replace preinit: function
{
    local o;

    global.init_list = [];

    for (o=firstobj(initialization); o!=nil; o=nextobj(o,initialization)) {

        // add to the list (for init: to call)
        if (proptype(o,&init_phase)==6)
            global.init_list += o;

        // now do whatever we can in advance
        o.preinit_phase;
    }
}

/*
 *    We work through the list of objects which were found at preinit() time
 *    and call any init_phase methods found.
 *
 *    Once processed, we call the "gameinit()" function which performs the
 *    functions traditionally associated with init() (except those which have
 *    already been automatically called)
 */
replace init: function
{
    local i,len;

    // call all the modules which registered that they wanted initialization
    len = length(global.init_list);
    for (i=1; i<=len; i++) {
        global.init_list[i].init_phase;
    }

    // start the turncounter daemon here as well.
    setdaemon( turncount, nil );             // start the turn counter daemon

    // now call the game specific one
    gameinit();
}

// A sample definition for gameinit
gameinit: function
{
    version.sdesc;
    Me.location = startroom;
    startroom.lookAround(true);
    startroom.isseen = true;
    scoreStatus(0, 0);
}

#endif

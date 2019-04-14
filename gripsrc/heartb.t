#ifndef HEARTBEAT
#define HEARTBEAT
#pragma C+

/* ex:set ts=4 sw=4:
 *  
 * heartbeat.t: come on, have a heart
 *
 * This module is intended to help cut down on the number of individual
 * daemons which are required in a TADS game.  It tackles the problem of the
 * daemon which wants to be called once per turn, sometimes.
 *
 * Every object which has a method defined called "heartbeat" will be
 * collected into a list by preinit().  Then, once every turn, it will be
 * called if the method "wantheartbeat" returns true.  i.e.
 *
 *    for all o in heartlist {    // for every entry in the list
 *        if (o.wantheartbeat)    // if it wants one
 *            o.heartbeat;        // send it
 *    }
 *
 * This module is Copyright (c) 1994 Jeff Laing.  Permission to use any or all
 * of this code in other TADS games is granted provided credit is given in
 * your "CREDITS" command for this code and that you leave this copyright
 * message in the source whenever distributed.  Please make all changes in
 * an backward compatible manner (where possible) and make them available
 * for free (like I did ;-)
 */

#include "version.t"
#include "sysfuncs.t"

heartbeatVersion: versionTag, initialization
    id="$Id: heartb.t,v 1.4 1997/01/24 00:38:04 sgranade Exp $\n"
    author='Jeff Laing'
    func='heartbeat monitoring'
    hblen = 0

    /*
     * called by preinit()
     */
    preinit_phase={
        local o;
        /*
         * inspect every object looking for a heartbeat method.  if we find
         * it, add it to our list
         */
        self.heartlist = [];
        for (o=firstobj(); o!=nil; o=nextobj(o)) {
            if (defined(o,&heartbeat))
                self.heartlist += o;
        }
        // Make sure the scoreWatcher is called last, if defined
#ifdef NOTIFY
        self.heartlist -= scoreWatcher;
        self.heartlist += scoreWatcher;
#endif
        self.hblen = length(self.heartlist);
    }
    /*
     * called by init()
     */
    init_phase={
        /*
         * start the heartbeat daemon
         */
        self.sendheartbeat;                    // send the first one for free
        notify( self, &sendheartbeat, 0 );    // the rest come from self
    }
    /*
     * send a heartbeat to every object (still in the game) that wants one
     */
    sendheartbeat={
        local i, o;
        i = 1;
        while (i <= self.hblen) {
            o = self.heartlist[i];
            if (o.wantheartbeat) o.heartbeat;
            i++;
        }
    }
;

#endif

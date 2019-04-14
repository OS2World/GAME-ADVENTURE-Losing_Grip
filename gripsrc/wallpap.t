/* ex:set ts=4 sw=4:
 *
 * wallpap.t: the stuff thats all around but you don't notice
 *
 * This module provides a slightly more complicated set of object classes
 * for objects which are more than decoration but at the same time less
 * than fixedItems.  We don't want them to show up in 'all' listings.
 *
 * It really only exists because the original support for floatingItems was
 * not (imho) sufficient to work with.
 *
 * This was originally implemented so that my port of Dungeon would allow
 * the player to mess with the bank walls without having to have hundreds
 * of wall objects.  It can probably be used for things like 'the floor'
 * and 'the sky' but I haven't tried yet.
 *
 * This was a fairly tricky module to get working within the TADS framework
 * because of the difficulty in determining which methods get called under
 * which circumstances.  *My* definitive answer is as follows
 *
 * 1.    If the player types "<verb> all" then <verb>.doDefault is called
 *        and all objects in that list are assumed to be ok - no check is
 *        made via <verb>.validDo
 *
 * 2.    If the player types "<verb> <object>" then <verb>.validDoList is
 *        called and the list is scanned for objects which match the
 *        vocabulary word <object>.  The object is then passed through the
 *        <verb>.validDo method.
 *
 * Adds:
 *    class wallpaper
 *        objects of this class are not ordinary objects but assumed to be
 *        wallpaper - i.e. they are in lots of rooms but are not significant
 *        enough (or too tedious) to include multiple objects.
 *
 *    room.floating_items
 *        this list of objects will automatically be included into the
 *        possible object lists where appropriate.  This allows for a
 *        specific object to occur in multiple rooms.  These objects should
 *        only be 'wallpaper'
 *
 *        note that we do *not* allow you to move these objects around
 *        because the code in thing.moveInto would screw things up real bad
 *        and you should *not* be moving the wallpaper around anyway.  If
 *        you don't want it to appear in a specific room, remove it from the
 *        floating_items list -- don't move it to nil
 *
 *    thing.floating_items
 *        default this to nil just in case someone manages to get into a
 *
 *    thing.visibleObjects(actor)
 *        this is a hook which replaces old calls to 'visibleList(obj)' and
 *        which allows individual objects/classes to replace it.  Thus, dark
 *        rooms can return nothing if they are not lit
 *
 *    thing.takeableObjects(actor)
 *        this is a hook which replaces old calls to 'takeableList(obj)' and
 *        which allows individual objects/classes to replace it.
 *
 *    thing.reachableObjects(flag)
 *
 * Replaces:
 *    deepverb.validDoList
 *    deepverb.doDefault
 *    deepverb.ioDefault
 *        These three methods are modified to use the visibleObjects method
 *        rather than call visibleList(room/actor) directly.
 *
 *    takeverb.doDefault
 *        This method is modified to use actor.location.visibleObjects rather
 *        than actor.location.contents (since the contents of a dark room
 *        can't be seen and thus shouldn't be taken by 'take all')
 *
 * This module is Copyright (c) 1994 Jeff Laing.  Permission to use any or all
 * of this code in other TADS games is granted provided credit is given in
 * your "CREDITS" command for this code and that you leave this copyright
 * message in the source whenever distributed.  Please make all changes in
 * a backward compatible manner (where possible) and make them available
 * for free (like I did ;-)
 *
 * There have been a few changes by Stephen Granade, labeled with SRG for
 * easy identification. For some reason wallpaper's preinit_phase calls
 * initSearch(). This is great if you know you'll be using wallpaper in all
 * of your games, but a pain otherwise. For the sake of this collection, I
 * have assumed otherwise.  Also, a missing close comment in the takeableList
 * function prevented the function from recognizing the notakeall flag in
 * objects.
 *
 * Changes:
 * 1.8  SRG initial release
 * 1.9  Missing close comment in takeableList() added (4 Mar 97)
 * 1.10 Modifications to visibleList() to allow the player to command objects
 *      in his/her inventory (22 Jul 97)
 */
#ifndef WALLPAPER
#define WALLPAPER

#pragma C-

#include "version.t"
#include "sysfuncs.t"

wallpaperVersion : versionTag, initialization
    id="$Id: wallpap.t,v 1.10 1997/07/23 01:38:53 sgranade Exp $\n"
    author='Jeff Laing'
    func='smarter floaters'

    /*
     * called by preinit()
     */
/*  preinit_phase={            // Commented out by SRG
        initSearch();
    }*/

    /*
     * called by init()
     */
    //init_phase={
    //}
;

/*
 * this function is used to produce the list of "all visible" objects
 * from within the specified "obj".
 */
replace visibleList: function(obj,actor)
{
    local ret := [];
    local i, lst, len;

    /* never look inside "nil" objects */
    if (obj=nil) return([]);

    /* if it has no contents, bail out */
    if (length(obj.contents)=0) return([]);

    if (
        not isclass(obj, openable)
        or (isclass(obj, openable) and obj.isopen)
        or obj.contentsVisible
    ) {
        lst := obj.contents;
        len := length(lst);
        ret += lst;
        for (i := 1 ; i <= len ; ++i) {

            // never recurse into the actor doing the verb
            if (lst[i]=actor) continue;

            ret += lst[i].visibleObjects(actor);
        }
        // SRG: Since the "Me" object never appears in a room's contents, if
        //      Me is located in obj and actor != Me, add Me.contents to the
        //      list
        if (actor <> Me and Me.location = obj)    // SRG
            ret += Me.visibleObjects(actor);      // SRG
    }

    return(ret);
}

/*
 *    This function is used to produce the list of "all takeable" objects
 *  from within the specified "obj".  It will not allow you to take "all"
 *    from an actor, nor can it reach inside non-open openables.  It will
 *    also not pick up fixed items or items that are tagged "notakeall".
 */
takeableList: function(obj,actor)
{
    local ret, i, lst, len;

    /* never "take all" from actors unless its ourself */
    if (obj.isactor and obj<>actor) return([]);

    /* can't "take all" from something thats not open */
    if (isclass(obj,openable) and not obj.isopen) return([]);

    /* recurse through all this objects fixed contents */
    lst := obj.contents;
    ret := [];
    len := length(lst);
    for (i := 1 ; i <= len ; ++i) {
    
        /* never recurse into actor performing verb */
        if (lst[i]=actor) continue;

        /* can't take fixed but things inside may be takeable */
        if (lst[i].isfixed) {
            ret += lst[i].takeableObjects(actor);
            continue;
        }

        /* special attribute prevents taking during "take all" */ // SRG
        if (lst[i].notakeall) continue;

        /* otherwise, add it to the list */
        ret += lst[i];
    }

    return(ret);
}

/*
 * we need to add our methods at the bottom of the hierachy so everyone
 * will inherit reasonable behaviour
 */
modify class thing
    floating_items = []        // we have nothing inside us by default

    // called by object validation mechanism.  'actor' is the actor who is
    // performing the verb building the list.
    visibleObjects(actor) = (visibleList(self,actor))

    // called by the takeVerb.doDefault method only.  flag is ignored for
    // now but may be changed later.
    takeableObjects(actor) = (takeableList(self,actor))
;

/*
 * objects which are tagged as wallpaper are like fixedItems in that you
 * can't budge them.  they are also assumed to be potentially globally
 * visible so they are floatingItems
 */
class wallpaper : fixeditem, floatingItem

    // this prevents contlist() from including us
    isListed = nil

    // our location defaults to nil
    location = nil

    // can it be reached by 'manipulative' verbs?
    isReachable(actor) = (find(actor.location.floating_items,self)<>nil)

    // called by inspectVerb.validDoList - floaters are probably visible
    isVisible(actor) = (find(actor.location.floating_items,self)<>nil)
;

/*
 * replace the default object mechanism so that it never returns wallpaper.
 * the user can still specify it explicitly if they like
 *
 * We needs to change two places because TADS seems to have two different
 * procedures for providing objects to verbs.
 *
 * 'verb object' - TADS calls verb.validDoList then validates using    verb.validDo
 * 'verb ALL' - TADS only calls deepverb.doDefault
 */
modify class deepverb

    // Build a list that contains all the objects that *might* be appropriate
    // to the current verb.  Our method asks the room & the actor and includes
    // the global floating-item list (which holds the wallpaper).  This
    // list will be passed through self.doValid() for confirmation.
    replace validDoList(actor, prep, iobj) = {
        local list, loc;

        loc := actor.location;
        while (loc.location) loc := loc.location;

        list :=    actor.visibleObjects(actor)    // what actor has
            +    loc.visibleObjects(actor)    // whats in this room
            +    global.floatingList;        // global stuff
        
        return(list);
    }

    // This looks the same as validDoList but is called at a different time
    // by the TADS parser.  It basically only gets called to change "all"
    // to a list of objects.  This must only return valid objects because
    // self.validDo() doesn't get called.
    replace doDefault( actor, prep, io ) = {
        local list;
           list :=    actor.visibleObjects(actor)                // what actor has
            +    actor.location.visibleObjects(actor);    // whats in this room
        return(list);
    }
    replace ioDefault( actor, prep ) = {
        local list;
           list :=    actor.visibleObjects(actor)                // what actor has
            +    actor.location.visibleObjects(actor);    // whats in this room
        return(list);
    }
;

// I may have changed the semantics of the "take all" verb here.  I need to
// document exactly what it does not but it seems to be better than it
// used to be.
modify takeVerb

    // take ALL
    replace doDefault( actor, prep, io ) =
    {
        local ret, rem, cur, rem2, cur2, tot, i, tot2, j;

        ret := [];

        /*
         *   For "take all out/off of <iobj>", return the (non-fixed)
         *   contents of the indirect object.  Same goes for "take all in
         *   <iobj>", "take all on <iobj>", and "take all from <iobj>".
         */
        if (io <> nil) {
            if (
                prep=outPrep or prep=offPrep or prep=inPrep or
                prep=onPrep or prep=fromPrep
            ) {
                ret := io.takeableObjects(actor);
                return( ret );
            }
        }

        /*
         * Build a list of all objects that we believe are takeable at the
         * actors location.
         */
        ret := actor.location.takeableObjects(actor);
        return( ret );
    }
;

/*
 * we can only drop things that we could "take from ourselves"
 */
modify dropVerb
    doDefault( actor, prep, io ) = (actor.takeableObjects(actor))
;

/*
 * we can only give things that we could drop
 */
modify giveVerb
    doDefault( actor, prep, io ) = (actor.takeableObjects(actor))
;

/*
 * we can put things that we are holding and things that we could take
 */
modify putVerb
    doDefault( actor, prep, io ) = (                // anything we can
            takeVerb.doDefault( actor, prep, io )    // take
            +                                        // or
            dropVerb.doDefault( actor, prep, io )    // drop
        )
;

#endif

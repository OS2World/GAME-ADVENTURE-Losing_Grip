/* ex:set ts=4 sw=4:
 *
 * look.t: An alternative way of "LOOKing at things"
 *
 * This module provides a slightly more sophisticated way of looking at
 * things in a TADS world.  The original TADS methods are still obeyed ( I
 * think! ) but additional methods have been provided to add better
 * descriptive capability.
 *
 *    thing.hdesc
 *        If thing.has_hdesc returns true, hdesc will be called whenever the room
 *        containing this object is viewed (i.e. 'look').  "hdesc" methods
 *        are called after all "fixed" objects are described.  Thus, decorations
 *        are still listed straight after the room description.  Objects
 *        without this method will be described in the list format.  i.e.
 *        "There is a dinosaur, a treadmill and a pound of butter here."
 *
 *    thing.listdesc
 *        This method is used to display the name of the object whenever it
 *        is presented in a list (except for disambiguation).  This allows a
 *        clean hook for the (being worn), (being wielded), etc messages.
 *
 *        It also allows object to describe themselves differently in the
 *        'inventory' command and the 'look' command.
 *        hint: if (object.location=Me) command='invent'; else command='look'
 *
 *    thing.showcontents
 *        The function showcontcont has been made into a method which makes a
 *        much cleaner interface - as new classes come along which can
 *        contain things, they can override this method rather than edit the
 *        showcontcont function.
 *
 *    thing.invdesc
 *        This method prints the list description in the "tall inventory" list.
 *
 *    thing.invcontents
 *        This method returns the list of objects which should be shown in a
 *        "tall inventory."
 *
 * Adds:
 *  thing.listdesc
 *  thing.showcontents
 *  thing.invcontents
 *  thing.invdesc
 *  surface.showcontents
 *  surface.invcontents
 *  surface.invdesc
 *  container.showcontents
 *  container.invcontents
 *  container.invdesc
 *  clothingItem.listdesc
 *  listlist: function(list)
 *  contlist: function(obj)
 *  listfixedcontents: function(obj)
 *  listsubcontents: function(obj)
 *
 * Replaces:
 *  room.nrmLkAround(verbosity)
 *  surface.ldesc
 *  container.ldesc
 *  openable.doOpen
 *  iVerb.action(actor)
 *
 * Obsoletes:
 *  itemcnt: function(obj)
 *  showcontcont: function(obj)
 *  listfixedcontcont:function(obj)
 *  listcontcont:function(obj)
 *
 * Affected verb structures:
 *  inventory
 *  look
 *  inspect <surface>
 *  inspect <container>
 *  open <container>
 *
 * This module is Copyright (c) 1993 Jeff Laing.  Permission to use any or all
 * of this code in other TADS games is granted provided credit is given in
 * your "CREDITS" command for this code and that you leave this copyright
 * message in the source whenever distributed.  Please make all changes in
 * an backward compatible manner (where possible) and make them available
 * for free (like I did ;-)
 *
 * Tall inventory, handling of indistinguishable objects (see TADS v2.2),
 * and clothingItem listdesc added by Stephen Granade.  In room.nrmLkAround,
 * hdesc now takes precedence over a fixed item's desc, and actors who have
 * isListed set to nil are not printed.  Also, bug fixed in which, if there
 * was nothing in the room except unlisted items, "You see a here." was
 * printed.  To select between tall and wide inventory, use the commands
 * "inventory tall" and "inventory wide".  All of my changes are
 * noted with my initials, SRG.
 *
 * Changes:
 * 1.9   SRG Initial release
 * 1.91  bug fix: fixed items with isListed = true were not being displayed.
 *       Fix due to D.J. Picton.
 * 1.92  nrmLkAround tweaked to make hdesc more important
 * 2.0   Major changes to handling of equivalent objects
 * 2.1   nrmLkAround changed so that actors w/isListed = nil are not shown.
 *       Also had to set isListed = true in movableActor and Actor (10 Oct 96)
 * 2.2   Modified the sentence printed by showcontents in surface (28 Jun 97)
 *
 */
#ifndef NEWLOOK
#define NEWLOOK

#pragma C-

#include "version.t"

lookVersion : versionTag
    id="$Id: look.t,v 2.2 1997/06/29 03:01:08 sgranade Exp $\n"
    author='Jeff Laing and Stephen Granade'
    func='look code'
;
/*
 * This function will display the list of objects passed to it in the
 * standard TADS inventory display.  it does *not* display a complete
 * sentence; instead, it expects that you wrap a sentence around it.
 *
 * obj1:      a obj1
 * obj1,2:    a obj1 and a obj2
 * obj1-3:    a obj1, a obj2 and a obj3
 */
listlist: function( list )
{
    local count, len, cur, prefix_count, disp_count;
    count := disp_count := 1;
    len := length(list);
    while (count<=len) {
        cur := list[count];
        prefix_count := 1;
        // SRG: Handle equivalent items
        if (cur.isEquivalent) {
            local j, o;

            for (prefix_count := 0, j := 1; j <= len; j++) {
                o := list[j];
                if (isIndistinguishable(cur, o)) {
                    if (j < count) {      // This should never be
                        "\n\([BUG IN LOOK.T: listlist. PLEASE REPORT IT TO THE
                            NEAREST IMPLEMENTOR.]\)\n";
                        return;
                    }
                    else {
                        prefix_count++;
                        if (j != count) { // (Don't remove the current item)
                            list -= o;    // Remove the other equivalent
                            len--;        //  items & fix the list len
                            j--;          //  and index variable j
                        }
                    }
                }
            }
        }
        // SRG: End equivalent item handling
        // various numbers of objects will generate different messages
        // 1    a dinosaur
        // 2    a dinosaur and an armchair
        // >2    a dinosaur, an armchair, and a pound of butter
        //
        if ( disp_count > 1 ) {             // this is object 2+
            // for those who don't like the comma before the "and", change
            // the following to (len > 2 and len < count)
            if (len > 2)                // >2 in the list
                ", ";
            if ( count = len )          // in fact, its the last
                " and ";
        }
        count++; disp_count++;
        if (prefix_count = 1)
            cur.listdesc;               // list this object
        else {
            "<<sayPrefixCount(prefix_count)>> <<cur.pluraldesc>>";  //SRG
        }
    }
}

/*
** talllist displays a list in tall format, for Infocom-style inventories.
**  indent gives how many spaces the list should be indented. Added by SRG.
*/
talllist: function(list, indent)
{
    local i, len, cur, cont, indstr, prefix_count;

    indstr := '';
    for (i := 0; i < indent; i++)
        indstr += '\ ';
    len := length(list);
    for (i := 1; i <= len; i++) {
        cur := list[i];
        prefix_count := 1;
        // Handle equivalent items
        if (cur.isEquivalent) {
            local before, after, j;

            for (before := after := 0, j := 1; j <= len; j++) {
                if (isIndistinguishable(cur, list[j])) {
                    if (j < i) {
                        before++;
                        break;
                    }
                    else after++;
                }
            }
            if (before = 0)    // Only list the FIRST indistinguishable item
                prefix_count := after;
            else continue;
        }
        say(indstr);
        if (prefix_count = 1)
            cur.invdesc;
        else {
            "<<sayPrefixCount(prefix_count)>> <<cur.pluraldesc>>";
        }
        "\n";
        cont := cur.invcontents;        // Do we need to list anything else?
        if (length(cont) <> 0 and cur.contentsVisible) {
            "<<indstr>><<cur.thedesc>> contains:\n";
            talllist(cont, indent + 2); // Indent contents by 2
        }
    }
}

/*
 * This function constructs a list which contains the objects within the
 * specified objects that would be displayed if we were to 'list the contents'
 * of it.  Its used for 'inventory' and 'look at room'
 *
 * This list is suitable for passing to listlist()
 */
contlist: function( obj )
{
    local count,disp,list,cur,len;
    disp := [];
    list := obj.contents;
    len := length(list);
    count := 1;
    while (count <= len) {
        cur := list[count++];
        if (cur.isListed) {
            disp += cur;
        }
    }
    return disp;
}
/*
 * make sure each thing defaults its list description
 */
modify class thing
    // thing.listdesc is used when the object is being mentioned in a list
    // of things (typically the inventory list or examining the contents
    // of a container)
    listdesc = { self.adesc; }

    // thing.invdesc is used when the object is being mentioned in a tall
    // inventory list. Added by SRG.
    invdesc = { self.listdesc; }

    // thing.showcontents is used when we wish to show the contents of an
    // object.  most objects don't have one.
    showcontents = {}

    // thing.invcontents returns a list of contents that should be shown.
    // usually linked with contents. Added by SRG.
    invcontents = { return contlist(self); }

    // method to determine whether we have a hdesc or not
    has_hdesc = {
        local flag;
        flag := proptype(self,&hdesc);
        return (flag<>0 and flag<>5);
    }
    // "LOOK THROUGH <self>"
    doLookthru(a) = "The world seems hazier but no more interesting!"
    // "LOOK AT <self> THROUGH <i>"
    verDoInspectThru(a,i) =    (self.verDoInspect(a))
    doInspectThru(a,i) = {
        self.doInspect(a);
        "\b(Using <<i.thedesc>> didn't make a difference)\n";
    }
    // "LOOK AT <o> THROUGH <self>"
    verIoInspectThru(a) =    (self.verDoLookthru(a))
    ioInspectThru(a,o) =    (o.doInspectThru(a,self))
    // "LOOK THROUGH <self> AT <i>"
    verDoLookthruAt(a,i) =    (self.verIoInspectThru(a))
    doLookthruAt(a,i) =        (i.ioInspectThru(a,self))
    // "LOOK THROUGH <o> AT <self>"
    verIoLookthruAt(a) =    (self.verDoInspect(a))
    ioLookthruAt(a,o) =        (self.doInspectThru(a,o))
;
/*
 * modify list descriptions to include (providing light) if appropriate
 */
modify class lightsource
    // listdesc is used when mentioned in lists. if we are lit, we display
    // the extra bit here.
    listdesc = {
        inherited.listdesc;
        if (self.islit) " (providing light)";
    }
;
/*
 * update inventory to use the new constructs
 */
modify iVerb
    // inventory
    tallFlag = nil                // SRG: For Infocom-style (tall) lists
    replace action( actor ) = {
        local list;
        list := contlist(actor);
        if (length(list)>0) {
            "%You% %have%";
            if (self.tallFlag) {
                ":\n<<talllist(list, 2)>>";
            }
            else {
                " <<listlist(list)>>. ";
                listsubcontents(actor);
            }
        }
        else
            "%You% %are% empty-handed.\n";
    }
;

// SRG: The next several verbs and "preposition" are for the new inventory
//      styles.
itallVerb: deepverb
    verb = 'i tall' 'inv tall' 'inventory tall'
    sdesc = "inventory tall"
    action(actor) = {
        iVerb.tallFlag := true;
        iVerb.action(actor);
    }
;

iwideVerb: deepverb
    verb = 'i wide' 'inv wide' 'inventory wide'
    sdesc = "inventory wide"
    action(actor) = {
        iVerb.tallFlag := nil;
        iVerb.action(actor);
    }
;

// Time for a nasty kludge or two for "inv tall" & "inv wide"
tallnwidePrep: Prep
    preposition = 'tall' 'wide'
    sdesc = "tallnwide"
;
/*
 * replace the nrmLkAround method to use the 'hdesc' methods if available
 */
modify class room
    /*
     *   lookAround describes the room.  If verbosity is true, the full
     *   description is given, otherwise an abbreviated description (without
     *   the room's ldesc) is displayed.
     */
    replace nrmLkAround( verbosity ) =
    {
        local l, cur, i, tot;
        local fixed_list,hdesc_list,other_list,actor_list;
        // we always build the lists of objects - its easier that way
        fixed_list := [];
        hdesc_list := [];
        actor_list := [];
        other_list := [];
        l := self.contents;
        while ( length(l) > 0 ) {
            cur := car(l); l := cdr(l);
            // never describe the player
            if ( cur = Me ) continue;
            // other actors
            if ( cur.isactor ) {
                actor_list := actor_list + cur;
                continue;
            }
            // items with 'hdesc' properties
            if (cur.has_hdesc) {    // SRG: moved before fixed items
                hdesc_list := hdesc_list + cur;
                continue;
            }
            // fixed items
            if ( cur.isfixed ) {
                fixed_list := fixed_list + cur;
                continue;
            }
            // everything else
            if (cur.isListed)        // Bug fix by SRG
                other_list := other_list + cur;
        }
        // If we are being 'verbose', we display the room description and
        // any fixed items that are here.
        if ( verbosity ) {
            "\n\t<<self.ldesc>>";
        }
        while (length(fixed_list) > 0) {
            cur:=car(fixed_list); fixed_list:=cdr(fixed_list);
        /* If isListed = true, place the object in other_list */
            if (cur.isListed)
                other_list += cur;
            else if (verbosity) cur.heredesc;
        }
        // now describe any objects who believe they have an important
        // description (hdesc)
        while (length(hdesc_list) > 0) {
            cur:=car(hdesc_list); hdesc_list:=cdr(hdesc_list);
            "\n\t<<cur.hdesc>>";
        }
        "\n\t";
        // now describe all the other tacky junk in list form
        if (length(other_list)>0) {
            "You see <<listlist(other_list)>> here. ";
        }
        // describe the contents of anything here
        listsubcontents( self ); "\n";
        // now let the actors describe themselves.
        while (length(actor_list)>0) {
            cur := car(actor_list); actor_list := cdr(actor_list);
            if (cur.isListed)
                "\n\t<<cur.actorDesc>>";
        }
    }
;
/*
 * List the contents of any fixedItem objects in the contents list of the
 * object passed.
 *
 * This routine behaves similiarly to listfixedcontcont
 */
listfixedcontents: function( obj )
{
    local list, i, tot, thisobj;
    list := obj.contents;
    tot := length( list );
    i := 1;
    while ( i <= tot )
    {
        thisobj := list[i];
        if (thisobj.isfixed) thisobj.showcontents;
        i++;
    }
}
/*
 * This function lists the contents of all objects within the specified
 * objects.
 *
 * It behaves in a similiar fashion to listcontcont()
 */
listsubcontents: function( obj )
{
    local list, i, tot;
    list := obj.contents;
    tot := length( list );
    i := 1;
    while ( i <= tot )
    {
        list[i++].showcontents;
    }
}
/*
 * movableActor: isListed should be true
 */
modify class movableActor
    isListed = true
;
/*
 * Actor: isListed should be true
 */
modify class Actor
    isListed = true
;
/*
 * surface: describing the surface should use the new constructs
 */
modify class surface
    // examine <surface>
    replace ldesc = {
        local list;
        list := contlist(self);
        if (length(list)>0) {    // SRG: changed sdesc to use it/them
            "On <<self.isThem ? "them" : "it">> %you%
                see%s% <<listlist(list)>>. ";
        }
/* SRG: I don't like this additional sentence, so I commented it out.
        else {
            "There's nothing on <<self.thedesc>>. ";
        }*/
    }
    // look (at room containing surface)
    showcontents = {
        local list;
        if (self.isqsurface) return;
        list := contlist(self);
        if (length(list)>0) {    // SRG: changed use of sdesc to thedesc
            // In this next sentence, changed "is" to "you see"
            "Sitting on <<self.thedesc>> %you% see%s% <<listlist(list)>>. ";
        }
        listfixedcontents( self );
    }

    invcontents = {              // SRG: added for tall/wide inventory
        if (self.isqsurface) return [];
        return (contlist(self));
    }
;
/*
 * container: describing the container should use the new constructs
 */
modify class container
    // examine <container>
    replace ldesc = {
        local list;
        list := contlist(self);
        if (self.contentsVisible and length(list)>0) { // SRG: thedesc->it/them
            "In <<self.isThem ? "them" : "it">> %you%
                see%s% <<listlist(list)>>. ";
        }
        else {
            // "There's nothing in "; self.thedesc; ". ";
            "\^<<self.thedesc>> is empty. ";
        }
    }
    // look (at room containing container)
    showcontents = {
        if (self.isqcontainer) return;
        if (self.contentsVisible) {
            local list;
            list := contlist(self);
            if (length(list)>0) {
                "\^<<self.thedesc>> seems to contain <<listlist(list)>>. ";
            }
            listfixedcontents( self );
        }
    }

    invcontents = {              // SRG: added for tall/wide inventory
        if (self.isqcontainer or not self.contentsVisible) return [];
        return contlist(self);
    }
;
/*
 * openable: as self is opened, revealing the contents should use the new
 * constructs.  also, we capture the 'examine <openable>' here and display
 * the contents of the <openable> in the 'The <openable> is open ...'
 * sentence rather than delivering two sentences about the same noun in a
 * row
 */
modify class openable
    // examine <openable>
    replace ldesc = {
        caps(); self.thedesc;
        if ( self.isopen ) {
            local list;
            list := contlist(self);
            " is open";
            if (length(list)>0) {
                " and seems to contain <<listlist(list)>>";
            }
            ".";
        }
        else " is closed. ";
    }
    // open <openable>
    replace doOpen( actor ) = {
        local list;
        list := contlist(self);
        if (length(list)>0) {
            "Opening <<self.thedesc>> reveals <<listlist(list)>>. ";
        }
        else "Opened. ";
        self.isopen := true;
    }

    replace invdesc = {
        inherited.invdesc;
        if (self.isopen)
            " (which is open)";
    }
;
/*
** Modify clothingItem to say (being worn) if worn
*/
modify clothingItem
    replace listdesc = {
        inherited.listdesc;
        if (self.isworn)
            " (being worn)";
    }
;
/*
 * adjust new method calls (introduced at TADS 2.1) to work with my
 * constructs.
 */
modify class transparentItem
    ldesc = {
        local list;
        list := contlist(self);
        if (self.contentsVisible and length(list) <> 0) {
            "In <<self.thedesc>> %you% see%s% <<listlist(list)>>. ";
        } else {
            "There's nothing in <<self.thedesc>>. ";
        }
    }
;
/*
 * "LOOK INTO <object>"
 */
modify lookVerb
    verb='look into'                // add another synonym
;
/*
 * "LOOK THROUGH <object> AT <object>"
 */
modify lookThruVerb
    verb = 'look out'                      // SRG: Added for e.g. "look out window"
    prepDefault = atPrep
    ioAction(atPrep) = 'LookthruAt'        // LOOK THRU <o> AT <i>
;
/*
 * "LOOK AT <object> THROUGH <object>"
 */
modify inspectVerb
    ioAction(thruPrep) = 'InspectThru'    // LOOK AT <o> THRU <i>
    ioAction(withPrep) = 'InspectThru'    // LOOK AT <o> WITH <i>
;

#endif

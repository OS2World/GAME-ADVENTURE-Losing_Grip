#ifndef CLOTHING
#define CLOTHING

/* ex:set ts=4 sw=4:
 * 
 * This source code is (C)1994 Jonathan D. Feinberg.  See below for
 * permission to distribute.
 * 
 * clothing.t:    smarter clothingItem
 * 
 * This file modifies the standard adv.t file to provide a slightly
 * more realistic feel for the clothingItem class.  To enjoy the benefits
 * of this modified class requires very little work on your part beyond
 * what you already need to do to implement clothingItem objects; indeed,
 * existing code that uses vanilla clothingItem objects will work the same
 * as ever, without "fixes."
 * 
 * clothing.t provides three new features:
 * 
 *     1) Custom messages for donning and doffing clothes, warning the
 *        user that clothes are already worn, and describing the state
 *        of the clothing in the inventory command.  If you do not provide
 *        custom messages, the default messages are supplied for you.
 *        
 *     2) Clothing "families," within which only one item at a time may be
 *        worn.  My sample code gives two theater masks.  In the real world,
 *        you aren't going to wear more than one mask at a time.  Other
 *        possible uses include uniforms, hats, etc.  If you do not specify
 *        a family number, the clothing will have default behavior.
 *     
 *     3) The "autoTakeOff" property which enables you to control whether,
 *        when the player either drops a clothingItem which isworn, or puts
 *        on a clothingItem in a family that has an isworn member already,
 *        the isworn item is automatically removed as a convenience to the
 *        user.  I advocate leaving it true. I provide it to make it easy to
 *        force the player to take off certain pieces of equipment manually,
 *        like, say, scuba gear.
 *     
 *     CUSTOM MESSAGES
 *     Please see the property definitions below for the expected formats
 *     of these messages.  The default values of these properties are copied
 *     from adv.t.
 *     
 *     beingWornDesc    Evaluated in inventory lists after the item's adesc
 *                      when its isworn property is true. (See listcont, below)
 *     putOnDesc        Evaluated when the player puts the item on.
 *     takeOffDesc      Evaluated when the player takes the item off.
 *     mustTakeOffDesc  Evaluated when the player must first remove the item
 *                      to perform some action (only shown if autoTakeOff is
 *                      nil. 
 *     alreadyOnDesc    Evaluated when the player tries to wear something
 *                      he/she is already wearing.
 *     notOnDesc        Evaluated when the player tries to unwear something
 *                      he/she is not wearing.
 *     autoTakeOffDesc  Evaluated when the self.checkDrop method takes off a
 *                      worn piece of clothing.
 * 
 *     FAMILIES
 *     Simply give the family property of your clothing item a non-zero
 *     integer that it will share with other members of its family, but
 *     not with other families.  An obvious way to do so is to subclass
 *     clothingItem, give the child class a family number, and create
 *     objects of that subclass that will automatically belong to that family.
 *     
 *     
 *     ADDS:
 *     clothingItem.clothing_family        clothingItem.putOnDesc
 *     clothingItem.autoTakeOff            clothingItem.takeOffDesc
 *     clothingItem.otherMemberWorn        clothingItem.mustTakeOffDesc
 *     clothingItem.beingWornDesc          clothingItem.notOnDesc
 *     clothingItem.autoTakeOffDesc        clothingItem.listdesc
 *     
 *     REPLACES:
 *     clothingItem.checkDrop              clothingItem.verDoUnwear
 *     clothingItem.verDoWear              clothingItem.doUnwear
 *     clothingItem.doWear
 *     
 *     I encourage you to use this code in your own TADS games.  I would
 *     appreciate a note from you if you use this code, or even if you see
 *     it and have comments or suggestions.  Please include my name in the
 *     credits for your game.  Please include this file in its entirety in
 *     any distribution of your source code.  Please clearly mark any
 *     alterations you have made to my code.
 *     
 *     By the way, I got the idea for this modification from my brief
 *     experience at LambdaMOO before it mysteriously vanished.  I like
 *     that you can create obects that appear to have required a lot of
 *     programming by just changing a few messages around.  Anybody know
 *     where LambdaMOO is?
 *
 *     jdf@panix.com
 *     
 *     2/23/94 - Given to Neil K. Guy for testing.  Thanks, Neil!
 *     2/28/94 - First public release.
 *     3/8/94  - Jeff Laing changed the following things....
 *     1. integrated code with "look.t" (available on ftp.gmd.de)
 *     2. remove two bugs(?) from "same-family" code.  first, it didn't pass the
 *        class parameter to nextobj thus making it slower than it needed to be.
 *        Second, it should only look through the inventory of the actor who is
 *        making the request.  Just imagine...
 *        > PUT ON BLUE WETSUIT
 *        Bob will have to take off the red wetsuit first.
 *     3. Added a versionTag - this works with "version.t" (available soon on
 *        ftp.gmd.de)
 *     4. Various cosmetic things to source layout.  I am just as pedantic
 *        about style as the next guy ;-)
 *     8/25/96 - Stephen Granade changed the following things:
 *     1. added #ifdef checking -- don't want to include it twice!
 *     2. made it follow C conventions (I did not mark these changes)
 *     3. had descriptions use the imbedded <<>> constructs.
 *        (say, aren't all these changes cosmetic?)
 *     12/16/97 - More changes by Stephen Granade
 *     1. You now must be holding a clothing item before you can wear it
 *
 *    As requested by Jonathan, changes are marked by *JL* or *SG*
 */

#pragma C+                                                             /*SG*/
#include "version.t"                                                   /*SG*/

clothingVersion: versionTag                                            /*JL*/
    id="$Id: clothing.t,v 1.6 1997/12/17 03:25:00 sgranade Exp $\n"                               /*SG*/
    author='Jonathan D.\ Feinberg'                                     /*JL*/
    func='clothing support'                                            /*JL*/
;                                                                      /*JL*/
modify clothingItem
    /*
     *    clothing_family property                                      *JL*
     *
     *    An integer that defines which clothing family this item is in.
     *    Items with clothing_family == 0 have the usual behavior (can be worn
     *    at the same time as each other).
     */
    clothing_family = 0                                                /*JL*/
    /*
     *    otherMemberWorn method
     *
     *    Determines whether any other member of this item's family isworn.
     *    Returns either nil (nothing else being worn) or the object being
     *    worn.
     */
    otherMemberWorn(a) = {                                             /*JL*/
        local o, obj, list;                                            /*JL*/
        if (self.clothing_family == 0) // wear as many 0 as you like   /*JL*/
            return( nil );
        list = a.contents;                                             /*JL*/
        for (o = 1; o <= length(list); o++) {                          /*JL*/
            obj = list[o];                                             /*JL*/
            if (!isclass(obj, clothingItem)) continue;
            if (obj.clothing_family != self.clothing_family) continue;
            if (obj == self) continue;
            if (obj.isworn)    
                return( obj );
        }
        return( nil );
    }
    /*
     *    descriptions
     *
     *    Evaluated when the player takes certain actions.  See above.
     */
    beingWornDesc = " (being worn)"                                     /*JL*/
    putOnDesc = { "Okay, %you're% now wearing <<self.thedesc>>. "; }    /*SG*/
    takeOffDesc = { "Okay, %you're% no longer wearing <<self.thedesc>>. "; }
    mustTakeOffDesc = { "%You% will have to remove <<self.thedesc>> first. "; }
    alreadyOnDesc = { "%You're% already wearing <<self.thedesc>>. "; }
    notOnDesc = { "%You're% not wearing <<self.thedesc>>. "; }
    autoTakeOffDesc = { "(Taking off <<self.thedesc>> first)\n"; }
    autoTakeOff = true

    replace checkDrop = {
        if ( self.isworn ) {
            if (autoTakeOff) {
                self.autoTakeOffDesc;
                self.isworn = nil;
            } else {
                self.mustTakeOffDesc;
                exit;
            }
        }
    }

    replace verDoWear( actor ) = {
        if ( self.isworn ) {
            self.alreadyOnDesc;
        } else if (self.location <> Me) {  // Changed from "not
                                           //  actor.isCarrying(self)" --SG
            "%You% %are%n't carrying <<self.thedesc>>. ";               /*SG*/
        }
    }

    replace doWear( actor ) = {
        local wornObject = self.otherMemberWorn(actor);                 /*JL*/

        if (wornObject != nil)
            wornObject.checkDrop;
        self.isworn = true;                                 /*switched by SG*/
        self.putOnDesc;                                     /*switched by SG*/
    }

    replace verDoUnwear( actor ) = {
        if ( !self.isworn ) {
            self.notOnDesc;
        }
    }

    replace doUnwear( actor ) = {
        self.isworn = nil;                                  /*switched by SG*/
        self.takeOffDesc;                                   /*switched by SG*/
    }
    // listdesc is used when mentioned in lists. if we are worn, we     /*JL*/
    // display the extra bit here.                                      /*JL*/
    listdesc = {                                                        /*JL*/
        inherited.listdesc;                                             /*JL*/
        if (self.isworn) self.beingWornDesc;                            /*JL*/
    }                                                                   /*JL*/
;

#endif

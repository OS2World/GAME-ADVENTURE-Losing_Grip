#ifndef SENSES
#define SENSES
#pragma C+

/*
** Senses.t --  Adds sound and smell descriptions to items.  Most everything
**              in here is thanks to Neil deMause.  Anything which isn't is
**              marked by my (Stephen Granade's) initials.
**
** Version history:
**   5 Apr 96 -- Initial release
**  24 Aug 96 -- Added a modification to room and Actor, as well as sense
**               information to verbs.  Also, the default touchdesc and
**               smelldesc now take isThem into account.
**   1 Mar 97 -- v1.2  Added touchdesc to distantItem
**  20 Jun 97 -- v1.3  Modified chairitem's roomAction to handle "listen" &c.
**               Tweaked smellVerb/listentoVerb's validDo. Also modified
**               decoration so that it's easier to add a listendesc/touchdesc.
*/

#include "version.t"

sensesVersion : versionTag
    id="$Id: senses.t,v 1.3 1997/06/21 01:40:34 sgranade Exp $\n"
    author = 'Neil deMause'
    func = 'smell and listen handling'
;

// The new verbs
smellVerb:deepverb
    verb='smell'
    sdesc="smell"
    action(actor)={Me.location.smelldesc;} // can have a global room smell
    doAction='Smell'
    validDo(actor, obj, seqno) = {      // SRG: I assume we can smell it if
        return (obj.isVisible(actor));  //  we can see it
    }
;

listenVerb:deepverb
    verb='listen'
    sdesc="listen"
    action(actor)={Me.location.listendesc;}    //add a listendesc
;                               //for any location
                                //where "listen" 
                                //should get a 
                                //specific response


listentoVerb:deepverb
    verb='listen to'
    sdesc="listen to"
    doAction='ListenTo'
    validDo(actor, obj, seqno) = {      // SRG: I assume we can smell it if
        return (obj.isVisible(actor));  //  we can see it
    }
;


// Modification to touchVerb to add "feel" to it.  SRG
modify touchVerb
    verb = 'feel'
;


// New additions to "thing" to handle the new senses
modify thing
    verDoSmell(actor)={}
    doSmell(actor)={self.smelldesc;}
    smelldesc="\^<<self.thedesc>> <<self.isThem ? "do" : "does">>n't smell like
        anything in particular."
    verDoTouch(actor)={}
    doTouch(actor)={self.touchdesc;}
    touchdesc="<<!self.isThem ? "It feels" : "They feel" >> just like <<
        self.adesc>>."
    listendesc="You don't hear anything unusual."
    verDoListenTo(actor)={}
    doListenTo(actor)={self.listendesc;}
;

// SRG: Modification to decoration
modify decoration
    verDoSmell(actor) = {}
    doSmell(actor) = {self.smelldesc;}
    verDoTouch(actor) = {}
    doTouch(actor) = {self.touchdesc;}
    verDoListenTo(actor) = {}
    doListenTo(actor) = {self.listendesc;}
    smelldesc = "Don't worry about <<self.thedesc>>. "
    touchdesc = "Don't worry about <<self.thedesc>>. "
    listendesc = "Don't worry about <<self.thedesc>>. "
;

// SRG: Modification to distantItem touchdesc
modify distantItem
    touchdesc = "\^<<self.thedesc>> <<self.isThem ? "are" : "is">> too far
        away. "
;

// SRG: Modification to room so that "smell" doesn't print the room's thedesc.
modify room
    smelldesc = "%You% %do%n't smell anything unusual."
;

// SRG: Modification to chairitem so that you can smell & listen to things
//  from chairs, beds, &c.
modify chairitem
    roomAction(actor, v, dobj, prep, io) = {
        if ( dobj != nil && (v != inspectVerb && v != smellVerb &&
            v != listentoVerb))
            checkReach(self, actor, v, dobj);
        if (io != nil && v != askVerb && v != tellVerb )
            checkReach(self, actor, v, io);
    }
;

// SRG: Modification to Actor's touchdesc
modify Actor
    touchdesc = "I don't think <<self.thedesc>> would appreciate that. "
;


// Intangible, for smells and sounds and whatnot.  It can't be felt, looked
//  at, &c.
class intangible : fixeditem
    takedesc = "That can't be taken."
    verDoMove(actor)={"That can't be moved.";}
    verDoTouch(actor)={"That can't be touched.";}
    ldesc="That's not visible."
    verDoLookbehind(actor)="That's not visible."
    verDoAttack(actor)={"That can't be attacked.";}
    verDoAttackWith(actor)={"That can't be attacked.";}
    verIoPutOn(actor)={"You can't put anything on that.";}
;


// SRG: I have marked every verb which obviously requires the use of sight
//      with "sight=true".  This is useful if you want a room with a light
//      so bright that you cannot "look", "look at", &c.
modify inspectVerb
    sight=true;
modify lookBehindVerb
    sight=true;
modify lookInVerb
    sight=true;
modify lookThruVerb
    sight=true;
modify lookUnderVerb
    sight=true;
modify lookVerb
    sight=true;
modify readVerb
    sight=true;

#endif

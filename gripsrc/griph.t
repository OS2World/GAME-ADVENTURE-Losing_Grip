/*
    Griph.t defines all the new verbs and classes for _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: griph.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

/*
   Modifications to thing, movableActor, and basicMe to handle the new verbs
*/
modify thing
    exits = "There are no obvious exits. "
    // Modify isVisible to handle the cube room in reason.t
    isVisible(vantage) = {
        if (self.location && vantage && self.location.isManyRm &&
            vantage.isManyRm)
            return true;
        pass isVisible;
    }
    // My version of cantReach
    replace cantReach(actor) = {
        // This is a _nasty_ workaround for if there's an object which matches
        //  the player's dobj, but it isn't in the same stage--you get this
        //  cantReach message.
        if (askVerb.myActor != nil) {
            askVerb.myActor.disavow;
            return;
        }
        if (!actor.isactor) {
            "\^<<actor.thedesc>> <<actor.isThem ? "do" : "does">> not
                respond. ";
            return;
        }
        // Another nasty workaround for if both the player and this object are
        //  in the many-sided room. I'm going to assume that the player can't
        //  reach the object b/c (s)he's on a different wall.
        if (uberloc(self).isManyRm && Me.location.isManyRm) {
            "%You% can't reach that from where you stand. ";
            return;
        }
        if (self.location == nil) {
            "%You% can't reach that from <<actor.location.thedesc>>. ";
            return;
        }
        if (!self.location.isopenable || self.location.isopen)
            self.location.cantReach(actor);
        else "%You%'ll have to open <<self.location.thedesc>> first. ";
    }
    verDoPutIn(actor, io) = {
        local loc;
        
        loc = self;
        while (loc != nil && loc != Me)
            loc = loc.location;
        if (loc == nil)
            "You cannot put <<self.thedesc>> anywhere without holding <<
                self.isThem ? "them" : "it">>. ";
        else pass verDoPutIn;
    }
    verDoPutOn(actor, io) = {
        local loc;
        
        loc = self;
        while (loc != nil && loc != Me)
            loc = loc.location;
        if (loc == nil)
            "You cannot put <<self.thedesc>> on anything without holding <<
                self.isThem ? "them" : "it">>. ";
        else pass verDoPutOn;
    }
    verDoKick(actor) = { "That would accomplish nothing. "; }
    verDoKiss(actor) = { "Bleah. "; }
    verDoTear(actor) = { "\^<<self.thedesc>> can't be torn. "; }
    verDoRaise(actor) = { "%You% cannot raise <<self.thedesc>>. "; }
    verDoLower(actor) = { "%You% cannot lower <<self.thedesc>>. "; }
    verDoDig(actor) = {}
    doDig(actor) = { askio(withPrep); }
    doSynonym('Turn') = 'TurnCW' 'TurnCCW'
    verDoTieTo(actor, io) = {
        "%You% can't tie <<self.thedesc>> to anything. ";
    }
    verIoTieTo(actor) = {
        "%You% can't tie anything to <<self.thedesc>>. ";
    }
    ioTieTo(actor, dobj) = { dobj.doTieTo(actor, self); }
    verDoUntie(actor) = {
        if (rope.tiedTo != self)
            "\^<<self.thedesc>> <<self.isThem ? "aren't" : "isn't">> tied to
                anything.  ";
    }
    doUntie(actor) = { rope.doUntie(actor); }
    verDoName(actor) = {
        "\^<<self.thedesc>> already has a perfectly good name. ";
    }
    doSynonym('Touch') = 'Pet'
    verDoStandBehind(actor) = {
        "There is no need to stand behind <<self.thedesc>>. ";
    }
    verDoHideBehind(actor) = {
        "There is no need to hide behind <<self.thedesc>>. ";
    }
    verDoUnhideBehind(actor) = {
        "But %you're% not behind <<self.thedesc>>. ";
    }
    verDoSqueeze(actor) = { "Nothing happens. "; }
    verDoInjectWith(actor, io) = {}
    verIoInjectWith(actor) = {
        "%You% can't use <<self.thedesc>> as a needle! ";
    }
    verDoInjectIn(actor, io) = {
        "%You% can't use <<self.thedesc>> as a needle! ";
    }
    verIoInjectIn(actor) = {}
    ioInjectIn(actor, dobj) = { dobj.doInjectIn(actor, self); }
    verDoPutUnder(actor, dobj) = {}
    verIoPutUnder(actor) = {
        "There's no need to put anything under <<self.thedesc>>. ";
    }
    verDoTakeWith(actor, io) = {}
    verIoTakeWith(actor) = {
        "%You% can't use <<self.thedesc>> to take anything. ";
    }
    verDoPourOn(actor, io) = {
        if (io != nil)
            "There's no need to pour <<self.thedesc>> on <<io.thedesc>>. ";
        else "There's no need to pour <<self.thedesc>> on anything. ";
    }
    verIoPourOn(actor) = {}
    ioPourOn(actor, dobj) = { dobj.doPourOn(actor, self); }
    verDoBegin(actor) = { "How do you propose to begin <<self.thedesc>>? "; }
    verDoPerform(actor) = { "You cannot perform <<self.thedesc>>. "; }
    verDoStop(actor) = { "You cannot stop <<self.thedesc>>. "; }
    verDoClimbup(actor) = { self.verDoClimb(actor); }
    doClimbup(actor) = { self.doClimb(actor); }
    verDoClimbdown(actor) = { self.verDoClimb(actor); }
    doClimbdown(actor) = { self.doClimb(actor); }
    verDoAttack(actor) = { "That would accomplish nothing. "; }
    verDoThrow(actor) = { "There is no need to throw <<self.thedesc>>. "; }
    verDoCutWith(actor, io) = {
        "There's no need to cut <<self.thedesc>>. ";
    }
    verDoCutIn(actor, io) = {
        "How do you propose to cut <<self.thedesc>> into <<io.thedesc>>? ";
    }
    verIoCutIn(actor) = { "There's no need to cut <<self.thedesc>>. "; }
    verDoDipIn(actor, io) = {
        if (io != nil)
            "There's no need to dip <<self.thedesc>> in <<io.thedesc>>. ";
        "There's no need to dip <<self.thedesc>> in anything. ";
    }
    verIoDipIn(actor) = {
        "There's no need to dip anything in <<self.thedesc>>. ";
    }
    verIoCutWith(actor) = {
        "\^<<self.thedesc>> makes a poor knife. ";
    }
    verDoKnockon(actor) = {
        "There's no need to knock on <<self.thedesc>>. ";
    }
    verDoRub(actor) = {
        "There's no need to rub <<self.thedesc>>. ";
    }
    verDoMoveU(actor) = { self.genMoveDir; }
    verDoMoveD(actor) = { self.genMoveDir; }
    verDoFill(actor) = { "There is no need to fill <<self.thedesc>>. "; }
    verDoFillWith(actor, io) = { "There is no need to fill <<self.thedesc>>. "; }
    verIoFillWith(actor) = {}
    ioFillWith(actor, dobj) = { dobj.doFillWith(actor, self); }
    verDoEmpty(actor) = { "There is no need to empty <<self.thedesc>>. "; }
    verDoMake(actor) = { "There is no need to make <<self.thedesc>>. "; }
    verDoUnmake(actor) = { "There is no need to unmake <<self.thedesc>>. "; }
    verDoClench(actor) = { "You cannot clench <<self.thedesc>>. "; }
    verDoRelax(actor) = { "You cannot relax <<self.thedesc>>. "; }
    verDoClean(actor) = { "There is no need to clean <<self.thedesc>>. "; }
    verDoGloat(actor) = { "You laugh nastily at <<self.thedesc>>. "; }
    verDoStare(actor) = { stareVerb.action(actor); }
    verDoStaredown(actor) = { staredownVerb.action(actor); }
    verDoStareup(actor) = { stareupVerb.action(actor); }
    verDoThank(actor) = { "There is no need. "; }
;

modify movableActor
    verDoPet(actor) = { "\^<<self.thedesc>> might not take kindly to that. ";}
    verDoSqueeze(actor) = { self.verDoPet(actor); }
    verDoAttack(actor) = { "That would be impolite at best. "; }
    verDoKnockon(actor) = { "That would be impolite at best. "; }
    verDoRub(actor) = { "That would be impolite at best. "; }
    verDoGloat(actor) = { "\^<<self.thedesc>> might not take kindly to that. "; }
;

modify basicMe
    readyToSleep = nil
    noun = ''
    verDoAskAbout(actor) = {
        "You only know what you know. ";
    }
    cutMyself = nil
    verDoName(actor) = { "You already have a perfectly good name. "; }
    verDoPet(actor) = { "You stroke your hair gently, purring in response. ";}
    verDoCutWith(actor, io) = {
        if (self.cutMyself)
            "You cannot bring yourself to cut yourself again. ";
    }
    doCutWith(actor, io) = {
        self.cutMyself = true;
        "You slice one of your fingers open, hissing at the pain. The blood
            drips from your fingers to the ground. Then the cut seals itself,
            leaving you with only a memory of the sharp pain. ";
        my_blood_pool.moveInto(actor.location);    // Defined in home.t
        if (io == pocketknife)
            io.drawnBlood = true;
    }
    verDoRub(actor) = { "You rub your head playfully. "; }
    verDoInjectIn(actor, io) = {
        "You need to specify what you want to inject yourself with. ";
    }
    verDoInjectWith(actor, io) = {
        "You need to specify where you want to inject yourself. ";
    }
    verDoSearch(actor) = {}
    doSearch(actor) = {
        iVerb.action(actor);
    }
;

/*
   Useful functions
*/
makeQuote: function(quote, author)
{
    "<<quote>>\n\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ -- <<
        author>>\b\b";
}

pauseAndClear: function
{
    "\b[Press a key to continue]";
    inputkey();
    clearscreen();
}

/*
   New class/object section
*/

// Where to put things when I still need people to be able to ask about them
limbo: room
;

// Rooms that are indoors
class insideRm: room
;

ceiling: floatingItem, decoration
    noun = 'ceiling'
    location = {
        if (isclass(Me.location, insideRm) && !Me.location.noCeiling)
            return Me.location;
        else return nil;
    }
    sdesc = "ceiling"
    ldesc = {
        if (proptype(Me.location, &ceildesc) != 5)
            Me.location.ceildesc;
        else "It looms above you. ";
    }
;

fake_wall: floatingItem, decoration
    noun = 'wall' 'walls'
    location = {
        if (isclass(Me.location, insideRm) && !Me.location.noWall)
            return Me.location;
        else return nil;
    }
    sdesc = "wall"
    ldesc = "There is nothing interesting about the wall. "
;

class doorItem: doorway
    noun = 'door'
    plural = 'doors'
    sdesc = "door"
    lookthrudesc = "You cannot see far enough beyond the door to form any
        useful conclusions. "
    verDoKnockon(actor) = { "No one answers. "; }
    verDoLookthru(actor) = {
        if (!self.isopen)
            "You find it difficult to do, given that the door is closed. ";
        else self.lookthrudesc;
    }
;

class myDoorway: fixedItem
    noun = 'doorway'
    plural = 'doorways'
    sdesc = "doorway"
    lookthrudesc = "You cannot see far enough beyond the doorway to form any
        useful conclusions. "
    verDoLookthru(actor) = { self.lookthrudesc; }
    verDoEnter(actor) = {}
    doEnter(actor) = { actor.travelTo(doordest); }
;

class bodypart: fixeditem
    isListed = nil    // Don't include us in contlist()
    isBodypart = true
    numbed = nil      // Have I been injected with novocaine?
//    location=Me
    // can it be reached by 'manipulative' verbs?
    isReachable(actor) = (self.location==Me)
    // called by inspectVerb.validDoList - floaters are probably visible
    isVisible(actor) = (self.location==Me)
    bulk=0
    weight=0
    replace verifyRemove(a) = {
        "Not bloody likely. ";
    }
    // don't allow us to do unexpected things
    noCanDoMsg = "There's no need to do that. "
    dobjGen(a,v,i,p) = { self.noCanDoMsg; exit; }
    iobjGen(a,v,o,p) = { self.noCanDoMsg; exit; }
    // inspect isn't unexpected
    verDoInspect(a) = {}
    // We can put lotion on body parts
    verIoPourOn(actor) = {}
    ioPourOn(actor, dobj) = { dobj.doPourOn(actor, self); }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (dobj != lotion)
            "There's no need to do that. ";
        else dobj.doPourOn(actor, self);
    }
;

arms: bodypart
    noun = 'arm'
    plural = 'arms'
    adjective = 'left' 'right' 'my'
    sdesc = "arms"
    ldesc = {
        "Your arms dangle from your shoulders. ";
        if (bp_cuff.isworn)
            "Wrapped around one of them is a blood pressure cuff. ";
    }
    thedesc = "your arm"
    adesc = "your arm"
    verDoPutIn(actor, iobj) = {
        if (iobj != crate_gap)
            self.noCanDoMsg;
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj == needle)
            needle.doWear(actor);
        else if (dobj == syringe)
            syringe.doInjectIn(actor, self);
        else "There's no need to put that in your arm. ";
    }
    verIoOpenWith(a) = {}
    ioOpenWith(a,dobj) = (dobj.doOpen(a))
    verIoInjectIn(actor) = {}
    verDoInjectWith(actor, io) = {}
    verDoClench(actor) = {}
    doClench(actor) = { "You flex your arms. "; }
    verDoRelax(actor) = {}
    doRelax(actor) = { "You relax your arms as much as possible. "; }
;

hands: bodypart
    noun = 'hand' 'fist'
    plural = 'hands' 'fists'
    adjective = 'left' 'right' 'my'
    sdesc = "hands"
    ldesc = {
        "Your hands are, surprisingly, on the end of your arms. ";
        if (ending_iv_needle.location == self)
            "An IV needle is stuck in the back of one of them. ";
    }
    thedesc = "your hand"
    adesc = "your hand"
    verDoPutIn(actor, dobj) = {
        if (dobj != crate_gap)
            self.noCanDoMsg;
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj == syringe)
            syringe.doInjectIn(actor, self);
        else if (dobj == gurney_needle)
            gurney_needle.doWear(actor);
        else if (dobj == needle)
            needle.doWear(actor);
        else "There's no need to put that in your hand. ";
    }
    verIoInjectIn(actor) = {}
    verDoInjectWith(actor, io) = {}
    verDoOpen(actor) = {}
    doOpen(actor) = {
        local words;
        
        words = objwords(1);
        "You open your hand";
        if (find(words, 'hands') != nil)
            "s";
        ". ";
        if (actor.location != old_standing_dad.location)
            return;
        "A sense of momentary peace spreads throughout your body. ";
        actor.relaxed = true;
        notify(actor, &tenseUp, 1);
    }
    verDoRelax(actor) = {}
    doRelax(actor) = {
        "You relax your hands as best you can. ";
        if (actor.location != old_standing_dad.location)
            return;
        "A sense of momentary peace spreads throughout your body. ";
        actor.relaxed = true;
        notify(actor, &tenseUp, 1);
    }
    verDoClench(actor) = {}
    doClench(actor) = { self.doMake(actor); }
    verDoMake(actor) = {
        local words;
        
        words = objwords(1);
        if (find(words, 'hand') != nil || find(words, 'hands') != nil)
            "There is no need to make your hands. ";
    }
    doMake(actor) = {
        local words, rightFlag, leftFlag;

        words = objwords(1);
        rightFlag = (find(words, 'right') != nil);
        leftFlag = (find(words, 'left') != nil);
        if (find(words, 'fists') != nil || find(words, 'hands') != nil) {
            rightFlag = true;
            leftFlag = true;
        }
        if (!leftFlag && !rightFlag) {
            "You need to specify either your right or your left. ";
            abort;
        }
        "You make a fist with ";
        if (rightFlag && leftFlag)
            "both hands";
        else "your <<rightFlag ? "right" : "left">> hand";
        if (actor.location != old_standing_dad.location) {
            " for a moment before relaxing. ";
            return;
        }
        if ((!leftFlag && argument_daemon.result > 0) ||
            (!rightFlag && argument_daemon.result < 0)) {
            ", but nothing happens. ";
            return;
        }
        ". A shock races from your feet up, concentrating in your hand.
            Power gathers there; your organs feel as if they will be ripped
            from their moorings. ";
        if (gloves.isworn)
            "Detached, you watch your glove flake into ash and drift away. ";
        "The pain is overwhelming, then the
            power rushes from your fist in one tremendous pulse. You drop to
            one knee, drained.\b
            The pulse moves through your father with a wet, squishy noise.
            Blood squirts from his eyes, his nose, his mouth. He collapses as
            if his innards had turned to jelly.\b
            Darkness enfolds you.\b";
        Me.ctrlPoints = -1;
        unnotify(old_standing_dad, &end);
        dadFinalAh.solve;
        ending_hospital_bed.setup;
    }
;

class rollItem: fixeditem
    goTo = nil
    moveMe(dir, actor) = {
        self.movedesc(dir);
        self.moveInto(self.goTo);
        actor.travelTo(self.location);
    }
    verDoPush(actor) = { "In which direction would %you% like to push <<
        self.thedesc>>? "; }
    verDoMove(actor) = { "In what direction do %you% want to move <<
        self.thedesc>>? "; }
    check_dir(dir) = {
        if (proptype(self.location, dir) == 6) return nil;
        self.goTo = self.location.(dir);
        if (isclass(self.goTo, room))
            return true;
        if (!isclass(self.goTo, obstacle))
            return true;
        if (self.goTo.isopen) {
            self.goTo = self.goTo.doordest;
            if (self.goTo == nil) return nil;
            return true;
        }
        if (self.goTo.swingDoors && !self.goTo.islocked) {
            self.goTo = self.goTo.doordest;
            return true;
        }
        return nil;
    }
    verDoMoveN(actor) = {
        if (actor.location == self)
            "%You% will have to get <<self.outofPrep>> the chair first. ";
        else if (!self.check_dir(&north))
            "You are blocked in that direction. ";
    }
    verDoMoveS(actor) = {
        if (actor.location == self)
            "%You% will have to get <<self.outofPrep>> the chair first. ";
        else if (!self.check_dir(&south))
            "You are blocked in that direction. ";
    }
    verDoMoveE(actor) = {
        if (actor.location == self)
            "%You% will have to get <<self.outofPrep>> the chair first. ";
        else if (!self.check_dir(&east))
            "You are blocked in that direction. ";
    }
    verDoMoveW(actor) = {
        if (actor.location == self)
            "%You% will have to get <<self.outofPrep>> the chair first. ";
        else if (!self.check_dir(&west))
            "You are blocked in that direction. ";
    }
    verDoMoveNE(actor) = {
        if (!self.check_dir(&ne))
            "You are blocked in that direction. ";
    }
    verDoMoveNW(actor) = {
        if (!self.check_dir(&nw))
            "You are blocked in that direction. ";
    }
    verDoMoveSE(actor) = {
        if (!self.check_dir(&se))
            "You are blocked in that direction. ";
    }
    verDoMoveSW(actor) = {
        if (!self.check_dir(&sw))
            "You are blocked in that direction. ";
    }
    doMoveN(actor) = {
        self.moveMe('north', actor);
    }
    doMoveS(actor) = {
        self.moveMe('south', actor);
    }
    doMoveE(actor) = {
        self.moveMe('east', actor);
    }
    doMoveW(actor) = {
        self.moveMe('west', actor);
    }
    doMoveNE(actor) = {
        self.moveMe('northeast', actor);
    }
    doMoveNW(actor) = {
        self.moveMe('northwest', actor);
    }
    doMoveSE(actor) = {
        self.moveMe('southeast', actor);
    }
    doMoveSW(actor) = {
        self.moveMe('southwest', actor);
    }
;

hollow_fool: item
    noun = 'fool' 'doll' 'harlequin'
    adjective = 'hollow'
    sdesc = "fool"
    ldesc = "A tiny doll tricked out in a harlequin's outfit. When you turn it
        over in your hands, you see that its back is missing, leaving the fool
        hollow. There is a matching hole where its larynx should be. "
;

/*
   Modified objects
*/
modify theFloor
    adjective = 'marble'
    location = {
        if (Me.location == self)
            return( self.sitloc );
        else if (!Me.location.noFloor)
            return(Me.location);
        else return nil;
    }
    ldesc = {
        if (proptype(Me.location, &floordesc) != 5)
            Me.location.floordesc;
        else pass ldesc;
    }
    verDoDig(actor) = {
        if (ground_mud.location == actor.location)
            ground_mud.verDoDig(actor);
        else pass verDoDig;
    }
    doDig(actor) = {
        ground_mud.doDig(actor);
    }
    verDoClean(actor) = {
        if (muddy_footprints.location != actor.location &&
            muddy_smear.location != actor.location)
        pass verDoClean;
    }
    doClean(actor) = {
        if (muddy_footprints.location == actor.location)
            muddy_footprints.doClean(actor);
        else muddy_smear.verDoClean(actor);
    }
;

modify switchItem
    doSynonym('Switch') = 'Throw' 'Flip'
;

modify nestedroom
    exits = "You can go nowhere until you get <<self.outOfPrep>> <<
        self.thedesc>>. "
;

modify chairItem
    jumpAction = "Not while you're <<self.statusPrep>> <<self.thedesc>>. "
;


// askaboutParseError (from askabout.t) must be modified due to my hacking of
//   askVerb's validIo routine below.  This is also where I placed the new
//   hacks to allow actors to say the disambiguation strings (i.e., Actor
//   says, "Which club did you mean, the club soda or the blackjack?").  See
//   askVerb below
modify askaboutParseError
    replace myParseError(errno, str) = {
        if ((errno == 2 || errno == 9) && askVerb.isAsking) {
            return 'There is no reply. ';
        }
        if (errno == 100 && askVerb.myActor != nil) {
            return askVerb.myActor.stringsdesc + ' sighs. ';
        }
        if (errno == 101) {
            global.disambiguating = true;
            if (askVerb.myActor != nil)
                return askVerb.myActor.stringsdesc + ' asks, "' + str;
        }
        if (errno == 104) {
            global.disambiguating = nil;
            if (askVerb.myActor != nil) {
                askVerb.myActor = nil;
                return str + '"';
            }
        }
        return nil;
    }
;

/*
   New verb/prep section
*/
// Information about the game
aboutVerb: sysverb
    sdesc = "about"
    verb = 'about'
    action(actor) = {
"\(Losing Your Grip\) is copyright 1997-2001 by Stephen Granade. It may be
freely copied, distributed and played as long as it is not modified in any
way. You may not distribute copies of the game for a fee exceeding the cost
of distribution.\b

The game is fairly long. The game may also be rendered unwinnable.
Save often, and keep your old saved games handy. \(Losing Your Grip\) is not
intended to be unreasonable; however, it is intended to be challenging.\b

\(Losing Your Grip\) is shareware. I encourage you to play even if you
have no intention of registering; I don't intend to guilt you into paying
for the game. (Not that I want to \(discourage\) you from registering, mind.)
My main reason for making this game shareware is to allow me
to offer a manual and some goodies in the style of old Infocom games.
Registering will also give you access to the on-line hints. If you do enjoy
the game and would like to register, type \(register\) for more information.\b

\(Losing Your Grip\) was authored using TADS, the Text Adventure Development
System, by Michael Roberts. It and other text adventures are available at\n
ftp://ftp.gmd.de/if-archive/\b

For a list of special commands, type \(commands\). The \(credits\) command
will list all applicable credits for \(Losing Your Grip\).\b

As of 2001 I may be reached at:\b
\ \ \ Stephen Granade\n
\ \ \ Physics Dept.\ Rm 156\n
\ \ \ Science Drive
\ \ \ Duke University\n
\ \ \ Durham, NC 27708-0305\n
\ \ \ USA\n
\ \ \ email: sgranade@phy.duke.edu";

"\b(Note that as of 2001 \(Losing Your Grip\) is no longer shareware.)";
        abort;
    }
;

// About the author
authorVerb: deepverb
    sdesc = "author"
    verb = 'author'
    action(actor) = {
        "At the tender age of four Stephen Granade was diagnosed as
            borderline hyperactive. Since then, he has been unable to
            concentrate on just one thing at a time. He tried acting and
            singing before settling on a career as a physicist. \(Losing
            Your Grip\) is the third piece of interactive fiction he
            will admit to. ";
        abort;
    }
;

// Prints the special commands
commandsVerb: sysverb
    sdesc = "commands"
    verb = 'commands'
    action(actor) = {
"ABOUT: Prints information about \(Losing Your Grip\).\b

AGAIN or G: Repeats your last command. If your last input line was
composed of several commands, only the last command on the line is repeated.\b

AUTHOR: About the author.\b

COMMANDS: Shows a list of these special commands.\b

CREDITS: Lists the credits for \(Losing Your Grip\).\b

DEDICATION: Prints the game's dedication.\b

EXITS: Lists the possible exits from your location.\b

HINT: Gives a hint about whatever puzzle you are stuck on. Only valid in
registered copies.\b

INVENTORY or I: Shows the list of items you are carrying.\b

INVENTORY TALL: Changes the inventory style to Infocom's style.\b

INVENTORY WIDE: Changes the inventory style to the default TADS style.\b

LOOK or L: Gives the full description of your location.\b

NOTIFY: Turns score notification on or off. Score notification is on by
default.\b

OOPS: Allows you to correct the spelling of a word in the last command. You
can use OOPS when the game displays this complaint: \"I don't know the word
<word>.\"  Immediately after this message, you can type OOPS followed by the
corrected spelling of the misspelled word. You can only type one word after
OOPS, so this command doesn't allow you to correct certain types of errors,
such as when you run two words together without a space.\b

QUIT or Q: Ends the game.\b

REGISTER: Information on ";

        if (global.registered)
            "who has registered this copy of";
        else "how to register";

" \(Losing Your Grip\).\b

RESTART: Starts the game over from the beginning.\b

RESTORE: Restores a position previously saved with the SAVE command.\b

REVIEW: Reviews the hints you have already been given.\b

SAVE: Stores the current state of the game in a disk file, so that you can
come back to the same place later with the RESTORE command.\b

SCORE: Shows you your current score and the maximum possible score.\b

SCRIPT: Starts writing everything you see on the screen (both your commands
and the game's responses) to a disk file. The game will ask you for a filename
to be used for the transcript; you should select a filename that does not yet
exist on your disk, because if you use an existing filename, data in that
file will be destroyed. Use the UNSCRIPT command to stop making the
transcript.\b

TERSE: For impatient users, this tells the game that you wish to see only
short descriptions of locations you have already seen when you reenter them.
See also the VERBOSE command.\b

UNDO: Tells the game you want to take back your last command. The game state
will be restored to the way it was before the previous command, as though the
command were never issued at all. You can do this more than once in a row.\b

UNSCRIPT: Turns off the transcript that was begun with the SCRIPT command.\b

VERBOSE: For amnesiac players, this tells the game to show you the full
description of every location you enter, whether or not you have seen the
description before. This is the default mode. See also the TERSE command.\b

VERSION: Shows the current version number of the game.\b

WAIT or Z: Causes game time to pass. When the game is waiting for you to type
a command, no game time passes; you can use this command to wait for something
to happen.";
        abort;
    }
;

// The dedication for the game
dedicationVerb: sysverb
    sdesc = "dedication"
    verb = 'dedication'
    action(actor) = {
        "\bFor my dad, who first taught me love of language.\n
            May I someday write as well as you.\n";
        abort;
    }
;

// This verb prevents seeding the random number generator if activated
//  within the first turn
deterministicVerb: sysverb
    sdesc = "deterministic"
    verb = 'deterministic'
    action(actor) = { global.noRand = true; abort; }
;

// Prints the exits from a room
exitsVerb: sysverb
    sdesc = "exits"
    verb = 'exits'
    action(actor) = {
        local prop = proptype(actor.location, &exits);

        if (prop == 3)
            "You can go <<actor.location.exits>>. ";
        else actor.location.exits;
        abort;
    }
;

// Find out about registration
registerVerb: sysverb
    sdesc = "register"
    verb = 'register'
    action(actor) = {
        if (global.registered) {
            "This copy of \(Losing Your Grip\) has already been registered
                to <<global.registeredTo>>. ";
            abort;
        }
"You can no longer register \(Losing Your Grip\). The feelies, including
the registration key, can be found at the IF Archive at
http://www.ifarchive.org/if-archive/games/tads/gripfeelies.zip";
/*"You can register either by sending me $20 US or by using Kagi's registration
service. If you register using Kagi, it will cost $23 US to cover their fees.
However, if you register using Kagi you can use credit cards. If a
registration program was not included with this game, you can register on-line
at http://order.kagi.com/?4V5.\b

For your trouble you will receive a key to unlock the online hints, a manual, 
and several other goodies. To register, either visit the Kagi web page or
send $20 in
American dollars to the address below and a letter giving \(your name\), the
\(address\) to which you wish the game shipped, \(and which operating system
you use\). Your name and operating system are \(very\) important; I will use
your name to create the registration key which unlocks the hints, and I will
be sending you either an MS-DOS disk or a Macintosh disk with the latest
version of the game for your particular operating system. The address:\b
\ \ \ Stephen Granade\n
\ \ \ Physics Dept.\ Room 156\n
\ \ \ Science Drive\n
\ \ \ Duke University\n
\ \ \ Durham, NC 27708-0305\n
\ \ \ USA\b
This address is good through roughly the middle of 2001. After that, either
send a letter sans money first, or attempt to contact me on-line at
sgranade@kagi.com or sgranade@phy.duke.edu.";*/
        abort;
    }
;

// The obligatory verb
xyzzyVerb: deepverb
    foolFlag = nil
    sdesc = "xyzzy"
    verb = 'xyzzy'
    action(actor) = {
        if (Me.stage == 0 || self.foolFlag || Me.location.isInDoll)
            "Nothing happens. ";
        else {
            self.foolFlag = true;
            "There is a puff of smoke. Something lands in your hands. ";
            hollow_fool.moveInto(actor);
        }
    }
;

kickVerb: deepverb
    touch = true
    sdesc = "kick"
    verb = 'kick'
    doAction = 'Kick'
;

kissVerb: deepverb
    touch = true
    sdesc = "kiss"
    verb = 'kiss'
    doAction = 'Kiss'
;

gloatVerb: deepverb
    sdesc = "gloat"
    verb = 'gloat' 'gloat at' 'taunt'
    action(actor) = "You chortle nastily. "
    doAction = 'Gloat'
;

tearVerb: deepverb
    touch = true
    sdesc = "tear"
    verb = 'tear' 'rip' 'unravel'
    doAction = 'Tear'
;

thankVerb: deepverb
    sdesc = "thank"
    verb = 'thank' 'thanks'
    action(actor) = { "You're welcome. "; }
    doAction = 'Thank'
;

raiseVerb: deepverb
    touch = true
    sdesc = "raise"
    verb = 'raise'
    doAction = 'Raise'
;

lowerVerb: deepverb
    touch = true
    sdesc = "lower"
    verb = 'lower'
    doAction = 'Lower'
;

standBehindVerb: deepverb
    sdesc = "stand behind"
    verb = 'stand behind' 'stand at'
    doAction = 'StandBehind'
;

turnclockwiseVerb: deepverb
    touch = true
    sdesc = "turn clockwise"
    verb = 'turn clockwise' 'turn cw' 'turn right'
    doAction = 'TurnCW'
;

turnccwVerb: deepverb
    touch = true
    sdesc = "turn counterclockwise"
    verb = 'turn counterclockwise' 'turn ccw' 'turn anticlockwise' 'turn left'
    doAction = 'TurnCCW'
;

cwPrep: Prep
    sdesc = "clockwise"
    preposition = 'clockwise' 'cw' 'right'
;

ccwPrep: Prep
    sdesc = "counterclockwise"
    preposition = 'counterclockwise' 'anticlockwise' 'ccw' 'left'
;

tieVerb: deepverb
    touch = true
    verb = 'tie'
    sdesc = "tie"
    prepDefault = toPrep
    ioAction(toPrep) = 'TieTo'
    ioAction(aroundPrep) = 'TieTo'
;

untieVerb: deepverb
    touch = true
    verb = 'untie' 'unlash'
    sdesc = "untie"
    doAction = 'Untie'
;

nameVerb: deepverb
    name = ''        // The name that was typed in
    verb = 'name' 'call'
    sdesc = "name"
    doAction = 'Name'
    action(actor) = {
        "You may name something by using NAME OBJECT \"NEWNAME\". ";
        abort;
    }
;

petVerb: deepverb
    touch = true
    verb = 'pet' 'stroke' 'pat'
    sdesc = "pet"
    doAction = 'Pet'
;

stayVerb: deepverb
    verb = 'stay'
    sdesc = "stay"
    action(actor) = { "%You% go%es% nowhere. "; }
;

heelVerb: deepverb
    verb = 'heel'
    sdesc = "heel"
    action(actor) = { "%You% begin%s% following yourself. "; }
;

insertVerb: deepverb
    verb = 'insert'
    sdesc = "insert"
    ioAction(inPrep) = 'PutIn'
;

hideVerb: deepverb
    verb = 'hide behind' 'get behind' 'go behind'
    sdesc = "hide behind"
    doAction = 'HideBehind'
;

unhideVerb: deepverb
    verb = 'get outfrombehind'
    sdesc = "get out from behind"
    doAction = 'UnhideBehind'
;

outfrombehindPrep: Prep
    preposition = 'outfrombehind'
    sdesc = "out from behind"
;

squeezeVerb: deepverb
    touch = true
    verb = 'squeeze' 'inflate'
    sdesc = "squeeze"
    doAction = 'Squeeze'
;

injectVerb: deepverb
    touch = true
    verb = 'inject' 'stick'
    sdesc = "inject"
    prepDefault = withPrep
    ioAction(inPrep) = 'InjectIn'
    ioAction(withPrep) = 'InjectWith'
;

pourVerb: deepverb
    verb = 'pour'
    sdesc = "pour"
    prepDefault = onPrep
    ioAction(onPrep) = 'PourOn'
;

dipVerb: deepverb
    touch = true
    verb = 'dip'
    sdesc = "dip"
    prepDefault = inPrep
    ioAction(inPrep) = 'DipIn'
;

swimVerb: deepverb
    touch = true
    verb = 'swim' 'swim in'
    sdesc = "swim in"
    action(actor) = {
        local i;
        i = proptype(Me.location, &swimAction);
        if (i == 6 || i == 9)
            Me.location.swimAction;
        else askdo;
    }
    doAction = 'Swimin'
;

beginVerb: deepverb
    verb = 'begin' 'start'
    sdesc = "begin"
    doAction = 'Begin'
;

performVerb: deepverb
    verb = 'perform'
    sdesc = "perform"
    doAction = 'Perform'
;

stopVerb: deepverb
    verb = 'stop'
    sdesc = "stop"
    doAction = 'Stop'
;

climbupVerb: deepverb
    touch = true
    verb = 'climb up'
    sdesc = "climb up"
    doAction = 'Climbup'
;

climbdownVerb: deepverb
    touch = true
    verb = 'climb down'
    sdesc = "climb down"
    doAction = 'Climbdown'
;

cutVerb: deepverb
    touch = true
    verb = 'cut' 'carve' 'hack'
    sdesc = "cut"
    prepDefault = withPrep
    ioAction(withPrep) = 'CutWith'
    ioAction(inPrep) = 'CutIn'
;

//knockVerb: deepverb  [### changed to adapt to adv.t 2.2.4]
replace knockVerb: deepverb
    touch = true
    verb = 'knock on' 'knock'
    sdesc = "knock on"
    doAction = 'Knockon'
;

rubVerb: deepverb
    touch = true
    verb = 'rub'
    sdesc = "rub"
    doAction = 'Rub'
;

moveUVerb: deepverb
    verb = 'move up' 'move u' 'push up' 'push u' 'wheel up' 'wheel u'
    sdesc = "move up"
    doAction = 'MoveU'
;

moveDVerb: deepverb
    verb = 'move down' 'move d' 'push down' 'push d' 'wheel down' 'wheel d'
    sdesc = "move down"
    doAction = 'MoveD'
;

fillVerb: deepverb
    touch = true
    verb = 'fill'
    sdesc = "fill"
    doAction = 'Fill'
    ioAction(withPrep) = 'FillWith'
;

emptyVerb: deepverb
    touch = true
    verb = 'empty'
    sdesc = "empty"
    doAction = 'Empty'
;

makeVerb: deepverb
    touch = true
    verb = 'make'
    sdesc = "make"
    doAction = 'Make'
;

unmakeVerb: deepverb
    touch = true
    verb = 'unmake'
    sdesc = "unmake"
    doAction = 'Unmake'
;

clenchVerb: deepverb
    verb = 'clench'
    sdesc = "clench"
    doAction = 'Clench'
;

relaxVerb: deepverb
    verb = 'relax' 'let go'
    sdesc = "relax"
    doAction = 'Relax'
;

goPrep: Prep
    preposition = 'go'
    sdesc = "go"
;

/*
   Modified verb section
*/

modify hintVerb
    verb = 'hint' 'hints' 'help'
    action(actor) = {
        if (!global.registered) {
            "Hints are only enabled in the registered version of \(Losing
                Your Grip\). For information on registering, please type
                \(register\). ";
            abort;
        }
        pass action;
    }
;

modify reviewVerb
    action(actor) = {
        if (!global.registered) {
            "Hints are only enabled in the registered version of \(Losing
                Your Grip\). For information on registering, please type
                \(register\). ";
            abort;
        }
        pass action;
    }
;

modify creditsVerb
    credit_header = {
        "\nAs is to be expected, no project of this magnitude is accomplished
            without the help of many. I would like to thank the following
            beta-testers:\ Michael Kinyon, Jools Arnold, Magnus Olsson,
            and Lon Thomas.\b";
        "Special thanks go to Michael Self, who critiqued an early form of
            this game; to Nicholas James, who created the original concept
            and design of the Matruska dolls; to Misty Granade, who designed
            the registration package; to Margaret Boozer, who gave
            invaluable advice about all things medical; and to Andrew
            Plotkin, who created the groovilicious \(Grip\) icon.\b";
        "The following people made suggestions about and discovered bugs in
            the released versions: Torbjorn Andersson, Gerry Kevin Wilson,
            Adam Thornton, David Gilbert, Ola Mikael Hansson, Ken Fair,
            D.\ J.\ Picton, Dan Shiovitz, Michael Gentry, Ben Hines, Russell
            Mirabelli, Axel Hundemer, Martin Braun, David Glasser, Andrew
            Plotkin, Mark Tilford, Neil deMause, Gunther Schmidl,
            Lucian P.\ Smith, and Brendan Milburn.\b";
        "In addition, these modules were provided by TADS developers
            who were prepared to share their work with others:\ ";
    }
;

modify sleepVerb
    action(actor) = {
        if (Me.readyToSleep)
            "Wait one moment. ";
        else "You find yourself unable to sleep. ";
    }
;

modify readVerb
    validDo(actor, obj, seqno) = {
        return(obj.isVisible(actor));
    }
;    

modify digVerb
    doAction = 'Dig'
;

modify yellVerb
    verb = 'scream'
;

modify sitVerb
    action(actor) = { "%You% must specify where you want to sit. "; }
;

modify takeVerb
    verb = 'fetch' 'hold'
    ioAction(withPrep) = 'TakeWith'
;

modify attachVerb
    verb = 'join' 'splice'
;

// For putting the rope OVER the pulley & putting things UNDER other things
modify putVerb
    verb = 'loop'
    ioAction(overPrep) = 'PutOn'
    ioAction(underPrep) = 'PutUnder'
;

modify outVerb
    verb = 'get down'
;

modify attackVerb
    verb = 'sic' 'waylay'    // 'waylay' is just for ddyte. Enjoy!
    doAction = 'Attack'
;

modify inVerb
    verb = 'climb out' 'climb in' 'climb through'
;

modify pushVerb
    ioAction(toPrep) = 'PutIn'
    ioAction(inPrep) = 'PutIn'
;

modify moveNVerb
    verb = 'wheel north' 'wheel n' 'roll north' 'roll n'
;

modify moveSVerb
    verb = 'wheel south' 'wheel s' 'roll south' 'roll s'
;

modify moveEVerb
    verb = 'wheel east' 'wheel e' 'roll east' 'roll e'
;

modify moveWVerb
    verb = 'wheel west' 'wheel w' 'roll west' 'roll w'
;

modify moveNEVerb
    verb = 'wheel northeast' 'wheel ne' 'roll northeast' 'roll ne'
;

modify moveSEVerb
    verb = 'wheel southeast' 'wheel se' 'roll southeast' 'roll se'
;

modify moveNWVerb
    verb = 'wheel northwest' 'wheel nw' 'roll northwest' 'roll nw'
;

modify moveSWVerb
    verb = 'wheel southwest' 'wheel sw' 'roll southwest' 'roll sw'
;

modify breakVerb
    verb = 'smash'
;

// Modify yellVerb so that dad can respond to you
modify yellVerb
    action(actor) = {
        if (uberloc(actor) == bedroom)
            "\"Terry!\"\ your father yells from somewhere in the house. \"If
                you don't hush I'll give you something to yell about!\" ";
        else pass action;
    }
;

modify turnVerb
    verb = 'set'
;

modify throwVerb
    ioAction(thruPrep) = 'ThrowAt'
;

// Modify throwVerb so you can "throw xxx into yyy"
modify throwVerb
    doAction = 'Throw'
    ioAction(inPrep) = 'ThrowAt'
;

// Yes/no/maybe verbs now handle Marie & Jefrey's questions
modify yesVerb
    action(actor) = {
        if (proptype(argument_daemon, &paused) == 13)
            argument_daemon.(argument_daemon.paused)(1);
        else pass action;
    }
;

modify noVerb
    action(actor) = {
        if (proptype(argument_daemon, &paused) == 13)
            argument_daemon.(argument_daemon.paused)(2);
        else pass action;
    }
;

modify maybeVerb
    verb = 'neither'
    action(actor) = {
        if (proptype(argument_daemon, &paused) == 13)
            argument_daemon.(argument_daemon.paused)(0);
        else pass action;
    }
;

modify cleanVerb
    verb = 'scrub'
;

modify jumpVerb
    action(actor) = {
        if (actor.location.isPlane) {
            if (getfuse(infinite_plane_one, &resetRipples) != nil) {
                "You jump again, damping out the ripples. ";
                infinite_plane_one.isRippling = nil;
                return;
            }
            "You jump, higher than you would have expected. When you land the
                plane begins rippling violently. ";
            if (
                (actor.location == infinite_plane_one &&
                    (length(contlist(infinite_plane_one)) > 2 ||
                        (length(contlist(infinite_plane_zero)) > 0 &&
                            (actor.location.inverted ||
                             actor.location.positionNum == 1
                            )
                        )
                    )
                )
                || (
                    actor.location != infinite_plane_one && 
                    length(contlist(actor.location)) > 1
                )
            )
                "Everything on the plane floats up, hovering above the
                    ground. ";
            infinite_plane_one.isRippling = true;
            notify(infinite_plane_one, &resetRipples, 2);
        }
        else {
            local i;
            i = proptype(Me.location, &jumpAction);
            if (i == 6 || i == 9)
                Me.location.jumpAction;
            else "Such fun should be illegal. ";
        }
    }
;

// An infinitely more complex askAbout handler
// What happens is this:
//   Objects which have a definite stage may only be asked about within that
//      stage
//   Objects which are located in nil are not considered
//   askVerb keeps track of the seqno of the first object it accepts.  If an
//      object doesn't care if it is asked about or not (i.e. askDisambig
//      is not set), then it is accepted if it is the first such object to be
//      tested; otherwise, it isn't accepted.
//   Any actor who is a valid do and has selfDisambig set is placed in
//      myActor.  see askaboutParseError above.
// N.B. The disambigDobjFirst is necessary--that way, the actors (the dobjs)
//      are disambiguated before the iobjs, allowing the actors to ask the
//      disambiguation questions
modify askVerb
    myseqno = 999
    myActor = nil
    // This next statement will require a whole lotta changes...
    ioAction(aboutPrep) = [disambigDobjFirst] 'AskAbout'
    validDo(actor, obj, seqno) = {
        if (obj.isReachable(actor)) {
            if (obj.selfDisambig) {
                myActor = obj;
                notify(self, &clearMyActor, 1);
            }
            return true;
        }
        return nil;
    }
    validIo(actor, obj, seqno) = {
        // If the obj's from a dif. stage than the player is in, don't ask
        if ((proptype(obj, &stage) == 1 || proptype(obj, &stage) == 3)
            && obj.stage != Me.stage)
            return nil;
        // If the obj's in nil && isn't wallpaper, don't ask don't tell
        if (obj.location == nil && !isclass(obj, wallpaper))
            return nil;
        if (myseqno > seqno)   // If myseqno > seqno, then this is a new loop
            myseqno = seqno;
        // If the obj's not worried about disambiguation, check seqno
        if (!obj.askDisambig && myseqno != seqno)
            return nil;
        return true;
    }
    clearMyActor = {
        myActor = nil;
    }
;

/*
   Modifications to room to handle the rope being tied to something
*/

modify room
    leaveRoom(actor) = {    // Can't leave with the rope
        if (rope.location == actor && rope.tiedTo != nil &&
                rope.tiedTo.location != actor && !actor.location.notLeaving) {
            if (rope.tiedTo == dog) {
                dog.isLying = nil;
                pass leaveRoom;
            }
            "Not until you either drop the rope or untie it
                from <<rope.tiedTo.thedesc>>. ";
            exit;
        }
        pass leaveRoom;
    }
;

/*
   preparse modification to handle the "name" verb.  For information on
   preparseItem, see the parseErr.t module.
*/
griphPreparse: preparseItem
    parseOn = true
    myPreparse(str) = {
        local i, mystr, ret;

        mystr = str;
        // Remove leading whitespace
        for (i = 1; substr(mystr, i, 1) == ' '; i++);
        mystr = substr(mystr, i, length(mystr) - i + 1);
        // If the command doesn't contain the word "name", return
        if ((i = find(mystr, 'name ')) == nil) {
            nameVerb.name = '';
            return true;
        }
        // Make sure "name" is used as a _verb_
        if (i != 1 && find(mystr, '; name ') == nil &&
            find(mystr, '!  name ') == nil && find(mystr, '?  name ') == nil &&
            find(mystr, '.  name ') == nil && find(mystr, '!name ') == nil &&
            find(mystr, '?name ') == nil && find(mystr, '.name ') == nil &&
            find(mystr, ' then name ') == nil && find(mystr, ',name ') == nil &&
            find(mystr, ', name ') == nil && find(mystr, ' and name ') == nil) {
            nameVerb.name = '';
            return true;
        }
        // Find the leading quote marks
        if ((i = find(mystr, '"')) == nil) {
            global.allMessage = 'You may name something by using NAME
                OBJECT "NEWNAME".';
            nameVerb.name = '';
            return true;
        }
        i++; mystr = substr(mystr, i, length(mystr) - i + 1);
        if ((i = find(mystr, '"')) == nil)
            return true;
        nameVerb.name = lower(substr(mystr, 1, i - 1));
        return substr(str, 1, find(str, '"') - 1);
    }
;

/*
   New compound word--outfrombehind
*/
compoundWord 'out' 'from' 'outfrom';
compoundWord 'outfrom' 'behind' 'outfrombehind';


/*
   New format string--were
*/
formatstring 'were' fmtWere;

modify movableActor
    fmtWere = "was";
modify basicMe
    noun = ''
    fmtWere = "were";

/*
   Here is where I change all the verDoAskAbout() and verIoAskAbout() routines.
   This is an ugly change, but it's the only way...
*/
modify thing
    verIoAskAbout(actor, dobj) = {}
    verDoAskAbout(actor) = {
        "Surely %you% can't think <<self.thedesc>> know<<self.isThem ?
            "" : "s">> anything about that! ";
    }
;

modify movableActor
    verDoAskAbout(actor) = {}
;

modify Actor
    verDoKiss(actor) = {
        "I doubt <<self.thedesc>> would like that. ";
    }
    checkAskAbout(i) = {
        actorOuthideStatus = outhide(true); // Don't let the player see this
        self.verDoAskAbout(Me);
        if (outhide(actorOuthideStatus)) {
            self.verDoAskAbout(Me);
        }
        else self.doAskAbout(Me, i);
    }
    verDoTellAbout(actor, io) = {
        self.verDoAskAbout(actor);
    }
;

modify conversationPiece
    location = doghouse            // For askabout to work
    verIoAskAbout(actor, dobj) = {}
;

// Put a flag in verbs which require you to touch the item
modify digVerb
    touch = true;
modify pushVerb
    touch = true;
modify attachVerb
    touch = true;
modify wearVerb
    touch = true;
modify dropVerb
    touch = true;
modify removeVerb
    touch = true;
modify openVerb
    touch = true;
modify closeVerb
    touch = true;
modify putVerb
    touch = true;
modify takeVerb
    touch = true;
modify plugVerb
    touch = true;
modify screwVerb
    touch = true;
modify unscrewVerb
    touch = true;
modify turnVerb
    touch = true;
modify switchVerb
    touch = true;
modify flipVerb
    touch = true;
modify turnOnVerb
    touch = true;
modify turnOffVerb
    touch = true;
modify sitVerb
    touch = true;
modify lieVerb
    touch = true;
modify breakVerb
    touch = true;
modify attackVerb
    touch = true;
modify climbVerb
    touch = true;
modify eatVerb
    touch = true;
modify drinkVerb
    touch = true;
modify giveVerb
    touch = true;
modify pullVerb
    touch = true;
modify throwVerb
    touch = true;
modify standOnVerb
    touch = true;
modify showVerb
    touch = true;
modify cleanVerb
    touch = true;
modify moveVerb
    touch = true;
modify fastenVerb
    touch = true;
modify unfastenVerb
    touch = true;
modify unplugVerb
    touch = true;
modify typeVerb
    touch = true;
modify lockVerb
    touch = true;
modify unlockVerb
    touch = true;
modify detachVerb
    touch = true;
modify pokeVerb
    touch = true;
modify touchVerb
    touch = true;
modify centerVerb
    touch = true;
modify searchVerb
    touch = true;

/*
    Dog, an actor from _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: dog.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

dog: Actor
    name = ''
    isSitting = nil
    isLying = nil
    isCurled = nil
    isRoaming = nil
    isWaiting = nil
    isPaused = nil        // True if the player's @ the beach (eggs.t)
    cameFromPurple2 = nil // From hospital.t
    age = 0
    namedAge = 'puppy'
    clearProps = {
        self.isSitting = self.isLying = self.isCurled = self.isRoaming
            = self.isWaiting = nil;
        self.actionTurn = global.turnsofar + 2 + RAND(2);
    }
    givenPoints = nil    // True if we've given points for getting vial
    actionTurn = -1
    noun = 'dog' 'corgi' 'puppy' 'pet'
    adjective = 'welsh' 'young' 'older' 'old'
    sdesc = {
        if (self.name == '')
            say(self.namedAge);
        else self.namedesc;
    }
    thedesc = {
        if (global.disambiguating)
            "the <<self.namedAge>>";
        else if (self.name != '')
            "\^<<self.name>>";
        else "the <<self.namedAge>>";
    }
    adesc = {
        if (self.name != '')
            "\^<<self.name>>";
        else "a<<self.namedAge == 'older dog' || self.namedAge == 'old dog' ?
            "n" : "">> <<self.namedAge>>";
    }
    namedesc = { "\^<<self.name>>"; }
    capdesc = { "\^<<self.thedesc>>"; }
    ldesc = {
        "<<self.capdesc>> resembles a corgi. In fact, it looks like the corgi
            you begged your father for when you were eight. ";
        if (self.age == 0)
            "It walks around on short legs, very much a young puppy. ";
        else if (self.age == 1)
            "It has recently grown out of early puppyhood. ";
        else if (self.age == 3)
            "It is beginning to grey around the muzzle. ";
        else if (self.age == 4)
            "Its fur is shot through with grey; its eyes are rheumy. ";
        if (rope.tiedTo == self) "A rope is tied about its neck. ";
        if (rucksack.location == self)
            "It is wearing the rucksack. ";
    }
    actorDesc = {
        "<<self.capdesc>> is ";
        if (self.isSitting) "sitting, watching you intently. ";
        else if (self.isLying) {
            "lying on the ground";
            if (!(ash_laurel.isworn && ash_laurel.dippedInBlood))
                ", staring at you with soulful eyes";
            ". ";
        }
        else if (self.isCurled) "curled in a small ball, resting. ";
        else if (self.isWaiting) "lying on the ground, waiting for you. ";
        else "wandering around, sniffing at things. ";
    }
    takedesc = "<<self.capdesc>> gives you a sidelong look. As your hands
        close around the dog, it swirls like smoke, solidifying just out of
        your reach. "
    frankiedesc = "Frankie shrugs. \"You've got me.\" "
    verGrab(item) = {}
    verDoAskAbout(actor) = { "<<self.capdesc>> makes no reply. "; }
    ioGiveTo(actor, dobj) = {
        if (dobj != rucksack)
            "<<self.capdesc>> has no real way of taking that. ";
        else if (rucksack.location == self)
            "<<self.capdesc>> already has that. ";
        else {
            "You place the rucksack on the ground next to <<self.thedesc>>.
                The dog proceeds to wriggle under the rucksack, then stand. ";
            dobj.moveInto(self);
            rucksackAh.see;
        }
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        local obj;
        
        if (dobj == rucksack)
            "<<self.capdesc>> leaps off the ground, barking in excitement. ";
        else if (dobj == crate_gap) {
            "<<self.capdesc>> looks at you for a moment, then begins
                wiggling into the space between crates. Shortly after
                its tail has vanished into the space ";
            if (length(contlist(dobj)) > 0) {
                obj = contlist(dobj)[1];
                "you hear excited barking, followed by the reemergence
                    of <<self.thedesc>>. <<self.capdesc>> then trots to
                    you and drops <<obj.thedesc>> at your feet. ";
                obj.moveInto(self.location);
                if (obj == novocaine) {
                    notify(hospitalMessages, &summonMessage, 2);
                    if (!self.givenPoints) {
                        self.givenPoints = true;
                        incscore(7);
                    }
                    vialAh.solve;
               }
            }
            else "<<self.thedesc>> returns, sneezing from the dust. ";
        }
        else "<<self.capdesc>> looks at you quizically, head cocked
            to one side. ";
    }
    ioSynonym('GiveTo') = 'PutOn'
    verDoKick(actor) = {
        if (ash_laurel.isworn && ash_laurel.dippedInBlood)
            "<<self.capdesc>> somehow dodges your kick, then looks around,
                sniffing mightily. ";
        else "<<self.capdesc>> dodges nimbly out of the way, then stares at
            you with narrowed eyes. ";
    }
    doSynonym('Kick') = 'Attack'
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "You grab the knife and take a swing at <<self.thedesc>>. The dog
            jumps back, but not fast enough to avoid the knife. You score a
            line along the dog's haunch. <<self.capdesc>> gives you
            a pained look before imploding with a pop. ";
        self.moveInto(nil);
        self.wantheartbeat = nil;
    }
    verIoCutIn(actor) = {
        if (pocketknife.location != actor)
            "You have nothing to cut with. ";
        else if (!pocketknife.isopen)
            "The pocketknife isn't open. ";
    }
    ioCutIn(actor, dobj) = {
        self.doCutWith(actor, dobj);
    }
    verDoAskFor(actor, io) = {
        if (io.location != self)
            "<<self.capdesc>> doesn't have <<io.thedesc>>. ";
    }
    doAskFor(actor, io) = {
        "<<self.capdesc>> wriggles out from under <<io.thedesc>>. Bemused,
            you pick it up. ";
        io.moveInto(actor);
    }
    verDoName(actor) = {
        if (self.name != '')
            "The dog already has a name:\ <<self.namedesc>>. ";
        else if (nameVerb.name == '')
            "You may name something by using NAME OBJECT \"NEWNAME\". ";
    }
    doName(actor) = {
        local word, i;
        
        while ((i = find(nameVerb.name, ' ')) != nil) {
            word = upper(substr(nameVerb.name, 1, 1)) +
                substr(nameVerb.name, 2, i-2);
            addword(self, &adjective, lower(word));
            self.name += word + ' ';
            nameVerb.name = substr(nameVerb.name, i+1, length(nameVerb.name));
        }
        self.name += upper(substr(nameVerb.name, 1, 1));
        if ((i = length(nameVerb.name)) > 1)
            self.name += substr(nameVerb.name, 2, i);
        addword(self, &noun, nameVerb.name);
        "You call to the dog. \"<<self.namedesc>>! C'mere, <<
            self.namedesc>>!\" The dog cocks its head at you, then trots over
            to you, panting happily. ";
    }
    verDoPet(actor) = {
        "You pet <<self.thedesc>>, whose tail wags mightily in response. ";
    }
    verDoSqueeze(actor) = { "You give <<self.thedesc>> a tight hug. "; }
    verIoTieTo(actor) = {}
    ioTieTo(actor, dobj) = {
        if (dobj == rope) {
            dobj.doTieTo(actor, self);
            "<<self.capdesc>> wriggles a bit, but submits to being
                leashed. ";
        }
        else "%You% can't tie <<dobj.thedesc>> to <<self.thedesc>>. ";
    }

// Movement handlers
    moveInto(loc) = {
        self.isSitting = nil;
        self.isLying = nil;
        self.isCurled = nil;
        pass moveInto;
    }
    actorAction(v, d, p, i) = {
        local obj;
        
        if (v==giveVerb && i==Me && p==toPrep) {
            actorOuthideStatus = outhide(true);
            self.verDoAskFor(Me, d);
            if (outhide(actorOuthideStatus)) {
                self.verDoAskFor(Me, d);
                exit;
            }
            self.doAskFor(Me, d);
            exit;
        }
        if (v == followVerb && d == Me)
            v = heelVerb;
        switch(v) {
            case helloVerb:
                "\"Bark! Bark!\" ";
                break;
            case sitVerb:
                if (self.isSitting)
                    self.imAheadOfYou('sitting');
                else {
                    "<<self.capdesc>> obediently sits. ";
                    self.isSitting = true;
                    self.isLying = nil;
                }
                break;
            case stayVerb:
                if (self.isLying)
                    self.imAheadOfYou('lying down');
                else {
                    "<<self.capdesc>> lies down, watching you carefully. ";
                    self.isLying = true;
                    self.isSitting = nil;
                }
                break;
            case heelVerb:
                if (!self.isSitting && !self.isLying)
                    self.imAheadOfYou('following you');
                else {
                    self.capdesc;
                    if (self.isSitting || self.isLying || self.isCurled)
                        " gets up and";
                    " trots over to you. ";
                    self.isSitting = nil;
                    self.isLying = nil;
                    self.isCurled = nil;
                }
                break;
            case attackVerb:
                if (d == bully) {
                    "<<self.capdesc>> looks at you, then at the boy carving
                        his initials in the tree. Lips pull back from teeth,
                        a growl begins deep in the throat; <<self.thedesc
                        >> leaps at the boy.\b";
                    if (bully.daemonNumber == 13) {
                        "The boy, though, has finished carving the oak tree.
                            He has time to turn, time to raise his knife and
                            bury it in the dog's skull.\b
                            A void rips open where <<self.capdesc>> was. The
                            boy looks remarkably surprised to be dragged
                            arm-first into the growing nothingness. You have
                            a moment to savor the fact that he was swallowed
                            first before you fall into the consuming blackness.
                            \bWhen you next open your eyes, it is to a sterile
                            hospital room. You cannot keep your eyes open for
                            long before you sink back into a deep sleep. ";
                        die();
                    }
                    "Surprised, the boy turns just enough for <<self.thedesc
                        >> to bury teeth in his arm. \"AaaaaAAAA!\"\ he
                        shrieks, dropping his knife. He shakes his arm, but <<
                        self.thedesc>> hangs on tenaciously.\b
                        Finally, the dog lets go and drops to the forest floor.
                        The boy grabs his arm, blood dripping around his hand.
                        He stares at you, white rimming the pupils of his eyes.
                        \"You!\"\ he says. He staggers back. \"You!\"\ he
                        repeats, before turning and running through the forest.
                        \b<<self.capdesc>> turns to you and grins, tongue
                        hanging from its mouth. ";
                    bully.moveInto(limbo);
                    pocketknife.moveInto(ne_forest);
                    oak_tree.moveInto(nil);
                    oak_tree_actor.moveInto(ne_forest);
                    oak_tree_actor.initials = oak_tree.initials;
                    oak_tree_actor.secondInitials = oak_tree.secondInitials;
                    if (oak_tree == rope.tiedTo)
                        rope.tiedTo = oak_tree_actor;
                    ash_tree.moveInto(nil);
                    ash_tree_actor.moveInto(ne_forest);
                    if (ash_tree == rope.tiedTo)
                        rope.tiedTo = ash_tree_actor;
                    notify(oak_tree_actor, &firstTalk, 2);
                    carvingAh.solve;
                    incscore(5);
                }
                else if (d == grey_man) {
                    if (Me.location == top_of_hill) {
                        "He lashes out smoothly with one foot, catching <<
                            dog.thedesc>> by surprise. <<dog.capdesc
                            >> yipes and runs. ";
                        dog.moveInto(doghouse);
                        dog.clearProps;
                        dog.wantheartbeat = nil;
                    }
                    else {
                        "The grey man stares at <<self.thedesc>>, who
                            hunkers down and stares back, eyes rimned
                            in white, before slinking back a step or two. ";
                    }
                }
                else "<<self.capdesc>> stares at you for a second, then
                    snorts. ";
                break;
            case inVerb:
            case searchVerb:
                if (d == crate_gap) {
                    "<<self.capdesc>> looks at you for a moment, then begins
                        wiggling into the space between crates. Shortly after
                        its tail has vanished into the space ";
                    if (length(contlist(d)) > 0) {
                        obj = contlist(d)[1];
                        "you hear excited barking, followed by the reemergence
                            of <<self.thedesc>>. <<self.capdesc>> then trots to
                            you and drops <<obj.thedesc>> at your feet. ";
                        obj.moveInto(self.location);
                        if (obj == novocaine) {
                            notify(hospitalMessages, &summonMessage, 2);
                            if (!self.givenPoints) {
                                self.givenPoints = true;
                                incscore(7);
                            }
                            vialAh.solve;
                        }
                    }
                    else "<<self.thedesc>> returns, sneezing from the dust. ";
                }
                else "<<self.capdesc>> looks at you quizically, head cocked
                    to one side. ";
                break;
            case takeVerb:
                if (!d.isfixed && uberloc(d) == self.location) {
                    if (d.location == crate_gap) {
                        "<<self.capdesc>> looks at you for a moment, then
                            begins wiggling into the space between crates.
                            Shortly after its tail has vanished into the
                            space you hear excited barking, followed by
                            the reemergence of <<self.thedesc>>. <<
                            self.capdesc>> then trots to you and drops <<
                            d.thedesc>> at your feet. ";
                        d.moveInto(self.location);
                        if (d == novocaine) { // Give a message
                            notify(hospitalMessages, &summonMessage, 2);
                            if (!self.givenPoints) {
                                self.givenPoints = true;
                                incscore(7);
                            }
                            vialAh.solve;
                        }
                    }
                    else "<<self.capdesc>> gazes pointedly
                        at your arms and legs before looking away. ";
                    break;
                }
            default:
                "<<self.capdesc>> looks at you quizically, head cocked
                    to one side. ";
        }
        exit;
    }
    imAheadOfYou(str) = {
        "<<self.capdesc>> looks at you with a disgusted expression.
            Sheepishly, you realize that <<self.thedesc>> is already
            <<str>>. ";
    }
    wantheartbeat = nil
    heartbeat = {
        local meLoc = uberloc(Me), selfLoc = uberloc(self), locFlag =
            (meLoc == selfLoc);

        // Don't do anything if we're paused
        if (self.isPaused) {
            self.actionTurn++;        // Delay the turn during which we act
            return;
        }

        if (self.isLying) {
            if (RAND(100) < 10 && locFlag)
                "\b<<self.capdesc>>'s tail hits the ground softly. ";
            return;
        }
        if (!locFlag && self.isRoaming == nil) {
        // if noDogWander is true, the closedIn condition only means "don't
        //  wander back into the room," not "don't follow the player."
            if (self.closedIn && !meLoc.noDogWander) {
                self.isLying = true;
                return;
            }
            self.moveInto(meLoc);
            if (rope.tiedTo == self) {
                if (rope.location == Me) {
                    "\b<<self.capdesc>> is dragged behind you.\n";
                    self.checkIntern;
                    return;
                }
                else rope.moveInto(self.location);
            }
            "\b<<self.capdesc>> comes trotting after you.\n";
            self.checkIntern;
            return;
        }
        if (self.actionTurn <= global.turnsofar && locFlag) {
            "\b<<self.capdesc>> ";
            if (eileen.location == self.location && RAND(100) > 50)
                "barks at <<eileen.thedesc>>. She glances down at the dog, her
                    mouth quirking into a smile. ";
            else if (attendant.location == self.location && RAND(100) > 20)
                "growls softly, baring teeth at <<attendant.thedesc>>. \^<<
                    attendant.thedesc>> glares back at
                    the dog. \"Don't you let that mutt bite me,\" she tells
                    you. ";
            else switch (RAND(4)) {
                case 1:
                default:
                    "comes over, sniffs at your legs, then
                        wanders off again. ";
                    break;
                case 2:
                    "takes a running fit, tearing around as ";
                    if (rope.tiedTo == self && rope.location == Me)
                        "much as possible while leashed. ";
                    else "fast as possible on short legs. ";
                    break;
                case 3:
                    if (!self.isCurled) {
                        "curls up in a small ball, resting. ";
                        self.isCurled = true;
                        return;
                    }
                    // If we're already curled up, try wandering
                case 4:
                    self.clearProps;
                    if (rope.tiedTo == self && rope.location == Me) {
                        "strains at the rope, then stares back at you. ";
                        break;
                    }
                    else if (self.closedIn && !self.location.dogCanLeave) {
                        "wanders around, looking for an exit. ";
                        break;
                    }
                    "wanders away. ";
                    self.moveInto(doghouse);
                    if (rope.tiedTo == self) rope.moveInto(doghouse);
                    self.isRoaming = global.turnsofar + 2 + RAND(2);
                    break;
            }
            self.isCurled = nil;
            self.actionTurn = global.turnsofar + 4 + RAND(4);
            return;
        }
        if (self.isRoaming != nil && self.isRoaming <= global.turnsofar) {
            if (self.closedIn) return;    // Dog can't enter
            "\b<<self.capdesc>> comes running toward you, barking loudly. 
                Upon ";
            if (ash_laurel.isworn && ash_laurel.dippedInBlood)
                "smelling";
            else "seeing";
            " you, however, <<self.thedesc>> calms down and
                trots nonchalantly up to you. ";
            self.moveInto(meLoc);
            self.isRoaming = nil;
            if (rope.tiedTo == self)
                rope.moveInto(meLoc);
            return;
        }
    }
    // If the player is in an inaccessible location, the room should
    closedIn = {    //  return TRUE in its noDog routine
        if ((Me.location == purple3 || Me.location == purple1) &&
            (self.location == admitting))
            return nil;
        if (proptype(Me.location, &noDog) == 8 ||
            (proptype(Me.location, &noDog) == 6 && Me.location.noDog))
            return true;
        return nil;
    }
    checkIntern = {    // Did the dog just enter purple3 or purple1?
        local dir;
        
        if (self.location != purple3 && self.location != purple1) return;
        if (self.cameFromPurple2) {
            self.cameFromPurple2 = nil;
            return;
        }
        dogToVialAh.see;
        if (self.location == purple3)
            dir = 'north';
        else dir = 'south';
        "\bA faceless man in blue scrubs appears from further down the hall.
            He starts to walk past, then pulls up short next to <<
            self.thedesc>>. ";
        if (rope.tiedTo == self && rope.location == Me) {
            if (sunglasses.isworn && cane.location == Me) {
                "He looks as if he is about to take action, but then he
                    notices your sunglasses and cane. Realizing what has
                    happened, you inspiredly begin tapping the cane on the
                    ground. The man, satisfied, continues on his way. ";
                dogToVialAh.solve;
                return;
            }
            if (cane.location == Me)
                "He notices the cane and glances at the dog's impromptu
                    leash. He then waves a hand in front of your face.
                    Startled, you jerk back. The man nods, taking the rope
                    from your hands and ushering <<self.thedesc>> to the
                    <<dir>>. ";
            else if (sunglasses.isworn)
                "He notices the sunglasses and glances at the dog's impromptu
                    leash. You can imagine his suspicion at seeing a Welsh
                    Corgi as a guide dog.\b
                    Apparently unconvinced by your disguise, he makes up his
                    mind, bending down to usher <<
                    self.thedesc>> <<dir>> over your protests. He takes
                    the rope from your hands and is gone with <<
                    self.thedesc>>. ";
            else "He turns his head towards you, then gently takes the rope
                from your hands and ushers <<self.thedesc>> to the <<dir>>.";
        }
        else "He turns his head towards you, then ushers <<self.thedesc>> to
            the <<dir>>. ";
        self.moveInto(admitting);
        if (rope.tiedTo == self)
            rope.moveInto(admitting);
        self.isLying = true;
    }
;

// The dead dog, for finale.t
dead_dog: fixedItem
    name = ''
    noun = 'dog' 'corgi' 'puppy'
    adjective = 'welsh' 'old'
    sdesc = {
        if (self.name == '')
            "old dog";
        else self.namedesc;
    }
    thedesc = {
        if (self.name != '')
            "\^<<self.name>>";
        else "the old dog";
    }
    adesc = {
        if (self.name != '')
            "\^<<self.name>>";
        else "an old dog";
    }
    namedesc = { "\^<<self.name>>"; }
    capdesc = { "\^<<self.thedesc>>"; }
    ldesc = {
        "<<self.capdesc>> has collapsed on the ground, its once-grey muzzle
            now dyed red. ";
    }
    actorDesc = {
        "<<self.capdesc>> lies in a broken heap on the ground. ";
    }
    takedesc = "You cannot bring yourself to. "
    touchdesc = "<<self.capdesc>> is still warm. "
    setup = {
        self.name = dog.name;
        if (self.name != '')
            addword(self, &noun, self.name);
        self.moveInto(dog.location);
        dog.moveInto(doghouse);
        dog.wantheartbeat = nil;
    }
;

// A place for the dog to stay when he/she goes wandering. This way, if the
//  dog's location is nil, we know the dog never was summoned
doghouse: thing
;

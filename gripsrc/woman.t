/*
    The old woman in the wheelchair, part of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: woman.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

old_woman: Actor, rollItem
    askDisambig = true
    selfDisambig = true
    isHer = true
    askme = &womandesc
    noAlreadyTold = true
    turnsSinceRolled = 0
    isAsleep = nil

    tellStory = {
        "\b";
        if (self.isAsleep) {
            self.wakeUp;
            return;
        }
        switch(RAND(4)) {
            case 1:
            "The old woman in the wheelchair rolls up to you. \"You know,
            seeing you reminds me of when John and I went to Paris. Have you
            ever been to Paris?\"\ she asks.";
            qDaemon.questionAsked('"Ooh, I\'m so glad!"\ she replies.',
                '"Pity,"\ the woman says.',
                'The old woman stares at you, then shrugs minutely.');
            break;

            case 2:
            "The old woman rolls her wheelchair forward for a minute, staring
            off into space, then rolls back.";
            break;

            case 3:
            "From behind you, you hear humming. Surprised, you turn around
            to see the old woman humming \"Amazing Grace\" to herself. When
            she notices your scrutiny she stops, her cheeks coloring
            slightly.";
            break;

            case 4:
            "Slowly, ever so slowly, the old woman's chin nods towards her
            chest. Shortly after the chin has completed its journey, soft
            snores begin floating from her.";
            self.isAsleep = true;
            break;
        }
        "\n";
    }
    wakeUp = {
        "With a start, the old woman wakes up. \"Yes? Yes?\"\ she asks
            querulously. ";
        self.isAsleep = nil;
    }

    noun = 'woman' 'wheelchair' 'chair' 'herself'
    adjective = 'old'
    location = green4
    sdesc = "old woman"
    stringsdesc = 'The old woman'
    thedesc = "the old woman"
    adesc = "an old woman"
    ldesc = {
        "The woman in the wheelchair is ancient, her parchment skin deeply
            wrinkled and folded. ";
        if (!self.isAsleep)
            "Alert eyes peer from behind large octagonal
                glasses, eyes which follow every movement in the room. ";
        else "Large octagonal glasses cover her closed eyes. ";
    }
    actorDesc = {
        if (!self.isAsleep)
            "Seated in a wheelchair is an old woman. ";
        else "Slumped in a wheelchair, asleep, is an old woman. ";
    }
    takedesc = "How rude!"
    movedesc(dir) = {
        "You wheel the old woman to the <<dir>>";
        if (self.isAsleep) {
            "; as you do, she wakes up with a jerk";
            self.isAsleep = nil;
        }
        if (attendant.shownPass && Me.location == attendant.location) {
            ". \^<<attendant.thedesc>> watches you until you are out of sight";
        }
        ".\b";
        self.turnsSinceRolled = 0;      // Reset our movement counter
    }
    touchdesc = {
        if (self.isAsleep) "The old woman snorts as you touch her, almost
            waking up. ";
        else "The old woman waves you away. \"Now just who are you to be
            fiddlin' with me?\"\ she asks.";
    }
    listendesc = {
        if (self.isAsleep) "You hear quiet snoring. ";
        else "The old woman giggles when she notices you listening to her. ";
    }
    womandesc = 'Me? Oh, my, no sense in boring you to tears!'
    greymandesc = 'Pitiful, isn\'t she?'
    eileendesc = 'Is she out again?" Eileen sighs heavily, tapping one hand
        against her thigh. "She\'ll have to be taken back to her room.'
    actorAction(v, d, p, i) = {
        if (self.isAsleep) {
            self.wakeUp;
            exit;
        }
        if (v == helloVerb) {
            "\"Oh, hello!\"\ she says excitedly. Then a look of puzzled
                concentration crosses her face. \"Have we met before?\"\ she
                asks. ";
            exit;
        }
        pass actorAction;
    }
    disavow = "The woman says, \"Oh, dear, I really can't help you with
        that.\" "
    verDoAskFor(actor, io) = {}
    doAskFor(actor, io) = {
        if (self.isAsleep) {
            self.wakeUp;
            exit;
        }
        "\"Now I don't have that!\"\ she says. ";
    }
    verDoAskAbout(actor) = {}
    doAskAbout(actor, io) = {
        if (self.isAsleep) {
            self.wakeUp;
            exit;
        }
        pass doAskAbout;
    }
    verIoGiveTo(actor) = {}
    ioGiveTo(actor, dobj) = {
        if (self.isAsleep)
            self.wakeUp;
        else "She waves you off. \"No, no, I don't need that,\" she says. ";
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (self.isAsleep)
            self.wakeUp;
        else "\"Oh, my, you know, my eyesight isn't what it once was,\" the
            woman tells you happily. ";
    }
    verDoKick(actor) = {"You would only bruise your toe on the wheelchair. ";}
    verDoKiss(actor) = {
        "The woman beams. \"That's nice, dear,\" she says. She frowns. \"Do I
            know you?\" ";
    }
    verDoMoveN(actor) = {
        if (self.location == purple3)
            "The stairs prevent you. ";
        else if (self.location == green1) {
            self.goTo = self.location.north;
            return;
        }
        else if (self.location == admitting && !attendant.shownPass) {
            "\^<<attendant.thedesc>> looks at you in disbelief as you roll the
                old woman to the north. \"Hold up there!\"\ she yells at you.
                Her voice strikes responsive chords:\ you freeze, then return
                to her desk. She smirks at you. \"Just because you work
                here doesn't mean you can wheel patients around without
                permission. Now you just turn your happy butt back around.\"
                Knowing her temper, you comply. ";
            lindaAh.see;
            return;
        }
        else pass verDoMoveN;
    }
    verDoMoveS(actor) = {
        if (self.location == purple2)
            "The stairs prevent you. ";
        else if (self.location == green3) {
            self.goTo = self.location.south;
            return;
        }
        else pass verDoMoveS;
    }
    verDoMoveE(actor) = {
        if (self.location == green2) {
            self.goTo = self.location.east;
            return;
        }
        else pass verDoMoveE;
    }
    wantheartbeat = nil
    heartbeat = {
        self.turnsSinceRolled++;
        if (self.turnsSinceRolled < 3 + RAND(3)) {
            if (RAND(100) < 15 && Me.location == self.location)
                self.tellStory;
            return;
        }
        if (self.location.womanDir == nil ||
            !self.check_dir(self.location.womanDest)) { // Can we move here?
            self.turnsSinceRolled = 0;                  // Guess not
            return;
        }
        if (uberloc(self) == uberloc(Me)) {
            "\b";
            if (self.isAsleep)
                "The old woman's light snores cease as she awakens. ";
            switch(RAND(3)) {
            case 1:
                "The old woman suddenly says, \"Kenny! Kenny!\" ";
                break;
            case 2:
                "\"I wonder where my son got off to,\" says the old woman. ";
                break;
            case 3:
                "The old woman begins humming to herself. ";
                break;
            }
            "She rolls to the <<self.location.womanDir>>";
            if (other_dxdoors.location == self.location)
                ", slowing only to force open the double doors with her
                    wheelchair";
            ". ";
            self.isAsleep = nil;
        }
        self.moveInto(self.goTo);
        if (uberloc(self) == uberloc(Me))
            "\bThe old woman rolls her wheelchair into the room. ";
        self.turnsSinceRolled = 0;
    }
;

oldWomanCon1: conversationPiece
    noun = 'kenny' 'son'
    sdesc = "that"
    womandesc = {
        switch(RAND(4)) {
            case 1:
            "\"Kenny's comming to visit me today!\"\ she says excitedly.
                Then she pauses, her forhead wrinkling. She peers through her
                glasses at you. \"Have you seen Kenny?\"\ she asks you. ";
            qDaemon.questionAsked('"That\'s nice. I\'m sure Kenny will
                be here shortly."',
                '"Oh,"\ the woman says, slumping slightly.',
                'The old woman stares at you, then shrugs minutely.');
            break;

            case 2:
            "\"My son's visiting me for his birthday. Did you know that he'll
                be seven today?\" ";
            qDaemon.questionAsked('"Oh," she says, confused. "I wasn\'t sure
                I had mentioned it."',
                '"That\'s right, seven!"',
                'The old woman stares at you, then shrugs minutely.');
            break;

            case 3:
            "She says cheerfully, \"I'm waiting for him! He's visiting with
                his wife!\" She peers at you, takes off her glasses and
                cleans them, the replaces them and stares at you some more.
                \"Are you with them?\"\ she asks you. ";
            qDaemon.questionAsked('"Well, go get them!"\ she says.',
                'The woman sighs once. "I thought not."',
                'The old woman stares at you, then shrugs minutely.');
            break;

            case 4:
            "\"Have you seen him?\"\ she asks you excitedly. \"He's getting
                married soon, you know,\" she adds in a conspiratorial
                whisper. ";
            break;
        }
    }
;

oldWomanCon2: conversationPiece
    noun = 'john' 'husband'
    sdesc = "that"
    womandesc = 'Have you seen John?" Her eyes light up. "He\'s been on a
        business trip.'
;

oldWomanCon3: conversationPiece
    noun = 'paris' 'france'
    sdesc = "that"
    womandesc = "\"I've been to Paris!\"\ she tells you excitedly. \"You
        must go and see it some time.  It's lovely!\" "
;

wheelchair: fixedItem
    noun = 'chair' 'wheelchair'
    sdesc = "wheelchair"
    ldesc = "Its seat is slightly bowed, as if someone were still sitting
        there. "
    takedesc = "You try to lift it, but find it improbably heavy. "
    verDoPush(actor) = { "It doesn't move. One of the wheels is frozen in
        place. "; }
    doSynonym('Push') = 'Move' 'MoveN' 'MoveS' 'MoveE' 'MoveW' 'MoveNE' 'MoveNW' 'MoveSE' 'MoveSW'
;

sick_woman: fixedItem
    stage = '2a'
    askDisambig = true
    isHer = true
    hookedUp = nil            // Am I attached to the ECG machine?
    johnCounter = 0           // For delaying Dr. John's actions

    noun = 'woman'
    adjective = 'old'
    sdesc = "old woman"
    thedesc = "the old woman"
    adesc = "an old woman"
    ldesc = {
        "The woman is ancient, her waxy skin draped loosely about her. ";
    }
    heredesc = "The old woman lies carelessly on
        the <<sick_woman_gurney.location == womans_room ? "gurney" :
        "bed">>. "
    takedesc = "You strain and strain, but cannot lift her. "
    touchdesc = "She feels cold. "
    listendesc = "You cannot hear her breathing. "
    
    verDoPush(actor) = {
        compressions.verDoBegin(actor);
    }
    doPush(actor) = {
        compressions.doBegin(actor);
    }
    
    // Myocardial infarction
    mi1 = {
        if (uberloc(Me) != self.location) return;
        "\bA doctor, notable for his unmissing face, walks by the door. He is
            back in seconds, striding into the room. Leaning over the old
            woman, he shakes her. \"I'm Doctor John; can you hear me? Ma'am?\"
            Her lack of
            response prompts him to lean out into the hall and shout: \"Woman
            down, unresponsive; crash cart to Orange 7.\" He returns to the
            woman, placing two fingers to her
            throat and a palm to her forehead. He tilts her head back,
            extending her neck, and huffs twice into her mouth. He then
            motions. \"You.\" He nods at the woman's
            chest. \"Begin compressions.\" ";
        precise_doctor.moveInto(womans_room);
        precise_doctor.breathing = true;
        notify(self, &mi2, 2);
    }
    mi2 = {
        if (uberloc(Me) != self.location) return;
        if (!Me.doingCPR) {
            "\bThe doctor glances at you, then begins pressing on the woman's
                chest. \"You.\" He motions you away with his head. \"Get
                out.\" ";
            precise_doctor.doingCPR = true;
            notify(self, &pushAway, 1);
            return;
        }
        "\bYou have slipped into a once-familiar rhythm:\ five compressions,
            then the doctor breathes, then five compressions. ";
        notify(self, &mi3, 1);
    }
    mi3 = {
        if (uberloc(Me) != self.location) return;
        "\bA gang of white-garbed doctors, all of whom lack faces, pour into
            the room. Several of them slide away from the door, revealing the
            gurney and crash cart they have brought with them.\b
            Dr.\ John nods at them and their cargo. He waves you away from
            the old woman and motions the others closer. \"On my mark:\ one,
            two, three,\" and they have lifted the woman up and onto the
            gurney. ";
        Me.moveInto(womans_room);
        Me.doingCPR = nil;
        precise_doctor.breathing = precise_doctor.doingCPR = nil;
        precise_doctor.preppingWoman = true;
        other_doctors.moveInto(womans_room);
        sick_woman_gurney.moveInto(womans_room);
        crash_cart.moveInto(womans_room);
        notify(self, &mi4, 1);
    }
    mi4 = {
        if (uberloc(Me) != self.location) return;
        "\bDr.\ John nods at the ECG readout. \"She's in VFib.\" He snatches
            up the defibrillator paddles and says to you, \"Charge to 200.\" ";
        precise_doctor.preppingWoman = nil;
        precise_doctor.holdingPaddles = true;
        defib_dial.requestedSetting = 200;
        notify(self, &mi5, 0);
    }
    mi5 = {
        if (defib_dial.setting != defib_dial.requestedSetting &&
            self.johnCounter != 5) {
            self.johnCounter++;
            return;
        }
        unnotify(self, &mi5);
        self.johnCounter = 0;
        if (uberloc(Me) != self.location)
            return;
        "\b\"Clear!\" A push of buttons; the woman's body arcs and
            recollapses. Dr.\ John rubs the paddles together, smearing paste,
            while he glances at the ECG. \"Give me";
        if (defib_dial.setting != 200) {
            "--what?\" His eyebrows swoop down. \"<<defib_dial.setting>>?\"
                He gestures at you with the paddles. \"Out.\" Two of the
                faceless doctors escort you ";
            if (dog.location == womans_room) {
                "and <<dog.thedesc>> ";
                dog.moveInto(orange5);
            }
            "through the door. ";
            Me.travelTo(orange5);
            small_h_womans_door.isopen = nil;
            small_h_womans_door.islocked = true;
            return;
        }
        " 260.\" ";
        defib_dial.requestedSetting = 260;
        notify(self, &mi6, 0);
    }
    mi6 = {
        if (defib_dial.setting != defib_dial.requestedSetting &&
            self.johnCounter != 3) {
            self.johnCounter++;
            return;
        }
        unnotify(self, &mi6);
        self.johnCounter = 0;
        if (uberloc(Me) != self.location)
            return;
        "\bAgain Dr.\ John says, \"Clear!\" Again the woman's body leaps into
            the air. Dr.\ John takes another look at the ECG, saying, \"Give me";
        if (defib_dial.setting != 260) {
            "--what?\" His eyebrows swoop down. \"<<defib_dial.setting>>?\"
                He gestures at you with the paddles. \"Out.\" Two of the
                faceless doctors escort you ";
            if (dog.location == womans_room) {
                "and <<dog.thedesc>> ";
                dog.moveInto(orange5);
            }
            "through the door. ";
            Me.travelTo(orange5);
            small_h_womans_door.isopen = nil;
            small_h_womans_door.islocked = true;
            return;
        }
        " 360.\" ";
        defib_dial.requestedSetting = 360;
        notify(self, &mi7, 0);
    }
    mi7 = {
        if (defib_dial.setting != defib_dial.requestedSetting &&
            self.johnCounter != 3) {
            self.johnCounter++;
            return;
        }
        unnotify(self, &mi7);
        self.johnCounter = 0;
        if (uberloc(Me) != self.location)
            return;
        "\bThe woman's body jumps once more as Dr.\ John discharges his
            paddles. When he looks at the ECG this time, his brow furrows. ";
        if (defib_dial.setting != 360) {
            "\"<<defib_dial.setting>>.\"
                He gestures at you with the paddles. \"Out.\" Two of the
                faceless doctors escort you ";
            if (dog.location == womans_room) {
                "and <<dog.thedesc>> ";
                dog.moveInto(orange5);
            }
            "through the door. ";
            Me.travelTo(orange5);
            small_h_womans_door.isopen = nil;
            small_h_womans_door.islocked = true;
            return;
        }
        "\"PEA,\" he mutters. \"Intubate; give me a 1 mg epinephrine push.\"
            He resumes breathing for the woman while one of his faceless
            helpers performs chest compressions. ";
        precise_doctor.holdingPaddles = nil;
        precise_doctor.breathing = true;
        defib_dial.requestedSetting = 0;
        notify(self, &mi8, 1);
    }
    mi8 = {
        if (uberloc(Me) != self.location) return;
        "\bDr.\ John notices you during a pause between breaths. \"Thanks,\"
            he says. \"We have it under control.\" Breath. \"You can go.\"
            Then his attention is focussed on the woman. \"Pulse back,
            breathing again. 60 mg lidocaine.\" Two of the faceless doctors
            usher you";
        if (dog.location == womans_room) {
            " and <<dog.thedesc>>";
            dog.moveInto(orange5);
        }
        ", not unkindly, through the door. ";
        Me.travelTo(orange5);
        small_h_womans_door.isopen = nil;
        small_h_womans_door.islocked = true;
        notify(self, &mi9, 1);
    }
    mi9 = {
        if (!Me.location.isHospitalHall) return;
        "\bYou glance up to see Dr.\ John standing beside you, a smile tugging
            at one side of his mouth. He begins to speak; stops; walks a few
            steps; stops. \"Nice. Good response time. She'll be fine,\" he
            tells you before continuing down the hall. ";
    }
    pushAway = {
        if (uberloc(Me) != self.location) return;
        "\bA clatter at the door catches your attention. Faceless people
            garbed in white enter, wheeling a gurney and a cart. The doctor
            furrows his brow at the interns; one of them peels off and brushes
            you ";
        if (dog.location == womans_room) {
            "and <<dog.thedesc>> ";
            dog.moveInto(orange5);
        }
        "out of the room.\b";
        Me.travelTo(orange5);
        small_h_womans_door.isopen = nil;
        small_h_womans_door.islocked = true;
    }
;

precise_doctor: Actor
    stage = '2a'
    isHim = true
    breathing = nil
    doingCPR = nil
    preppingWoman = nil
    holdingPaddles = nil
    
    noun = 'doctor' 'john'
    adjective = 'single' 'doctor'
    sdesc = "Doctor John"
    ldesc = {
        "His face is scrunched in concentration, his thin glasses dangling
            from his ears. ";
        if (self.breathing)
            "He is hunched over the old woman, breathing for her. ";
        else if (self.doingCPR)
            "He is performing efficient CPR on the old woman. ";
        else if (self.holdingPaddles)
            "He is weilding the defibrillator paddles. ";
    }
    actorDesc = {
        if (self.breathing)
            "Doctor John bends over the old woman, breathing for both. ";
        else if (self.doingCPR)
            "Doctor John moves about the old woman, performing CPR. ";
        else if (self.preppingWoman)
            "Dr.\ John stands beside the woman, preparing the crash cart. ";
        else if (self.holdingPaddles)
            "Dr.\ John holds the defibrillator paddles to the old woman's
                chest. ";
        else "Dr.\ John stands nearby, polishing his glasses. ";
    }
    disavow = "He shakes his head, but does not reply. "
    alreadyTold = "He shakes his head, but does not reply. "
    verDoKick(actor) = "You move towards him, but you somehow get no closer
        than you already are. "
    doSynonym('Kick') = 'Kiss'
;

other_doctors: Actor
    stage = '2a'
    isThem = true
    noun = 'doctor' 'group'
    plural = 'doctors'
    adjective = 'group' 'faceless'
    sdesc = "the faceless doctors"
    ldesc = "They fill the room, moving about purposefully. "
    actorDesc = "A group of faceless doctors surround the gurney in the center
        of the room. "
    disavow = "They don't respond. "
    alreadyTold = "They don't respond. "
    verDoKick(actor) = {
        "Considering what they are doing, you would do well to leave them
            alone. ";
    }
    doSynonym('Kick') = 'Kiss'
;

sick_woman_gurney: decoration
    stage = '2a'
    noun = 'gurney'
    sdesc = "gurney"
    ldesc = "It stands, slab-like, in the center of the room. "
;

crash_cart: fixedItem, surface
    stage = '2a'
    noun = 'cart' 'medication'
    adjective = 'crash'
    isListed = true
    sdesc = "crash cart"
    ldesc = {
        local list = contlist(self);
        
        "The crash cart appears only when someone is in great distress. It
            contains plenty of medication, an ECG machine, ";
        if (syringe.location == self && !syringe.isListed)
            "a syringe, ";
        "and a defibrillator. ";
        if (length(list) > 0)
            "Also on the cart %you% see%s% <<listlist(list)>>. ";
    }
;

cc_ecg: decoration
    stage = '2a'
    noun = 'machine' 'ecg'
    adjective = 'ecg'
    location = crash_cart
    sdesc = "ECG machine"
    ldesc = {
        "For showing the electrical activity of the heart. ";
        if (sick_woman.hookedUp) "Its readout from the old woman is
            meaningless to you. ";
    }
;

defibrillator: fixedItem
    stage = '2a'
    noun = 'defibrillator'
    location = crash_cart
    sdesc = "defibrillator"
    ldesc = "You always found it ironic that shocking someone violently,
        normally a prescription for stopping the heart, is the only way known
        to restart the heart. Its dial, marked from 200 J to 400 J, currently
        points at <<defib_dial.setting>>. "
    doTurn -> defib_dial
    doTurnTo -> defib_dial
;

defib_dial: fixedItem
    stage = '2a'
    noun = 'dial'
    setting = 320          // the current setting
    requestedSetting = 0   // the setting Dr. John wants
    location = crash_cart
    sdesc = "dial"
    ldesc = {
        "The dial is marked from 200 J to 400 J. Currently it is set
            to <<self.setting>>. ";
    }
    verDoTurn(actor) = {}
    doTurn(actor) = {
        askio(toPrep);
    }
    verDoTurnTo(actor, io) = {}
    doTurnTo(actor, io) = {
        if (io == numObj) {
            if (numObj.value < 200 || numObj.value > 400) {
                "There's no such setting! ";
            }
            else if (numObj.value != self.setting) {
                self.setting = numObj.value;
                "The dial clicks as you turn it to <<self.setting>>. ";
            }
            else {
                "The dial is already set to <<self.setting>>. ";
            }
        }
        else {
            "I don't know how to turn the dial to that. ";
        }
    }
;

syringe: unlistedItem
    stage = '2a'
    notakeall = true
    firstMove = { self.notakeall = nil; incscore(7); pass firstMove; }
    isFull = nil            // Have I been filled w/Novocaine?
    noun = 'syringe' 'needle'
    weight = 4
    bulk = 8
    location = crash_cart
    sdesc = {
        if (self.isFull) "full ";
        "syringe";
    }
    ldesc = {
        "The syringe is graduated in cc's. ";
        if (self.isFull)
            "It is filled with a clear liquid. ";
    }
    verDoPutIn(actor, io) = {
        if (io == Me)
            "You'll have to be more specific about where you want to inject
                yourself. ";
        else if (!io.isBodypart && io != novocaine)
            "You refrain for fear of snapping off the end of the needle. ";
        else if (io == hands && gloves.isworn)
            "The gloves are too thick for the needle. ";
    }
    doPutIn(actor, io) = {
        if (io == novocaine) {
            io.ioPutIn(actor, self);
            return;
        }
        "You stick the syringe into <<io.thedesc>>";
        if (!self.isFull)
            "; however, lacking anything in the syringe, nothing happens.
                You withdraw the syringe. ";
        else {
            " and depress the plunger. A shock of cold runs through you
                as <<io.thedesc>> grows numb. ";
            io.numbed = true;
            self.isFull = nil;
        }
    }
    doSynonym('PutIn') = 'InjectIn'
    verIoInjectWith(actor) = {}
    ioInjectWith(actor, dobj) = {
        if (dobj == Me)
            "You'll have to be more specific about where you want to inject
                yourself. ";
        else if (!dobj.isBodypart && dobj != novocaine)
            "You refrain for fear of snapping off the end of the needle. ";
        else self.doPutIn(actor, dobj);
    }
;

compressions: intangible
    stage = 0
    noun = 'compressions'
    location = womans_room
    sdesc = "compressions"
    ldesc = "You cannot examine compressions. "
    verDoBegin(actor) = {
        if (actor.doingCPR)
            "You are already performing CPR on the woman. ";
        else if (precise_doctor.location != womans_room)
            "You concentrate, but can't remember where to put your hands. ";
        else if (precise_doctor.doingCPR)
            "The doctor blocks your efforts. \"No,\" he says, pressing
                fiercely on the woman's chest. ";
        else if (sick_woman_gurney.location == womans_room)
            "The group of doctors is clustered too tightly about the woman
                for you to reach her. ";
    }
    doBegin(actor) = {
        "You link fingers, one hand on top of the other, and watch as your
            hands drift to a dimly-remembered position. Then you are pumping
            as hard as you can, the woman's sternum creaking beneath your
            weight. ";
        actor.doingCPR = true;
        actor.moveInto(cprRoom);
    }
    doSynonym('Begin') = 'Perform'
    verDoStop(actor) = {
        if (!Me.doingCPR)
            "You are not performing CPR. ";
    }
    doStop(actor) = {
        "You step away from the woman, your arms trembling with exhaustion. ";
        Me.doingCPR = nil;
        Me.moveInto(womans_room);
        if (getfuse(sick_woman, &mi2) == nil &&
            getfuse(sick_woman, &pushAway) == nil) {
            "The doctor furrows his brow at you. \"Out,\" he says. ";
            notify(sick_woman, &pushAway, 2);
        }
    }
;

cpr: intangible
    stage = 0
    noun = 'cpr'
    location = womans_room
    sdesc = "CPR"
    ldesc = "You cannot examine CPR. "
    doBegin -> compressions
    doPerform -> compressions
    doStop -> compressions
;

cprRoom: nestedroom, fixedItem
    statusLine = "<<self.location.sdesc>>, performing CPR\n\t"
    reachable = [cpr, compressions, sick_woman, precise_doctor]
    location = womans_room
    roomAction(a, v, d, p, i) = {
        if (v.touch) {
            "Not until you stop CPR. ";
            exit;
        }
    }
    noexit = { "You're not going anywhere until you stop CPR. "; return nil; }
;

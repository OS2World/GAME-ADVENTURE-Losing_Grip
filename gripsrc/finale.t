/*
    Finale, part five of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: finale.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

blasted_plain: room
    sdesc = "Blasted Plain"
    ldesc = "You stand on uneven footing, the dry terrain buckled
        underneath you. A few twisted shrubs and bushes, leafless and gaunt,
        cling to the cracked ground, ekeing out enough sustenance to maintain
        a shadowy half-life. Light filtering through the roiling clouds
        above gives the entire scene an unhealthy grey tinge. "
    setup = {
        moveAllCont(Me, nil);
        moveAllCont(dog, nil);    // Just in case
        if (dog.location != nil) {
            dog.age = 4;
            dog.namedAge = 'old dog';
            dog.clearProps;
            dog.wantheartbeat = nil;
            if (rope.tiedTo == dog) {
                rope.tiedTo = nil;
                rope.moveInto(nil);
            }
            dog.moveInto(blasted_plain);
        }
        Me.travelTo(self);
        notify(old_standing_dad, &end, 3);
        Me.stage = 5;
    }
    noexit = "You make no progress. "
;

terrain: decoration
    noun = 'terrain'
    location = blasted_plain
    sdesc = "terrain"
    ldesc = "The dry ground looks as if something has pushed at it from
        underneath. "
;

shrubs_n_bushes: decoration
    noun = 'shrub' 'shrubs' 'bush' 'bushes'
    adjective = 'leafless' 'gaunt'
    location = blasted_plain
    sdesc = "shrubs and bushes"
    ldesc = "The shrubs and bushes are more twigs than foliage. "
;

blasted_clouds: distantItem
    noun = 'cloud' 'clouds'
    adjective = 'roiling'
    location = blasted_plain
    sdesc = "roiling clouds"
    ldesc = "The clouds form and vanish in seconds like a sped-up film. "
;

old_standing_dad: Actor
    endNum = 1
    isHim = true
    noun = 'father' 'dad'
    adjective = 'old'
    sdesc = "father"
    thedesc = "your father"
    adesc = "your father"
    ldesc = "He looks as he did shortly before he died:\ prematurely-white
        hair, seamed face, narrowed eyes. "
    actorDesc = "Your father stands on the plain two meters in front of you. "
    takedesc = "Not likely. "
    touchdesc = "He moves effortlessly away as you move towards him. "
    actorAction(v, d, p, i) = {
        "He ignores you. ";
        exit;
    }
    verDoKiss(actor) = (self.touchdesc)
    verDoTellAbout(actor, io) = { "He ignores you. "; }
    doSynonym('TellAbout') = 'AskFor'
    verDoAskAbout(actor) = { self.verDoTellAbout(actor, nil); }
    verIoShowTo(actor) = { self.verDoTellAbout(actor, nil); }
    verDoCutWith(actor, io) = { self.touchdesc; }
    verIoCutIn(actor) = { self.touchdesc; }
    verIoGiveTo(actor) = { "He ignores you. "; }
    verDoAttack(actor) = { "How do you intend to do that?"; }
    end = {
        "\b";
        switch (self.endNum++) {
            case 1:
                "There is a gust of wind and your father steps out of the
                    whirling dust. He looks to be the same age he was before
                    he died a few years ago. He grins at you, tobacco-stained
                    teeth gleaming in the grey light. \"Terry,\" he says. ";
                self.moveInto(blasted_plain);
                dadFinalAh.see;
                break;

            case 2:
                if (dog.location == self.location) {
                    "He gestures at the dog. \"A friend. How nice.\" <<
                        dog.capdesc>> makes a phlegmy growl which is cut short
                        by a wheeze. \"You know how I feel about mongrels.\"\b
                        Your father clenches his fist. A nearly-invisible
                        ring of force spreads from him. Nothing happens when
                        it washes over you, but it lifts <<dog.thedesc>> a
                        foot into the air and back down. The dog's eyes film
                        over; blood pools around its muzzle. You kneel in time
                        to hear <<dog.thedesc>> take one last shuddery breath,
                        then let it out in a slow hiss. ";
                    dead_dog.setup;
                }
                else {
                    "He gestures at you. \"Revisiting old haunts?\" He shakes
                        his head. \"You've been tied up with the wrong crowd
                        for too long. I knew you'd end up in a bad way.\" ";
                }
                break;

            case 3:
                "Your father looks at his <<argument_daemon.result > 0 ?
                    "left" : "right">> hand thoughtfully. \"Not
                    that I haven't enjoyed this, but it's time.\" You feel the
                    hair on the back of your neck stand up. ";
                if (Me.ctrlPoints > 0)
                    "\bIn your head a voice says, \"Let go, Terry.\" ";
                break;

            case 4:
                "Your father clenches his <<argument_daemon.result > 0 ?
                    "left" : "right">> hand";
                if (dead_dog.location == self.location)
                    " again";
                if (!Me.relaxed) {
                    ". A rush of air is all the warning you get before
                        something slams into your head with all the care of an
                        errant baseball bat. Blood spurts from your nose in an
                        arc as you fall.\b
                        You lie on the ground";
                    if (dead_dog.location == self.location)
                        " next to <<dog.thedesc>>";
                    " and hazily watch the ground absorb your blood. A booted
                        foot appears in front of you. You try to look up at
                        your father but pass out from the effort.\b
                        You remember nothing else after that.\b";
                    die();
                }
                ". There is a rush of air and something slams into you. It
                    passes through you; the pain is excrutiating but
                    bearable.\b
                    Then it is past and gone. Your father slumps, something
                    vital drained from him. The world around you goes grey
                    before reforming.\b";
                Me.ctrlPoints = 1;
                Me.travelTo(final_hospital_room);
                notify(old_lying_dad, &talk, 2);
                dadFinalAh.solve;
                return;
        }
        notify(self, &end, 1);
    }
;

final_hospital_room: insideRm, droom
    sdesc = "Hospital Room"
    firstdesc = "You are in the room where your father died, though you never
        saw it until he was already gone. It is crowded with familiar medical
        equipment which clusters around a bed. "
    seconddesc = "You are in the room where your father died. It is crowded
        with familiar medical equipment which clusters around a bed. "
    smelldesc = "A smell of decay clings to the room. "
    noexit = "There appears to be no exit. "
;

familiar_med_equipment: decoration
    stage = '5'
    noun = 'equipment'
    adjective = 'familiar' 'medical'
    location = final_hospital_room
    sdesc = "medical equipment"
    ldesc = "The array of equipment only succeeded in prolonging your father's
        agony. "
    listendesc = "The equipment whistles and beeps."
;

final_dads_bed: bedItem
    stage = '5'
    noun = 'bed'
    location = final_hospital_room
    sdesc = "bed"
    ldesc = "The bed is bowed with your father's weight. "
    hdesc = "Your father lies under the bedcovers. "
    verDoSiton(actor) = { "Your father takes up the entire bed. "; }
;

old_lying_dad: Actor
    talkNum = 1
    isListed = nil
    isHim = true
    noun = 'father' 'dad'
    adjective = 'old'
    location = final_dads_bed
    sdesc = "father"
    thedesc = "your father"
    adesc = "your father"
    ldesc = {
        "He breathes in shallow gasps. His face is pale as a candle flame.
            The cancer has crept from his lungs to the rest of his body. ";
        if (dad_strings.location == final_hospital_room)
            "Strings run from under his bedcovers to somewhere above. ";
    }
    actorDesc = "Your father lies under the bedcovers. "
    takedesc = "Not likely. "
    touchdesc = {
        if (gloves.isworn)
            "Your gloves rasp across his skin. ";
        else "His skin is papery and clammy to the touch. ";
    }
    actorAction(v, d, p, i) = {
        "He makes no response. ";
        exit;
    }
    verDoKiss(actor) = {
        "He says nothing, but you can tell he is pleased. ";
    }
    verDoKick(actor) = {
        "Despite your feelings, that would accomplish nothing. ";
    }
    verDoTellAbout(actor, io) = { "He makes no response. "; }
    doSynonym('TellAbout') = 'AskFor'
    verDoAskAbout(actor) = { self.verDoTellAbout(actor, nil); }
    verIoShowTo(actor) = { self.verDoTellAbout(actor, nil); }
    verDoCutWith(actor, io) = {
        "There is no need to hasten your father's demise. ";
    }
    verIoCutIn(actor) = {
        "There is no need to hasten your father's demise. ";
    }
    verIoGiveTo(actor) = { "He makes no response. "; }
    talk = {
        "\b";
        switch (self.talkNum++) {
            case 1:
                "Your father coughs violently several times. \"Dammit, Terry,
                    I never planned any of this.\" He is interrupted by
                    another spasm of coughing. ";
                 break;
            case 2:
                "\"Oh, Terry, I'm so sorry, I'm so sorry.\" Your father shifts
                    in his bed, the sheets rustling under him. \"My heart was
                    in the right space, but after your mother died...\" ";
                break;
            case 3:
                "Your father laughs; it changes to a cough. \"It wasn't
                    even me. Ah, dammit,\" as his arms jerk spasmodically
                    upwards, then fall back down. You see faint strings tied
                    through them; blood oozes from the holes through which
                    they are threaded. \"This wasn't me!\"\ your dad cries in
                    a reedy voice. ";
                dad_strings.moveInto(final_hospital_room);
                break;
            case 4:
                "The light dims as your dad's breathing slows.
                    \"...sorry...\"\ is the last you hear.\b
                    Darkness enfolds you.\b";
                ending_hospital_bed.setup;
                return;
        }
        notify(self, &talk, 1);
    }
;

dad_strings: fixedItem
    noun = 'string' 'strings'
    adjective = 'faint'
    sdesc = "faint strings"
    ldesc = {
        "When your father shifts in his bed, you see that one is attached
            through each wrist; two others presumably run to his ankles.
            You follow the path of the strings with your eyes. They run up
            into the darkness above, far above. The harder you stare, the
            farther you see, until you catch a glimpse of the person at the
            other end of the strings. The face is your own.\b
            Darkness enfolds you.\b";
        unnotify(old_lying_dad, &talk);
        ending_hospital_bed.setup;
    }
;

ending_room: room
    sdesc = "Hospital Room"
    ldesc = {
        "From the bed you can just see a door and a ";
        if (Me.ctrlPoints > 0)
            "window through which light streams";
        else "dark window";
        ". Abstract patterns on the ceiling catch your eye every time you
            glance at them. Beside you rises an IV stand; your hand is at the
            other end of the IV. ";
    }
    listendesc = {
        if (muzak.location == self)
            "You hear muzak. ";
        else pass listendesc;
    }
;

ending_hospital_bed: bedItem
    chatterNum = 1
    stage = 0
    noun = 'bed'
    location = ending_room
    sdesc = "bed"
    ldesc = "The bed is uncomfortable no matter how you turn. "
    listendesc = (ending_room.listendesc)
    verDoUnboard(actor) = {
        "The covers hold you down. ";
    }
    setup = {
        local flag = scoreWatcher.notifyMe;
        
        scoreWatcher.notifyMe = nil;    // Shhhhh!
        incscore(20);
        scoreWatcher.notifyMe = flag;
        pauseAndClear();
        "\b\(Epilog\):\ Release\b\b";
        makeQuote('"When I see the future I close my eyes"',
            'Peter Gabriel');
        Me.travelTo(self);
        ending_room.enterRoom(Me);
        ending_iv_needle.moveInto(hands);
        notify(self, &chatter, 2);
    }
    chatter = {
        "\b";
        switch (self.chatterNum++) {
            case 1:
                "A burst of muzak leaking through the door makes you glance up
                    in time to see Dr.\ Boozer slip into your room. He grins
                    at you. \"No need to get up,\" he says, then laughs. \"Oh,
                    it's good to see you awake. The nurse told me you'd
                    been near to waking up for some time.\" ";
                dr_boozer.moveInto(ending_room);
                muzak.moveInto(ending_room);
                break;
            case 2:
                "Dr.\ Boozer rocks back and forth, heel to toe, heel to toe.
                    \"I won't stay; I'm sure you're tuckered out. We'll talk
                    more in a while.\" He heads for the door. \"You just work
                    on getting well,\" he adds over his shoulder. ";
                dr_boozer.moveInto(nil);
                Me.readyToSleep = true;     // A tweak to sleepVerb
                break;
            case 3:
                "Your eyes grow heavier and heavier the longer you keep them
                    open. Eventually you let them drift shut. You fall into a
                    healing sleep";
                if (Me.ctrlPoints > 0)
                    ", smiling gently";
                ". ";
                die();
        }
        notify(self, &chatter, 1);
    }
;

ending_hospital_covers: fixedItem
    stage = 0
    noun = 'cover' 'covers'
    location = ending_hospital_bed
    sdesc = "covers"
    ldesc = "Though they are thin, their weight is enough to hold you fast. "
    takedesc = "You are too weak. "
    verDoMove(actor) = { "You are too weak. "; }
;

ending_hospital_window: decoration
    stage = 0
    noun = 'window'
    adjective = 'dark' 'light'
    location = ending_room
    sdesc = "window"
    ldesc = {
        if (Me.ctrlPoints > 0)
            "Light streams in through the window. ";
        else "Through the window you can see that night has fallen. ";
    }
;

ending_hospital_door: decoration
    stage = 0
    noun = 'door'
    location = ending_room
    sdesc = "door"
    ldesc = "It leads to the hall which is presumably outside your room. "
;

ending_hospital_ceiling: decoration
    stage = 0
    noun = 'ceiling' 'pattern' 'patterns'
    adjective = 'abstract' 'patterned'
    location = ending_room
    sdesc = "patterned ceiling"
    ldesc = {
        "The ceiling is crazed with ";
        if (Me.ctrlPoints <= 0) "dark ";
        "patterns. ";
    }
;

ending_iv_stand: decoration
    noun = 'stand' 'bag'
    adjective = 'iv' 'IV'
    location = ending_room
    sdesc = "IV stand and bag"
    ldesc = "A bag hangs from the stand. "
;

ending_iv_needle: fixedItem
    noun = 'needle' 'tape'
    adjective = 'iv' 'IV'
    sdesc = "IV needle"
    ldesc = "The needle is held in the back of your hand by tape. "
    takedesc = "It's best that you leave that where it is. "
    verDoPutIn(actor, io) = {
        if (io == Me || io.isBodypart)
            "The needle is already in the back of your hand. ";
        else self.takedesc;
    }
    doSynonym('PutIn') = 'InjectIn'
    verIoInjectWith(actor) = {}
    ioInjectWith(actor, dobj) = {
        self.verDoPutIn(actor, dobj);
    }
;

dr_boozer: Actor
    isHim = true
    noun = 'boozer' 'doctor' 'dr'
    adjective = 'doctor' 'dr'
    sdesc = "Dr.\ Boozer"
    ldesc = "Dr.\ Boozer is in his late fifties, a research doctor who still
        has the air of a small-town GP. "
    actorDesc = "Dr.\ Boozer stands at the foot of your bed. "
    takedesc = "Not likely. "
    touchdesc = "You can't reach him from the bed. "
    actorAction(v, d, p, i) = {
        "Your voice is so weak that Dr.\ Boozer doesn't hear you. ";
        exit;
    }
    verDoTellAbout(actor, io) = {
        "Your voice is so weak that Dr.\ Boozer doesn't hear you. ";
    }
    doSynonym('TellAbout') = 'AskFor'
    verDoAskAbout(actor) = { self.verDoTellAbout(actor, nil); }
    verIoShowTo(actor) = { "Dr.\ Boozer doesn't notice. "; }
    verDoCutWith(actor, io) = { self.touchdesc; }
    verIoCutIn(actor) = (self.touchdesc)
    verIoGiveTo(actor) = { "Dr.\ Boozer doesn't notice your offer. "; }
;

muzak: fixedItem
    noun = 'muzak'
    sdesc = "muzak"
    ldesc = "You find it difficult to see. "
    listendesc = "With concentration you can almost recognize the .38 Special
        song \"Hold on Loosely.\" "
    takedesc = "Not likely. "
;


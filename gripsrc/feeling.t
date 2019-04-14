/*
    Feeling, part four b of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: feeling.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

clock_room: insideRm
    sdesc = "Clock Room"
    ldesc = "The walls of the room are filled to capacity with clocks of
        varying shapes and sizes. All are running, though the hands of some
        whirl quickly while others creep infinitesimally forward. A thick red
        light glows through the doorway to the north. "
    exits = 'north'
    firstseen = {
        frozenWomanAh.see;
        pass firstseen;
    }
    north = south_bridge_end
    out = south_bridge_end
    toBalance = [ 'through the north doorway' south_bridge_end ]
;

clock_room_doorway: myDoorway
    location = clock_room
    ldesc = "It leads north. "
    lookthrudesc = "The ruddy light is all you can see. "
    doordest = south_bridge_end
;

terrys_clocks: decoration
    noun = 'clock' 'clocks'
    location = clock_room
    sdesc = "clocks"
    ldesc = "The clocks are all inset in the walls. Their faces are covered
        in faceted glass and there is no obvious way to set any of them. "
;

red_light: decoration
    noun = 'light'
    adjective = 'thick' 'red'
    location = clock_room
    sdesc = "red light"
    ldesc = "The red light puddles on the floor around the north doorway. "
;

frozen_woman: fixedItem
    isHer = true
    noun = 'woman'
    adjective = 'frozen'
    location = clock_room
    sdesc = "frozen woman"
    ldesc = "She stands perfectly still, head tilted to one side. She has no
        mouth--where it should be, there is only smooth skin. Despite this,
        she is rather pretty, with brown hair framing her face. She stares
        fixedly straight ahead. She is holding
        a sign on which is printed in block letters, \"Touch Me.\" "
    hdesc = "Standing frozen in the middle of the room is a woman. "
    touchdesc = {
        "As soon as you touch the woman, she blinks. She glances around,
            then nods at you. With a swift motion she crumples her sign.
            A second later she is striding out of the room, beckoning you
            with one hand. ";
        self.moveInto(nil);
        unfrozen_woman.moveInto(south_bridge_end); // To set the follower
        unfrozen_woman.moveInto(cb_room);
        south_bridge_end.womanWalkedEast = true;
        notify(unfrozen_woman, &putter1, 0);
        setit(unfrozen_woman);
        frozenWomanAh.solve;
    }
    verDoKiss(actor) = {}
    doKiss(actor) = (self.touchdesc)
;

frozen_sign: fixedItem, readable
    noun = 'sign'
    location = frozen_woman
    sdesc = "sign"
    ldesc = "Printed on the sign in block letters are the words, \"Touch Me.\" "
    takedesc = "You cannot pry it out of the woman's hands. "
;

unfrozen_woman: Actor
    actionNum = 1
    movingNum = 1
    drunkNum = 1
    isMoving = nil
    isWatchingStrands = nil
    isWaiting = nil
    isHer = true
    firstStrand = nil
    noMoreStrands = nil
    myfollower = unfrozen_woman_follower
    noun = 'woman'
    adjective = 'mouthless'
    sdesc = "mouthless woman"
    thedesc = "the mouthless woman"
    adesc = "a mouthless woman"
    ldesc = {
        "She stands just over five feet tall. Her brown hair falls to her
            shoulders, framing a face which lacks a mouth. ";
    }
    actorDesc = {
        if (self.isMoving)
            "There is a woman here, walking with a purpose. ";
        else if (self.isWatchingStrands)
            "The woman is here, watching the strands float about the room. ";
        else if (self.isWaiting)
            "The woman is waiting by the balance, watching you. ";
        else "A woman stands here, unremarkable save for her lack of a
            mouth. ";
    }
    touchdesc = "She bats your hands away. "
    disavow = "She furrows her forehead at you, eyebrows lowering. "
    actorAction(v, d, p, i) = {
        if (v == yellVerb) {
            "The woman glares at you. Obviously she is no fan of Ellison. ";
            exit;
        }
        "The woman tugs on a lock of her hair, ignoring you. ";
        exit;
    }
    verDoKiss(actor) = { "She has no lips to kiss. "; }
    ioGiveTo(actor, dobj) = {
        if (!floating_strands.womanSeenStrandTaken || !dobj.isStrand) {
            "The woman ignores you. ";
            return;
        }
        if (self.isMoving) {
            "The woman shakes her head at you, telling you to wait. ";
            return;
        }
        if (self.noMoreStrands) {
            "She pushes the strand away. ";
            return;
        }
        if (self.location != cb_room) {
            if (self.firstStrand != nil) {
                "The woman holds up a hand, refusing your proffered gift. ";
                return;
            }
            "The woman takes the strand, then gestures for you to follow
                her. ";
            dobj.moveInto(self);
            self.firstStrand = dobj;
            unnotify(self, &putter2);
            notify(self, &wander2, 0);
            getstrandsAh.solve;
            return;
        }
        if (self.firstStrand == nil) {
            "The woman takes the strand, then looks at you again expectantly. ";
            dobj.moveInto(self);
            unnotify(self, &putter2);
            self.firstStrand = dobj;
        }
        else {
            "The woman takes the second strand from you. She places one on
                each pan of the balance. ";
            weighedAh.see;
            if (russian_doll.location == cb_balance) {
                "When nothing happens, she looks under the balance and kicks
                    the doll she finds there out of the way. ";
                russian_doll.moveInto(cb_room);
            }
            "The arms swing back and forth, far out of proportion to the
                weight placed on them. You and the woman watch as the balance's
                motion damps out, moving slower and slower. When the arms
                stop, ";
            if ((firstStrand.myWord == 'chain' && dobj.myWord == 'restart') ||
                (firstStrand.myWord == 'restart' && dobj.myWord == 'chain')) {
                "the two pans are level. Swiftly now, the woman snatches the
                    strands from the balance. ";
                dobj.moveInto(nil);
                self.firstStrand.moveInto(nil);
                self.noMoreStrands = true;
                notify(self, &putter3, 2);
                incscore(5);
            }
            else {
                "they are canted at a severe angle. The woman's excited
                    expression drains from her face as she hands the two
                    strands back to you. ";
                self.firstStrand.moveInto(Me);
                self.firstStrand = nil;
            }
        }
    }
    ioSynonym('GiveTo') = 'ShowTo'
    
    putter1 = {
        if (Me.location != self.location)
            return;
        "\b";
        switch (self.actionNum++) {
            case 1:
                "Scratching her head, the woman glances at the chains. She
                    tugs gently on one of them. ";
                break;
            case 2:
                "With a loud rattle, the woman shakes several of the chains,
                    creating a cloud of rust. She steps back, looking up and
                    down the chains slowly. ";
                break;
            case 3:
                "The woman walks to the levers and gives them an experimental
                    tug. They don't move. She kicks them. They don't move. ";
                break;
            case 4:
                "The woman tugs at a lock of her hair. Her brow furrows. ";
                break;
            case 5:
                "The woman's eyes widen, and she snaps her fingers.
                    She strides out of the room, pulling ";
                if (rope.location == Me && rope.tiedTo != nil) {
                    "the rope from your fingers and ";
                    rope.moveInto(Me.location);
                }
                "you with her.\b";
                self.moveInto(south_bridge_end);
                self.isMoving = true;
                Me.travelTo(south_bridge_end);
                break;
        }
        if (self.actionNum <= 5)
            return;
        self.actionNum = 1;
        unnotify(self, &putter1);
        notify(self, &wander1, 0);
    }
    wander1 = {
        local locFlag = (Me.location == self.location);
        
        switch (self.movingNum++) {
            case 1:
                if (locFlag)
                    "\bThe woman walks onto the rock bridge without a second
                        thought. ";
                self.moveInto(bridge);
                if (Me.location == self.location)
                    "\bThe woman walks onto the bridge. She glides past you,
                        teetering near the edge, before you have time to
                        worry. ";
                break;
            case 2:
                if (locFlag)
                    "\bThe woman walks off the bridge to the north. ";
                self.moveInto(north_bridge_end);
                if (Me.location == self.location)
                    "\bThe woman walks off of the rock bridge and joins you
                        on the ledge. ";
                break;
            case 3:
                if (locFlag)
                    "\bThe woman enters the doorway to the north. ";
                self.moveInto(links_room);
                if (Me.location == self.location)
                    "\bThe woman enters the room. ";
                break;
            default:
        }
        if (self.movingNum > 3) {
            self.isMoving = nil;
            unnotify(self, &wander1);
            notify(self, &putter2, 0);
            self.isWatchingStrands = true;
        }
    }
    putter2 = {
        local l = uberloc(Me);

        if (!floating_strands.womanSeenStrandTaken) {
            if (Me.location == self.location) {
                switch (RAND(7)) {
                    case 1:
                        "\bThe woman points at the strands, then back to you. ";
                        break;
                    case 2:
                        "\bThe woman attempts to grab some of the strands, but
                            they avoid her. ";
                        break;
                    case 3:
                        "\bYou feel a tap at your shoulder. When you turn to
                            look, you see the woman glaring at you. She
                            motions you towards a clump of the strands. ";
                        break;
                    case 4:
                        "\bThe woman stares intently at the strands. ";
                        break;
                    default:
                }
            }
            return;
        }
        if (l != self.location) {
            "\bThe woman follows you";
            if (l == bridge) {
                " onto the bridge";
                if (self.location == south_bridge_end)
                    ". She sidles past you, both of you coming precariously
                        near the edge of the bridge";
            }
            ". ";
            self.moveInto(l);
            if (self.location != links_room)
                self.isWatchingStrands = nil;
            else self.isWatchingStrands = true;
        }
    }
    wander2 = {
        self.isMoving = true;
        self.isWatchingStrands = nil;
        if (self.location != cb_room) {
            if (Me.location == self.location)
                "\bThe woman walks <<self.location.toBalance[1]>>. ";
            self.moveInto(self.location.toBalance[2]);
            if (Me.location == self.location)
                "\bThe woman enters the room, walking towards you. ";
        }
        else {
            if (Me.location != self.location)
                return;
            "\bThe woman moves to the balance, then looks back at you,
                waiting for something else. ";
            unnotify(self, &wander2);
            givestrandsAh.see;
            self.isMoving = nil;
        }
    }
    putter3 = {
        if (Me.location != self.location) {
            notify(self, &putter3, 1);
            return;
        }
        "\bThe woman takes the two strands you gave her and wraps them around
            one of the chains. She steps back, admiring the wrapped chain.
            With a swift motion she yanks down one of the levers. A loud groan
            echoes through the room. Rust swirls down as one of the chains
            jerks upwards, followed by another, then another, until all are
            winding their way from somewhere below to somewhere above. The
            woman nods in satisfaction. ";
        chains.moving = true;
        strand_breeze.moveInto(nil);
        strand_decoration.moveInto(nil);
        notify(completed_breeze, &blow, 2 + RAND(2));
        notify(self, &wander3, 2);
        givestrandsAh.solve;
    }
    wander3 = {
        if (self.location == Me.location)
            "\bThe woman walks through the doorway to the south. ";
        self.moveInto(break_room);    /* To set the follower */
        self.moveInto(easy_chair);
        if (uberloc(Me) == uberloc(self)) {
            "\bThe woman walks into the break room and ";
            if (Me.location == easy_chair) {
                "moves you out of the way before she ";
                Me.moveInto(break_room);
            }
            "sinks into the easy chair. ";
        }
        notify(self, &getMeDrunk, 1);
    }
    getMeDrunk = {
        if (uberloc(Me) != uberloc(self)) {
            notify(self, &getMeDrunk, 1);
            return;
        }
        "\b";
        switch (self.drunkNum++) {
            case 1:
                "The woman takes a flask from one of her pockets and opens
                    it. She closes her eyes as she holds it under her nose,
                    breathing deeply. You catch a whiff from the flask; it
                    stings your nose. ";
                flask.moveInto(self);
                break;

            case 2:
                "Fumes from the flask fill the room. Your vision blurs
                    momentarily. ";
                if (Me.location != sofa) {
                    "The sofa is there to catch you as you crumple. ";
                    Me.moveInto(sofa);
                }
                "The woman slumps down in the easy chair as if boneless. ";
                Me.drunk = true;
                drunkAh.see;
                break;

            case 3:
                "You barely notice when the woman caps the flask and walks
                    out the doorway. She pauses, sketches a salute to you, and
                    is gone. ";
                self.moveInto(nil);
                self.myfollower.moveInto(nil);
                notify(coffee_spoons, &glow, 5);
                flask.moveInto(south_bridge_end);
                flask_note.moveInto(south_bridge_end);
                flask_note.firstPick = true; // So the note still has an hdesc
                break;
        }
        if (self.drunkNum <= 3)
            notify(self, &getMeDrunk, 1);
    }
;

unfrozen_woman_follower: follower
    myactor = unfrozen_woman
    noun = 'woman'
    adjective = 'mouthless'
    verDoFollow(actor) = {
        if (unfrozen_woman.location == bridge) {
            if (Me.memory >= 0)
                "As you place a foot on the bridge, you remember hanging on to
                    the side of the cliff above the cage of faeries. Fear rises
                    up and grips you; you take several shaky steps away from
                    the bridge. Even if you could force yourself onto the
                    bridge, you would no doubt fall. ";
        }
        else if (unfrozen_woman.location == cb_room &&
            Me.location == south_bridge_end) {
            south_bridge_end.east;    // Make sure the monkeys don't block us
        }
    }
;

flask: item
    noun = 'flask'
    adjective = 'metal'
    sdesc = "metal flask"
    ldesc = {
        "A metal hip flask. ";
        if (flask_water.location == self)
            "It is filled with water. ";
    }
    fill(t) = {
        if (flask_water.location == self) {
            if (flask_water.type != t) {
                "As you add water to the flask you hear a loud hissing noise.
                    The flask heats up. When the steam has cleared and you
                    can look in the flask, you see that it is empty. ";
                flask_water.moveInto(nil);
            }
            else
                "The water in the flask begins overflowing into the sink.
                    When you pull the flask out from under the stream of
                    water, it is as full as it was to begin with. ";
        }
        else {
            "The flask fills with water. ";
            flask_water.moveInto(self);
            flask_water.type = t;
        }
    }
    verDoOpen(actor) = { "The flask is already open. "; }
    verDoDrink(actor) = {
        if (flask_water.location != self)
            "There is nothing in the flask to drink. ";
    }
    doDrink(actor) = {
        flask_water.doDrink(actor);
    }
    // Pull a fast one w/"take" to handle being under the water stream(s)
    doTake(actor) = {
        if (self.location == metal_sink) {
            if (left_handle.isActive && !right_handle.isActive) {
                flask_water.moveInto(self);
                flask_water.type = 1;
            }
            else if (right_handle.isActive && !left_handle.isActive) {
                flask_water.moveInto(self);
                flask_water.type = 2;
            }
        }
        pass doTake;
    }
    verDoFill(actor) = { askio(withPrep); }
    verDoFillWith(actor, io) = {
        if (io == karo_syrup || io == karo_syrup_bottle)
            "You tilt the bottle, but before the mass of syrup has made its
                meandering way to the neck of the bottle, you realize that
                the opening in the flask is too small to admit the Karo
                syrup without also spilling enough to cover your hands.
                You straighten the bottle; the Karo syrup settles back down
                with a blorp. ";
        else if (io != lethe_sink_water && io != mnemosyne_sink_water)
            "There's no need to fill the flask with <<io.thedesc>>. ";
    }
    doFillWith(actor, io) = {
        if (io == lethe_sink_water)
            self.fill(1);
        else self.fill(2);
    }
    verDoEmpty(actor) = {
        if (flask_water.location != self)
            "There is nothing in the flask. ";
    }
    doEmpty(actor) = {
        "You pour the water out of the flask. ";
        flask_water.moveInto(nil);
    }
;

flask_note: readable, complex
    noun = 'note'
    weight = 1
    bulk = 1
    sdesc = "note"
    ldesc = "On one side of the note \"Touch Me\" is written in block letters.
        The other side reads, \"Your exit lies down.\" "
    hdesc = "Lying wrinkled on the ledge is a note. "
    verDoEat(actor) = {}
    doEat(actor) = {
        "It has all the substance of cotton candy in your mouth as it melts
            away. A faint aftertaste of grape remains. ";
        self.moveInto(nil);
    }
;

fake_red_light: wallpaper, decoration
    noun = 'light'
    adjective = 'red' 'reddish' 'crimson' 'ruddy' 'thick'
    sdesc = "red light"
    ldesc = "The red light illuminates the cavern from somewhere above. It
        is thick, the color of blood. "
;

fake_bridge: wallpaper, decoration, readable
    noun = 'bridge'
    adjective = 'narrow' 'rock'
    sdesc = "rock bridge"
    ldesc = "The bridge is just wider than your two feet placed together.
        It looks sturdy enough. There are words painted on the bridge. "
    readdesc = "This is painted on the bridge:\ \"I don't want the world;
        I just want your half.\" "
;

fake_words: wallpaper, decoration, readable
    noun = 'words' 'paint'
    adjective = 'painted'
    sdesc = "painted words"
    ldesc = "This is painted on the bridge:\ \"I don't want the world;
        I just want your half.\" "
;

fake_chasm: wallpaper, decoration
    noun = 'chasm'
    adjective = 'deep'
    sdesc = "chasm"
    ldesc = "It drops down out of sight; not even the red light can
        penetrate its depths. "
    verDoEnter(actor) = { "You cannot bring yourself to jump in the chasm. "; }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        "\^<<dobj.thedesc>> <<dobj.isThem ? "are" : "is">> quickly lost from
            view. ";
        dobj.moveInto(nil);
    }
;

completed_breeze: floatingItem, fixedItem
    noun = 'breeze'
    location = {
        if (Me.location.breezeRoom && chains.moving)
            return Me.location;
    }
    sdesc = "breeze"
    ldesc = "You stick your hand in the breeze, feeling it slide along your
        skin. "
    touchdesc = {
        if (gloves.isworn)
            "You can barely feel it through the gloves. ";
        else "It is cool as it slides past you. ";
    }
    blow = {
        if (Me.location.breezeRoom) {
            if (Me.location == cb_room) {
                "\bStrands are borne into the room on the breeze. They float
                    over to the balance, where they pile up on both pans.
                    Faster than you can clearly follow, the
                    balance rocks back and forth. Strands shift between the
                    pans until the balance is level. The strands then bind
                    together and attach to various chains which carry them
                    up and out of sight. ";
            }
            else "\bStrands slither over you, carried past on the breeze. ";
        }
        notify(self, &blow, 3 + RAND(2));
    }
;

south_bridge_end: room
    womanWalkedEast = nil
    breezeRoom = true
    floating_items = [fake_red_light, fake_bridge, fake_words, fake_chasm]
    sdesc = "South End of Bridge"
    ldesc = {
        "You are in a tall cavern, standing on a narrow ledge which hugs the
            south wall. To the north, the ledge becomes a narrow rock bridge
            which arcs over a deep chasm. ";
        if (chains.moving)
            "From across the bridge you occasionally feel a breeze blow. ";
        "Doorways have been cut in the rock to the south and east. The entire
            scene is lit by reddish light from above. ";
    }
    exits = 'north, south, and east'
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (self.womanWalkedEast) {
            self.womanWalkedEast = nil;
            "\bThrough the east doorway you catch a glimpse of brown hair as
                the woman moves about the room. ";
        }
    }
    firstseen = {
        monkeysAh.see;
        pass firstseen;
    }
    north = {
        if (Me.memory >= 0) {
            "As you place a foot on the bridge, you remember hanging on to
                the side of the cliff above the cage of faeries. Fear rises
                up and grips you; you take several shaky steps away from the
                bridge. Even if you could force yourself onto the bridge,
                you would no doubt fall. ";
            chasmAh.see;
            return nil;
        }
        else {
            "You pause for a moment, troubled by something, before you shake
                it off and continue.\b";
            chasmAh.solve;
            return bridge;
        }
    }
    south = clock_room
    east = {
        if (no_evil_monkeys.location == self) {
            "You cannot get past the monkeys. ";
            return nil;
        }
        else return cb_room;
    }
    toBalance = [ 'into the room to the east' cb_room ]
    jumpAction = "You cannot bring yourself to jump into the chasm. "
;

south_bridge_south_doorway: myDoorway
    adjective = 'south'
    location = south_bridge_end
    sdesc = "south doorway"
    ldesc = "It is more a hole in the rock than a doorway. "
    lookthrudesc = "The red light keeps you from seeing any details. "
    doordest = clock_room
;

south_bridge_east_doorway: myDoorway
    adjective = 'east'
    location = south_bridge_end
    sdesc = "east doorway"
    ldesc = "It is more a hole in the rock than a doorway. "
    lookthrudesc = "The red light keeps you from seeing any details. "
    doEnter(actor) = {
        local dest;

        dest = south_bridge_end.east;
        if (dest != nil)
            actor.travelTo(dest);
    }
;

no_evil_monkeys: Actor
    isThem = true
    noun = 'monkey' 'monkeys'
    adjective = 'three'
    location = south_bridge_end
    actorDesc = "Three monkeys block the east doorway. "
    sdesc = "three monkeys"
    stringsdesc = 'the three monkeys'
    thedesc = "the three monkeys"
    ldesc = "The three monkeys are nearly two meters tall. One holds his
        hands over his eyes; another holds his hands over his ears; the
        third covers his mouth with his hands. "
    touchdesc = "One of the monkeys bares his teeth; you back away slowly. "
    verDoAskAbout(actor) = { "The monkeys do not respond. "; }
    actorAction(v, d, p, i) = {
        "The monkeys studiously ignore you. ";
        exit;
    }
    verDoKiss(actor) = {
        "One of the monkeys bares its teeth, convincing you not to kiss any
            of them. ";
    }
    verDoKick(actor) = {
        "One of the monkeys nips you on the foot. You dance back in pain. ";
    }
    doSynonym('Kick') = 'Attack'
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "The monkey who is covering his mouth removes one of his hands, leaving
            the other to block his mouth. He reaches out and scoops <<
            io.thedesc>> from your hands. With a negligent flick of the wrist
            he tosses it into the depths of the chasm before replacing his hand
            over his mouth and other hand. ";
        io.moveInto(nil);
    }
    verIoCutIn(actor) = {
        if (pocketknife.location != actor)
            "You have nothing to cut with. ";
        else if (!pocketknife.isopen)
            "The pocketknife isn't open. ";
    }
    ioCutIn(actor, dobj) = { self.doCutWith(actor, pocketknife); }
    verDoAskFor(actor, io) = { "The monkeys do not respond. "; }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (dobj != evil_memory)
            "The monkeys do not respond. ";
        else {
            "As you hold up the sphere, it begins making a loud humming noise.
                You see the three monkeys twitch as you bring the sphere
                closer. Then you drop the sphere, letting it roll to the
                feet of one of the monkeys.\b
                That monkey can stand it no longer. He takes his hands from
                his ears and grabs the sphere. When he does so, he hears
                the noise the sphere is making. Eyes wide, he shrieks and
                pulls the second monkey's hands from his eyes. They shriek in
                unison and dive into the chasm, one right after the other.\b
                The third monkey sits there, the whites of his eyes showing.
                He looks at you, then at the sphere, then at you, then at the
                sphere. \"Oh, bugger,\" he says resignedly before following his
                companions into the chasm. ";
            evil_memory.moveInto(south_bridge_end);
            self.moveInto(nil);
            monkeysAh.solve;
            incscore(5);
        }
    }
    ioSynonym('ShowTo') = 'GiveTo'
;

cb_room: insideRm
    notLeaving = true        // Flag for handling the rope. See the
                             //  the room.leaveRoom modification in gript.h.
    breezeRoom = true
    sdesc = "Room of Chains and Balance"
    ldesc = {
        "The east wall of the room is covered in chains, chains which run
            from the ceiling to the floor. ";
        if (cb_levers.location == self)
            "Next to the chains are several levers. ";
        "In the center of the room a large balance huddles. A doorway leads
            west; to the south is an oddly-shaped arch. ";
        if (chains.moving)
            "A breeze occasionally wends its way in from the west doorway. ";
    }
    exits = 'west and south'
    west = {
        self.notLeaving = nil;
        return south_bridge_end;
    }
    south = {
        self.notLeaving = true;
        return break_room;
    }
;

cb_room_doorway: myDoorway
    location = cb_room
    ldesc = "It leads west. "
    lookthrudesc = "All you can see is ruddy light. "
    doordest = south_bridge_end
;

chains: decoration
    moving = nil
    noun = 'chain' 'chains'
    adjective = 'rusted' 'rusty' 'knotted' 'moving'
    location = cb_room
    sdesc = "chains"
    ldesc = {
        "The chains are ";
        if (self.moving)
            "slowly shedding their layer of rust as they move from the floor
                to the ceiling, drawn up by some unseen mechanism. ";
        else "rusted and knotted. They've not moved for some time. ";
    }
;

cb_levers: fixedItem
    noun = 'lever' 'levers'
    location = cb_room
    sdesc = "levers"
    ldesc = "The levers jut from the wall next to the chains. "
    verDoPull(actor) = {
        if (unfrozen_woman.location == self.location)
            "The woman catches your wrists and moves you away from the
                levers. ";
        else "The levers are frozen. ";
    }
;

cb_balance: decoration
    noun = 'balance'
    adjective = 'large'
    location = cb_room
    sdesc = "balance"
    ldesc = {
        "A large brass balance. Its pans are the size of dinner plates. ";
        if (russian_doll.location == self)
            "Jammed under one of the plates is a doll, preventing the balance
                from working. ";
    }
;

russian_doll: item
    noun = 'doll' 'groove'
    adjective = 'russian' 'matruska'
    location = cb_balance
    sdesc = "Russian doll"
    ldesc = "A Russian nesting doll, cheap and tacky. A groove runs around
        it. "
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You tug open the halves of the doll. The blackness you find inside
            rushes out, washing over you, carrying you away.\b";
        setit(nil);
        cantLeaveAh.solve;
        dollsAh.see;
        dolldaemon.setup;
    }
;

arch: fixedItem, floatingItem
    noun = 'arch'
    adjective = 'oddly-shaped' 'odd'
    location = {
        if (Me.location == cb_room || Me.location == break_room)
            return Me.location;
        return nil;
    }
    sdesc = "arch"
    ldesc = "The arch is slightly asymmetrical, a deviation so slight as to be
        unnoticeable except for the odd sense of unease it engenders. A knob
        protrudes from one side of it. "
    verDoEnter(actor) = {}
    doEnter(actor) = { actor.travelTo(break_room); }
;

arch_knob: fixedItem, floatingItem
    noun = 'knob' 'protrusion'
    adjective = 'wood' 'wooden'
    location = arch
    sdesc = "knob"
    ldesc = {
        "A wooden protrusion about the size of your fist. ";
        if (rope.tiedTo == self)
            "Tied to it is a length of rope. ";
    }
    verIoTieTo(actor) = {}
;

break_room: insideRm
    notLeaving = true
    sdesc = "Break Room"
    ldesc = {
        local bothFlag = left_handle.isActive && right_handle.isActive;

        "A break room, similar in appearance and seediness to the one in
            the McDonald's where you used to work. There is a sink against one
            wall";
        if (left_handle.isActive || right_handle.isActive)
            ", water pouring from <<left_handle.isActive &&
                right_handle.isActive ? "" : "one of">> its spigots";
        ". A sofa, its floral pattern faded, and an easy chair are the
            only furniture. ";
    }
    smelldesc = {
        if (uberloc(unfrozen_woman) == self && unfrozen_woman.drunkNum > 0)
            "The fumes from the woman's flask sting your nose. ";
        else pass smelldesc;
    }
    listendesc = {
        if (left_handle.isActive && right_handle.isActive)
            "You hear a hissing noise. ";
        else pass listendesc;
    }
    exits = 'north'
    firstseen = {
        breakAh.see;
        pass firstseen;
    }
    north = {
        if (Me.drunk) {
            "Your feet move faster than you can control. The doorway slyly
                moving to one side every time you approach finalizes your
                inability to leave. ";
            return nil;
        }
        return cb_room;
    }
    west = {
        if (pointing_coffee_spoons.location == self)
            pointing_coffee_spoons.doFollow(Me);
        else self.noexit;
        return nil;
    }
    out = (self.north)
    toBalance = [ 'out of the room' cb_room ]
;

metal_sink : fixeditem, container
    sdesc = "metal sink"
    ldesc = {
        local list = contlist(self);

        "The sink is made of metal and is stained from
            repeated use.  There are two handles, each with its own spigot. ";
        if (left_handle.isActive) {
            if (right_handle.isActive)
                "Water flows from both spigots, forming a frothy, hissing
                    mixture in the sink. ";
            else "Water flows from the left spigot. ";
        }
        else if (right_handle.isActive)
            "Water flows from the right spigot. ";
        if (coffee_spoons.firstPick)
            "In the sink are a collection of spoons. ";
        if (length(list) > 0) {
            if (coffee_spoons.firstPick)
                "Also in";
            else "In";
            " the sink you see <<listlist(list)>>. ";
        }
    }
    maxbulk = 5
    noun = 'sink'
    adjective = 'metal'
    location = break_room
    ioPutIn(actor, dobj) = {
        if (dobj == flask) {
            if (left_handle.isActive || right_handle.isActive) {
                "Which handle would you like to put the flask under? ";
                setit(flask);
                abort;
            }
        }
        pass ioPutIn;
    }
;

left_handle: switchItem
    noun = 'handle' 'spigot' 'faucet'
    plural = 'handles' 'spigots'
    adjective = 'left' 'l'
    location = break_room
    sdesc = {
        "left ";
        if (find(objwords(1), 'spigot') != nil ||
            find(objwords(2), 'spigot') != nil ||
            find(objwords(1), 'spigots') != nil ||
            find(objwords(2), 'spigots') != nil)
            "spigot";
        else "handle";
    }
    ldesc = {
        "The left handle has an \"L\" on it. ";
        if (self.isActive) "Water runs from the left spigot. ";
    }
    verDoSwitch( actor ) = { "There's no switch on the handle. "; }
    verDoTurn(actor) = {
        "You must specify whether you want to turn the handle on or off. ";
    }
    doTurnon( actor ) = {
        inherited.doTurnon(actor);
        lethe_sink_water.moveInto(break_room);
        "Water begins pouring from the spigot";
        if (flask.location == metal_sink) {
            " and splashing into the flask";
            if (flask_water.location == flask && flask_water.type != 1) {
                " with a loud sizzle";
                flask_water.moveInto(nil);
            }
        }
        ". ";
        if (right_handle.isActive)
            "A hissing noise rises from the sink as the two streams of
                water mix.";
    }
    doTurnoff( actor ) = {
        inherited.doTurnoff(actor);
        lethe_sink_water.moveInto(nil);
        if (right_handle.isActive)
            "The hissing noise stops. ";
        else if (flask.location == metal_sink) {
            flask_water.moveInto(flask);
            flask_water.type = 1;
        }
    }
    doSynonym('Turnon') = 'Open'
    doSynonym('Turnoff') = 'Close'
    verIoPutUnder(actor) = {
        if (!self.isActive)
            pass verIoPutUnder;
    }
    ioPutUnder(actor, dobj) = {
        if (dobj != flask)
            "There's no need to put anything under <<self.thedesc>>. ";
        else
            flask.fill(1);
    }
    verDoPull(actor) = {
        "You can only turn the spigot on or off. ";
    }
    doSynonym('Pull') = 'Push'
;

right_handle: switchItem
    noun = 'handle' 'spigot' 'faucet'
    plural = 'handles' 'spigots'
    adjective = 'right' 'm'
    location = break_room
    sdesc = {
        "right ";
        if (find(objwords(1), 'spigot') != nil ||
            find(objwords(2), 'spigot') != nil ||
            find(objwords(1), 'spigots') != nil ||
            find(objwords(2), 'spigots') != nil)
            "spigot";
        else "handle";
    }
    ldesc = {
        "The right handle has an \"M\" on it. ";
        if (self.isActive) "Water runs from the right spigot. ";
    }
    verDoSwitch( actor ) = { "There's no switch on the handle. "; }
    verDoTurn(actor) = {
        "You must specify whether you want to turn the handle on or off. ";
    }
    doTurnon( actor ) = {
        inherited.doTurnon(actor);
        mnemosyne_sink_water.moveInto(break_room);
        "Water begins flowing from the spigot";
        if (flask.location == metal_sink) {
            " and splashing into the flask";
            if (flask_water.location == flask && flask_water.type != 1) {
                " with a loud sizzle";
                flask_water.moveInto(nil);
            }
        }
        ". ";
        if (left_handle.isActive)
            "A hissing noise rises from the sink as the two streams of
                water mix. ";
    }
    doTurnoff( actor ) = {
        inherited.doTurnoff(actor);
        mnemosyne_sink_water.moveInto(nil);
        if (left_handle.isActive)
            "The hissing noise stops. ";
        else if (flask.location == metal_sink) {
            flask_water.moveInto(flask);
            flask_water.type = 2;
        }
    }
    doSynonym('Turnon') = 'Open'
    doSynonym('Turnoff') = 'Close'
    verIoPutUnder(actor) = {
        if (!self.isActive)
            pass verIoPutUnder;
    }
    ioPutUnder(actor, dobj) = {
        if (dobj != flask)
            "There's no need to put anything under <<self.thedesc>>. ";
        else
            flask.fill(2);
    }
    verDoPull(actor) = {
        "You can only turn the spigot on or off. ";
    }
    doSynonym('Pull') = 'Push'
;

lethe_sink_water: fixedItem
    noun = 'stream' 'water'
    adjective = 'left'
    sdesc = "left stream of water"
    ldesc = "A stream of water is pouring merrily from the left spigot. "
    verDoDrink(actor) = {}
    doDrink(actor) = {
        "You take a sip of the water. It has a cool, refreshing taste. ";
        actor.memory--;
        if (actor.memory < -1) {
            "It sluices away memories as you swallow, until you suddenly
                realize that you have no memory save that of drinking the
                water, and no compulsion save to continue drinking....\b";
            die();
        }
        else "As it trickles down your throat, you feel an odd sensation, as
            of cool fingers run lightly across your brain. A carefree mood
            grips you, some of your worries lifted from you. ";
    }
    verIoPutUnder(actor) = {}
    ioPutUnder(actor, dobj) = {
        if (dobj != flask)
            "There's no need to put anything under <<self.thedesc>>. ";
        else
            flask.fill(1);
    }
    doTurnoff -> left_handle
    ioSynonym('PutUnder') = 'PutIn'
;

mnemosyne_sink_water: fixedItem
    noun = 'stream' 'water'
    adjective = 'right'
    sdesc = "right stream of water"
    ldesc = "From the right spigot a stream of water slowly pours. "
    verDoDrink(actor) = {}
    doDrink(actor) = {
        "You carefully sip the water. It is thick and has a bitter
            aftertaste to it. ";
        actor.memory++;
        if (actor.memory > 1) {
            "Your memory improves again, so much in fact that the past seems
                more real than the present. You slump to the floor, enraptured
                by what you recall....\b";
            die();
        }
        else "As it settles in your stomach you feel a sharp pain right behind
            your eyes. It slowly fades, leaving in its wake several
            rememberances of the past. ";
    }
    verIoPutUnder(actor) = {}
    ioPutUnder(actor, dobj) = {
        if (dobj != flask)
            "There's no need to put anything under <<self.thedesc>>. ";
        else
            flask.fill(2);
    }
    doTurnoff -> right_handle
    ioSynonym('PutUnder') = 'PutIn'
;

/* The water which is placed in the flask */
flask_water: fixedItem
    type = nil    // Set = to 1 for lethe water, = to 2 for mnemosyne water
    noun = 'water'
    adjective = 'flask'
    sdesc = "flask water"
    ldesc = "The water is barely visible inside the flask. "
    verDoDrink(actor) = {}
    doDrink(actor) = {
        switch (self.type) {
            case 1:        // Lethe water
                lethe_sink_water.doDrink(actor);
                break;
            case 2:        // Mnemosyne water
                mnemosyne_sink_water.doDrink(actor);
                if (Me.location == bridge && Me.memory >= 0) {
                    leaveAh.solve;
                    "One of those rememberances is of you clinging to the
                        cliff above the cage. You look down, far down. You
                        hear blood rushing in your ears as you gently topple
                        off the bridge.\b";
                    if (!Me.solvedDolls) {
                        "And then you are on the side of the chasm watching
                            yourself fall. A feeling of separation washes
                            over you as the other you vanishes into the depths. ";
                        cantLeaveAh.see;
                        Me.moveInto(south_bridge_end);
                    }
                    else {
                        "And you are floating, with Jefrey ";
                        if (dog.location == argument_room)
                            "and <<dog.thedesc>> ";
                        "for company. \"Glad to see you again, Terry,\" Jefrey
                            says. \"You cleaned up those problems quickly.\"
                            He removes the matruska dolls from his pocket and
                            lets them tumble away. \"Won't need those any
                            more.\"\b
                            There is a loud buzzing. Around you the space is
                            threaded with veins of white light. Jefrey throws
                            an arm over his eyes";
                        if (dog.location == argument_room)
                            " and tightens his grip on <<dog.thedesc>>, who
                            growls";
                        ". \"Ah, shit,\" he murmurs. \"I thought I had longer.\"
                            He grabs your shoulder. \"You have to listen,
                            before they pull you back.\" But he is wrenched
                            away from you and sent flying. \"Terry! ";
                        if (Me.ctrlPoints > 0)
                            "Don't do what he--\"\b";
                        else "His hands! When he--\"\b";
                        unnotify(completed_breeze, &blow); // Turn off breeze
                        short_interlude();
                    }
                }
        }
        self.moveInto(nil);
    }
;

coffee_spoons: complex
    twitchy = nil
    dirty = true
    isThem = true
    noun = 'spoon' 'spoons'
    adjective = 'coffee' 'stained'
    weight = 2
    bulk = 5
    location = break_room
    sdesc = "coffee spoons"
    ldesc = "The spoons have been used to stir many a cup of coffee, judging
        from the stains which cover their surface. "
    hdesc = {
        "Sitting in the sink";
        if (self.dirty)
            ", waiting vainly to be scrubbed,";
        " are several spoons. ";
    }
    glow = {
        if (drunkAh.solved)
            return;
        "\b";
        if (self.location == Me)
            "In your hand, the coffee spoons twitch, as if they would leap
                from your grasp. ";
        else if (self.firstPick)
            "The coffee spoons clatter suddenly, loudly, in the sink. ";
        else if (inside(self, Me))
            "You feel the coffee spoons you are carrying turn and tug. ";
        else "The coffee spoons jump and clang against each other. ";
        self.twitchy = true;
    }
    doTake(actor) = {
        if (self.twitchy) {
            "The coffee spoons slide out of your hands and onto the floor,
                where they form a curving line which points at the west
                wall. ";
            pointing_coffee_spoons.moveInto(break_room);
            self.moveInto(nil);
        }
        else pass doTake;
    }
    doDrop(actor) = {
        if (self.twitchy) {
            "As the coffee spoons leave your fingers, they fan out and slide
                across the floor, forming a curving line which points at the
                west wall. ";
            pointing_coffee_spoons.moveInto(break_room);
            self.moveInto(nil);
        }
        else pass doDrop;
    }
    doPutIn(actor, io) = {
        if (self.twitchy)
            self.doDrop(actor);
        else pass doPutIn;
    }
    doPutOn(actor, io) = {
        if (self.twitchy)
            self.doDrop(actor);
        else pass doPutIn;
    }
    verDoClean(actor) = {
        if (!self.dirty)
            "The spoons are as clean as possible. ";
        else if (self.location != metal_sink && !self.firstPick)
            "To clean them you will have to put them in the sink. ";
    }
    doClean(actor) = {
        "You ";
        if (!left_handle.isActive && !right_handle.isActive)
            "turn on some water and rinse off the spoons. ";
        else "run the spoons under the water for a while. ";
        "No matter how you scrub, though, the spoons become no cleaner than
            before. ";
        self.dirty = nil;
    }
;

pointing_coffee_spoons: fixedItem
    noun = 'spoon' 'spoons'
    adjective = 'coffee' 'stained' 'pointing'
    sdesc = "pointing coffee spoons"
    ldesc = "The stained coffee spoons form a curving line which points
        at the west wall. "
    hdesc = "A line of stained coffee spoons curve on the floor, pointing
        at the west wall. "
    takedesc = "When you reach down for the spoons, the floor retreats. Dizzy,
        you stumble back. "
    verDoFollow(actor) = {}
    doFollow(actor) = {
        "Haltingly you walk along the curved line of the spoons, arms spread
            wide for balance. You don't look up, even as you see the west wall
            approaching. ";
        if (rope.location == actor && rope.tiedTo == arch_knob) {
            "The rope slides through your fingers. ";
            rope.moveInto(break_room);
        }
        "\bThen you are through the wall and somewhere else. For a brief
            instant you see images of a long drop, but they are gone and
            you are back where you started, in the room of clocks.\b";
        actor.travelTo(clock_room);
        actor.drunk = nil;
        self.moveInto(nil);
        incscore(5);
        drunkAh.solve;
        leaveAh.see;
    }
;

break_room_west_wall: fixeditem
    noun = 'wall'
    adjective = 'west'
    location = break_room
    sdesc = "west wall"
    ldesc = "You can see nothing unusual about the west wall. "
    verDoEnter(actor) = {
        if (pointing_coffee_spoons.location != break_room)
            "You cannot enter that. ";
    }
    doEnter(actor) = {
        pointing_coffee_spoons.doFollow(Me);
    }
;

sofa: chairItem
    notLeaving = true        // Flag for handling the rope. See the
                             //  the room.leaveRoom modification in gript.h.
    statusPrep = "on"
    noun = 'sofa' 'couch'
    adjective = 'floral' 'floral-print'
    location = break_room
    sdesc = "floral-print sofa"
    ldesc = "Its floral pattern has been worn by time and by cigarettes.
        It smells faintly of dogs. "
    smelldesc = "The couch has been lightly sprinkled with eau de Beagle. "
    verDoUnboard(actor) = {
        if (actor.drunk && uberloc(unfrozen_woman) == break_room)
            "After a brief struggle, you determine that you are temporarily
                unable to stand. You glare owlishly at your mutinous legs. ";
        else pass verDoUnboard;
    }
;

easy_chair: chairItem
    noun = 'chair'
    adjective = 'easy' 'battered'
    location = break_room
    sdesc = "easy chair"
    ldesc = "The battered chair cants slightly to one side. Stuffing peeks
        through strained stitching. "
    verDoSiton(actor) = {
        if (unfrozen_woman.location == self)
            "Not while the woman is in the chair. ";
        else pass verDoSiton;
    }
;

bridge: room
    enterFromNorth = nil
    breezeRoom = true
    floating_items = [fake_red_light, fake_bridge, fake_words, fake_chasm]
    sdesc = "Rock Bridge"
    ldesc = {
        "Balancing on the center of the bridge, you doubt the wisdom
            of your position. Below you yawns the chasm. The bridge continues
            to safety to both the north and the south. ";
        if (chains.moving)
            "A breeze whips past you, unnerving you further. ";
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (self.enterFromNorth) {
            self.enterFromNorth = nil;
            if (unfrozen_woman.location == self)
                "\bYou and the woman carefully slip past each other, at times
                    edging close to the drop-off to either side. ";
        }
    }
    exits = 'north and south'
    north = {
        if (unfrozen_woman.location == self)
            "You and the woman do a shuffling dance to pass each other,
                coming frighteningly close to the edge.\b";
        return north_bridge_end;
    }
    south = south_bridge_end
    down = {
        self.jumpAction;
        return nil;
    }
    toBalance = [ 'south along the bridge' south_bridge_end ]
    jumpAction = "No matter how hard you try, your legs refuse to obey you. "
;

north_bridge_end: room
    floating_items = [fake_red_light, fake_bridge, fake_words, fake_chasm]
    breezeRoom = true
    sdesc = "North End of Bridge"
    ldesc = {
        "The north end of the cavern is much like the south end. The
            bridge crosses the cavern to the south, and a doorway leads north.
            An occasional breeze brushes past you";
        if (!chains.moving)
            " and into the chasm";
        ". ";
    }
    exits = 'north and south'
    enterRoom(actor) = {
        if (strand_breeze.location == self)
            notify(strand_breeze, &blow, 2 + RAND(2));
        pass enterRoom;
    }
    north = links_room
    south = {
        if (Me.memory >= 0) {
            "As you place a foot on the bridge, you remember hanging on to
                the side of the cliff above the cage of faeries. Fear rises
                up and grips you; you take several shaky steps away from the
                bridge. Even if you could force yourself onto the bridge,
                you would no doubt fall. ";
            return nil;
        }
        else {
            "You pause for a moment, troubled by something. Then you shake
                it off and continue.\b";
            return bridge;
        }
    }
    toBalance = [ 'onto the bridge' bridge ]
    jumpAction = "You cannot bring yourself to jump into the chasm. "
;

north_bridge_doorway: myDoorway
    location = north_bridge_end
    ldesc = "It leads north. "
    doordest = links_room
;

strand_breeze: fixedItem
    noun = 'breeze'
    location = north_bridge_end
    sdesc = "breeze"
    ldesc = "You stick your hand in the breeze, feeling it slide along your
        skin. "
    touchdesc = {
        if (gloves.isworn)
            "You can barely feel it through the gloves. ";
        else "It is cool as it slides past you. ";
    }
    blow = {
        if (Me.location != north_bridge_end || self.location == nil)
            return;
        "\bA breeze whips around you, carrying thin, filmy strands of some
            material past you and into the chasm. ";
        notify(self, &blow, 2 + RAND(2));
    }
;

strand_decoration: fixeditem
    noun = 'strands'
    adjective = 'filmy' 'thin' 'gauzy' 'floating'
    location = north_bridge_end
    sdesc = "floating strands"
    ldesc = "From time to time, thin, filmy strands of some material move
        past you and into the chasm. "
    takedesc = "You cannot seem to grab hold of them. "
;

links_room: insideRm
    sdesc = "Hazy Room"
    ldesc = "The room is filled with gauzy floating strands which drift around
        the room. Occasionally a group of them drift towards the door, where
        they are caught in a breeze and borne out of the room. On the east wall
        are five groupings of pipe. "
    exits = 'south'
    south = north_bridge_end
    out = north_bridge_end
    firstseen = {
        floating_strands.setup;
        pass firstseen;
    }
    enterRoom(actor) = {
        if (unfrozen_woman.location == self)
            getstrandsAh.see;
        pass enterRoom;
    }
    toBalance = [ 'out of the room to the south' north_bridge_end ]
;

pipe_groupings: decoration
    noun = 'pipe' 'pipes' 'grouping' 'groupings'
    adjective = 'pipe' 'pipes'
    location = links_room
    sdesc = "pipe"
    ldesc = "The east wall is studded with short sections of PVC pipe leading
        from somewhere. They are loosely grouped into five regions.
        Occasionally a tangle of the strands will slide out of the pipes and
        begin floating about the room with the others. "
;

floating_strands: fixedItem
    listPointer = &strandWordList1
    listNumber = 1
    strandRealWords = [ 'doll' 'balance' 'pipe' 'chain' 'lever' 'stymie'
        'break' 'restart' 'remove' 'tangle' ]
    strandOtherWords = [ 'faerie' 'dog' 'man' 'pawn' 'cage' 'fly' 'fall'
        'open' 'carve' 'climb' ]
    strandWordList1 = []
    strandWordList2 = []
    strandsMade = []
    womanSeenStrandTaken = nil
    noun = 'strand' 'strands'
    adjective = 'filmy' 'thin' 'gauzy' 'floating'
    location = links_room
    sdesc = "floating strands"
    ldesc = "The strands brush past and around you. Surprisingly, you breathe
        none of them in. "
    setup = {
        self.strandWordList1 += shuffle(self.strandRealWords);
        self.strandWordList2 += shuffle(self.strandOtherWords);
    }
    verDoTake(actor) = {
        if (unfrozen_woman.location == actor.location)
            self.womanSeenStrandTaken = true;
    }
    doTake(actor) = {
        local word, obj;

        if (self.listNumber > length(self.(self.listPointer))) {
            "The strands dart away from you as you try to grab them. ";
            return;
        }
        word = self.(self.listPointer)[self.listNumber];
        "You grab one of the strands. As you touch it, you hear the word
            \"<<word>>\" echo eerily in your head. ";
        self.listNumber++;
        obj = new taken_strand;
        addword(obj, &adjective, word);
        obj.myWord = word;
        self.strandsMade += obj;
        obj.moveInto(actor);
    }
;

class taken_strand: item
    isStrand = true
    myWord = ''
    noun = 'strand'
    plural = 'strands'
    sdesc = "'<<self.myWord>>' strand"
    ldesc = "The strand is thin and translucent. It quivers slightly. "
    verDoTake(actor) = { "You already have <<self.thedesc>>. "; }
    verDoDrop(actor) = {}
    doDrop(actor) = {
        "When you let go of the strand, it floats away from you. ";
        floating_strands.strandsMade -= self;
        delete self;
    }
    doPutOn(actor, io) = { self.doDrop(actor); }
    doPutIn(actor, io) = { self.doDrop(actor); }
;


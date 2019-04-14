/*
    Intlude, the interludes of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: intlude.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

withdrawal: function;
unfulfilledInt1: function;

class inner_door: doorItem
    stage = 0        // It's in an interlude
    ldesc = "The door has a knob with which it can be locked
        or unlocked.  It is currently <<self.wordDesc>><<self.islocked ? 
        " and locked" : "">>. "
    islockable = true
;

class outer_door: doorItem
    stage = 0
    ldesc = "The door has a small keyhole beneath its
        knob. The door is currently <<self.wordDesc>><<self.islocked ? 
        " and locked" : "">>. "
    islockable = true
    mykey = dog                // No player-accessible key
;

intlude_keyhole: wallpaper, decoration
    noun = 'keyhole' 'hole'
    sdesc = "keyhole"
    ldesc = "A small keyhole in the door. "
    verDoLookthru(actor) = {}
    doLookthru(actor) = { "You can see nothing through the keyhole. "; }
;

op_theatre: droom, insideRm
    noWall = true
    noun = 'theatre'
    sdesc = "Operating Theatre"
    firstdesc = "Your eyes open reluctantly under the glare of light
        above you. Memory comes flooding back:\ the clinic,
        Dr.\ Boozer, the experimental drug to wean you from nicotine.\b
        They'll take away the drug. Part of you pronounces this a
        wonderful idea. Another, louder, part of you disagrees, thinks that
        something _important_ is happening in your head, something you
        shouldn't interrupt.\b
        The theatre is reassuringly familiar, distracting you from your
        thoughts. You are reclining on a padded chair, much like those
        dentists use. To your left, monitors softly wheep in response to
        signals from the leads attached to you. The north wall boasts <<
        op_theatre_door.aWordDesc>> door, while the west wall is mostly
        mirror. "
    seconddesc = "The operating theatre is dominated by a padded chair in
        its center, a light just above it. On the north wall, just to
        the left of the door, is a bank of monitors. The west wall is
        mostly mirror. "
    exits = 'north'
    listendesc = {
        "You ";
        if (monitors.isActive) {
            "hear the monitors ";
            if (!monitor_leads.isworn)
                "shrilling loudly. ";
            else "bleep and wheep, occasionally letting out a piercing
                whistle. ";
        }
        else "don't hear anything. ";
    }
    north = {
        if (monitor_leads.location == Me) {
            "Not while you are attached to the monitors. ";
            return nil;
        }
        return op_theatre_door;
    }
    out = (self.north)
    nrmLkAround(v) = {
        inherited.nrmLkAround(v);
        self.isseen = true;
    }
;

op_theatre_door: inner_door
    location = op_theatre
    isopen = true
    otherside = hall_op_door
    doordest = clinic_hall1
;

padded_chair: chairItem
    stage = 0
    reachable = [padded_chair monitors]
    noun = 'chair'
    plural = 'chairs'
    adjective = 'padded'
    location = op_theatre
    sdesc = "padded chair"
    ldesc = "It reclines slightly, its padded surface glistening wetly in the
        light. "
    touchdesc = "Your finger slides over its plastic surface. "
;

light_on_a_stick: decoration
    stage = 0
    noun = 'light'
    location = op_theatre
    sdesc = "light"
    ldesc = {
        "It looms over ";
        if (Me.location == padded_chair)
            "you";
        else "the padded chair";
        ", harshly illuminating the room and all in it. ";
    }
;

monitors: switchItem
    isThem = true
    isActive = true
    noun = 'monitor'
    plural = 'monitors'
    location = op_theatre
    sdesc = "monitors"
    ldesc = {
        "The monitors are stacked next to the chair, facing it. ";
        if (self.isActive) {
            "Lights play across their surfaces, and a bright spot traces a ";
            if (monitor_leads.isworn)
                "jagged heartbeat";
            else "straight line";
            " across a square screen. ";
        }
        else "Dark lights decorate their surface. ";
        "Running from one of the monitors are several wires, leads attached to
            their other ends. ";
    }
    listendesc = {
        if (self.isActive) {
            if (!monitor_leads.isworn)
                "They are shrilling loudly. ";
            else "They bleep and wheep, occasionally letting out a piercing
                whistle. ";
        }
        else "It is tomblike in its silence. ";
    }
    doSwitch(actor) = {
        inherited.doSwitch(actor);
        if (self.isActive) {
            "The screen begins tracing out ";
            if (monitor_leads.isworn)
                "your heartbeat";
            else {
                "a flat line and shrilling loudly";
                monitor_leads.checkFlatline;
            }
            ". ";
        }
        else {
            "The screen and lights go dark. ";
            monitorsAh.solve;
        }
    }
    doTurnon(actor) = {
        self.isActive = true;
        "You turn on the monitors. The screen begins tracing out ";
        if (monitor_leads.isworn)
            "your heartbeat";
        else {
            "a flat line and shrilling loudly";
            monitor_leads.checkFlatline;
        }
        ". ";
    }
    doTurnoff(actor) = {
        self.isActive = nil;
        "You turn off the monitors. ";
        if (!monitor_leads.isworn)
            "They stop shrilling loudly. ";
        monitorsAh.solve;
    }
;

monitor_leads: clothingItem
    isThem = true
    autoTakeOff = nil
    noun = 'lead' 'wire' 'electode'
    plural = 'leads' 'wires' 'electrodes'
    adjective = 'medical'
    sdesc = "medical leads"
    ldesc = {
        "Round, cold; used for monitoring heartbeat and other vital
            functions. The leads are attached by wires to the monitors on one
            end";
        if (self.isworn)
            " and you";
        else ", dangling free";
        " on the other. ";
    }
    hdesc = "Hanging from the monitors are several medical leads. "
    takeOffDesc = {
        "With a slight sucking sound the leads come free from your temples
            and from your wrists. ";
        if (monitors.isActive) {
            "The monitors immediately begin shrilling loudly, the screen
                tracing out a flat line. Startled, you drop the leads. ";
            monitor_leads.checkFlatline;
        }
        else "You drop them, leaving them dangling from the monitors. ";
        self.moveInto(op_theatre);
    }
    putOnDesc = {
        "You place the leads on your temple and wrist in the places
            Dr.\ Boozer put them. ";
        if (monitors.isActive)
            "The monitors stop shrilling. ";
    }
    doSynonym('Unwear') = 'Detach' 'Unplug'
    checkFlatline = {
        if (!getfuse(self, &flatline))
            notify(self, &flatline, 2);
    }
    flatline = {
        if (Me.location == op_theatre) {
            "\bYou hear footsteps outside the theatre, followed by ";
            if (op_theatre_door.islocked)
                "the rattle of a key in the door lock and ";
            "Dr.\ Boozer's entrance. ";
        }
        else "\bYou hear footsteps behind you and turn to see Dr.\ Boozer
            running down the hall. When he sees you, he pulls up short. ";
        "His eyes, crinkled with concern, relax when he sees you awake.
            \"Thank God,\" he says. \"I thought I'd heard you flatline.\"
            You begin to crumple but Dr.\ Boozer moves to support you,
            surreptitiously taking your pulse. \"Are you recovered?\"\ he
            asks worriedly.\b
            You glance down, staring past your trembling hands. You find
            you don't know how to answer. ";
        die();
    }
;

first_observation_mirror: decoration
    stage = 0
    noun = 'mirror' 'wall'
    adjective = 'west'
    location = op_theatre
    sdesc = "west wall"
    ldesc = "The west wall is mostly mirror, reflecting the chair
        and the bright light over it. "
    verDoLookin(actor) = {}
    doLookin(actor) = {
        "You spend several moments gazing at your reflection and its haggard,
            sunken eyes. ";
    }
    verDoLookthru(actor) = {}
    doLookthru(actor) = {
        "By cupping your hands around your eyes you can see through the
            mirror to the room beyond, though you can make out no details. ";
    }
;

iv_stand: complex
    stage = 0
    contentsVisible = true
    noun = 'stand'
    adjective = 'iv'
    location = op_theatre
    sdesc = "IV stand"
    hdesc = "Standing next to the padded chair is an IV stand, its needle
        dangling from it. "
    ldesc = "Hanging from the stand is a bag filled with a clear liquid--the
        nicotine antiaddiction drug. A needle hangs from the bag. "
    adesc = "an IV stand"
;

iv_bag: fixeditem
    stage = 0
    noun = 'bag' 'label'
    adjective = 'plastic'
    location = iv_stand
    sdesc = "plastic bag"
    ldesc = "The plastic bag hangs from the IV stand. It is filled with
        a clear liquid. Written on it in black magic marker is 'Nicor 100mL.' "
    takedesc = "It's attached to the IV stand. "
    verDoRead(actor) = {}
    doRead(actor) = {
        "The words 'Nicor 100mL' are written across the bag in black magic
            marker. ";
    }
;

iv_liquid: item
    stage = 0
    noun = 'liquid' 'drug'
    adjective = 'clear'
    location = iv_stand
    sdesc = "clear liquid"
    ldesc = "The drug which should wean you from your love of nicotine. "
    dobjGen(a, v, i, p) = {
        if (v.touch) {
            "The bag prevents you. ";
            exit;
        }
    }
    iobjGen(a, v, d, p) = { self.dobjGen(a, v, d, p); }
;


needle: fixeditem
    noun = 'needle'
    location = iv_stand
    sdesc = "needle"
    ldesc = "Pointed, sharp. Liquid glistens from its tip. "
    takedesc = "It's attached to the IV stand. "
    verDoWear(actor) = {}
    doWear(actor) = {
        "Wincing slightly in anticipation, you jab the needle into a
            prominent vein. Your summer job in the hospital
            pays off:\ the needle slides home on the first try.\b
            Ice cold, the drug races up your arm and through your chest,
            numbing you. Fire hot, the next wave of the drug invades your
            system. The walls around you blur, fade away as the world runs
            in technicolor streaks...\n";
        if (Me.location == supply_crates) {
            if (!supplies_door.isopen) {
                notify(hospitalDaemon, &passersBy, 5 + RAND(2));
                if (dog.location != nil) {
                    dog.age = 1;
                    dog.namedAge = 'young dog';
                    dog.isWaiting = true;
                    if (rope.tiedTo == dog) {
                        rope.tiedTo = nil;
                        rope.moveInto(nil);
                    }
                    dog.moveInto(admitting);
                }
                Me.noWithdrawal = true;    // Stop the withdrawal function
                radioDaemon.playlist = &playlist2;    // Reset the radio
                Me.stage = '2a';           // Which stage I'm in
                pauseAndClear();
                "\b\(Fit the Second\):\ Revisit\b\b"; // Originally "Replay"
                makeQuote('"play of light/a photograph/the way I used to be\n\
some half-forgotten stranger/doesn\'t mean that much to me"', 'Rush');
                moveAllCont(Me, nil);
                hideAh.solve;
                hide1Ah.solve;
                hide2Ah.solve;
                actor.travelTo(green4);
                old_woman.wantheartbeat = true;
                return;
            }
            unfulfilledInt1(0);
        }
        if (Me.location == attic) {
            if (attic_ladder.isopen)
                unfulfilledInt1(1);
            else if (single_chair.location == clinic_hall3)
                unfulfilledInt1(2);
            notify(schoolDaemon, &passersBy, 5 + RAND(2));
            notify(janitor, &firstMove, 2);
            Me.noWithdrawal = true;    // Stop the withdrawal function
            if (dog.location != nil) {
                dog.age = 1;
                dog.namedAge = 'young dog';
                dog.isWaiting = true;
                dog.wantheartbeat = nil;
                if (rope.tiedTo == dog) {
                    rope.tiedTo = nil;
                    rope.moveInto(nil);
                }
                dog.moveInto(nw2_end);
            }
            Me.noWithdrawal = true;        // Stop the withdrawal function
            radioDaemon.playlist = &playlist2;        // Reset the radio
            buddy.wantheartbeat = true;
            Me.stage = '2b';
            pauseAndClear();
            "\b\(Fit the Second\):\ Revisit\b\b"; // Originally "Replay"
            makeQuote('"play of light/a photograph/the way I used to be\n\
some half-forgotten stranger/doesn\'t mean that much to me"', 'Rush');
            moveAllCont(Me, nil);
            hideAh.solve;
            hide1Ah.solve;
            hide2Ah.solve;
            actor.travelTo(mid1_hall_one);
            return;
        }
        unfulfilledInt1(3);
    }
    verDoPutIn(actor, io) = {
        if (io == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (!io.isBodypart) pass verDoPutIn;
    }
    verDoInjectIn(actor, io) = {
        if (io == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (!io.isBodypart)
            "There's no need to stick the needle in <<io.thedesc>>. ";
    }
    doInjectIn(actor, io) = { io.ioPutIn(actor, self); }
    verIoInjectWith(actor) = {}
    ioInjectWith(actor, dobj) = {
        if (dobj == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (!dobj.isBodypart)
            "There's no need to stick the needle in <<dobj.thedesc>>. ";
        else dobj.ioPutIn(actor, self);
    }
;

clinic_hall1: insideRm
    floating_items = [intlude_keyhole]
    sdesc = "Hallway"
    ldesc = "The hallway runs west to east; the east end of the hall curves
        south towards reception. \^<<hall_op_door.aWordDesc>> door lies to the
        south, a closed door to the north. "
    exits = 'east and west'
    north = hall_op2_door
    south = hall_op_door
    east = { "You begin walking east, then realize that that way lies
        reception. You quickly retrace your steps. "; return nil; }
    west = clinic_hall2
;

hall_op_door: outer_door
    adjective = 'south'
    location = clinic_hall1
    sdesc = "south door"
    isopen = true
    otherside = op_theatre_door
    doordest = op_theatre
;

hall_op2_door: outer_door
    adjective = 'north'
    location = clinic_hall1
    sdesc = "north door"
    islocked = true
;

clinic_hall2: insideRm
    sdesc = "Hallway"
    ldesc = "The hallway bends here, running north and east. To the south
        is <<hall_obs_door.aWordDesc>> door. "
    exits = 'north, south, and east'
    north = clinic_hall3
    south = hall_obs_door
    east = clinic_hall1
;

hall_obs_door: outer_door
    adjective = 'south'
    location = clinic_hall2
    sdesc = "south door"
    otherside = obs_door
    doordest = observation
;

observation: insideRm
    noWall = true
    sdesc = "Observation Room"
    ldesc = "The observation room's only notable feature is the smoky glass
        window on its east wall. Several chairs face it. "
    exits = 'north'
    north = obs_door
    out = obs_door
;

obs_door: inner_door
    location = observation
    otherside = hall_obs_door
    doordest = clinic_hall2
;

smoky_window: decoration
    stage = 0
    noun = 'wall' 'window'
    adjective = 'east' 'smoky' 'glass'
    location = observation
    sdesc = "glass window"
    ldesc = "The east wall contains a window which looks into the operating
        theatre where you awoke. "
    verDoLookin(actor) = {}
    doLookin(actor) = {
        "You see the operating theatre you recently left. ";
    }
    doSynonym('Lookin') = 'Lookthru'
;

group_of_chairs: chairItem
    stage = 0
    isThem = true
    chairGotten = nil
    noun = 'chair'
    plural = 'chairs'
    adjective = 'group' 'plastic'
    location = observation
    sdesc = "group of chairs"
    ldesc = "The chairs, plastic and wheeled, face the glass window. "
    verDoTake(actor) = {
        if (self.chairGotten)
            "One chair is plenty. ";
    }
    doTake(actor) = {
        self.chairGotten = true;
        "You wheel one chair away from the group. ";
        single_chair.moveInto(observation);
        setit(single_chair);
    }
    doSynonym('Take') = 'Push' 'Pull' 'Move'
    verDoMoveN(actor) = { self.verDoTake(actor); }
    doMoveN(actor) = {
        single_chair.moveInto(self.location);
        if (single_chair.check_dir(&north))
            single_chair.doMoveN(actor);
        else "The door prevents you. ";
    }
;

single_chair: rollItem, chairItem
    stage = 0
    standingOn = nil
    reachable = [attic_cord, single_chair]
    statusPrep = {
        if (self.standingOn)
            "on";
        else "in";
    }
    outOfPrep = {
        if (self.standingOn)
            "down from";
        else "out of";
    }
    noun = 'chair'
    plural = 'chairs'
    adjective = 'single' 'plastic'
    sdesc = "single chair"
    ldesc = "It is plastic, with wheels on its base. "
    heredesc = {
        if (self.location == attic_cord.location)
            "Under the cord is a plastic chair. ";
        else if (self.location == observation)
            "One of the chairs has been pushed away from the others. ";
        else "There is a plastic chair here. ";
    }
    takedesc = "The effort of trying to pick up the chair doubles you over
        with nausea. "
    down = (self.location)
    out = (self.location)
    movedesc(dir) = "You push the chair <<dir>>, then follow it.\b"
    doUnboard(actor) = {
        inherited.doUnboard(actor);
        self.standingOn = nil;
    }
    verDoMoveE(actor) = {
        if (actor.location == self)
            "%You% will have to get <<self.outOfPrep>> the chair first. ";
        else if (actor.location == clinic_hall1)
            "You start to wheel the chair down the hall, then realize that
                the waiting room waits for you at the end. You quickly wheel
                the chair back. ";
        else if (!self.check_dir(&east))
            "You are blocked in that direction. ";
    }
    verDoStandon(actor) = {
        if (actor.location == self) {
            if (self.standingOn)
                "%You're% already standing on the chair. ";
            else "Not until %you% stop%s% sitting on the chair. ";
        }
    }
    doStandon(actor) = {
        "%You% climb on the chair. It wavers under your feet, unsure of
            whether or not to hold you. ";
        self.standingOn = true;
        actor.moveInto(self);
    }
    doSynonym('Standon') = 'Climb'
;

clinic_hall3: room
    floating_items = [intlude_keyhole]
    sdesc = "Hallway"
    ldesc = {
        "The hallway ends to the north. Doors lead north and east. ";
        if (hall_attic_ladder.location != self)
            "A cord hangs from an outlined rectangle in the ceiling. ";
        else "A ladder leads up into an open hole in the ceiling. ";
    }
    ceildesc = {
        if (hall_attic_ladder.location == clinic_hall3)
            "A ladder leads up to it. ";
        else "It contains an outlined rectangle, at one end of which is a
            cord. ";
    }
    jumpAction = "Your feet barely clear the ground, so weak are you. The
        cord dangles tauntingly out of reach. "
    exits = {
        "You can go north, south, ";
        if (hall_attic_ladder.location == self)
            "east, and up. ";
        else "and east. ";
    }
    north = offices_door
    south = clinic_hall2
    east = hall_supplies_door
    up = {
        if (hall_attic_ladder.location == self) return attic;
        return self.noexit;
    }
;

hall_attic_ladder: fixedItem
    stage = 0
    noun = 'ladder'
    sdesc = "ladder"
    ldesc = "It leads up into the ceiling. "
    verDoClimb(actor) = {}
    doClimb(actor) = { actor.travelTo(attic); }
;

hall_attic_rectangle: distantItem
    stage = 0
    noun = 'rectangle'
    adjective = 'outlined'
    location = clinic_hall3
    sdesc = "rectangle"
    ldesc = "The rectangle is outlined in the ceiling above. "
;

attic_cord: fixedItem
    stage = 0
    noun = 'cord'
    location = clinic_hall3
    sdesc = "cord"
    ldesc = {
        "It dangles from the ceiling";
        if (!single_chair.standingOn)
            " far above your head";
        ". ";
    }
    dobjGen(a, v, i, p) = {
        if (v != inspectVerb && !single_chair.standingOn) {
            "The cord is too far above your head. ";
            exit;
        }
    }
    iobjGen(a, v, d, p) = {
        self.dobjGen(a, v, d, p);
    }
    verDoPull(actor) = {
        if (!single_chair.standingOn)
            "The cord is too far above your head. ";
    }
    doPull(actor) = {
        "You reach up and, with an effort which leaves you trembling,
            pull the cord down. The rectangle unfolds, a ladder disgorging
            from the attic above. ";
        self.moveInto(nil);
        attic_rectangle.moveInto(nil);
        hall_attic_ladder.moveInto(clinic_hall3);
    }
    takedesc = {
        if (!single_chair.standingOn)
            "It's too far above your head.";
        else self.doPull(Me);
    }
;

offices_door: outer_door
    adjective = 'north'
    location = clinic_hall3
    sdesc = "north door"
    islocked = true
;

hall_supplies_door: outer_door
    adjective = 'east'
    location = clinic_hall3
    sdesc = "east door"
    otherside = supplies_door
    doordest = supplies
;

supplies: insideRm
    sdesc = "Supplies Room"
    ldesc = "The walls of the room are lined with shelves, all of which are
        neatly stocked with supplies. \^<<supplies_door.aWordDesc>> door
        is set in the west wall. "
    exits = 'west'
    west = supplies_door
    out = supplies_door
;

supplies_door: inner_door
    location = supplies
    otherside = hall_supplies_door
    doordest = clinic_hall3
;

supply_shelves: decoration
    stage = 0
    isThem = true
    noun = 'shelf'
    plural = 'shelves'
    location = supplies
    sdesc = "shelves"
    ldesc = "The shelves hold row after row of supplies. "
;

fake_supplies: decoration
    stage = 0
    isThem = true
    noun = 'supply' 'needle' 'glove'
    plural = 'supplies' 'needles' 'gloves'
    adjective = 'latex'
    location = supplies
    sdesc = "supplies"
    ldesc = "Nearly random supplies, such as needles and latex gloves. Part
        of the supplies are still in crates, piled high near the northeast
        corner. "
;

supply_crates: fixeditem, nestedroom
    stage = 0
    isThem = true
    statusPrep = "behind"
    reachable = [ supply_crates ]
    noun = 'crate'
    plural = 'crates'
    location = supplies
    sdesc = "crates"
    ldesc = "The crates are stacked almost to the ceiling by the northeast
        corner, leaving a small cubby behind them. "
    exits = 'west'
    north -> supplies
    south -> supplies
    east  -> supplies
    west  -> supplies
    up    -> supplies
    down  -> supplies
    ne    -> supplies
    nw    -> supplies
    se    -> supplies
    sw    -> supplies
    in    -> supplies
    out   -> supplies
    noexit = { "%You% can't go that way. "; return nil; }
    verDoLookbehind(actor) = {
        "There is a small cubby behind the crates. ";
    }
    verDoHideBehind(actor) = {
        if (actor.location == self)
            "%You're% already hiding behind the crates. ";
    }
    doHideBehind(actor) = {
        "You hunker down behind the crates. They are just tall enough to hide
            you";
        if (iv_stand.location == actor)
            " and the IV stand";
        ". ";
        actor.moveInto(self);
    }
    verDoUnhideBehind(actor) = {
        if (actor.location != self)
            "But you're not behind the crates. ";
    }
    doUnhideBehind(actor) = { self.doUnboard(actor); }
    doSynonym('HideBehind') = 'Enter'
;

supply_cubby: fixedItem
    noun = 'cubby'
    adjective = 'small'
    location = supplies
    sdesc = "cubby"
    ldesc = "A small space behind the crates. "
    verDoEnter(actor) = {}
    doEnter(actor) = {
        supply_crates.doHideBehind(actor);
    }
    doSynonym('Enter') = 'Board'
;

attic: insideRm
    sdesc = "Attic"
    ldesc = {
        "The attic is, apart from several cardboard boxes, amazingly free of
            clutter. ";
        if (attic_ladder.isopen)
            "A ladder leads down through a hole in the floor. ";
        else "A ladder lies affixed to a rectangle on the floor. ";
    }
    exits = {
        if (attic_ladder.isopen)
            "You can go down. ";
        else "There are no obvious exits. ";
    }
    smelldesc = "You fill your nose with dust, making you sneeze. "
    down = {
        if (attic_ladder.isopen) return clinic_hall3;
        return self.noexit;
    }
    out = (self.down)
;

attic_ladder: fixedItem
    stage = 0
    isopen = true
    noun = 'ladder' 'door' 'trapdoor' 'entrance'
    location = attic
    sdesc = "ladder"
    ldesc = {
        if (self.isopen) "The ladder leads down. ";
        else "The ladder lies folded on the floor. ";
    }
    verDoClimb(actor) = {
        if (!self.isopen)
            "Currently the ladder leads nowhere. ";
    }
    doClimb(actor) = { actor.moveInto(clinic_hall3); }
    verDoPush(actor) = {
        if (self.isopen) "Pushing the ladder has no further effect. ";
    }
    doPush(actor) = {
        self.isopen = true;
        attic_rectangle.moveInto(nil);
        "You push the ladder down, opening the exit, until the ladder
            reaches the floor below. ";
    }
    verDoPull(actor) = {
        if (!self.isopen) "Pulling the ladder has no further effect. ";
    }
    doPull(actor) = {
        self.isopen = nil;
        attic_rectangle.moveInto(attic);
        "You reach down and pull the ladder up, closing the exit from the
            attic. ";
    }
    doSynonym('Pull') = 'Close' 'Take'
    doSynonym('Push') = 'Open'
;

attic_rectangle: decoration
    stage = 0
    noun = 'rectangle'
    sdesc = "rectangle"
    ldesc = "The rectangle serves to close the attic off from the rest of the
        hall. "
;

attic_boxes: readable, decoration
    stage = 0
    noun = 'box' 'label'
    plural = 'boxes' 'labels'
    adjective = 'cardboard'
    location = attic
    sdesc = "cardboard boxes"
    ldesc = "They have been used repeatedly, judging from the many crossed-out
        labels which cover their surfaces. "
    readdesc = "There are so many labels and so many crossed-out scribblings
        that the sum total is unreadable. "
;

gurney: droom, insideRm
    stage = 0
    noun = 'gurney'
    sdesc = "On a Gurney"
    firstdesc = "The ceiling above you looms, fluorescent lights glaring
        down at you. You've been strapped to a gurney and reattached to
        monitors. Ambulance workers run alongside you, occasionally bending
        over to check your condition. Your ill-fated IV has been brought along
        for the ride, its needle bouncing against your hand from time to
        time. "
    seconddesc = "You've been strapped down on a gurney and covered in a
        blanket. Around you, ambulance workers run along side, guiding you to
        the ambulance. Your IV is attached to the side of the gurney, the
        needle occasionally bouncing against your hand. "
    roomAction(a, v, d, p, i) = {
        if (v == wearVerb || v == takeVerb ||
            ((v == putVerb || v == injectVerb || v == insertVerb) &&
            p == inPrep)) {
            if (d != gurney_needle) {
                "You are strapped too tightly to the gurney. ";
                exit;
            }
        }
        else if (v == injectVerb && p == withPrep) {
            if (i != gurney_needle) {
                "You are strapped too tightly to the gurney. ";
                exit;
            }
        }
        else if (v == askVerb || v == tellVerb || v == sayVerb ||
            v == yellVerb) {
            "Your voice eemerges as an unintelligible croak. ";
            exit;
        }
        else if (!v.issysverb && (v != inspectVerb) && (v != lookVerb)
            && (v != waitVerb) && (v != sleepVerb) && (v != smellVerb) &&
            (v != listenVerb) && (v != listentoVerb)) {
            "You are strapped too tightly to the gurney. ";
            exit;
        }
        pass roomAction;
    }
    setup = {
        buddyAh.solve;
        insertNeedleAh.see;
        pauseAndClear();
        "\b\(Interlude\)\b\b";
        moveAllCont(Me, nil);
        gloves.isworn = nil;
        thermoelectric_cooler.moveInto(nil);  // To avoid embarassing problems
        fuzzy.moveInto(nil);                  // Ditto
        force_field_machine.moveInto(nil);
        dog.clearProps;
        dog.wantheartbeat = nil;
        notify(ambulance_workers, &daemon, 2);
        Me.stage = '0';
        Me.travelTo(self);
    }
;

gurney_gurney: fixedItem
    noun = 'gurney'
    location = gurney
    sdesc = "gurney"
    ldesc = "It lies beneath you. "
;

gurney_blanket: fixedItem
    noun = 'blanket'
    location = gurney
    sdesc = "blanket"
    ldesc = "It covers you, keeping you uncomfortably warm. "
;

gurney_monitors: fixedItem
    isThem = true
    stage = 0
    noun = 'monitor'
    plural = 'monitors'
    location = gurney
    sdesc = "monitors"
    ldesc = "The monitors, small and boxy, are attached to the gurney. "
    listendesc = "Their bleeps and wheeps are several octaves lower than they
        should be. "
;

ambulance_workers: fixedItem
    stage = 0
    daemonNumber = 0
    noun = 'worker'
    plural = 'workers'
    adjective = 'ambulance'
    location = gurney
    sdesc = "ambulance workers"
    ldesc = "They work around you, but you cannot hear what they say. "
    actorAction(v, d, p, i) = {
        "They can't seem to hear you. ";
        exit;
    }
    // The daemon that talks while the player is on the gurney
    daemon = {
        "\b";
        switch (daemonNumber++) {
            case 0:
            "One of the workers bends down and shines a light in your left eye.
                Your reflexive blink seems to take forever. ";
            break;

            case 1:
            "Two of the medical workers confer over your head, their lips
                moving slowly. No sound reaches you. ";
            break;

            case 2:
            "Ahead of you, the clinic exit creeps closer. ";
            break;

            case 3:
            "You are wheeled outside and into an ambulance, its roof cutting
                off the light of the sun. Blackness descends, and you fall
                into a dreamless sleep. ";
            die();
        }
        notify(self, &daemon, 3);
    }
;

gurney_lights: distantItem
    stage = 0
    noun = 'light' 'lights'
    adjective = 'fluorescent'
    location = gurney
    sdesc = "fluorescent lights"
    ldesc = "As the gurney moves down the hall they inch past, making
        alternating bands of light and dark. "
;

gurney_iv_stand: fixedItem
    stage = 0
    noun = 'stand' 'bag'
    adjective = 'iv'
    location = gurney
    sdesc = "IV stand"
    ldesc = "It has been attached to the gurney, most likely for the hospital
        staff to analyze the drug. "
;

gurney_needle: fixedItem
    stage = 0
    noun = 'needle'
    location = gurney
    sdesc = "needle"
    ldesc = "Pointed, sharp. Liquid glistens from its tip. "
    takedesc = "You can grab it with your fingers, but can't hold it for long
        because of the awkward way your arms are strapped down. "
    verDoWear(actor) = {}
    doWear(actor) = {
        "By a series of excruciating contortions, you can just reach the
            needle and jab it in your hand. The familiar waves of heat and
            cold race through your body. The lights overhead approach and
            recede, light and dark, light and dark, blending into...\n";
        unnotify(ambulance_workers, &daemon);
        insertNeedleAh.solve;
        pauseAndClear();
        "\b\(Fit the Third\):\ Renascence\b\b";
        makeQuote('"When I was a child/I caught a fleeting glimpse\n\
Out of the corner of my eye"', 'Pink Floyd');
        moveAllCont(Me, nil);
        Me.travelTo(bedroom_bed);
        bedroom.enterRoom(Me);
        if (dog.location != nil) {
            dog.age = 2;
            dog.namedAge = 'dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            if (rope.tiedTo == dog) {
                rope.tiedTo = nil;
                rope.moveInto(nil);
            }
            dog.moveInto(top_of_hill);
        }
        radioDaemon.playlist = &playlist3;
        Me.stage = 3;
        roomAh.see;
    }
    verDoPutIn(actor, io) = {
        if (io == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (io != hands)
            "You can't reach <<io.thedesc>> to put the needle in it. ";
    }
    verDoInjectIn(actor, io) = {
        if (io == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (io != hands)
            "You can't reach <<io.thedesc>> to put the needle in it. ";
    }
    doInjectIn(actor, io) = { io.ioPutIn(actor, self); }
    verIoInjectWith(actor) = {}
    ioInjectWith(actor, dobj) = {
        if (dobj == Me)
            "You'll have to be more specific about where you want to stick
                the needle. ";
        else if (dobj != hands)
            "You can't reach <<dobj.thedesc>> to put the needle in it. ";
        else dobj.ioPutIn(actor, self);
    }
;

my_hospital_room: insideRm, droom
    sdesc = "Hospital Room"
    firstdesc = "The white ceiling slowly recedes, eventually settling down
        to a reasonable distance. Mindful of a disorienting dizziness,
        you turn your head slowly from side to side, taking in the sight of
        a hospital room. <<self.seconddesc>> "
    seconddesc = {
        "The room is dim, its only light the sunlight leaking through the
            window whose curtains are ";
        if (curtains.isopen) "thrown wide";
        else "drawn";
        ". Equipment surrounds your bed in the center of the room. ";
    }
;

my_hospital_window: distantItem
    stage = 0
    noun = 'window'
    location = my_hospital_room
    sdesc = "window"
    ldesc = {
        "The window is ";
        if (curtains.isopen)
            "swathed in closed curtains. ";
        else "outlined in curtains. ";
    }
;

my_hospital_sun: distantItem
    stage = 0
    noun = 'sun' 'light' 'sunlight'
    location = my_hospital_room
    sdesc = "sunlight"
    ldesc = "Sunlight leaks into the room through the window. "
;

my_hospital_bed: bedItem, insideRm
    stage = 0
    noun = 'bed'
    adjective = 'hospital'
    location = my_hospital_room
    sdesc = "hospital bed"
    ldesc = {
        if (Me.location == self)
            "It is most notable for holding you. ";
        else "A rumpled hospital bed, bearing the fading impression of your
            body. ";
    }
    verDoUnboard(actor) = {
        "You try to get out of the bed, but find you are too dizzy. ";
    }
    setup = {
        pauseAndClear();
        "\b\(Interlude\)\b\b";
        moveAllCont(Me, nil);
        "White surrounds you, envelops you. In front of you your
            father, now an old man, sits before a chess board. He looks up
            from contemplating his next move and glances at you. He looks
            back to the board and tips a pawn over with deliberation. Then
            you are falling, the white closing in.\n";
        pauseAndClear();
        "\b\(Interlude, Again\)\b\b";
        Me.stage = '0';
        Me.travelTo(self);
        if (dog.location != nil) {
            dog.age = 3;
            dog.namedAge = 'dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            if (rope.tiedTo == dog) {
                rope.tiedTo = nil;
                rope.moveInto(nil);
            }
            dog.moveInto(argument_room);
        }
        curtains.moveInto(my_hospital_room);
        my_hospital_room.enterRoom(Me);
        notify(butler, &setup, 3);
    }
;

my_hospital_equipment: decoration
    stage = 0
    noun = 'equipment'
    adjective = 'arcane' 'medical'
    location = my_hospital_room
    sdesc = "medical equipment"
    ldesc = "The equipment gathers around your bed, as if to watch the progress
        of illness. "
    listendesc = "The equipment whistles and beeps."
;

withdrawal: function(n)
{
    if (Me.noWithdrawal) {
        Me.noWithdrawal = nil;
        return;
    }
    "\b";
    switch(n) {
        case 1:
            "You feel hot, then cold several times in succession.";
            break;
        case 2:
            "Your hands begin twitching uncontrollably. You fight to keep them
                still.";
            break;
        case 3:
            "The fever and chills return, accompanied by a fierce pain behind
                your eyes.";
            break;
        case 4:
            "A cramp doubles you over, as if you were hit in the stomach. It
                takes all of your control to straighten up against the pain. ";
            break;
        case 5:
            "A particularly violent spasm ";
            if (Me.location.ischair)
                "wracks your body. You writhe in the chair. ";
            else "throws you to the floor. You stand again with some effort.";
            break;
        case 6:
            "All of your symptoms attack at once:\ fever, chills, cramps,
                pain. Your vision dims as you slump to the floor. Time passes
                without you noticing.\b
                The feel of cool air brings you back around. Above you,
                blue sky streaks by. A face intrudes, looking down at you and
                mouthing words you cannot hear. A glance down
                shows you strapped to a gurney. When you look up again, the
                sky has been cut off by the roof of an ambulance. You close
                your eyes, succumbing to a dark tide.\n";
            die();
    }
    "\n";
    setfuse(withdrawal, 6 + RAND(4), n+1);
}

// flag contains information about where the player hid:
//  0 = in storeroom, forgot to close door
//  1 = in attic, forgot to pull up ladder
//  2 = in attic, left the chair underneath
//  3 = just stuck needle in arm
unfulfilledInt1: function(flag)
{
    "\bWith a snap, the vision ends. ";
    switch (flag) {
        case 0:
        "You are lying prostrate on the ground,
            the ceiling whirling above you. Next to you, you hear Dr.\ 
            Boozer's voice. \"Thank God we found you in time,\" he says. \"If
            you hadn't left that door open...\b";
        break;

        case 1:
        case 2:
        "You are being carried down the attic stairs. From somewhere overhead,
            you hear Dr.\ Boozer's voice. \"Thank God we found you in time,\"
            he says. \"If you hadn't left the ";
        if (flag == 1)
            "stairs down...\b";
        else "chair under the attic door...\b";
        break;

        case 3:
        "You are lying prostrate on the ground, the ceiling whirling above you.
            Next to you, you hear Dr.\ Boozer's voice. \"Thank God we found
            you in time,\" he says.\b";
        break;
    }
    "\"Must be deranged,\" he whispers to the nurse who is with him. Even in
        your fevered state, you hear every word. \"Poor kid put the IV back
        in.\" Then you drift away, the rest of Dr.\ Boozer's words lost. ";
    die();
}

short_interlude: function
{
    pauseAndClear();
    "\b\(Interlude\)\b\b";
    "\"Doctor...going into....\"\b
        \"...BP...forty and....\"\b
        \"Dammit, give me...cc's of...followed by....\"\b
        \"We're losing...think...coming out of....\"\b";
    pauseAndClear();
    "\b\(Fit the Fifth\):\ Revelation\b\b";
    makeQuote('"This one goes out to the one I love"', 'R.E.M.');
    blasted_plain.setup;    // Get this finale running
}


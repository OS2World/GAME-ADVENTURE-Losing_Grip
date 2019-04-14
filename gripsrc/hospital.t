/*
    Hospital, part two a of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: hospital.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+


hospitalDaemon: object
    firstSight2 = true
    passersBy = {
        local isDoc, isMale;

        if (!Me.location.isHospitalHall) {    // Are we in a hallway?
            if (Me.location.isHospital)       // Are we still in the hospital?
                notify(self, &passersBy, 3);  // Yes, so try again later
            return;
        }
        "\b";
        switch(RAND(7)) {
            case 1:
            case 2:
            if (RAND(1000)>500) isDoc = true;
                else isDoc = nil;
            if (RAND(1000)>500) isMale = true;
                else isMale = nil;
            "A <<isMale ? "":"wo">>man passes by, dressed in <<isDoc ?
                "a white coat" : "blue scrubs">>. Where <<isMale ? "his" :
                "her">> face should be there is nothing. <<isMale ? "He" :
                "She">> is soon out of sight, hidden by a turn in the hall.";
            if (old_woman.location == Me.location && RAND(100) < 40 &&
                    old_woman.location.womanDest != nil &&
                    old_woman.check_dir(old_woman.location.womanDest)) {
                " The old woman rolls past you, following the <<
                    isMale ? "":"wo">>man. \"Pardon me!\"\ you hear her
                    calling, \"Pardon me! Have you seen my Kenny?\" ";
                old_woman.moveInto(old_woman.goTo);
                old_woman.turnsSinceRolled = 0;
            }
            break;

            case 3:
            case 4:
            "A group of doctors and interns appears in the hall, headed
                towards you. ";
            if (self.firstSight2) {
                self.firstSight2 = nil;
                "You are fixated by the sight of their faces, or rather by
                    their lack of ones.";
            }
            else "They, too, are faceless.";
            " Their heads nearly touch; they are obviously in conference,
                though you can hear nothing. They pass you and are gone.";
            break;

            case 5:
            if (RAND(1000)>500) isMale = true;
                else isMale = nil;
            "A patient slowly makes <<isMale ? "his" : "her">> way
                down the hall, pushing an IV stand. <<isMale ? "He" : "She"
                >> has no face--<<isMale ? "his" : "her">> head is
                featureless. <<isMale ? "He" : "She">> continues
                down the hall and out of sight.";
            break;

            case 6:
            "From further down the hall you hear the familiar squeak of a
                gurney. A faceless man in blue scrubs is pushing it. A shape
                on the gurney is completely covered by the white sheet draped
                over it. The
                shape occasionally writhes, as if in terrible pain. You watch
                until you can no longer see them.";
            break;

            case 7:
            "Down the hall, a shapeless, faceless patient in a white gown
                shuffles towards you. You cannot guess the sex of
                wraith-like person, even when he (she?)\ is merely feet
                away. You watch the patient until you can no longer see
                the white gown.";
            break;
        }
        "\n";
        notify(self, &passersBy, 6 + RAND(3));
    }
;

operationDaemon: object
    eventNum = -1
    events = [
    'One of the doctors takes a glass cup from its stand over a candle and
        applies it to the patient\'s skin, making the man writhe.',
    'One of the doctors takes a large needle filled with an amber liquid
        and injects it in the patient\'s forearm. The patient slumps.',
    'One of the doctors inserts an iv into the patient\'s forearm. The
        patient blinks, then closes his eyes.',
    'Taking a packet of powder from his vest, a doctor opens it and
        places some of it in the patient\'s nostrils. The patient inhales
        reflexively, then begins sneezing. As the patient\'s sneezing abates,
        a pair of observing doctors near you makes comments.
        "Hellebore root and cowslip,"\ says one. "Thomas believes all problems
        arise from the brain," says the other with a derisive snort.',
    'A doctor bends over the patient and taps his chest several
        times in different places. A doctor standing near you
        snorts, unimpressed with the procedure.',
    'A nurse in blue scrubs says, "BP one-forty over ninety." One of the
        doctors prepares to make an incision.',
    'Everyone stands away from the patient as a doctor produces a long twisted
        tube with an egg-sized bulb at one end. He places the bulb in the
        patient\'s mouth, then withdraws it, clucking softly to himself.',
    'Everyone stands away from the patient as a doctor produces a long
        trumpet-shaped tube and places the wide end on the patient\'s chest
        and the other end against his ear. The doctor then removes it,
        clucking softly to himself.',
    'Everyone gathers around the patient, obscuring your view of the ongoing
        operation.',
    'The patient convulses once, then again. His head lolls to one side, his
        eyes far back in his head. Two doctors immediately begin arguing
        whether herbs or minerals are called for in this situation, while a
        doctor near you mutters, "Not even a theriac could save Simon now."',
    'The patient convulses once, then again. His head lolls to one side, his
        eyes far back in his head. "Digitalis!"\ shouts one of the doctors
        to a colleague, who rummages around in a black bag.',
    'A monitor begins shrilling; one of the doctors jerks back in
        surprise. "Oh, shit,"\ someone murmurs.',
    'With an air of finality, one of the doctors begins cutting through the
        patient\'s skull with a metal saw. The patient does not move, even
        after a slice of his skull peels away.',
    'A doctor begins sawing through the patient\'s skull with a metal saw;
        the other doctors mutter or shake their heads, convinced that the
        trephining will do no good but unwilling to stop it. After a moment,
        the doctor gives up, washing the saw in a white ceramic bowl.',
    '"Clear!"\ shouts a doctor, brandishing a pair of paddles. Everyone backs
        away as the doctor applies the paddles. The patient\'s body jerks,
        then jerks again. The doctors finally put away the instruments and
        paddles.',
    'The doctors gather up their equipment, cover the now-dead patient and
        wheel him out.',
    'The doctors cover the now-dead patient and wheel him out.',
    'The doctors cover the now-dead patient and wheel him out. One nurse
        lingers for a moment, fingering a glass vial. She absentmindedly
        places it on the crates while exiting to the north.'
    ]
    operationTalk = {
        if (Me.location.opRoom)
            "\b<<self.events[self.eventNum * 3 + Me.location.opNum]>>\n";
        if (self.eventNum == 5) {
            old_or.clearRoom;
            medium_or.clearRoom;
            current_or.clearRoom;
            return;
        }
        self.eventNum++;
        if (self.eventNum == 5)
            notify(self, &operationTalk, 1);
        else notify(self, &operationTalk, 3);
    }
;

class hospital_room: insideRm
    isHospital = true
    smelldesc = "You smell alcohol and plastic. "
;

class hospital_hall: hospital_room
    isHospitalHall = true
    sdesc = "\^<<self.color>> \^<<self.num>>"
;

hall_color: floatingItem, decoration
    stage = '2a'
    noun = 'color' 'strip' 'stripe'
    plural = 'strips' 'stripes'
    adjective = 'green' 'purple' 'orange'
    location = {
        if (Me.location.isHospitalHall) return Me.location;
        return nil;
    }
    sdesc = "<<Me.location.color>> stripe"
    ldesc = "A stripe of <<Me.location.color>> running just below the
        ceiling. "
;

hospital_fluorescent_lights: floatingItem, decoration
    stage = '2a'
    noun = 'light' 'lights'
    adjective = 'fluorescent'
    location = {
        if (Me.location.isHospitalHall) return Me.location;
        return nil;
    }
    sdesc = "fluorescent lights"
    ldesc = "They buzz above you. "
    listendesc = "Once, when you were five, you took a long branch to a wasp's
        nest and knocked it down. The wasps swarmed around you, filling your
        ears with their angry sound.\bThese lights are louder. "
;

green4: droom, hospital_hall
    noDog = true
    noDogWander = true      // Necessary to bound the dog's wandering
    dogCanLeave = true      // But the dog can leave
    color = 'green'
    num = 'four'
    firstdesc = "A familiar green hallway embraces you. As the world ceases
        its unnatural spin, you find you recognize the east-west
        hall. You're in Green area of the hospital where you volunteered
        for three months one summer.\b
        No, not volunteered. It was coercion. You were going to be a
        doctor, just like father wanted, so you had to help out at a local
        hospital. \"Looks good on your resume,\" everyone told you.\b
        Three months of hell. This place cemented your desire to avoid med
        school.\b"
    seconddesc = "A hospital hall running east-west.  A green stripe just
        below the ceiling decorates the otherwise-bland walls. The hum of
        fluorescent lighting is barely audible. "
    exits = 'east and west'
    listendesc = "You hear the hum of lights. "
    east = {
        "As you walk east, the hall lengthens. With each step everything
            blurs, vanishing into a grey mist. Your sense of
            balance is lost; you stumble back the way you came. ";
        return nil;
    }
    west = green3
;

green3: hospital_hall
    noDog = true
    noDogWander = true       // Necessary to bound the dog's wandering
    dogCanLeave = true
    womanDir = 'east'        // Which way the woman rolls her wheelchair
    womanDest = &east
    color = 'green'
    num = 'three'
    ldesc = "The hall enters from the east and bends to the southwest. A
        small door leads north and an open doorway graces the south wall. "
    exits = 'north, south, east, and southwest'
    north = small_h_dads_door
    south = {
        if (operationDaemon.eventNum == 5)
            return current_or;
        return old_or;
    }
    east = green4
    sw = green2
    leaveRoom(actor) = {
        if (actor == Me && grey_man.location == self) {
            "The grey man lays a hand on your shoulder. \"Not just yet, I
                think,\" he tells you. ";
            exit;
        }
        pass leaveRoom;
    }
;

small_h_dads_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    adjective = 'small'
    location = green3
    sdesc = "small door"
    ldesc = "The <<self.wordDesc>> door leads north.  A plastic
        plaque mounted on it reads \"G7.\" "
    doordest = dads_room
    otherside = dads_room_door
;

green3_doorway: myDoorway
    location = green3
    ldesc = "It leads south. "
    doordest = { return green3.south; }
;

plastic_plaque_g7: decoration, readable
    stage = '2a'
    noun = 'plaque' 'sign'
    plural = 'plaques' 'signs'
    adjective = 'plastic'
    location = green3
    sdesc = "plastic plaque"
    ldesc = "It reads \"G7.\" "
    readdesc = (self.ldesc)
;

dads_room: hospital_room
    noDog = true             // Necessary to bound the dog's wandering
    noDogWander = true
    dogCanLeave = {
        return (dads_room_door.isopen);
    }
    womanDir = 'south'       // Which way the woman rolls her wheelchair
    womanDest = &south
    floating_items = [med_equipment]
    sdesc = "Hospital Room"
    ldesc = "A dim room filled with arcane medical equipment and dominated
        by a bed in its center. There is a window, its curtains <<
        curtains.wordDesc>>, on the north wall. A door leads south. "
    exits = 'south'
    smelldesc = "A smell of decay clings to the room. "
    south = dads_room_door
    out = dads_room_door
    firstseen = {
        if (eileen.motionListNum > 1) return;    // Never mind...
        "\bMovement at the edge of your vision causes you to whirl around.
            Before you complete the motion grey hands have grabbed you and
            dragged you backwards. You have time to register the sight of
            a white-haired head--familiar, but from where?--next to the bed
            before you are pulled from the room.\b";
        dads_room_door.isopen = small_h_dads_door.isopen = nil;
        small_h_dads_door.islocked = true;
        grey_man.moveInto(green3);
        Me.travelTo(green3);
        notify(grey_man, &scoldTerryA, 1);
    }
;

dads_room_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    location = dads_room
    sdesc = "small door"
    ldesc = "The <<self.wordDesc>> door leads south. "
    doordest = green3
    otherside = small_h_dads_door
;

med_equipment: decoration, wallpaper
    stage = '2a'
    noun = 'equipment'
    adjective = 'arcane' 'medical'
    sdesc = "medical equipment"
    ldesc = "Through the long months you worked here you never discovered
        their purpose. "
    listendesc = "The equipment whistles and beeps."
;

dads_bed: bedItem, underHider
    stage = '2a'
    noun = 'bed'
    location = dads_room
    sdesc = "bed"
    ldesc = {
        "A hospital bed, designed for utility rather than comfort. ";
        pass ldesc;
    }
;

dust: hiddenItem, item
    stage = '2a'
    noun = 'dust'
    weight = 0
    bulk = 1
    underLoc = dads_bed
    sdesc = "dust"
    adesc = "some dust"
    ldesc = "Allergenic and non-sanitary. "
    smelldesc = "It tickles your nose. "
;

dads_window: fixedItem
    stage = '2a'
    noun = 'window'
    adjective = 'north'
    location = dads_room
    sdesc = "window"
    ldesc = {
        if (curtains.isopen)
            "The window looks out onto a sea of shifting grey mist. ";
        else "The window is covered by curtains. ";
    }
    verDoLookthru(actor) = {
        if (!curtains.isopen)
            "The curtains prevent you. ";
    }
    doLookthru(actor) = {
        "A grey mist fills the window, obstructing your view. ";
    }
;

curtains: fixedItem
    stage = '2a'
    isThem = true
    isopen = nil
    firstOpen = true
    wordDesc = {
        self.isopen ? "open" : "closed";
    }
    noun = 'curtain'
    plural = 'curtains'
    adjective = 'fuchsia'
    location = dads_room
    sdesc = "fuchsia curtains"
    ldesc = "The <<self.wordDesc>> curtains are a vivid fuchsia, an anomaly
        among the aniseptic white of the remainder of the room. "
    verDoOpen(actor) = {
        if (self.isopen)
            "The curtains are already open. ";
    }
    doOpen(actor) = {
        if (self.firstOpen) {
            "Opening the curtains, instead of revealing the green lawn which
                surrounds this hospital, reveals a grey mist which clings
                to the window. It is translucent, admitting a diffuse light
                but no glimpse of what's beyond. ";
            self.firstOpen = nil;
        }
        else "Behind the curtains and the window, the grey mist remains. ";
        self.isopen = true;
        grey_mist.moveInto(dads_room);
    }
    verDoClose(actor) = {
        if (!self.isopen)
            "The curtains are already closed. ";
    }
    doClose(actor) = {
        "You draw the curtains against the grey mist. ";
        self.isopen = nil;
        grey_mist.moveInto(nil);
    }
;

grey_mist: thing
    stage = '2a'
    isListed = nil
    noun = 'mist'
    adjective = 'grey' 'gray'
    sdesc = "grey mist"
    ldesc = "It has a greasy look to it; it rubs against the window, leaving
        tracks of moisture. "
    dobjGen(a, v, i, p) = {
        if (!v.issysverb && v != inspectVerb && v != askVerb &&
                v != tellVerb) {
            "The window prevents you. ";
            exit;
        }
    }
    iobjGen(a, v, d, p) = { self.dobjGen(a,v,d,p); }
;

bp_cuff: complex, clothingItem
    noun = 'cuff' 'bulb' 'dial'
    adjective = 'blood' 'pressure' 'bp'
    weight = 10
    bulk = 8
    sdesc = "blood pressure cuff"
    ldesc = "The blood pressure cuff has a dial and an inflation bulb. "
    hdesc = "Coiled on the floor where it was carelessly dropped is a
        blood pressure cuff. "
    putOnDesc = "You slide the cuff over your arm. "
    takeOffDesc = "You slide the cuff off of your arm. "
    moveInto(loc) = {
        inherited.moveInto(loc);
        if (inside(self, Me))
            cuffAh.solve;
    }
    verDoSqueeze(actor) = {}
    doSqueeze(actor) = {
        "%You% give the bulb several firm squeezes. The cuff inflates";
        if (self.isworn) " around your arm, making you feel light-headed";
        ". After a few seconds, you let the air escape from it. ";
    }
;

green2: hospital_hall
    noDog = true
    noDogWander = true            // Necessary to bound the dog's wandering
    dogCanLeave = true
    womanDir = 'northeast'   // Which way the woman rolls her wheelchair
    womanDest = &ne
    color = 'green'
    num = 'two'
    ldesc = "A U-shaped hall, entering from the northeast. The floor
        slopes gently down as it rounds the curve towards the southeast.
        Directly across from you is a doorway leading east. "
    exits = 'northeast, southeast, and east'
    east = {
        if (operationDaemon.eventNum == 5)
            return current_or;
        return medium_or;
    }
    ne = green3
    se = green1
;

green2_doorway: myDoorway
    location = green2
    ldesc = "It leads east. "
    doordest = { return green2.east; }
;

green1: hospital_hall
    noDog = true
    noDogWander = true            // Necessary to bound the dog's wandering
    dogCanLeave = true
    womanDir = 'northwest'   // Which way the woman rolls her wheelchair
    womanDest = &nw
    color = 'green'
    num = 'one'
    ldesc = "A nondescript hall leading east to northwest. To the north is an
        open doorway. The ever-present stripe changes color to the east, just
        beyond a sign. "
    exits = 'north, east, and northwest'
    north = current_or
    east = purple3
    nw = green2
;

green1_doorway: myDoorway
    location = green1
    ldesc = "It leads north. "
    doordest = current_or
;

green_purple_sign: distantItem, readable
    stage = '2a'
    noun = 'sign'
    plural = 'signs'
    location = green1
    sdesc = "sign"
    ldesc = "The sign hangs from the ceiling to the west. It reads, \"Leave
        Green/Enter Purple\" in the appropriate colors. "
    readdesc = "\"Leave Green/Enter Purple\" "
;

class or_room: hospital_room
    opRoom = true
    noDog = true
    noDogWander = true       // Necessary to bound the dog's wandering
    dogCanLeave = true
    womanDir = 'south'       // Which way the woman rolls her wheelchair
    womanDest = &south
    sdesc = "Operating Room"
    exits = 'north, south, and west'
    north = green3
    south = green1
    west = green2
    firstseen = {
        if (operationDaemon.eventNum == -1) {
            operationDaemon.eventNum = 0;
            notify(operationDaemon, &operationTalk, 1 + RAND(2));
        }
    }
;

old_or: or_room
    opNum = 1
    ldesc = "The operating room is dim and smoky, lit by kerosene lamps and
        candles. Through the haze you make out exits to the north, south,
        and west. "
    smelldesc = "Smoke curls in your nostrils, making your sneeze."
    clearRoom = {
        old_docs.moveInto(nil);
        old_patient.moveInto(nil);
        old_doctors_equipment.moveInto(nil);
    }
;

old_docs: Actor
    stage = '2a'
    isThem = true
    isHim = true
    noun = 'doctor' 'doctors' 'group'
    adjective = 'doctor' 'doctors'
    location = old_or
    sdesc = "the doctors"
    ldesc = "The doctors are dressed in archaic clothing and powdered wigs.
        They stand in clumps, discussing the patient's condition or peering
        at the patient himself."
    actorDesc = "A group of doctors fills the room, milling about a patient."
    disavow = "The doctors wave you away. "
    alreadyTold = "The doctors wave you away. "
    verDoKick(actor) = {
        "Considering what they are doing, you would do well to leave them
            alone. ";
    }
    doSynonym('Kick') = 'Kiss'
;

old_patient: Actor
    stage = '2a'
    isHim = true
    isListed = nil
    noun = 'patient' 'simon'
    location = old_or
    sdesc = "patient"
    ldesc = "The poor man is enduring what passes for medical care
        in this room. "
    disavow = "The patient is in no condition to answer. "
    alreadyTold = "The patient is in no condition to answer. "
    verDoKick(actor) = { "He is on a table, higher than you can kick. "; }
    verDoKiss(actor) = { "Considering his condition, you change your mind. "; }
;

old_doctors_equipment: decoration
    stage = '2a'
    noun = 'stand' 'equipment' 'cup' 'candle' 'tube' 'bulb' 'saw'
    adjective = 'glass' 'medical' 'archaic' 'metal'
    location = old_or
    sdesc = "medical equipment"
    ldesc = "Various pieces of medical equipment lie scattered about the room
        and held in doctors' hands. "
;

old_doctors_lamps: decoration
    isThem = true
    stage = '2a'
    noun = 'lamp' 'lamps' 'candle' 'candles'
    adjective = 'kerosene'
    location = old_or
    sdesc = "lamps and candles"
    ldesc = "The OR is lit by lamps and candles. "
;

medium_or: or_room
    opNum = 2
    ldesc = "The operating room is mildly clean; evidently Lister's ideas
        have begun to catch on, though they are applied haphazardly. There
        are exits to the north, south, and west. "
    clearRoom = {
        medium_docs.moveInto(nil);
        medium_patient.moveInto(nil);
    }
;

medium_docs: Actor
    stage = '2a'
    isThem = true
    isHim = true
    noun = 'doctor' 'doctors' 'group'
    adjective = 'doctor' 'doctors'
    location = medium_or
    sdesc = "the doctors"
    ldesc = "The doctors are dressed in dark suits and vests.  They stand
        in clumps, discussing the patient's condition or peering
        at the patient himself."
    actorDesc = "A group of doctors fills the room, milling about a patient."
    disavow = "The doctors wave you away. "
    alreadyTold = "The doctors wave you away. "
    verDoKick(actor) = {
        "Considering what they are doing, you would do well to leave them
            alone. ";
    }
    doSynonym('Kick') = 'Kiss'
;

medium_patient: Actor
    stage = '2a'
    isHim = true
    isListed = nil
    noun = 'patient' 'simon'
    location = medium_or
    sdesc = "patient"
    ldesc = "The poor man is suffering what passes for medical care in this
        room. "
    disavow = "The patient is in no condition to answer. "
    alreadyTold = "The patient is in no condition to answer. "
    verDoKick(actor) = { "He is on a table, higher than you can kick. "; }
    verDoKiss(actor) = { "You consider his condition and change your mind. "; }
;

current_or: or_room
    opNum = 3
    ldesc = "Shiny and clean. The only feature which breaks the sterility of
        the room is a pile of crates stacked in the northeast corner. There
        are exits to the north, south, and west. "
    clearRoom = {
        current_docs.moveInto(nil);
        current_patient.moveInto(nil);
        novocaine.moveInto(crates);
        small_h_dads_door.isopen = nil;
        small_h_dads_door.islocked = true;
        dads_room_door.isopen = nil;
        dads_room_door.islocked = true;
        eileen.moveInto(green3);
        gurney_line.moveInto(purple1);
        if (Me.location == purple1)
            "\bA sound makes you turn around. A line of patients, all on
                gurneys, now fills the hallway. What the hell?\n";
        else if (Me.location == green3)
            "\bA nurse walks in from the south. ";
        eileen.firstMove;
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (uberloc(novocaine) == self)
            seenVialAh.see;
    }
    roomAction(a, v, d, p, i) = {
        if (a == Me && v.touch && ((d && d.location == crate_gap) ||
            (i && i.location == crate_gap)) &&
            !(v == takeVerb && p == withPrep)) {
            "You reach under the crates, but your arm isn't long enough. ";
            exit;
        }
        if (a == Me && v.sight && (d && d.location == crate_gap)) {
            "\^<<d.thedesc>> <<d.isThem ? "are" : "is">> so far back in the
                gap that you can't make out any details. ";
            exit;
        }
        if (a == Me && v.touch && ((d && d == novocaine &&
            d.location == crates) || (i && i == novocaine &&
            i.location == crates)) && !(v == takeVerb && p == withPrep)) {
            novocaine.rolledUnder = true;
            "The vial turns out to be wet; it slips between your ";
            if (gloves.isworn) "gloved ";
            "fingers and hits the floor. It doesn't break, thankfully, but it
                does roll under the crates and out of view. ";
            vialAh.see;
            novocaine.moveInto(crate_gap);
            exit;
        }
        pass roomAction;
    }
;

crates: surface, fixedItem
    stage = '2a'
    isThem = true
    noun = 'crate' 'pile'
    plural = 'crates'
    adjective = 'pile'
    location = current_or
    sdesc = "crates"
    ldesc = {
        "The crates are stacked in the northeast corner of the room in such
            a way as to leave a small gap between two of them. ";
        pass ldesc;
    }
    touchdesc = {
        if (gloves.isworn) "You can feel nothing through the gloves. ";
        else "Rough and splintery. ";
    }
    verDoLookin(actor) = { "You see no way to open the crates. "; }
    doSynonym('Lookin') = 'Open'
    verDoSearch(actor) = {
        "You'll have to be more specific about how you want to examine the
            crates. ";
    }
    verDoLookunder(actor) = {}
    doLookunder(actor) = {
        crate_gap.doLookin(actor);
    }
    verIoPutUnder(actor) = { crate_gap.verIoPutIn(actor); }
    ioPutUnder(actor, dobj) = { crate_gap.ioPutIn(actor, dobj); }
;

crate_gap: fixedItem
    noun = 'gap' 'hole' 'space'
    location = current_or
    sdesc = "gap"
    ldesc = {
        "The gap is barely wide enough for your arm and is very deep. ";
        if (length(contlist(self)) != 0)
            "By straining your eyes, you can just make out the shadow of
                something deep within the gap. ";
        else "It is too dark for you to make out any other details. ";
    }
    touchdesc = "You reach in the gap. Your hand encounters nothing, no
        matter how hard you strain. "
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        local list;
        
        if (dobj == arms || dobj == hands) {
            self.touchdesc;
            return;
        }
        if (dobj == cane) {
            list = contlist(self);
            "You scrape the cane about in the gap but ";
            if (length(contlist(self)) == 0)
                "encounter nothing. ";
            else "cannot manage to retrieve anything from under the crates. ";
            return;
        }
        "%You% place%s% <<dobj.thedesc>> in the gap, where <<dobj.isThem ?
            "they are" : "it is">> promptly lost from view. ";
        dobj.moveInto(self);
    }
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (length(self.contents) != 0)
            "You can barely see something at the far end of the gap. ";
        else "You see nothing in the gap. ";
    }
    verDoEnter(actor) = { "The space is much too small for you. "; }
;

novocaine: item, readable
    rolledUnder = nil
    empty = nil
    contentsReachable = { return nil; }
    noun = 'vial' 'novocaine' 'label' 'liquid' 'top'
    adjective = 'glass' 'clear' 'rubber'
    weight = 5
    bulk = 2
    sdesc = "glass vial"
    ldesc = {
        "The glass vial has a rubber top";
        if (!self.empty) " and is partially filled with a clear liquid";
        ". A label wraps around it. ";
    }
    readdesc = "\"Novocaine.\" "
    verDoOpen(actor) = { "You see no way of removing the rubber top. "; }
    doTake(actor) = {
        if (!self.rolledUnder) {
            self.rolledUnder = true;
            "You pick up the vial, which turns out to be wet. It slips from
                between your ";
            if (gloves.isworn) "gloved ";
            "fingers and hits the floor. It doesn't break, thankfully, but it
                does roll under the crates and out of view. ";
            self.moveInto(crate_gap);
            vialAh.see;
            return;
        }
        pass doTake;
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj != syringe) {
            "You can't put <<dobj.thedesc>> in the vial. ";
            return;
        }
        "You stick the end of the needle through the rubber top";
        if (dobj.isFull)
            ", but the syringe is already full";
        else if (self.empty)
            ", but the vial is empty";
        else {
            " and draw on the syringe's plunger, filling it with the
                liquid";
            syringe.isFull = true;
            self.empty = true;
        }
        ". ";
    }
;

current_docs: Actor
    stage = '2a'
    isThem = true
    noun = 'doctor' 'nurse' 'group'
    plural = 'doctors' 'nurses'
    adjective = 'group'
    location = current_or
    sdesc = "the doctors and nurses"
    ldesc = "They fill the room, standing around a patient undergoing
        surgery. "
    actorDesc = "A group of doctors and nurses is milling about a patient
        on a gurney. "
    disavow = "They wave you away. "
    alreadyTold = "They wave you away. "
    verDoKick(actor) = {
        "Considering what they are doing, you would do well to leave them
            alone. ";
    }
    doSynonym('Kick') = 'Kiss'
;

current_patient: Actor
    stage = '2a'
    isHim = true
    isListed = nil
    noun = 'patient' 'simon'
    location = current_or
    sdesc = "patient"
    ldesc = "The poor man is undergoing surgery. "
    disavow = "The patient is in no condition to answer. "
    alreadyTold = "The patient is in no condition to answer. "
    verDoKick(actor) = { "He is on a table, higher than you can kick. "; }
    verDoKiss(actor) = { "Given his condition, you change your mind. "; }
;

eileen: dthing, trackActor
    askDisambig = true
    selfDisambig = true
    stage = '2a'
    isHer = true
    askme = &eileendesc
    myfollower = eileenFollower
    treatingPatients = nil        // Am I working on the line of patients?
    treatmentNum = 0              // 1-2=Taking history 3-5=treating
    waitNum = 0                   // Cntr for when I talk to Terry
    holdingBag = nil              // Am I holding out the colostomy bag?
    bagWaitNum = 0                // How long I've held out the bag
    onHold = nil                  // Am I waiting for the BP cuff?
    holdTime = 0                  // How long I've waited for the cuff
    motionList = [['n'] ['s' 'sw' 'se' 'e' 'n' 'e']]

    noun = 'eileen' 'woman' 'nurse'
    sdesc = {
        if (self.firstLdesc) "nurse";
        else "Eileen";
    }
    stringsdesc = 'Eileen'
    adesc = {
        if (self.firstLdesc) "a nurse";
        else "Eileen";
    }
    thedesc = {
        if (self.firstLdesc) "the nurse";
        else "Eileen";
    }
    firstdesc = "You recognize her as Eileen, one of the nurses you worked
        with during your three hellish months at the hospital. Though she,
        unlike others, never seemed angry with you, she often seemed irritated
        by your lack of enthusiasm and wandering attention. "
    seconddesc = {
        "Eileen has a shock of red hair which surrounds her head like a
            nimbus. ";
        if (self.holdingBag)
            "She is holding a colostomy bag out to you, looking at you
                expectantly. ";
        else if (self.treatmentNum == 2 || self.treatmentNum == 3)
            "She is talking with a patient. ";
    }
    moveInto(dest) = {
        self.myfollower.noFollow = nil;
        pass moveInto;
    }
    actorDesc = {
        if (self.firstLdesc)
            "There is a nurse here";
        else "Eileen is here";
        if (self.isMoving)
            ", striding purposefully down the halls";
        else if (self.onHold)
            ", waiting for you";
        else if (self.holdingBag)
            ", holding out a colostomy bag for you to take";
        else if (self.treatmentNum == 2 || self.treatmentNum == 3)
            ", talking with a patient";
        ". ";
    }
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "\^<<self.thedesc>> gives you the slightest of nods. ";
            exit;
        }
        else pass actorAction;
    }
    disavow = "\^<<self.thedesc>> sighs. \"I don't really have anything to say
        about that.\" "
    alreadyTold = "\"There's nothing more to tell,\"\ <<self.thedesc>> says. "
    verDoKiss(actor) = { "\^<<self.thedesc>> frowns at you. \"Not now,\" she
        says. "; }
    verDoAskFor(actor, io) = {
        "\^<<self.thedesc>> shakes her head in your direction. \"Not now,\"
            she says. ";
    }
    verIoGiveTo(actor) = {}
    ioGiveTo(actor, dobj) = {
        if (dobj != hall_pass && dobj != bp_cuff) {
            "\"I don't need that right now,\" <<self.thedesc>> says. ";
            return;
        }
        if (dobj == hall_pass) {
            "\"Thanks,\" she says, absentmindedly placing it in a pocket. ";
            dobj.moveInto(eileen);
            return;
        }
        // Handle BP stuff
        if (self.onHold) {
            "\^<<self.thedesc>> thanks you as she applies the BP
                cuff to a patient and takes a reading. ";
            incscore(1);
        }
        else if (self.holdTime > 30) {
            "\^<<self.thedesc>> sighs. \"Thanks, but I found another.\" She
                takes the cuff anyway. ";
        }
        else {
            "\^<<self.thedesc>> says, \"My BP cuff! Where did you find it?\"\
                as she takes it from you. ";
        }
        bp_cuff.moveInto(eileen);
        self.onHold = nil;
    }
    ioSynonym('GiveTo') = 'ShowTo'
    verDoKick(actor) = {
        "You kick <<self.thedesc>> in the shins, hard. \"What the hell?\"\ she
            snaps, glaring at you. ";
    }
    doorLocked(dest) = {
        if (self.motionListNum == 1) {
            if (Me.location == self.location)
                "\b\^<<self.thedesc>> swiftly unlocks the door to the north,
                    opens it, and slips through. You hear the lock click
                    behind her again.\n";
            self.moveInto(dads_room);
            eileenFollower.noFollow = true;     // No following me thru door
            bp_cuff.moveInto(dads_room);
            bp_cuff.firstPick = true;           // So we still get the hdesc
            self.isMoving = nil;
            self.motionListNum++;
            self.motionListListNum = 1;
            self.moveTurn = global.turnsofar + 3;
        }
        else {
            small_h_dads_door.islocked = nil;
            dads_room_door.islocked = nil;
            if (Me.location == green3)
                "\bThe door to the north unlocks with a click.\n";
        }
    }
    verGrab(item) = {
        if (item == colostomy_bag && self.holdingBag) {
            notify(self, &bagTaken, 0);
            self.bagWaitNum = 0;    // So we don't complain AND congratulate
        }
        else pass verGrab;
    }
    arriveDaemon = {
        if (Me.location == self.location)
            "\b\"Good God!\"\ <<self.thedesc>> exclaims in surprise, her
                eyes widening at the sight of all of the patients. She
                recovers quickly, though, and moves to treat them. ";
        self.treatingPatients = true;
        self.treatmentNum = 1;
    }
    heartbeat = {
        local c;

        if (!self.treatingPatients) {
            pass heartbeat;
        }
        if (self.onHold) {
            self.holdTime++;
            if (self.holdTime > 30) {
                if (Me.location == self.location)
                    "\bA blank-faced woman appears from the north and gives
                        <<self.thedesc>> a BP cuff. \^<<self.thedesc>> turns
                        to look at you. \"Never mind now, Terry,\" she says. ";
                self.onHold = nil;
            }
            return;
        }
        c = (Me.location == self.location);
        if (c && waitNum != true) {
            waitNum++;
            if (waitNum > 3 + RAND(2)) {
                "\bA sudden scream from further down the line. Both you and
                    <<self.thedesc>> jump; she runs to the patient, then
                    returns, wheeling him at high speed. She holds out a
                    horrible-smelling sac filled with a black substance.
                    \"Here!\"\ she snaps. \"Colostomy bag. Take it, quick!\"
                    You remember why you chose not to go to med school. ";
                colostomy_bag.moveInto(self);
                self.holdingBag = true;
                self.waitNum = true;
                return;
            }
        }
        if (self.holdingBag) {
            if (++self.bagWaitNum > 2) {
                "\b\"Dammit, Terry, this man is in pain!\"\ <<self.thedesc
                    >> shouts. \"Terry! Terry!\" She is interrupted by the
                    arrival of one of the blank-faced people in blue scrubs,
                    who takes the bag from her. She wheels the patient north,
                    but not before giving you a murderous glare. The man
                    follows her.\n";
                self.treatmentNum = 4;
                self.moveInto(nil);
                self.holdingBag = nil;
                self.bagWaitNum = nil;
                return;
            }
            else return;
        }
        if (c && self.bagWaitNum == true) {
            if (bp_cuff.location == self) {
                "\b\^<<self.thedesc>> begins talking to a patient, then
                    stops to check her pockets. She pulls a BP cuff out of
                    one of them and smiles at you. \"Thanks again for finding
                    the cuff!\"\ she calls out before returning to the
                    patient. ";
                    return;
            }
            "\b\^<<self.thedesc>> begins talking to a patient, but is brought
                up short by something. She turns and sees you. She beams.
                \"Terry, glad you're still here. I'm missing my BP
                cuff--must've dropped
                it somewhere in Green. Go get it for me, will you?\" She hands
                you a hall pass. \"In case someone harasses you,\" she says
                with a wink before turning back to another patient.\n";
            hall_pass.moveInto(Me);
            self.bagWaitNum = nil;
            self.onHold = true;
            self.treatmentNum = 2;
            incscore(5);
            cuffAh.see;
            passAh.see;
            return;
        }
        switch (self.treatmentNum) {
            case 1:
                if (self.holdTime > 0) {
                    if (c) {
                        "\b\^<<self.thedesc>> looks around. The line of
                            patients is gone, dispatched at last. From down
                            the hall, you hear one of the doctors call,
                            \"Come on, Eileen! Break time!\"\b\"Coming!\"\
                            she yells in response. ";
                        if (self.holdTime <= 30)
                            "She turns to you. \"Thanks for your help,\" she
                                says warmly. ";
                        "Eileen jogs down the hall and is gone. ";
                    }
                    self.moveInto(nil);
                    self.myfollower.moveInto(nil);
                    self.wantheartbeat = nil;
                    return;
                }
                if (c) "\b\^<<self.thedesc>> moves to the patient at the head
                    of the line and begins taking a history.\n";
                break;
            case 2:
            case 4:
            case 5:
                break;
            case 3:
                if (c) {
                    "\b\^<<self.thedesc>>, satisfied, wheels the gurney
                        through the swinging doors to the north. ";
                    if (RAND(100) < 20)
                        "As the doors swing back out, it is as if the room
                            behind them exhales. You feel pressure pushing
                            you away, then pressure pulling you
                            forward as the doors swing the other way and the
                            unseen room inhales. ";
                }
                eileen.moveInto(nil);
                eileenFollower.noFollow = true;
                if (self.holdTime > 0)    // We're done with the BP stuff
                    gurney_line.moveInto(nil);
                else if (c) "The remaining patients call after her.\n";
                break;
            case 6:
                eileen.moveInto(purple1);
                if (eileen.location == Me.location)
                    "\b\^<<self.thedesc>> reenters the hallway from the north,
                        wheeling a gurney covered in a fine coating of ash.
                        She pushes the gurney west, then returns a few seconds
                        later empty-handed.\n";
                break;
        }
        self.treatmentNum++;
        if (self.treatmentNum > 6) self.treatmentNum = 1;
    }
    bagTaken = {
        if (!self.holdingBag) return;
        "\b\^<<self.thedesc>> looks at you gratefully as she wheels the patient
            north. As she and the patient pass through the doors, one of the
            blank-faced men slips past her and into the hall. He takes the
            colostomy bag from you and reenters the north doors. It takes a
            moment for you to realize the bag is really gone, another to
            realize that you are now covered in a light sheen of sweat.\n";
        colostomy_bag.moveInto(nil);
        self.treatmentNum = 4;
        self.moveInto(nil);
        self.holdingBag = nil;
        self.bagWaitNum = true;
    }
;

eileenFollower: follower
    stage = 0
    noFollow = nil
    noun = 'eileen' 'woman' 'nurse'
    myactor = eileen
    verDoFollow(actor) = {
        if (self.noFollow)
            "You can't follow <<eileen.thedesc>>. ";
    }
;

colostomy_bag: item
    stage = '2a'
    noun = 'bag' 'sac'
    adjective = 'colostomy'
    sdesc = "colostomy bag"
    ldesc = "The bag's stench is almost enough to overwhelm you. "
    smelldesc = "You breathe in a good lungfull of odor. The room swims
        before your eyes. "
    touchdesc = "Digustingly slick and warm. "
    takedesc = "It slithers warmly in your grasp. "
;

hall_pass: item
    stage = '2a'
    noun = 'pass' 'card'
    adjective = 'hall' 'laminated'
    weight = 2
    bulk = 1
    sdesc = "hall pass"
    ldesc = "The hall pass is a laminated card with colors around its edges
        to show what areas the bearer is authorized to enter.  This one is
        edged in purple and green stripes. "
;

purple3: hospital_hall
    womanDir = 'west'        // Which way the woman rolls her wheelchair
    noDog = true
    noDogWander = true
    dogCanLeave = true
    womanDest = &west
    color = 'purple'
    num = 'three'
    ldesc = "The hall jogs west to north, interrupted by several stairs to the
        north. A sign hangs from the ceiling to the west, delineating where
        the stripe of color changes from purple to green. A set of doors leads
        east. "
    exits = 'north, east, and west'
    firstseen = {
        doubleDoorAh.see;
        pass firstseen;
    }
    leaveRoom(actor) = {
        dog.cameFromPurple2 = nil;
        pass leaveRoom;
    }
    north = purple2
    east = double_doors
    west = green1
;

several_steps1: fixedItem
    stage = '2a'
    isThem = true
    noun = 'step' 'stair'
    plural = 'steps' 'stairs'
    location = purple3
    sdesc = "stairs"
    ldesc = "Four steps leading north. "
    verDoClimb(actor) = {}
    doClimb(actor) = { nVerb.action(actor); }
;

purple_green_sign: distantItem, readable
    stage = '2a'
    noun = 'sign'
    plural = 'signs'
    location = purple3
    sdesc = "sign"
    ldesc = "The sign hangs from the ceiling to the west. It reads, \"Leave
        Purple/Enter Green\" in the appropriate colors. "
    readdesc = "\"Leave Purple/Enter Green\" "
;

double_doors: obstacle, fixeditem
    stage = '2a'
    isThem = true
    swingDoors = true
    islocked = true
    contentsReachable = true
    noun = 'door' 'keyhole'
    plural = 'doors'
    adjective = 'set' 'two' 'double'
    location = purple3
    sdesc = "set of double doors"
    ldesc = {
        "The doors are spring-loaded so as to close automatically. In
            one of them is a keyhole";
        if (dxdoor_key.location == self)
            " in which a key is thrust";
        ". ";
    }
    doordest = admitting
    destination = {
        if (!self.islocked) {
            "You push past the doors, which shut behind you.\b";
            return admitting;
        }
        "The doors are locked. ";
        setit(self);
        return nil;
    }
    verDoKnockon(actor) = { "No one answers. "; }
    verDoOpen(actor) = {
        if (self.islocked)
            "The doors are locked. ";
        else "You give the doors a firm push.  They swing open, then back
            shut. ";
    }
    doSynonym('Open') = 'Push'
    verDoClose(actor) = { "They're already closed. "; }
    verDoLock(actor) = {
        if (self.islocked) "The doors are already locked. ";
    }
    doLock(actor) = { askio(withPrep); }
    verDoUnlock(actor) = {
        if (!self.islocked) "The doors are already unlocked. ";
    }
    doUnlock(actor) = { askio(withPrep); }
    verDoLockWith(actor, io) = {
        if (self.islocked) "It's already locked. ";
    }
    doLockWith(actor, io) = {
        if (io == dxdoor_key) {
            "Locked. ";
            self.islocked = true;
            other_dxdoors.islocked = true;
        }
        else "It doesn't fit the lock. ";
    }
    verDoUnlockWith(actor, io) = {
        if (!self.islocked) "The doors are already unlocked. ";
    }
    doUnlockWith(actor, io) = {
        if (io == dxdoor_key) {
            "Unlocked. ";
            self.islocked = nil;
            other_dxdoors.islocked = nil;
            doubleDoorAh.solve;
        }
        else "It doesn't fit the lock. ";
    }
    verIoUnlockWith(actor) = {}    // To prevent max disambiguation
    ioUnlockWith(actor, dobj) = {
        "I don't know how to unlock anything with the set of doors. ";
    }
;

dxdoor_key: keyItem
    stage = '2a'
    weight = 2
    bulk = 1
    noun = 'key'
    plural = 'keys'
    adjective = 'small' 'metal' 'metallic' 'aluminum' 'aluminium'
    location = double_doors
    sdesc = "aluminum key"
    adesc = "an aluminum key"
    ldesc = "A small aluminum key with fairly regular teeth. "
    verDoTurn(actor) = {
        if (self.location != double_doors) pass verDoTurn;
    }
    doTurn(actor) = {
        local stat;
        
        "You turn the key, ";
        stat = outhide(true);
        if (double_doors.islocked)
            double_doors.doUnlockWith(actor, self);
        else double_doors.doLockWith(actor, self);
        outhide(stat);
        if (!double_doors.islocked) {
            "un";
            doubleDoorAh.solve;
        }
        "locking the doors. ";
    }
;

purple2: hospital_hall
    color = 'purple'
    womanDir = 'east'        // Which way the woman rolls her wheelchair
    womanDest = &east
    num = 'two'
    ldesc = "An east-south bend in the hall. To the south are several
        stairs. "
    exits = 'east and south'
    leaveRoom(actor) = {
        if (dog.location == self)
            dog.cameFromPurple2 = true;
        pass leaveRoom;
    }
    east = purple1
    south = purple3
;

several_steps2: fixedItem
    stage = '2a'
    isThem = true
    noun = 'step' 'stair'
    plural = 'steps' 'stairs'
    location = purple2
    sdesc = "stairs"
    ldesc = "Four steps leading south. "
    verDoClimb(actor) = {}
    doClimb(actor) = { sVerb.action(actor); }
;

purple1: hospital_hall
    color = 'purple'
    womanDir = 'south'       // Which way the woman rolls her wheelchair
    womanDest = &south
    noDog = true
    noDogWander = true
    dogCanLeave = true
    num = 'one'
    ldesc = "The corridors of the hospital join in a T-junction. The arms
        of the T lie east and west, while the base runs south. A pair of
        swinging doors crowns the top of the T, to the north. Over the
        east corridor is a sign. "
    exits = 'south, east, and west'
    listendesc = {
        if (gurney_line.location == self)
            "You hear the muttering, grumblings, and wheezings of patient
                after patient. ";
        else "You hear nothing unusual. ";
    }
    north = {
        "The doors will not budge for you. As you push harder, a squirt of
            grey smoke escapes from behind them. ";
        return nil;
    }
    south = admitting
    east = orange5
    west = purple2
    leaveRoom(actor) = {
        if (actor == Me && eileen.holdingBag) {
            "As you walk away, you hear <<eileen.thedesc>> yelling after you.
                \"Terry! Terry!\"\ Silence, then \"Damn that
                kid.\"\b";
            eileen.treatmentNum = 4;
            eileen.moveInto(nil);
            eileen.holdingBag = nil;
            eileen.bagWaitNum = nil;
        }
        dog.cameFromPurple2 = nil;
        pass leaveRoom;
    }
;

purple1_doors: fixedItem
    stage = '2a'
    isThem = true
    noun = 'door'
    plural = 'doors'
    adjective = 'swinging'
    location = purple1
    sdesc = "swinging doors"
    ldesc = "They lead north. "
    verDoKnockon(actor) = { "No one answers. "; }
    verDoOpen(actor) = { "They refuse to move. "; }
    verDoClose(actor) = { "But the doors are already closed!"; }
;

purple_orange_sign: distantItem, readable
    stage = '2a'
    noun = 'sign'
    plural = 'signs'
    location = purple1
    sdesc = "sign"
    ldesc = "The sign hangs from the ceiling to the west. It reads, \"Leave
        Purple/Enter Orange\" in the appropriate colors. "
    readdesc = "\"Leave Purple/Enter Orange\" "
;

gurney_line: dthing, fixedItem
    askDisambig = true
    isThem = true
    noun = 'patient' 'gurney' 'line'
    plural = 'patients' 'gurneys'
    adjective = 'line'
    sdesc = "line of patients"
    firstdesc = {
        if (eileen.onHold)
            "There is a patient on a gurney in the hallway. ";
        else if (eileen.waitNum == true)
            "A few patients on gurneys line the hallway. ";
        else "Shock fills you, making you light-headed. So many patients!
            Where did they come from? A wave of remembered nausea sweeps you.
            It passes, but an acidic gnawing remains in your stomach, as if
            you had stayed awake the entire previous night. ";
    }
    seconddesc = {
        if (eileen.onHold)
            "There is a patient on a gurney in the hallway. ";
        else if (eileen.waitNum == true)
            "A few patients on gurneys line the hallway. ";
        else "The line of patients on gurneys fills the hallway, making
            this part of the hospital resemble a triage unit. ";
    }
    heredesc = {
        if (eileen.onHold)
            "There is a patient on a gurney in the hallway. ";
        else if (eileen.waitNum == true)
            "A few patients on gurneys line the hallway. ";
        else "A line of patients on gurneys fills the hallway. ";
    }
    listendesc = "You hear crying, moaning, mumbling, cursing, a mass of
        pain and distress. "
    eileendesc = {
        "\"I don't know,\" <<eileen.thedesc>> says in bewilderment.
            \"They...just arrived from somewhere, all at once.\" ";
    }
;

admitting: hospital_room
    womanDir = 'west'        // Which way the woman rolls her wheelchair
    womanDest = &west
    sdesc = "Admitting"
    ldesc = "The first line of defense between the hospital and the outside
        world. Chairs are strewn about at random; on several there are
        magazines. A counter guards the hall leading north. Above it is a
        speaker. To the west are a set of wide double doors labeled
        \"Deliveries.\" South is the hospital exit. "
    listendesc = "Music is drifting from a speaker in the ceiling. "
    exits = 'north and west'
    north = purple1
    west = other_dxdoors
    south = {
        "You push open the glass doors that lie between you and the outside.
            As you do, a grey mist begins pouring through the door. You can't
            see a thing outside. You're not even sure if there _is_ an
            outside. You let the doors swing shut in front of you. ";
        return nil;
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (dog.isWaiting && dog.location == self) {
            "\b<<dog.capdesc>>, upon seeing you, cocks its head at you as
                it stands. The dog is quite a bit larger than it was
                before. ";
            if (rucksack.location == dog)
                "It is wearing the rucksack and, you would swear, grinning at
                    you. ";
            dog.clearProps;
            dog.wantheartbeat = true;
        }
    }
;

other_dxdoors: obstacle, fixedItem
    stage = '2a'
    isThem = true
    swingDoors = true
    islocked = true
    noun = 'door'
    plural = 'doors'
    adjective = 'set' 'two' 'double'
    location = admitting
    sdesc = "set of double doors"
    ldesc = "The doors are spring-loaded so as to close automatically. "
    doordest = purple3
    destination = {
        if (!self.islocked) {
            "You push past the doors, which shut behind you 
                on <<attendant.thedesc>>'s startled exclamation.\b";
            return purple3;
        }
        "The doors are locked. ";
        setit(self);
        return nil;
    }
    verDoKnockon(actor) = {
        "No one answers, though <<attendant.thedesc>> does glare at you. ";
    }
    verDoOpen(actor) = {
        if (self.islocked)
            "The doors are locked. ";
        else "You give the doors a firm push.  They swing open, then back
            shut. ";
    }
    doSynonym('Open') = 'Push'
    verDoClose(actor) = { "They're already closed. "; }
    verDoLock(actor) = {
        "There is no keyhole on this side of the doors. ";
    }
    doSynonym('Lock') = 'Unlock'
    verDoLockWith(actor, io) = (self.verDoLock(actor))
    doSynonym('LockWith') = 'UnlockWith'
;

admitting_chairs: chairitem
    stage = '2a'
    isThem = true
    noun = 'chair'
    plural = 'chairs'
    adjective = 'cheap' 'plastic'
    location = admitting
    sdesc = "plastic chairs"
    ldesc = {
        local list;
        "Plastic chairs, grouped in small sets of three or four. They are
            surprisingly empty; when you worked here, they were always in
            use. Magazines decorate a few of them. ";
        list = contlist(self);
        if (length(list)>0)
            "Also on the chairs %you% see%s% <<listlist(list)>>. ";
    }
;

buncha_magazines: fixeditem, readable
    stage = '2a'
    isThem = true
    myChildren = []
    numChildren = 0
    magNames = ['Ladies\' Home Journal', ['journal', 'home'],
        'Time', 'time',
        'Newsweek', 'newsweek'
        'U.S.\ News and World Report', ['report', 'news', 'world']
        'Healthy Living', ['living', 'healthy'],
        'J.\ Crew', ['catalog', 'crew'],
        'Popular Mechanics', ['mechanics', 'popular'],
        'Popular Science', ['science', 'mechanics']
    ]
    noun = 'magazine'
    plural = 'magazines'
    adjective = 'stack'
    location = admitting
    sdesc = "stack of magazines"
    ldesc = "The magazines are all years out of date. "
    readdesc = "You pick one up and leaf through it. All of its pages are
        slate grey, completely empty. "
    verDoTake(actor) = {}
    doTake(actor) = {            // Create a magazine anew each time
        local newmag, i, j, len, words;

        if ((addweight(actor.contents) + 4) > actor.maxweight) {
            "%Your% load is too heavy. ";
            return;
        }
        if ((addbulk(actor.contents) + 5) > actor.maxbulk) {
            "%You've% already got %your% hands full. ";
            return;
        }
        newmag = new magazineItem;
        "%You% choose%es% a magazine at random from the ones scattered about
            the room. ";
        i = RAND(length(self.magNames)/2);
        newmag.name = self.magNames[i*2 - 1];
        words = self.magNames[i*2];
        if (datatype(words) == 3)
            addword(newmag, &noun, words);
        else {
            addword(newmag, &noun, words[1]);
            len = length(words);
            for (j = 2; j <= len; j++)
                addword(newmag, &adjective, words[j]);
        }
        self.myChildren += newmag;
        self.numChildren++;
        if (self.numChildren > 5)
            notify(self, &removeOne, 3 + RAND(3));
        newmag.moveInto(actor);
    }
    removeOne = {                    // Remove one of the magazines
        delete self.myChildren[1];
        self.numChildren--;
        self.myChildren = cdr(self.myChildren);
    }
    cleanup = {
        local i, len;

        while (getfuse(self, &removeOne) != nil)    // Get rid of leftover
            unnotify(self, &removeOne);             //  fuses
        len = length(self.myChildren);
        for (i = 1; i <= len; i++)
            delete self.myChildren[i];
        self.myChildren = [];
        self.numChildren = 0;
    }
;

class magazineItem: readable
    stage = '2a'
    name = ''
    isEquivalent = true
    noun = 'magazine'
    plural = 'magazines'
    adjective = 'single'
    sdesc = "single magazine"
    ldesc = "It's a copy of <<self.name>> from hospital admissions. "
    pluraldesc = "magazines"
    readdesc = "All of its pages are a uniform slate grey. "
    weight = 4
    bulk = 5
    destruct = {
        if (uberloc(self) == uberloc(Me)) {
            "\b";
            if (self.location.location == Me) {
                "A puff of grey smoke rises from <<
                    self.location.thedesc>>.";
            }
            else {
                "A magazine ";
                if (self.location == Me)
                    "you are carrying";
                else "in the room";
                " begins glowing. Its outline wavers before it turns into a
                    puff of grey smoke.";
            }
            "\n";
        }
        pass destruct;
    }
;

admitting_counter: fixedItem
    stage = '2a'
    noun = 'counter'
    location = admitting
    sdesc = "counter"
    ldesc = "The counter is next to the north hallway. It is pushed nearly
        against the east wall, leaving little room for the attendant
        behind it. Signs dot its front surface. "
;

admitting_signs: readable, decoration
    stage = '2a'
    noun = 'sign'
    plural = 'signs'
    location = admitting
    sdesc = "signs"
    ldesc = "The signs are all ones you remember from your time here:\
        \"Payment expected at time of treatment unless prior arrangements are
        made,\" \"No pets, guide dogs excepted,\" and your personal favorite,
        \"No smoking.\" Someone has raked ashes across the last sign. "
;

admitting_ashes: decoration
    stage = '2a'
    noun = 'ash' 'ashes'
    location = admitting
    sdesc = "ashes"
    ldesc = "The ashes have adhered to the surface of the sign. "
;

attendant: dthing, Actor
    stage = '2a'
    shownPass = nil
    isHer = true
    noun = 'attendant' 'linda'
    location = admitting
    actorDesc = {
        if (self.firstLdesc) "An attendant";
        else "Linda";
        " is here, sitting behind the counter. ";
    }
    sdesc = {
        if (self.firstLdesc) "attendant";
        else "Linda";
    }
    adesc = {
        if (self.firstLdesc) "an attendant";
        else "Linda";
    }
    thedesc = {
        if (self.firstLdesc) "the attendant";
        else "Linda";
    }
    firstdesc = "Glancing at her, you feel a shock of recognition. It's Linda,
        the woman you disliked most while working here. With her flaming
        red hair and her patronizing attitude towards anyone younger than she,
        she was hated by many in the hospital. "
    seconddesc = "Linda has fiery red hair and long black fingernails. She has
        made a career of being angry. "
    disavow = "\"I don't have time for stupid questions.\" She rolls her
        eyes in exasperation. "
    alreadyTold = "\^<<self.thedesc>> says, \"I told you once already. Don't
        you listen?\" "
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "\^<<self.thedesc>> snorts, but otherwise makes no sign that she
                heard you. ";
            exit;
        }
        pass actorAction;
    }
    verDoKick(actor) = { "Not while she's behind the counter. "; }
    verDoKiss(actor) = { "\^<<self.thedesc>> stops you with a well-placed
        grimace. "; }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (dobj != hall_pass)
            "\"You think I've got nothing better to do than look at
                that?\"\ she asks you. ";
        else {
            self.shownPass = true;
            "\^<<self.thedesc>> grimaces. \"Okay, so you can come and go as
                you please. Big deal.\" But she looks distinctly unhappy. ";
            if (dog.location == actor.location)
                "You hear what sounds remarkably like snickering coming
                    from <<dog.thedesc>>. ";
            lindaAh.solve;
        }
    }
;

orange5: hospital_hall
    color = 'orange'
    womanDir = 'west'        // Which way the woman rolls her wheelchair
    womanDest = &west
    num = 'five'
    ldesc = {
        "Two doors, ";
        if (!small_h_womans_door.isopen) "a closed ";
        "one on the north wall and one on the south, flank
            this east-west hall. A sign hangs from the ceiling to the west. ";
    }
    exits = 'north, south, east, and west'
    north = small_h_womans_door
    south = small_h_empty_door
    east = orange4
    west = purple1
;

orange_purple_sign: distantItem, readable
    stage = '2a'
    noun = 'sign'
    plural = 'signs'
    adjective = 'ceiling'
    location = orange5
    sdesc = "ceiling sign"
    ldesc = "The sign hangs from the ceiling to the west. It reads, \"Leave
        Orange/Enter Purple\" in the appropriate colors. "
    readdesc = "\"Leave Orange/Enter Purple\" "
;

small_h_womans_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    adjective = 'small' 'north'
    location = orange5
    sdesc = "north door"
    ldesc = "The <<self.wordDesc>> door leads north.  A plastic
        plaque mounted on it reads \"O7.\" "
    doordest = womans_room
    otherside = womans_room_door
    verDoClose(actor) = "It is frozen in place. "
;

plastic_plaque_o7: decoration, readable
    stage = '2a'
    noun = 'plaque' 'sign'
    plural = 'plaques' 'signs'
    adjective = 'plastic' 'north'
    location = orange5
    sdesc = "north plastic plaque"
    ldesc = "It reads \"O7.\" "
    readdesc = (self.ldesc)
;

small_h_empty_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    adjective = 'small' 'south'
    location = orange5
    sdesc = "south door"
    ldesc = "The <<self.wordDesc>> door leads south.  A plastic
        plaque mounted on it reads \"O6.\" "
    doordest = empty_room
    otherside = empty_room_door
;

plastic_plaque_o6: decoration, readable
    stage = '2a'
    noun = 'plaque' 'sign'
    plural = 'plaques' 'signs'
    adjective = 'plastic' 'south'
    location = orange5
    sdesc = "south plastic plaque"
    ldesc = "It reads \"O6.\" "
    readdesc = (self.ldesc)
;

womans_room: hospital_room
    floating_items = [med_equipment, med_bed]
    sdesc = "Hospital Room"
    ldesc = "A sterile white room, bereft of any humanizing touches. A bed
        surrounded by medical equipment is the sole piece of furniture in
        the room. Judging from its rumpled condition, this room is occupied. "
    exits = 'south'
    south = {
        if (Me.doingCPR) {
            "You break off compressions. \"Stop,\" the doctor says, but you
                are already walking away. ";
            Me.doingCPR = nil;
        }
        return womans_room_door;
    }
    out = { return self.south; }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (old_woman.location != self) return;
        "\bAs you wheel the old woman into the room, she turns to look at
            you. \"Time for bed, I suppose?\"\ she asks you.\b
            She rolls towards the bed. As she nears it, her motions become
            unsteady, her forward motion jerky. \"John?\"\ she murmurs, then
            pitches forward onto the bed. You take a closer look; she's
            not breathing. ";
        old_woman.wantheartbeat = nil;
        old_woman.moveInto(nil);
        sick_woman.moveInto(womans_room);
        setit(sick_woman);
        wheelchair.moveInto(womans_room);
        notify(sick_woman, &mi1, 2);
    }
    leaveRoom(actor) = {
        inherited.leaveRoom(actor);
        if (sick_woman.location == self) {
            small_h_womans_door.isopen = nil;
            small_h_womans_door.islocked = true;
            "As you leave, the door closes behind you";
            if (dog.location == self)
                " and <<dog.thedesc>>";
            ", snicking shut.\b";
        }
    }
;

womans_room_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    location = womans_room
    ldesc = "The door is <<self.wordDesc>>. "
    doordest = orange5
    otherside = small_h_womans_door
    verDoClose(actor) = "It is frozen in place. "
;

med_bed: decoration, wallpaper
    stage = '2a'
    noun = 'bed'
    location = womans_room
    sdesc = "bed"
    ldesc = "A hospital bed, designed for utility rather than comfort. "
;

empty_room: hospital_room
    floating_items = [med_equipment, med_bed]
    womanDir = 'north'       // Which way the woman rolls her wheelchair
    womanDest = &north
    sdesc = "Hospital Room"
    ldesc = "The unoccupied room is an oddity in this hospital. Like other
        hospital rooms, it sports a bed and an excess of medical equipment. "
    exits = 'north'
    north = empty_room_door
    out = empty_room_door
;

empty_room_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    location = empty_room
    ldesc = "The door is <<self.wordDesc>>. "
    doordest = orange5
    otherside = small_h_empty_door
;

cane: complex
    noun = 'cane'
    adjective = 'white' 'red' 'red-tipped'
    location = empty_room
    weight = 5
    bulk = 10
    sdesc = "white cane"
    hdesc = "Leaning in a corner is a white cane. "
    ldesc = "The cane is white with a red tip. Its grip is worn with use. "
    verIoTakeWith(actor) = {}
    ioTakeWith(actor, dobj) = {
        if (dobj.location != crate_gap)
            "There's no need to get <<dobj.thedesc>> with the cane. ";
        else "No matter how hard you try, you are unable to drag anything
            out of the gap with the cane. ";
    }
;

orange4: hospital_hall
    color = 'orange'
    womanDir = 'west'        // Which way the woman rolls her wheelchair
    womanDest = &west
    num = 'four'
    ldesc = "An east-west hall with an orange strip coloring the wall just
        below the ceiling. There is <<small_h_sickman_door.aWordDesc>> door
        in the south wall. "
    exits = 'south and east'
    south = small_h_sickman_door
    east = {
        "As you walk east, the hall lengthens. With each step everything
            blurs, vanishing into a grey mist. Your sense of
            balance is lost; you stumble back the way you came. ";
        return nil;
    }
    west = orange5
;

small_h_sickman_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    adjective = 'small' 'south'
    location = orange4
    sdesc = "south door"
    ldesc = "The <<self.wordDesc>> door leads south.  A plastic
        plaque mounted on it reads \"O5.\" "
    doordest = sickman_room
    otherside = sickman_room_door
;

plastic_plaque_o5: decoration, readable
    stage = '2a'
    noun = 'plaque' 'sign'
    plural = 'plaques' 'signs'
    adjective = 'plastic' 'south'
    location = orange4
    sdesc = "plastic plaque"
    ldesc = "It reads \"O5.\" "
    readdesc = (self.ldesc)
;

sickman_room: hospital_room
    floating_items = [med_equipment, med_bed]
    womanDir = 'north'       // Which way the woman rolls her wheelchair
    womanDest = &north
    sdesc = "Hospital Room"
    ldesc = "In the center of the room, a bed. In the bed, a huddled shape.
        Beside the bed, murmuring equipment. To the north is a door."
    exits = 'north'
    listendesc = {
        if (!sickman.isDead)
            "You hear bubbling, raspy breathing, over which is layered
                the sounds of medical equipment.";
        else pass listendesc;
    }
    smelldesc = "There is a horrendous stench hanging in the room. "
    north = sickman_room_door
    out = sickman_room_door
    firstseen = {
        notify(self, &manSitsUp, 2);
    }
    manSitsUp = {
        if (Me.location != self) {
            notify(self, &manSitsUp, 1);
            return;
        }
        "\bThe shape under the bed sits up, startling you. A withered hand
            grabs you, leaving streaks of blood on your arm. The man is
            trying to say something, a violent exercise which makes his head
            shake with effort. He finally points to the globe on the shelf,
            making a horrible keening noise, before collapsing back under
            the sheets.\n";
    }
;

sickman_room_door: doorItem
    stage = '2a'
    isopen = true
    islocked = nil
    mykey = frankie
    location = sickman_room
    ldesc = "The door is <<self.wordDesc>>. "
    doordest = orange4
    otherside = small_h_sickman_door
;

sickman: dthing, Actor
    askDisambig = true
    stage = '2a'
    isHim = true
    isListed = nil
    isDead = nil
    noun = 'man' 'shape' 'patient'
    adjective = 'sick' 'huddled'
    location = sickman_room
    sdesc = "sick man"
    thedesc = "the sick man"
    adesc = "a sick man"
    firstdesc = {
        "The shape underneath the covers is barely recognizable as a man.
            Tubes snake around and through his body; what skin he still owns
            he wears poorly. ";
        if (self.isDead)
            "He lies still. ";
        else "The rise and fall of his chest are uneven.";
    }
    seconddesc = "The man is clinging to life with an ever-weakening grip. "
    listendesc = {
        if (!self.isDead)
            "His burbling breathing makes you cough in sympathy. ";
        else pass listendesc;
    }
    verGrab(item) = {
        "The man has an iron grip. ";
    }
    verDoKiss(actor) = {
        "You cannot bring yourself to kiss him, so great is your nausea. ";
    }
    verDoAskAbout(actor) = {
        if (self.isDead)
            "The man stays silent. ";
    }
    doAskAbout(actor, iobj) = {
        if (iobj != fuzzy) {
            "The man's eyes grind open for a second, then close. ";
            return;
        }
        if (fuzzy.toldAbout)
            "The man mumbles, his eyelids flutter, but after a brief
                struggle he relaxes. ";
        else {
            "The man's eyes pop open, fever bright. His lips move
                soundlessly; exhausted from the effort, he sinks further
                into his bed. ";
            fuzzy.toldAbout = true;
        }
    }
    verIoGiveTo(actor) = {}
    ioGiveTo(actor, dobj) = {
        if (dobj != fuzzy)
            "The man fails to notice <<dobj.thedesc>>. ";
        else {
            "When you press the globe to the man's chest, his eyes snap
                open. The glow suffuses his face and he smiles, revealing
                gaps once inhabited by teeth. The glow fades, leaving behind
                a lead sphere. The man's muscles relax, allowing
                the sphere to fall to the floor. His whole face sags; his
                breathing stops. ";
            fuzzy.moveInto(nil);
            self.isDead = true;
            lead_sphere.moveInto(sickman_room);
            notify(lead_sphere, &giveMessage, 2);
//            incscore(5);
        }
    }
;

fake_fuzzy_shelf: decoration
    noun = 'shelf'
    stage = '2a'
    location = sickman_room
    sdesc = "shelf"
    ldesc = {
        "A small shelf on the wall. ";
        if (fuzzy.firstPick)
            "A fuzzy globe sits on it. ";
    }
;

fuzzy: complex
    askDisambig = true
    toldAbout = nil
    painLevel = 0
    noun = 'globe'
    adjective = 'fuzzy'
    location = sickman_room
    sdesc = "fuzzy globe"
    ldesc = "Its borders are nebulous; it gives off a faint glow. "
    hdesc = "Lying on a shelf is a strangely-glowing globe."
    touchdesc = "You stroke its outer borders, making your fingers tingle. "
    verDoTake(actor) = {
        if (!hands.numbed) {
            "As your hands close around the globe, you feel a tingling in
                your fingers";
            if (gloves.isworn)
                " even through the gloves";
            ". The tingling quickly grows, becomes horrendous
                pain. You jerk back your hands; the feeling of having dipped
                them in lava fades. ";
            globeAh.see;
        }
    }
    takedesc = {
        "You pick up the globe with your numbed ";
        if (gloves.isworn) "and gloved ";
        "hand. Your fingers feel warm, but the novocaine blocks any pain. ";
        if (!globeAh.solved) {
            notify(self, &shootingPains, 0);
            globeAh.solve;
        }
    }
    shootingPains = {
        if (painLevel == 1 && gloves.isworn) {
            "\bYour hands feel tight inside the gloves, uncomfortably so;
                you peel off the gloves. ";
            gloves.isworn = nil;
        }
        else if (painLevel == 2)
            "\bNumbness begins creeping up your arm. You look down to find
                your hand turning black, beginning to suppurate. Horror, you
                think, I should be feeling horror. But you are as numb to
                your growing disfigurement as your hand is to pain.\n";
        else if (painLevel == 3) {
            "\bYour hand cracks and bleeds, the white pus running from it
                turning red. You stumble back against a wall, holding your
                arm away from you. You close your eyes against the sight,
                amazed that you still feel no pain. Then you make the mistake
                of trying to flex your hand.\b
                Pain, unending pain, until you can bear no more, until...\n";
            unnotify(self, &shootingPains);
            self.wantheartbeat = nil;
            self.painLevel = 0;
            gurney.setup;
        }
        self.painLevel++;
    }
    dobjGen(a, v, i, p) = {
        if (v.touch && !hands.numbed) {
            self.verDoTake(a);
            exit;
        }
    }
    iobjGen(a, v, d, p) = {
        if (v.touch && !hands.numbed && !(v == throwVerb && p == atPrep)) {
            self.verDoTake(a);
            exit;
        }
    }
;

lead_sphere: item
    stage = '2a'
    noun = 'sphere'
    adjective = 'lead'
    sdesc = "lead sphere"
    ldesc = "A dull lead sphere, devoid of any distinguishing marks. "
    weight = 200    // Much too heavy to be picked up
    giveMessage = {
        if (Me.location == self.location)
            "\bThe lead sphere bursts into flame, oily smoke curling from it.
                From the center of the flame you hear an eerily familiar voice
                say, \"So sorry about your hands. Be glad I decided to
                forego the needles this time.\" The voice pauses, then, \"Not
                too much longer, now.\"
                Then the sphere vanishes in a final burst of fire. ";
        self.moveInto(nil);
    }
;

// The object which keeps track of messages from outside
hospitalMessages: object
    messageNum = 1
    summonMessage = {
        switch (messageNum) {
            case 1:
            nurseMessage.setup('Oh!" The voice is fainter than before. "Dr.\ 
                Boozer! In here, behind the crates!');
            "\bA section of the air just above your head shimmers. A small
                pyramid falls from the disturbance to the ground below. ";
            nurseMessage.moveInto(Me.location);
            break;

            case 2:
            doctorMessage.setup('Help me..." Dr.\ Boozer\'s voice fades in and
                out, a poorly-tuned radio station.
                "...on the gurney...ambulance...arms and legs...');
            "\bThe air just above you begins shimmering. From the disturbance
                falls a smallish cube. ";
            doctorMessage.moveInto(Me.location);
            break;

            default:
                return;
        }
        self.messageNum++;
    }
;

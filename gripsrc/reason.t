/*
    Reason, part four a of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: reason.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

class crystal_piece: surface
    isCrystal = true
    weight = 8
    bulk = 5
    noun = 'piece' 'crystal'
    plural = 'pieces'
    adjective = 'crystal'
    sdesc = "<<self.color>> crystal piece"
    ldesc = {
        local conts;

        conts = deeplistcont(self);
        "The piece is heavy crystal of a translucent <<self.color>> color. It
            is square on four sides; its top and bottom are irregularly shaped. ";
        if (length(conts) > 0)
            "On it you see <<listlist(conts)>>. ";
    }
    // showcontents (from look.t) modified to show _all_ contents
    showcontents = {
        local list;
        list = deeplistcont(self);
        if (length(list)>0)
            "Sitting on <<self.thedesc>> is <<listlist(list)>>. ";
        listfixedcontents(self);
    }
    doPutOn(actor, io) = {
        self.moveInto(io);
        if (io == self.lowerCrystal)
            "It clicks neatly into place. ";
        else if (io.isCrystal)
            "After you place <<self.thedesc>> on <<io.thedesc>>, you
                notice that the surfaces of the two crystals don't
                quite match up, leaving gaps between them. ";
        else "Done. ";
    }
    verIoPutOn(actor) = {
        if (self.location == actor)
            "Not until you put <<self.thedesc>> down. ";
    }
    ioPutOn(actor, dobj) = {
        if (!dobj.isCrystal)
            "There's no good surface on <<self.thedesc>>. ";
        else if (length(contlist(self)) > 0)
            "There's no more room on <<self.thedesc>>. ";
        else pass ioPutOn;
    }
    verIoAttachTo(actor) = {}
    ioAttachTo(actor, dobj) = {
        if (!dobj.isCrystal) {
            "There is no need to attach <<self.thedesc>> to <<dobj.thedesc>>. ";
            return;
        }
        if (dobj == self.lowerCrystal) {
            if (self.location == dobj)
                "\^<<self.thedesc>> is already on <<dobj.thedesc>>. ";
            else if (dobj.location == actor)
                "Not until you put <<dobj.thedesc>> down. ";
            else dobj.ioPutOn(actor, self);
        }
        else {
            if (dobj.location == self)
                "\^<<dobj.thedesc>> is already on <<self.thedesc>>. ";
            else if (self.location == actor)
                "Not until you put <<self.thedesc>> down. ";
            else self.ioPutOn(actor, dobj);
        }
    }
    verDoAttachTo(actor, io) = {
        if (!io.isCrystal) "There is no need. ";
    }
    verDoTake(actor) = {
        local conts;

        conts = deeplistcont(self);
        if (length(conts) > 0)
            "Not while <<listlist(conts)>> <<length(conts) > 1 ? "are" : "is"
                >> on it. ";
        else pass verDoTake;
    }
    // pileCheck is a recursive function which traverses down the lowerCrystal
    //  list to see if everyone is where they're supposed to be. If so, the
    //  heavens opens up and the player is caught up in a bright light.
    //  This entire chain is started by violet_piece, the uppermost piece.
    pileCheck = {
        // If lowerCrystal = nil, we're at the bottom
        if (self.lowerCrystal != nil) {
            if (self.location == self.lowerCrystal)
                self.lowerCrystal.pileCheck;
        }
        // We must be on the pedestal for the skies to open
        else if (self.location == pedestal) {
            crystalsAh.solve;
            "A shaft of light shoots up through the six crystal pieces and
                splashes against the ceiling. The abstract patterns contract,
                opening a hole for the light. As the ceiling continues to
                open you feel the pull of the shaft of light. It lifts you
                up and into it, surrounds you with warmth. When next you look
                down the floor is far below you and the shaft of light is
                dimming.\b
                Marie is here, wherever here is. ";
            if (dog.location == argument_room)
                "She is holding <<dog.thedesc>>, who regards you calmly. ";
            "\"Terry,\" she says warmly. \"I knew you'd be done quickly.\"
                She frowns slightly. \"Had you been taking care of things
                in here, you wouldn't have had to jump through all those
                hoops for me.\"\b
                There is a loud buzzing. The space around you is shot through
                with vivid white light. Marie looks away, blinking fiercely";
            if (dog.location == argument_room)
                " while <<dog.thedesc>> whines";
            ". \"We don't have much time,\" Marie says, talking much faster
                than before. \"They're trying to pull you back. But you're not
                done here.\" Then she is moving away, or you are, and her
                voice floats back, ";
            if (Me.ctrlPoints > 0)
                "\"Don't let him--\"\b";
            else "\"Watch what he--\"\b";
            short_interlude();
        }
    }
;

red_piece: crystal_piece
    color = 'red'
    adjective = 'red'
    location = pedestal
    lowerCrystal = nil
    doPutOn(actor, io) = {
        self.moveInto(io);
        if (io == self.lowerCrystal)
            "It clicks neatly into place. ";
        else if (io == pedestal)
            "The red crystal piece slides onto the pedestal as if magnetically
                attracted. ";
        else "Done. ";
    }
;

orange_piece: crystal_piece
    color = 'orange'
    adjective = 'orange'
    location = shelf_9
    adesc = "an orange crystal piece"
    lowerCrystal = red_piece
    verifyRemove(actor) = {
        if (uberloc(self) == inside_transform_box &&
            transform_lever.pos != 1)
            "The orange piece seems glued to the shelf, as little success as
                you have in taking it. ";
        else if (self.location == transform_box_room && transform_lever.pos
            != 4)
            "The orange piece moves, but refuses to budge beyond a certain
                point. When you let it go it snaps back in place. ";
        else pass verifyRemove;
    }
;

yellow_piece: crystal_piece, treasure
    color = 'yellow'
    worth = 4
    adjective = 'yellow'
    location = inside_cube
    lowerCrystal = orange_piece
    firstMove = {
        yellowAh.solve;
        pass firstMove;
    }
;

green_piece: crystal_piece
    color = 'green'
    adjective = 'green'
    lowerCrystal = yellow_piece
;

blue_piece: crystal_piece
    color = 'blue'
    adjective = 'blue'
    lowerCrystal = green_piece
;

violet_piece: crystal_piece
    color = 'violet'
    worth = 4
    firstPick = true
    adjective = 'violet'
    location = infinite_plane_infinity
    lowerCrystal = blue_piece
    moveInto( location ) = {
        inherited.moveInto(location);
        if (self.firstPick && location == Me) {
            self.firstPick = nil;
            incscore(self.worth);
            violetAh.solve;
        }
    }
    // doPutOn, for the violet piece, will look to see if all the pieces are
    //  properly aligned
    doPutOn(actor, io) = {
        self.moveInto(io);
        if (io == self.lowerCrystal) {
            "It clicks neatly into place. ";
            io.pileCheck;
        }
        else "Done. ";
    }
;

center: insideRm
    sdesc = "Domed Room"
    ldesc = "The roof above you is domed, abstract patterns inscribed on
        it. Light filters through parts of the dome, stippling the floor.
        Some of the light reflects from a pedestal in the exact center of the
        room. Exits from the room lead in each of the four cardinal directions,
        and a hole in the floor leads down. "
    exits = 'north, south, east, west, and down'
    north = cube_room_2
    south = {
        "The exit bends to the southwest.\b";
        return hall_curved_floor;
    }
    east = transform_box_room
    west = texture_room_4
    down = {
        infinite_plane_one.comingDown = true;
        "You waft gently down.\b";
        return infinite_plane_one;
    }
    firstseen = {
        crystalsAh.see;
    }
;

center_patterns: distantItem
    noun = 'pattern' 'patterns'
    adjective = 'abstract'
    location = center
    sdesc = "abstract patterns"
    ldesc = "The patterns seem to swirl whenever you catch a glimpse of them
        out of the corner of your eye. "
;

center_light: fixedItem
    noun = 'light'
    location = center
    sdesc = "light"
    ldesc = "It drifts down through parts of the dome. "
;

center_dome: distantItem
    noun = 'dome' 'roof'
    location = center
    sdesc = "dome"
    ldesc = "It arches above you. "
;

center_hole: fixedItem
    noun = 'hole'
    location = center
    sdesc = "hole"
    ldesc = "You can't tell where it leads. "
    verDoEnter(actor) = {}
    doEnter(actor) = {
        actor.travelTo(center.down);
    }
;

pedestal: fixedItem, surface
    noun = 'pedestal'
    location = center
    sdesc = "pedestal"
    ldesc = {
        local conts;

        "It is short and squat, rising barely half a meter from the floor. ";
        conts = deeplistcont(self);
        if (length(conts) > 0)
            "On the pedestal you see <<listlist(conts)>>. ";
    }
    ioPutOn(actor, dobj) = {
        if (!dobj.isCrystal)
            "\^<<dobj.thedesc>> slide<<dobj.isThem ? "" : "s">> off. ";
        else pass ioPutOn;
    }
    showcontents = {
        local conts;

        conts = deeplistcont(self);
        if (length(conts) > 0)
            "Sitting on the pedestal you see <<listlist(conts)>>. ";
    }
;

/*
** The textured rooms
*/

rp_daemon: object
    patchNum = 1
    patches = [rp_1, rp_2, rp_3, rp_4, rp_5, rp_6]
    patchOrder = [1, 5, 4, 2, 6, 3]
    patchOk = true
    pieceProduced = nil
    reset = {
        for (patchNum = 1; patchNum < 7; patchNum++)
            patches[patchNum].isDepressed = nil;
        patchNum = 1;
        patchOk = true;
    }
;

class raised_patch: fixedItem
    isDepressed = nil
    noun = 'patch' 'pattern'
    adjective = 'raised'
    sdesc = {
        if (!self.isDepressed) "raised ";
        "patch";
    }
    ldesc = {
        "The patch is about thirty centimeters on a side";
        if (!isDepressed)
            " and raised slightly above the rest of the floor";
        ". A pattern is inscribed across its surface, too fine for you to tell
            anything about it. ";
    }
    touchdesc = {
        if (gloves.isworn)
            "With the gloves, you feel nothing unusual. ";
        else "The patch feels <<self.texturedesc>>. ";
    }
    verDoPush(actor) = {
        if (isDepressed)
            "The patch will go no further. ";
    }
    doPush(actor) = {
        "You press the raised patch, which sinks until it is flush with the
            floor. ";
        isDepressed = true;
        if (rp_daemon.patchOrder[rp_daemon.patchNum] != self.num)
            rp_daemon.patchOk = nil;
        if (++rp_daemon.patchNum == 7) {
            "Almost immediately the entire room begins to shake. ";
            if (!rp_daemon.patchOk)
                "The floor begins to split apart, but halts after it has
                    spread only a few centimeters. It then reverses direction
                    and reseals. ";
            else {
                "The floor splits along the creases, gaping wider and wider.
                    From under the floor a mechanical hand appears";
                if (rp_daemon.pieceProduced)
                    ". It turns towards you and very calmly flips you the
                        bird before vanishing underneath the closing floor. ";
                else {
                    ", holding a green crystal piece. It deposits the piece on
                        the floor and withdraws before the floor closes again. ";
                    green_piece.moveInto(actor.location);
                    rp_daemon.pieceProduced = true;
                    greenAh.solve;
                    incscore(4);
                }
            }
            "The depressed sections of the floor then spring back up. ";
            rp_daemon.reset;
        }
    }
;

/*
** The rooms are arranged as follows:
** 1  2
** 3  4
** 5  6
*/
class textureRm: insideRm
    isTextureRm = true
    floordesc = "You notice a patch of the floor which looks different from the
        rest. "

;

// Feeling theFloor should result in the patch being mentioned
modify theFloor
    touchdesc = {
        if (Me.location.isTextureRm) {
            if (gloves.isworn)
                "You can feel nothing unusual through the gloves. ";
            else "As you run your fingers along the floor you notice that a
                patch of it has an odd texture. ";
        }
        else "You feel nothing unusual. ";
    }
;

texture_room_1: textureRm
    sdesc = "Northwest Corner of Sloping Room"
    ldesc = "The room is creased in a line running from the corner to near
        the center. Though the crease marks the low junction of the floor,
        the entire floor on either side of the crease slopes down towards the
        center. "
    exits = 'south, east, and southeast'
    south = texture_room_3
    east = texture_room_2
    se = texture_room_4
;

rp_1: raised_patch
    num = 1
    adjective = 'rough'
    location = texture_room_1
    texturedesc = "rough"
;

texture_room_2: textureRm
    sdesc = "Northeast Corner of Sloping Room"
    ldesc = "The floor of the room is creased, as if the floor of a much
        larger room was forced into this one. The room continues to the west
        and south. "
    exits = 'south, west, and southwest'
    south = texture_room_4
    west = texture_room_1
    sw = texture_room_3
;

rp_2: raised_patch
    num = 2
    adjective = 'barely' 'smooth'
    location = texture_room_2
    texturedesc = "barely smooth"
;

texture_room_3: textureRm
    sdesc = "West Side of Sloping Room"
    ldesc = "You are forced to stand at an angle due to the floor's slope
        towards the center of the room. North, south, and east is the rest
        of the room. "
    exits = 'north, south, east, northeast, and southeast'
    north = texture_room_1
    south = texture_room_5
    east = texture_room_4
    ne = texture_room_2
    se = texture_room_6
;

rp_3: raised_patch
    num = 3
    adjective = 'smooth'
    location = texture_room_3
    texturedesc = "smooth"
;

texture_room_4: textureRm
    tripped = nil
    sdesc = "East Side of Sloping Room"
    ldesc = "The room is huge, the size of your old church's fellowship hall.
        The floor slopes noticeably from a high point at the east doorway to
        a low point to the west. The remainder of the room lies to the north,
        south, and west. Next to the doorway a white rectangle is mounted. "
    exits = 'north, south, east, west, northwest, and southwest'
    north = texture_room_2
    south = texture_room_6
    east = center
    west = texture_room_3
    nw = texture_room_1
    sw = texture_room_5
    out = center
    firstseen = {
        greenAh.see;
        pass firstseen;
    }
    leaveRoom(actor) = {
        if (!tripped && RAND(100) < 50) {
            tripped = true;
            "As you are walking out of the room, you trip over a patch of the
                floor.\b";
        }
        pass leaveRoom;
    }
;

white_rectangle: fixedItem
    noun = 'rectangle'
    adjective = 'white'
    location = texture_room_4
    sdesc = "white rectangle"
    ldesc = "It resembles the floor. Subtle gradations of light play across
        its surface, revealing changes in its texture. "
    touchdesc = {
        if (gloves.isworn)
            "Through the thick fingers of the gloves you feel nothing untoward. ";
        else "As you run your fingers along its length, you feel it surface
            shade from sandpapery rough to nearly frictionless. ";
    }
;

rp_4: raised_patch
    num = 4
    adjective = 'barely' 'rough'
    location = texture_room_4
    texturedesc = "barely rough"
;

texture_room_4_doorway: myDoorway
    location = texture_room_4
    ldesc = "It leads east. "
    lookthrudesc = "You can see the domed room beyond. "
    doordest = center
;

texture_room_5: textureRm
    sdesc = "Southwest Corner of Sloping Room"
    ldesc = "A fold in the floor points northeast from the corner. More of
        the room lies east and north. "
    exits = 'north, east, and northeast'
    north = texture_room_3
    east = texture_room_6
    ne = texture_room_4
;

rp_5: raised_patch
    num = 5
    adjective = 'fairly' 'rough'
    location = texture_room_5
    texturedesc = "fairly rough"
;

texture_room_6: textureRm
    sdesc = "Southeast Corner of Sloping Room"
    ldesc = "The floor has been folded, resulting in a crease running from
        southeast to northwest. To the north and west the room continues. "
    exits = 'north, west, and northwest'
    north = texture_room_4
    west = texture_room_5
    nw = texture_room_3
;

rp_6: raised_patch
    num = 6
    adjective = 'fairly' 'smooth'
    location = texture_room_6
    texturedesc = "fairly smooth"
;

/*
** Transform box room
*/

transform_box_room: insideRm
    sdesc = "Arching Chamber"
    ldesc = {
        "The chamber is roofed by two arches at right angles to each other,
            the ceiling drooping between each arch. Beneath the arches";
        if (transform_box.location == self)
            ", slightly off-center, a large box floats. To one side of it";
        " is a free-standing panel. Alone in one part of the chamber a
            doorframe incongruously stands alone, a smaller version of the
            west exit. ";
    }
    exits = 'west'
    west = center
    out = center
;

transform_box_arches: decoration
    noun = 'arch' 'arches'
    adjective = 'two' 'white' 'marble'
    location = transform_box_room
    sdesc = "arches"
    ldesc = "The arches are white marble and stand about six meters high. "
;

transform_box: fixedItem
    noun = 'box'
    adjective = 'large' 'white'
    location = transform_box_room
    sdesc = "white box"
    ldesc = "A square white box a meter and a half on each side. It is
        featureless; it floats above the ground. "
    takedesc = "The box gives ground somewhat, but refuses to move past a
        certain point. When you let go it drifts back to its original
        position. "
    verDoOpen(actor) = "You can find no way to open the box. "
    verDoClimb(actor) = "As smooth as it is, you are unable to find sufficient
        footing. "
;

transform_panel: fixedItem
    noun = 'panel'
    adjective = 'free-standing'
    location = transform_box_room
    sdesc = "free-standing panel"
    ldesc = "Its face is studded with three buttons, each of which has a
        small display above it. Next to the row of buttons is a large lever
        and metal plaque. "
;

transform_plaque: fixedItem
    noun = 'plaque'
    adjective = 'metal'
    location = transform_box_room
    sdesc = "metal plaque"
    ldesc = "Imprinted on it in raised letters is the following:\b
tr:\ \ \ x' = x - c; y' = y + c; z' = z + c\n
rot:\ \ x' = r cos(t); y' = r sin(t); t = -90\n
inv:\ \ r' = 1/r"
    verDoRead(actor) = {}
    doRead(actor) = self.ldesc;
;

transform_lever: fixedItem
    pos = 1
    frozen = nil
    posNames = [ 'first' 'second' 'third' 'fourth' ]
    displayObjs = [ left_display mid_display right_display ]
    noun = 'lever'
    adjective = 'large'
    location = transform_box_room
    sdesc = "large lever"
    ldesc = "The lever consists of two parallel pieces of metal connected by a
        round handle, much like a plane's throttle. It has four possible
        positions; currently it is in the <<self.posNames[self.pos]
        >> position. "
    verDoPull(actor) = {
        if (self.frozen)
            "The lever is frozen. ";
        else if (self.pos == 4)
            "The lever will move no closer to you. ";
    }
    doPull(actor) = {
        local i;
        
        "You pull the lever one position closer to you. ";
        self.frozen = true;
        if (orange_piece.location == transform_box_room) {
            "The orange piece trembles, then vanishes in a flurry of orange
                dust. ";
            orange_piece.moveInto(nil);
            orange_powder.moveInto(nil);
            return;
        }
        i = (self.displayObjs[self.pos]).num;
        if (i == 3) {
            "The box trembles, then inverts. ";
            if (uberloc(orange_piece) == inside_transform_box) {
                if (orange_piece.location != shelf_8) {
                    "You see a flash of orange, a momentary glimpse of a
                        crystal piece with the inverted box jutting out at an
                        improbable angle, and then the entire structure
                        vanishes. Air whumps into the space formerly occupied
                        by the box. ";
                }
                else {
                    "You see the orange crystal piece inverting with the box.
                        The box dwindles into the center of the piece, which
                        looks the same inverted as not. ";
                    if (self.pos == 3) {
                        "After the orange piece has swallowed the inverted
                            box, it settles gently to the ground. ";
                        incscore(4);
                        orangeAh.solve;
                    }
                    else {
                        "The orange piece hangs in midair, frozen in place. ";
                        self.frozen = nil;
                    }
                    orange_piece.moveInto(transform_box_room);
                }
            }
            else {
                "The box lasts for only a moment in this strained state before
                    vanishing with a whump of air. ";
            }
            transform_box.moveInto(nil);
        }
        else {
            "The box trembles, moving slightly. ";
            transform_daemon.movePiece(i);
            if (orange_piece.location != nil)
                self.frozen = nil;
        }
        self.pos++;
    }
    verDoPush(actor) = {
        if (self.frozen)
            "The lever is frozen. ";
        else if (self.pos == 1)
            "The lever will go no further. ";
    }
    doPush(actor) = {
        local i;
        
        "You push the lever away from you. ";
        i = (self.displayObjs[self.pos - 1]).num;
        if (i == 3) {
            "The orange piece trembles, then inverts. It is swallowed by
                the box which reappears. ";
            orange_piece.moveInto(shelf_8);
            transform_box.moveInto(transform_box_room);
        }
        else {
            "The box trembles, moving slightly. ";
            transform_daemon.revmovePiece(i);
        }
        self.pos--;
    }
;

transform_daemon: object
    displayStrings = [ 'tr' 'rot' 'inv' ]
    incNumber(display) = {
        display.num++;
        if (display.num > 3)
            display.num = 1;
    }
    movePiece(i) = {
        local prop;
        
        if (i == 1)
            prop = &translate;
        else prop = &rotate;
        if (proptype(orange_piece.location, prop) == 2)
            orange_piece.moveInto(orange_piece.location.(prop));
        else {
            orange_piece.location.(prop);
            if (proptype(orange_piece.location, prop) != 6)
                orange_powder.moveInto(transform_box_room);
            orange_piece.moveInto(nil);
        }
    }
    revmovePiece(i) = {
        local prop;
        
        if (i == 1)
            prop = &invtranslate;
        else prop = &invrotate;
        if (proptype(orange_piece.location, prop) == 2)
            orange_piece.moveInto(orange_piece.location.(prop));
        else {
            "An angelic host from on high appears, singing, \"Yooooouuu've
                discovered a buuuuuuuuug; pleeeeeease tell Author
                Steeeeeephen.\" The harmonising is quite nice. The heavenly
                host vanishes; the symbols \"sgranade@phy.duke.edu\" appear
                momentarily in flaming letters before disappearing as well. ";
        }
    }
;

class transform_button: buttonItem
    myDisplay = nil
    location = transform_box_room
    ldesc = "A red button about five centimeters in diameter. "
    verDoPush(actor) = {
        if (transform_lever.pos != 1 || transform_box.location == nil)
            "The button refuses to move. ";
    }
    doPush(actor) = {
        transform_daemon.incNumber(self.myDisplay);
        "The button clicks as you depress it. The display above the button
            changes to read \"<<
            transform_daemon.displayStrings[self.myDisplay.num]>>\". ";
    }
;

class transform_display: fixedItem
    num = 1
    noun = 'display'
    plural = 'displays'
    location = transform_box_room
    ldesc = {
        if (transform_box.location == nil)
            "The display is blank. ";
        else "The display reads \"<<transform_daemon.displayStrings[self.num]
            >>\" in glowing red letters. ";
    }
;

left_button: transform_button
    myDisplay = left_display
    adjective = 'left'
    sdesc = "left button"
;
mid_button: transform_button
    myDisplay = mid_display
    adjective = 'middle' 'center'
    sdesc = "middle button"
;
right_button: transform_button
    myDisplay = right_display
    adjective = 'right'
    sdesc = "right button"
;

left_display: transform_display
    num = 3
    adjective = 'left'
    sdesc = "left display"
;
mid_display: transform_display
    num = 1
    adjective = 'middle'
    sdesc = "middle display"
;
right_display: transform_display
    num = 2
    adjective = 'right'
    sdesc = "right display"
;

transform_door_frame: fixedItem
    firstTrip = true
    noun = 'frame' 'doorframe' 'door'
    adjective = 'door'
    location = transform_box_room
    sdesc = "doorframe"
    ldesc = "It stands with no visible means of support. You can see through
        it from both sides. "
    doLookthru(a) = "You see the rest of the chamber. "
    verDoOpen(actor) = "There is nothing on it to open or close. "
    verDoClose(actor) = { self.verDoOpen(actor); }
    verDoEnter(actor) = {
        if (transform_box.location != transform_box_room)
            "You step through the doorframe but go nowhere. ";
    }
    doEnter(actor) = {
        local flag = nil;

        if (self.firstTrip) {
            self.firstTrip = nil;
            "In a blink you are elsewhere.";
            flag = true;
        }
        if (length(contlist(Me)) > 0) {
            if (flag) " In transit y";
            else "Y";
            "ou feel your possessions pulled from your grasp.\b";
            moveAllCont(Me, transform_door_frame);
        }
        else if (flag) "\b";
        actor.travelTo(inside_transform_box);
    }
;

inside_transform_box: room
    neverLeft = true
    sdesc = "Inside the Box"
    ldesc = "Either the box is larger inside than out or you are smaller, for
        you fit easily inside it. The white walls of the box are lit by a
        diffuse, sourceless light. Shelves dot the room, so many that you can
        barely move. A pole runs through the west side of the box. "
    firstseen = {
        orangeAh.see;
        pass firstseen;
    }
    getOut = {
        local flag = nil;
        
        if (self.neverLeft) {
            self.neverLeft = nil;
            "The walls shimmer around you.";
            flag = true;
        }
        if (orange_piece.location == Me) {
            orange_piece.moveInto(shelf_9);
            if (flag) " ";
            "You feel the orange piece ripped from your hands as you leave.\b";
        }
        else if (flag)
            "\b";
        moveAllCont(transform_door_frame, Me);
        return transform_box_room;
    }
    north = self.getOut
    south = self.getOut
    east = self.getOut
    west = self.getOut
    ne = self.getOut
    nw = self.getOut
    se = self.getOut
    sw = self.getOut
    up = self.getOut
    down = self.getOut
    out = self.getOut
;

box_pole: fixedItem
    noun = 'pole'
    location = inside_transform_box
    sdesc = "pole"
    ldesc = "The pole is oriented vertically and touches the west wall,
        running through the bottom and top west shelves. "
;

class tshelf: surface, fixedItem
    noun = 'shelf'
//    plural = 'shelves'
    stage = 0
    location = inside_transform_box
    ldesc = {
        local cont;

        self.shelfdesc;
        if (length(cont = contlist(self)) > 0)
            "Sitting on the shelf you see <<listlist(cont)>>. ";
    }
    verDoClimb(actor) = {
        "You place a foot on the shelf; it bends alarmingly, and you to
            desist. ";
    }
;

orange_powder: fixedItem
    noun = 'powder' 'dust'
    adjective = 'orange'
    isListed = true
    sdesc = "orange powder"
    ldesc = "The orange powder glints as you look at it. "
    adesc = "some orange powder"
    takedesc = "The powder is sharper than it looks. You carefully dust it
        off your fingers, drawing blood. "
    touchdesc = (self.takedesc)
;

plural_shelves: fixedItem
    firstLdesc = true
    noun = 'shelves'
    location = inside_transform_box
    sdesc = "shelves"
    ldesc = "You can only specify one shelf at a time. "
    dobjGen(a, v, i, p) = {
        if (v != inspectVerb && !(v.issysverb)) {
            "You must specify each shelf in turn. ";
            exit;
        }
        else if (v == inspectVerb) {
            "For the most part, the shelves hug the walls of the cube. They
                are arranged in three distinct layers, like those of a cake,
                with five shelves in each layer. The shelves in the top and
                bottom layers form a cross, with a shelf attached to the
                walls in each cardinal direction and one in the middle of the
                floor and ceiling. The shelves in the middle layer form an
                'X', with shelves in the northeast, northwest, southeast, and
                southwest corners and one in the exact center of the box. ";
            if (self.firstLdesc) {
                "\b[The following naming convention is used:\ the top and bottom
                    layer of shelves are referred to by those names plus their
                    direction, e.g.\ \"top
                    northern shelf\" or \"bottom e shelf\". Shelves in
                    the middle layer are named by their direction, e.g.\ 
                    \"northwestern shelf\". The exceptions
                    are the three shelves in the center of the room. The top
                    and bottom middle shelves are just that, \"top middle\" and
                    \"bottom middle\". The shelf in the exact center of the
                    room is the \"center shelf\".] ";
                self.firstLdesc = nil;
            }
            exit;
        }
    }
    iobjGen(a, v, d, p) = { self.dobjGen(a, v, d, p); }
;

shelf_1: tshelf
    adjective = 'bottom' 'north' 'northern' 'n'
    sdesc = "bottom northern shelf"
    shelfdesc = "The shelf on the north wall, near the bottom. "
    translate = "An orange crystal piece makes a brief appearance on the
        north side of the box before falling to shatter on the floor beneath. "
    rotate = shelf_5
;

shelf_2: tshelf
    adjective = 'bottom' 'west' 'western' 'w'
    sdesc = "bottom western shelf"
    shelfdesc = "The shelf on the west side of the box, near the bottom. "
    translate = "An orange piece shimmers into existence next to the northwest
        corner of the box. It falls the the floor and shatters. "
    rotate = shelf_2
    invrotate = shelf_2
;

shelf_3: tshelf
    adjective = 'bottom' 'middle'
    sdesc = "bottom middle shelf"
    shelfdesc = "It lies in the exact middle of the box, slightly above the
        bottom. "
    translate = shelf_6
    rotate = "An orange crystal piece suddenly juts from the southwest corner
        of the white box before it is reduced to powder by the stress of
        coexisting with the sides of the box. "
;

shelf_4: tshelf
    adjective = 'bottom' 'east' 'eastern' 'e'
    sdesc = "bottom eastern shelf"
    shelfdesc = "It is attached to the east side of the box, near the bottom. "
    translate = {
        "You hear something shatter inside the box. ";
        orange_powder.moveInto(shelf_1);
    }
    rotate = "You see an orange crystal appear southwest of the white box; it
        falls to the floor, where it shatters into powder. "
;

shelf_5: tshelf
    adjective = 'bottom' 'south' 'southern' 's'
    sdesc = "bottom southern shelf"
    shelfdesc = "A smallish shelf located on the box's south wall. "
    translate = {
        "You hear something shatter inside the box. ";
        orange_powder.moveInto(shelf_2);
    }
    rotate = "You see an orange crystal appear southwest of the white box; it
        falls to the floor, where it shatters into powder. "
    invrotate = shelf_1
;

shelf_6: tshelf
    adjective = 'northwest' 'northwestern' 'nw'
    sdesc = "northwestern shelf"
    shelfdesc = "The shelf is in the northwest corner of the box at chest
        level. "
    translate = "A piece of orange crystal flickers into existence above the
        and to the northwest of the box. It falls to the floor and breaks. "
    rotate = shelf_8
    invtranslate = shelf_3
;

shelf_7: tshelf
    adjective = 'northeast' 'northeastern' 'ne'
    sdesc = "northeastern shelf"
    shelfdesc = "Smallish and located in the northeast corner of the box at
        chest level. "
    translate = "Above the box, just north of it, an orange crystal piece
        appears before plummeting to the floor and fragmenting. "
    rotate = "To the south of the box an orange crystal piece appears, falling
        and breaking before you can catch it. "
;

shelf_8: tshelf
    adjective = 'center'
    sdesc = "center shelf"
    shelfdesc = "It has the distinction of being in the exact center of the
        box. "
    translate = {
        "From inside the box you hear a tinkling crash. ";
        orange_powder.moveInto(shelf_6);
    }
    rotate = shelf_9
    invrotate = shelf_6
;

shelf_9: tshelf
    adjective = 'southwest' 'southwestern' 'sw'
    sdesc = "southwestern shelf"
    shelfdesc = "A shelf in the southwest corner of the box, at chest height. "
    translate = "An orange crystal piece appears above the box to the west. It
        falls, glancing off one side of the box and turning to powder. "
    rotate = "An orange crystal piece appears just west of the box. It falls
        and breaks. "
    invrotate = shelf_8
;

shelf_10: tshelf
    adjective = 'southeast' 'southeastern' 'se'
    sdesc = "southeastern shelf"
    shelfdesc = "A smallish shelf at chest level in the southeast corner. "
    translate = shelf_13
    rotate = "You notice an orange piece protruding from the southwest corner
        of the box. Seconds later it is shredded by the strain of coexisting
        with the box. "
;

shelf_11: tshelf
    adjective = 'top' 'north' 'northern' 'n'
    sdesc = "top northern shelf"
    shelfdesc = "The shelf is on the north wall, a foot or so above your
        head. "
    translate = "An orange crystal piece appears northwest of the box and
        far above it. Predictably, it falls and breaks. "
    rotate = shelf_15
;

shelf_12: tshelf
    adjective = 'top' 'west' 'western' 'w'
    sdesc = "top western shelf"
    shelfdesc = "It is over a foot above your head, barely reachable, and
        is on the west wall. "
    translate = "An orange crystal piece appears northwest of the box and
        far above it. Predictably, it falls and breaks. "
    rotate = shelf_12
    invrotate = shelf_12
;

shelf_13: tshelf
    adjective = 'top' 'middle'
    sdesc = "top middle shelf"
    shelfdesc = "The shelf is in the middle of the box, suspended from the
        ceiling a foot or so above your head. "
    translate = "Above you, northwest of the box, an orange crystal piece
        appears shortly before it plummets to the floor and shatters. "
    rotate = "The southwest corner of the box is suddenly obscured by an
        orange crystal piece. The crystal shatters. "
    invtranslate = shelf_10
;

shelf_14: tshelf
    adjective = 'top' 'east' 'eastern' 'e'
    sdesc = "top eastern shelf"
    shelfdesc = "A shelf on the east side of the box, over a foot above your
        head. "
    translate = "Above your head, north of the box, an orange crystal piece
        appears and falls to the unyielding floor below. "
    rotate = "An orange crystal piece pops into existence southwest of the
        box. It falls and shatters. "
;

shelf_15: tshelf
    adjective = 'top' 'south' 'southern' 's'
    sdesc = "top southern shelf"
    shelfdesc = "The smallish shelf is attached to the south wall a foot
        or so above you. "
    translate = "Far above you, west of the box, an orange crystal piece
        appears and falls to its powdery death. "
    rotate = "An orange crystal piece appears southwest of the box, where it
        falls to the floor and shatters. "
    invrotate = shelf_11
;

/*
** Many-sided room
*/

hall_curved_floor: insideRm
    sdesc = "Rounded Teak Hall"
    ldesc = "A hall of worn teak. Its floor is curved, as if cut from the
        bottom of a sphere.  Passages curve up to the north, south, east,
        and west. Another hall splits off to the northeast. Above you is
        an opening, barely within reach. "
    exits = 'north, south, east, west, northeast, and up'
    north = hall_north_wall
    south = hall_south_wall
    east = hall_east_wall
    west = hall_west_wall
    ne = {
        "The northeast passage curves until it is running north.\b";
        return center;
    }
    up = {
        "You pull yourself through the opening.\b";
        return many_sided_floor;
    }
;

hall_curved_floor_opening: decoration
    noun = 'opening'
    location = hall_curved_floor
    sdesc = "opening"
    ldesc = "The opening leads up. "
    verDoEnter(actor) = {}
    doEnter(actor) = {
        actor.travelTo(actor.location.up);
    }
;

hall_north_wall: insideRm
    sdesc = "North Side of Curving Hall"
    ldesc = "The teak hall curves southeast to southwest, with symmetrical
        offshoots leading up and down. To the south is a square opening. "
    exits = 'south, southeast, southwest, up, and down'
    south = {
        ms_daemon.enterWallDesc;
        return many_sided_north;
    }
    se = hall_east_wall
    sw = hall_west_wall
    up = hall_curved_ceiling
    down = hall_curved_floor
;

hall_south_wall: insideRm
    sdesc = "South Side of Curving Hall"
    ldesc = "The passages which make up the teak hall curve as if on the
        surface of a sphere. The semicircular branches leading northeast and
        northwest are mirrored by the branches leading up and down. Only an
        opening to the north breaks the symmetry. "
    exits = 'north, northeast, northwest, up, and down'
    north = {
        ms_daemon.enterWallDesc;
        return many_sided_south;
    }
    ne = hall_east_wall
    nw = hall_west_wall
    up = hall_curved_ceiling
    down = hall_curved_floor
;

hall_east_wall: insideRm
    sdesc = "East Side of Curving Hall"
    ldesc = "Passages lead northwest, southwest, up, and down, reminiscent
        of the hallway you first entered. The teak gives way to an exit
        to the west. "
    exits = 'west, northwest, southwest, up, and down'
    west = {
        ms_daemon.enterWallDesc;
        return many_sided_east;
    }
    nw = hall_north_wall
    sw = hall_south_wall
    up = hall_curved_ceiling
    down = hall_curved_floor
;

hall_west_wall: insideRm
    sdesc = "West Side of Curving Hall"
    ldesc = "The teak hall splits into four branches:\ northeast, southeast,
        up, and down. Marring the smoothness of the teak walls is an east
        exit. "
    exits = 'east, northeast, southeast, up, and down'
    east = {
        ms_daemon.enterWallDesc;
        return many_sided_west;
    }
    ne = hall_north_wall
    se = hall_south_wall
    up = hall_curved_ceiling
    down = hall_curved_floor
;

hall_curved_ceiling: insideRm
    sdesc = "Rounded Teak Hall"
    ldesc = "The teak halls branch north, south, east, and west, curving down
        like the dangling legs of some bizarre creature. Under your feet is
        an opening. "
    exits = 'north, south, east, west, and down'
    north = hall_north_wall
    south = hall_south_wall
    east = hall_east_wall
    west = hall_west_wall
    down = {
        ms_daemon.enterCeilingDesc;
        return many_sided_ceiling;
    }
;

ms_daemon: object
    firstWallFlag = true  // True if player hasn't entered cube room wall yet
    firstCeilingFlag = true // Ditto
    msRooms = [many_sided_floor, many_sided_north, many_sided_south,
        many_sided_east, many_sided_west, many_sided_ceiling]
    roomConts(cur_rm) = {
        local list = self.msRooms - cur_rm,
              i, conts = [];

        for (i = 1; i <= length(list); i++) {
            conts += list[i].contents;
        }
        return (conts);
    }
    printContents(cur_rm) = {
        local len, i, conts;

        len = length(self.msRooms);
        for (i = 1; i <= len; i++) {
            if (self.msRooms[i] == cur_rm)
                continue;
            conts = contlist(self.msRooms[i]);
            if (length(conts) > 0)
                "\n\tOn the <<self.msRooms[i].roomWord>> you see <<
                    listlist(conts)>>. ";
        }
    }
    // Description which is printed as you enter one of the cube room's walls
    enterWallDesc = {
        if (firstWallFlag) {
            firstWallFlag = nil;
            "Dizziness washes over you. The world spins about you; you fall
                until the opening is beneath you.\b";
        }
        else "As you pass through the opening, you experience the sharp wave
            of dizziness again.\b";
    }
    enterCeilingDesc = {
        if (firstCeilingFlag) {
            firstCeilingFlag = nil;
            "You fall, then reverse directions until you land beside the
                opening.\b";
        }
        else "As you lower yourself through the opening, you experience the
            sharp wave of dizziness again.\b";
    }
;

class manyRm: insideRm
    isManyRm = true
    ldesc = {
        self.roomDesc;
        ms_daemon.printContents(self);
    }
    dizzyExit = { 
        "As you approach the walls, you find yourself off-balance.
            The closer you get to the walls, the worse the disturbance in your
            inner-ear becomes. You are forced to give up the attempt. ";
        return nil;
    }
    visibleObjects(actor) = {
        return (inherited.visibleObjects(actor) + ms_daemon.roomConts(self));
    }
    firstseen = {
        blueAh.see;
        pass firstseen;
    }
;

many_sided_floor: manyRm
    sdesc = "Large Cubic Room"
    roomWord = "floor"
    roomDesc = "You stand on the floor of a white cubic room. There are
        openings in the middle of the floor, each of the walls, and the
        ceiling. "
    exits = 'down'
    north = self.dizzyExit
    south = self.dizzyExit
    east = self.dizzyExit
    west = self.dizzyExit
    down = hall_curved_floor
    out = hall_curved_floor

    // Which direction the many_sided_box spins when it is pushed in a given
    //  direction. + numbers mean cw (viewed from above), - numbers mean ccw.
    //  The number is equal to the number of quarter-turns the box takes
    nPush = 1
    sPush = -2
    ePush = -1
    wPush = 1

    // Which axis the box rotates about (viewed from above). 1=up, -1=down,
    //  2=north, -2=south, 3=east, -3=west
    axis = 1
;

many_sided_north: manyRm
    sdesc = "North Wall of Large Cubic Room"
    roomWord = "north wall"
    roomDesc = "With effort you can tell that you are somehow standing on
        the north wall of this cubic room, though where you are looks like
        any other point in the room. An opening leads back north; similar
        openings are on every other side of the room. "
    exits = 'north'
    north = {
        "The wave of dizziness washes over you.\b";
        return hall_north_wall;
    }
    east = self.dizzyExit
    west = self.dizzyExit
    up = self.dizzyExit
    down = self.dizzyExit
    out = (self.north)

    ePush = -1
    wPush = -2
    uPush = -1
    dPush = -1

    axis = -2               // Rotates about the south
;

many_sided_south: manyRm
    sdesc = "South Wall of Large Cubic Room"
    roomWord = "south wall"
    roomDesc = "Something, perhaps your inner ear, tells you that you are on
        the south wall and not the floor of this stark white cube. Under
        your feet an opening leads south. "
    exits = 'south'
    south = {
        "The wave of dizziness washes over you.\b";
        return hall_south_wall;
    }
    east = self.dizzyExit
    west = self.dizzyExit
    up = self.dizzyExit
    down = self.dizzyExit
    out = (self.south)

    ePush = 1
    wPush = -1
    uPush = 1
    dPush = 2

    axis = 2                // Rotates about the north
;

many_sided_east: manyRm
    sdesc = "East Wall of Large Cubic Room"
    roomWord = "east wall"
    roomDesc = "The east wall of this white room looks like every other side,
        even to the opening leading east under your feet. "
    exits = 'east'
    east = {
        "The wave of dizziness washes over you.\b";
        return hall_east_wall;
    }
    north = self.dizzyExit
    south = self.dizzyExit
    up = self.dizzyExit
    down = self.dizzyExit
    out = (self.east)

    nPush = 1
    sPush = -1
    uPush = -1
    dPush = 1

    axis = -3               // Rotates about the west
;

many_sided_west: manyRm
    sdesc = "West Wall of Large Cubic Room"
    roomWord = "west wall"
    roomDesc = "You look up to the east, standing on the west wall of a white
        cube, feet firmly planted. Beneath you gapes an opening. "
    exits = 'west'
    west = {
        "The wave of dizziness washes over you.\b";
        return hall_west_wall;
    }
    north = self.dizzyExit
    south = self.dizzyExit
    up = self.dizzyExit
    down = self.dizzyExit
    out = (self.west)

    nPush = 2
    sPush = 1
    uPush = -1
    dPush = -1

    axis = 3                // Rotates about the east
;

many_sided_ceiling: manyRm
    sdesc = "Ceiling of Large Cubic Room"
    roomWord = "ceiling"
    roomDesc = "You dangle from the ceiling, staring down at the floor below.
        Openings mark each side of the white cube, including the one leading
        up at your feet. "
    exits = 'up'
    up = {
        "The wave of dizziness washes over you.\b";
        return hall_curved_ceiling;
    }
    north = self.dizzyExit
    south = self.dizzyExit
    east = self.dizzyExit
    west = self.dizzyExit
    out = (self.up)

    nPush = 1
    sPush = -1
    ePush = 1
    wPush = 1

    axis = -1               // Rotates about the down
;

// The crate which holds the blue piece. Its sides are numbered thusly:
//  1 is top, 2 is bottom, 3-6 run clockwise (as you face down from above)
//  around the box.  These numbers are ONLY used in the xxSide properties
many_sided_crate: fixedItem
    // Which sides are pointing in which direction
    uSide = 2
    dSide = 1
    nSide = 3
    eSide = 6
    sSide = 5
    wSide = 4

    // Connects the numbers 1-6 with the proper sides. Not to be confused
    //  with the _actual_ sides 1-6
    sidePointers = [ &uSide, &dSide, &nSide, &eSide, &sSide, &wSide ]

    // Which side is opposite side 1 (up), side 2 (down), &c.
    sideOpposite = [ &dSide, &uSide, &sSide, &wSide, &nSide, &eSide ]
    sideNames = [ 'ceiling', 'floor', 'north wall', 'east wall',
        'south wall', 'west wall' ]

    // A list of property pointers for rotation
    sideRotate = [
        [&nSide, &eSide, &sSide, &wSide],        // Up/-down
        [&uSide, &wSide, &dSide, &eSide],        // North/-south
        [&uSide, &nSide, &dSide, &sSide]         // East/-west
    ]

    rotateCw(axis) = {     // Rotate the crate clockwise
        local sideList, i, tempSide;

        // Rotating cw about one side is the same as rotating ccw around
        //  its opposite side. So if I get a negative axis, call rotateCcw
        //  with -axis.  It gets me the same result and cuts down on coding
        if (axis < 0) {
            self.rotateCcw(-axis);
            return;
        }

        sideList = self.sideRotate[axis];

        // Do the rotation
        tempSide = self.(sideList[4]);
        for (i = 3; i >= 1; i--)        // Shift the contents right
            self.(sideList[i+1]) = self.(sideList[i]);
        self.(sideList[1]) = tempSide;
    }
    rotateCcw(axis) = {    // Rotate the crate counterclockwise
        local sideList, i, tempSide;

        // Again, rotating ccw about one side is like rotating cw about
        //  the opposite side.
        if (axis < 0) {
            self.rotateCw(-axis);
            return;
        }

        sideList = self.sideRotate[axis];

        // Do the rotation
        tempSide = self.(sideList[1]);
        for (i = 1; i <= 3; i++)        // Shift the contents left
            self.(sideList[i]) = self.(sideList[i+1]);
        self.(sideList[4]) = tempSide;
    }

    blockedSide = 1        // Which side of the crate is against a wall
    buttonSide = 2         // Which side the button is on
    buttonIsUp = {
        return (sidePointers[buttonSide] == sideOpposite[blockedSide]);
    }
    buttonIsBlocked = {
        return (blockedSide == buttonSide);
    }
    adjustButton = {
        local i;

        for (i = 1; i <= 6; i++) {
            if (self.(self.sidePointers[i]) == 1)
                self.buttonSide = i;
        }
    }

    isListed = true
    noun = 'box' 'crate'
    adjective = 'wood' 'wooden'
    location = many_sided_ceiling
    sdesc = "wooden crate"
    ldesc = {
        "A wooden crate, approximately a meter cubed. It has no
            distinguishing marks on it";
        if (!self.buttonIsBlocked) {
            " except for a recessed button pointing towards the <<
                self.sideNames[self.buttonSide]>>";
        }
        ". ";
    }
    takedesc = "Its rough sides may offer excellent purchase, but at a meter
        on a side it is much too bulky and heavy to lift. "

    verDoPush(actor) = {
        "In which direction would %you% like to push the crate? ";
    }
    verDoMove(actor) = {
        "In which direction would %you% like to move the crate? ";
    }
    verDoMoveN(actor) = {
        if (proptype(self.location, &nPush) != 1)
            "%You% can't move the crate to the north. ";
    }
    verDoMoveS(actor) = {
        if (proptype(self.location, &sPush) != 1)
            "%You% can't move the crate to the south. ";
    }
    verDoMoveE(actor) = {
        if (proptype(self.location, &ePush) != 1)
            "%You% can't move the crate to the east. ";
    }
    verDoMoveW(actor) = {
        if (proptype(self.location, &wPush) != 1)
            "%You% can't move the crate to the west. ";
    }
    verDoMoveU(actor) = {
        if (proptype(self.location, &uPush) != 1)
            "%You% can't move the crate up. ";
    }
    verDoMoveD(actor) = {
        if (proptype(self.location, &dPush) != 1)
            "%You% can't move the crate down. ";
    }
    doMoveN(actor) = {
        self.moveMe(self.location.nPush, 'to the north', 3,
            many_sided_north);
    }
    doMoveS(actor) = {
        self.moveMe(self.location.sPush, 'to the south', 5,
            many_sided_south);
    }
    doMoveE(actor) = {
        self.moveMe(self.location.ePush, 'to the east', 4,
            many_sided_east);
    }
    doMoveW(actor) = {
        self.moveMe(self.location.wPush, 'to the west', 6,
            many_sided_west);
    }
    doMoveU(actor) = {
        self.moveMe(self.location.uPush, 'up', 1,
            many_sided_ceiling);
    }
    doMoveD(actor) = {
        self.moveMe(self.location.dPush, 'down', 2,
            many_sided_floor);
    }
    moveMe(turns, dirStr, newSide, dest) = {
        local clockwise = true;

        if (turns < 0) {
            clockwise = nil;
            turns = -turns;
        }
        // The description uses sayPrefixCount() from adv.t to print "two" &c.
        "You push the crate <<dirStr>>. It gains momentum, moving faster and
            faster. As it nears the wall, the crate sways oddly from side
            to side. Just as it hits the wall, it makes <<
            sayPrefixCount(turns)>> <<clockwise ? "" : "counter">>clockwise 
            quarter-turn<<turns > 1 ? "s" : "">> and slides into the middle
            of that side of the room";
        self.blockedSide = newSide;    // The side that's against the wall
        self.moveInto(dest);
        while (turns > 0) {
            if (clockwise)
                self.rotateCw(dest.axis);
            else self.rotateCcw(dest.axis);
            turns--;
        }
        self.adjustButton;
        if (!self.buttonBlocked)
            ", until the button is pointing towards the <<
                self.sideNames[self.buttonSide]>>";
        ". ";
    }
;

crate_button: floatingItem, fixedItem
    noun = 'button'
    adjective = 'recessed' 'red'
    location = {
        if (!many_sided_crate.buttonIsBlocked)
            return many_sided_crate;
        return nil;
    }
    sdesc = "recessed button"
    ldesc = "The red button is recessed in the crate, so that its top is
        just below the level of the side of the crate. "
    locationOk = true
    verDoPush(actor) = {
        if (!many_sided_crate.buttonIsUp)
            "The button depresses with a click. The crate shivers; you hear
                the whine of machinery. The whine goes up in pitch, then
                stops. The crate settles down. ";
    }
    doPush(actor) = {
        "The button depresses with a click. The crate shivers; you hear
            the hum of machinery. Smoothly the sides of the crate fold down
            and into themselves, vanishing. Their disappearence reveals
            a blue crystal piece which ";
        if (many_sided_crate.buttonSide != 1)
            "plummets to the floor below and shatters into dust. ";
        else {
            "falls to the floor. ";
            blue_piece.moveInto(many_sided_crate.location);
            incscore(4);
            blueAh.solve;
        }
        many_sided_crate.moveInto(nil);
    }
;

/*
** The infinite plane
*/

white_line: wallpaper
    noun = 'line' 'marks' 'tick-marks'
    adjective = 'white' 'tick'
    sdesc = "white line"
    ldesc = "It runs east to west. Occasionally along its length tick-marks
        are drawn. "
;

fake_plane: wallpaper
    noun = 'plane' 'floor'
    adjective = 'black'
    sdesc = "black plane"
    ldesc = "It stretches around you as far as you can see. "
    verDoPush(actor) = {}
    doPush(actor) = { "The plane flexes slightly, then springs back when you
        stop pushing on it. "; }
    doSynonym('Push') = 'Attack' 'Poke'
    verDoKick(actor) = {}
    doKick(actor) = { "The plane wobbles for a second before it settles down. "; }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = { dobj.doDrop(actor); }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = { dobj.doDrop(actor); }
;

class infinite_plane_room: room
    notakeall = true    // To avoid large amounts of goofiness
    isPlane = true
    noFloor = true
    floating_items = [white_line, fake_plane]
    noexit = { "You find that you cannot leave the white line. "; return nil; }
    down = { "You find it impossible to pass through the plane. "; return nil; }
    up = {
        "You float up from the plane.\b";
        return center;
    }
;

infinite_plane_one: infinite_plane_room
    inverted = nil
    isRippling = nil
    comingDown = nil
    positionNum = 1
    powerOfTwo = 1
    myBoxes = [ ip_1, ip_2, ip_3, ip_4, ip_5, ip_6, ip_7, ip_8, ip_9, ip_10,
        ip_11, ip_12, ip_13, ip_14, ip_15, ip_16 ]
    myaBoxes = [ aip_1, aip_2, aip_3, aip_4, aip_5, aip_6, aip_7, aip_8, aip_9,
        aip_10, aip_11, aip_12, aip_13, aip_14, aip_15, aip_16 ]

    sdesc = {
        "Infinite Plane, ";
        if (inverted && positionNum != 1) {
            if (positionNum < 16)
                "at 1/<<powerOfTwo>>";
            else "Close to 0";
        }
        else {
            if (positionNum < 16)
                "at <<powerOfTwo>>";
            else "Far from 0";
        }
    }
    ldesc = {
        local conts;

        conts = contlist(infinite_plane_zero);
        "You are standing on a";
        if (isRippling)
            " rippling";
        else "n";
        " infinite plane. A white line begins to the west
            at a sign, runs beneath your feet, then vanishes in the distance
            to the east. ";
        if (positionNum == 1)
            "A box floats above the plane next to you. ";
        if (length(conts) > 0 && (inverted || positionNum == 1))
            "Sitting near the sign you see <<listlist(conts)>>. ";
    }
    exits = 'east and west'
    east = {
        if (inverted) {
            if (positionNum == 1) {
                "The plane zips past you in several strides.\b";
                return (infinite_plane_infinity);
            }
            moveAllCont(self, myBoxes[positionNum]);
            positionNum--;
            powerOfTwo /= 2;
            moveAllCont(myBoxes[positionNum], self);
            return self;
        }
        if (positionNum == 16) {
            "As far as you can tell, your steps take you no further. ";
            return nil;
        }
        moveAllCont(self, myBoxes[positionNum]);
        positionNum++;
        powerOfTwo *= 2;
        moveAllCont(myBoxes[positionNum], self);
        return self;
    }
    west = {
        if (!inverted) {
            if (positionNum == 1)
                return infinite_plane_zero;
            moveAllCont(self, myBoxes[positionNum]);
            positionNum--;
            powerOfTwo /= 2;
            moveAllCont(myBoxes[positionNum], self);
            return self;
        }
        if (positionNum == 16) {
            "Your steps take you no further. ";
            return nil;
        }
        moveAllCont(self, myBoxes[positionNum]);
        positionNum++;
        powerOfTwo *= 2;
        moveAllCont(myBoxes[positionNum], self);
        return self;
    }
    up = {
        "You float up from the plane.\b";
        return center;
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (comingDown) {
            comingDown = nil;
            "\bYou land softly, setting up gentle ripples in the plane. ";
        }
    }
    resetRipples = {
        if (isRippling) {
            isRippling = nil;
            if (Me.location.isPlane)
                "\bThe ripples slowly damp out. ";
        }
    }
;

plane_button_box: fixedItem
    noun = 'box'
    adjective = 'black' 'floating'
    location = infinite_plane_one
    sdesc = "floating black box"
    ldesc = "It is jet black and stands at chest height, hovering. A white
        button marks the exact center of the box. \"1/x\" is painted above
        the button. "
    takedesc = "It doesn't budge. "
;

plane_button_button: buttonItem
    firstPush = true
    noun = 'button'
    adjective = 'white'
    location = plane_button_box
    sdesc = "white button"
    ldesc = "Eminently pushable. "
    doPush(actor) = {
        "A wave of nausea passes through you. When your stomach settles, you
            notice something different. ";
        if (self.firstPush) {
            self.firstPush = nil;
            violetAh.see;
        }
        infinite_plane_one.inverted = !(infinite_plane_one.inverted);
        if (!infinite_plane_one.isRippling) {
            moveAllCont(infinite_plane_zero, self);
            moveAllCont(infinite_plane_infinity, infinite_plane_zero);
            moveAllCont(self, infinite_plane_infinity);
        }
        else {
            local i, b1 = infinite_plane_one.myBoxes,
                b2 = infinite_plane_one.myaBoxes;

            for (i = 1; i <= 16; i++) {
                moveAllCont(b1[i], self);
                moveAllCont(b2[i], b1[i]);
                moveAllCont(self, b2[i]);
            }
        }
    }
;

infinite_plane_zero: infinite_plane_room
    location = infinite_plane_one    // To make my contents (but not me)
    isListed = nil                   //  visible from infinite_plane_one
    isUber = true                    // See uberloc() in funcs.t
    noMoveAll = true                 // See moveAllCont() in funcs.t
    contentsReachable = { // More balcony fun--so you can't manipulate items
        return (Me.location == self);    //  in the hall
    }
    sdesc = "Infinite Plane, at 0"
    ldesc = {
        "A black plane ";
        if (infinite_plane_one.isRippling)
            "ripples";
        else "stretches";
        " around you, infinite in all directions. A white line begins at your
            feet and heads to the east. There is a sign at the beginning of
            the line. ";
    }
    exits = 'east'
    east = infinite_plane_one
    up = {
        "You float up from the plane.\b";
        return center;
    }
;

sign_at_zero: readable, decoration
    noun = 'sign'
    adjective = 'black'
    location = infinite_plane_zero
    sdesc = "black sign"
    ldesc = "It is matte black. Painted on it in white is a large zero. "
    readdesc = "A large zero is painted on it. "
;

infinite_plane_infinity: infinite_plane_room
    sdesc = "Infinite Plane, at Infinity"
    ldesc = {
        "You are surrounded by a ";
        if (infinite_plane_one.isRippling)
            "rippling";
        " black plane. A white line runs from east to west. ";
    }
    exits = 'west'
    east = {
        "You have somehow reached the non-zero end of the infinite line,
            inasmuch as an infinite line can have a non-zero end. You make
            no further progress. ";
        return nil;
    }
    west = infinite_plane_one
    up = {
        "You float up from the plane.\b";
        return center;
    }
;

// Where I put contents as the player moves around
class ip_box: object
    contents = []
    verGrab(obj) = {}
    Grab(obj) = {}
;

ip_1: ip_box;
ip_2: ip_box;
ip_3: ip_box;
ip_4: ip_box;
ip_5: ip_box;
ip_6: ip_box;
ip_7: ip_box;
ip_8: ip_box;
ip_9: ip_box;
ip_10: ip_box;
ip_11: ip_box;
ip_12: ip_box;
ip_13: ip_box;
ip_14: ip_box;
ip_15: ip_box;
ip_16: ip_box;

aip_1: ip_box;
aip_2: ip_box;
aip_3: ip_box;
aip_4: ip_box;
aip_5: ip_box;
aip_6: ip_box;
aip_7: ip_box;
aip_8: ip_box;
aip_9: ip_box;
aip_10: ip_box;
aip_11: ip_box;
aip_12: ip_box;
aip_13: ip_box;
aip_14: ip_box;
aip_15: ip_box;
aip_16: ip_box;

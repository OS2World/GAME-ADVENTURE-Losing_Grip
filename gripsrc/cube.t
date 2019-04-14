/*
** The 4D granite cube puzzle, from part four a of _Losing Your Grip_.
** Copyright (c) 1998, Stephen Granade. All rights reserved.
** $Id: cube.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
**
** Author: Stephen Granade                Date: 23 Jan 96
*/

#pragma C+

#define DIMENSION 612            // Setting for the w_dial

/*
** Decorations
*/

// The huge cube
granite_cube: wallpaper
    noun = 'cube'
    adjective = 'granite'
    sdesc = "granite cube"
    ldesc = "The craggy face of the granite cube is pitted and scarred,
        as if multiple attempts have been made to break it open.  It hangs
        in midair; no supports are visible.  At just over 10 meters on a side,
        it is claustrophobia-inducing in this relatively small room. "
    takedesc = "Even if you could somehow take it,
        it would pulp you beneath its weight."
    touchdesc = {
        if (gloves.isworn)
            "You feel nothing unusual through the gloves. ";
        else "It is rough, rough enough to scrape skin from your fingers. ";
    }
    verDoLookin(actor) = {
        "Lacking x-ray vision, you are unable to look into the cube. ";
    }
    verDoClimb(actor) = { "There are no convenient handholds. "; }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (dobj != sounder) {
            if (actor.locaton != cube_room_10)
                "There's no good surface on the cube. ";
            else dobj.doDrop(actor);
        }
        else dobj.doPutOn(actor, self);
    }
;

/*
** Rooms
*/

// Rooms about the cube.  dialer tells which dial moves you close to the
//    cube; greaterFlag is true if the dial's setting must be > 150 to
//    trigger a warning (otherwise the dial's setting must be < 1250).
//    proximityWarning actually prints the warning if necessary.
class cube_room: insideRm
    floating_items = [granite_cube]
    dialer = nil//w_dial                    // So as not to trigger a warning
    greaterFlag = true
    isCubeRoom = true
    sdesc = {
        if (flying_belt.isworn && belt_switch.isActive &&
            (z_dial.setting > 250 && Me.location != cube_room_10))
            "<<self.worddesc>> (high above the ground)";
        else self.worddesc;
    }
    ldesc = "The metal-walled room is dominated by the floating cube in its
        center.  A two-meter clearance on every side of the cube allows for
        somewhat cramped passage. <<self.proximityWarning>>"
    exits = {
        if (flying_belt.isworn && belt_switch.isActive)
            "You can't go anywhere until you turn off the belt. ";
        else "You can go <<self.exitList>>. ";
    }
    proximityWarning = {
        if (flying_belt.isworn && belt_switch.isActive) {
            "The belt is holding you in place";
            if (dialer && ((greaterFlag && dialer.setting > 150) ||
                (!greaterFlag && dialer.setting < 1250)))
                " disturbingly close to the cube";
            ". ";
        }
    }
    // Trap travel verbs for when the belt is activated
    roomAction(a, v, d, p, i) = {
        if (flying_belt.isworn && belt_switch.isActive) {
            if (v.isTravelVerb) {
                "Despite your best efforts, the belt holds you captive. ";
                exit;
            }
            else if (v == takeVerb) {
                "The belt's hold on you is too restrictive. ";
                exit;
            }
            else if (v == sitVerb || v == lieVerb) {
                "Not while the belt holds you up. ";
                exit;
            }
        }
        pass roomAction;
    }
;

/*
**  The rooms are arranged as follows:
**  7  8  9
**  4  5  6
**  1  2  3
**  Room 10 is on top of the cube
*/

cube_room_1: cube_room
    worddesc = "Southwest of the Cube"
    exitList = 'north, east, and northeast'
    north = cube_room_4
    east = cube_room_2
    ne = cube_room_5
    firstseen = {
        beltClueAh.see;
        pass firstseen;
    }
;

cube_room_2: cube_room
    worddesc = "South of the Cube"
    exitList = 'north, south, east, west, northeast, and northwest'
    ldesc = "The metal walls of this room have been polished until they
        reflect its most prominent feature:\ a large granite cube.
        The cube appears to be more than 10 meters on a side; there is
        a two meter clearance on every side of it, including the top and
        bottom. An open doorway leads south. <<self.proximityWarning>>"
    north = cube_room_5
    south = center
    east = cube_room_3
    west = cube_room_1
    ne = cube_room_6
    nw = cube_room_4
    dialer = y_dial
    greaterFlag = true
    firstseen = {
        inside_cube.x = 400 + RAND(600);      // Randomize the loc of the
        inside_cube.y = 400 + RAND(600);      //  cube's center
        inside_cube.z = 400 + RAND(600);
        yellowAh.see;
        pass firstseen;
    }
;

cube_room_doorway: myDoorway
    location = cube_room_2
    ldesc = "It leads south. "
    lookthrudesc = "The domed room and pedestal lie beyond. "
    doordest = center
;

cube_room_3: cube_room
    worddesc = "Southeast of the Cube"
    exitList = 'north, west, and northwest'
    north = cube_room_6
    west = cube_room_2
    nw = cube_room_5
;

cube_room_4: cube_room
    worddesc = "West of the Cube"
    exitList = 'north, south, east, northeast, and southeast'
    north = cube_room_7
    south = cube_room_1
    east = cube_room_5
    ne = cube_room_8
    se = cube_room_2
    dialer = x_dial
    greaterFlag = true
;

cube_room_5: cube_room
    worddesc = "Under the Cube"
    noCeiling = true
    ldesc = {
        if (belt_switch.isActive)
            "Though held beneath the cube, you duck your head";
        else "You find yourself stooping as you stand beneath the
            granite cube";
        ", more from psychological pressure than from any true
            force.  Due to the two meter clearance around the cube, you can
            travel in any cardinal direction. <<self.proximityWarning>>";
    }
    exitList = 'north, south, east, west, northeast, northwest, southeast,
        and southwest'
    north = cube_room_8
    south = cube_room_2
    east = cube_room_6
    west = cube_room_4
    ne = cube_room_9
    nw = cube_room_7
    se = cube_room_3
    sw = cube_room_1
    dialer = z_dial
    greaterFlag = true
;

cube_room_6: cube_room
    worddesc = "East of the Cube"
    exitList = 'north, south, west, northwest, and southwest'
    north = cube_room_9
    south = cube_room_3
    west = cube_room_5
    nw = cube_room_8
    sw = cube_room_2
    dialer = x_dial
    greaterFlag = nil
;

cube_room_7: cube_room
    worddesc = "Northwest of the Cube"
    exitList = 'south, east, and southeast'
    south = cube_room_4
    east = cube_room_8
    se = cube_room_5
;

cube_room_8: cube_room
    worddesc = "North of the Cube"
    exitList = 'south, east, west, southeast, and southwest'
    south = cube_room_5
    east = cube_room_9
    west = cube_room_7
    se = cube_room_6
    sw = cube_room_4
    dialer = y_dial
    greaterFlag = nil
;

cube_room_9: cube_room
    worddesc = "Northeast of the Cube"
    exitList = 'south, west, and southwest'
    south = cube_room_6
    west = cube_room_8
    sw = cube_room_5
;

cube_room_10: cube_room
    noFloor = true
    sdesc = "Above the Cube"
    ldesc = {
        "The top of the granite cube is a mirror analogue of every other side
            of the cube.  The two meters between it and the ceiling are just
            enough to make you ";
        if (belt_switch.isActive)
            "duck your head";
        else "crouch";
        " somewhat. <<self.proximityWarning>>";
    }
    dialer = z_dial
    greaterFlag = nil
    roomDrop(obj) = {
        if (obj != sounder)
            pass roomDrop;
        "You place the box on the cube.  With a soft sucking sound, it
            adheres to the surface.  It then begins crawling over the
            surface with amazing speed, emitting high-pitched squeaks.
            Several seconds later, it returns to where you placed
            it. ";
        sounder.takeReading(self);
        sounder.moveInto(self);
    }
    north = {
        "The cube's height above the ground dissuades you. ";
        return nil;
    }
    south = (self.north)
    east = (self.north)
    west = (self.north)
    ne = (self.north)
    nw = (self.north)
    se = (self.north)
    sw = (self.north)
    up = { "Not likely. "; return nil; }
    down = { "Not likely. "; return nil; }
;

ana_kata_room: room
    sdesc = "Somewhere <<w_dial.setting > DIMENSION ? "Ana" : "Kata">>"
    ldesc = "The space around you is filled with a shifting, misty blur of
        shapes.  Occasionally you can make out a protrusion, but your eyes
        refuse to focus sharply on anything. "
    noexit = { "Though you still have a grasp on direction, this place
        seems to disagree with you. "; return nil; }
;

inside_cube: room
    x = -1                    // Location inside the cube
    y = -1
    z = -1
    isCubeRoom = true
    sdesc = "Inside the Cube"
    ldesc = "Despite its solid-seeming exterior, the cube contains this one
        pocket deep within it.  The space is just larger than a meter cubed,
        forcing you into ever-more-uncomfortable contortions. "
    noexit = { "The granite cube restrains you. "; return nil; }
;

/*
** Objects
*/

// The flying belt.  It consists of a switch and four dials.
flying_belt: clothingItem
    noun = 'belt'
    adjective = 'leather'
    location = cube_room_1
    sdesc = "leather belt"
    ldesc =
        "The large leather belt is distinguished
            by the switch and four dials built into it. The four dials are
            each colored differently:\ red, green, blue, and grey. The switch
            is currently <<belt_switch.wordDesc>>. The
            red dial is set to <<x_dial.setting>>, the green dial
            to <<y_dial.setting>>, the blue dial to <<z_dial.setting>>,
            and the grey dial to <<w_dial.setting>>. "
    hdesc = {
        if (z_dial.setting > 250 && self.location != cube_room_10)
            "Above your head, a leather belt floats far out of your reach. ";
        else "A leather belt incongruously floats in midair here. ";
    }
    has_hdesc = { return belt_switch.isActive; }
    weight = 1
    bulk = 1
    doTurnon -> belt_switch
    doTurnoff -> belt_switch
    doSwitch -> belt_switch
    doFlip -> belt_switch
    checkHeight(actor, verb) = {
        if (verb.issysverb || !verb.touch)
            return true;
        if (belt_switch.isActive && !self.isworn && z_dial.setting > 250
            && !(actor.location == cube_room_10 && z_dial.setting > 1200)) {
            "It's too far above your head. ";
            return nil;
        }
        return true;
    }
    dobjGen(a,v,i,p) = {
        if (!self.checkHeight(a, v))
            exit;
    }
    iobjGen(a,v,d,p) = {
        self.dobjGen(a,v,d,p);
    }
    verDoTake(actor) = {
        if (!self.checkHeight(actor, takeVerb))
            return;
        if (belt_switch.isActive)
            "No matter how hard you tug at it, the belt refuses to move. ";
        else pass verDoTake;
    }
    checkDrop = {
        if (self.isworn) {
            if (w_dial.setting != DIMENSION) {    // Can't be ana/kata from us
                "You find that you cannot undo the belt. ";
                exit;
            }
            "(Removing <<self.thedesc>> first)\n";
            self.isworn = nil;
            if (belt_switch.isActive) {
                if (z_dial.setting > 250 && uberloc(self) != cube_room_10) {
                    "As you remove the belt, you find yourself tumbling
                        to the floor below, where you land badly. ";
                    die();
                }
                else {
                    "You fall a short distance down.  The belt, however,
                        stays in place. ";
                    self.moveInto(Me.location);
                    exit;
                }
            }
        }
    }
    verDoUnwear(actor) = {
        if (w_dial.setting != DIMENSION)    // Can't be ana/kata from us
            "You find that you cannot undo the belt. ";
        else pass verDoUnwear;
    }
    doUnwear(actor) = {
        self.isworn = nil;
        if (belt_switch.isActive) {
            if (z_dial.setting > 250 && uberloc(self) != cube_room_10) {
                "As you remove the belt, you find yourself tumbling
                    to the floor below...far below... ";
                die();
            }
            else {
                "You fall a short distance down.  The belt, however,
                    stays in place. ";
                self.moveInto(Me.location);
                return;
            }
        }
        "Okay, you're no longer wearing the belt. ";
    }
    // belt_room determines which room the belt should be in.  Returns nil
    //  if the location is inside the cube
    belt_room = {
        local total, temp, rooms = [cube_room_1, cube_room_2, cube_room_3,
            cube_room_4, cube_room_5, cube_room_6, cube_room_7, cube_room_8,
            cube_room_9, cube_room_10];

    // Set the y room
        temp = y_dial.setting;
        if (temp <= 200)
            total = 1;
        else if (temp <= 1200)
            total = 4;
        else total = 7;
    // Set the x room
        temp = x_dial.setting;
        if (temp <= 200)
            total += 0;    // No change
        else if (temp <= 1200)
            total += 1;
        else total += 2;
    // Handle "inside the cube"
        if (total == 5 && z_dial.setting > 200 && z_dial.setting <= 1200)
            return nil;
    // Handle "above the cube"
        if (total == 5 && z_dial.setting > 1200)
            total = 10;
        return rooms[total];    // Return the room loc
    }
;

belt_switch: switchItem, fixedItem
    noun = 'switch'
    location = flying_belt
    sdesc = "switch"
    ldesc = "The switch is currently <<self.wordDesc>>. "
    dobjGen(a,v,i,p) = {
        if (!flying_belt.checkHeight(a, v))
            exit;
    }
    iobjGen(a,v,d,p) = {
        self.dobjGen(a,v,d,p);
    }
    verDoSwitch(actor) = {
        if (!self.isActive)
            self.verDoTurnon(actor);
        else self.verDoTurnoff(actor);
    }
    doSwitch(actor) = {
        if (!self.isActive)
            self.doTurnon(actor);
        else self.doTurnoff(actor);
    }
    verDoFlip(actor) = (self.verDoSwitch(actor))
    doFlip(actor) = (self.doSwitch(actor))
    verDoThrow(actor) = (self.verDoSwitch(actor))
    doThrow(actor) = (self.doSwitch(actor))
    verDoTurnoff(actor) = {
        if (!flying_belt.checkHeight(actor, turnOffVerb)) return;
/*        if (self.isActive && !flying_belt.isworn && z_dial.setting > 250
            && !(actor.location == cube_room_10 && z_dial.setting > 1200))
            "It's too far above your head. ";
        else*/ if (self.isActive && flying_belt.isworn && w_dial.setting !=
            DIMENSION)
            "The switch is frozen in place. ";
        else pass verDoTurnoff;
    }
    doTurnoff(actor) = {
        self.isActive = nil;
        if (flying_belt.isworn) {
            if (z_dial.setting > 250 && uberloc(actor) != cube_room_10) {
                "As you turn off the belt, you find yourself tumbling
                    to the floor below...far below... ";
                die();
            }
            else {
                "You fall a short distance down after you turn off the belt. ";
                self.moveInto(Me.location);
                return;
            }
        }
        "The belt falls to the floor. ";
    }
    verDoTurnon(actor) = {
        if (!flying_belt.checkHeight(actor, turnOnVerb)) return;
/*        if (self.isActive && !flying_belt.isworn && z_dial.setting > 250
            && !(actor.location == cube_room_10 && z_dial.setting > 1200))
            "It's too far above your head. ";
        else*/ if (!actor.location.isCubeRoom)
            "The switch clicks, then returns to the off position. ";
        else pass verDoTurnon;
    }
    doTurnon(actor) = {
        local dest;

        self.isActive = true;
        dest = flying_belt.belt_room;
        "The belt ";
        if (!flying_belt.isworn) {
            if (flying_belt.location == actor)
                "tears itself from your hands and ";
            "shoots away from you";
            if (uberloc(flying_belt) != dest)
                ". It is quickly lost from view. ";
            else " to another part of the room. ";
            flying_belt.moveInto(dest);
        }
        else {
            "raises a bit, dragging you with it. ";
            if (actor.location == dest)
                "It quickly pulls you to another part of the room. ";
            else {
                "It then speeds off with you as its passenger.  The grey
                    surface of the cube careens past you until you finally
                    slow.\b";
                actor.travelTo(dest);
            }
        }
    }
;

// Inside the dial, the greater & lesser methods print the word which
//  describes the direction the belt moves when the dial is increased/
//  decreased.
class belt_dial: dialItem, fixedItem
    noun = 'dial'
    plural = 'dials'
    location = flying_belt
    maxsetting = 1400
    ldesc = "\^<<self.thedesc>> is marked from 1 to 1400.  It is currently
        set to <<self.setting>>. "
    dobjGen(a,v,i,p) = {
        if (!flying_belt.checkHeight(a, v))
            exit;
    }
    iobjGen(a,v,d,p) = {
        self.dobjGen(a,v,d,p);
    }
    verDoTurn(actor) = {
        if (!flying_belt.checkHeight(actor, turnVerb)) return;
        if (!belt_switch.isActive)
            "It is frozen in place. ";
    }
    verDoTurnTo(actor, io) = {
        if (!flying_belt.checkHeight(actor, turnVerb)) return;
        if (!belt_switch.isActive)
            "It is frozen in place. ";
        else if (io != numObj)
            "I don't know how to turn <<self.thedesc>> to that. ";
        else if (numObj.value < 1 || numObj.value > self.maxsetting)
            "There's no such setting. ";
        else if (numObj.value == self.setting)
            "It's already set to <<self.setting>>. ";
        else if (actor.location == inside_cube && !self.isFourthDial)
            "You only succeed in scraping yourself along the confines of
                your prison.  A terrible cramp begins in one of your legs. ";
    }
    doTurnTo(actor, io) = {
        local dest, loc, old_setting;

        old_setting = self.setting;            // Save the original setting
        self.setting = numObj.value;
        "You turn the dial to <<self.setting>>. ";
        if (w_dial.setting != DIMENSION) {    // Handle ana/kata
            "You are swept through the mist, strange shapes flicking past
                you. ";
            return;
        }
        dest = flying_belt.belt_room;
        loc = uberloc(flying_belt);            // Get overall location
        if (flying_belt.isworn) {
            if (dest == loc)
                "The belt drags you <<self.setting > old_setting
                    ? self.greater : self.lesser>>. ";
            else if (dest == nil) {
                "The belt tumbles you towards the cube. Unable to slow your
                    progress, you slam into the rough surface of the cube.
                    When the sparks clear from your vision, you discover that
                    the belt has returned you to your old location. ";
                self.setting = old_setting;
                return;
            }
            else {
                "You careen past the surface of the cube, its grey surface
                    speeding by, until you come to a halt seconds later.\b";
                actor.travelTo(dest);
            }
        }
        else {
            if (dest == loc)
                "The belt quickly moves to another part of the room. ";
            else if (dest == nil) {
                "The belt zips toward the cube, slamming into its rough
                    surface.  The belt then drifts towards the floor until
                    it comes to rest beside you. ";
                x_dial.setting = y_dial.setting = z_dial.setting = 1;
                belt_switch.isActive = nil;
            }
            else {
                "The belt zips away from you and is soon lost to sight. ";
                flying_belt.moveInto(dest);
            }
        }
    }
;

x_dial: belt_dial
    adjective = 'red'
    sdesc = "red dial"
    greater = "to the east"
    lesser = "to the west"
;

y_dial: belt_dial
    adjective = 'green'
    sdesc = "green dial"
    greater = "to the north"
    lesser = "to the south"
;

z_dial: belt_dial
    adjective = 'blue'
    sdesc = "blue dial"
    greater = "up"
    lesser = "down"
;

w_dial: belt_dial
    isFourthDial = true
    setting = DIMENSION
    adjective = 'grey' 'gray'
    sdesc = "grey dial"
    numMsgs = 1
    doTurnTo(actor, io) = {
        local dest, loc, old_setting, travelMessages = [
            'As you turn it, the world around you begins to change.  Like
                a riffled stack of cards, views of worlds appear and vanish
                before you, too rapid to comprehend.  All appear to
                be made of mist and air.  Soon, though, the changes cease,
                leaving you in a strange place...',
            'The riffling views begin again, like an infinite number of
                slides displayed infinitely quickly.  This time the
                disorientation is somewhat less.',
            'The shuffling views accompany your twist of the dial, ending
                in a place very like the one you just left.' ];

        old_setting = self.setting;            // Save the original setting
        self.setting = numObj.value;
        "You turn the dial to <<self.setting>>. ";
        if (!flying_belt.isworn) {
            "The belt flickers once, then vanishes. ";
            flying_belt.moveInto(nil);
            return;
        }
        // See if they pass through our dimension
        if ((self.setting <= DIMENSION && old_setting > DIMENSION) ||
            (self.setting >= DIMENSION && old_setting < DIMENSION)) {
            dest = flying_belt.belt_room;    // Where should we end up
            if (dest == nil) {
                "Again you see the riffling effect, ";
                if (x_dial.setting == inside_cube.x &&
                    y_dial.setting == inside_cube.y &&
                    z_dial.setting == inside_cube.z) {
                    "ending this time in a recognizable place.\b";
                    actor.travelTo(inside_cube);
                    return;
                }
                "but this time your trip is brought up short as you slam into
                    something.  Dazed, you drift away. ";
                self.setting = old_setting;
                return;
            }
            if (self.setting == DIMENSION) {
                "The rapidly shuffling views begin again, but as they end
                    you find yourself in a world you recognize.\b";
                actor.travelTo(dest);
                self.numMsgs = 1;
                return;
            }
            "The shuffling views of your transit are momentarily interrupted
                by a glimpse of familiar objects.  The view is fleeting,
                gone before you can react. ";
            return;
        }
        "<<travelMessages[self.numMsgs++]>>";
        if (self.numMsgs > length(travelMessages))
            self.numMsgs = length(travelMessages);
        if (actor.location != ana_kata_room) {
            "\b";
            actor.travelTo(ana_kata_room);
        }
    }
;

sounder: moveItem
    noun = 'box' 'handle' 'display' 'needle' 'analyzer'
    adjective = 'metal' 'sonic'
    location = tool_shed        // From home.t
    setting = 0
    weight = 5
    bulk = 3
    sdesc = "metal box"
    ldesc = "The box is made of seamless metal, marred only by a large
        handle and a display with a needle.  Its underside is
        crisscrossed with a strange pattern, giving it the look of granite.
        The display is marked from 0 millimeters to 20000; the needle is
        currently pointing at <<self.setting>>. "
    has_hdesc = { return((self.setting != 0) || firstPick); }
    hdesc = {
        if (firstPick)
            "Seated on a shelf";
        else "Attached to the cube";
        " is a metal box. ";
    }
    moveInto(obj) = {
        sounderClueAh.see;
        pass moveInto;
    }
    doPutOn(actor, io) = {
        local temp_reading;

        if (io != granite_cube)
            pass doPutOn;
        if (flying_belt.isworn && belt_switch.isActive &&
            Me.location != cube_room_10) {
            "Your purchase is too precarious for you to place it on the
                cube. ";
            return;
        }
        if (actor.location == cube_room_1 || actor.location == cube_room_3 ||
            actor.location == cube_room_7 || actor.location == cube_room_9) {
            "As you are standing at the corner of the cube, there is no good
                place to put it. ";
            return;
        }
        "You place the box on the cube.  With a soft sucking sound, it
            adheres to the surface.  It then begins crawling over the
            surface with amazing speed, emitting high-pitched squeaks.
            Several seconds later, it returns to where you placed it. ";
        self.takeReading(actor.location);
        self.moveInto(actor.location);
    }
    takedesc = {
        if (setting != 0) {
            "You have to pull firmly to detach the box from the cube. It comes
                free with the sound of water swirling down a drain. ";
            setting = 0;
        }
        else "Taken. ";
    }
    verDoRead(actor) = {}
    doRead(actor) = {
        "The needle is pointing at <<self.setting>>. ";
    }
    takeReading(loc) = {
        local temp_reading, flip_flag = nil;

        if (loc == cube_room_2 || loc == cube_room_8) {
            temp_reading = inside_cube.y;
            if (loc == cube_room_8)
                flip_flag = true;
        }
        else if (loc == cube_room_4 || loc == cube_room_6) {
            temp_reading = inside_cube.x;
            if (loc == cube_room_6)
                flip_flag = true;
        }
        else {
            temp_reading = inside_cube.z;
            if (loc == cube_room_10)
                flip_flag = true;
        }
        temp_reading *= 10;
        temp_reading += (RAND(6) - 3) - 2000;
        if (flip_flag)
            self.setting = 10000 - temp_reading;
        else self.setting = temp_reading;
    }
;

sounder_info: readable, complex
    noun = 'paper' 'flyer'
    adjective = 'curled'
    location = tool_shed
    weight = 1
    bulk = 0
    sdesc = "flyer"
    ldesc = "The flyer extols the virtues of the SchimTek Sonic Cavity
        Analyzer.  The picture on the flyer shows a rectangular box
        with a large grip handle on one end, reminiscent of an old
        geiger counter. Your father was eternally collecting gadgets like
        the Sonic Cavity Analyzer. "
    hdesc = "A yellowed flyer is curled on the floor. "
    readdesc = "\"Find the flaws hidden deep beneath the surface!  A must
        have for any structural engineer!  Accurate to within plus or
        minus three millimeters.\" "
;


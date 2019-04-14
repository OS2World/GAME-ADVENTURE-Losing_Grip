/*
    Home, part three of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: home.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

#define HAT    1            // A clothing family

// Bit definitions for dragon senses
#define SEEN      1
#define SMELLED   2
#define HEARD     4

// To ease my suffering
#define FAERIE 'faerie' 'fairy' 'faery'
#define FAERIES 'faeries' 'fairies'

bedroom: droom, insideRm
    sdesc = "Your Bedroom"
    firstdesc = "You are lying on your bed, staring up at the ceiling. The
        sun streams through the window blinds and falls in stripes across
        your face.\b
        But it's not the bed in your apartment. It's your childhood bedroom,
        upstairs in the house you lived in until shortly after your Mom died.\b
        Judging from the room's neatness, your Mom must have died not too
        long ago; you remember cleaning your room compulsively after she died
        in the hopes that it would bring her back. You also remember being sent
        to your room this day for some unexplained infraction of your father's
        rules.\b
        Your dresser leans against the north wall and a closed door leads
        east. There is a window in the west wall. "
    seconddesc = {
        "Your room has been neatly cleaned; your bed ";
        if (bedroom_bed.isMade)
            "carefully made";
        else "unmade";
        ". A dresser sits against the north wall and a closed door leads
            east. The window in the west wall is <<bedroom_window.wordDesc>>. ";
    }
    east = { "The door prevents you. "; return nil; }
    west = {
        if (!bedroom_window.isopen) {
            "The closed window prevents you. ";
            return nil;
        }
        if (bedsheet.location != Me || bedsheet.tiedTo == nil) {
            "The fall would kill you. ";
            return nil;
        }
        if (bedsheet.tiedTo == bedroom_door) {
            "The door is so far from the window that the bedsheet barely
                reaches; it's certainly not long enough to let you climb down
                safely. ";
            return nil;
        }
        if (mythology_book.location == Me || faerie_book.location == Me) {
            "You realize that it is impossible to hold onto the bedsheet and
                anything as large as the oversized books at the same time if
                you intend to reach the ground safely. ";
            return nil;
        }
        "You grab hold of the bedsheet tightly and lower yourself out the open
            window. You shimmy down the sheet, old skills returning. A few feet
            above the ground your sheet runs out, but the shock of the drop is
            easily absorbed by your young legs.\b";
        bedsheet.moveInto(nil);
        roomAh.solve;
        return backyard1;
    }
    jumpAction = "\"Terry!\"\ your father yells from somewhere in the house.
        \"You better just settle down, now!\" "
;

bedroom_bed: bedItem, insideRm
    stage = 3
    isMade = true
    everUnmade = nil
    noun = 'bed' 'bedspread'
    adjective = 'made' 'unmade' 'my'
    location = bedroom
    sdesc = "your bed"
    thedesc = "your bed"
    adesc = "your bed"
    ldesc = {
        local list = contlist(self);

        "The bed was large enough for you through your tenth birthday. ";
        if (self.isMade) {
            "It has been neatly made";
            if (!self.everUnmade)
                ", although your arrival has mussed it somewhat";
            ". The bedsheet peeks out from under one corner. ";
        }
        else "It has been unmade and its bedsheet removed. ";
        if (length(list) > 0)
            "On the bed you see <<listlist(list)>>. ";
    }
    verIoTieTo(actor) = {}
    verDoMake(actor) = {
        if (self.isMade)
            "The bed is already made. ";
        else if (bedsheet.location != actor)
            "You'll need to get the bedsheet first. ";
        else if (bedsheet.tiedTo != nil)
            "Not until you untie the sheet. ";
    }
    doMake(actor) = {
        "You ";
        if (actor.location == bedroom_bed)
            "stand up and ";
        "make the bed with a precision borne of practice";
        if (actor.location == bedroom_bed)
            " before sitting down again";
        ". ";
        self.isMade = true;
        bedsheet.moveInto(bedroom_bed);
        bedsheet.isListed = nil;
        bedsheet.firstPick = true;
    }
    verDoUnmake(actor) = {
        if (!self.isMade)
            "The bed is already unmade. ";
        else bedsheet.verDoTake(actor);
    }
    doUnmake(actor) = {
        bedsheet.doTake(actor);
    }
;

bedsheet: unlistedItem
    stage = 3
    tiedTo = nil
    notakeall = true
    noun = 'sheet' 'bedsheet'
    location = bedroom_bed
    sdesc = "bedsheet"
    ldesc = {
        if (bedroom_bed.isMade)
            "It peeks from under one corner of your bedspread. ";
        else {
            "It is off-white, which eased your Mom's laundry duties. ";
            if (tiedTo != nil)
                "It is tied to <<tiedTo.thedesc>>. ";
        }
    }
    listdesc = {
        inherited.listdesc;
        if (self.tiedTo != nil) {
            if (self.location == Me)    // Inventory description
                " (tied to <<self.tiedTo.thedesc>>)";
            else                        // Look description
                " tied to <<self.tiedTo.thedesc>>";
        }
    }
    verDoTake(actor) = {
        if (actor.location == bedroom_bed && bedroom_bed.isMade)
            "Not while you're sitting on the bed. ";
        else pass verDoTake;
    }
    takedesc = {
        if (bedroom_bed.isMade) {
            "You pull the bedsheet free, unmaking the bed in the process. ";
            bedroom_bed.isMade = nil;
            bedroom_bed.everUnmade = true;
        }
        else "Taken. ";
    }
    verDoTieTo(actor, io) = {
        if (self.tiedTo != nil)
            "The sheet is already tied to <<self.tiedTo.thedesc>>. ";
    }
    doTieTo(actor, io) = {
        if (bedroom_bed.isMade) {
            self.doTake(actor);
            "You then";
        }
        else "You";
        " loop the sheet around <<io.thedesc>> and tie it. ";
        self.tiedTo = io;
    }
    verDoUntie(actor) = {
        if (self.tiedTo == nil)
            "It's not tied to anything. ";
    }
    doUntie(actor) = {
        "You untie the bedsheet. ";
        self.tiedTo = nil;
    }
    verDoClimb(actor) = {
        if (self.tiedTo == nil)
            "Purposeless, but it takes little to amuse a creative
                nine-year-old. You spend several moments climbing the
                bedsheet to nowhere. ";
    }
    doClimb(actor) = {
        bedroom_window.doEnter(actor);
    }
    doClimbup(actor) = {
        "Even tied to <<tiedTo.thedesc>> the bedsheet presents no good place
            to climb up to. ";
    }
    verDoWear(actor) = {
        "This is neither Halloween nor a Ku Klux Klan meeting. ";
    }
;

bedroom_dresser: surface, fixedItem
    stage = 3
    noun = 'dresser'
    location = bedroom
    sdesc = "dresser"
    ldesc = {
        local list = contlist(self);

        "The dresser is almost as tall as you and is topped by a mirror. ";
        if (length(list) > 0)
            "In front of the mirror you see <<listlist(list)>>. ";
    }
    verIoTieTo(actor) = {}
    verDoOpen(actor) = {
        "You pull open a few drawers and look at the rows of neatly-folded
            clothes before closing the drawers once more. ";
    }
    verDoClose(actor) = { "It's already closed. "; }
    verDoLookin(actor) = { self.verDoOpen(actor); }
    doSearch(actor) = {
        if (itemcnt(self.contents) != 0)
            "On <<self.thedesc>> %you% see%s% <<listcont(self)>>. ";
        else "Only clothes fill your dresser. ";
    }
;

bedroom_mirror: fixedItem
    stage = 3
    noun = 'mirror'
    location = bedroom
    sdesc = "mirror"
    ldesc = "The mirror is oval and sits atop the dresser. Reflected in it you
        see yourself as a nine-year-old, a nasty bruise forming on your
        cheekbone. "
    takedesc = "It's attached to the dresser. "
    verDoLookin(actor) = {}
    doLookin(actor) = "You see yourself as a nine-year-old, a nasty bruise
        forming on your cheekbone. "
    verDoBreak(actor) = { "Your father would skin you alive. "; }
;

mythology_book: readable
    stage = 3
    bulk = 3
    weight = 4
    noun = 'book'
    plural = 'books'
    adjective = 'mythology'
    location = bedroom_dresser
    sdesc = "book of mythology"
    ldesc = "In the third grade you became enamored with Greek mythology,
        scouring the 000-010 section of your school library. This book by
        Edith Hamilton is a remnant of that time. "
    readdesc = "You flip through the book, remembering different stories which
        caught your attention:\ Perseus and Medusa, the rivers lethe and
        mnemosyne, Zeus visiting Leda in the guise of a swan. "
;

faerie_book: readable
    stage = 0                // Don't ask, don't tell
    bulk = 10
    weight = 5
    noun = 'book' 'faeries' 'fairies' 'faerie' 'fairy' 'faery'
    plural = 'books'
    location = bedroom_dresser
    sdesc = "book of faeries"
    ldesc = "Shortly after your interest in mythology waned, you became
        interested in faeries. At this age your nascent research had not yet
        taken over the top of your dresser, as this lone oversized book can
        attest. "
    readdesc = "As you skim through the book, several facts jump out:\ how
        faeries are driven away by church bells, how they change homes on
        Quarter Days, how you shouldn't eat faerie food, how a four-leaf clover
        will let you see them. "
;

bedroom_door: fixedItem
    stage = 0
    noun = 'door'
    adjective = 'east'
    location = bedroom
    sdesc = "door"
    ldesc = "It is closed. "
    verDoOpen(actor) = "Your father would see you come out of your room if
        you left via this door, and the punishment to follow would be
        painful. "
    verDoClose(actor) = "It's already closed. "
    verIoTieTo(actor) = {}
    verDoKnockon(actor) = {
        "From somewhere else in the house, your father yells, \"Don't make me
            come up there!\" ";
    }
;

bedroom_window: openable, fixedItem
    stage = 3
    isopen = nil
    noun = 'window'
    adjective = 'bedroom'
    location = bedroom
    sdesc = "bedroom window"
    ldesc = "The window is <<self.wordDesc>> and looks out on the rolling
        hills behind your house; without looking directly through the window,
        the details are hard to make out. You can just see your backyard one
        story beneath you. "
    verDoLookthru(actor) = {}
    doLookthru(actor) = "You see the hills behind your house and your
        backyard. Your father called that region \"Big Country,\" and
        he used to tell you stories of heroes who walked Big Country in search
        of adventures. Though he stopped telling you those stories after
        your mom died, the dreams stay with you. "
    ioPutIn(actor, dobj) = {
        if (dobj == bedsheet && dobj.tiedTo != nil) {
            "If you wish to climb down the sheet, you need only hold it
                while you climb out the window. ";
            return;
        }
        "You drop <<dobj.thedesc>> through the window. It vanishes to the
            ground below. ";
        dobj.moveInto(backyard1);
    }
    ioThrowAt(actor, dobj) = {
        if (!self.isopen)
            dobj.doThrowAt(actor, self);
        else {
            if (dobj == bedsheet && dobj.tiedTo != nil)
                "If you wish to climb down the sheet, you need only hold it
                    while you climb out the window. ";
            else {
                "You throw <<dobj.thedesc>> through the window. It vanishes
                    to the ground below. ";
                dobj.moveInto(backyard1);
            }
        }
    }
    verDoEnter(actor) = {}
    doEnter(actor) = {
        local dest;

        dest = bedroom.west;
        if (dest == nil) return;
        actor.travelTo(dest);
    }
    doSynonym('Enter') = 'Climb'
    verDoBreak(actor) = { "Your father would skin you alive. "; }
;

backyard_faeries: Actor
    stage = 0                // Don't ask about us
    daemonNumber = 1
    canSeeMe = { return (four_leaf_clover.location == Me); }
    isThem = true
    isHim = true
    noun = FAERIE FAERIES 'creature' 'creatures' 'leprechaun' 'leprechauns'
        'voice' 'voices'
    adjective = 'small' 'invisible'
    sdesc = {
        if (canSeeMe) "small faeries";
        else
            "invisible creatures";
    }
    ldesc = {
        if (canSeeMe) "There are three of them, small faeries with gnarled
            faces and red stubbly beards. ";
        else
            "You look all over, but can't find the source of the voices. ";
    }
    thedesc = {
        if (canSeeMe) "the small faeries";
        else "the invisible creatures";
    }
    actorDesc = {
        if (canSeeMe)
            "Three faeries are conversing near your feet. ";
    }
    takedesc = "They manage to be wherever your hands are not without seeming
        to move. "
    actorAction(v, d, p, i) = {
        if (canSeeMe)
            "The faeries do not notice you. ";
        else "You cannot see anyone to address. ";
        exit;
    }
    verDoAskAbout(actor) = {
        if (canSeeMe)
            "The faeries do not notice you. ";
        else "You cannot see anyone to address. ";
    }
    verIoShowTo(actor) = {
        if (canSeeMe)
            "The faeries do not notice you. ";
        else "You cannot see anyone to address. ";
    }
    verDoAttack(actor) = { "Given what you've read of faeries, you refrain. "; }
    daemon = {
        switch (daemonNumber++) {
            case 1:            // Introduce the faeries
            self.moveInto(Me.location);
            "\bFrom somewhere around your feet you hear a tiny voice pipe up:\ 
                \"Top o' the mornin' to ya!\" You look down";
            if (canSeeMe) " and see a small faerie just on this side of the
                fence. He is joined by two others, though you can't see where
                they came from.\bOne of the others replies";
            else {
                ", but can't find the source of the voice.\bAnother voice joins
                    in, saying";
                voicesAh.see;
            }
            ", \"And the rest of the day to yerself!\" ";
            break;

            case 3:            // Father calls
            "\b";
            if (Me.location == tool_shed)
                "From outside the shed";
            else "From the house";
            " you hear, \"Terry! TERRY!\"\b
            Your father. He's found your open window. ";
            break;

            case 4:            // Move the faeries to the shed
            if (Me.location != self.location)    // Nasty workaround
                goto noTalk1;
            "\b";
            if (canSeeMe)
                "One of the faeries says to the other two";
            else "Again a voice near your feet says";
            ", \"Shall we be returnin'? The king wanted us back quick as
                possible.\"\b
                \"Aye.\"\b
                \"But we're without a padfoot. How to get back?\"\b
                \"I've a way,\" responds ";
            if (canSeeMe) "the third faerie";
            else "a third voice";
            ". \"'Tis in the shed.\" The ";
            if (canSeeMe) "faeries move to the east";
            else "voices move away";
            ". ";
noTalk1:
            self.moveInto(tool_shed);
            if (Me.location == tool_shed && canSeeMe)
                "\bThree small faeries slip into the shed. ";
            break;

            case 6:            // Have the faeries fly away, leaving a hat
            if (Me.location != self.location)    // Nasty workaround pt 2
                goto noTalk2;
            "\b";
            if (canSeeMe) {
                "One of the faeries pulls several over-sized white hats from
                    under a pile of dirt. Despite their earthy storage they
                    are pristine white. He hands them to the others. Then he
                    wears his hat, saying, \"I'm off!\" In a flash, he zips out
                    the door and into the air.\b
                    The two remaining faeries don their hats. \"I'm after!\"
                    \"I'm after!\" Both are caught up in the air and are gone.\b
                    In their wake, a lone white hat drifts to the floor of the
                    shed, forgotten. ";
                white_hat.moveInto(tool_shed);
                followFaeriesAh.see;
            }
            else "At your feet, you hear three successive voices say: \"I'm
                off!\" \"I'm after!\" \"I'm after!\" After each sentence you
                feel a light breeze blow past you. ";
noTalk2:
            self.moveInto(nil);
            break;

            case 10:            // Dad shows up
            "\bYour father ";
            if (Me.location == tool_shed)
                "comes into the tool shed, looking around";
            else "appears from behind the shed, glancing about";
            ". He is in his late thirties, a vigorous man who shows no sign
                of the cancer which will steal his life in thirteen years. His
                face darkens when he sees you, and he walks stiffly towards
                you. \"_There_ you are,\" he says, grabbing your ear and
                pulling firmly. You skip after him, pain burgeoning across
                your head.\b
                Your father punctuates each phrase with a twist of your ear,
                causing sparks to burst across your vision. \"You were
                supposed\"--twist--\"to stay\"--twist--\"in your room\"--twist.\b
                The final twist overcomes you; your vision dims. The throbbing
                in your head worsens as you fall back.\b
                A hospital bed catches you, supporting you. A quick glance
                shows you a sterile hospital room. No one else is here; the
                room is yours alone. Then a black tide washes over you,
                carrying you away....";
            die();
        }
    }
;

chain_link_fence: wallpaper
    stage = 3
    noun = 'fence'
    adjective = 'chain' 'chain-link'
    sdesc = "chain-link fence"
    ldesc = "Your father put up the fence in preparation for the puppy he
        kept promising you. Nothing ever came of the puppy, but the fence
        remained. "
    verDoClimb(actor) = {
        "Though you climbed it many times when you were younger, you find that
            you can't today, that your feet and hands won't obey you when you
            try. ";
    }
;

backyard_grass: wallpaper
    stage = 3
    noun = 'grass' 'mat'
    adjective = 'grass'
    sdesc = "grass"
    ldesc = {
        "It thickly covers the ground. ";
        if (Me.location == backyard1)
            "A rogue patch of clover has established a beachhead in the sea
                of grass. Your father will no doubt rip it out at the first
                opportunity, restoring the backyard to its former glory. ";
    }
    verDoSearch(actor) = {
        "There is too much of it for you to search indiscriminately. ";
    }
;

backyard1: room
    floating_items = [chain_link_fence, backyard_grass]
    sdesc = "South Part of Backyard"
    ldesc = "The backyard ends to the south and west in a chain-link
        fence which fetches up against your house. Grass covers the
        ground in a remarkably even carpet. "
    exits = 'north'
    north = backyard2
    south = { "The chain-link fence prevents you. "; return nil; }
    east = { "The house is in the way. "; return nil; }
    west = { return south; }
;

backyard_house: decoration
    stage = 0
    noun = 'house'
    location = backyard1
    sdesc = "your house"
    thedesc = "your house"
    adesc = "your house"
    ldesc = "It rises to the east, a two-story brick edifice from your childhood. "
;

backyard_bedsheet: distantItem
    noun = 'sheet' 'bedsheet'
    location = backyard1
    sdesc = "bedsheet"
    ldesc = "It dangles above you, far out of reach. "
;

clover_patch: fixedItem
    stage = 3
    haveSearched = nil
    noun = 'clover' 'patch'
    adjective = 'clover'
    location = backyard1
    sdesc = "patch of clover"
    ldesc = "The patch of clover huddles together in solidarity against the
        encroaching grass. "
    takedesc = {
        if (haveSearched)
            "You find only three-leaf clovers this time, which you scatter
                to the wind. ";
        else "You grab a handful of clover at random, then drop it for the
            wind to catch. ";
    }
    verDoSearch(actor) = {
        if (haveSearched)
            "You search for a while longer, but find no more four-leaf
                clovers. ";
    }
    doSearch(actor) = {
        "You get on hands and knees and begin carefully examining each clover
            individually. After a moment you are rewarded with a pristine
            four-leaf clover, which you take. ";
        four_leaf_clover.moveInto(actor);
        haveSearched = true;
        voicesAh.solve;
    }
;

four_leaf_clover: item
    stage = 3
    noun = 'clover'
    adjective = 'four-leaf' 'four-leaved' 'four'
    weight = 0
    bulk = 1
    sdesc = "four-leaf clover"
    ldesc = "A deep emerald sprig. It gleams, as if made of crystal. "
;

backyard2: room
    floating_items = [chain_link_fence, backyard_grass]
    sdesc = "North Part of Backyard"
    ldesc = "The fence paces you to the west, then angles north to block
        further progress. To the east is the old tool shed your father built.
        The thick mat of grass leads back south. "
    exits = 'south and east'
    north = { "The chain-link fence is in your way. "; return nil; }
    south = backyard1
    east = tool_shed
    west = { return north; }
    firstseen = {
        notify(backyard_faeries, &daemon, 0);
    }
;

fake_shed: fixedItem
    noun = 'shed' 'plate' 'plates' 'pillar' 'pillars'
    adjective = 'tool' 'aluminum' 'aluminium'
    location = backyard2
    sdesc = "tool shed"
    ldesc = "The shed leans to one side, a tired structure resting its old
        joints. The door's been missing since you can remember. The entire
        structure balances on four short pillars capped off with plates of
        soft aluminum to foil termites. "
    verDoEnter(actor) = {}
    doEnter(actor) = { actor.travelTo(tool_shed); }
;

tool_shed: insideRm
    sdesc = "Tool Shed"
    ldesc = "Light filters through chinks in the roof, dimly illuminating
        empty shelves and forgotten tools. The structure smells of mildew
        and rot. "
    exits = 'west'
    smelldesc = "Mold and dust make you sneeze. "
    west = backyard2
    out = backyard2
;

fake_shelves: decoration
    noun = 'shelf' 'shelves'
    stage = 3
    location = tool_shed
    sdesc = "shelves"
    ldesc = "Many of the shelves have warped and twisted from the elements. "
;

fake_tools: decoration
    noun = 'tool' 'tools'
    location = tool_shed
    sdesc = "tools"
    ldesc = "The tools are all in various stages of decay. For a while your
        father was interested in woodwork, but as your mom sickened, he
        lost interest. "
;

// The sounder, frome the granite cube puzzle in stage 4a, goes in the shed.
//  See cube.t for details

white_hat: clothingItem
    askDisambig = true
    clothing_family = HAT
    stage = 3
    noun = 'hat' 'cap'
    adjective = 'white' 'three-cornered' 'tri-cornered'
    weight = 3
    bulk = 7
    sdesc = "tri-cornered hat"
    ldesc = "The hat is tri-cornered and gleaming white. "
    feeldesc = "There is a light sprinkling of powder over it. "
    pixiedesc = 'One of our flying hats, no doubt.'
    putOnDesc = "As you wear the hat, a tingle runs the length of your body. "
    takeOffDesc = "You feel heavier as you remove the hat. "
;

cave_ceiling: wallpaper
    noun = 'ceiling' 'roof'
    sdesc = "ceiling"
    ldesc = "The ceiling of the cave is rough, though any protruding
        stalactites have been removed. "
;

class caveRm: room
    floating_items = [cave_ceiling]
;

faerie_cave: caveRm
    northOpen = true
    upOpen = nil
    goneUpOnce = nil    // Man, what a work-around
    sdesc = "Cave"
    ldesc = {
        "The cave encloses you, reflecting the sound of your breathing. It is
            dry and illuminated, though you cannot find the source of the
            light. Rough stairs are cut into one part of the cave, leading ";
        if (upOpen) "to a thin exit above";
        else "nowhere";
        ". ";
        if (northOpen) "The cave widens to the north. ";
    }
    exits = {
        "You can go ";
        if (northOpen) {
            "north";
            if (upOpen)
                " and up";
        }
        else if (upOpen)
            "up";
        else "nowhere";
        ". ";
    }
    north = {
        if (northOpen) return light_hall;
        return self.noexit;
    }
    up = {
        if (upOpen) {
            if (!self.goneUpOnce) {
                "The exit closes behind you.\b";
                self.goneUpOnce = true;
            }
            return top_of_hill;
        }
        return self.noexit;
    }
    out = {
        if (upOpen)
            return self.up;
        if (northOpen)
            return self.north;
    }
;

fake_stairs: decoration
    noun = 'stair' 'stairs'
    adjective = 'rough'
    location = faerie_cave
    sdesc = "stairs"
    ldesc = "They are carved into one of the cave walls. "
    verDoClimb(actor) = {}
    doClimb(actor) = {
        local dest;

        if ((dest = faerie_cave.up) != nil)
            actor.travelTo(dest);
    }
;

light_hall: caveRm
    ruined = nil
    sdesc = "Hall of Stolen Light"
    ldesc = {
        if (ruined)
            "Someone has rearranged the hall with a heavy set of boots. The
                light sources have been smashed, the throne broken, the table
                overturned. Mud has been tracked across the carpet. ";
        else "Everywhere you look in this hall you find another source of light.
            They come in all shapes and forms:\ candles, lamps, crystals. The
            light bounces about the room, illuminating the throne at the north
            end of the hall. A thick carpet runs from the throne to the south
            exit, passing by a banquet table. ";
    }
    exits = 'south'
    firstseen = {
        notify(faerie_king, &daemon, 0);
        pass firstseen;
    }
    // Handle dropping things
    roomAction(a, v, d, p, i) = {
        if (self.ruined) pass roomAction;
        if (a == Me && (v == dropVerb || v == putVerb)) {
            if (d != mason_jar) {
                "The guards clench their fists, and you find yourself unable
                    to move. ";
                exit;
            }
            "As you let go of the mason jar, it falls slowly. The king narrows
                his eyes at you. \"Rejecting our offer, are you?\"\ he asks. 
                Startled, you jerk back. ";
            faerie_guards.death;
        }
        else pass roomAction;
    }
    enterRoom(actor) = {
        if (self.ruined)
            grey_man.moveInto(top_of_hill);
        pass enterRoom;
    }
    leaveRoom(actor) = {
        if (faerie_guards.location == self && !banquet_food.eaten) {
            "The guards both cross their arms at their chests, and you find
                yourself unable to leave. ";
            exit;
        }
        pass leaveRoom;
    }
    south = faerie_cave
    out = faerie_cave
;

fake_light: intangible
    stage = 0
    noun = 'light'
    location = light_hall
    sdesc = "light"
    ldesc = "It surrounds you, suffusing the entire room with a warm glow. "
;

fake_light_sources: decoration
    askDisambig = true
    stage = 3
    isThem = true
    noun = 'crystal' 'crystals' 'lamp' 'lamps' 'candle' 'candles'
        'source' 'sources'
    adjective = 'light' 'king' 'king\'s'
    location = light_hall
    sdesc = "sources of light"
    ldesc = {
        if (light_hall.ruined)
            "Someone has smashed them all. ";
        else "The sources of light decorate the room. ";
    }
    verIoAskAbout(actor, dobj) = {}
    pixiedesc = {
        "The pixie grins sardonically. \"So you have seen our vaunted king's
            collection, have you?\" He lowers his voice. \"Yet it cannot be
            complete 'til someone captures the dragon's fire for him.";
        if (find(mason_jar.factTold, lonely_pixie) == nil)
            " Thank your luck you have not been chosen to bear the king's jar
                to the dragon's lair.";
        "\" ";
    }
;

light_throne: chairItem, decoration
    noun = 'throne'
    adjective = 'ivy' 'wood'
    location = light_hall
    sdesc = "throne"
    ldesc = {
        if (light_hall.ruined)
            "The throne lies in ruins, its wood snapped, the ivy which once
                decorated it torn and tossed atop the wreckage. ";
        else {
            "The throne is made of a finely-wrought blonde wood. Growing around
                its legs and up its back are strands of ivy. ";
            if (faerie_king.location == self)
                "Seated on it is the faerie king. ";
        }
    }
    verDoSiton(actor) = {
        if (faerie_king.location == self)
            "Not while the faerie king is there! ";
        else if (light_hall.ruined)
            "There's not much left to sit on. ";
        else pass verDoSiton;
    }
;

light_carpet: decoration
    noun = 'carpet' 'mud'
    adjective = 'grass' 'green'
    location = light_hall
    sdesc = "carpet"
    ldesc = {
        if (light_hall.ruined)
            "Mud has ruined the carpet's once-pristine surface. ";
        else
            "It is made of interwoven grass which forms a thick, springy mat. ";
    }
;

banquet_table: fixedItem, surface
    noun = 'table'
    adjective = 'banquet'
    location = light_hall
    sdesc = "banquet table"
    ldesc = {
        local list = contlist(self);

        if (banquet_food.location == self)
            list += banquet_food;
        if (light_hall.ruined)
            "The table is cracked in the center. It now leans at a drunken
                angle. ";
        else {
            "The sturdy table has seen much use in its time. It is covered with
                heavy scars. ";
            if (length(list) > 0)
                "On its surface you see <<listlist(list)>>. ";
        }
    }
    takedesc = "It is much too heavy. "
    verIoPutOn(actor) = {
        if (light_hall.ruined)
            "It is in no condition to hold anything. ";
    }
;

banquet_food: fixedItem
    eaten = nil
    noun = 'food' 'steak' 'chicken' 'cheese' 'cheeses' 'bread'
    location = banquet_table
    sdesc = "food"
    thedesc = "some food"
    adesc = "some food"
    ldesc = "Steak, chicken, cheeses, bread--all grace the banquet table. "
    takedesc = "There is too much of it. "
    verDoEat(actor) = {}
    doEat(actor) = {
        "You take a few bites of the food, then spit it out. It has no taste.\b
            The guards, who made no move to stop you, grin, revealing their
            many
            rows of teeth. The faerie court draws back, hissing. \"Well,\" the
            king says, \"the human has partaken of our bounty. And having
            enjoyed our hospitality, is ours.\"\b
            True Thomas interrupts, \"Sire, if you intend to keep the child
            until harvest time, might I suggest where? In my travels, I have
            discovered just the place:\ the child will not be underfoot.\"\b
            The king frowns, brow furrowed. Then, after a moment's thought, he nods.
            \"Done.\" And the ground beneath you opens, dropping you into...\b";
        self.eaten = true;
        self.moveInto(nil);
        unnotify(faerie_king, &daemon);
        Me.travelTo(cell);
        self.eaten = nil;        // For the next time around
    }
;

class faerie_type: Actor
    askDisambig = true
    stage = 3
    ioAskAbout(actor, dobj) = {
        if (dobj == lonely_pixie) {
            switch(lonely_pixie.toldBanishment) {
                case 1:
                "The pixie looks away. \"Ask me not about the faerie court.\" ";
                break;

                case 2:
                "The pixie looks at you, eyes flashing. \"And you cannot keep
                    from asking, I will make you hear the story entire!\" As
                    quickly as the pixie has become angry he becomes dejected.
                    He sits on one of the toadstools, head in hands.\b
                    \"Not so long ago, I was one of the court.\" His squeaky
                    voice is soft. \"Never of high station, no, never one of
                    the inner circle, but happy enough to be in the court.
                    And then.\"\b
                    He pauses before continuing. \"And then once
                    I did not agree quickly enow with our king. We were living
                    then in this ring of toadstools, but next moving day I
                    awoke alone. I had been left, banished from the realm.\b
                    \"It was his right! His right, aye, but why?\" The pixie
                    hops from his perch and wanders aimlessly around the ring.
                    \"He was a stern one in past times, though those who still
                    speak to me say he has mellowed. But not towards me.\" He
                    sighs before returning slowly to his cleaning. ";
                break;

                case 3:
                "\"No more!\"\ he shouts. \"I will not be mocked!\" He throws
                    a handfull of powder in your eyes. When you can see again,
                    he is gone. ";
                lonely_pixie.moveInto(limbo);
                solitary_toadstool.moveInto(nil);
                toadstool_door.moveInto(nil);
                break;
            }
            lonely_pixie.toldBanishment++;
        }
        else pass ioAskAbout;
    }
    actorAction(v, d, p, i) = {
        faerie_guards.spokenTo;
        exit;
    }
    doAskAbout -> faerie_guards
    ioGiveTo -> faerie_guards
    ioShowTo -> faerie_guards
    ioThrowAt -> faerie_guards
    doKick -> faerie_guards
;

faerie_king: faerie_type
    daemonNumber = 1
    noun = 'king'
    adjective = FAERIE
    location = light_throne
    sdesc = "faerie king"
    thedesc = "the faerie king"
    adesc = "a faerie king"
    ldesc = "He is one of the tallest faeries you have yet met. His beard is
        red and reaches to his waist. Other than his clothes of rough cloth,
        he wears a gold circlet around his head, sign of his kingship. "
    actorDesc = "The faerie king sits on the throne, regarding you. "
    takedesc = faerie_guards.death
    touchdesc = faerie_guards.death
    verDoKiss(actor) = {}
    doKiss(actor) = faerie_guards.death
    daemon = {
        "\b";
        switch (daemonNumber++) {
            case 1:
            "The king looks at you, his eyes glinting strangely. \"A human
                child? It's been an age since one visited.\" While he speaks,
                the other faeries slowly circle you. A sibilant whisper rises
                from the gathering. ";
            if (white_hat.location == Me)
                    "\"Guards, retake what is ours.\" One of
                    the guards reaches over and plucks the white hat from you. ";
            white_hat.isworn = nil;
            white_hat.moveInto(nil);
            break;

            case 2:
            "\"We've naught to offer to incipient royalty such as yourself,\"
                the king continues mockingly. He pauses for a moment, stroking
                his beard. His queen leans over and whispers to him, causing
                him to grin. There is nothing human in his expression.
                \"Perhaps there is something you can offer us instead,\" he
                says. ";
            break;

            case 3:
            "The other faeries stop circling and point at you. You feel a
                tingle running up and down your spine. \"We'd have from you a
                story, but one already fills that role.\" The king gestures at
                True Thomas, who glances uncomfortably at you. \"No, for you
                I think harvesting would suit.\" The faeries begin
                running, flying, hopping around you, a writhing mass of flesh.
                The guards to either side of you take one step back. ";
            break;

            case 4:
            "\"Hold!\"\ shouts Thomas. The assemblage halts, many in mid-air.
                As one they turn and focus unnaturally-bright eyes on Thomas,
                who blanches. Nevertheless, he continues. \"King, could this
                child not fetch for you some new light?\" As Thomas finishes,
                the silence deepens. Sweat begins to run down his face. ";
            true_thomas.worried = true;
            break;

            case 5:
            "\"A fine suggestion!\"\ the king finally says. Thomas sways
                somewhat, as if released from a painful grip. From the horde of
                faeries an excited buzz arises. ";
            true_thomas.worried = nil;
            break;

            case 6:
            "\"My hall is lit by light stolen from many a source,\" the king
                explains. At the snap of a finger, one of the faeries brings
                forward a bright glint cupped in his hands. \"Taken from one of
                Judas' silver pieces, that was,\" says the king. Another faerie
                brings forward a dancing flame. The flame radiates cold you
                can feel from feet away. \"At the heart of every pawnbroker's
                diamond is a flame like this,\" says the king. \"And you'll be
                fetching me the light of a dragon's flame.\" ";
            break;

            case 7:
            "A tiny faerie approaches bearing a mason jar, which he places in
                your hands. \"Capture the light of a dragon's flame in that
                jar,\" says the king, \"but let not the flame touch the jar,
                for it will melt.\" ";
            mason_jar.moveInto(Me);
            break;

            case 8:
            "\"Return with the dragon fire and we will reward you.\" As the
                king finishes speaking, the two guards lead you back out of
                the hall.\b";
            faerie_guards.moveInto(nil);
            banquet_food.moveInto(nil);
            fake_light.moveInto(nil);
            faerie_cave.upOpen = true;
            faerie_cave.northOpen = nil;
            Me.travelTo(faerie_cave);
            light_hall.ruined = true;
            dragonAh.see;
            dragonSeeAh.see;
            dragonSmellAh.see;
            dragonHearAh.see;
            dragonBurnAh.see;
            unnotify(self, &daemon);
        }
    }
;

faerie_queen: faerie_type
    noun = 'queen'
    adjective = FAERIE
    location = light_hall
    sdesc = "faerie queen"
    thedesc = "the faerie queen"
    adesc = "a faerie queen"
    ldesc = "She stands quietly, watching what goes on. Her eyes are large and
        luminous. Though she says nothing, she is carefully following
        everything that is said. "
    actorDesc = "Beside the king stands his queen. "
    takedesc = faerie_guards.death
    touchdesc = faerie_guards.death
    verDoKiss(actor) = {}
    doKiss(actor) = faerie_guards.death
;

true_thomas: Actor
    askDisambig = true
    worried = nil
    stage = 3
    isHim = true
    noun = 'thomas' 'rhymer'
    adjective = 'true'
    location = light_hall
    sdesc = "True Thomas"
    ldesc = "He is an old man, with snow-white hair and a creased face. He
        holds a stringed instrument which he absentmindedly strums from time
        to time. "
    actorDesc = {
        "Off to one side of the throne, True Thomas ";
        if (self.worried) "stands nervously. ";
        else "idly sits. ";
    }
    takedesc = faerie_guards.death
    touchdesc = faerie_guards.death
    pixiedesc = 'The only mortal in the king\'s court. He stumbled into the
        faerie kingdom years ago, and the king kept him to make the court
        merry.'
    actorAction(v, d, p, i) = {
        faerie_guards.spokenTo;
        exit;
    }
    verDoKiss(actor) = {}
    doKiss(actor) = faerie_guards.death
    doAskAbout -> faerie_guards
    ioGiveTo -> faerie_guards
    ioShowTo -> faerie_guards
    doKick -> faerie_guards
;

faerie_court: faerie_type
    isThem = true
    noun = FAERIE
    plural = FAERIES
    location = light_hall
    sdesc = "faeries"
    thedesc = "the faeries"
    adesc = "some faeries"
    ldesc = "The faeries ring the throne, looking at you or whispering to one
        another. Their size and shape vary wildly, though none are over a meter
        tall. "
    actorDesc = "Faeries stand all around you, watching you with a disturbing
        intensity. "
    takedesc = "The faeries move out of your way, giggling. The guards pull
        you back. "
    touchdesc = takedesc
;

faerie_guards: Actor
    isThem = true
    noun = 'guard'
    plural = 'guards'
    adjective = FAERIE FAERIES
    location = light_hall
    sdesc = "faerie guards"
    thedesc = "the faerie guards"
    adesc = "some faerie guards"
    ldesc = "The guards stand to either side of you, hemming you in. "
    actorDesc = "To either side of you stands a faerie guard. "
    takedesc = faerie_guards.death
    touchdesc = faerie_guards.death

    death = {
        "As you move, the two guards touch you. A shock races through you as
            your knees give way and you fall to the floor. As you close your
            eyes you see the faeries watching you with inhuman eyes. Only
            True Thomas seems saddened.\b
            Then you jerk awake, as from a bad dream. Sweat dampens the covers
            of your hospital bed. Your breathing takes some time to slow, but
            as it does you drop into a dreamless sleep. ";
        die();
    }
    spokenTo = {
        "One of the guards taps you, and you find yourself unable to say
            anything. \"Speak when you are spoken to,\" he says in a lilting
            voice. ";
    }

    actorAction(v, d, p, i) = { spokenTo; exit; }
    verDoAskAbout(actor) = { spokenTo; }

    verIoGiveTo(actor) = {}
    ioGiveTo(actor, dobj) = {
        if (dobj == mason_jar)
            "The guards prevent you. ";
        else {
            "As you bring out <<dobj.thedesc>>, the two guards grab your arms,
                forcing you to drop <<dobj.isThem ? "them" : "it">>. The king
                holds up one hand, and the guards subside. ";
            dobj.moveInto(light_hall);
        }
    }
    ioSynonym('GiveTo') = 'ShowTo'
    verDoKick(actor) = {}
    doKick(actor) = { death; }
    verIoThrowAt(actor) = {}
    ioThrowAt(actor, dobj) = { death; }
;

mason_jar: container
    askDisambig = true
    lightFilled = nil
    stage = 3
    noun = 'jar'
    adjective = 'mason'
    bulk = 3
    weight = 3
    sdesc = "mason jar"
    ldesc = {
        local list = contlist(self);

        "The mason jar is made of thick glass. ";
        if (length(list) > 0)
            "Rattling around inside it you see <<listlist(list)>>. ";
        if (lightFilled)
            "It glows with an angry red light. ";
    }
    pixiedesc = {
        "The pixie says, \"So...the king has at last found someone to fetch
            for him the light of the dragon.\" He cocks his head and peers
            up at you. \"And he did mention the precautions?\"\b
            When you shake your head, he leaps into the air, hovering for a
            second. \"No word of the wards?\" He mutters, then runs into his
            home. There is the sound of rummaging, things being thrown about,
            before he emerges holding a pair of boots.\b
            \"You must have wards, lest the dragon sense you. You must be
            silent, you must be invisible, you must be without scent.\" He
            squints at you, then adds as an afterthought, \"Also fireproof.\b
            \"A laurel of ash dipped in the blood of another will make you
            invisible to animals. These boots,\" he hands the boots to you,
            \"are elfin and will muffle your steps. An oak staff will protect
            you from the dragon's flame.\" ";
        elf_boots.moveInto(Me);
        dragonAh.solve;
    }
    verIoPutIn(actor) = {
        if (lightFilled)
            "You cannot; the dragon's fire has sealed the jar. ";
    }
    verDoBreak(actor) = {}
    doBreak(actor) = {
        "You hurl down the jar, which smashes into millions of tiny shards";
        if (lightFilled) {
            " in an intense flash of light. ";
            if (grey_man.holdingLoose && grey_man.location == actor.location) {
                "The grey man looks down in time to be blinded by the light.
                    He screams, throwing one arm across his face. When he pulls
                    his arm back down, you see that his eyes have been burnt
                    from their sockets. ";
                grey_man.pullOverBluff;
            }
        }
        else ". ";
        if (Me.location == light_hall && faerie_king.location == light_throne) {
            "The king looks at you. \"You should not do such things, willful
                child,\" he tells you. You instinctively take a step back. ";
            faerie_guards.death;
        }
        self.moveInto(nil);
    }
;

fake_hill: wallpaper
    noun = 'hill'
    adjective = 'grassy'
    sdesc = "hill"
    ldesc = "The grassy hill was your playground for years. "
    verDoClimb(actor) = {}
    doClimb(actor) = {
        if (proptype(actor.location, &climbHill) == 2)
            actor.travelTo(actor.location.climbHill);
        else actor.location.climbHill;
    }
;

top_of_hill: room
    floating_items = [fake_hill]
    downOpen = nil
    sdesc = "Top of Hill"
    ldesc = {
        "The hill curves away from this spot, crowned on top by a gnarled
            thorn tree. Paths curve down the hill to the west and south. ";
        if (downOpen)
            "A passage gapes in the side of the hill, leading down. ";
        "Far to the north is a small white church. ";
    }
    exits = {
        "You can go south ";
        if (downOpen)
            ", west, and down. ";
        else "and west. ";
    }
    climbHill = "You are already at the top of the hill. "
    listendesc = "You hear music. "
    north = {
        "The hill drops too steeply for you in that direction. ";
        return nil;
    }
    south = hill_bottom
    west = bluff
    down = {
        if (downOpen) return faerie_cave;
        "There are two ways down the hill:\ south and west. ";
        return nil;
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (dog.isWaiting && dog.location == self) {
            "\b<<dog.capdesc>>, upon seeing you, cocks its head at you and
                stands. The dog has now reached full adulthood. ";
            if (rucksack.location == dog)
                "On its back is the rucksack. ";
            dog.clearProps;
            dog.wantheartbeat = true;
        }
        if (grey_man.location == self) {
            "\bThe grey man reaches out and grabs you before you can run. ";
            grey_man.holdingTight = true;
            notify(grey_man, &scoldTerryC, 0);
            greyManAh.see;
        }
    }
    roomAction(a, v, d, p, i) = {
        if (grey_man.location == self && (!v.issysverb && v != inspectVerb &&
            v != waitVerb && v != againVerb && v != iVerb && v != lookVerb)) {
            "The grey man tightens his grip on you, preventing you from moving
                or drawing much breath. ";
            exit;
        }
        pass roomAction;
    }
;

thorn_tree: fixedItem
    askDisambig = true
    stage = 3
    noun = 'tree'
    adjective = 'thorn' 'gnarled'
    location = top_of_hill
    sdesc = "thorn tree"
    ldesc = "It curves and stoops, as if shielding itself from the sky. "
    pixiedesc = 'It marks the entrance to the kingdom.'
    verDoClimb(actor) = {
        "There is a reason it is called a thorn tree. You scratch yourself
            horribly in the attempt. ";
    }
    verIoTieTo(actor) = {}
;

top_of_hill_paths: decoration
    noun = 'path' 'paths'
    location = top_of_hill
    sdesc = "paths"
    ldesc = "The paths lead down the hill to the west and south. "
;

distant_baptist_church: distantItem
    noun = 'church'
    adjective = 'small' 'white' 'baptist'
    location = top_of_hill
    sdesc = "Baptist church"
    ldesc = "The church you attended until your mother fell ill. You can hear
        music floating from it; it must be revival week. "
    listendesc = "You hear a loud, happy hymn, accompanied by many pairs of
        hands clapping. \"A Friend to Me\" perhaps? "
    verDoListenTo(actor) = {}
;

church_music: intangible
    stage = 3
    noun = 'music' 'hymn'
    adjective = 'loud' 'happy'
    location = top_of_hill
    sdesc = "music"
    listendesc = (distant_baptist_church.listendesc)
;

bluff: room
    floating_items = [far_away_kill, far_away_rocks, fake_hill]
    sdesc = "Bluff"
    ldesc = "The hill drops off sharply to the west, overlooking a rocky tumble
        to a kill below. A worn path leads up to the east and down to the
        southeast. "
    exits = 'east and southeast'
    climbHill = top_of_hill
    east = top_of_hill
    west = {
        "The slope is too rocky. ";
        return nil;
    }
    se = hill_bottom
    up = self.east
    down = self.se
    roomAction(a, v, d, p, i) = {
        if (grey_man.location == self && !v.issysverb && v != inspectVerb
            && v != waitVerb && v != againVerb && v != iVerb && v != lookVerb) {
            if (grey_man.holdingTight || (v != attackVerb && v != breakVerb &&
                v != dropVerb && v != kickVerb && v != cutVerb)) {
                "The grey man tightens his grip on you, preventing you from
                    moving or drawing much breath. ";
                exit;
            }
        }
        pass roomAction;
    }
;

far_away_kill: distantItem, wallpaper
    noun = 'kill'
    location = bluff
    sdesc = "kill"
    ldesc = "The kill makes its slow, flowing way among rocks dislodged from
        the hill where you stand, victims of time and erosion. "
;

far_away_rocks: distantItem, wallpaper
    noun = 'rock' 'rocks'
    sdesc = "rocks"
    ldesc = "They lay scattered along the length of the kill. "
;

below_bluff: room
    floating_items = [far_away_kill, far_away_rocks, fake_hill]
    sdesc = "Side of the Bluff"
    ldesc = "You are clinging to the side of the bluff almost by your
        fingernails. Your wild descent has been arrested by an iron cage which
        is caught in some roots. The grey man has not been so lucky:\ his
        body lies folded in the kill below. The top of the bluff is a good
        ten feet above you. "
    up = {
        "You climb up the bluff, feet slipping. One flail of your feet catches
            the cage, knocking it free from its perch. You hear high-pitched
            screams as the cage tumbles down the side of the bluff. With a
            final pull you gain the top of the bluff, then look back over
            the edge. The cage is still falling; the screams still rising.
            Louder and louder, until you can hear nothing else....\n";
        Me.ctrlPoints -= 2;
        unnotify(trapped_faeries, &thrashAbout);
        my_hospital_bed.setup;
    }
    climbHill = { self.up; }
    roomAction(a, v, d, p, i) = {
        if (v == jumpVerb) {
            "Your hands won't let go. ";
            exit;
        }
        pass roomAction;
    }
;

roots: decoration
    noun = 'root' 'roots'
    location = below_bluff
    sdesc = "roots"
    ldesc = "They are wrapped around an iron cage, holding it fast. "
;

grey_man_body: distantItem
    stage = 0
    noun = 'body' 'man'
    adjective = 'grey' 'man' 'man\'s'
    location = below_bluff
    sdesc = "grey man"
    ldesc = "The grey man's head is tilted at an acute angle, a spot of
        non-color against the kill. "
;

iron_cage: fixedItem
    stage = 3
    noun = 'cage'
    adjective = 'iron'
    location = below_bluff
    sdesc = "iron cage"
    ldesc = "The iron cage is nearly two meters square. A cloth has been placed
        on the bottom of the cage. Faeries are crammed into it, trying
        desperately to avoid the sides of the cage. "
    takedesc = "Your position is too precarious. "
    verDoLookin(actor) = {}
    doLookin(actor) = {
        "You crane your head and peer at the faeries which fill the cage to
            overflowing. ";
    }
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You lean over the cage and pull open its door. In an
            instant, a rush of faeries flies past you. The sudden shift of
            weight inside the cage dislodges it from its perch, sending it
            tumbling. You find your hands slipping from the tree roots until
            you fall after the cage, ignored by all the faeries.\b
            All but one. She glances down, then pauses her upward flight. She
            gestures and your fall slows. A bright glow surrounds you,
            cushioning you. You feel your head strike a rock sharply, laying
            bare your skull. Pain and muzziness vie for control of your
            attention. The
            faerie frowns in concentration. She gestures again, and the glow
            brightens, blinding you.\n";
        Me.ctrlPoints++;
        unnotify(trapped_faeries, &thrashAbout);
        my_hospital_bed.setup;
    }
    verDoPush(actor) = {
        "Not as long as it's all that stands between you and a fall! ";
    }
    verDoStandon(actor) = {
        "You're already on the cage. ";
    }
    doSynonym('Push') = 'Pull' 'Turn'
;

fake_cloth: decoration
    stage = 3
    noun = 'cloth'
    location = iron_cage
    sdesc = "cloth"
    ldesc = "It has been draped across the bottom of the cage to keep the
        faeries from touching the iron bars. "
    takedesc = "Not without opening the cage. "
;

trapped_faeries: fixedItem
    stage = 0
    thrashNum = 1
    isThem = true
    noun = FAERIE FAERIES
    location = iron_cage
    sdesc = "faeries"
    ldesc = "The faeries mill about the cage, miserable in their contortions
        to avoid the walls and ceiling of the cage. "
    takedesc = "Not without opening the cage. "
    actorAction(v, d, p, i) = {
        "None of the faeries are listening to you. ";
        exit;
    }
    verDoAskAbout(actor) = { "None of the faeries are listening to you. "; }
    verIoGiveTo(actor) = {
        "None of the faeries are paying you much attention. ";
    }
    verDoAskFor(actor, io) = { "None of the faeries are listening to you. "; }
    verIoShowTo(actor) = {
        "None of the faeries are paying you much attention. ";
    }
    thrashAbout = {
        switch (thrashNum++) {
            case 2:
                "\bBelow you, you glimpse faeries fluttering about the confines
                    of their cage. One notices you. \"Please!\"\ he pleads.
                    \"Help us!\" ";
                break;
            case 3:
                "\bThe faeries' motions become even more frantic. One is
                    pressed against the bars and screams thinly. ";
                break;
            case 4:
                "\bThe rocking of the cage has grown worse. Both you and the
                    cage slip down an inch or so. ";
                break;
            case 5:
                "\bThe cage tumbles to the kill below, with you following.
                    The sound of running water grows louder, filling your
                    ears.\n";
                Me.ctrlPoints--;
                unnotify(self, &thrashAbout);
                my_hospital_bed.setup;
        }
    }
;

bluff_path: decoration
    noun = 'path'
    location = bluff
    sdesc = "path"
    ldesc = "It leads up to the east and down to the southeast. "
;

hill_bottom: room
    floating_items = [fake_hill]
    sdesc = "Bottom of Hill"
    ldesc = "The south side of a gently-sloping hill. Scrub grass clings
        tenaciously to its side. A path from the east divides here and crawls
        up the hill to the north and northwest. "
    exits = 'north, northwest, and east'
    climbHill = "You can go up to the north or the northwest. "
    north = top_of_hill
    nw = bluff
    east = nw_forest
;

scrub_grass: decoration
    noun = 'grass'
    adjective = 'scrub'
    location = hill_bottom
    sdesc = "scrub grass"
    ldesc = "It covers the hill in patches. "
    verDoEat(actor) = {
        "You haven't done that since you were three. ";
    }
;

hill_bottom_path: decoration
    noun = 'path'
    location = hill_bottom
    sdesc = "path"
    ldesc = "The path from the east divides in two, one branch leading north,
        the other leading northwest. "
;

class forestRm: room
    floating_items = [ forest_trees, forest_underbrush ]
    sdesc = "Forest"
;

forest_trees: wallpaper
    noun = 'tree' 'trees'
    adjective = 'mixed' 'hardwood'
    sdesc = "hardwood trees"
    ldesc = "Mixed hardwood trees, clustering tightly. "
    verDoClimb(actor) = { "None of them are suitable for climbing. "; }
;

forest_underbrush: wallpaper
    noun = 'brush' 'underbrush'
    sdesc = "underbrush"
    ldesc = "It blocks passage in many directions. "
;

nw_forest: forestRm
    ldesc = "Hardwood trees stand close together, choking off light and
        preventing you from seeing far. You can, however, see a hill rising to
        the west. You can walk through the trees and underbrush to the east
        and south. "
    exits = 'south, east, and west'
    south = sw_forest
    east = ne_forest
    west = hill_bottom
;

nw_forest_hill: distantItem
    noun = 'hill'
    adjective = 'grassy'
    location = nw_forest
    sdesc = "hill"
    ldesc = "It is visible between the trees, a ways to the west. "
;

ne_forest: forestRm
    sdesc = "Forest Clearing"
    ldesc = "The trees are grouped less tightly here, allowing space for an
        oak tree and a lone ash tree. The two trees leave room for passage to
        the north, south, and west. "
    exits = 'north, south, and west'
    north = dragons_hill
    south = se_forest
    west = nw_forest
    firstseen = {
        notify(bully, &daemon, 0);
        carvingAh.see;
        pass firstseen;
    }
;

oak_tree: fixedItem
    askDisambig = true
    stage = 3
    initials = 'B'
    secondInitials = ''
    noun = 'tree' 'oak'
    plural = 'trees'
    adjective = 'oak'
    location = ne_forest
    sdesc = "oak tree"
    ldesc = {
        "The oak tree towers above you, its bole wider than your arms can
            span. You spent a long time one summer trying to climb it, only to
            break your arm in the process. Since then, someone has hacked '<<
            self.initials>>' in its trunk";
        if (self.secondInitials != '')
            ", tried to scratch out the letters (with little success), then
            carved '<<self.secondInitials>>' just below the first letters";
        ". ";
    }
    touchdesc = {
        if (gloves.isworn) "You feel nothing through the gloves. ";
        else "The tree's bark is rough under your fingertips. ";
    }
    pixiedesc = (ash_tree.pixiedesc)
    verDoClimb(actor) = {
        "It is no more climbable for you at age nine than it was at age
            seven. ";
    }
    verIoTieTo(actor) = {}
;

oak_tree_actor: Actor
    askDisambig = true
    selfDisambig = true
    stage = 3
    askme = &oaktreedesc

    contentsVisible = nil
    isHim = true
    noun = 'tree' 'bob' 'oak'
    plural = 'trees'
    adjective = 'oak'
    sdesc = "oak tree"
    thedesc = "the oak tree"
    adesc = "an oak tree"
    stringsdesc = 'The oak tree'
    ldesc = {
        "The oak tree towers above you, its bole wider than your arms can
            span. You spent a long time one summer trying to climb it, only to
            break your arm in the process. Since then, someone has hacked '<<
            oak_tree.initials>>' in its trunk";
        if (oak_tree.secondInitials != '')
            ", tried to scratch out the letters (with little success), then
            carved '<<oak_tree.secondInitials>>' just below the first letters";
        ". ";
    }
    actorDesc = ""
    takedesc = "Not likely. "
    touchdesc = "\"Woo-hoo! Whoa! Don't tickle! Don't tickle!\"\ the tree
        says. "
    pixiedesc = 'Bob has stood upon that spot in the forest for years.'
    disavow = "The oak tree's branches wave in an approximation of a shrug.
        \"I dunno, Terry. Sorry.\" "
    actorAction(v, d, p, i) = {
        if (v == thankVerb) {
            if (oak_staff.location == self)
                "\"What for?\" ";
            else "The tree shrugs. \"I dunno if you should thank me or not,
                'specially if you're gonna use that to see the dragon.\" ";
            exit;
        }
        if (v==tellVerb && d==Me && p==aboutPrep) {
            self.checkAskAbout(i); // See if we can ask about this object
            exit;
        }
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
        "The tree's branches shake with laughter. ";
        if (v == helloVerb)
            "\"'lo again!\" ";
        else "\"Just calm down, now, Terry.\" ";
        exit;
    }
/*    ioAskAbout(actor, dobj) = {
        oak_tree.ioAskAbout(actor, dobj);
    }*/
    verDoThank(actor) = {}
    doThank(actor) = {
        if (oak_staff.location == self)
            "\"What for?\" ";
        else "The tree shrugs. \"I dunno if you should thank me or not,
            'specially if you're gonna use that ta see the dragon.\" ";
    }
    verDoAskFor(actor, io) = {
        if (io != oak_staff)
            "\"Like I've got anythin',\"\ the oak tree says. ";
        else if (oak_staff.location != self)
            "\"Look, I gave ya all I could,\" the tree protests. ";
    }
    doAskFor(actor, io) = {
        "\"Oh?\"\ the tree asks. Then, \"oh,\" he says knowingly. \"Well, I
            did say anything.\" There is the sound of rustling branches, then
            a particularly large one comes hurtling to the ground in front of
            you. \"I hope you're not plannin' on going after that dragon,
            though.\" ";
        io.moveInto(self.location);
        dragonBurnAh.solve;
    }
    verDoTouch(actor) = {}
    verIoGiveTo(actor) = {
        "\"Terry, Terry, Terry,\" the tree chuckles. \"Am I gonna put that in
            my pockets?\" ";
    }
    verIoShowTo(actor) = {
        "\"Mmm-hmm,\" mutters the tree, his mind elsewhere. ";
    }
    verIoTieTo(actor) = {
        "\"Hey, don't tie that to me!\"\ the tree says. ";
    }
    verDoClimb(actor) = {
        "\"Hey!\"\ the oak tree says. \"Didn't you learn anything the first
            time? Keep offa me!\" ";
    }
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "As you approach the oak tree, knife held before you, a branch cracks
            down on your head. \"I trusted you,\" the tree rumbles before
            hitting you again, hard.\b
            You fall down, tumbling head-first into a hospital bed. You gaze
            around in confusion, taking in the hospital room, empty of people
            except for you. Then the lump on your head starts hurting, and you
            begin thinking how nice it would be to sleep for a while, and soon
            you are.";
        die();
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.doCutWith(actor, dobj))

    firstTalk = {
        if (Me.location == self.location) {
            "\b\"Oww! Woo! Whoo!\" The voice is deep and booming, coming from
                somewhere above your head. You look around, but see no one.
                \"That smarts!\"\b
                You suddenly notice the oak tree wiggling in time to the voice.
                You peer at the tree, then jump back as some of its branches
                bend towards you. \"Oh, MAN, that's gonna be tender.\" One
                branch tenderly traces the carvings in the tree, then jerks
                away. \"Wooh. Thanks for the help, Terry.\"\b
                The tree must see the puzzled look on your face, because he
                begins laughing. \"Surprised, huh? I bet. We don't talk to
                many people these days, do we, Phil?\"\b
                You get another shock when the ash tree next to the oak waves
                its branches. \"Wmmf fmm,\" the ash tree says.\b
                \"Anyway, lissen. You ever need anything, you let me know.
                Okay?\"\b
                \"Pffth yrmm,\" agrees the ash tree. ";
            unnotify(self, &firstTalk);
        }
        else {
            if (getfuse(self, &firstTalk) == nil)
                notify(self, &firstTalk, 0);
        }
    }
;

oak_tree_initials: fixedItem, readable
    stage = 3
    noun = 'initial' 'initials' 'carving' 'letter' 'letters'
    location = ne_forest
    sdesc = "letters"
    ldesc = {
        "The letters '<<oak_tree.initials>>' have been carved in the trunk
            of the oak tree. ";
        if (oak_tree.secondInitials != '')
            "Someone has tried to scratch out those letters (with little
                success) and then carved '<<oak_tree.secondInitials>>'
                below them. ";
    }
    touchdesc = {
        if (oak_tree.location == ne_forest)
            oak_tree.touchdesc;
        else oak_tree_actor.touchdesc;
    }
    verDoCutIn(actor, io) = {}
;

oak_staff: item
    askDisambig = true
    stage = 3
    bulk = 12
    weight = 10
    noun = 'staff' 'branch'
    adjective = 'oak'
    location = oak_tree_actor
    sdesc = "oak staff"
    adesc = "an oak staff"
    ldesc = "It is nearly as tall as you, and is gnarled and bent. "
    pixiedesc = 'No fire will harm you while you hold an oak staff.'
    oaktreedesc = 'It\'s been a long time since I\'ve made a staff for someone.'
    verDoPutIn(actor, io) = {
        if (io == rucksack)
            "It won't fit. ";
        else pass verDoPutIn;
    }
    verIoTieTo(actor) = {}
    verIoAttackWith(actor) = {}
    ioAttackWith(actor, dobj) = {
        if (dobj != dragon && dobj != grey_man)
            "There's no need to use the staff as a weapon right now. ";
        else dobj.doAttackWith(actor, self);
    }
;

ash_tree: fixedItem
    askDisambig = true
    stage = 3
    noun = 'tree' 'ash'
    plural = 'trees'
    adjective = 'ash' 'lone'
    location = ne_forest
    sdesc = "ash tree"
    ldesc = "Thinner than its neighboring oak tree, the trunk of the ash
        gracefully sways in a gentle breeze. "
    pixiedesc = "The pixie's eyes slide away from yours. \"There's nowt I have
        to say about the tree.\" "
    verDoClimb(actor) = {
        "It is too thin to climb. ";
    }
    verIoTieTo(actor) = {}
;

ash_tree_actor: Actor
    askDisambig = true
    stage = 3
    isHim = true
    contentsVisible = nil
    noun = 'tree' 'phil' 'ash'
    plural = 'trees'
    adjective = 'ash' 'lone'
    sdesc = "ash tree"
    thedesc = "the ash tree"
    adesc = "an ash tree"
    ldesc = "Thinner than its neighboring oak tree, the trunk of the ash
        gracefully sways in a gentle breeze. "
    actorDesc = ""
    takedesc = "Not likely. "
    touchdesc = "\"Mrf mmm,\" says the ash tree. "
    pixiedesc = 'Phil? I\'ve known him for some time, though of late he has
        grown quiet.'
    oaktreedesc = "The oak tree replies, \"Oh, me and Phil have been around
        a while, right, bud?\"\b\"Gbbbz,\" the ash tree agrees. "
    actorAction(v, d, p, i) = {
        if (v == thankVerb) {
            if (ash_laurel.location == self)
                "\"Fwmml?\" ";
            else "The ash bows slightly. \"Glm pffffwb wb.\" ";
        }
        else "The ash tree says, \"Wmf brrrm.\" ";
        exit;
    }
    disavow = "\"Pfffl hrm,\" says the ash tree. "
/*    ioAskAbout(actor, dobj) = {
        ash_tree.ioAskAbout(actor, dobj);
    }*/
    verDoThank(actor) = {}
    doThank(actor) = {
        if (ash_laurel.location == self)
            "\"Fwmml?\" ";
        else "The ash bows slightly. \"Glm pffffwb wb.\" ";
    }
    verDoAskFor(actor, io) = {
        if (io != ash_laurel)
            "\"Bllf hrm smm,\"\ the ash tree says. \"Ahh, Phil doesn't have
                that.\"\ the oak tree adds. ";
        else if (io.location != self)
            "\"Wfmm! Plrf frgt vmnn!\"\ the ash tree says emphatically. \"C'mon,
                kid,\" the oak tree says. \"He can't spare another one!\" ";
    }
    doAskFor(actor, io) = {
        "The ash tree is silent for a second. Finally, the ash tree bends over
            and deposits a circle of ash branches at your feet. \"Blggg,\" he
            says. ";
        io.moveInto(self.location);
        io.askDisambig = true;        // So we can ask the pixie about it
        laurelAh.see;
    }
    verDoTouch(actor) = {}
    verIoGiveTo(actor) = {
        "\"He doesn't need that,\" the oak tree says. \"Bll phrbb,\" the ash
            tree agrees. ";
    }
    verIoTieTo(actor) = {
        "The ash tree twists out of your way, preventing you. ";
    }
    verDoAskAbout(actor) = {
        "\"Prrrm rfth wlft, zrm thmn lffm. Thrf nbbr wrm brrmlm.\" ";
    }
    verIoShowTo(actor) = {
        "There is no response. ";
    }
    verDoClimb(actor) = {
        "The ash tree says, \"Wff! Hrrg hmf fmf!\" The oak tree chimes in,
            \"Phil's not the climbing kind of tree.\" ";
    }
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "You pull out the knife and approach the ash tree. As you get close,
            the ash tree begins making a high-pitched sound. Then a large
            branch slams into your head. Dazed, you turn to see the oak branch
            which hit you swinging about for another blow, which you catch
            across the forehead.\b
            You fall down, tumbling head-first into a hospital bed. You gaze
            around in confusion, taking in the hospital room, empty of people
            except for you. Then the lump on your head starts hurting, and you
            begin thinking how nice it would be to sleep for a while, and soon
            you are.";
        die();
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.doCutWith(actor, dobj))
;

ash_laurel: clothingItem
    dippedInBlood = nil
    clothing_family = HAT
    autoTakeOff = nil
    stage = 3
    bulk = 7
    weight = 5
    noun = 'laurel' 'branch' 'crown' 'circle' 'circlet' 'wreath'
    adjective = 'ash'
    location = ash_tree_actor
    sdesc = "ash laurel"
    adesc = "an ash laurel"
    ldesc = {
        if (self.dippedInBlood)
            "Made of shiny ash, i";
        else "I";
        "t is just wide enough to fit your head. ";
    }
    pixiedesc = 'Dipped in the blood of another and worn, it will mask your
        sight from beasts.'
    putOnDesc = {
        if (self.dippedInBlood) {
            "You feel subtly different when you wear it. ";
            if (dog.location == uberloc(Me))
                "<<dog.capdesc>> cocks its head, then begins sniffing until <<
                    dog.thedesc>> locates you and is satisfied. ";
        }
        else pass putOnDesc;
    }
    takeOffDesc = {
        "You remove the ash laurel. ";
        if (Me.location == dragon.location) {
            "As you do so, the dragon's head swivels towards you. His beady
                eyes narrow as the realization that something is wrong slowly
                seeps through his brain. ";
            dragon.fryTerry;
        }
    }
    verIoTieTo(actor) = {}
    verDoDipIn(actor, io) = {}
;

bully: Actor
    daemonNumber = 1
    initials = 'RANDN'
    secondInitials = 'BRANDON'
    askDisambig = true
    selfDisambig = true
    stage = 3
    isHim = true

    noun = 'bully' 'boy' 'brandon'
    adjective = 'older'
    location = ne_forest
    sdesc = "older boy"
    stringsdesc = 'The older boy'
    thedesc = "the older boy"
    adesc = "an older boy"
    ldesc = "He lived (lives?)\ somewhere around here. You can remember the
        delight he took in tormenting you over the years. The three-year age
        difference was enough to give him the edge. "
    actorDesc = "There is an older boy here, carving his name in the oak tree. "
    pixiedesc = 'He\'s a stropping one, always stomping about with those
        great boots.'
    oaktreedesc = "The oak thrashes around. \"If I could lay a branch upside
        that thick head of his...\" "

    actorAction(v, d, p, i) = {
        if (v == helloVerb)
            "\"Shove off, squirt,\" he says. ";
        else "He ignores you. ";
        exit;
    }
    verGrab(item) = {
        if (item == pocketknife)
            "The boy rests the point of the knife on the middle of your
                chest. \"Want this?\" You step back; he laughs before turning
                again to the tree. ";
        else pass verGrab;
    }
    verDoKiss(actor) = {
        "The bully shoves you backwards. \"What's the matter with you?\"\ he
            asks, looking embarrassed. \"Freak!\" ";
    }
    verDoAskFor(actor, io) = {
        if (io.location != self)
            "He stops hacking on the oak for a moment to stare at you. ";
        else "\"Whatever,\" he says. ";
    }
    verIoGiveTo(actor) = {
        "He ignores you. ";
    }
    verDoAskAbout(actor) = {
        "\"I'm busy,\" he says, wood shavings falling at his feet. \"'less you
            want me to notice you.\" ";
    }
    verDoKick(actor) = {}
    doKick(actor) = {
        "Your kick";
        self.killMe;
    }
    verDoAttack(actor) = {}
    doAttack(actor) = {
        "Your wild punch";
        self.killMe;
    }
    verDoAttackWith(actor, io) = {}
    doAttackWith(actor, io) = {
        "Your wild attack";
        self.killMe;
    }
    verDoPush(actor) = {}
    doPush(actor) = {
        "Your awkward shove";
        self.killMe;
    }
    doSynonym('Push') = 'Pull' 'Move' 'Poke' 'Touch'

    daemon = {
        local locFlag = (self.location == Me.location),
              len1 = length(initials), len2 = length(secondInitials);

        if (self.location != oak_tree.location) {
            unnotify(self, &daemon);
            return;
        }
        if (locFlag) {
            "\b";
            switch (daemonNumber) {
                case 1:
                "The boy very carefully carves a large 'R' in the oak tree. ";
                break;

                case 2:
                "The boy hacks another initial in the oak tree. ";
                break;

                case 3:
                "Wielding his knife like a cleaver, the boy manages to carve
                    an 'N' in the oak tree. ";
                break;

                case 4:
                "Shavings fall from the oak tree as the boy carves a 'D' into
                    its trunk. ";
                break;

                case 5:
                "With a flourish, the boy finishes carving an 'N' in the oak
                    tree. He steps back to admire his handiwork. ";
                break;

                case 6:
                "The boy's eyes widen, and he mumbles to himself under his
                    breath. With several sweeps of the knife he tries to
                    obliterate his previous effort, then carve another 'B' in
                    the oak tree just below the first letters. ";
                break;

                case 7:
                "The boy carves an 'R' in the oak tree. ";
                break;

                case 8:
                "An 'A' joins the other letters on the oak tree. ";
                break;

                case 9:
                "The boy carves an 'N' next to the other letters he has already
                    carved. ";
                break;

                case 10:
                "The boy hacks out another 'D' on the oak tree. ";
                break;

                case 11:
                "Carefully, the boy adds an 'O' to the oak tree. He grins
                    smugly. ";
                break;

                case 12:
                "The boy finishes up his work with a few last stabs of his
                    knife. ";
                break;

                case 13:
                "The boy closes his knife and pockets it. Sticking his hands in
                    his pockets and whistling, he wanders off. ";
                self.moveInto(nil);
                unnotify(self, &daemon);
                return;
            }
        }
        if (daemonNumber > len1) {
            if (daemonNumber - len1 <= len2)
                oak_tree.secondInitials +=
                    substr(secondInitials, daemonNumber - len1, 1);
        }
        else oak_tree.initials += substr(initials, daemonNumber, 1);
        daemonNumber++;
    }
    killMe = {
        " catches him by surprise. He slips and nicks his finger with his
            knife.\b
            \"Stupid kid!\"\ he shouts, whirling around. A struggle ensues,
            with you taking the worse of it. At some point, as he is banging
            your head against the ground, his knife slides into your chest.
            Your vision, none too good after the beating you've endured, dims
            further. You feel the boy's knee lift from your stomach, then hear
            him running away.\b
            You turn your head, numbness spreading through your chest. The
            rough ground beneath your cheek smooths, becomes a pillow. You
            feel the sheets of a hospital bed enfold you before the numbness
            reaches your head.";
        die();
    }
;

pocketknife: item
    isopen = true
    drawnBlood = nil
    noun = 'knife' 'pocketknife'
    adjective = 'pocket'
    location = bully
    sdesc = "pocketknife"
    ldesc = {
        "It is a thin knife with only one blade, currently ";
        if (!isopen)
            "folded in the handle. ";
        else {
            "open. The blade has held its edge, despite its assault on the oak
                tree. ";
            if (drawnBlood)
                "The edge of the blade is red. ";
        }
    }
    verIoCutWith(actor) = {
        if (!isopen)
            "Not with the blade closed. ";
        else if (self.location != actor)
            "%You% %have% to hold it first. ";
    }
    ioCutWith(actor, dobj) = {
        dobj.doCutWith(actor, self);
    }
    ioSynonym('CutWith') = 'AttackWith'
    verDoOpen(actor) = {
        if (isopen)
            "The knife is already open. ";
        else if (self.location != actor)
            "%You% %have% to hold it first. ";
    }
    doOpen(actor) = {
        "You pull open the knife. ";
        isopen = true;
    }
    verDoClose(actor) = {
        if (!isopen)
            "The knife is already closed. ";
        else if (self.location != actor)
            "%You% %have% to hold it first. ";
    }
    doClose(actor) = {
        "You carefully close the blade. ";
        isopen = nil;
    }
;

my_blood_pool: fixedItem
    stage = 3
    noun = 'pool'
    adjective = 'blood' 'small'
    sdesc = "small pool of blood"
    ldesc = "It is the pool of blood you extracted from your finger. "
    heredesc = "On the ground is a small pool of blood. "
    takedesc = "All you would do is bloody your fingers again. "
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj != ash_laurel)
            "There's no need to dip <<dobj.thedesc>> in the blood. ";
        else
            "The blood flows greasily off of the laurel, none of it
                sticking. ";
    }
    ioSynonym('PutIn') = 'DipIn'
;

fathers_blood_pool: fixedItem
    stage = 3
    noun = 'pool'
    adjective = 'blood' 'large'
    sdesc = "large pool of blood"
    ldesc = "Blood from your father's hand. "
    heredesc = "The floor is stained with blood. "
    takedesc = "All you would do is bloody your fingers. "
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj != ash_laurel)
            "There's no need to dip <<dobj.thedesc>> in the blood. ";
        else {
            if (ash_laurel.isworn) "You take the laurel off your head and dip
                it in the pool. ";
            "The blood vanishes, absorbed by the laurel. For a brief instant,
                the laurel glows. ";
            if (ash_laurel.isworn)
                "As you put it back on your head, you feel oddly
                    different. ";
            ash_laurel.dippedInBlood = true;
            self.moveInto(nil);
            dragonSeeAh.solve;
        }
    }
    ioSynonym('PutIn') = 'DipIn'
;

sw_forest: forestRm
    ldesc = "Trees cluster thickly here in response to the additional water
        provided by a nearby stream. Mossy rocks lead down to the stream, and
        the underbrush allows passage to the north, east, and west. "
    exits = 'north, east, west, and down'
    north = nw_forest
    south = forest_stream
    east = se_forest
    west = west_forest
    down = self.south
;

sw_forest_stream: distantItem
    noun = 'stream'
    location = sw_forest
    sdesc = "stream"
    ldesc = "It lies a short distance to the south. You can occasionally
        feel its spray on your cheeks. "
;

sw_forest_mossy_rocks: decoration
    noun = 'rock' 'moss'
    plural = 'rocks'
    adjective = 'mossy'
    location = sw_forest
    sdesc = "mossy rocks"
    ldesc = "The rocks are green and furry, watered liberally by spray from the
        stream. "
;

se_forest: forestRm
    ldesc = "The forest growth pauses here, leaving room for a ring of
        mushrooms and toadstools. Due to the spacious arrangement of trees,
        paths exist north and west. "
    exits = 'north and west'
    north = ne_forest
    west = sw_forest
;

faerie_ring: fixedItem
    askDisambig = true
    stage = 3
    noun = 'ring' 'mushroom' 'toadstool' 'mushrooms' 'toadstools'
    adjective = 'mushroom' 'toadstool' 'mushrooms' 'toadstools' FAERIE
    location = se_forest
    sdesc = "ring of mushrooms"
    ldesc = {
        "The ring of mushrooms and toadstools is ragged in places, as if no
            longer cared for. ";
        if (solitary_toadstool.location == se_forest)
            "One toadstool in particular stands out from its brethren. ";
    }
    takedesc = "The strange symmetry of the ring gives you pause. "
    pixiedesc = "The pixie glances at the ring. \"'Twas our home for many a
        year. Now it is mine only.\" "
;

solitary_toadstool: fixedItem
    askDisambig = true
    stage = 3
    noun = 'toadstool'
    adjective = 'single' 'solitary' 'lone'
    location = se_forest
    sdesc = "solitary toadstool"
    ldesc = "It is the tallest of the fungi gathered here. Set in its side is
        a small door. "
    takedesc = "It resists your best efforts. "
    pixiedesc = '\'Tis my home.'
;

toadstool_door: fixedItem
    stage = 0
    noun = 'door'
    adjective = 'small'
    location = se_forest
    sdesc = "small door"
    ldesc = "The small door is painted a bright green and is closed. You are
        surprised that you never saw it before. "
    verDoOpen(actor) = { "It's locked. "; }
    verDoClose(actor) = { "It's already closed. "; }
    verDoLock(actor) = { "It's already locked. "; }
    verDoUnlock(actor) = {}
    doUnlock(actor) = { askio(withPrep); }
    verDoUnlockWith(actor, io) = { "\^<<io.thedesc>> doesn't fit. "; }
    verDoKnockon(actor) = {
        if (lonely_pixie.location == se_forest)
            "The pixie stares at you as you knock on the door. \"I am already
                here, now,\" he says. ";
        else if (global.turnsofar < lonely_pixie.turnWentIn + 8)
            "There is no answer. ";
    }
    doKnockon(actor) = {
        lonely_pixie.appear;
        toadstoolDoorAh.see;
    }
;

lonely_pixie: Actor
    selfDisambig = true
    askme = &pixiedesc
    turnWentIn = 0
    toldBanishment = 1

    appearNum = 1
    appear = {
        if (appearNum == 1) {
            "The door swings open, revealing a tiny pixie. He looks at your
                knees, then up, then further up. His eyes widen. \"You see
                me?\"\ he asks unnecessarily. He steps out, closing the door.
                \"A visitor! Well, an you can see me, let us visit whilst I
                clean my yard,\" he says, bustling about. \"Have you questions
                on the forest? I have been here for many whiles.\" Before
                you can answer, he begins scuffing dirt. ";
            appearNum++;
        }
        else "The pixie opens his door and comes out, beaming. \"Welcome
            back!\"\ he says, \"Welcome back!\" ";
        self.moveInto(se_forest);
        notify(self, &disappear, 12 + RAND(3));
        notify(self, &clean, 2 + RAND(2));
    }
    disappear = {
        if (Me.location == self.location) {
            "\b";
            if (RAND(100) < 30)
                "\"Your pardon, but I'm needed elsewhere in the forest,\"
                    the pixie says. He hunches over and turns into a hedgehog
                    before waddling off into the underbrush. ";
            else "The pixie walks to his toadstool and opens the door. \"I
                needs must work indoors for a time,\" he says by way of
                explanation before going inside. ";
        }
        unnotify(self, &clean);
        turnWentIn = global.turnsofar;
        self.moveInto(limbo);
    }
    clean = {
        if (Me.location == self.location) {
            "\b";
            switch(RAND(5)) {
                case 1:
                "The pixie polishes one of the toadstools, removing stray
                    debris. ";
                break;

                case 2:
                "The pixie rearranges some of the dirt in the middle of the
                    faerie ring. ";
                break;

                case 3:
                "The pixie clears twigs from around the toadstools. ";
                break;

                case 4:
                "The pixie swirls one of his hands, and a tiny cyclone carries
                    away some leaves. ";
                break;

                case 5:
                "The pixie wipes dirt from his door. ";
                break;
            }
        }
        notify(self, &clean, 2 + RAND(2));
    }

    isHim = true
    stage = 3
    noun = 'pixie' 'pisgie' 'piskie' 'pigsey' FAERIE
    adjective = 'banished' 'lonely'
    sdesc = "pixie"
    stringsdesc = 'The pixie'
    thedesc = "the pixie"
    adesc = "a pixie"
    ldesc = {
        "He is about twenty centimeters tall and rail-thin, with tufts of white
            hair sticking out from under a hat made of leaves. ";
    }
    actorDesc = "A pixie moves about the faerie ring, cleaning. "
    takedesc = "He slips from between your fingers. \"'t'isn't wise to capture
        a pixie!\"\ he says, eyes agleam with anger. You quickly draw back. "
    touchdesc = {
        "The pixie evades your clumsy grasp. \"This is how you repay my
            kindness?\"\ he asks you. His hand sweeps towards you, filling
            your eyes with a powder. When you can see again, he has vanished. ";
        self.moveInto(limbo);
        solitary_toadstool.moveInto(nil);
        toadstool_door.moveInto(nil);
    }
    oaktreedesc = 'Yeah, he comes by and talks to us sometimes.'
    pixiedesc = 'What you see is all I am...now.'
    disavow = "\"I've nowt to say of that,\" the pixie says. "
    alreadyTold = "\"Have I not already answered you that?\"\ he asks. "
    actorAction(v, d, p, i) = {
        if (v==tellVerb && d==Me && p==aboutPrep) {
            self.checkAskAbout(i); // See if we can ask about this object
            exit;
        }
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
        if (v == helloVerb)
            "The pixie bows, sweeping his cap from his head. \"An honor,\"\ he
                says. ";
        else "The pixie looks at you, a spark in his eyes. \"A command?\"\ he
            asks you. ";
        exit;
    }
    verDoAskFor(actor, io) = {
        "\"'Tis our kind what takes from you'rn,\" the pixie responds with a
            grin, \"and nowt t'other way round.\" ";
    }
    verIoGiveTo(actor) = {
        "The pixie shakes his head. \"I've no need for anything,\" he says. ";
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        dobj.ioAskAbout(actor, self);
    }
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "The pixie is much too fast for your clumsy swings. \"Cold iron?\"\ he
            asks softly. He spreads his hands and a blinding powder fills your
            eyes. When you can see again, he is gone. ";
        self.moveInto(limbo);
        solitary_toadstool.moveInto(nil);
        toadstool_door.moveInto(nil);
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.doCutWith(actor, dobj))
;

elf_boots: clothingItem
    askDisambig = true
    autoTakeOff = nil
    stage = 3
    noun = 'boot' 'boots'
    adjective = 'elf'
    sdesc = "elf boots"
    adesc = "a pair of elf boots"
    ldesc = "They are light and supple. "
    pixiedesc = "The pixie frowns. \"Did I not tell you about them when I
        gave them to you?\" "
    putOnDesc = "You pull the boots on, muffling your footsteps. "
    takeOffDesc = {
        "As you remove the boots, you hear your footsteps once more. ";
        if (Me.location == dragon.location) {
            "Unfortunately, so does the dragon. He cocks his head, revealing
                ear flaps, then turns towards you. ";
            dragon.fryTerry;
        }
    }
;

smell_word: conversationPiece
    noun = 'smell' 'scent'
    pixiedesc = {
        if (find(mason_jar.factTold, lonely_pixie) == nil) {
            "The pixie says, \"I shall withhold comment on your,\"
                he sniffs mightily, \"noticeable odor.\" ";
            return;
        }
        "The pixie claps a hand to his mouth, then grimaces. \"Smell! I forgot
            to tell how to mask your smell!\" A red flush creeps up his
            green-tinged face. \"Apologies. Find a stone rubbed smooth by a
            stream. When rubbed enough, the stone will release scent to mask
            your,\" he sniffs mightily, \"noticeable odor.\" ";
        magic_stone.factTold += lonely_pixie;
        dragonSmellAh.solve;
    }
;

forest_stream: room
    sdesc = "Stream"
    ldesc = "Water burbles past rocks worn smooth over time, running east to
        west. Across the stream the forest continues. Behind you a path leads
        up. "
    exits = 'up'
    north = sw_forest
    south = {
        "The stream is too wide and too deep to ford. ";
        return nil;
    }
    up = self.north
    swimAction = "It is much too cold for your tastes. "
;

fake_stream: fixedItem
    noun = 'water' 'stream'
    location = forest_stream
    sdesc = "stream"
    ldesc = "The water is shockingly clear, clearer than you had remembered. "
    takedesc = "You dip your hands in the cold water. The handfull of water
        you pull from the stream gleams softly before escaping your grasp. "
    verDoDrink(actor) = {
        "You bend down and take a sip of the water. It is cold enough to hurt
            your teeth. ";
    }
    verDoSwimin(actor) = { "It is much too cold for your tastes. "; }
;

magic_stone: complex
    askDisambig = true
    stage = 3
    heatStage = 1
    noun = 'rock' 'stone'
    adjective = 'shiny'
    location = forest_stream
    sdesc = "shiny stone"
    ldesc = "It shines gently, as if rubbed until it glowed. "
    hdesc = "One shiny stone in particular stands out from its brothers. "
    touchdesc = {
        "Your ";
        if (gloves.isworn) "gloved ";
        "fingers slide along it with ease over its ";
        switch (heatStage) {
            case 1:
                "cool";
                break;
            case 2:
                "warm";
                break;
            case 4:
                "painfully ";
            case 3:
                "hot";
                break;
        }
        " surface. ";
    }
    pixiedesc = {
        if (find(mason_jar.factTold, lonely_pixie) == nil) {
            "The pixie says, \"When rubbed enough, the stone will release
                scent to mask your,\" he sniffs mightily, \"noticeable
                odor.\" ";
            return;
        }
        "The pixie claps a hand to his mouth, then grimaces. \"Smell! I forgot
            to tell how to mask your smell!\" A red flush creeps up his
            green-tinged face. \"Apologies. When rubbed enough, the stone will
            release scent to mask your,\" he sniffs mightily, \"noticeable
            odor.\" ";
        smell_word.factTold += lonely_pixie;
        dragonSmellAh.solve;
    }
    verDoRub(actor) = {
        if (Me.smellMasked == true)
            "The stone turns rough in your hands and your fingers halt.
                Seconds later, the stone smooths again. ";
    }
    doRub(actor) = {
        "You rub your hand over the stone, feeling it warm in your grasp. ";
        if (++heatStage == 4) {
            Me.smellMasked = true;
            "A nearly-invisible cloud rises from the stone and settles about
                you, making you sneeze. ";
            notify(self, &removeSmell, 12);
        }
        unnotify(self, &coolDown);
        notify(self, &coolDown, 4);
    }
    coolDown = {
        if (--heatStage != 1)
            notify(self, &coolDown, 1);
    }
    removeSmell = {
        Me.smellMasked = nil;
        "\bA nearly-invisible cloud rises from you and disperses into the
            air. ";
        if (Me.location == dragon.location) {
            "The dragon sneezes, an impressive sight. Then he turns towards
                you, forked tongue flicking in and out rapidly. ";
            dragon.fryTerry;
        }
    }
;

stream_rocks: decoration
    stage = 3
    noun = 'rock' 'rocks'
    adjective = 'smooth'
    location = forest_stream
    sdesc = "rocks"
    ldesc = "The rocks have been rubbed smooth by the stream. "
;

forest_stream_path: decoration
    noun = 'path'
    location = forest_stream
    sdesc = "path"
    ldesc = "It leads back up the bank. "
;

west_forest: forestRm
    ldesc = "Trees stop to the west, forming a remarkably straight line,
        corralled by some feature of the land. To the east the trees thicken
        once again. "
    exits = 'east and west'
    east = sw_forest
    west = front_of_house
;

front_of_house: room
    goingOut = nil
    sdesc = "Front of House"
    ldesc = "You stand at the road in front of your house. The dirt road leads
        north and south, with no other houses visible for miles. On the east
        side of the road opposite your house, the forest looms. "
    exits = 'north, south, east, and west'
    listendesc = "You can hear music. "
    north = {
        goingOut = nil;
        return north_road;
    }
    south = {
        goingOut = nil;
        return south_road;
    }
    east = {
        goingOut = nil;
        return west_forest;
    }
    west = {
        goingOut = true;
        return inside_house;
    }
    firstseen = {
        "\bA breeze wanders along the road, carrying with it a hint of music. ";
        pass firstseen;
    }
    leaveRoom(actor) = {
        if (self.goingOut && rope.tiedTo == dog && rope.location == Me) {
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                refusing to budge. ";
            exit;
        }
        pass leaveRoom;
    }
;

fake_house: decoration
    stage = 3
    noun = 'house'
    location = front_of_house
    sdesc = "house"
    ldesc = "It is to the west. No doubt your father is waiting for you there. "
    verDoEnter(actor) = {
        if (rope.tiedTo == dog && rope.location == Me)
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                refusing to budge. ";
    }
    doEnter(actor) = { actor.travelTo(inside_house);}
;

front_of_house_dirt_road: decoration
    noun = 'road'
    adjective = 'dirt'
    location = front_of_house
    sdesc = "dirt road"
    ldesc = "It runs north to south. "
;

north_road: room
    walkNum = 0
    sdesc = "Dirt Road"
    ldesc = "A rural dirt road. Though no one has passed by in some time,
        a haze of dust still hangs in the air. "
    exits = 'north and south'
    north = {
        "You walk for a while, but the Baptist church you know is ahead never
            comes into view.\b";
        walkNum++;
        return north_road;
    }
    south = {
        if (walkNum != 0) {
            walkNum--;
            return north_road;
        }
        return front_of_house;
    }
;

south_road: room
    walkNum = 0
    sdesc = "Dirt Road"
    ldesc = "A rural dirt road. Though no one has passed by in some time,
        a haze of dust still hangs in the air. "
    exits = 'north and south'
    north = {
        if (walkNum != 0) {
            walkNum--;
            return south_road;
        }
        return front_of_house;
    }
    south = {
        "Your house moves further to the north, but you seem to make no
            progress.\b";
        walkNum++;
        return south_road;
    }
;

inside_house: droom, insideRm
    noDog = true
    sdesc = "Inside Your House"
    firstdesc = "Your home once held nothing but good memories; it was a place
        where you were happy, where you felt safe. But after Mom died you felt
        your life escaping your control. Now the very sight of the first floor
        entrance, its walls and stairs, the table by the entrance, gives you
        pause. "
    seconddesc = "The entranceway opens into the living room. Beside the door
        is a small table. A flight of warped wooden stairs, clinging to one
        wall, leads to the second floor. "
    exits = 'east'
    east = front_of_house
    west = {
        "You find yourself unable to walk further into your house. ";
        return nil;
    }
    out = front_of_house
    up = {
        "Knowing your father is up there, you are unable to set one foot on the
            stairs. ";
        return nil;
    }
    firstseen = {
        "\bYou hear heavy footsteps on the stairs and look up to see your
            father descending, an avatar of righteous wrath. \"Terry!\"\ he
            shouts. \"You stay right there!\"\b
            Then he is beside the stair, shaking you. \"I told you to stay in
            your room!\" ";
        young_father.checkTerryInv;
        "He stops, looks you over. \"I see you hiding something! What have you
            got in your hands?\" He stretches his hand out and waits. ";
        young_father.moveInto(self);
        notify(young_father, &waiting, 0);
        dadLeaveAh.see;
    }
    roomAction(a, v, d, p, i) = {
        if (v.isTravelVerb && young_father.location == self) {
            "Your father grabs your shoulder. \"Where do you think you're
                going?\"\ he asks you, shaking you slightly. ";
            exit;
        }
        pass roomAction;
    }
;

inside_house_door: decoration
    stage = 0
    noun = 'door'
    location = inside_house
    sdesc = "door"
    ldesc = "The door to the outside stands open, letting the excess heat of
        the house escape. "
    verDoOpen(actor) = { "It is already open. "; }
    verDoClose(actor) = {
        "Your father would punish you if he found that you had closed the
            door. ";
    }
    verDoKnockon(actor) = { "No one answers. "; }
;

inside_house_table: surface, fixedItem
    stage = 0
    noun = 'table'
    adjective = 'small'
    location = inside_house
    sdesc = "small table"
    ldesc = {
        local list = contlist(self);

        "A small table beside the door. ";
        if (length(list) > 0)
            "On the table you see <<listlist(list)>>. ";
    }
    verGrab(obj) = {
        if (young_father.location == self.location)
            "Your father grabs your wrist. \"Stop it!\"\ he snaps. ";
    }
;

karo_syrup_bottle: dthing, moveItem
    noun = 'bottle'
    adjective = 'glass' 'syrup' 'karo'
    location = inside_house_table
    sdesc = "bottle of Karo syrup"
    firstdesc = "The glass bottle is a familiar sight to you:\ Mom would give
        you a teaspoon of the thick Karo corn syrup whenever you were
        nauseated to settle your stomach. Since she died, your father has had
        to dose you with it at least once a week. He must have left it on
        the table after your latest bout. "
    seconddesc = "The bottle is labeled \"Dark Karo syrup.\" "
    smelldesc = { karo_syrup.smelldesc; }
    firstMove = { self.firstLdesc = nil; }
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (karo_syrup.location == self)
            "The bottom of the bottle is swamped with thick, dark Karo
                syrup. ";
        else "The bottle is empty. ";
    }
    doDrink -> karo_syrup
    verDoFill(actor) = { "With what do you wish to fill the bottle? "; }
    verDoFillWith(actor, io) = {
        "Mixing the syrup with <<io.thedesc>> would undoubtedly result in
            a nasty mess. ";
    }
;

karo_syrup: fixedItem
    sipped = nil
    noun = 'syrup'
    adjective = 'karo' 'dark'
    location = karo_syrup_bottle
    sdesc = "karo syrup"
    ldesc = "The dark syrup was your Mom's remedy for all manner of stomach
        aliments. "
    smelldesc = "It smells strongly of sugar. "
    takedesc = "Karo syrup is best kept in the bottle until used. "
    verDoPourOn(actor, io) = {
        "There's no need to pour the syrup on <<io.thedesc>>. ";
    }
/*    doPourOn(actor, io) = {
        "You pour the syrup onto the slide; it winds its thixotropic way
            down the aluminum until the entire slide is coated. ";
        io.syrupPoured = true;
        self.moveInto(nil);
    }*/
    doSynonym('PourOn') = 'PutOn'
    verDoDrink(actor) = {
        if (sipped)
            "You couldn't stomach another taste. ";
    }
    doDrink(actor) = {
        "You take a sip of the cloyingly sweet syrup. It creeps down your
            throat and coats your stomach. ";
        sipped = true;
    }
;

inside_house_stairs: decoration
    noun = 'stair' 'stairs'
    adjective = 'warped' 'wooden'
    location = inside_house
    sdesc = "wooden stairs"
    ldesc = "The old stairs, the ones in place when you and your parents moved
        in, were rotten. Your father tore them out and replaced them with
        these, which warped over the years. "
    verDoClimb(actor) = { inside_house.up; }
;

fathers_briefcase: decoration
    stage = 3
    noun = 'briefcase' 'coat'
    location = inside_house
    sdesc = "briefcase and coat"
    ldesc = "The coat puddles about the briefcase. Both belong to your father;
        every time you glance at them you see him in your memory. Few other
        things in the house have as strong a memory attached to them. "
    heredesc = "Leaning against the bottom stair is a briefcase and coat. "
;

young_father: Actor
    checkTerryInv = {
        if (length(contlist(Me)) == 0) {
            "He then marches you up the stairs, which begin to dissolve as you
                climb them. As they fade away they tilt, until you are lying
                on them. The last remnants of their stair-hood vanish, leaving
                you in a hospital bed. Then sleep claims you, a deep,
                dreamless sleep.";
            die();
        }
    }

    stage = 3
    turnsSinceGiven = 0
    askDisambig = true
    isHim = true
    noun = 'father' 'dad'
    adjective = 'young'
    sdesc = "father"
    thedesc = "your father"
    adesc = "your father"
    ldesc = "Your father towers above you, hand outstretched, glaring down at
        you. His face registers a mixture of anger, frustration, and concern. "
    actorDesc = "Your father stands beside the stairs. "
    takedesc = "Not likely. "
    touchdesc = "Your father slaps your hand away. \"Stop it!\"\ he snaps. "
    annoyance = "\"Terry! Do as I say!\"\ your father says. "
    actorAction(v, d, p, i) = {
        self.annoyance;
        exit;
    }
    verDoKiss(actor) = {
        "\"Don't think you can charm me that easily!\" ";
    }
    verDoTellAbout(actor, io) = {
        "Your father cuts you off. \"Give me your things now, Terry.\" ";
    }
    doSynonym('TellAbout') = 'AskFor'
    verDoAskAbout(actor) = { self.verDoTellAbout(actor, nil); }
    verIoShowTo(actor) = { self.verDoTellAbout(actor, nil); }
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "Your father grabs your hand. \"That is it!\"\ he shouts, backhanding
            you across the face. You stagger back, but not fast enough to
            avoid the second slap. Your head slams into the door jamb.\b
            You fall down, tumbling head-first into a hospital bed. You gaze
            around in confusion, taking in the hospital room, empty of people
            except for you. Then the lump on your head starts hurting, and you
            begin thinking about how nice it would be to sleep for a while, and
            soon you are.";
        die();
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.doCutWith(actor, dobj))
    verDoAttackWith(actor, io) = {}

    verIoGiveTo(actor) = {
        if (self.location != actor.location)
            "Your father isn't here. ";
    }
    ioGiveTo(actor, dobj) = {
        if (dobj != pocketknife || !pocketknife.isopen) {
            "You hand <<dobj.thedesc>> over to your father, who takes it,
                looks at it briefly, then places it on the table. ";
            dobj.moveInto(inside_house_table);
            self.checkTerryInv;
            turnsSinceGiven = 0;
            "\"Give me the rest,\" he snaps. ";
        }
        else {
            "Without a second thought, your father grabs the open pocketknife.
                \"Shit!\"\ he exclaims, dropping the knife. He grabs his hand,
                blood welling around his fingers. \"You stupid--\" He stops,
                a pained expression on his face. \"I can't--\" and then,
                \"Blood--\" Your father never could stand the sight of blood.
                He races up the stairs, yelling, \"Stay right there!\" ";
            dobj.moveInto(self.location);
            fathers_blood_pool.moveInto(self.location);
            pocketknife.drawnBlood = true;
            unnotify(self, &waiting);
            notify(homeMessages, &summonMessage, 2);
            dadLeaveAh.solve;
            self.moveInto(limbo);
        }
    }
    waiting = {
        switch (++turnsSinceGiven) {
            case 2:
                "\b\"Terry,\" your father says, sounding more and more angry. ";
                break;
            case 3:
                "\b\"What's in your hands?\"\ your father asks, shaking you
                    slightly. ";
                break;
            case 4:
                "\b\"You little shit,\" your father growls, backhanding you.
                    He draws back, mortified. \"Terry--I didn't mean--\"
                    But he is farther and farther away, as the slap
                    reverberates in your head, drowning out all else.\b
                    And then you are in a hospital bed, your head aching. No
                    one else is in the room. You blink several times before
                    a bone-deep tiredness catches up to you. You close your
                    eyes and sink into a dreamless sleep.";
                die();
        }
    }
;

dragons_hill: room
    floating_items = [fake_hill]
    goingOut = nil
    sdesc = "Hill"
    ldesc = "A small hill within the forest. A cave entrance opens in a rock
        outcropping to the east. Charred and trampled grass leads up to the
        cave. "
    exits = 'south and east'
    south = {
        goingOut = nil;
        return ne_forest;
    }
    east = {
        goingOut = true;
        return dragons_den;
    }
    climbHill = dragons_den
    leaveRoom(actor) = {
        if (self.goingOut && rope.tiedTo == dog && rope.location == Me) {
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                refusing to budge. ";
            exit;
        }
        pass leaveRoom;
    }
;

cave_entrance: fixedItem
    noun = 'entrance'
    adjective = 'cave'
    location = dragons_hill
    sdesc = "cave entrance"
    ldesc = "It leads into a cave. "
    verDoEnter(actor) = {
        if (rope.tiedTo == dog && rope.location == Me)
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                refusing to budge. ";
    }
    doEnter(actor) = {
        actor.travelTo(dragons_den);
    }
;

rock_outcropping: fixedItem
    noun = 'outcropping' 'rock' 'rocks'
    adjective = 'rock'
    location = dragons_hill
    sdesc = "rock outcropping"
    ldesc = "The outcropping juts from the side of the hill, as if it had
        forcefully pushed its way free of the protesting earth. "
    verDoClimb(actor) = {
        "You've climbed up it many times in the past. Today, however, you find
            yourself reluctant to brave its uncertain footing. ";
    }
;

charred_grass: decoration
    noun = 'grass'
    adjective = 'charred' 'trampled'
    location = dragons_hill
    sdesc = "grass"
    ldesc = "The grass leading to the cave entrance has been mashed flat and
        burned. "
;

dragons_den: room
    noDog = true
    sdesc = "Dragon's Den"
    ldesc = "The cave flares open into a large space. Most of the space is
        filled with dragon, tons and tons of dragon. The air is heavy with
        the smell of sulfur. "
    smelldesc = "The smell of sulfur is almost enough to set you to coughing. "
    exits = 'west'
    east = { "There is no way around the dragon. "; return nil; }
    west = dragons_hill
    out = dragons_hill
    enterRoom(actor) = {
        local flags;

        inherited.enterRoom(actor);
        flags = dragon.checkSenses;
        "\b";
        if (flags != 0) {
            if (flags & SEEN)
                "The dragon's head turns towards you. Its tiny eyes focus on
                    you, narrowing. ";
            else if (flags & SMELLED)
                "The dragon's tongue flicks out repeatedly. His head swings
                    about, finally zeroing in on you. ";
            else if (flags & HEARD)
                "The dragon's head cocks to one side, exposing tiny ear flaps.
                    Then his head snaps about, straight at you. ";
            dragon.fryTerry;
        }
        "The dragon shifts his head from side to side, tongue testing the
            air. After a minute he settles down. ";
        dragonFireNowAh.see;
    }
    roomAction(a, v, d, p, i) = {        // Catch verbs that make noise
        if (v == dropVerb || v == helloVerb || v == sayVerb || v == yellVerb
            || v == putVerb) {
            "The dragon notices the noise you make, and his head swings about
                until it points straight at you. ";
            dragon.fryTerry;
        }
        pass roomAction;
    }
;

dragon: Actor
    askDisambig = true
    checkSenses = {
        local flags;

        flags = 0;
        if (!ash_laurel.isworn || !ash_laurel.dippedInBlood)
            flags |= SEEN;
        if (!Me.smellMasked)
            flags |= SMELLED;
        if (!elf_boots.isworn)
            flags |= HEARD;
        return flags;
    }
    fryTerry = {
        "The dragon's snout opens, gases curling from it. You have a momentary
            glimpse of the back of the dragon's throat before all is erased
            in a roiling mass of fire. ";
        if (oak_staff.location == Me)
            "The fire splits to either side of you for a moment, but the staff
                cannot withstand such intense heat for long. It, too, bursts
                into flames. ";
        "You fall back, landing hard on the cave floor, but feel nothing other
            than the agony of flame.\b
            Then you are wrapped in coolness. You blink, discovering that you
            are lying in a hospital bed. No one else is in the room; only the
            sound of monitors keeps you company. An overwhelming tiredness
            swamps you then, and you fall into a dreamless sleep.";
        die();
    }
    produceFlame = {
        "The dragon spews fire all about the cave, though none of it directly
            at you. ";
        if (oak_staff.location != Me) {
            "Still, the heat is more than enough to overcome you. You fall to
                the cave floor in a faint.\b
                When you wake up, you find yourself in a hospital
                bed. Then you fall back into a dreamless sleep.";
            die();
        }
        "Occasionally a tongue of flame licks over you, but the oak staff
            is more than enough protection. ";
        dragonFireNowAh.solve;
        if (mason_jar.location == Me && !mason_jar.lightFilled) {
            "One tongue of flame caresses the mason jar, which swallows the
                flame and glows in response. ";
            mason_jar.lightFilled = true;
            moveAllCont(mason_jar, nil);
            top_of_hill.downOpen = true;
            faerie_cave.northOpen = true;
            faerie_cave.upOpen = true;
            faerie_king.moveInto(nil);
            faerie_queen.moveInto(nil);
            faerie_court.moveInto(nil);
            true_thomas.moveInto(nil);
            notify(homeMessages, &summonMessage, 2);
            dragonHearAh.solve;
            dragonSmellAh.solve;
            incscore(5);
        }
    }

    stage = 3
    isHim = true
    noun = 'dragon'
    location = dragons_den
    sdesc = "dragon"
    thedesc = "the dragon"
    adesc = "a dragon"
    pixiedesc = 'Be cautious of the dragon.'
    oaktreedesc = 'Now, don\'t you go messin\' with the dragon.'
    ldesc = "The dragon's bulk fills the cave. His head swings from side to
        side; occasionally a forked tongue flicks out, testing the air. "
    actorDesc = ""
    actorAction(v, d, p, i) = {
        "You realize your mistake as soon as you open your mouth. The dragon
            is not in a forgiving mood. He swings his head until it points
            directly at you. ";
        fryTerry;
    }
    verDoKiss(actor) = {
        "Stealthily you approach the dragon. You lean forward and kiss his
            snout, then leap back to avoid any flame.\bNone appears, however.
            The dragon looks around, blushing, before it settles down again. ";
    }
    verDoAttackWith(actor, io) = {}
    doAttackWith(actor, io) = {
        if (io == oak_staff)
            "You whirl the staff fiercely, summoning a buzz from the air
                around you. Before the dragon can locate you, you bring one
                end down on the tender part of his snout. He bellows, filling
                the cave with noxious gas. ";
        else "You disturb the dragon sufficiently for him to bellow, filling
            the cave with noxious gas. ";
        produceFlame;
    }
    verDoAskFor(actor, io) = {}
    doAskFor(actor, io) = { self.actorAction(nil, nil, nil, nil); }
    verDoAskAbout(actor) = {}
    doAskAbout(actor, io) = { self.actorAction(nil, nil, nil, nil); }
    verIoGiveTo(actor) = {
        "That would not be wise. ";
    }
    verIoShowTo(actor) = {
        "The dragon cannot see you. ";
    }
    verDoKick(actor) = {}
    doKick(actor) = {
        "You creep forward, then give the dragon a solid kick before skipping
            backwards.  He bellows, filling the cave with noxious gas. ";
        produceFlame;
    }
    verDoPoke(actor) = {}
    doPoke(actor) = {
        "You creep forward and poke the dragon hard before skipping backwards.
            He bellows, filling the cave with noxious gas. ";
        produceFlame;
    }
    doSynonym('Poke') = 'Touch' 'Push' 'Pet' 'Squeeze' 'Attack' 'Rub'
    ioThrowAt(actor, dobj) = {
        "\^<<dobj.thedesc>> sails towards the dragon, bouncing off dull
            scales. His head whips around; his snout wrinkles back. ";
        dobj.moveInto(self.location);
        produceFlame;
    }
    verDoCutWith(actor, io) = {}
    doCutWith(actor, io) = {
        "You dash forward and scratch the dragon's hide with <<io.thedesc
            >> before skipping backwards. He bellows, filling the cave with
            noxious gas. ";
        produceFlame;
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.doCutWith(actor, dobj))
;

// The object which keeps track of messages from outside
homeMessages: object
    messageNum = 1
    summonMessage = {
        switch (messageNum) {
            case 1:
            nurseMessage.setup(nil);
            "\bA section of the air just above your head shimmers. A small
                pyramid falls from the disturbance to the ground below. ";
            nurseMessage.moveInto(Me.location);
            break;

            case 2:
            doctorMessage.setup(nil);
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


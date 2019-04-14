/*
    Recovery, part one of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: recovery.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

rollAvalanche: function;
withdrawal: function;

class mudroom: room
    floating_items = [ground_mud, rain]
    exits = 'in any compass direction'
    north = { return self.allexit; }
    south = { return self.allexit; }
    east = { return self.allexit; }
    west = { return self.allexit; }
    ne = { return self.allexit; }
    nw = { return self.allexit; }
    se = { return self.allexit; }
    sw = { return self.allexit; }
    listendesc = "You hear the sound of rain slapping muddy ground."
;

ground_mud: wallpaper
    sdesc = "mud"
    noun = 'mud'
    adjective = 'brown'
    ldesc = "The viscous brown substance uniformly covers the ground. "
    takedesc = "Your attempts result in dirty hands and no appreciable amount
        of mud. "
    verDoDig(actor) = {}
    doDig(actor) = {
        if (conscience.location == actor.location)
            conscience.doDig(actor);
        else "You kneel down and dig for a time, accomplishing nothing. ";
    }
    verDoClean(actor) = { "Impossible, not to mention useless. "; }
;

rain: wallpaper, decoration
    sdesc = "rain"
    noun = 'rain'
    ldesc = "Slanting down in sheets, it soaks you to the bone. "
    verDoDrink(actor) = {
        "You tilt your head back, allowing it to run down your throat. A brief
            taste of silt causes you to choke, spitting up what little you had
            caught in your mouth. ";
    }
    takedesc = "As soon capture the air. "
    touchdesc = "It pelts down in fat drops, splashing on your hand. "
    verIoAskAbout(actor, dobj) = {}
;

startroom: mudroom
    sdesc = "Muddy Glade"
    ldesc = "The trees around you are spaced far enough to provide little
        shelter, allowing the stinging rain to pelt you. A grey mist conceals
        everything past four meters. "
    allexit = {
        "You strike off in that direction, but soon become disoriented
            by the rain.\b";
        Me.stumbleTurns++;
        if (Me.stumbleTurns > 6)
            return muddy_front_of_bldg;
        return muddy_field;
    }
;

muddy_trees: decoration
    stage = 1
    isThem = true
    sdesc = "trees"
    noun = 'tree'
    plural = 'trees'
    location = startroom
    ldesc = "Mostly pine. Their protection is scant comfort in the rain and
        the wind. "
    verDoClimb(actor) = "Their rain-slicked trunks offer no purchase. "
;

mist: decoration
    stage = 1            // Tells which stage the object came from
    noun = 'mist'
    adjective = 'grey' 'gray'
    location = startroom
    sdesc = "mist"
    ldesc = "Its shifting form obscures most details of the world around you. "
    verDoLookthru(actor) = {
        "If there is anything beyond the mist, you cannot see it. ";
    }
;

muddy_field: mudroom
    sdesc = "Muddy Field"
    ldesc = "Once the field might have been covered in grass. Now the grass is
        but a memory. Mud covers the ground in its place, fed by the constant
        rain. "
    firstseen = {
        manClueAh.see;
    }
    allexit = {
        if (conscience.location == Me.location) {
            if (conscience.sayingsNum == 0)    // The head's done
                "\"Good luck,\" the man whispers as you walk away. The
                    hiss of the rain covers anything else he might have
                    said.\b";
            else "As you walk away, the head screams at you. \"Coward!
                You put me here! Can't you watch my last minutes?\"
                Disturbed, you keep walking.\b";
            conscience.moveInto(nil);
        }
        else "You strike off in that direction, but soon become disoriented by
            the rain.\b";
        Me.stumbleTurns++;
        if (Me.stumbleTurns > 6)
            return muddy_front_of_bldg;
        return startroom;
    }
    ne = { self.allexit; return muddy_front_of_bldg; }
;

conscience: Actor
    stage = 1
    selfDisambig = true   // See griph.t for details
    isHim = true
    pulled = nil
    pushed = nil
    noun = 'head' 'man' 'conscience'
    adjective = 'human'
    location = muddy_field
    sayingsNum = 1
    actorDesc = "Buried almost to its chin in the mud is a human head. "
    sdesc = "human head"
    stringsdesc = 'The human head'
    thedesc = "the human head"
    adesc = "a human head"
    ldesc = "Other than being buried in mud to his chin, the head is
        reassuringly normal. His hair and mustache are a matted brown,
        perhaps from genetics, perhaps from mud. Rivulets of water run
        down his creased face. "
    takedesc = "You grab hold of his ears, but before you can pull, the
        head says, \"It's no good now. I'm done for.\" His eyes narrow at
        you. \"The least you can do is feel guilty.\" "
    disavow = "\"Few things give me more pleasure than to be unable to
        answer you.\" "
    alreadyTold = "\"Can't you fill my final moments with more than repetitive
        questions?\" "
    verDoPet(actor) = {
        "His hair is too matted for you to run your fingers through. ";
    }
    verDoKick(actor) = {}
    doKick(actor) = {
        "The head's eyes widen as you draw your foot back. \"Terry, no, please,
            oh God you can't--\" His cries are cut short as your foot slams
            into him. With the sound of eggshells cracking, the head fragments
            into countless pieces which are quickly lost in the mud. ";
        self.moveInto(nil);
    }
    verDoPull(actor) = {
        if (self.pulled)
            "You couldn't stand to try again. ";
    }
    doPull(actor) = {
        self.pulled = true;
        "You lean over him, place your hands over his ears, and pull. He
            shrieks in pain, eyes squeezed shut. You quickly determine that he
            cannot be pulled free of the mud. When you let go the man's ears
            are bright red. ";
    }
    verDoPush(actor) = {
        if (self.pushed)
            "You couldn't stand to try again. ";
    }
    doPush(actor) = {
        self.pushed = true;
        "You lean over him, place your hands on his forehead, and push.
            Hard. He screams, eyes squeezed shut, as you bear down on his
            head. When you stop you see that you have left a fiery red
            handprint on his forehead which is slow to fade. ";
    }
    doSynonym('Kick') = 'Attack'
    verDoKiss(actor) = { "The mud coating him makes you think twice. "; }
    verDoDig(actor) = {}
    doDig(actor) = {
        "You kneel and begin scooping mud from around the head
            with both hands. As fast as you remove the mud, more mud and
            water return. \"Forget it,\" the man says gruffly. \"It's
            too late now.\" He seems strangely touched by your attempt,
            however. ";
    }
    verDoGloat(actor) = {}
    doGloat(actor) = {
        "You laugh nastily at the man. He grimaces. \"I should have known,\"
            he says, sinking faster into the mud. \"I should have--\" Then he
            is gone. ";
        self.moveInto(nil);
    }
    verDoClean(actor) = {}
    doClean(actor) = {
        "No matter how much you wipe, the man's face is still begrimed. He
            grimaces. \"Thanks,\" he says. ";
    }
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "\"Why, Terry,\" he says, eyes widening in mock surprise, \"I
                never expected you to visit!\" ";
        }
        else "\"Strangely enough,\" he says, \"I don't feel all that inclined
            to do anything for you.\" ";
        exit;
    }
    wantheartbeat = { return (Me.location == self.location) &&
        self.sayingsNum; }
    heartbeat = {
        local sayings = ['The head\'s eyes suddenly open, fixing you in
            place. "Oh, my," he says. "This is a surprise. I
            certainly never expected to see you in person!"',
            '"Come to gloat?"\ the man says. "Why not? After all, you put
            me here."',
            '"That\'s right, try to deny it.  If it weren\'t for you,
            I\'d still be safe." His eyes dart to the northeast
            for a second, then return to you.',
            'The man laughs softly. "Not long now." He grins
            sarcastically. "An interesting end, don\'t you think? Jiminy
            Cricket never had such an exit scene."',
            'Resignation and more than a little bitterness fill the man\'s
            face. "Go on," he says. "You\'ve work to do, pieces to recover."
            He pauses, then yells, "Go on, I said!" Then, muttered, \"You\'ve
            ignored me too long to do anything about it now."'];

        "\b<<sayings[self.sayingsNum]>>\n";
        self.sayingsNum++;
        if (self.sayingsNum > length(sayings))
            self.sayingsNum = 0;
    }
    askWord(word, wordList) = {
        if (word == 'me') {
            "The man laughs. \"Funny, I've spent my life judging you, and now
                I can't think of a thing to say about you.\" ";
            return true;
        }
        if (word == 'head' || word == 'himself' || word == 'man') {
            "\"What's to say?\"\ he asks. \"I've led a dull life, and now I'm
                about to have a dull end.\" ";
            return true;
        }
        if (word == 'northeast' || word == 'ne') {
            "\"My services were no longer needed in the hall, so I was turned
                out in this rain,\" the man spits out. ";
            return true;
        }
        if (word == 'northwest' || word == 'nw') {
            self.disavow;
            return true;
        }
        if (word == 'end' || word == 'exit' || word == 'scene') {
            "\"I had no idea I'd get to speak to you once more before I
                drowned.\" ";
            return true;
        }
        if (word == 'hall') {
            "The man grimaces. \"You\'ll see.\" ";
            return true;
        }
        if (word == 'work' || word == 'pieces') {
            "\"Well, now,\" he says, \"If I were to tell you, that'd take the
                sport out of it.\" ";
            return true;
        }
        if (word == 'rain' || word == 'mud') {
            "He says, \"If only the rain would stop...\" ";
            return true;
        }
        return nil;
    }
;

conscience_words: conversationPiece
    stage = 1
    askDisambig = true
    noun = 'northeast' 'ne' 'end' 'exit' 'scene' 'work' 'himself' 'northwest' 'nw'
;

muddy_front_of_bldg: mudroom, droom
    sdesc = "Front of Building"
    firstdesc = "Looming suddenly out of the gloom is a large marble building.
        Its columns jut skyward, raked by the unending rain. To the north
        lies its entrance. "
    seconddesc = "In front of you a large marble building looms.
        Its columns jut skyward, raked by the unending rain. To the north
        lies its entrance. "
    allexit = {
        "As you walk away, the building is quickly swallowed by the rain and
            mist.\b";
        Me.stumbleTurns = 0;
        return muddy_field;
    }
    north = {
        "As you walk through the door of the building the sound of the rain
            stops, as if suddenly turned off.\b";
        frankie.askDisambig = true;
        beginningAh.solve;
        return foyer;
    }
    in = { return self.north; }
;

muddy_building: decoration
    stage = 1
    sdesc = "building"
    noun = 'building' 'column'
    plural = 'columns'
    adjective = 'marble'
    location = muddy_front_of_bldg
    ldesc = "The building's white marble is streaked with grime, the rain
        having no visible effect. Its entrance lies open to the north. "
    verDoEnter(actor) = {}
    doEnter(actor) = {
        actor.location.north;
        actor.travelTo(foyer);
    }
;

entrance: decoration
    stage = 1
    sdesc = "entrance"
    noun = 'entrance'
    location = muddy_front_of_bldg
    ldesc = "The entrance to the building is to the north. "
    doEnter -> muddy_building
    verDoLookthru(actor) = { "Shadows obscure your glimpse into the building. "; }
;

foyer: insideRm
    goingOut = nil        // Is the actor going out i.e. south?
    enterNum = 0          // Number of times entered
    contentsReachable = {
        if (Me.location == balcony) return nil;
        return true;
    }
    sdesc = "Foyer"
    ldesc = "The two-story height of the foyer is channelled into a narrower
        hallway to the north. On the north wall to the west of the hallway's
        beginning is an open doorway. The building's entrance to the south
        is reflected in the marble floor. "
    floordesc = {
        if (muddy_footprints.location == self)
            "The reflections on the floor are obscured by muddy footprints. ";
        else if (muddy_smear.location == self)
            "A smear of mud dulls the floor. ";
        else "The floor reflects your surroundings:\ the entrance, the hallway
            to the north, the northwest doorway. ";
    }
    exits = 'north, south, and northwest'
    moveMud = {
        if (muddy_footprints.location == nil && muddy_smear.location == nil) {
            muddy_footprints.moveInto(self);
            return true;
        }
        return nil;
    }
    north = {
        self.goingOut = nil;
        if (self.moveMud)
            muddy_footprints.direction = 'to the north';
        return south_hallway;
    }
    south = {
        self.goingOut = true;
        if (self.moveMud)
            muddy_footprints.direction = 'back outside';
        return snowy_front_of_bldg;
    }
    nw = {
        self.goingOut = nil;
        if (self.moveMud)
            muddy_footprints.direction = 'through the northwest doorway';
        return clerk_office;
    }
    out = { return self.south; }
    enterRoom(actor) = {
        snowDaemon.mentionCoat = 0;
        inherited.enterRoom(actor);
        if (dog.isWaiting && dog.location == self) {
            "\b<<dog.capdesc>> sees you and jumps up, barking loudly at your
                return. ";
            dog.clearProps;
            dog.wantheartbeat = true;
        }
        self.enterNum++;            // 2nd time player enters foyer,
        if (self.enterNum == 2) {   //  send nurse's message
            nurseMessage.setup('Doctor! Doctor! Something\'s wrong with Terry!');
            "\bA section of the air just above your head shimmers. A small
                pyramid falls from the disturbance to the ground below. ";
            nurseMessage.moveInto(self);
        }
    }
    leaveRoom(actor) = {
        if (self.goingOut && rope.tiedTo == dog && rope.location == Me) {
            "<<dog.capdesc>> plants all four feet on the ground and
                resists being taken outside. No matter how hard you pull,
                <<dog.thedesc>> doesn't move. ";
            exit;
        }
        inherited.leaveRoom(actor);
        if (actor != Me || !self.goingOut || dog.location != self)
            return;
        "<<dog.capdesc>> ";
        if (!coat.isworn || coat.tuftNumber != 3)
            "begins barking at you fiercely, dancing in front of you and
                impeding your progress. You nearly have to jump over <<
                dog.thedesc>> to get past, at which point it lies on the floor,
                staring mournfully at you as you leave. ";
        else if (rucksack.location == Me)
            "begins barking at your rucksack, leaping off
                the ground in an effort to grab hold of it before you leave.
                Your momentum, however, carries you out the door before <<
                dog.thedesc>> is successful.";
        else {
            "lies down on the floor, waiting for you to return. ";
            if (rucksack.location == dog)
                "It places its paws protectively over the rucksack it is
                    guarding.";
        }
        "\b";
        dog.wantheartbeat = nil;
        dog.clearProps;
        dog.isWaiting = true;
    }
;

muddy_footprints: decoration
    isThem = true
    isListed = true
    has_hdesc = true
    direction = ''
    noun = 'footprint' 'mud' 'print'
    plural = 'footprints' 'prints'
    adjective = 'muddy'
    sdesc = "muddy footprints"
    ldesc = "The footprints mill about the south entrance, then
        lead <<self.direction>>. "
    hdesc = "Tracked across the marble floor are muddy footprints. "
    verDoClean(actor) = {}
    doClean(actor) = {
        "You scrub the footprints into a nasty smear. ";
        self.moveInto(nil);
        muddy_smear.moveInto(foyer);
    }
;

muddy_smear: decoration
    isListed = true
    has_hdesc = true
    noun = 'smear' 'mud'
    adjective = 'muddy'
    sdesc = "muddy smear"
    ldesc = "The smear leads <<muddy_footprints.direction>> from the entrance. "
    hdesc = "Streaked across the marble floor is a muddy smear. "
    verDoClean(actor) = { "Your scrubbing has no more effect on the mud. "; }
;

foyer_doorway: myDoorway
    location = foyer
    ldesc = "It is on the northwest wall. "
    lookthrudesc = "The room beyond is in shadow. "
    doordest = clerk_office
;

// If there is power and the switch is turned on, lightsOn is set to true in
//  the room in which the lightswitch is located
class lightswitch: switchItem    // All the lightswitches
    stage = 1
    noun = 'switch'
    adjective = 'light'
    plural = 'switches'
    sdesc = "light switch"
    ldesc = "The switch is currently <<self.wordDesc>>. "
    doSwitch(actor) = {
        if (!self.isActive) self.doTurnon(actor);
        else self.doTurnoff(actor);
    }
    doTurnon(actor) = {
        self.isActive = true;
        if (breaker_box.hasPower(self.location.breakerNum)) {
            self.location.lightsOn = true;
            "The room's lights turn on in response. ";
        }
        else {
            "You turn on the switch, but nothing happens. ";
            self.location.lightsOn = nil;
        }
    }
    doTurnoff(actor) = {
        self.isActive = nil;
        self.location.lightsOn = nil;
        if (breaker_box.hasPower(self.location.breakerNum))
            "The room's lights turn off. ";
        else "Okay, it's now turned off. ";
    }
    doSynonym('Switch') = 'Flip'
    evalSwitch(power) = {    // See if we should turn the lights on
        if (power && self.isActive)
            self.location.lightsOn = true;
        else self.location.lightsOn = nil;
    }
;

class ceiling_lights: distantItem
    stage = 1
    isThem = true
    noun = 'light'
    plural = 'lights'
    adjective = 'ceiling'
    sdesc = "ceiling lights"
    ldesc = {
        if (self.location.lightsOn)
            "They glow softly, illuminating the room. ";
        else "They are cold and dark. ";
    }
    verDoTurnon(actor) = { self.mySwitch.verDoTurnon(actor); }
    doTurnon(actor) = { self.mySwitch.doTurnon(actor); }
    verDoTurnoff(actor) = { self.mySwitch.verDoTurnoff(actor); }
    doTurnoff(actor) = { self.mySwitch.doTurnoff(actor); }
    verDoSwitch(actor) = { self.mySwitch.verDoSwitch(actor); }
    doSwitch(actor) = { self.mySwitch.doSwitch(actor); }
    doSynonym('Switch') = 'Flip' 'Throw'
;

class wall_clock: fixedItem
    stage = 1
    timeOfDeath = ''
    noun = 'clock'
    plural = 'clocks'
    sdesc = "clock"
    ldesc = {
        "A white-faced clock with numbers and black hands, hands which ";
        if (breaker_box.hasPower(self.location.breakerNum))
            "turn slowly, ticking off seconds, minutes, hours.";
        else "stand frozen at <<self.timeOfDeath>>. ";
    }
;

clerk_office: insideRm
    breakerNum = 1
    sdesc = "Cramped Office"
    ldesc = {
        "Shadows crowd the room, ";
        if (self.lightsOn)
            "barely dimmed by the lit";
        else "strengthened by the unlit";
        " ceiling light which is canted at a strange angle. A scarred mahogany
            desk is crammed into one corner of the room, facing the doorway and
            the clock above it. The room is small enough that the light switch
            beside the door is within arms reach of the desk. ";
    }
    exits = 'southeast'
    south = foyer
    se = foyer
    out = foyer
;

office_light: fixedItem
    stage = 1
    noun = 'light' 'lamp'
    adjective = 'ceiling'
    location = clerk_office
    sdesc = "ceiling light"
    ldesc = {
        "It is tilted at an angle, as if someone once tried to pull it down.
            It vibrates in time to some unheard syncopated beat";
        if (self.location.lightsOn)
            ", sending shards of light dancing on the floor";
        ". ";
    }
    takedesc = {
        if (Me.location != mahogany_desk)
            "It's too far away. ";
        else "Despite its precarious-looking hold on the ceiling, you are
            unable to tear it down. ";
    }
    touchdesc = "When you place your hands on it, you can feel the entire
        building shuddering. "
    verDoTurnon(actor) = { office_switch.verDoTurnon(actor); }
    doTurnon(actor) = { office_switch.doTurnon(actor); }
    verDoTurnoff(actor) = { office_switch.verDoTurnoff(actor); }
    doTurnoff(actor) = { office_switch.doTurnoff(actor); }
    verDoSwitch(actor) = { office_switch.verDoSwitch(actor); }
    doSwitch(actor) = { office_switch.doSwitch(actor); }
    doSynonym('Switch') = 'Flip' 'Throw'
    verDoPush(actor) = {
        if (actor.location != mahogany_desk)
            "It's too far away. ";
    }
    verDoTouch(actor) = {
        if (actor.location != mahogany_desk)
            "It's too far away. ";
    }
    doPush(actor) = {
        "Your attempt to straighten it is fruitless. It immediately cants
            off true once more. ";
    }
    verDoPull(actor) = (self.verDoPush(actor))
    doPull(actor) = (self.takedesc)
;

office_switch: lightswitch
    location = clerk_office
;

office_clock: wall_clock
    location = clerk_office
    timeOfDeath = '2:59'
;

office_shadows: decoration
    noun = 'shadow' 'shadows'
    location = clerk_office
    sdesc = "shadows"
    ldesc = "They fill the room. Opaque...no shadows should be so thick. "
    verDoEnter(actor) = {
        "I believe you have a different game in mind. ";
    }
;

clerk_doorway: myDoorway
    location = clerk_office
    ldesc = "It leads south. "
    lookthrudesc = "You can see part of the foyer. "
    doordest = foyer
;

mahogany_desk: fixedItem, platformItem
    reachable = [ office_light, office_switch, mahogany_desk ]
    noun = 'desk'
    plural = 'desks'
    adjective = 'mahogany' 'scarred'
    location = clerk_office
    sdesc = "mahogany desk"
    ldesc = "The dark wood of the desk only serves to make the office more
        claustrophobic. Deep gouges run from the front of the desk to the back;
        close examination shows them to be fingernail-shaped. All of the desk
        drawers have been removed. "
    touchdesc = "The gouges are spaced perfectly for your fingers. "
    verDoSiton(actor) = { "There is no need. "; }
    verDoStandon(actor) = {
        if (actor.location == self)
            "%You're% already on the desk. ";
    }
    doStandon(actor) =
    {
        "Okay, %you're% now standing on the desk. ";
        actor.travelTo( self );
    }
    doSynonym('Standon') = 'Climb' 'Board'
    down = (self.location)
    out = (self.location)
;

mahogany_desk_gouges: decoration
    noun = 'gouge' 'gouges' 'groove' 'grooves'
    location = clerk_office
    sdesc = "gouges"
    ldesc = "Gouges scar the once-pristine surface of the desk. "
    touchdesc = {
        if (gloves.isworn)
            "Even in the gloves y";
        else "Y";
        "our fingers fit neatly in the gouges. ";
    }
    verDoTouch(actor) = {}
;

fake_walkway: wallpaper, decoration
    noun = 'walkway'
    sdesc = "walkway"
    ldesc = "The walkway rings the hall on every side but the south, casting
        a shadow on the floor. "
;

walkway_shadow: wallpaper, decoration
    noun = 'shadow'
    sdesc = "shadow"
    ldesc = "It is cast by the walkway above. Opaque...no shadow should be
        so thick. "
    verDoEnter(actor) = {
        "I believe you have a different game in mind. ";
    }
;

south_hallway: insideRm
    floating_items = [ fake_walkway, walkway_shadow ]
    location = {          // So its contents are visible from the walkways
        if (Me.location.sHallFlag)
            return true;
        return nil;
    }
    isListed = nil        // So it's not mentioned in the walkways
    isUber = true         // For the uberloc() routine--see funcs.t
    sdesc = "South End of Hallway"
    ldesc = "Like the foyer, the hallway is marble. Its two-story height
        combined with its thinness inspires unease. A walkway runs above you,
        clinging to the east and west walls. Below the east walkway is a
        doorway. "
    exits = 'north, south, and east'
    east = south_archive
    north = north_hallway
    south = foyer
;

fake_south_hallway: wallpaper
    noun = 'hallway' 'hall'
    contentsReachable = nil
    sdesc = "hallway"
    ldesc = {
        local conts;

        "The marble floor is dimmed by the leaden light from outside. ";
        if (length(conts = contlist(south_hallway)) > 0)
            "Lying in the hallway you see <<listlist(conts)>>. ";
    }
;

south_hallway_doorway: myDoorway
    location = south_hallway
    ldesc = "The doorway is on the east wall. "
    lookthrudesc = "You can see boxes in the room beyond the doorway. "
    doordest = south_archive
;

large_audience_doors: wallpaper, decoration
    stage = 1
    isThem = true
    noun = 'door'
    plural = 'doors'
    adjective = 'large' 'wooden' 'oak' 'carved'
    sdesc = "large wooden doors"
    ldesc = "The carved doors are made of oak and are twice your height.
        They stand slightly ajar, leaving enough room for you to enter."
    touchdesc = {
        "You run your ";
        if (gloves.isworn) "gloved ";
        "hands over the carving. ";
        if (!gloves.isworn)
            "Almost you can tell what the carving is of. ";
    }
    verDoKnockon(actor) = { "Your knock reverberates, but no one answers. "; }
    verDoOpen(actor) = { "The doors have frozen in position over time. You
        cannot budge them. "; }
    verDoTouch(actor) = {}
    doSynonym('Open') = 'Close' 'Move'
    verDoEnter(actor) = {}
    doEnter(actor) = {
        if (actor.location == foyer)
            actor.travelTo(foyer.west);
        else actor.travelTo(audience_hall.east);
    }
;

door_carving: wallpaper, decoration
    stage = 1
    noun = 'carving' 'carvings'
    sdesc = "carving"
    ldesc = "You peer closely at the door, but are unable to tell what the
        carving is of in the dim light. "
    touchdesc = {
        if (gloves.isworn)
            "You can feel nothing through the gloves. ";
        else "The carving is distinct beneath your fingers, yet its subject
            remains tantalizingly unobvious. ";
    }
    verDoTouch(actor) = {}
;

north_hallway: insideRm, floatingItem
    floating_items = [ fake_walkway, walkway_shadow, large_audience_doors,
        door_carving, ne_staircase, nw_staircase ]
    location = {          // So its contents are visible from the walkways
        if (Me.location.nHallFlag)
            return Me.location;
        return nil;
    }
    isListed = nil        // So it's not mentioned in the walkways
    isUber = true         // For the uberloc() routine--see funcs.t
    contentsReachable = { // More balcony fun--so you can't manipulate items
        return (Me.location == self);    //  in the hall
    }
    sdesc = "North End of Hallway"
    ldesc = "The hallway ends abruptly in a pair of large oak doors. Their
        intricate carving is barely visible in the leaden light from the
        windows above you. The doors are flanked by two sweeping staircases
        to the northeast and northwest. A doorway to the east is mirrored by
        <<utility_door1.aWordDesc>> door to the west. "
    exits = 'north, south, east, west, northeast, and northwest'
    north = audience_hall
    south = south_hallway
    east = north_archive
    west = utility_door1
    ne = {
        if (fatherMessage.location != nil)
            fatherMessage.upStairs = true;
        return ne_walkway;
    }
    nw = {
        if (fatherMessage.location != nil)
            fatherMessage.upStairs = true;
        return nw_walkway;
    }
    up = {
        "You can go up to the northeast or to the northwest. ";
        return nil;
    }
;

fake_north_hallway: wallpaper
    noun = 'hallway' 'hall'
    contentsReachable = nil
    sdesc = "hallway"
    ldesc = {
        local conts;

        "The marble floor is dimmed by the leaden light from outside. ";
        if (length(conts = contlist(north_hallway)) > 0)
            "Lying in the hallway you see <<listlist(conts)>>. ";
    }
;

hallway_windows: distantItem
    isThem = true
    noun = 'window'
    plural = 'windows'
    location = north_hallway
    sdesc = "windows"
    ldesc = "The narrow windows are set just below the ceiling. Grey light
        from outside spills through them. "
    verDoLookthru(actor) = {}
    doLookthru(actor) = { "You can see a grey sky filled with clouds. "; }
;

ne_staircase: wallpaper, decoration
    stage = 1
    noun = 'staircase' 'stair' 'stairs'
    adjective = 'sweeping' 'northeast' 'ne'
    plural = 'staircases'
    sdesc = "northeast staircase"
    ldesc = {
        "The staircase curves as it ";
        if (Me.location == north_hallway) "climbs";
        else "falls";
        " to the ";
        if (Me.location == north_hallway) "walkway above. ";
        else "floor below. ";
    }
    verDoClimb(actor) = {}
    doClimb(actor) = {
        if (actor.location == north_hallway)
            actor.travelTo(north_hallway.ne);
        else actor.travelTo(ne_walkway.down);
    }
    doSynonym('Climb') = 'Enter'
;

nw_staircase: wallpaper, decoration
    stage = 1
    noun = 'staircase' 'stair' 'stairs'
    adjective = 'sweeping' 'northwest' 'nw'
    plural = 'staircases'
    sdesc = "northwest staircase"
    ldesc = {
        "The staircase curves as it ";
        if (Me.location == north_hallway) "climbs";
        else "falls";
        " to the ";
        if (Me.location == north_hallway) "walkway above. ";
        else "floor below. ";
    }
    verDoClimb(actor) = {}
    doClimb(actor) = {
        if (actor.location == north_hallway)
            actor.travelTo(north_hallway.nw);
        else actor.travelTo(nw_walkway.down);
    }
    doSynonym('Climb') = 'Enter'
;

utility_door1: doorItem
    stage = 1
    isopen = nil
    adjective = 'small'
    location = north_hallway
    sdesc = "small door"
    ldesc = "The <<self.wordDesc>> door leads west. "
    lookthrudesc = "You catch a glimpse of something large and metal. "
    doordest = utility_room
    otherside = utility_door2
;

north_hallway_doorway: myDoorway
    location = north_hallway
    ldesc = "It leads east. "
    lookthrudesc = "You can see some empty shelves. "
    doordest = north_archive
;

south_archive: insideRm
    breakerNum = 5
    floating_items = [ archive_shelves ]
    sdesc = "South Half of Archive"
    ldesc = {
        if (!self.lightsOn)
            "Just enough light filters in to show you r";
        else "R";
        "ow after row of boxes fill<<self.lightsOn ? "" : "ing" >> rack after
            rack of shelves, making it difficult to find a place to stand. ";
        if (self.lightsOn)
            "The boxes glisten in the room lights. ";
        "The room continues to the north. Above the west exit is a clock;
            beside the exit is a light switch. ";
    }
    exits = 'north and west'
    north = north_archive
    west = south_hallway
    out = south_hallway
;

archive_lights: ceiling_lights
    mySwitch = archive_switch
    location = south_archive;

archive_switch: lightswitch
    location = south_archive;

archive_clock: wall_clock
    location = south_archive
    timeOfDeath = '2:25'
;

archive_shelves: wallpaper, decoration
    stage = 1
    isThem = true
    noun = 'shelf' 'rust'
    plural = 'shelves'
    adjective = 'metal' 'rusty'
    sdesc = "metal shelves"
    ldesc = {
        "The shelves cover the room, as if they had multiplied in the same
            manner coathangers are reputed to. ";
        if (Me.location == south_archive)
            "There are few empty ones, as most are taken up by boxes. ";
        else "They are covered in broken shards. ";
    }
;

archive_boxes: fixeditem, readable
    stage = 1
    isThem = true
    noun = 'box'
    plural = 'boxes'
    adjective = 'cardboard'
    location = south_archive
    sdesc = "cardboard boxes"
    ldesc = "Cardboard boxes, all taped shut. Each one has been labeled with
        a black magic marker. "
    readdesc = "Your eyes roam over their surfaces, taking in their titles.
        Many are labeled \"Memories\" with a range of dates following. A
        few are labeled \"Fragments.\" You feel an odd sense of
        disorientation as you stare at them. "
    takedesc = "There are too many, and you have no way of determining
        which are important. "
    frankiedesc = 'Another group was working on those, but they never could
        get them open. Judging from the shards near them, they probably held
        some of these spheres.'
    verDoOpen(actor) = { "The tape prevents you from opening the boxes. "; }
    doSynonym('Open') = 'Search'
;

archive_tape: fixedItem
    stage = 1
    noun = 'tape'
    location = south_archive
    sdesc = "tape"
    ldesc = "Strong grey tape, covering every open flap of the boxes. "
    takedesc = "No matter how hard you tug, the tape remains in place. "
    verDoPull(actor) = (self.takedesc)
;

north_archive: insideRm
    floating_items = [ archive_shelves ]
    sdesc = "North Half of Archive"
    ldesc = {
        "Metal shelves fill the hall; most are empty and many have succumbed
            to rust";
        if (south_archive.lightsOn)
            ", dimming their reflection of the room lights";
        ". The shelves that aren't empty hold broken shards of glass. The
            archive continues to the south, and an exit leads west. ";
    }
    exits = 'south and west'
    south = south_archive
    west = north_hallway
    out = north_hallway
;

fake_archive_lights: ceiling_lights
    location = north_archive
    ldesc = {
        if (south_archive.lightsOn)
            "They glow softly, illuminating the room. ";
        else "They are cold and dark. ";
    }
    verDoTurnon(actor) = { "You see no way of turning on or off the lights. "; }
    doSynonym('Turnon') = 'Turnoff' 'Switch' 'Flip'
;

broken_shards: fixedItem
    noun = 'shard' 'shards' 'glass' 'powder'
    adjective = 'glass' 'sharp'
    location = north_archive
    sdesc = "shards of glass"
    ldesc = "The glass fragments run the gamut from large shards to fine,
        gritty powder. "
    touchdesc = {
        if (gloves.isworn)
            "You can't feel them through the gloves. ";
        else "You would most surely cut yourself. ";
    }
    takedesc = {
        if (gloves.isworn)
            "Though the gloves protect your hands, they render your fingers
                too clumsy to pick up the shards. ";
        else "You would most surely cut yourself. ";
    }
;

utility_room: insideRm
    floating_items = [ rickety_stairs ]
    noDog = { return !utility_door2.isopen; }
    sdesc = "Utility Room"
    ldesc = {
        "The room is hot and stifling; cobwebs drip from every surface. A
            hot-water tank crouches in one corner. ";
        if (utility_trapdoor.location == self)
            "A trapdoor in the floor marks where the stairs used to be. ";
        else "Rickety stairs lead into the depths of the building. ";
        "To the east is <<utility_door2.aWordDesc>> door. ";
    }
    smelldesc = "The room has a musty odor. "
    exits = {
        "You can go east";
        if (utility_trapdoor.location != self)
            " and down";
        ". ";
    }
    east = utility_door2
    down = {
        if (utility_trapdoor.location == self) {
            "The trapdoor prevents you. ";
            return nil;
        }
        if (fatherMessage.location != nil)
            fatherMessage.downStairs = true;
        return balance_room;
    }
    out = utility_door2
;

utility_door2: doorItem
    stage = 1
    isopen = nil
    location = utility_room
    ldesc = "The <<self.wordDesc>> door leads east. "
    lookthrudesc = "You see the hallway beyond. "
    doordest = north_hallway
    otherside = utility_door1
;

// Only appears if the sludge claims the room below
utility_trapdoor: fixedItem
    stage = 1
    noun = 'trapdoor'
    plural = 'trapdoors'
    sdesc = "trapdoor"
    ldesc = "The trapdoor is closed. It bulges upwards slightly. "
    verDoKnockon(actor) = { "Your knuckle makes a dull sound on the
        trapdoor. "; }
    verDoOpen(actor) = {
        "Pressure from the other side opposes you. ";
    }
;

utility_cobwebs: decoration
    isThem = true
    noun = 'cobweb' 'cobwebs' 'web' 'webs'
    location = utility_room
    sdesc = "cobwebs"
    ldesc = "The cobwebs are draped over every imaginable surface. "
;

hot_water_tank: fixedItem
    noun = 'tank'
    adjective = 'water' 'hot-water' 'old' 'rusty'
    location = utility_room
    sdesc = "hot-water tank"
    ldesc = "The tank is old and somewhat rusty. An orange wire runs past it. "
    touchdesc = "The tank is cool. "
    verDoLookin(actor) = {
        "The tank is solid, preventing you from looking inside. ";
    }
;

utility_orange_cable: decoration
    noun = 'cable' 'wire'
    adjective = 'orange'
    location = utility_room
    sdesc = "orange cable"
    ldesc = "The cable runs from the northeast baseboards to the floor beside
        the hot-water tank. "
;

rickety_stairs: wallpaper
    stage = 1
    noun = 'stair'
    adjective = 'rickety'
    plural = 'stairs'
    sdesc = "rickety stairs"
    ldesc = {
        "The stairs lead ";
        if (Me.location == utility_room)
            "down. ";
        else "up. ";
    }
    verDoClimb(actor) = {}
    doClimb(actor) = {
        if (actor.location == utility_room)
            actor.travelTo(utility_room.down);
        else actor.travelTo(balance_room.up);
    }
    doSynonym('Climb') = 'Enter'
;

balance_room: insideRm
    noDog = { return !utility_door2.isopen; }
    floating_items = [ rickety_stairs ]
    breakerNum = 2
    nsHeight = 0  // Tilt to north-south. +#'s mean n is raised, s lowered
    ewHeight = 1  // Tilt to east-west. +#'s mean e is raised, w lowered
    sdesc = "Balance Room"
    ldesc = {
        local flag = 0;

        "A cramped square room, barely lit by ";
        if (self.lightsOn)
            "ceiling lights";
        else "windows above you";
        ". The north and west walls are taken up by tables. A clock and a light
            switch are just
            visible next to the stairs on the south wall. In the northwest
            corner ";
        if (sludge.location == self) {
            "a river of black sludge is continuously flowing into the room";
            if (!(self.nsHeight < 2 && self.ewHeight > -2)) {
                " and towards the ";
                if (self.nsHeight < 2) "north"; else "south";
                if (self.ewHeight > -2) "west"; else "east";
                " corner";
                if (!(self.nsHeight < 2) && self.ewHeight > -2)
                    " by the stairs";
                if (self.nsHeight >= 2 && self.ewHeight <= -2 &&
                    heater.wallSpot == 1)
                    " where it is being consumed by the heater";
            }
        }
        else {
            "is a tiny drain";
            if (self.lightsOn)
                " which catches and reflects the light from the ceiling
                    lights";
        }
        "; in the southeast
            corner are two large wheels, one on the east wall and one on the
            south wall. A pile of spheres has claimed part of the east wall
            beneath the wheel. ";
        if (self.nsHeight >= 2 || self.nsHeight <= -2 || self.ewHeight >= 2 ||
                self.ewHeight <= -2) {
            "The floor slopes noticeably towards the ";
            if (self.nsHeight >= 2) "south";
            else if (self.nsHeight <= -2) "north";
            if (self.ewHeight >= 2) "west";
            else if (self.ewHeight <= -2) "east";
            ". ";
        }
    }
    smelldesc = "There is the hint of smoke in the air. "
    listendesc = {
        if (junction_box.isActive)
            "You hear a high-pitched humming coming from somewhere. ";
        else if (breakers.numberOn == 6)
            "There is a low humming coming from somewhere. ";
        else pass listendesc;
    }
    exits = 'up'
    south = {
        if (fatherMessage.location != nil)
            fatherMessage.upStairs = true;
        return utility_room;
    }
    up = { return self.south; }
    out = { return self.south; }
    firstseen = {
        "\bAs your footsteps sound on the stairs, the man turns. He looks you
            over, one eyebrow quirking in surprise. \"Hello,\" he says. \"And
            here I thought I was the last one still around. I'm Frankie.\" ";
        frankie.beenIntroduced = true;
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (breakers.numberOn == 8 && sludge.location != self)
            notify(sludge, &grow, 2);
    }
;

balance_room_lights: ceiling_lights
    mySwitch = balance_room_switch
    location = balance_room;

balance_room_switch: lightswitch
    firstOn = true
    location = balance_room
    doTurnon(actor) = {
        inherited.doTurnon(actor);
        if (firstOn) {
            firstOn = nil;
            if (frankie.location != actor.location || balance_room.lightsOn)
                return;
            "Frankie's head turns at the sound of the switch. \"It's no
                good,\" he calls over his shoulder. \"Power went out in here
                yesterday morning.\" ";
        }
    }
;

balance_room_clock: wall_clock
    location = balance_room
    ldesc = {
        inherited.ldesc;
        "Next to the clock is a light switch. ";
    }
    timeOfDeath = '10:02'
;

fake_windows: distantItem
    isThem = true
    noun = 'window' 'windows'
    location = balance_room
    sdesc = "windows"
    ldesc = "The windows are barely ten centimeters tall and are nearly flush
        with the ceiling. They are much thicker than you would expect, almost
        like the glass found on submersibles. "
    verDoLookthru(actor) = {}
    doLookthru(actor) = { "You glimpse grey skies outside. "; }
;

drain: fixeditem, surface
    stage = 1
    noun = 'drain' 'grate'
    adjective = 'tiny' 'metal' 'circular'
    location = balance_room
    sdesc = "metal drain"
    ldesc = {
        local list;
        
        "The metal drain is a small circle with a grate about ten
            centimeters in diameter. ";
        list = contlist(self);
        if (length(list) > 0)
            "On the drain %you% see%s% <<listlist(list)>>. ";
    }
    takedesc = "It is too firmly affixed to the floor. "
;

balance_tables: surface, fixedItem
    stage = 1
    isThem = true
    firstLdesc = true
    noun = 'table'
    plural = 'tables'
    location = balance_room
    sdesc = "tables"
    ldesc = {
        local conts;

        "The tables line the north and west walls. ";
        if (length(conts = contlist(self)) > 0)
            "On them %you% see%s% <<listlist(conts)>>. ";
        if (self.firstLdesc) {
            self.firstLdesc = nil;
            "\bOut of the corner of your eye you notice something under the
                tables. ";
        }
    }
    verDoLookunder(actor) = {
        "Under the tables you see a junction box. ";
        junction_box.moveInto(balance_room);
        junction_wire.moveInto(balance_room);
    }
    showcontents = {
        local list;
        list = contlist(self);
        if (length(list)>0) {    // SRG: changed use of sdesc to thedesc
            "Sitting on <<self.thedesc>> are <<listlist(list)>>. ";
        }
        listfixedcontents(self);
    }
;

junction_box: switchItem
    flippedOnce = nil        // For scoring purposes
    askDisambig = true
    stage = 1
    noun = 'box' 'switch'
    plural = 'boxes' 'switches'
    adjective = 'junction' 'knife'
    firstOn = true
    sdesc = "junction box"
    ldesc = "The junction box has a wire running out of it and a large knife
        switch on its side. The switch is currently <<self.wordDesc>>. "
    listendesc = {
        if (self.isActive) "It is emitting a high-pitched hum. ";
        else if (breakers.numberOn == 8)
            "From somewhere behind it you hear a low hum. ";
        else pass listendesc;
    }
    frankiedesc = 'It supposedly powers the fence on the hill above us."
        He shrugs. "I\'ve never seen it working.'
    doSwitch(actor) = {
        if (self.isActive) self.doTurnoff(actor);
        else self.doTurnon(actor);
    }
    doSynonym('Switch') = 'Flip' 'Throw'
    doTurnon(actor) = {
        "%You% push%es% the large knife switch up. ";
        if (breakers.numberOn == 8) {
            "The box begins a high-pitched humming, the switch fixed in
                place. ";
            self.isActive = true;
            if (!self.flippedOnce) {
                self.flippedOnce = true;
                findJunctionBoxAh.solve;
                incscore(1);
            }
            return;
        }
        "When %you% release%s% it, however, it slides back to its original
            position. ";
        if (self.firstOn) {
            self.firstOn = nil;
            if (frankie.location != actor.location) return;
            if (balance_room_switch.firstOn)
                "\"Don't waste your time with that,\" Frankie tells you.
                    \"It won't work without power.\" ";
            else "Frankie chuckles softly. \"Didn't I tell you power had gone
                out?\" ";
        }
    }
    doTurnoff(actor) = {
        "%You% pull%s% the large knife switch down.  The box quietens
            somewhat. ";
        self.isActive = nil;
    }
;

junction_wire: decoration
    askDisambig = true
    stage = 1
    noun = 'wire'
    plural = 'wires'
    adjective = 'large' 'orange' 'bare'
    sdesc = "large wire"
    ldesc = "The wire is large and sheathed in orange. It runs from the box
        into the northeast corner of the wall. "
    frankiedesc = { return junction_box.frankiedesc; }
    factTold = { return junction_box.factTold; }
;

balances: decoration
    stage = 1
    isThem = true
    isListed = true
    noun = 'balance'
    plural = 'balances'
    adjective = 'tarnished' 'brass' 'steel' 'five'
    location = balance_tables
    sdesc = "five balances"
    ldesc = "Sitting silent on the tables, the balances are all tarnished
        brass and pitted steel. "
    frankiedesc = "\"Frankly, I don't know what they were for. One of the
        unsolved mysteries of this place.\" "
    verIoAskAbout(actor, dobj) = {}
;

pile_o_memories: fixeditem
    askDisambig = true
    stage = 1
    firstTouch = true
    noun = 'pile' 'memory' 'sphere'
    plural = 'memories' 'spheres'
    location = balance_room
    sdesc = "pile of spheres"
    ldesc = "The spheres are smooth and translucent, glowing softly from
        within. Several are caked with mud and dirt, testimony to their
        recent location. They have been stacked in a tight-fitting pyramid.
        You feel a strange sense of deja vu as you gaze into them. "
    touchdesc = { self.takedesc; }
    takedesc = {
        if (!self.firstTouch) {
            "Again you reach for the spheres, but cannot draw close. The
                rush of memories triggered by the spheres was overwhelming
                the first time. ";
            return;
        }
        self.firstTouch = nil;
        "You reach your hand towards one of the spheres. As you draw nearer,
            a spark spits from the sphere, rushes up your arm, and then--\b
            Darkness, then light.\b
            You see yourself, a brief memory of driving your father's car
            alone for the first time, Joe Walsh on the radio, hands ice-slick
            with the fear of wrecking, pulse pounding, the thrill of being in
            control--\b
            Light, then darkness.\b
            You are thirteen, on a camping trip with friends, hiding in
            the dark, playing a game of flashlight tag, who will be the
            first to find you, or will you find the others first--\b
            With a horrendous wrenching sensation you pull yourself away
            from the pile of spheres. ";
        if (frankie.location == Me.location)
            "You glance at Frankie but, absorbed in his notetaking, he
                has not noticed your momentary distress. ";
        notify(self, &makeDog, 2);
    }
    frankiedesc = 'They were my project. Well, mine and some colleagues.
        They\'d been buried near here for years." He gazes at the spheres for
        a minute, then at you. "Makes you wonder why someone would go to all
        the trouble to bury them.'
    verDoLookin(actor) = {
        "Almost you can look past their murky surface and into them.
            Almost... ";
    }
    makeDog = {
        if (Me.location != balance_room) {
            notify(self, &makeDog, 2);
            return;
        }
        "\bOne of the spheres teeters, then rolls down the pile.
            It reaches the bottom
            and breaks, golden smoke issuing from it.
            As the shards of the sphere melt into the floor, the smoke begins
            coalescing, solidifying into a Welsh Corgi puppy who barks
            twice at you. ";
        if (frankie.location == balance_room)
            "\bFrankie glances at the puppy, then at you, smiling at something.
                \"Looks like you have a new pet,\" he says. \"I'd say the
                first order of business is to name him.\" ";
        dog.moveInto(balance_room);
        dog.wantheartbeat = true;        // Wind up the dog
        dogClueAh.see;
    }
;

heater: fixedItem
    wallSpot = 0  // Where on the south wall we are. -1 (sw) to 1 (se)
    burningSludge = nil  // If we're burning sludge yet
    noun = 'heater' 'stove'
    location = balance_room
    sdesc = "heater"
    ldesc = "It is an old-fashioned wood-burning heater, standing a few
            centimeters above the ground on metal legs. Heat pours from it
            in waves. Its most noticeable feature isn't:\ it has no smoke
            stack. "
    hdesc = {
        if (self.wallSpot == -1)
            "Near the entrance in the southwest corner";
        else if (self.wallSpot == 0)
            "In the middle of the south wall";
        else if (self.wallSpot == 1)
            "Just east of the stairs";
        else "\(somewhere it shouldn't be\)";
        " is a heater. ";
    }
    takedesc = "It is much too heavy. "
    smelldesc = "It smells strongly of wood-smoke. "
    touchdesc = "The outside is quite warm in places, scalding in others. "
    verDoOpen(actor) = { "%You% see%s% no way of opening it. "; }
    verIoPutInto(actor) = {
        "The heater is closed; %you% see%s% no way of opening it. ";
    }
    verDoPush(actor) = {
        "The heater rocks a bit, as if you could move it. ";
    }
    doSynonym('Push') = 'Pull'
    verDoMove(actor) = { "In what direction do %you% want to move it? "; }
    verDoMoveN(actor) = { "You don't have enough leverage. "; }
    doSynonym('MoveN') = 'MoveNE' 'MoveNW'
    verDoMoveS(actor) = { "It is already flush against the wall. "; }
    doSynonym('MoveS') = 'MoveSE' 'MoveSW'
    verDoMoveE(actor) = {
        if (self.wallSpot == 1)
            "The east wall prevents you. ";
    }
    verDoMoveW(actor) = {
        if (self.wallSpot == -1)
            "The heater is already flush against the stairs. ";
        else if (self.burningSludge)
            "It would not be wise to move it and allow the sludge to flow
                unchecked. ";
    }
    doMoveE(actor) = {
        "%You% %are% not able to touch the surface of the heater for long, but
            by fits and starts %you% %are% finally able to push the heater
            east. ";
        self.wallSpot++;
        if (gloves.location == actor && gloves.isworn) {
            "%Your% gloves smolder slightly in the process. ";
            gloves.smoldered = true;
        }
        self.testSludge;
    }
    doMoveW(actor) = {
        "%You% %are% not able to touch the surface of the heater for long, but
            by fits and starts %you% %are% finally able to push the heater
            west. ";
        self.wallSpot--;
        if (gloves.location == actor && gloves.isworn) {
            "%Your% gloves smolder slightly in the process. ";
            gloves.smoldered = true;
        }
    }
    testSludge = {
        if (!(sludge.location == balance_room && sludge.isBig &&
            balance_room.nsHeight >= 2 && balance_room.ewHeight <= -2 &&
            self.wallSpot == 1)) return;
        self.burningSludge = true;
        if (Me.location == balance_room)
            "\bYour actions catch Frankie's attention. He turns and sees
                the sludge heading for the heater. His eyes widen comically.
                Alarmed at the sludge building up around the heater's
                legs, Frankie says, \"Don't do it!\"\ just as the sludge
                reaches the bottom of the heater. With a horrendous sizzling
                noise, the sludge begins evaporating as fast as it is flowing
                into the corner. It recoils, trying to escape, but the slope
                of the floor prevents it.\bIn its thrashing, however, one
                tendril caresses a loose sphere, turning its golden light
                dark black. ";
        sludgeAh.solve;
        findJunctionBoxAh.see;
        evil_memory.moveInto(balance_room);
        notify(frankie, &success, 2);
        frankie.sorting = nil;
        unnotify(sludge, &grow);
        incscore(7);
    }
;

evil_memory: item
    isSphere = true
    askDisambig = true
    firstTake = true
    weight = 3
    bulk = 5
    noun = 'sphere' 'memory'
    plural = 'spheres'
    adjective = 'black' 'dark' 'evil'
    sdesc = "dark sphere"
    ldesc = "Unlike its mates, this smooth sphere glows blackly. It feels
        oddly wrong, almost evil. "
    takedesc = {
        if (self.firstTake) {
            "You bend down and pick it up. A sudden tremor seizes your arm
                muscles, then stops. ";
            self.firstTake = nil;
            evilClueAh.see;
        }
        else "Taken. ";
    }
    touchdesc = "It feels wetly slick to the touch. "
    doBreak(actor) = {
        "You crack the sphere in your hands. A black cloud rises from the
            shards, coalescing about you. You hear a horrendous shriek just
            at the level of audibility; your surroundings dim. Memories of bad
            dreams brush across the edges of your vision.\b
            Then the cloud dissipates, the shriek falls silent. The shards
            in your hands evaporate like so much mist. ";
        self.moveInto(nil);
    }
    frankiedesc = 'I\'m not sure. It does look evil, though, doesn\'t it?'
    verDoRub(actor) = {}
    doRub(actor) = { "The sphere vibrates with the sound of a thousand
        screams. "; }
;

south_wheel: fixeditem
    stage = 1
    noun = 'wheel'
    plural = 'wheels'
    adjective = 'south' 's' 'metal'
    location = balance_room
    sdesc = "south wheel"
    ldesc = "The spoked metal wheel has a handle at one point of its
        circumference. "
    frankiedesc = 'The wheels control the level of this room. I assume that
        they were installed to keep the balances...well, balanced.'
    verDoTurn(actor) = {
        "%You% need%s% to specify clockwise or counterclockwise. ";
    }
    verDoTurnCW(actor) = {
        if (balance_room.ewHeight >= 2)
            "The wheel, stubborn, refuses to turn further in that direction. ";
        else if (heater.burningSludge)
            "It would not be wise to interrupt the flow of sludge to
                the heater. ";
    }
    verDoTurnCCW(actor) = {
        if (balance_room.ewHeight <= -2)
            "The wheel refuses to turn further in that direction. ";
    }
    doTurnCW(actor) = {
        balance_room.ewHeight++;
        "%You% give%s% the wheel a clockwise spin. As %you% %do%, a groaning,
            shuddering sound emanates from beneath your feet. The floor tilts
            alarmingly, sending the balances to chattering and the pyramid
            of spheres to shaking. ";
        if (frankie.location == actor.location ||
            dog.location == actor.location) {
            if (frankie.location == actor.location) {
                "Frankie spares you a glance";
                if (dog.location == actor.location)
                    "; <<dog.thedesc>> looks surprised. ";
                else ". ";
            }
            else if (dog.location == actor.location)
                "<<dog.capdesc>> looks surprised. ";
        }
        "When %you% %are% done the east side of the room is higher than it
            was, the west side lower. ";
        if (!(sludge.location == balance_room && sludge.isBig &&
            balance_room.ewHeight == -1)) return;
        "The flow of sludge alters course, until it is collecting near ";
        if (balance_room.nsHeight < 2)
            "the middle of the room. ";
        else "the entrance. ";
    }
    doTurnCCW(actor) = {
        balance_room.ewHeight--;
        "%You% give%s% the wheel a counterclockwise spin. As %you% %do%, a
            groaning,
            shuddering sound emanates from beneath your feet. The floor tilts
            alarmingly, sending the balances to chattering. The pyramid of
            spheres shakes but stays together. ";
        if (frankie.location == actor.location ||
            dog.location == actor.location) {
            if (frankie.location == actor.location) {
                "Frankie spares you a glance";
                if (dog.location == actor.location)
                    "; <<dog.thedesc>> looks surprised. ";
                else ". ";
            }
            else if (dog.location == actor.location)
                "<<dog.capdesc>> looks surprised. ";
        }
        "When %you% %are%
            done the west side of the room is higher than it was, the east
            side lower. ";
        if (!(sludge.location == balance_room && sludge.isBig &&
            balance_room.ewHeight == -2)) return;
        "The flow of sludge alters course, until it is collecting near ";
        if (balance_room.nsHeight < 2)
            "the northeast corner. ";
        else {
            "the southeast corner. ";
            heater.testSludge;
        }
    }
;

east_wheel: fixeditem
    stage = 1
    noun = 'wheel'
    plural = 'wheels'
    adjective = 'east' 'e' 'metal'
    location = balance_room
    sdesc = "east wheel"
    ldesc = "The spoked metal wheel has a handle at one point of its
        circumference. "
    ioAskAbout -> south_wheel
    verDoTurn(actor) = {
        "%You% need%s% to specify clockwise or counterclockwise. ";
    }
    verDoTurnCW(actor) = {
        if (balance_room.nsHeight >= 2)
            "The wheel refuses to turn further in that direction. ";
    }
    verDoTurnCCW(actor) = {
        if (balance_room.nsHeight <= -2)
            "The wheel, stubborn, refuses to turn further in that direction. ";
        else if (heater.burningSludge)
            "It would not be wise to interrupt the flow of sludge to
                the heater. ";
    }
    doTurnCW(actor) = {
        balance_room.nsHeight++;
        "%You% give%s% the wheel a clockwise spin. As %you% %do%, a groaning,
            shuddering sound emanates from beneath your feet. The floor tilts
            alarmingly, sending the balances to chattering. The pyramid of
            spheres shakes but stays together. ";
        if (frankie.location == actor.location ||
            dog.location == actor.location) {
            if (frankie.location == actor.location) {
                "Frankie spares you a glance";
                if (dog.location == actor.location)
                    "; <<dog.thedesc>> looks surprised. ";
                else ". ";
            }
            else if (dog.location == actor.location)
                "<<dog.capdesc>> looks surprised. ";
        }
        "When %you% %are% done the north side of the room is
            higher than it was, the south side lower. ";
        if (!(sludge.location == balance_room && sludge.isBig &&
            balance_room.nsHeight == 2)) return;
        "The flow of sludge alters course, until it is collecting near ";
        if (balance_room.ewHeight <= -2) {
            "the southeast corner. ";
            heater.testSludge;
        }
        else "the entrance. ";
    }
    doTurnCCW(actor) = {
        balance_room.nsHeight--;
        "%You% give%s% the wheel a counterclockwise spin. As %you% %do%, a
            groaning,
            shuddering sound emanates from beneath your feet. The floor tilts
            alarmingly, sending the balances to chattering. The pyramid of
            spheres shakes but stays together. ";
        if (frankie.location == actor.location ||
            dog.location == actor.location) {
            if (frankie.location == actor.location) {
                "Frankie spares you a glance";
                if (dog.location == actor.location)
                    "; <<dog.thedesc>> looks surprised. ";
                else ". ";
            }
            else if (dog.location == actor.location)
                "<<dog.capdesc>> looks surprised. ";
        }
        "When %you% %are% done the south side of the room is
            higher than it was, the north side lower. ";
        if (!(sludge.location == balance_room && sludge.isBig &&
            balance_room.nsHeight == 1)) return;
        "The flow of sludge alters course, until it is collecting near ";
        if (balance_room.ewHeight > -2)
            "the middle of the room. ";
        else "the northwest corner. ";
    }
;

sludge: fixedItem
    askDisambig = true
    stage = 1
    isBig = nil
    noun = 'sludge'
    adjective = 'black' 'thick' 'viscous'
    sdesc = "black sludge"
    ldesc = {
        local ns, ew;

        "The black sludge is burgeoning out of what used to be the drain. ";
        if (!isBig) return;
        ns = balance_room.nsHeight;
        ew = balance_room.ewHeight;
        "It has flowed from the northwest corner to the ";
        if (ns < 2 && ew > -2) {
            "center of the room. ";
            return;
        }
        if (ns < 2) "north"; else "south";
        if (ew > -2) "west"; else "east";
        " corner";
        if (ns >= 2 && ew > -2) " in front of the stairs";
        if (ns >= 2 && ew <= -2 && heater.wallSpot == 1)
            " where it is being consumed by the heater";
        ". ";
    }
    touchdesc = { self.takedesc; }
    takedesc = "The thick, viscous stuff surges towards you as you approach.
        Alarmed, you back away. "
    frankiedesc = 'I don\'t know. Sam was studying it. He thought it was
        connected somehow to the spheres. All he was able to discover about
        it was that it was highly toxic and flammable.'
    grow = {
        if (self.location == nil) {
            self.moveInto(balance_room);
            if (Me.location == balance_room) {
                "\bA quiet sound catches your attention. Black sludge has
                    begun welling up through the drain, ";
                if (length(contlist(drain)) > 0)
                    "moving the things ";
                "covering it and
                    starting to fill the northwest corner.\b
                    Frankie glances down, then swears quietly. \"Sam, you
                    son-of-a-bitch,\" he mutters, scribbling furiously in
                    his notebook. ";
                if (dog.location == balance_room)
                    "<<dog.capdesc>> barks at the sludge, then begins whining
                        softly. ";
                sludgeAh.see;
            }
            moveAllCont(drain, drain.location);
            drain.moveInto(nil);
            notify(self, &grow, 5);
            frankie.actionTurn = -2;    // Frankie needs to shut up now
            return;
        }
        if (!self.isBig) {
            self.isBig = true;
            notify(self, &grow, 15);
            if (Me.location == balance_room)
                "\bWith a loud blorp, the flow of sludge increases.
                    Noticeably. ";
            if (!(self.location == balance_room &&
                balance_room.nsHeight >= 2 && balance_room.ewHeight <= -2 &&
                heater.wallSpot == 1)) return;
            if (Me.location == balance_room)
                "It begins flowing towards the southeast corner. You quickly
                    adjust the heater to be in the path of the sludge. ";
            heater.testSludge;
            return;
        }
        utility_trapdoor.moveInto(utility_room);
        utility_room.floating_items -= rickety_stairs;
        if (dog.location == balance_room)
            dog.moveInto(utility_room);
        frankie.moveInto(utility_room);
        if (Me.location == balance_room) {
            "\bThe flow of sludge triples, then triples again. ";
            if ((balance_room.nsHeight < 0 && balance_room.ewHeight <= 0) ||
                balance_room.ewHeight < 0)
                "There is a loud sizzle as it engulfs the heater,
                    extinguishing it. The flow";
            else "It";
            " reaches the
                pile of spheres, turning them all black, then dissolving
                them.\b
                \"Come on!\" Frankie shouts in horror, abandoning his task.
                He grabs your arm and drags you up the stairs,
                pulling the trapdoor shut behind him";
            if (dog.location == balance_room) {
                dog.moveInto(utility_room);
                " just after <<dog.thedesc>> runs through it";
            }
            ".\b";
            Me.travelTo(utility_room);
        }
        else if (Me.location == utility_room) {
            "\b\"Gangway!\"\ Frankie shouts as he runs up the stairs, pulling
                the trapdoor shut behind him";
            if (dog.location == balance_room) {
                dog.moveInto(utility_room);
                " just after <<dog.thedesc>> runs through it";
            }
            ". He sags against a
                nearby wall, panting heavily, while the trapdoor bulges
                outwards a bit. ";
        }
        frankie.sphereInInv = nil;        // Frankie no longer has a sphere
        notify(frankie, &failure, 1);
    }
;

frankie: trackActor
    selfDisambig = true
    stage = 1
    isHim = true
    beenIntroduced = nil
    askme = &frankiedesc
    motionList = [['u' 'e' 's' 's' 's']]
    actions = [
        'Frankie walks over to the pile of spheres, replaces one, and picks
            another after a moment of thought.'
        'Frankie holds a sphere up to his eye, looking at it. He then jots
            some notes down in a notebook.'
        'Frankie thoughtfully rolls a sphere around in his hand, then makes
            more notes.'
    ]
    actionNum = 2
    playerAskedForGlasses = nil
    okToGive = nil                            // Is it ok to give glasses?
    givenSphere = nil
    sphereChance = 0
    itemsGiven = 0                            // Number of objects given
    sphereInInv = true                        // I'm holding a sphere
    sorting = true
    myfollower = frankie_follower
    noun = 'frankie' 'archaeologist' 'man'
    location = balance_room
    sdesc = "Frankie"
    stringsdesc = 'Frankie'
    ldesc = {
        local sb = (single_book.location == self),
            cl = (connection_list.location == self), i = 0;
        
        "Frankie is of middling height, with tousled hair and a sandy brown
            mustache. He carries a notebook";
        if (sb) i++; if (cl) i++; if (self.sphereInInv) i++;
        if (sb) {
            if (i == 1) " and"; else ",";
            " a book";
        }
        if (cl) {
            if (i > 1) ",";
            if (i == 1 || (i == 2 && sb))
                " and";
            " a list";
        }
        if (self.sphereInInv) {
            if (i > 1) ",";
            " and a sphere";
        }
        ". ";
        if (sunglasses.location == self)
            "Resting in his shirt pocket are a pair of sunglasses. ";
    }
    actorDesc = {
        if (!beenIntroduced) {
            "A man stands bent over the tables, jotting things down in a
                large notebook. ";
            return;
        }
        if (self.location == balance_room && self.sorting) {
            "Frankie is here, sorting and cataloging";
            if (sludge.location == balance_room && !heater.burningSludge)
                " like mad";
            ". ";
        }
        else "Frankie is here. ";
    }
    verGrab(item) = {
        "Frankie snaps, \"If you want something, why don't you ask for it?\"
            He then sighs heavily. \"Sorry. I didn't mean to yell.\" ";
    }
    frankiedesc = "Frankie grins sardonically. \"I'm just an archaeologist,
        nothing more. My team and I were working on unearthing those,\" he
        gestures at the pile of spheres by the wall, \"until we got word of
        the avalanche.\" "
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "Frankie says, \"Hello again.\" ";
            exit;
        }
        else pass actorAction;
    }
    disavow = "Frankie says, \"I'm afraid I won't be much help with that.\" "
    alreadyTold = "Frankie says, \"This isn't a good time for repeat
        questions.\" "
    verDoAskFor(actor, io) = {
        if (io == rucksack && !io.firstMove)
            "Frankie says, \"You're welcome to the rucksack.\" ";
        else if (io.location != self)
            "\"I'm not carrying <<io.thedesc>>.\" ";
        else if (io == notebook)
            "\"I need it for my research.\" ";
        else if (io == single_book || io == connection_list)
            "\"I won't have time to look at it until later, so I'll hold on
                to it.\" ";
    }
    doAskFor(actor, io) = {
        if (!self.okToGive) {
            if (self.playerAskedForGlasses)
                "\"I told you, I'll help you if you help me.\" Frankie
                    grins. ";
            else {
                self.playerAskedForGlasses = true;
                if (!self.givenSphere)
                    self.giveSphere;
                else "Frankie smiles. \"I'll be happy to give you <<
                    io.thedesc>> if you can find out anything about that
                    sphere I gave you. You scratch my back and all that.\" ";
            }
            return;
        }
        "Frankie thinks, then grins. \"Sure. Here you go.\" He
            hands <<io.isThem ? "them" : "it">> to you. ";
        io.moveInto(actor);
        setit(io);
    }
    verIoGiveTo(actor) = {
        if (!self.givenSphere)
            "Frankie demurs, \"I don't need anything right now, thank you.\" ";
    }
    ioGiveTo(actor, dobj) = {
        if (dobj != single_book && dobj != connection_list &&
            dobj != lone_memory) {
            "Frankie says, \"No thanks.\" ";
            return;
        }
        if (dobj == lone_memory) {
            if (self.itemsGiven != 2)
                "\"I think you need that right now,\" Frankie says. ";
            else {
                "\"Mmm, I'd almost forgotten. Thanks,\" Frankie says as he
                    takes the sphere from you. He jots a few notes in his
                    notebook and replaces it on the pile. ";
                dobj.moveInto(nil);
            }
            return;
        }
        self.itemsGiven++;
        "Frankie grins. \"Thanks! ";
        if (self.itemsGiven == 1)
            "I think there's more to be found out about that sphere; see what
                you can find, if you will.\" ";
        else {
            "I think that does it.\" ";
            if (self.playerAskedForGlasses) {
                "Frankie takes his sunglasses out of his pocket. \"As
                    promised,\" he says as he hands them to you. ";
                glassesAh.see;
                sunglasses.moveInto(actor);
            }
            self.okToGive = true;
        }
        dobj.moveInto(self);
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (dobj == connection_list || dobj == single_book)
            self.ioGiveTo(actor, dobj);
        else "Frankie isn't impressed. ";
    }
    verDoKick(actor) = {
        "As you prepare to kick Frankie, he turns and fixes you with a gimlet
            glare. \"Now, now,\" he says softly. ";
    }
    verDoKiss(actor) = {
        "Frankie fends you off. \"Thanks, no,\" he says with a laugh. ";
    }
    verDoAttack(actor) = {
        "As you prepare to attack Frankie, he turns and fixes you with a gimlet
            glare. \"Now, now,\" he says softly. ";
    }
    actionDaemon = {
        if (Me.location != self.location) {
            self.actionNum = RAND(length(self.actions));
            self.actionTurn = -1;
            return;
        }
        "\b<<self.actions[self.actionNum]>>\n";
        self.actionNum++;
        if (self.actionNum > length(self.actions))
            self.actionNum = 1;
        self.actionTurn += 3 + RAND(3);
    }
    arriveDaemon = {
        if (Me.location == self.location)
            "\bFrankie turns and gives you a half-smile, then begins trudging
                through the snow. As he does so, he separates into thousands
                of grains, a painting by Seurat. The grains separate, caught
                in a sudden zephyr, and are gone. ";
        self.moveInto(nil);
        self.myfollower.moveInto(nil);
        self.wantheartbeat = nil;
    }
    heartbeat = {
        if (Me.location == nil) {
            self.wantheartbeat = nil;
            return;
        }
        if (Me.location == self.location && self.actionTurn == -1)
            self.actionTurn = global.turnsofar + 4 + RAND(4);
        if (!givenSphere && Me.location == self.location) {
            if (RAND(100) <= sphereChance) {
                "\b";
                self.giveSphere;
            }
            else sphereChance += 10 + RAND(7);
        }
        pass heartbeat;
    }
    giveSphere = {
        if (sludge.location == balance_room && !heater.burningSludge)
            return;
        "Frankie snaps his fingers. \"You know, I'd really appreciate it if
            you'd do me a favor.\" He holds up one of the spheres. \"I've
            had trouble cataloguing this one. Information's available
            upstairs, but I'd lose too much time if I searched for it myself.
            Would you mind terribly?\" Frankie puts the light sphere in your
            hands
            before you can answer, then picks up another sphere from the
            pile. ";
         self.givenSphere = true;
         sphereInfoAh.see;
         lone_memory.moveInto(Me);
         notify(lone_memory, &giveMemory, 2);
    }
    success = {
        if (Me.location == self.location)
            "\bFrankie grins at you. \"Nice work with the sludge,\" he says
                as he closes his notebook and replaces one last sphere on
                the pile. \"I was afraid the whole mass would catch on fire.\"
                He looks around the room, then grins again. \"I'd best
                be gone before the avalanche reaches here. I'd suggest the
                same for you.\" ";
        self.isMoving = true;    // Start moving
        self.sphereInInv = nil;  // No more sphere
    }
    failure = {
        if (Me.location == self.location) {
            "\bFrankie looks at his hands, surprised to find he is still
                carrying a sphere. He holds it up to the light; it has turned
                black as pitch. \"The sludge must've hit it,\" he says. Then
                he smiles at you, sadly. \"It would have been nice to be
                able to finish.\" He shrugs resignedly, dropping the sphere.
                \"Ah, well. See you round.\" He ";
            if (utility_door2.isopen) "turns";
            else {
                "opens the door";
                utility_door2.isopen = true;
                utility_door1.isopen = true;
            }
            " and walks into the hallway, but as
                he does, he separates into thousands of grains, a painting
                by Seurat. The grains separate, caught in a sudden zephyr,
                and are gone. ";
        }
        self.moveInto(nil);
        self.myfollower.moveInto(nil);
        self.wantheartbeat = nil;
        evil_memory.moveInto(utility_room);
    }
;

frankie_follower: follower
    myactor = frankie
    noun = 'frankie' 'archaeologist' 'man'
;

lone_memory: item
    isSphere = true
    askDisambig = true
    weight = 3
    bulk = 5
    memoryNum = 1
    noun = 'sphere' 'memory'
    plural = 'spheres'
    adjective = 'light' 'translucent'
    sdesc = "light sphere"
    ldesc = "A translucent sphere, about the size of an apple. "
    touchdesc = "It is smooth. "
    doBreak(actor) = {
        "You crack the sphere in your hands. A cloud rises from it, a
            vaguely-familiar smell. The shards evaporate. ";
        self.moveInto(nil);
    }
    frankiedesc = 'It\'s the one I asked you to find out about.'
    verDoRub(actor) = {}
    doRub(actor) = { "The sphere hums lightly, vibrating in response. "; }
    giveMemory = {
        switch (self.memoryNum++) {
            case 1:
                "\bSomething half-remembered intrudes on your thoughts, then
                    is gone. ";
                break;
            case 2:
                "\bA birthday party. You remember a birthday party, although
                    you're not sure whose it was. ";
                return;
        }
        notify(self, &giveMemory, 4);
    }
;

notebook: readable
    stage = 1
    noun = 'notebook'
    adjective = 'large'
    location = frankie
    sdesc = "notebook"
    ldesc = "A spiral-bound notebook, dog-eared and worn. You catch occasional
        glimpses of pages filled with small writing. "
    readdesc = "The pages you can see are filled with entry after entry. A
        typical one begins \"Sph 512:\ lt grey approx.\ 120g\" and continues
        from there. "
;

rucksack: sackItem, clothingItem, openable
    firstMove = true
    weight = 2
    bulk = 15
    maxbulk = 100
    noun = 'sack' 'rucksack' 'backpack' 'pack' 'knapsack'
    location = balance_tables
    sdesc = "rucksack"
    ldesc = {
        "It is made of heavy denim and looks well-used. ";
        pass ldesc;
    }
    takedesc = {
        if (!self.firstMove) {
            "Taken. ";
            return;
        }
        self.firstMove = nil;
        if (frankie.location == Me.location)
            "Frankie glances over at you as you pick up the rucksack. \"You
                can have it,\" he says. \"It'll do you more good than it will
                me.\" ";
        else "Taken. ";
    }
    frankiedesc = 'I used it to carry spheres, but I won\'t be needing it
        any more.'
;

sunglasses: clothingItem
    isThem = true
    weight = 2
    bulk = 5
    noun = 'sunglasses' 'glasses' 'shades'
    adjective = 'cheap' 'black' 'plastic'
    location = frankie
    adesc = "a pair of sunglasses"
    sdesc = "sunglasses"
    ldesc = "Cheap. Black. Plastic. "
    frankiedesc = {
        "He glances at the sunglasses. \"For outside.\" ";
    }
    putOnDesc = {
        if (Me.location.isSnowRoom) {
            "The blinding sunlight is suddenly reduced, allowing you to
                see again.\b";
            Me.location.lookAround(true);
        }
        else "Everything becomes a little dimmer as you put on the
            sunglasses. ";
    }
    takeOffDesc = {
        "%You% remove the sunglasses. ";
        if (Me.location.isSnowRoom)
            "The sudden glare of sun on snow blinds and disorients you. ";
    }
;

audience_hall: insideRm
    location = balcony    // So its contents are visible from the balcony
    isListed = nil        // So it's not mentioned in the Balcony
    isUber = true         // For the uberloc() routine--see funcs.t
    notakeall = true      // Otherwise much goofiness will ensue
    contentsReachable = { // More balcony fun--so you can't manipulate items
        return (Me.location == self);    //  in the hall
    }
    breakerNum = 3
    floating_items = [large_audience_doors, door_carving]
    sdesc = "Audience Hall"
    ldesc = {
        if (Me.location == benches)
            "The sound of the building settling echoes";
        else
            "Your footsteps echo hollowly";
        " in the ";
        if (self.lightsOn)
            "well";
        else "dimly";
        "-lit and cavernous hall. ";
        "Benches line the floor, their rows skewed
            slightly to focus on the desk at the north end. A clock is set in
            the wall in plain view of the desk. The south third of the room
            is covered by a balcony, reducing the height of the
            hall from two stories to one. A small door to the east and two
            large doors to the south stand ajar.  To one side of the two doors
            is a light switch. ";
    }
    exits = 'south and east'
    south = north_hallway
    east = prep_room
    listendesc = "You can hear the building settling. "
;

fake_audience_hall: decoration
    noun = 'hall'
    adjective = 'audience'
    location = balcony
    contentsReachable = nil
    sdesc = "audience hall"
    ldesc = {
        local conts;

        "The benches and desk look forlorn from this height. ";
        if (length(conts = contlist(audience_hall)) > 0)
            "Lying in the hall you see <<listlist(conts)>>. ";
    }
;

audience_lights: ceiling_lights
    stage = 1
    mySwitch = audience_switch
    isThem = true
    noun = 'light' 'chandelier'
    plural = 'lights' 'chandeliers'
    adjective = 'ceiling'
    location = audience_hall
    sdesc = "chandeliers"
    ldesc = {
        "The chandeliers hang above the hall, ";
        if (self.location.lightsOn)
            "raining light on the benches below. ";
        else "dark and useless. ";
    }
;

audience_switch: lightswitch
    location = audience_hall
;

audience_clock: wall_clock
    location = audience_hall
    timeOfDeath = '1:43'
;

fake_balcony: decoration
    noun = 'balcony'
    location = audience_hall
    sdesc = "balcony"
    ldesc = "The balcony stands above you, covering one-third of the hall. "
;

benches: platformItem, fixeditem
    stage = 1
    isThem = true
    noun = 'bench'
    plural = 'benches'
    adjective = 'row' 'rows'
    location = audience_hall
    sdesc = "benches"
    ldesc = {
        "They stand to either side of the hall, lined in rows running from east
            to west. They stop short of the desk, leaving several meters
            of clear floor. ";
        pass ldesc;
    }
    listendesc = "You can hear the building settling. "
    doSiton(actor) = {
        "You lower yourself onto a bench. ";
        actor.moveInto(self);
    }
    verDoPush(actor) = { "No matter how hard you push, they don't move. "; }
;

audience_desk: surface, fixeditem, nestedroom
    reachable = [audience_desk]
    stage = 1
    statusPrep = "behind"
    noun = 'desk' 'lectern'
    location = audience_hall
    sdesc = "desk"
    ldesc = {
        "More lectern than desk, it is slightly elevated. There is space
            behind it, presumably for a large chair, and it commands an
            excellent view of the entire room. ";
        pass ldesc;
    }
    verDoStandBehind(actor) = {
        if (actor.location == self)
            "You're already behind the desk. ";
    }
    doStandBehind(actor) = {
        "You step behind the desk. ";
        actor.moveInto(self);
    }
    verDoUnhideBehind(actor) = {
        if (actor.location != self)
            "But you're not behind the desk. ";
    }
    doUnhideBehind(actor) = { self.doUnboard(actor); }
    doSynonym('StandBehind') = 'HideBehind' 'Enter'
    north -> audience_hall
    south -> audience_hall
    east  -> audience_hall
    west  -> audience_hall
    up    -> audience_hall
    down  -> audience_hall
    ne    -> audience_hall
    nw    -> audience_hall
    se    -> audience_hall
    sw    -> audience_hall
    in    -> audience_hall
    out   -> audience_hall
    noexit = { "%You% can't go that way. "; return nil; }
;

small_door: decoration
    stage = 1
    noun = 'door'
    plural = 'doors'
    adjective = 'small'
    location = audience_hall
    sdesc = "small door"
    ldesc = "It stands partially ajar and leads to the east. "
    verDoKnockon(actor) = { "No one answers. "; }
    verDoOpen(actor) = {
        "No matter how hard you push and pull, it stays put. The hinges feel
            as if they have rusted into immobility. ";
    }
    doSynonym('Open') = 'Close' 'Move'
    verDoEnter(actor) = {}
    doEnter(actor) = { actor.travelTo(prep_room); }
;

prep_room: insideRm
    breakerNum = 4
    sdesc = "Preparatory Room"
    ldesc = {
        "Small and comfortable after the audience hall, a retreat for
            whoever once presided to the west. A coatrack, chair, and desk";
        if (self.lightsOn)
            ", lit by the glow of the ceiling lights,";
        " fill the room without crowding it. ";
    }
    listendesc = "You hear music coming from somewhere in the room. "
    firstseen = {
        coatClueAh.see;
        gloveAh.see;
    }
    exits = 'west'
    west = audience_hall
    sw = audience_hall
    out = audience_hall
;

prep_room_lights: ceiling_lights
    mySwitch = prep_room_switch
    location = prep_room;

prep_room_switch: lightswitch
    isActive = true
    location = prep_room;

// To make objects hangable on the coatrack, set canHang to true in that obj
coatrack: fixeditem
    stage = 1
    noun = 'rack' 'coatrack'
    location = prep_room
    sdesc = "coatrack"
    ldesc = {
        "Tall and wooden, it has several branches for coats and hats. ";
        self.showcontents;
    }
    takedesc = "It is too unwieldy for you to carry. "
    showcontents = {
        local conts;

    if (length(conts = contlist(self)) > 0) 
        "Hanging from the coatrack <<length(conts) > 1 ? "are" : "is"
            >> <<listlist(conts)>>. ";
    }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (dobj.canHang)
            dobj.doPutOn(actor, self);
        else "There's no good way to put that on the coatrack. ";
    }
    verIoTieTo(actor) = {}
;

prep_chair: chairitem, fixeditem
    stage = 1
    reachable = ([] + self + prep_desk + prep_clock + recovery_radio)
    noun = 'chair'
    plural = 'chairs'
    adjective = 'plush'
    location = prep_room
    sdesc = "plush chair"
    ldesc = {
        "The plush chair sits behind the desk. ";
        pass ldesc;
    }
    takedesc = "Were you to take it, you would be unable to walk. "
    verIoTieTo(actor) = {}
;

prep_desk: fixeditem, surface
    stage = 1
    noun = 'desk'
    plural = 'desks'
    adjective = 'wooden'
    location = prep_room
    sdesc = "wooden desk"
    ldesc = {
        "It is large without being overwhelming. An air of disuse hangs about
            it. Set into its surface are a clock and a radio. ";
        pass ldesc;
    }
;

prep_clock: fixedItem
    stage = 1
    timeOfDeath = '1:18'
    noun = 'clock'
    plural = 'clocks'
    adjective = 'desk'
    location = prep_room
    sdesc = "desk clock"
    ldesc = {
        "Its tiny face is turned towards the plush chair, its base affixed
            to the desk's surface. ";
        if (breaker_box.hasPower(self.location.breakerNum))
            "Its hands turn slowly, ticking off seconds, minutes, hours.";
        else "It has stopped at <<self.timeOfDeath>>. ";
    }
    verDoTurn(actor) = {
        "You give the clock a gentle spin. It ratchets around with the sound
            of shrieking metal. ";
    }
;

gloves: clothingItem
    askDisambig = true
    isThem = true
    canHang = true    // Can hang from the coatrack
    smoldered = nil   // Has been worn while pushing the stove in balance_room
    noun = 'glove'
    plural = 'gloves'
    adjective = 'heavy' 'wool'
    location = coatrack
    weight = 3
    bulk = 5
    sdesc = "heavy gloves"
    listdesc = {
        "a pair of gloves";
        if (self.isworn)
            " (being worn)";
    }
    ldesc = {
        "The gloves are thick and warm, padded with wool. ";
        if (self.smoldered)
            "Their palms are somewhat charred, as if held over a flame
                momentarily. ";
    }
    verDoWear(actor) = {
        if (fuzzy.painLevel > 1) {    // From hospital.t
            "Your hands will no longer fit in the gloves. ";
        }
        else pass verDoWear;
    }
    // checkInsulation also checks for the cold TEC. dropflag is a workaround
    //  to tell us if we are being called from a drop command or from an
    //  autoTakeOff routine, i.e. (removing the gloves first).
    checkInsulation(dropflag) = {
        local i, len, flag = nil;

        len = length(closet_insulation.tuftList);
        for (i = 1; i <= len; i++) {
            if (closet_insulation.tuftList[i].location == self.location) {
                closet_insulation.tuftList[i].moveInto(self.location.location);
                flag = true;
            }
        }
        if (flag) {
            if (dropflag)    // We were called from checkDrop
                ". ";
            "As %you% remove%s% the gloves, %you% find%s% that %you%
                %have% to drop the insulation %you% %were% carrying";
            if (!dropflag) ". ";
        }
        if (thermoelectric_cooler.location == self.location &&
            thermoelectric_cooler.coolLevel == 3) {
                if (dropflag) ". ";
                "Without the gloves' protection, the ceramic square is too
                    cold to hold on to";
                if (!dropflag) ". ";
                thermoelectric_cooler.moveInto(self.location.location);
        }
    }
    autoTakeOffDesc = {
        "(Taking off the gloves first";
        self.checkInsulation(true); // true b/c checkInsulation is being
        ")\n";                      //  called from checkDrop
    }
    takeOffDesc = {
        "Okay, %you're% no longer wearing the gloves. ";
        self.checkInsulation(nil);
    }
;

coat: clothingItem, container
    stage = 1
    tearLevel = 0  // How much the stitching is torn
    tuftNumber = 0 // Number of insulation tufts we hold
    canHang = true
    maxbulk = 6
    contentsReachable = { return !self.isworn; }
    contentsVisible = { return !self.isworn; }
    noun = 'coat' 'windbreaker'
    adjective = 'thin'
    location = coatrack
    weight = 5
    bulk = 3
    sdesc = "thin coat"
    ldesc = {
        local conts;

        "The coat is thin, more of a windbreaker than a coat. ";
        if (self.tearLevel == 0)
            "White stitching runs down its arms and sides. ";
        else if (self.tearLevel == 1)
            "Its white stitching gapes in places, giving you a glimpse
                into it. ";
        else if (self.tearLevel == 2) {
            "Its white stitching is torn, leaving it open like a
                huge sack. ";
            if (self.contentsVisible && length(conts = contlist(self)) > 0)
                "Stuffed inside the coat you see <<
                listlist(conts)>>. ";
        }
    }
    putOnDesc = {
        if (self.tuftNumber > 0) {
            "As %you% wear the coat %you% feel%s% the insulation inside
                crackling. ";
            if (self.tuftNumber == 3) {
                Me.coldTurns = 0;
                if (Me.location.isSnowRoom && !snowDaemon.givenPoints) {
                    snowDaemon.givenPoints = true;
                    incscore(5);
                }
            }
            else if (Me.coldTurns == 0)
                Me.coldTurns -= 5;
        }
        else if (self.contents != [])
            "The coat is uncomfortable, with strange lumps in it, but
                still wearable. ";
        else "Okay, %you're% now wearing <<self.thedesc>>. ";
        if (Me.location.isSnowRoom) {
            if (self.tuftNumber == 3)
                "The cold in your bones begins to dissipate. ";
            else if (self.tuftNumber > 0 && Me.coldTurns <= 0)
                "The cold feels somewhat less intense. ";
            else "It provides almost no protection from the cold. ";
        }
        else if (self.tuftNumber > 0)
            "The coat is <<self.tuftNumber == 3 ? "very" :
                "somewhat">> warm. ";
    }
    takeOffDesc = {
        if (Me.location.isSnowRoom) {
            "As you remove the coat, the wind rips through you. ";
            if (Me.coldTurns < 0)
                Me.coldTurns = 0;
        }
        else pass takeOffDesc;
    }
    showcontents = {
        local conts;

        if (self.contentsVisible && length(conts = contlist(self)) > 0) {
            "Stuffed inside the coat you see <<listlist(conts)>>. ";
        }
        listfixedcontents( self );
    }
    Grab(obj) = {               // Keep track of insulation in us
        if (obj.isInsulation)
            self.tuftNumber--;
        pass Grab;
    }
    verIoPutIn(actor) = {
        if (self.tearLevel != 2)
            "%You% can't put anything into the coat. ";
        else if (self.isworn)
            "Not while %you're% wearing the coat. ";
    }
    ioPutIn(actor, dobj) = {    // Keep track of insulation in us
        inherited.ioPutIn(actor, dobj);
        if (dobj.isInsulation && dobj.location == self)
            self.tuftNumber++;
    }
    verDoOpen(actor) = {
        if (self.tearLevel != 2)
            "How do you intend to do that? ";
        else "It is already as open as possible. ";
    }
    verDoLookin(actor) = {
        if (self.isworn)
            "Not while you're wearing the coat. ";
        else pass verDoLookin;
    }
    doPull -> stitching
    doTear -> stitching
;

stitching: fixeditem, floatingItem
    noun = 'stitching'
    adjective = 'white'
    location = { return coat.location; }
    sdesc = "white stitching"
    ldesc = {
        "It runs down the coat's arms and sides. ";
        if (coat.tearLevel == 0)
            "It has begun to unravel. ";
        else if (coat.tearLevel == 1)
            "In places it gapes slightly. ";
        else if (coat.tearLevel == 2)
            "It hangs loosely in many places, torn free from the coat. ";
    }
    takedesc = "You tug on the stitching and feel it give slightly. "
    verDoPull(actor) = {}
    doPull(actor) = {
        if (coat.tearLevel == 0) {
            "You give the stitching a good tug and feel it give slightly. ";
            stitchingAh.see;
        }
        else if (coat.tearLevel == 1)
            "The stitching gives further, causing the coat to gape. ";
        else {
            "With a final rip, the stitching tears completely free, leaving
                only scraps behind. ";
            if (coat.location == coatrack)
                scraps.moveInto(coatrack.location);
            else scraps.moveInto(coat.location);
            coat.moveInto(nil);
        }
        coat.tearLevel++;
    }
    doSynonym('Pull') = 'Tear' 'Open'
;

scraps: item
    isThem = true
    noun = 'scrap'
    plural = 'scraps'
    weight = 3
    bulk = 3
    sdesc = "scraps"
    adesc = "some scraps"
    thedesc = "some scraps"
    ldesc = "Despite their origin, the scraps now could barely cover one of
        your arms. "
;

north_walkway: insideRm
    nHallFlag = true
    floating_items = [ fake_north_hallway ]
    sdesc = "North Walkway"
    ldesc = "The walkway is just wide enough to accomodate two people turned
        sideways. Below you spreads the hallway. There is a
        gaping doorway to the north. "
    exits = 'north, east, and west'
    north = balcony
    south = { "The walkway runs east and west here. "; return nil; }
    east = {
        "The walkway bends to the south; you follow it.\b";
        return ne_walkway;
    }
    west = {
        "The walkway bends to the south; you follow it.\b";
        return nw_walkway;
    }
;

north_walkway_doorway: myDoorway
    adjective = 'scratched'
    location = north_walkway
    ldesc = "It is larger than your average doorway. It is heavily scratched. "
    doordest = balcony
;

balcony: insideRm
    sdesc = "Balcony"
    ldesc = "You have an excellent view of the audience hall from the balcony.
        Benches, which would look somber from the floor below, look forlorn
        from here. Metal bolts in the floor indicate where benches once stood. "
    jumpAction = "Your mild fear of heights overcomes the urge. "
    exits = 'south'
    south = north_walkway
    out = north_walkway
;

metal_bolts: fixedItem
    isThem = true
    noun = 'bolt' 'bolts'
    adjective = 'metal'
    location = balcony
    sdesc = "metal bolts"
    ldesc = "The metal bolts stud the balcony, making for treacherous footing.
        Their spacing and uniformity mark the outlines of the benches they
        once held. "
    takedesc = "Though they could not prevent the benches from being removed,
        their grip on the floor is strong enough to defeat your best efforts. "
    verDoScrew(actor) = { "The bolts refuse to turn. "; }
    doSynonym('Screw') = 'Unscrew' 'Turn'
    verDoPull(actor) = (self.takedesc)
;

ne_walkway: insideRm
    floating_items = [ fake_north_hallway, ne_staircase ]
    nHallFlag = true
    sdesc = "Northeast Walkway"
    ldesc = "The walkway runs along the east wall of the hallway. A sweeping
        staircase joins the walkway to the southwest. "
    exits = 'north, south, and down'
    north = {
        "The walkway curves to the west; you follow it.\b";
        return north_walkway;
    }
    south = se_walkway
    west = north_walkway
    nw = north_walkway
    sw = {
        if (fatherMessage.location != nil)
            fatherMessage.downStairs = true;
        return north_hallway;
    }
    down = { return self.sw; }
    jumpAction = "Your mild fear of heights overcomes the urge. "
;

se_walkway: insideRm
    floating_items = [ fake_south_hallway ]
    sHallFlag = true
    sdesc = "Southeast Walkway"
    ldesc = "The walkway is cut off to the south by the rising walls of the
        foyer. There is a doorway to the east; the walkway continues to the
        north. "
    exits = 'north and east'
    north = ne_walkway
    east = library
    jumpAction = "Your mild fear of heights overcomes the urge. "
;

se_walkway_doorway: myDoorway
    location = se_walkway
    ldesc = "It leads east. "
    lookthrudesc = "You can see books. "
    doordest = library
;

class memory_sentinel: fixedItem
    myHands = nil                // Point this at the sentinel's hinged hands
    noun = 'sentinel' 'statue' 'head' 'body'
    adjective = 'metal' 'dark'
    sdesc = "sentinel"
    ldesc = {
        local cont;

        "A dark metal statue, reminiscent of a prop from Fritz Lang's
            Metropolis.
            A stern, angular head sits atop a sexless body seven feet tall. ";
        if (myHands.areUp)
            "Its hands are held cupped in front of it. ";
        else "Its arms are straight at its sides. ";
        cont = contlist(self.myHands);
        if (length(cont) > 0)
            "In its hands you see <<listlist(cont)>>. ";
    }
    frankiedesc = 'There\'re two of them upstairs. One of our researchers
        claimed that they have some connection to these spheres.'
    verDoMove(actor) = { self.myHands.verDoMove(actor); }
    doMove(actor) = { self.myHands.doMove(actor); }
;

class sentinel_hands: fixedItem
    areUp = nil
    isThem = true
    noun = 'hand' 'hands' 'arm' 'arms'
    adjective = 'metal' 'sentinel' 'sentinel\'s' 'sentinels'
    sdesc = {
        "sentinel's ";
        if (find(objwords(1), 'hand') != nil ||
            find(objwords(1), 'hands') != nil||
            find(objwords(2), 'hand') != nil ||
            find(objwords(2), 'hands') != nil)
            "hands";
        else "arms";
    }
    ldesc = {
        local cont;
        
        "Metal hands, held ";
        if (self.areUp) "cupped in front of the statue. ";
        else "at the sides of the statue. ";
        "The arms to which the hands belong are hinged at the elbow. ";
        cont = contlist(self);
        if (length(cont) > 0)
            "It is holding <<listlist(cont)>>. ";
    }
    verDoMove(actor) = {}
    doMove(actor) = {
        "After a bout of experimentation you discover that you can raise and
            lower the sentinel's hands. ";
    }
    doSynonym('Move') = 'Pull' 'Turn'
    verDoRaise(actor) = {
        if (self.areUp)
            "The sentinel's hands will move no further. ";
    }
    doRaise(actor) = {
        "You pull the sentinel's arms, which slowly move up. As they do they
            come together, until the hands are held cupped in front of the
            statue. ";
        self.areUp = true;
    }
    verDoLower(actor) = {
        if (!self.areUp)
            "The sentinel's hands are as low as they will go. ";
    }
    doLower(actor) = {
        local cont;
        
        "With a modicum of effort you are able to push the sentinel's arms
            back down by its sides. ";
        self.areUp = nil;
        cont = contlist(self);
        if (length(cont) > 0) {
            "The sentinel drops <<cont[1].thedesc>>. ";
            moveAllCont(self, self.location);
        }
    }
    verIoPutOn(actor) = {
        if (length(contlist(self)) > 0)
            "There is no more room in the sentinel's hands. ";
        else if (!self.areUp)
            pass verIoPutOn;
    }
    ioPutOn(actor, dobj) = {
        "You place <<dobj.thedesc>> in the sentinel's hands. ";
        dobj.moveInto(self);
        if (dobj.isSphere) {
            sphereInfoAh.solve;
            self.handleSphere(dobj);
        }
    }
    ioSynonym('PutOn') = 'PutIn'
    showcontents = {
        local list;

        list = contlist(self);
        if (length(list)>0) {
            "In the sentinel's hands you see <<listlist(list)>>. ";
        }
        listfixedcontents(self);
    }
    handleSphere(obj) = {}
;

library: insideRm
    breakerNum = 8
    sdesc = "Library"
    ldesc = {
        "The library is a ";
        if (self.lightsOn)
            "harshly-lit ";
        else "dimly-lit ";
        "backwards L curving around the end of the building. Shelves filled
        with books
        take up much of the room; the rest is inhabited by stacks of books. 
        A metal sentinel guards the west exit; on the other side of the exit
        is a light switch. There is a clock above the sentinel. ";
    }
    exits = 'west'
    west = se_walkway
    out = se_walkway
;

library_lights: ceiling_lights
    mySwitch = library_switch
    location = library;

library_switch: lightswitch
    location = library;

library_clock: wall_clock
    location = library
    timeOfDeath = '10:58'
;

library_sentinel: memory_sentinel
    myHands = library_sentinel_hands
    location = library
;

library_sentinel_hands: sentinel_hands
    location = library
    handleSphere(obj) = {
        if (obj == evil_memory) {
            "The sentinel judders. Its hands lower, dropping the
                sphere onto the floor. ";
            obj.moveInto(self.location);
        }
        else if (single_book.location == nil) {
            "One of the books on the shelves slides out and falls on the floor.
                The other books close in, eliminating the space left by the
                defector. ";
            single_book.moveInto(self.location);
        }
    }
;

library_shelves: decoration
    stage = 1
    isThem = true
    noun = 'shelf'
    plural = 'shelves'
    adjective = 'wooden'
    location = library
    sdesc = "wooden shelves"
    ldesc = "They are stacked back to back in rows running around the room. "
;

books: fixeditem, readable
    stage = 1
    askDisambig = true
    isThem = true
    noun = 'book' 'stack'
    plural = 'books' 'stacks'
    adjective = 'shelved'
    location = library
    sdesc = "shelved books"
    ldesc = "The books resemble case histories from a law library:\ leather
        binding, small type on their spines. "
    takedesc = "You wouldn't know where to begin. "
    smelldesc = "Musty. You take a step backwards, fighting the urge to
        sneeze. "
    readdesc = "You pull one off a shelf at random and open it. You read of a
        dilemma, arguments pro and con, and then of the final decision.
        As you replace the book, you realize that the entire episode seems
        oddly familiar."
    frankiedesc = 'Another group was working on them; I never heard what they
        found out.'
;

single_book: item, readable
    stage = 1
    weight = 10
    bulk = 10
    noun = 'book'
    plural = 'books'
    adjective = 'single'
    sdesc = "single book"
    ldesc = "A large, leather-bound volume with the title \"Attendance
        27914414.\" "
    readdesc = "A long, boring list of back-and-forth arguments about
        attending a party whose purpose is shrouded in jargon. "
    frankiedesc = "\"It sounds exactly like what I need.\" "
;

nw_walkway: insideRm
    breakerNum = 7
    nHallFlag = true
    floating_items = [ fake_north_hallway, nw_staircase ]
    sdesc = "Northwest Walkway"
    ldesc = "The walkway runs along the west wall of the hallway. To the
        southeast, a sweeping staircase meets the hallway from below. \^<<
        closet_door1.aWordDesc>> door is to the west. Above the door is a
        clock. "
    jumpAction = "Your mild fear of heights overcomes the urge. "
    exits = 'north, south, and down'
    north = {
        "The walkway curves to the east; you follow it.\b";
        return north_walkway;
    }
    south = sw_walkway
    east = north_walkway
    west = closet_door1
    ne = north_walkway
    se = {
        if (fatherMessage.location != nil)
            fatherMessage.downStairs = true;
        return north_hallway;
    }
    down = { return self.se; }
;

nw_walkway_clock: wall_clock
    location = nw_walkway
    timeOfDeath = '11:30'
;

closet_door1: doorItem
    stage = 1
    isopen = nil
    location = nw_walkway
    ldesc = "The <<self.wordDesc>> door leads west. "
    doordest = storage_closet
    otherside = closet_door2
;

storage_closet: insideRm
    breakerNum = 7
    noDog = { return !closet_door2.isopen; }
    sdesc = "Storage Closet"
    ldesc = {
        "The tiny closet is dank and has a strange smell. It is
            unfinished; in many places unadorned sheetrock and insulation
            show. The only light in the room comes from ";
        if (self.lightsOn)
            "the bare bulb above you.  Dangling from it is a pull cord. ";
        else {
            if (closet_door2.isopen) "the open";
            else "under the closed";
            " door to the east.  Above you hang a bare bulb and a pull cord. ";
        }
    }
    smelldesc = "You smell an odd mix of mildew and mothballs. "
    exits = 'east'
    east = closet_door2
    out = closet_door2
;

bare_bulb: ceiling_lights
    isThem = nil
    mySwitch = pull_cord
    stage = 1
    noun = 'bulb' 'lightbulb'
    plural = 'bulbs' 'lightbulbs'
    adjective = 'bare' 'light'
    location = storage_closet
    sdesc = "bare lightbulb"
    ldesc = {
        "The bare bulb hangs above you";
        if (self.location.lightsOn)
            ", glowing harshly";
        ". ";
    }
    verDoTouch(actor) = {}
    touchdesc = {
        if (self.location.lightsOn) {
            if (gloves.isworn)
                "You can feel its heat even through the gloves. ";
            else "Yow! You yank back reddened fingers and instinctively suck
                on them. ";
        }
        else "Dead cold. ";
    }
    verDoTurnon(actor) = {}
    doTurnon(actor) = { pull_cord.doPull(actor); }
    verDoTurnoff(actor) = {}
    doTurnoff(actor) = { pull_cord.doPull(actor); }
    verDoSwitch(actor) = {}
    doSwitch(actor) = { pull_cord.doPull(actor); }
;

pull_cord: fixedItem
    stage = 1
    isActive = nil
    noun = 'cord'
    adjective = 'pull'
    location = storage_closet
    sdesc = "pull cord"
    ldesc = "It dangles from the lightbulb overhead, just within reach. "
    verDoPull(actor) = {}
    doPull(actor) = {
        "%You% give the cord a firm tug and are rewarded with a click from
            the lightbulb. ";
        self.isActive = !self.isActive;
        if (breaker_box.hasPower(self.location.breakerNum)) {
            if (self.isActive) {
                "The bulb begins glowing harshly. ";
                self.location.lightsOn = true;
            }
            else {
                "The bulb is snuffed out. ";
                self.location.lightsOn = nil;
            }
        }
        else "Nothing else happens. ";
    }
    doSynonym('Pull') = 'Switch'
    evalSwitch(power) = {
        if (power && self.isActive)
            self.location.lightsOn = true;
        else self.location.lightsOn = nil;
    }
;


sheetrock: fixeditem
    noun = 'sheetrock' 'rock'
    location = storage_closet
    sdesc = "sheetrock"
    ldesc = "It has been haphazardly applied to the studs behind it. "
    takedesc = "Where it has been applied it has been well-anchored to the
        frame, preventing its dislodging. "
;

closet_insulation: thing
    isListed = nil    // Never mentioned in any lists
    tuftsTaken = 0    // Number of insulation tufts taken
    tuftList = []
    noun = 'insulation'
    adjective = 'mass' 'pink' 'fluffy'
    location = storage_closet
    sdesc = "mass of insulation"
    ldesc = {
        insulationClueAh.see;
        "Pink and fluffy, it pokes from ";
        if (self.tuftsTaken == 10) "one or two";
        else if (self.tuftsTaken > 8) "very few";
        else if (self.tuftsTaken > 5) "some";
        " spots in the closet. ";
    }
    touchdesc = {
        if (gloves.isworn) "You feel nothing through the gloves. ";
        else "The merest touch of the stuff sends your hands to itching. ";
    }
    verDoTake(actor) = {
        if (!gloves.isworn) {
            "%You% reach%es% out and grab a tuft of insulation. The tiny
                fibers jab into %your% hands, causing them to burn and itch
                fiercely. %Your% hands open involuntarily, leaving the
                insulation undisturbed. ";
            insulationClueAh.see;
            insulationAh.see;
        }
        else if (self.tuftsTaken == 10)
            "There aren't any more sizable tufts to grab. ";
    }
    doTake(actor) = {
        local o, totbulk, totweight;

        o = new insulation_tuft;

        insulationClueAh.see;

        totbulk = addbulk(actor.contents) + o.bulk;
        totweight = addweight(actor.contents) + o.weight;

        if (totweight > actor.maxweight) {
            "%Your% load is too heavy. ";
            delete o;
            return;
        }
        if (totbulk > actor.maxbulk && !makeRoom(actor, self)) {
            "%You've% already got %your% hands full. ";
            delete o;
            return;
        }
        o.moveInto(actor);
        "%You% rip%s% off a tuft of the insulation. ";
        insulationAh.solve;
        self.tuftsTaken++;
        self.tuftList += o;
        if (self.tuftsTaken == 1) {
            incscore(2);
        }
    }
    verDoTakeOut(actor, io) = {
        "%You% can't take the mass of insulation out of anything. ";
    }
    verDoDrop(actor) = {
        "%You% can't drop the mass of insulation. ";
    }
    verDoTakeOff(actor, io) = {
        self.verDoTakeOut(actor, io);
    }
    verDoPutOn(actor, io) = {
        "%You% can't put the mass of insulation anywhere. ";
    }
    verDoMove(actor) = {
        "%You% can't move the mass of insulation. ";
    }
    verDoThrowAt(actor, io) = {
        "%You% can't throw the mass of insulation.";
    }
    verDoPutIn(actor, io) = {
        "%You% can't take the whole mass of insulation. ";
    }
    verDoEat(actor) = {
        "Despite its resemblance to cotton candy, the insulation is inedible. ";
    }
    cleanUp = {
        local i;

        for (i = 0; i <= length(self.tuftsList); i++)
            delete self.tuftsList[i];
        self.tuftsList = [];
    }
;

class insulation_tuft: item
    isEquivalent = true
    isInsulation = true
    weight = 1
    bulk = 2
    noun = 'insulation' 'tuft'
    plural = 'tufts'
    adjective = 'tuft' 'pink' 'fluffy'
    sdesc = "tuft of insulation"
    ldesc = "Pink and fluffy. "
    pluraldesc = "tufts of insulation"
    touchdesc = {
        if (gloves.isworn) "You feel nothing through the gloves. ";
        else "The merest touch of the stuff sends your hands to itching. ";
    }
    verDoTake(actor) = {
        if (!gloves.isworn)
            "%You% reach%es% out and grab the tuft of insulation. The tiny
                fibers jab into %your% hands, causing them to burn and itch
                fiercely. %Your% hands open involuntarily, leaving the
                insulation undisturbed. ";
        else pass verDoTake;
    }
    verDoDrop(actor) = {
        if (!actor.isCarrying(self))
            "%You're% not carrying the tuft of insulation. ";
        else if (!gloves.isworn)
            self.verDoTake(actor);
        else self.verifyRemove(actor);
    }
    verDoEat(actor) = { "The thought is enough to make your lips itch. "; }
    doSynonym('Eat') = 'Kiss'
;

closet_door2: doorItem
    stage = 1
    isopen = nil
    location = storage_closet
    ldesc = "The <<self.wordDesc>> door leads east. "
    lookthrudesc = "You catch a glimpse of the walkway. "
    doordest = nw_walkway
    otherside = closet_door1
;

sw_walkway: insideRm
    sHallFlag = true
    floating_items = [ fake_south_hallway ]
    sdesc = "Southwest Walkway"
    ldesc = "The walkway ends to the south in a blank wall. A doorway to the
        west and the remainder of the walkway to the north allow egress. "
    jumpAction = "Your mild fear of heights overcomes the urge. "
    exits = 'north and west'
    north = nw_walkway
    west = cabinet_room
;

sw_walkway_doorway: myDoorway
    location = sw_walkway
    ldesc = "It leads west. "
    lookthrudesc = "You can see filing cabinets. "
    doordest = cabinet_room
;

cabinet_room: insideRm
    breakerNum = 6
    sdesc = "Filing Office"
    ldesc = {
        "Rows of filing cabinets divide the room into sections. ";
        if (self.lightsOn)
            "Light glints from metal which";
        else "Metal";
        " rises from floor to ceiling. Drawer after drawer stare at you, none
            of them labelled";
        if (single_drawer.location == self)
            ", one of them open";
        ". The exit to the east is barely visible due to the
            metal sentinel partially blocking it. The clock above the
            exit, however, is plainly visible from anywhere in the
            room, a feat which is nothing short of miraculous. ";
    }
    exits = 'east'
    east = sw_walkway
    out = sw_walkway
;

cabinet_lights: ceiling_lights
    mySwitch = cabinet_switch
    location = cabinet_room;

cabinet_switch: lightswitch
    location = cabinet_room;

cabinet_clock: wall_clock
    location = cabinet_room
    timeOfDeath = '11:07'
;

cabinet_sentinel: memory_sentinel
    myHands = cabinet_sentinel_hands
    location = cabinet_room
;

cabinet_sentinel_hands: sentinel_hands
    location = cabinet_room
    handleSphere(obj) = {
        if (obj == evil_memory) {
            "A shudder wracks the sentinel. Its hands lower, dropping the
                sphere onto the floor. ";
            obj.moveInto(self.location);
        }
        else if (single_drawer.location == nil) {
            "A drawer in one of the cabinets silently opens. ";
            single_drawer.moveInto(self.location);
        }
    }
;

filing_cabinets: fixedItem
    isThem = true
    noun = 'cabinet' 'cabinets'
    adjective = 'metal' 'filing'
    location = cabinet_room
    sdesc = "filing cabinets"
    ldesc = "The sheer number of filing cabinets boggles the mind. "
    doOpen -> filing_cabinet_drawers
;

filing_cabinet_drawers: fixedItem
    isThem = true
    noun = 'drawer' 'drawers' 'slot' 'slots'
    adjective = 'cabinet'
    location = cabinet_room
    sdesc = "cabinet drawers"
    ldesc = {
        "Each drawer has an empty slot where an identifying card should be. ";
        if (single_drawer.location == cabinet_room)
            "One of the drawers is open. ";
    }
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You try several cabinet drawers. All are locked. ";
    }
    verDoClose(actor) = { "They are already closed. "; }
;

single_drawer: fixedItem, container
    maxbulk = 20
    noun = 'drawer'
    adjective = 'open'
    sdesc = "open drawer"
    ldesc = {
        local cont;

        "An open cabinet drawer. ";
        cont = contlist(self);
        if (length(cont) > 0)
            "In the drawer %you% see%s% <<listlist(cont)>>. ";
    }
    verDoOpen(actor) = { "It is already open. "; }
    verDoClose(actor) = {}
    doClose(actor) = {
        if (lone_memory.location == cabinet_sentinel_hands)
            "You push the drawer closed, but it opens as soon as you let go. ";
        else {
            "The drawer smoothly slides shut. ";
            self.moveInto(nil);
            setit(nil);
        }
    }
;

connection_list: item, readable
    weight = 7
    bulk = 10
    noun = 'list' 'paper'
    adjective = 'fanfold' 'long'
    location = single_drawer
    sdesc = "long list"
    ldesc = "The list is printed on a stack of fanfold paper almost five
        centimeters thick. On the top sheet is the number \"27914414.\"
        Below it are a list of words and numbers:\ \"cake 739424\ \ 
        games 598384\" and so on. "
    frankiedesc = 'I think I could use it in my research.'
;

// All snowrooms have two descriptions: one if you're snowblind, the other
//  if you're wearing the sunglasses and thus can see.
class snowroom: room
    isSnowRoom = true
    noDog = true        // The dog can't wander in here
    printsNumber = 0    // Number of footprints
    floating_items = [snow, snowprints, snowy_building]
    leaveList = [snowDaemon]
    listendesc = {
        if (snowDaemon.avalancheOn)
            "A rumbling can just be heard over";
        else "You hear";
        " the hiss of falling snow.";
    }
    lookAround( verbosity ) = {
        self.statusLine;
        if (sunglasses.isworn) {
            snowblindAh.solve;
            self.nrmLkAround(verbosity);
        }
        else if (verbosity) {
            snowblindAh.see;
            "\n\t<<self.blinddesc>>\n";
        }
        self.kludge;
    }
    kludge = {}
    exits = {
        if (sunglasses.isworn)
            "You can go <<self.exitList>>. ";
        else "You cannot tell through the glare. ";
    }
    roomAction(a, v, d, p, i) = {
        if (!sunglasses.isworn) {
            if ((v.sight && v != lookVerb) || v == iVerb) {
                "You can see nothing through the horrible glare.\n";
                exit;
            }
            if (v == takeVerb) {
                "You fumble around blindly in the snow, but cannot find what
                    you seek.\n";
                exit;
            }
        }
        pass roomAction;
    }
    up = { "You can't go that way. "; return nil; }
    down = self.up
    noexit = { "The snow is impassable in that direction. "; return nil; }
;

snow: wallpaper, decoration
    stage = 1
    noun = 'snow' 'ice'
    sdesc = "snow"
    ldesc = "The snow covers everything you see in a fine layer of white.
        It looks to have been falling for hours. "
    takedesc = "You scoop up some of the snow, then realize that you have
        no way to contain it without it melting. "
    frankiedesc = "\"Here already? The avalanche can't be far behind.\" "
    verDoEat(actor) = {
        "You dance about delightedly, catching snowflakes on your tongue,
            until you tire of the sport. ";
    }
    verIoAskAbout(actor, dobj) = {}
;

snowprints: wallpaper, decoration
    isThem = true
    noun = 'footprint' 'track' 'print'
    plural = 'footprints' 'tracks' 'prints'
    sdesc = "footprints"
    ldesc = {
        local num = Me.location.printsNumber;

        "Pressed down in the snow <<num > 1 ? "are" : "is">> ";
        switch (num) {
            case 1:
                "a"; break;
            case 2:
                "two"; break;
            case 3:
                "three"; break;
            default:
                "countless"; break;
        }
        " track<<num > 1 ? "s" : "">> of footprints. ";
    }
;

snowy_building: wallpaper, decoration
    stage = 1
    sdesc = "building"
    noun = 'building' 'column'
    plural = 'columns'
    adjective = 'marble'
    ldesc = {
        "The building's white marble is now covered with snow. Only
            a few discolored trails indicate where rain recently sluiced
            over its surface. ";
        if (Me.location == snowy_front_of_bldg)
            "Its entrance lies open to the north. ";
        else if (Me.location == breaker_box.location) {
            "Bolted to its side is a grey box. ";
            breaker_box.has_hdesc = true;
        }
    }
    verDoEnter(actor) = {
        if (actor.location != snowy_front_of_bldg)
            "You cannot enter from this side of the building. ";
    }
    doEnter(actor) = {
        actor.travelTo(foyer);
    }
;

// snowDaemon, which takes care of making the player cold. coldTurns counts
//  how long the player has been exposed. See GripSTD.t for more details.
//  leaving() is called by each snowroom when the player leaves. It
//  increments printsNumber, which counts the footprint tracks.
snowDaemon: object
    wantheartbeat = nil
    mentionCoat = 0  // Set to 1 to mention windy coat, 2 to mention partially
                     // full coat, 3 to mention full coat, -1 to show that the
                     // coat has been mentioned
    givenPoints = nil    // For giving points to the player
    avalancheOn = nil    // Is the avalanche going?
    heartbeat = {
        coldAh.see;
        if (self.mentionCoat > 0) {
            switch (self.mentionCoat) {
                case 1:
                "\bThe wind slices through your coat, belying its status as a
                    \"windbreaker.\"\n";
                Me.coldTurns++;
                break;

                case 2:
                "\bThe coat offers limited protection from the wind.\n";
                Me.coldTurns -= 5;
                break;

                case 3:
                "\bThe wind beats futilely against your ";
                if (!self.givenPoints) {
                    "now-warm ";
                    self.givenPoints = true;
                    incscore(5);
                    coldAh.solve;
                }
                "coat.\n";
            }
            self.mentionCoat = -1;
            return;
        }
        if (coat.isworn && coat.tuftNumber == 3) return;
        if (Me.location.isSnowRoom) {
            Me.coldTurns++;
            switch (Me.coldTurns) {
                case 1:
                    "\bYou begin to feel the cold seep into you, chilling
                        you.\n";
                    break;
                case 4:
                    "\bThe cold is becoming worse, making your fingers slow to
                        work";
                    if (gloves.isworn)
                        " despite the gloves";
                    ".\n";
                    break;
                case 7:
                    "\bYour eyelids are becoming gummed. It is now a struggle
                        to keep moving.\n";
                    break;
                case 8:
                    "\bStrangely enough, you are no longer cold. The
                        enveloping warmth you now feel is soothing.\n";
                    break;
                case 9:
                    "\bYou sink to the ground, lassitude overcoming you. Just
                        a rest, you think, and then onward.\b";
                    die();
                    exit;
                default:
            }
        }
        else {
            Me.coldTurns--;
            if (Me.coldTurns == 0) {
                "\bYou now feel recovered from your exposure to the
                    cold.\n";
                self.wantheartbeat = nil;
            }
            else if (Me.coldTurns < 0) {
                Me.coldTurns = 0;
                self.wantheartbeat = nil;
            }
            else if (Me.coldTurns == 7)
                "\bYou feel cold now in comparison to the warmth around
                    you.\n";
            else if (Me.coldTurns == 3)
                "\bYour hands are working again, albeit a little stiffly.\n";
        }
    }
    leaving(actor) = {
        actor.location.printsNumber++;
        if (actor.location.printsNumber < 4) // Stay on or get off?
             return nil;                     // Stay on the list
        else return true;                    // Get off the list
    }
;

snowy_front_of_bldg: snowroom
    greyManSeen = nil
    sdesc = "Front of Building"
    blinddesc = "You can see little through the glare of sun on snow. The
        building to the north is just visible, but everything else is a wash
        of bright white. "
    ldesc = {
        "The building to the north is now covered with snow. Under
            your feet it squeaks with the sound of deep-seated ice.
            To the northeast and northwest the snow is somewhat thinner, due
            to the building's protection. ";
        if (self.printsNumber > 0)
            "Pressed down in the ice and snow are tracks of footprints. ";
    }
    exitList = 'north, northeast, and northwest'
    firstseen = {
        findBreakersAh.see;
    }
    enterRoom(actor) = {
        if (coat.isworn &&
                snowDaemon.mentionCoat != -1) { // -1 == coat was mentioned
            if (coat.tuftNumber == 0)
                snowDaemon.mentionCoat = 1;
            else if (coat.tuftNumber < 3)
                snowDaemon.mentionCoat = 2;
            else if (coat.tuftNumber == 3)
                snowDaemon.mentionCoat = 3;
        }
        snowDaemon.wantheartbeat = true;
        inherited.enterRoom(actor);
        if (!junction_box.isActive || self.greyManSeen) return;
        self.greyManSeen = true;
        "\b";
        if (!sunglasses.isworn)
            "Through the glare you can make out a man striding through the
                snow to the south. ";
        else "To the south you see a man striding through the snow. ";
        "He is completely grey, as if all color had been leeched from him
            long ago, a black and white image in a world of technicolor.
            He pauses, stares at you, then continues on until he is lost
            in the distance. You feel a sudden chill. ";
        notify(fatherMessage, &prepare1, 2);
        setfuse(&rollAvalanche, 2, 1);
    }
    north = foyer
    ne = snowy_east_side
    nw = snowy_west_side
;

snowy_east_side: snowroom
    firstSeen = 0
    sdesc = "East of Building"
    blinddesc = "The building's shadow gives some relief from the glare,
        but not enough to let you see anything. "
    ldesc = {
        "The building looms to the west, shadowing the path which leads
            north and south. ";
        if (self.printsNumber > 0)
            "Pressed down in the snow are tracks of footprints. ";
        if (self.firstSeen == 0) {
            self.firstSeen = 1;
            "\n\ \ \ Something on the building catches your eye. ";
        }
    }
    listendesc = {
        if (breakers.numberOn == 6)
            "You hear a faint hum eminating from the building. ";
        else pass listendesc;
    }
    exitList = 'north, south, and southwest'
    kludge = {
        if (self.firstSeen != 1) return;
        doctorMessage.setup('I\'m going to try removing the IV. Prep exam
            room two; I\'ll round up equipment. Turn the monitors up
            so we\'ll hear if anything goes wrong.');
        "\bThe air just above you begins shimmering. From the disturbance
            falls a smallish cube. ";
        doctorMessage.moveInto(self);
        self.firstSeen = 2;
    }
    north = snowy_ne_side
    south = snowy_front_of_bldg
    west = {
        "You run into the side of the building, scattering snow. ";
        return nil;
    }
    sw = snowy_front_of_bldg
;

breaker_box: fixedItem, openable
    stage = 1
    hasPower(breakerNum) = {
        return (breakers.breakersOn[breakerNum] && !breakers.isFried);
    }
    isopen = nil
    noun = 'box'
    plural = 'boxes'
    adjective = 'breaker' 'grey' 'gray'
    location = snowy_east_side
    sdesc = "breaker box"
    ldesc = {
        "The gunmetal-grey box is attached to the side of the building,
            marring its otherwise smooth surface. ";
        if (self.isopen)
            "Its cover is open, revealing a row of breakers inside and
                a list taped to the box door. ";
    }
    hdesc = "On the side of the building is a grey box. "
    has_hdesc = nil
    doOpen(actor) = {
        if (sunglasses.isworn)
            "Opening the box reveals a row of breakers and a list. ";
        else "You fumblingly open the breaker box. ";
        self.isopen = true;
        findBreakersAh.solve;
        turnOnBreakersAh.see;
    }
    verDoLookin(actor) = {
        if (!sunglasses.isworn)
            "You can see nothing through the glare. ";
    }
    doLookin(actor) = {
        if (!self.isopen) {
            "(Opening the box)\n";
            self.isopen = true;
            findBreakersAh.solve;
            turnOnBreakersAh.see;
        }
        "Inside the box are a row of breakers and a list. ";
    }
    frankiedesc = 'The breaker box controls the power to this building.'
    doSmell -> breakers
    doListenTo -> breakers
;

breaker_list: fixedItem, readable
    noun = 'list'
    adjective = 'breaker'
    location = breaker_box
    sdesc = "list"
    ldesc =
         "\ \ 1:\ Box Office\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 5:\ Archives
        \n\ \ 2:\ Balance Room\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 6:\ Filing Office
        \n\ \ 3:\ Audience Hall\ \ \ \ \ \ \ \ \ \ \ \ \ \ 7:\ Storage Closet
        \n\ \ 4:\ Preparatory Room\ \ \ \ \ \ \ \ \ \ \ 8:\ Library"
;

breakers: fixedItem, dthing
    isThem = true
    givenPoints = nil        // Have I given points yet?
    breakersOn = [nil, nil, nil, nil, nil, nil, nil, nil]
    numberOn = 0
    switchList = [office_switch, balance_room_switch, audience_switch,
        prep_room_switch, archive_switch, cabinet_switch, pull_cord,
        library_switch]
    switchOrder = [2, 8, 6, 7, 4, 3, 5, 1]
    isFried = nil
    noun = 'breakers'
    adjective = 'row'
    location = breaker_box
    sdesc = "row of breakers"
    pluraldesc = "breakers"
    firstdesc = {
        self.seconddesc;
        "\n[You may refer to the individual breakers by \"<number>
            breaker\" or simply by their number.] ";
    }
    seconddesc = {
        "There are eight breakers, arranged in two rows of four. ";
        if (self.isFried)
            "The breakers look charred, as if raked by fire. ";
    }
    listendesc = {
        if (self.numberOn == 8)
            "You hear a hum rising from somewhere behind the box. ";
        else pass listendesc;
    }
    smelldesc = {
        if (self.isFried) "You smell ozone eminating from the breakers. ";
        else pass smelldesc;
    }
    verDoSwitch(actor) = { "You'll have to be more specific. "; }
    doSynonym('Switch') = 'Turnon' 'Turnoff' 'Flip' 'Throw'
    ioAskAbout -> breaker_box
    //turnedOn & turnOff return true if everything's ok, nil otherwise
    turnedOn(num) = {
        if (self.isFried) return nil;
        if (num != self.switchOrder[++self.numberOn]) {
            ". There is a loud pop and sparks fly from the breakers. You
                shield your eyes instinctively, but the display is over
                quickly";
            self.fry;
            return nil;
        }
        self.switchList[num].evalSwitch(true);
        if (self.numberOn == 8) {
            " with a satisfying click. A basso hum rises, then falls
                away. ";
            if (!self.givenPoints) {
                self.givenPoints = true;
                incscore(5);
                turnOnBreakersAh.solve;
            }
            exit;
        }
        return true;
    }
    turnedOff(num) = {
        if (self.isFried) return nil;
        if (num != self.switchOrder[self.numberOn--]) {
            ". There is a loud pop and sparks fly from the breakers. You
                shield your eyes instinctively, but the display is over
                quickly";
            self.fry;
            return nil;
        }
        self.switchList[num].evalSwitch(nil);
        if (self.numberOn == 7) {
            " with a satisfying click.  A hum you had not realized was
                present fades away. ";
            junction_box.isActive = nil; // Make sure junction box is off
            exit;
        }
        return true;
    }
    // Someone messed up, and now the board fries...
    fry = {
        local i;

        for (i = 1; i <= 8; i++)
            self.switchList[i].evalSwitch(nil);
        self.isFried = true;
        self.numberOn = 0;
        junction_box.isActive = nil;    // Make sure junction box is off
    }
;

class single_breaker: fixedItem
    stage = 1
    noun = 'breaker' 'switch'
    location = breaker_box
    ldesc = {
        "The breaker is currently <<breakers.breakersOn[self.num] ?
            "on" : "off">>. ";
    }
    doSmell -> breakers
    doListenTo -> breakers
    verDoSwitch(actor) = {
        if (!sunglasses.isworn)
            "You can't see well enough to do that. ";
    }
    doSwitch(actor) = {
        if (breakers.breakersOn[self.num])
            self.doTurnoff(actor);
        else self.doTurnon(actor);
    }
    doSynonym('Switch') = 'Flip' 'Throw'
    ioAskAbout -> breaker_box
    verDoTurnon(actor) = {
        if (breakers.breakersOn[self.num])
            "That breaker is already on. ";
        else if (!sunglasses.isworn)
            "You can't see well enough to do that. ";
    }
    doTurnon(actor) = {
        breakers.breakersOn[self.num] = true;
        "You flip the breaker on";
        if (breakers.turnedOn(self.num))
            " with a satisfying click";
        ". ";
    }
    verDoTurnoff(actor) = {
        if (!breakers.breakersOn[self.num])
            "That breaker is already off. ";
        else if (!sunglasses.isworn)
            "You can't see well enough to do that. ";
    }
    doTurnoff(actor) = {
        breakers.breakersOn[self.num] = nil;
        "You turn off the breaker";
        if (breakers.turnedOff(self.num))
            " with a satisfying click";
        ". ";
    }
;

breaker1: single_breaker
    num = 1
    adjective = 'one' '1' 'first'
    sdesc = "first breaker"
;

breaker2: single_breaker
    num = 2
    adjective = 'two' '2' 'second'
    sdesc = "second breaker"
;

breaker3: single_breaker
    num = 3
    adjective = 'three' '3' 'third'
    sdesc = "third breaker"
;

breaker4: single_breaker
    num = 4
    adjective = 'four' '4' 'fourth'
    sdesc = "fourth breaker"
;

breaker5: single_breaker
    num = 5
    adjective = 'five' '5' 'fifth'
    sdesc = "fifth breaker"
;

breaker6: single_breaker
    num = 6
    adjective = 'six' '6' 'sixth'
    sdesc = "sixth breaker"
;

breaker7: single_breaker
    num = 7
    adjective = 'seven' '7' 'seventh'
    sdesc = "seventh breaker"
;

breaker8: single_breaker
    num = 8
    adjective = 'eight' '8' 'eighth'
    sdesc = "eighth breaker"
;

snowy_west_side: snowroom
    sdesc = "West of Building"
    blinddesc = "Through slitted eyelids you can vaguely make out the building
        to the east. "
    ldesc = {
        "To the east, the building glitters in the sun. A wind-swept path
            runs north and south. ";
        if (self.printsNumber > 0)
            "Pressed down in the snow are tracks of footprints. ";
    }
    exitList = 'north and southeast'
    north = snowy_nw_side
    south = snowy_front_of_bldg
    east = {
        "You run into the side of the building, scattering snow. ";
        return nil;
    }
    se = snowy_front_of_bldg
;

snowy_ne_side: snowroom
    sdesc = "Hillside"
    blinddesc = "You can sense the ground sloping up to the north. To the
        south the ground drops, then levels. "
    ldesc = {
        "To the north, the ground suddenly rises into tree-speckled
            heights. ";
        if (snowDaemon.avalancheOn)
            "From those heights you see snow gracefully piling towards you. ";
        "To the south, the building's shape breaks the smooth
            white carpet of the ground. Partially buried in the snow is
            a large post. ";
        if (self.printsNumber > 0)
            "Pressed down in the snow are many footprints. ";
    }
    exitList = 'south and west'
    north = { "The hill rises at too steep a gradient. "; return nil; }
    ne = { return self.north; }
    nw = { return self.north; }
    south = snowy_east_side
    west = snowy_n_side
    leaveRoom(actor) = {    // Can't leave with the wires
        if (fence_cable.location == actor || post_cable.location == actor) {
            "Not while you are holding a cable. ";
            exit;
        }
        pass leaveRoom;
    }
;

post: fixeditem
    stage = 1
    noun = 'post'
    adjective = 'large' 'wooden' 'square'
    location = snowy_ne_side
    sdesc = "square post"
    ldesc = "Its square outline thrusts skywards from the snow. A dark
        line in the snow runs beside it, northwest to southeast. From the
        line a cable issues. The cable's twin dangles from the post, then
        scurries down its length and into the snow on the side of the post
        opposite the line. "
    verIoTieTo(actor) = {}
;

nw_se_dark_line: fixeditem
    firstLdesc = true
    noun = 'line' 'fence'
    adjective = 'dark' 'wooden' 'mottled'
    location = snowy_ne_side
    sdesc = "wooden fence"
    ldesc = {
        self.firstLdesc = nil;
        if (find(objwords(1), 'line'))
            "You peer down into the dark line and discover a mottled wooden
                fence lying flat in its depths. ";
        else {
            "The fence runs northwest to southeast. It looks to be intact
                despite the weather. From somewhere near the bottom of
                it, buried deep, a cable runs. ";
        }
        fenceAh.see;
    }
    frankiedesc = "Frankie shrugs. \"It was on our to-do list. Too bad we
        never got around to it:\ it could have protected us from the
        avalanche.\" "
    verDoDig(actor) = { "There is too much snow and too much buried fence. "; }
    verIoTieTo(actor) = {}
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (find(objwords(1), 'line'))
            self.ldesc;
        else "There is nothing in the wooden fence. ";
    }
;

// To keep the player from being able to "touch cables," for instance.
plural_cables: fixedItem
    stage = 1
    isListed = nil
    noun = 'cables' 'wires'
    location = snowy_ne_side
    sdesc = "cables"
    ldesc = "You can only specify one cable at a time. "
    dobjGen(a, v, i, p) = {
        if (v != inspectVerb && !(v.issysverb)) {
            "You must specify each cable in turn. ";
            exit;
        }
        else if (v == inspectVerb) {
            "lower cable: <<fence_cable.ldesc>>\n
             upper cable: <<post_cable.ldesc>>";
            exit;
        }
    }
    iobjGen(a, v, d, p) = { self.dobjGen(a, v, d, p); }
;

fence_cable: thing
    stage = 1
    isListed = nil
    noun = 'cable' 'wire'
    adjective = 'lower'
    location = snowy_ne_side
    sdesc = "lower cable"
    adesc = "the lower cable"
    ldesc = {
        "It runs from somewhere ";
        if (nw_se_dark_line.firstLdesc)
            "in the line in the snow";
        else "near the bottom of the fence";
        " to about thirty centimeters above the snow. Its end is frayed,
            showing bare wire. ";
    }
    verDoTake(actor) = {
        if (self.location == actor)
            "You're already holding the lower cable. ";
    }
    doTake(actor) = {
        "You reach down and grab hold of the bare end of the cable. The
            wire ";
        if (gloves.isworn)
            "rasps against your gloves";
        else "rubs against your hand";
        ". ";
        self.isListed = true;
        self.moveInto(actor);
    }
    verDoDrop(actor) = {
        if (self.location != actor)
            "You're not holding the lower cable. ";
    }
    doDrop(actor) = {
        "You let go, allowing the taut lower cable to relax. ";
        self.isListed = nil;
        self.moveInto(snowy_ne_side);
    }
    verIoTieTo(actor) = {}
    verDoTieTo(actor, io) = {
        if (io == post_cable)
            "The two cables are too short to reach each other. ";
        else pass verDoTieTo;
    }
    verDoAttachTo(actor, io) = {
        if (io == post_cable)
            "The two cables are too short to reach each other. ";
        else pass verDoAttachTo;
    }
    verIoAttachTo(actor) = {}
    verDoPull(actor) = {
        "The cable stretches, but remains attached to the fence. When you let
            go, it relaxes to its former length. ";
    }
    verDoPutIn(actor, io) = {
        "The cable is too short to put anywhere. ";
    }
    doSynonym('PutIn') = 'PutOn'
;

post_cable: thing
    stage = 1
    isListed = nil
    noun = 'cable' 'wire'
    adjective = 'upper' 'orange' 'bare'
    location = snowy_ne_side
    sdesc = "upper cable"
    adesc = "the upper cable"
    ldesc = "It begins partway up the post and is lashed to it. The cable runs
        over the top of the post, down the other side, then plunges into
        the snow, heading towards the building. Some of its orange insulation
        has been stripped, leaving behind a section of bare wire. "
    touchdesc = {
        local flag;
        
        flag = (self.location == snowy_ne_side);
        self.doTake(Me);
        if (flag) {
            self.moveInto(snowy_ne_side);
            self.isListed = nil;
        }
    }
    verDoTake(actor) = {
        if (self.location == actor)
            "You're already holding the upper cable. ";
    }
    doTake(actor) = {
        "You reach up and grab hold of the bare end of the cable. The
            wire ";
        if (junction_box.isActive) {
            "writhes in your grasp as a surge of electricity passes through
                you and into the ground";
            if (fence_cable.location == actor) {
                " and the cable in your other hand. Through a blue haze you
                    see snow fly as the fence raises up, forming a caret on
                    the hillside above the building. ";
                if (avalanche.location != nil) {
                    "\bThe avalanche bears down upon it, then is
                        shunted to either side of the building. ";
                    if (fatherMessage.location != nil)
                        "Over the crackling of the avalanche you hear an
                            eerily familiar voice say, \"Ah, well. Perhaps
                            next time.\" Despite this, a";
                    else "A";
                    " sense of
                        peace fills you even as you jerk in a Saint
                        Vitus' dance.\n";
                    pauseAndClear();
                    "\b\(Interlude\)\b\b";
                    sunglasses.moveInto(rucksack);
                    sunglasses.isworn = nil;
                    gloves.isworn = nil;
                    moveAllCont(Me, nil);
                    avalancheAh.solve;
                    coldAh.solve;
                    sphereAh.solve;
                    dog.clearProps;
                    dog.wantheartbeat = nil;
                    arms.moveInto(Me);
                    hands.moveInto(Me);
                    monitor_leads.moveInto(Me);
                    monitor_leads.isworn = true;
                    monitorsAh.see;
                    hideAh.see;
                    hide1Ah.see;
                    hide2Ah.see;
                    Me.stage = '0';
                    Me.travelTo(padded_chair);
                    op_theatre.enterRoom(Me);
                    remfuse(&rollAvalanche, 2);    // Get rid of all
                    remfuse(&rollAvalanche, 3);    //  avalanches
                    snowDaemon.wantheartbeat = nil;//  and cold messages
                    unnotify(fatherMessage, &giveMessage);
                    unnotify(fatherMessage, &breathe);
                    setfuse(withdrawal, 5 + RAND(2), 1);
                    exit;
                }
            }
            else ". Sparks leap gleefully between your rigid fingers, between
                you and the post, between you and the lower cable. For a
                moment, improbably, you are a living Jacob's ladder. ";
            "You begin to lose consciousness as your clothes
                smoulder, then burst into flames.\bThe pain is mercifully
                brief.\b";
            die();
        }
        if (gloves.isworn)
            "rasps against your gloves";
        else "rubs against your bare hand";
        ". ";
        self.isListed = true;
        self.moveInto(actor);
    }
    verDoDrop(actor) = {
        if (self.location != actor)
            "You're not holding the upper cable. ";
    }
    doDrop(actor) = {
        "Done. ";
        self.isListed = nil;
        self.moveInto(snowy_ne_side);
    }
    verDoUntie(actor) = {
        "No matter how hard you tug, you are unable to free the cable from
            the post. ";
    }
    verDoTakeOut(actor, io) = {
        if (io == post)
            self.verDoUntie(actor);
        else pass verDoTakeOut;
    }
    verIoTieTo(actor) = {}
    verDoTieTo(actor, io) = {
        if (io == fence_cable)
            "The two cables are too short to reach each other. ";
        else pass verDoTieTo;
    }
    verDoAttachTo(actor, io) = {
        if (io == fence_cable)
            "The two cables are too short to reach each other. ";
        else pass verDoAttachTo;
    }
    verIoAttachTo(actor) = {}
    verDoPull(actor) = {
        "It is too tightly lashed to the post:\ it goes nowhere. ";
    }
    verDoPutIn(actor, io) = {
        "The cable is too short to put anywhere. ";
    }
    doSynonym('PutIn') = 'PutOn'
;

snowy_trees: distantItem
    stage = 1
    isThem = true
    noun = 'tree'
    plural = 'trees'
    adjective = 'snowy'
    location = snowy_ne_side
    sdesc = "trees"
    ldesc = "They dot the hillside above, layered in thick snow. "
;

post_insulation: decoration
    noun = 'insulation'
    adjective = 'orange'
    location = snowy_ne_side
    sdesc = "orange insulation"
    ldesc = "It covers the upper cable. "
;

snowy_nw_side: snowroom
    sdesc = "Hillside"
    blinddesc = "You can sense the ground sloping up to the north. To the
        south, the ground drops, then levels. "
    ldesc = {
        "The hill undulates, then rises steeply to the north. A path leads
            south past the building. A dark line running northeast to
            southwest mars the pristine white of the ground. ";
        if (self.printsNumber > 0)
            "In many places, footprints dot the snow. ";
        if (snowDaemon.avalancheOn)
            "Above you, further to the north, you see a mass of snow bearing
                down upon you. ";
    }
    exitList = 'south and east'
    north = { "The hill rises too steeply. "; return nil; }
    ne = { return self.north; }
    nw = { return self.north; }
    south = snowy_west_side
    east = snowy_n_side
;

ne_sw_dark_line: fixeditem
    contentsVisible = true
    contentsReachable = true
    noun = 'line' 'fence'
    adjective = 'dark' 'wooden' 'mottled'
    location = snowy_nw_side
    sdesc = "wooden fence"
    ldesc = {
        if (find(objwords(1), 'line'))
            "You peer down into the dark line and discover a mottled wooden
                fence lying flat in its depths. ";
        else {
            "The fence runs northeast to southwest. It looks to be intact
                despite the weather. ";
            if (rope.location == self) {
                if (rope.tiedTo != nil) "Tied to";
                else "Lying on";
                " the fence is a rope. ";
            }
        }
        fenceAh.see;
    }
    verDoDig(actor) = { "There is too much snow and too much buried fence. "; }
    verIoTieTo(actor) = {}
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (find(objwords(1), 'line'))
            self.ldesc;
        else "There is nothing in the wooden fence. ";
    }
;

rope: moveItem
    tiedTo = ne_sw_dark_line
    noun = 'rope'
    adjective = 'length'
    location = ne_sw_dark_line
    weight = 4
    bulk = 3
    sdesc = "rope"
    adesc = "a length of rope"
    ldesc = {
        "Hemp fibers twisted around each other. ";
        if (self.tiedTo != nil)
            "It is tied to <<self.tiedTo.thedesc>>. ";
        if (self.location == crawl_pulley)
            "It is looped over a pulley. ";
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
    firstMove = {
        ropeAh.see;
    }
    verDoPutIn(actor, io) = {
        if (self.tiedTo != nil)
            "Not while the rope is tied to anything. ";
    }
    verDoCutWith(actor, io) = {
        "No matter how you saw at the rope with <<io.thedesc>>, the strands
            refuse to part. ";
    }
    verIoCutIn(actor) = {}
    ioCutIn(actor, dobj) = (self.verDoCutWith(actor, dobj))
    verDoTieTo(actor, io) = {
        if (self.location != actor && !(self.location == crawl_pulley &&
            io == steel_plate))
            "You must be holding the rope in your hands before you can tie
                it to anything. ";
        else if (self.tiedTo != nil)
            "The rope is already tied to <<self.tiedTo.thedesc>>. ";
    }
    doTieTo(actor, io) = {
        "You tie the rope to <<io.thedesc>>. ";
        self.tiedTo = io;
    }
    doSynonym('TieTo') = 'AttachTo'
    verDoUntie(actor) = {
        if (self.tiedTo == nil)
            "It's not tied to anything. ";
    }
    doUntie(actor) = {
        if (self.tiedTo == box_of_books) {
            "You undo the knot holding the rope in place. It slithers off
                the box and puddles on the floor. ";
            self.tiedTo = nil;
            self.moveInto(box_of_books.location);
        }
        else "You untie the rope. ";
        self.tiedTo = nil;
    }
    verDoClimb(actor) = {
        if (self.tiedTo == nil)
            "%You're% not exactly a fakir. ";
    }
    doClimb(actor) = {
        "Even tied to <<self.tiedTo.thedesc>>, the rope does not present
            a decent climb. ";
    }
    verDoPull(actor) = {
        if (self.tiedTo == nil) pass verDoPull;
    }
    doPull(actor) = {
        if (self.tiedTo == arch_knob) {
            self.doFollow(actor);
            return;
        }
        if (self.tiedTo == post_cable || self.tiedTo == fence_cable) {
            "No matter how hard you pull on the rope, the cable to which
                it is tied refuses to lengthen. ";
            return;
        }
        if (self.tiedTo != steel_plate) {
            "You give the rope a good tug. ";
            if (self.tiedTo.isfixed || self.tiedTo.weight > 100)
                "\^<<self.tiedTo.thedesc>> goes nowhere. ";
            else "\^<<self.tiedTo.thedesc>> moves with a jerk. ";
            return;
        }
        "You pull on the rope";
        if (steel_plate.isRaised) {
            ", but nothing further happens. ";
            return;
        }
        if (rope.location != crawl_pulley) {
            ", but lack the necessary leverage to raise the steel plate. ";
            return;
        }
        ". With a horrendous screech the steel plate begins rising, revealing
            a sharp edge on its bottom side. Encouraged, you pull as hard as
            your awkward position will allow. Hand over hand you pull on the
            rope; little by little the steel plate
            rises, until you hear a loud click and the rope stops moving. When
            you gently relax your grip, the steel plate quivers but holds its
            place. Where the plate was there is now ";
        if (small_grate.isopen)
            "an opening into the library. ";
        else "a grate. ";
        steel_plate.isRaised = true;
        fake_steel_plate.moveInto(nil);
        incscore(5);
        plateAh.solve;
    }
    verDoFollow(actor) = {
        if (self.tiedTo != arch_knob)
            "You go nowhere. ";
    }
    doFollow(actor) = {
        "You pull yourself along the rope, hand over hand. ";
        if (actor.drunk) {
            "With its help you are able to navigate the bobbing doorway.";
            actor.drunk = nil;
            pointing_coffee_spoons.moveInto(nil);    /* Just in case */
            drunkAh.solve;
            leaveAh.see;
            incscore(5);
        }
        "\b";
        if (actor.location == cb_room)
            actor.travelTo(break_room);
        else actor.travelTo(cb_room);
    }
;

snowy_n_side: snowroom
    sdesc = "Hillside"
    blinddesc = "You can sense the ground sloping up to the north. To the
        south, the ground drops, then levels. "
    ldesc = {
        "A sudden rise to the north is balanced by the solidity of the
            building to the south. A thin path of less-deep snow runs
            east and west. ";
        if (snowDaemon.avalancheOn)
            "Some distance up the hill you see snow tumbling towards you. ";
        if (self.printsNumber > 0)
            "The snow is flattened in many places by footprints. ";
    }
    exits = 'east and west'
    north = { "The snow is too deep and the hill too steep. "; return nil; }
    ne = { return self.north; }
    nw = { return self.north; }
    south = { "You gently run into the building. "; return nil; }
    east = snowy_ne_side
    west = snowy_nw_side
;

avalanche: distantItem, floatingItem
    stage = 1
    noun = 'avalanche'
    location = {
        if (Me.location == snowy_ne_side || Me.location == snowy_nw_side ||
            Me.location == snowy_n_side)
            return (Me.location);
        return doghouse;        // So you can ask Frankie about it
    }
    sdesc = "avalanche"
    ldesc = "Far above you, you can see it gathering, moving towards you
        with frightening rapidity. "
    frankiedesc = 'When we heard about it yesterday, we all started rushing
        about, hither and yon, trying to finish our separate projects. The
        power going out didn\'t help things a bit." He sighs heavily. "I only
        wish someone could have protected my project.'
;

rollAvalanche: function(num) {
    switch (num) {
        case 1:
            "\bYou hear a faint rumbling begin.\n";
            snowDaemon.avalancheOn = true;
            avalancheAh.see;
            break;
        case 2:
            "\bThe rumbling you heard earlier has grown in volume. It sounds
                very close.\n";
            break;
        case 3:
            "\b";
            if (Me.location.isSnowRoom)
                "The sound of a freight train makes you look to the north,
                    where a solid wall of white is sweeping towards you.
                    You turn to run, but the avalanche is faster.";
            else "The rumbling sound outside grows louder and louder,
                reverberating throughout the building. As you glance around,
                a rabbit in headlights, the north wall falls towards you,
                staved in by the mass of snow behind it.";
            " Powder fills your mouth, your nose; it stoppers your ears. You
                drift in white for some time.\b";
            die();
            exit;
    }
    setfuse(&rollAvalanche, 8, num + 1);
}

frankieConversation: conversationPiece
    stage = 1
    askDisambig = true
    noun = 'power' 'sam' 'limit' 'project' 'team'
    adjective = 'time'
    sdesc = "that"
    frankiedesc = {
        if (find(objwords(2), 'power')) {
            "\"We put too many demands on the building, tripped every breaker
                it had, one by one. Thing is, to restart the system you
                have to reset the breakers in the order in which they were
                tripped. Too much bother for us, considering our time
                limit, and what with the breakers being on the outside of the
                building and all.\" ";
            askedFrankieClue.see;
        }
        else if (find(objwords(2), 'sam'))
            "\"Sam was one of my colleagues,\" Frankie says. \"He left
                mid-afternoon yesterday.\" ";
        else if (find(objwords(2), 'limit'))
            "Frankie says, \"I have to finish before the avalanche
                arrives.\" ";
        else if (find(objwords(2), 'project'))
            "\"Why, the spheres,\" he says. ";
        else if (find(objwords(2), 'team'))
            "\"I sent my team away when we heard about the avalanche.
                I couldn't ask them to put themselves in harm's way.\" ";
    }
;


/*
    Eggs, the easter eggs in _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: eggs.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

/*
** The beach
*/

fasterVerb: deepverb
    speed = 10
    sdesc = "faster"
    verb = 'faster'
    action(actor) = {
        if (!actor.location.beachRoom) {
            "Things are already occurring as quickly as possible. ";
            return;
        }
        if (self.speed > 2) {
            self.speed -= 2;
            "The world around you speeds up. ";
        }
        else "Nothing further happens. ";
        if (the_author.location == actor.location && !the_author.seenVerb) {
            "Stephen looks at you strangely. \"You know about that already?\"\ 
                he says in surprise. ";
            the_author.seenVerb = true;
        }
    }
;

slowerVerb: deepverb
    sdesc = "slower"
    verb = 'slower'
    action(actor) = {
        if (!actor.location.beachRoom) {
            "Things are already occurring as slowly as possible. ";
            return;
        }
        if (fasterVerb.speed < 20) {
            fasterVerb.speed += 2;
            "The world around you slows. ";
        }
        else "Nothing further happens. ";
        if (the_author.location == actor.location && !the_author.seenVerb) {
            "Stephen looks at you strangely. \"You know about that already?\"\ 
                he says in surprise. ";
            the_author.seenVerb = true;
        }
    }
;

// Notice that Stephen can comment on save/restore/undo
the_author: Actor, predetector, detector
    chatterNum = 1
    stage = '2b'
    seenVerb = nil        // True if the player uses "faster" or "slower"
    isHim = true          //  while Stephen is around
    noun = 'stephen' 'author' 'granade' 'himself'
    location = beach1
    sdesc = "Stephen"
    ldesc = "Stephen is sitting on the beach, leaning back on his hands.
        Wind riffles his light brown hair as he stares contemplatively at
        the ocean. "
    actorDesc = "Stephen is reclining on the beach. "
    verDoAskAbout(actor) = {
        "Stephen shakes his head, stopping you mid-sentence. \"Not now,\" he
            says. ";
    }
    verDoAskFor(actor, io) = { self.verDoAskAbout(actor); }
    doSynonym('AskFor') = 'TellAbout'
    verIoGiveTo(actor) = {
        "Stephen grins, shaking his head at you. ";
    }
    actorAction(v, d, p, i) = {
        if (v == helloVerb)
            "Stephen nods at you. ";
        else "Stephen puts a finger to his lips, then returns to staring at
            the sea. ";
        exit;
    }
    verDoKick(actor) = {
        "As you pull your leg back, Stephen glances in your direction. Your leg
            seizes up, preventing you from completing the kick. ";
    }
    verDoKiss(actor) = {
        "He laughs. \"I expected as much. All anyone wants to do in IF these
            days is kiss and take their clothes off.\" ";
    }
    chatter = {
        if (Me.location != self.location)
            return;
        "\b";
        switch(chatterNum++) {
            case 1:
            "Stephen stares out at the ocean, smiling. \"I've always liked the
                Gulf,\" he says. \"I started coming here when I was twelve,
                and ever since then it's been an escape, a chance to
                recharge.\" ";
            break;

            case 2:
            "Stephen laughs. \"I'm always ambivalent about the beach. I want to
                share it with others, but I don't want this stretch to become
                Destin, with twenty-story hotels looming over the ocean and
                tourist-trap businesses clustering along the strip.\" He
                grimaces, running a hand through his hair. \"Developers versus
                environmentalists, with me in the middle.\" ";
            break;

            case 3:
            "\"Well, I suppose I should apologize, Terry. I've carved out a
                bit of your world for my pleasure.\" Laughter. \"I never
                expected you to stumble here, but I was careless. Left a
                doorway behind me.\" He shrugs. \"In for a penny, in for a
                pound.\" ";
            break;

            case 4:
            "\"I have to leave, but feel free to stay and watch the changing
                face of the beach. ";
            if (!self.seenVerb)
                "I've tweaked things a bit:\ you can speed up or slow down
                    the passage of time here using 'faster' and 'slower'. ";
            "Head north when you're done. Don't worry, this isn't really
                part of the game.\" He stands,
                brushing white sand from his clothes. \"And good luck,\" he
                adds as an afterthought before collapsing into a vertical
                line, then into a point, then into nothing. ";
            self.moveInto(nil);
            not_the_author.moveInto(nil);
        }
        if (chatterNum <= 4)
            notify(self, &chatter, 1);
    }

    preSaveGame = "Stephen smiles. \"Planning on returning soon?\"\b"
    restoreGame(preLoc, postLoc) = {
        if (!preLoc && postLoc)
            "\b\"Welcome back, Terry,\" Stephen tells you. ";
    }
    undoMove(preLoc, postLoc) = {
        if (!preLoc && !postLoc) return;
        "\b";
        if (postLoc)
            "Stephen looks at you and says, \".ereh sneppah hcum ton ;odnu ot
                tnaw uoy desirprus m'I\" ";
        else "From far away you hear Stephen:\ \"!ysae ti ekaT\" ";
    }
;

not_the_author: item
    stage = -1
    isListed = nil
    noun = 'steve'
    location = beach1
    sdesc = "Steve"
    dobjGen(a, v, i, p) = {
        "He's never liked being called \"Steve.\" ";
        exit;
    }
    iobjGen(a, v, d, p) = {
        self.dobjGen(a, v, d, p);
    }
;

beachRm: room
    closedIn = true        // No dogs allowed (dog.t)
    isSchool = true        // Is part of the school, in a weird way (school.t)
    beachRoom = true
    moveNum = 0
    floating_items = [beach_ocean, beach_sand, beach_clouds, beach_sun,
        beach_dunes, beach_copse]
    smelldesc = "The salt tang makes you sneeze. "
    listendesc = "You hear the crash of the ocean. "
    moveMe = {
        if (Me.location != self)
            return;
        self.moveNum++;
        if (self.moveNum < fasterVerb.speed) {
            notify(Me.location, &moveMe, 1);
            return;
        }
        self.moveNum = 0;
        "\b<<self.movedesc>> ";
        Me.moveInto(self.movedest);
        notify(Me.location, &moveMe, 1);
    }
    north = {
        "With every step, the beach receeds into the distance. Ahead of you,
            a hallway opens up and embraces you.\b";
        buddy.isPaused = nil;    // Start everyone back up
        dog.isPaused = nil;
        janitor.isPaused = nil;
        return mid2_hall_one;
    }
    swimAction = {
        if (the_author.location == self)
            "You refrain while Stephen is here. ";
        else "Glancing along the beach, you see no one else. You strip, placing
            your clothes in a neat pile, and fling yourself into the surf with
            gleeful abandon. After being pummelled by waves for a while, you
            climb back out and redress. ";
    }
;

beach_ocean: wallpaper
    stage = -1
    noun = 'ocean' 'water' 'wave' 'waves'
    adjective = 'ocean' 'green' 'deep' 'azure'
    sdesc = "ocean"
    ldesc = "<<Me.location.oceandesc>>"
;

beach_sand: wallpaper
    stage = -1
    noun = 'sand' 'beach'
    adjective = 'white' 'wet' 'brown'
    sdesc = "sand"
    ldesc = "<<Me.location.sanddesc>>"
    verDoDig(actor) = {
        if (Me.location.isRaining)
            "You dig, but the rain quickly flattens any structures you make. ";
    }
    doDig(actor) = {
        "You spend some time digging in the sand, forming castles and mounds,
            then knocking them down again. ";
    }
;

beach_clouds: wallpaper
    stage = -1
    noun = 'cloud' 'clouds'
    sdesc = "clouds"
    ldesc = "<<Me.location.clouddesc>>"
;

beach_sun: wallpaper
    stage = -1
    noun = 'sun' 'glow'
    sdesc = "sun"
    ldesc = "<<Me.location.sundesc>>"
;

beach_dunes: wallpaper
    stage = -1
    noun = 'dune' 'dunes' 'mound' 'mounds' 'grass'
    adjective = 'dune'
    sdesc = "dunes"
    ldesc = "<<Me.location.dunedesc>>"
;

beach_copse: wallpaper, distantItem
    stage = -1
    noun = 'copse' 'oak' 'oaks' 'pine' 'pines' 'tree' 'trees'
    adjective = 'scrub' 'short' 'small' 'stand' 'copse'
    sdesc = "copse"
    ldesc = "<<Me.location.copsedesc>>"
;

beach1: beachRm
    sdesc = "Coastline"
    ldesc = "The salt smell of the sea fills the air. In front of you, the
        ocean laps the light brown sand in a continuous rumble of sound.
        The water is deep green at the shore, darkening to azure before it
        meets the weaker blue of the sky. A thin scattering of clouds to your
        left is lit by the rising sun. White sand intermixed with black
        specks lead back to sloping mounds covered with burnt dune grass, then
        to a copse of scrub oaks and pines. "
    movedesc = "You notice the sun has risen higher."
    movedest = beach2
    oceandesc = "The salt water stretches from here to the white line of the
        horizon. It is deep green near the shore, darkening to blue as the
        water deepens. "
    sanddesc = "The sand is white with occasional flecks of black beneath the
        surface. "
    clouddesc = "A barely-noticeable layer of white. "
    sundesc = "It peeks over the horizon. "
    dunedesc = "The dunes are mounds of white sand vaguely held in place by
        limp brown grass. "
    copsedesc = "The trees are far to the north. "

    firstseen = {
        notify(self, &moveMe, fasterVerb.speed);
        pass firstseen;
    }
;

beach2: beachRm
    sdesc = "Coastline"
    ldesc = "Sunlight beats down upon the white sand and dances along the tips
        of the ocean waves. The noonday heat is oppressive, and a swim in the
        blue-green waters is tempting. Behind you rise mounds covered in brown
        dune grass, their surface blinding except when fast-moving clouds
        obscure the sun. Behind them is a small copse of short pines and
        scrub oaks. "
    movedesc = "Twilight steals across the sand."
    movedest = beach3
    oceandesc = "The wind sculpts the ocean into gentle waves. "
    sanddesc = "The beach glitters and twinkles. "
    clouddesc = "The clouds scud across the sky. "
    sundesc = "You cannot look directly at it. "
    dunedesc = "The mounds glint in the sunlight. "
    copsedesc = "They are pale in the fierce light. "
;

beach3: beachRm
    sdesc = "Coastline"
    ldesc = "As sunset approaches the horizon burns, staining the flickering
        ocean crimson. Whipped by a strong wind, the waves slap the wet shore,
        leaving behind foam and the occasional broken shell. The dunes behind
        you mirror the dusky color, their grass looking more lifeless than
        ever. The small stand of trees behind them is barely visible this late
        in the day. "
    movedesc = "The sun finally sets. Darkness envelops you."
    movedest = beach4
    oceandesc = "Waves crash against the gentle slope of the shore. "
    sanddesc = "It mirrors the blood-red of the setting sun. "
    clouddesc = "Most of the clouds have vanished. "
    sundesc = "It is setting. "
    dunedesc = "The dunes are stained red by the setting sun. "
    copsedesc = "The copse is hard to see in the murky twilight. "
;

beach4: beachRm
    sdesc = "Coastline"
    ldesc = "Night has descended. The constant grumble of the shore continues,
        although it sounds muted by the inky blackness. Above the stars shine
        fiercely, diamonds on velvet. Insects sound their raspy calls about
        you. Heat from the long-past day rises from the sand, only to be beaten
        off by the chill of nighttime. "
    listendesc = "Over the roar of the ocean you hear the rasp of insects. "
    movedesc = {
        if (Me.inRain)
            "Light spills across the beach.";
        else "Clouds gather, obscuring the stars.";
    }
    movedest = {
        if (Me.inRain) {
            Me.inRain = nil;
            return beach1;
        }
        Me.inRain = true;
        return beach1a;
    }
    oceandesc = "The waves glow with phosphorescence. "
    sanddesc = "It has cooled since daytime. "
    clouddesc = "You can see no clouds. "
    sundesc = "Presumably it is somewhere beneath you. "
    dunedesc = "The dunes are hidden by nighttime. "
    copsedesc = "You cannot see the copse in the darkness. "
;

beach_stars: distantItem
    stage = -1
    isThem = true
    noun = 'star' 'stars'
    location = beach4
    sdesc = "stars"
    ldesc = "They twinkle, refracted by the atmosphere. "
;

beach1a: beachRm
    sdesc = "Coastline"
    ldesc = "The rising sun gives little light to the land:\ a thick blanket of
        clouds has encircled the beach during the night. A chill wind blows
        across the muted gunmetal ocean. There is a thick expectancy to the
        air, lying over the white sands of the dunes and the grass on top of
        them. Behind the dunes, a copse of scrub oaks and pines shift in the
        wind. "
    movedesc = "A vague glow in the sky appears, rising higher. As it does,
        the skies open up, pouring rain down upon your head. "
    movedest = beach2a
    oceandesc = "The blue-green of the water is now gunmetal grey. "
    sanddesc = "The sand is still cool beneath you. "
    clouddesc = "The clouds are piled above you. "
    sundesc = "It is masked by clouds. "
    dunedesc = "The sand of the dunes is more grey than white. "
    copsedesc = "The trees bend and twist in the wind. "
;

beach2a: beachRm
    isRaining = true
    sdesc = "Coastline"
    ldesc = "Blinding rain mixes with the salt spray of ocean waves driven by
        a fierce wind. Thunder occasionally drowns out the roar of the angry
        surf. The once-white sand is wet and brown; the dune grass is beaten
        down by rain and blown by wind. Little is visible through the haze
        of the storm. "
    movedesc = "The rain ends; the clouds part, allowing you a glimpse of the
        setting sun."
    movedest = beach3a
    oceandesc = "The ocean snarls angrily against the coast. "
    sanddesc = "The white has become brown under the deluge. "
    clouddesc = "The clouds are a deep grey. "
    sundesc = "The sun is hidden by clouds, if it even exists. "
    dunedesc = "The dunes are slowly being flattened by the rain. "
    copsedesc = "You cannot see it--the rain cuts visibility drastically. "
;

beach3a: beachRm
    sdesc = "Coastline"
    ldesc = "As the sun sinks below the horizon the clouds sullenly move away
        from the beach. The blue-grey water has calmed, although the sand
        still bears marks of the storm's passage. The dunes have been smoothed
        by the wind and rain. "
    movedesc = "A moment's hush, and night has fallen."
    movedest = beach4
    oceandesc = "The water is much calmer than a short time before. "
    sanddesc = "It has been worked over by the rain. "
    clouddesc = "The clouds are reluctantly withdrawing. "
    sundesc = "It edges towards the horizon. "
    dunedesc = "The dunes look as if they have been smoothed with a small
        hammer. "
    copsedesc = "The branches of the trees drip with water. "
;

/*
** The cell from "Waystation"
*/

cell : room
    sdesc = "Cell"
    ldesc = {
    "You are surrounded by one of the most depressing places ever
        created--the cell.  Thick metal bars line the north wall.  To the
        east is a cot, bolted to the floor.  A metal sink along
        the west wall completes the amenities.  The flagstone floor is quite
        rough-hewn. ";
    if (flagstone.moved) "A flagstones lies pushed to one side,
        revealing a hole approximately one meter in diameter. ";
    }
    floordesc = "It is made of flagstones. "
    exits = {
        if (flagstone.moved)
            "You can go down. ";
        else "There are no obvious exits. ";
    }
    down = {
        if (flagstone.moved) {
          hole_one.doBoard(Me);
          return nil;
        }
        else return (self.noexit);
    }
;

flagstone : fixeditem
    stage = -1
    sdesc = "flagstone"
    ldesc = "The flagstones are more like large rocks, but then this is not
        exactly the Hilton.  They look very heavy."
    noun = 'flagstone' 'rock' 'stone'
    plural = 'flagstones' 'rocks' 'stones'
    adjective = 'rocky'
    location = cell
    verDoTake(actor) = {
        if (self.moved)
            "Even the one you managed to pry up is too massive for you. ";
        else {
            "After a few moments of back-breaking labor, you determine that
                the flagstones are much, MUCH too heavy to lift.  However,
                one of them seems to be a bit loose. ";
        }
    }
    verDoPull(actor) = {}
    doPull(actor) = {
        if (self.moved)
            "As hard as moving one flagstone was, you don't want to repeat
                that again. ";
        else {
        "You somehow manage to fit your fingers around a slightly loose
            flagstone.  You begin to pull on the flagstone, trying to get
            it to come free.  Sweat begins
            to trickle down your face.  Then, it's free!  You slide it to
            one side, revealing a hole. ";
        self.moved = true;
        hole_one.moveInto(cell); // Have the hole appear
        }
    }
    doSynonym('Pull') = 'Move' 'Pry' 'Raise'
    verDoPush(actor) = {
        if (self.moved)
            "Shoving that thing once was enough, thanks. ";
        else pass verDoPush;
    }
;

cot : beditem
    stage = -1
    sdesc = "cot"
    ldesc =
        "The cot is what you would expect in a cell. The steel frame is
            worn and twisted and the bare mattress appears to contain
            entire insect civilizations. "
    noun = 'cot' 'bed'
    location = cell
    doSiton(actor) = {
        "As you lie down the mattress squirms underneath you. When you
            rest your weight fully on the cot, a sickening crunch stills
            the motion. ";
        actor.moveInto(self);
    }
    out = cell
    doSynonym('Siton') = 'Lieon'
    verDoLookunder(actor) = {
        "You discover that all of the slats and springs have been removed from
            this cot. ";
    }
;

mattress : fixedItem
    stage = -1
    sdesc = "mattress"
    ldesc = "Don't look too closely.  No telling what's crawling around
        inside of it. "
    location = cot
    noun = 'mattress'
    verDoTear(actor) = {
        "The mattress is made of too stern a material for that to be
            effective. You doubt that a chainsaw would be
            effective enough. ";
    }
    verDoSiton(actor) = {}
    doSiton(actor) = { cot.doSiton(actor); }
    doSynonym('Siton') = 'Lieon'
;

cell_sink : fixeditem
    stage = -1
    sdesc = "metal sink"
    ldesc = "The sink is old and stained with repeated use. The spigot is
        encrusted with slime and gunk. Behind the spigot is one handle
        for turning the water on or off. The sink is currently off. "
    noun = 'sink' 'handle' 'tap'
    adjective = 'metal'
    location = cell
    verDoTurn(actor) = { self.verDoTurnon(actor); }
    verDoTurnon(actor) = {
        "You twist the handle of the sink. There is a dry, raspy sound from
            behind the wall. Green, brackish water begins spurting from the
            spigot in large clumps. Disgusted, you turn the sink off again
            and watch the water slowly slip down the drain. ";
    }
    verDoTurnoff(actor) = {
        "The sink isn't on. ";
    }
;

fake_walls_n_ceiling : decoration
    stage = -1
    noun = 'wall' 'ceiling'
    plural = 'walls'
    location = cell
    sdesc = {
        if (car(objwords(1)) == 'ceiling')
            "ceiling";
        else if (car(objwords(1)) == 'wall')
            "wall";
        else "walls";
    }
    ldesc = "You glance around at the walls and ceiling, finding nothing
        that would be of any help. "
;

bars : fixeditem
    stage = -1
    sdesc = "bars"
    ldesc = "Strong metal bars. It'll take more than a sharpened spoon to
        get past them. "
    adesc = "some bars"
    thedesc = "the bars"
    thrudesc = "Past the bars you see a nondescript hallway lit by
        fluorescent lights. Further down the hall you can see shadows
        which suggest that a guard is on duty. "
    takedesc = "Not bloody likely. "
    noun = 'bar'
    plural = 'bars'
    location = cell
    verDoLookthru(actor) = {}
    doLookthru(actor) = { self.thrudesc; }
    verDoPull(actor) = { "The bars are stronger than you are. "; }
    verDoPush(actor) = { "You push with all your might...to no avail. "; }
;

hole_one : fixeditem
    stage = -1
    sdesc = "hole"
    ldesc = "You can't see where the hole leads to. "
    noun = 'hole'
    verDoBoard(actor) = {}
    doBoard(actor) = {
        "You swing your feet into the hole, then jump, trusting that there
            is something below to cushion your fall.\b
            You fall for a very long time.\b";
        pauseAndClear();
        "\b";
        bedsheet.moveInto(bedroom_bed);
        bedsheet.tiedTo = nil;
        bedsheet.isListed = nil;
        bedsheet.firstPick = true;
        bedroom_bed.isMade = true;
        backyard_faeries.daemonNumber = 1;
        clover_patch.haveSearched = nil;
        four_leaf_clover.moveInto(nil);
        backyard2.isseen = nil;
        light_hall.isseen = nil;
        faerie_king.daemonNumber = 1;
        Me.travelTo(bedroom);
    }
    doSynonym('Board') = 'Enter'
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        "You drop <<dobj.thedesc>> into the hole. It vanishes soundlessly. ";
        dobj.moveInto(bedroom);
    }
;

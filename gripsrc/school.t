/*
    School, part two b of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: school.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

unfulfilledThreeB: function;

schoolDaemon: object
    firstSight = true
    noises = [
            'The low sussuration of voices fills the hall, competing with the
                tramp of many feet, though no horde of students appear. You
                crouch against a wall as the voices wash
                over you. \"...and then Wight says, \'Obviously the action
                potential will decrease.\' Can you believe him?\"\ one voice
                says loudly enough to be distinguished from the hubbub.
                \"Arrogant bastard,\" another voice agrees, before all the
                voices fall silent again. ',
            'The growing sound of marching feet heralds the arrival of the
                bodiless voices. \"Yeah, Hancock\'s biochem class isn\'t bad,
                but I\'d avoid, y\'know, second-semester PChem,\" you hear
                someone say near your ear. Another voice rises out of the
                noise, saying, \"I don\'t know, Bob, I just don\'t know. None
                of my students are--\" The voices vanish once more. ',
            'Laughter fills the hall, shrieks and giggles bouncing off the
                walls. \"C\'mon!\"\ a voice yells. \"The organic chem class is
                having its end-of-the-year water fight!\" Then the hall falls
                silent. ',
            'Behind you, a voice mumbles, \"Adenine, guanine, thymine,
                cytosine, adenine, guanine, thymine, cytosine,\" as it
                overtakes and passes you. The owner of the voice is nowhere in
                sight. ',
            '\"BITCH!\" You leap into the air, trying to find who yelled.
                You see no one, but the voice continues. \"Give ME a thirty?
                Fucking BITCH!\" '
            ]
    noiseNum = 6
    passersBy = {
        if (!Me.location.isSchoolHall) {      // Are we in a hallway?
            if (Me.location.isSchool)         // Are we still in the school?
                notify(self, &passersBy, 3);  // Yes, so try again later
            return;
        }
        if (grey_man.location == Me.location) {
            notify(self, &passersBy, 2);      // Don't interrupt the grey man
            return;
        }
        "\b";
        if (firstSight) {
            firstSight = nil;
            "The sound of a crowd of students rises, washing over you. You
                look about in confusion; no students are in sight. The babble
                grows louder, louder, filling your ears--then cuts off sharply. ";
        }
/*        else switch(RAND(5)) {
            case 1:
            "The low sussuration of voices fills the hall, competing with the
                tramp of many feet, though no horde of students appear. You
                crouch against a wall as the voices wash
                over you. \"...and then Wight says, 'Obviously the action
                potential will decrease.' Can you believe him?\"\ one voice
                says loudly enough to be distinguished from the hubbub.
                \"Arrogant bastard,\" another voice agrees, before all the
                voices fall silent again. ";
            break;

            case 2:
            "The growing sound of marching feet heralds the arrival of the
                bodiless voices. \"Yeah, Hancock's biochem class isn't bad,
                but I'd avoid, y'know, second-semester PChem,\" you hear
                someone say near your ear. Another voice rises out of the
                noise, saying, \"I don't know, Bob, I just don't know. None
                of my students are--\" The voices vanish once more. ";
            break;

            case 3:
            "Laughter fills the hall, shrieks and giggles bouncing off the
                walls. \"C'mon!\"\ a voice yells. \"The organic chem class is
                having its end-of-the-year water fight!\" Then the hall falls
                silent. ";
            break;

            case 4:
            "Behind you, a voice mumbles, \"Adenine, guanine, thymine,
                cytosine, adenine, guanine, thymine, cytosine,\" as it
                overtakes and passes you. The owner of the voice is nowhere in
                sight. ";
            break;

            case 5:
            "\"BITCH!\" You leap into the air, trying to find who yelled.
                You see no one, but the voice continues. \"Give ME a thirty?
                Fucking BITCH!\" ";
            break;
        }*/
        else {
            if (self.noiseNum > length(self.noises)) {
                self.noises = shuffle(self.noises);
                self.noiseNum = 1;
            }
            say(self.noises[self.noiseNum]);
            self.noiseNum++;
        }
        "\n";
        notify(self, &passersBy, 10 + RAND(5));
    }
;

class school_room: insideRm
    isSchool = true
;

class school_hall: school_room
    isSchoolHall = true
;

class school_crawlspace: room
    isSchool = true
    isCrawlspace = true
    noDog = true        // Dog can't wander in here
    noBuddy = true      // Neither can Little Buddy
    sdesc = "Crawlspace"
;

class school_door: doorItem, lockableDoorway
    stage = '2b'
    isopen = nil
    mykey = key_ring
    verIoTieTo(actor) = {}
    verDoOpen(actor) = {
        if (self.islocked)
            lockedDoorsAh.see;
        pass verDoOpen;
    }
    doUnlockWith(actor, io) = {
        inherited.doUnlockWith(actor, io);
        if (io == mykey && janitor.location == Me.location) {
            "As you do so, the janitor looks at the ring of keys for a second,
                then at you, then at his cart. \"Hey!\"\ he says, grabbing the
                keys from you. \"What's the big idea?\" He treats you to a
                baleful glare for a few seconds before returning to sweeping. ";
            key_ring.moveInto(nil);
        }
    }
;

class mist_door: school_door
    openedOnce = nil
    destination = {
        if (!self.islocked) {
            self.doOpen(nil);
            return nil;
        }
        else {
            "%You%'ll have to open <<self.thedesc>> first. ";
            setit(self);
            return nil;
        }
    }
    verDoOpen(actor) = {
        if (self.islocked)
            lockedDoorsAh.see;
        pass verDoOpen;
    }
    doOpen(actor) = {
        if (!openedOnce) {
            "You open the door, only to find that behind it lies a swirling
                grey mist. Greasy tendrils reach out and caress you; you
                flinch back, slamming shut the door. ";
            openedOnce = true;
        }
        else "You find yourself loathe to open the door again. ";
    }
;

school_stairs_up: wallpaper
    stage = '2b'
    isThem = true
    noun = 'stairs' 'step' 'staircase'
    plural = 'steps'
    adjective = 'flight'
    sdesc = "stairs"
    ldesc = "They lead to the second floor. "
    verDoClimb(actor) = {}
    doClimb(actor) = {
        actor.travelTo(actor.location.up);
    }
    doSynonym('Climb') = 'Enter'
;

school_stairs_down: wallpaper
    stage = '2b'
    isThem = true
    noun = 'stairs' 'step' 'staircase'
    plural = 'steps'
    adjective = 'flight'
    sdesc = "stairs"
    ldesc = "They lead to the first floor. "
    verDoClimb(actor) = {}
    doClimb(actor) = {
        actor.travelTo(actor.location.down);
    }
    doSynonym('Climb') = 'Enter'
;

glass_doors: wallpaper, obstacle, seethruItem
    stage = '2b'
    isThem = true
    noun = 'door'
    plural = 'doors'
    adjective = 'glass'
    sdesc = "glass doors"
    ldesc = "The closed doors lead out. "
    thrudesc = "Grey mist licks at the doors. "
    verDoKnockon(actor) = { "No one answers. "; }
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You push open the glass doors that lie between you and the outside.
            Grey mist begins pouring through the door. You can't
            see a thing outside. You're not even sure if there _is_ an
            outside. The doors slip from your sweaty hands and ease shut
            in front of you. ";
    }
    destination = {
        self.doOpen(nil);
        return nil;
    }
;

sw1_end: school_hall
    floating_items = [school_stairs_up, glass_doors]
    buddyList = [&up, 'up the stairs', &ne, 'down the hall']
    buddyToShelf = 2      // Which way to the reagent shelf? (see buddy.t)
    sdesc = "Southwest End"
    ldesc = "The hall ends in glass doors leading out. A flight of steps
        rises to the northwest, then doubles back to the floor above. The
        remainder of the hall lies to the northeast. "
    exits = 'northeast, southwest, and up'
    ne = mid1_hall_one
    nw = sw2_end
    sw = glass_doors
    up = sw2_end
;

mid1_hall_one: droom, school_hall
    buddyList = [&ne, 'to the northeast', &sw, 'to the southwest']
    buddyToShelf = 1
    sdesc = "Northeast-Southwest Hall"
    firstdesc = "A familiar hallway embraces you. As the world ceases its
        unnatural spin, you find you recognize the northeast-southwest
        hall.  You're in the downstairs hallway of the science building where
        you spent much of your time in college.\b
        Not that you enjoyed your time here. It was one more step on the road
        to being a doctor, just like father wanted. The only catch:\ you
        hated the science classes, the endless recitation of boring facts.
        It made your decision not to be a doctor that much easier. "
    seconddesc = "The hall runs northeast to southwest; further to the
        southwest, the hall ends in a set of doors. A single door stands
        to the northwest. "
    exits = 'northeast and southwest'
    ne = mid1_hall_two
    nw = mid1_hall_door
    sw = sw1_end
;

mid1_hall_door: school_door
    adjective = 'northwest' 'nw'
    location = mid1_hall_one
    sdesc = "northwest door"
    otherside = classroom_door
    doordest = school_classroom
;

fake_double_doors: distantItem
    stage = '2b'
    isThem = true
    noun = 'door'
    plural = 'doors'
    adjective = 'glass'
    location = mid1_hall_one
    sdesc = "glass doors"
    ldesc = "They lead out. "
;

school_classroom: school_room
    noBuddy = true
    noDog = { return !classroom_door.isopen; }
    sdesc = "Classroom"
    ldesc = "Desks crowd into the classroom, pointing towards a lectern.
        The <<classroom_door.wordDesc>> door leads southeast. "
    se = classroom_door
    out = classroom_door
;

classroom_door: school_door
    location = school_classroom
    otherside = mid1_hall_door
    doordest = mid1_hall_one
;

classroom_lectern: surface, fixeditem, nestedroom
    reachable = ([] + self)
    stage = '2b'
    statusPrep = "behind"
    noun = 'lectern' 'podium'
    location = school_classroom
    sdesc = "lectern"
    ldesc = {
        "It gives a reasonably good view of the classroom. ";
        pass ldesc;
    }
    verDoStandBehind(actor) = {
        if (actor.location == self)
            "You're already behind the lectern. ";
    }
    doStandBehind(actor) = {
        "You step behind the lectern. ";
        actor.moveInto(self);
    }
    verDoUnhideBehind(actor) = {
        if (actor.location != self)
            "But you're not behind the lectern. ";
    }
    doUnhideBehind(actor) = { self.doUnboard(actor); }
    doSynonym('HideBehind') = 'Enter'
    north -> school_classroom
    south -> school_classroom
    east  -> school_classroom
    west  -> school_classroom
    up    -> school_classroom
    down  -> school_classroom
    ne    -> school_classroom
    nw    -> school_classroom
    se    -> school_classroom
    sw    -> school_classroom
    in    -> school_classroom
    out   -> school_classroom
    noexit = { "%You% can't go that way. "; return nil; }
;

school_desks: platformItem, fixedItem
    talkNum = 1
    jabber = [
'A soft voice tickles your ear:\ \"Dr. Weller?\"  The voice pauses; you
glance around but see no one. \"Could you go back over
balancing reactions? I\'m still having trouble with how it works.\"',
'"I\'ve explained it twice." A second, deeper voice comes from somewhere
behind the lectern. "What don\'t you understand about it?" The voice is
as ghostly as the first.',
'The first voice continues. "I just...well, I\'m not--"\b
"It\'s not that difficult," the second voice says, interrupting the other.',
'"Well, I don\'t think I\'m the only one who can\'t follow your explanation."
The first man\'s voice has grown decidedly sharper.',
'There is a pause. "Does anyone else share Mr.\ Jeffers\' poor opinion of
this class?"',
'"It\'s not the class I have problems with, it\'s this one topic--"\b
The professor\'s voice is cutting. "Give your other classmates a chance
to answer."',
'There is a pause undercut by whispering.',
'"I see my explanation is not as misunderstood as you might think," says
the professor smugly. Angry footsteps storm from your desk to the door
and through it.',
'"Now if you will turn to the section on titration...." The professor\'s
voice fades away.'
    ]
    stage = '2b'
    isThem = true
    noun = 'desk'
    plural = 'desks'
    location = school_classroom
    statusPrep = "in"
    firstLdesc = true
    sdesc = "desks"
    ldesc = {
        "Desks fill the room in slightly askew lines. You remember sitting
            in them for hours at a time, listening to professors drone. ";
        if (self.firstLdesc) {
            "A brief flirtation with nostalgia makes you wonder what it would
                be like to sit in them once more. ";
            self.firstLdesc = nil;
        }
        pass ldesc;
    }
    listendesc = "Right now you hear nothing. "
    doSiton(actor) = {
        "You slip into one of the desks. A sourceless whisper of sound
            catches your attention, then is gone. ";
        actor.moveInto(self);
        if (self.talkNum <= length(self.jabber))
            notify(self, &whisper, 2);
    }
    whisper = {
        if (Me.location != self || self.talkNum > length(self.jabber))
            return;
        "\b<<self.jabber[self.talkNum++]>>";
        notify(self, &whisper, 1);
    }
;


mid1_hall_two: school_hall
    buddyList = [&ne, 'to the northeast', &sw, 'to the southwest', &se,
        'into the library']
    sdesc = "Northeast-Southwest Hall"
    ldesc = {
        "The hall's tile floor glints sickly under fluorescent lighting, its
            shine worn away by countless feet. The symmetry of the hall is
            broken by a doorway to the southeast. ";
        if (reagent_shelf.location == self)
            "A shelf is mounted next to the doorway. ";
        else "A tilted shelf clings desperately to the wall next to the
            doorway. ";
    }
    exits = 'northeast, southeast, and southwest'
    enterRoom(actor) = {
        if ((uberloc(buddy) != uberloc(Me)) && (buddy.stuckInGrate == 0) &&
            (reagent_shelf.location == self) &&
            (uberloc(buddy) != school_library) &&
            (uberloc(buddy) != library_stacks)) {
            if (RAND(100) < 50)
                buddy.moveInto(ne1_end);
            else buddy.moveInto(mid1_hall_one);
        }
        pass enterRoom;
    }
    ne = ne1_end
    se = school_library
    sw = mid1_hall_one
;

school_fluorescent_lights: floatingItem, decoration
    stage = '2b'
    noun = 'light' 'lights' 'lighting'
    adjective = 'fluorescent'
    location = {
        if (Me.location.isSchoolHall) return Me.location;
        return nil;
    }
    sdesc = "fluorescent lights"
    ldesc = "They buzz above you. "
    listendesc = "Once, when you were five, you took a long branch to a wasp's
        nest and knocked it down. The wasps swarmed around you, filling your
        ears with their angry sound.\bThese lights are louder. "
;

mid1_hall_two_doorway: myDoorway
    location = mid1_hall_two
    ldesc = {
        "It leads southeast. A shelf ";
        if (reagent_shelf.location == mid1_hall_two)
            "is mounted";
        else "hangs tilted";
        " next to it. ";
    }
    lookthrudesc = "You can see part of the science library. "
    doordest = school_library
;

reagent_shelf: fixedItem
    askDisambig = true
    stage = '2b'
    noun = 'shelf' 'reagent' 'chemical' 'bracket'
    plural = 'reagents' 'chemicals' 'brackets'
    adjective = 'reagent' 'wooden' 'angle'
    location = mid1_hall_two
    sdesc = "reagent shelf"
    ldesc = "The wooden shelf is mounted at eye level to the left of the
        southwest door. It is filled with chemicals and reagents. The angle
        brackets which attach it to the wall are worn and twisted:\ while
        you were a student here the shelf fell no less than three times. "
    takedesc = "The shelf tilts alarmingly, making you jerk back. "
    erindesc = 'That old thing? Nix\'s been taking bets as to when it\'ll
            collapse.'
    buddydesc = {
        if (self.location != Me.location) {
            "\"Hey, there's something you have to see about that shelf!\"\ 
                Little Buddy says excitedly. \"C'mon!\" ";
            buddy.clearProps;
            buddy.movingToShelf = true;
        }
        else buddy.waitForShelf;
    }
    verDoTouch(actor) = { "The shelf twists slightly under pressure. "; }
    verDoMove(actor) = {}
    doMove(actor) = {
        "You push on the shelf, which twists dramatically. With a loud snap,
            one of the angle brackets gives way. The chemicals slide off the
            end of the shelf, smashing over your arms and on the floor. ";
        if (gloves.isworn)
            "Liquids slide under the cuffs of your gloves; you rip them off,
                scratching your hands on bits of glass which had also fallen
                into the gloves. ";
        "Blood
            from cuts mingle with the chemicals. Acid pain claws at your
            hands";
        if (!coat.isworn) " and arms";
        ". ";
        unfulfilledThreeB();
    }
    doSynonym('Move') = 'Poke' 'Pull' 'Push' 'Turn' 'Break'
    verDoKick(actor) = { "You are not quite that agile. "; }
    verIoPutOn(actor) = { "The shelf is crammed with chemicals, so many that
        there is no space for anything else. "; }
;

chemical_mess: fixedItem
    stage = '2b'
    noun = 'mess' 'puddle' 'chemical' 'spill'
    plural = 'chemicals'
    adjective = 'chemical'
    sdesc = "puddle of chemicals"
    ldesc = "The chemicals have made quite a mess, streaking down the wall and
        puddling on the floor. Odd blends of colors vie for dominance of the
        puddle. A frothing section threatens to make short work of the
        rest of the puddle. "
    heredesc = "A puddle of chemicals mars the clean floor. "
    takedesc = "Were you to plunge your hands in that mix, there is some doubt
        as to whether or not they would still be attached to your wrists when
        you pulled them back. "
    janitordesc = 'I hate these messes, I surely do.'
    verDoTouch(actor) = {
        "Given the unknown chemicals floating in the puddle, you'd best not. ";
    }
    doSynonym('Touch') = 'Clean'
;

tilted_shelf: fixedItem
    askDisambig = true
    stage = '2b'
    noun = 'shelf'
    adjective = 'reagent' 'wooden' 'tilted'
    sdesc = "tilted shelf"
    ldesc = "The wooden shelf tilts at an alarming angle, its contents having
        fallen to the floor. It still clings to the wall with remarkable
        tenacity. "
    buddydesc = "Little Buddy looks down at his sneakers. \"Um. It never did
        that before.\" "
    takedesc = "It has moved all it will move. "
    verDoTouch(actor) = { "It has moved all it will move. "; }
    doSynonym('Touch') = 'Move' 'Poke' 'Pull' 'Push' 'Turn' 'Break'
    verIoPutOn(actor) = { "Not likely. "; }
;

school_library: school_room
    buddyList = [&nw, 'back into the hall', &sw, 'into the stacks to the
        southwest']
    buddyToShelf = 1
    sdesc = "Library"
    ldesc = "Site of many all-night study sessions. Its scarred wooden
        tables and straight-backed chairs spread in small whorls, orbiting
        open textbooks. To the northwest, the exit. To the southwest, the
        stacks. "
    exits = 'northwest and southwest'
    nw = mid1_hall_two
    sw = library_stacks
    out = mid1_hall_two
    firstseen = {
        if (box_of_books.location != self)
            "\bErin glances at you before returning to her books. \"Hi,
                Hastings,\" she says, loudly and less than warmly. ";
    }
    listendesc = {
        if (erin.location == self)
            erins_headphones.listendesc;
        else pass listendesc;
    }
    // Turn Erin on/off when the player enters/exits the room
    enterRoom(actor) = {
        if (erin.location == self)
            erin.wantheartbeat = true;
        pass enterRoom;
    }
    leaveRoom(actor) = {
        if (erin.leaveCounter == 0)    // Don't shut her off if she's about
            erin.wantheartbeat = nil;  //  to leave
        pass leaveRoom;
    }
;

library_tables: surface, fixedItem, readable
    stage = '2b'
    isThem = true
    noun = 'table'
    plural = 'tables'
    adjective = 'scarred' 'wooden'
    location = school_library
    sdesc = "wooden tables"
    ldesc = {
        "The tables have been etched by countless pencils, the work of bored
            or desperate students. ";
        pass ldesc;
    }
    readdesc = "You read nothing of any importance, only the usual jokes
        about science and science majors. "
    verDoSiton(actor) = {
        "You hop on one of the tables, swinging your legs like you used to
            do while studying Organic Chemistry. The memory is enough to make
            you hop back up again. ";
    }
    verIoTieTo(actor) = {}
;

library_chairs: decoration
    stage = '2b'
    isThem = true
    noun = 'chair' 'spiral'
    plural = 'chairs' 'spirals'
    adjective = 'wooden' 'straight-backed' 'library'
    location = school_library
    sdesc = "library chairs"
    ldesc = "Students have arranged the chairs in odd configurations, the most
        prominent being spirals with textbooks at the center. "
;

// books_in_box moved here to beat out other books
books_in_box: fixedItem, readable
    askDisambig = true
    stage = '2b'
    isThem = true
    noun = 'book' 'books'
    location = box_of_books
    sdesc = "books"
    ldesc = "From a cursory glance at their spines, you surmise they are
        old science texts no longer held in the main library. "
    readdesc = "There are too many to choose from, all on uninteresting
        topics. "
    takedesc = "There are too many to choose from. "
    erindesc = {
        if (school_storage_closet.isseen == nil) {
            "\"Yeah, yeah, there are plenty of books here.\" Erin sighs
                heavily. ";
            self.factTold -= erin;
        }
        else if (erin.leaveCounter > 0)
            "\"Just what I was looking for. Thanks,\" she says. ";
        else if (pile_of_books.location != nil) {
            "You open your mouth, then shut it, strangely reluctant to tell
                Erin what you've done. ";
        }
        else "\"Old books?\"\ Erin asks excitedly. \"You didn't happen to
            see a...no, wait, I tell you what. Can you bring them down here?\"
            She pats the books in front of her. \"I can't take a break right
            now, but if the book I'm after is in that box, it'd save me a lot
            of work.\" ";
    }
;

textbooks: readable, decoration
    stage = '2b'
    isThem = true
    noun = 'textbook' 'book'
    plural = 'textbooks' 'books'
    adjective = 'open'
    location = school_library
    sdesc = "open textbooks"
    ldesc = "Various textbooks dot the room, byproducts of study. "
    readdesc = "Every science subject from astronomy to zoology is
        represented. They're no more exciting to you now than they were then. "
;

// The radiator is not mentioned in the room description, just 'cause
//  (It's only here so Little Buddy can climb on it)
radiator: decoration
    stage = '2b'
    noun = 'radiator'
    adjective = 'white' 'stained'
    location = school_library
    sdesc = "radiator"
    ldesc = "Its white surface has been stained by age, time, and students. "
    verDoClimb(actor) = { "Were you Little Buddy's size, perhaps. "; }
    verIoTieTo(actor) = {}
;

// Similarly the file cabinet
school_file_cabinet: decoration
    stage = '2b'
    noun = 'cabinet'
    adjective = 'file'
    location = school_library
    sdesc = "file cabinet"
    ldesc = "No one has used the cabinet for ages; why it is still here is a
        mystery. "
    verDoClimb(actor) = { "It is much too high for that. "; }
    verDoOpen(actor) = { "It is rusted shut. "; }
;

erin: dthing, Actor
    leaveCounter = 0
    selfDisambig = true
    actions = [
        'Erin looks at you. "I don\'t suppose you know where they\'ve taken
            to hiding the old books, do you?" She thumps some books in front
            of her. "I need some earlier editions." Then she snorts. "Look
            who I\'m
            asking," she mutters to herself, turning back to her books.'
        'Erin pauses to rub lotion on her hands.'
        'Erin sighs heavily.'
        'Her chair creaks as Erin leans back and rolls her head, stretching
            stiff muscles, before going back to her studies.'
        'Erin mutters under her breath, memorizing something.'
        'Erin pounds her fist against her forehead a few times, as if to drive
            home some important concept.'
        'Erin tugs on a lock of her long copper hair.'
        'Erin closes one book and walks into the stacks, only to return a
            moment later with another. She sits down and resumes studying.'
        'Erin taps two fingers of one hand against a thigh, humming to
            herself.'
    ]
    actionNum = 1
    actionTurn = 2
    isHer = true
    askme = &erindesc
    noun = 'erin' 'student'
    sdesc = "Erin"
    stringsdesc = 'Erin'
    adesc = "Erin"
    thedesc = "Erin"
    firstdesc = "Erin was in several classes with you, most notably Physics
        12. She is currently studying with a fierce intensity, freckled
        face wrinkled in concentration, trying to learn
        physical chemistry if her choice of books is any indication. Headphones
        in her ears filter out distractions. "
    seconddesc = "Erin is hunched over several books, studying with a
        desperate intensity. Headphones in her ears block out distractions. "
    actorDesc = "Seated at one of the tables is Erin, lost in a haze of study. "
    listendesc = erins_headphones.listendesc
    buddydesc = {
        if (uberloc(self) == uberloc(buddy))
            "Little Buddy looks at Erin and giggles. ";
        else "\"Aw, she's okay,\" he says. ";
    }
    location = school_library
    disavow = "\"I'm busy,\" she says. \"Try me later.\" "
    alreadyTold = "\"I have to tell you twice?\" "
    verDoKick(actor) = {
        "\"Hey!\"\ Erin yelps as you kick her shin. \"What gives?\" ";
    }
    verDoKiss(actor) = {
        "Erin frowns when you kiss her. \"What was that for?\"\ she grumbles. ";
    }
    verDoAttack(actor) = { "You find yourself unable to. "; }
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "Erin grunts in response. ";
            exit;
        }
        pass actorAction;
    }
    
    wantheartbeat = nil
    heartbeat = {
        if (leaveCounter > 0) {
            switch (leaveCounter++) {
                case 1:    // LB runs into the stacks
                buddy.wanderTo(2);
                break;

                case 2:    // LB gets stuck in the grate; Erin leaves
                if (Me.location == buddy.location)
                    "\bLittle Buddy suddenly spies the small shaft, recently
                        opened by you. \"Cool!\"\ he softly breathes. He runs,
                        clambers over the grate, and begins wriggling his way
                        into the shaft. After a few seconds, though, he stops.
                        \"Uh-oh,\" he says. ";
                else if (Me.location == small_crawl)
                    "\bThe light suddenly dims as Little Buddy's head pops
                        into the shaft, followed shortly by his shoulders.
                        \"Hey!\"\ he says, wriggling towards you. Then he
                        stops, frowning. \"Uh-oh,\" he says. ";
                else if (Me.location.isCrawlspace)
                    "\bYou hear scratching echoing in the crawlspace, followed
                        shortly by Little Buddy saying, \"Uh-oh.\" ";
                else if (Me.location == self.location) 
                    "\bFrom the stacks you hear Little Buddy say, \"Uh-oh.\"
                        Erin turns to look at you, grinning. \"You go take
                        care of it,\" she says, gathering up her books and
                        dropping her mostly-spent bottle of lotion on the
                        table. \"I'm outta here.\" And with that, she is. ";
                else
                    "\bFrom somewhere in the library you hear Little Buddy say,
                        \"Uh-oh.\" A moment later, Erin brushes past you.
                        \"LB's gotten himself in a mess, I bet,\" she says
                        as she walks down the hall. ";
                buddy.clearProps;
                buddy.stuckInGrate = 1;
                buddy_front.moveInto(small_crawl);
                buddy.waitingAtShelf = 0; // Stop pausing, Buddy
                notify(buddy, &grateProblems, 2);
                bottle_of_lotion.moveInto(library_tables);
                self.moveInto(nil);
                self.wantheartbeat = nil;
                buddyAh.see;
                break;
            }
        }
        else if (box_of_books.location == self.location) {
            "\bErin glances up as you push the box into the room. Suddenly
                realizing what it is, she jumps up and rushes to it, opening
                it and pawing at the books inside.
                \bAfter a brief search, she triumphantly pulls out an old
                book. \"This is it!\"\ she says excitedly. Her grin is nearly
                blinding. \"Thanks,\" she tells you as she sits back down. ";
            if (buddy.location != school_library) {
                buddy.moveInto(school_library);
                "\bLittle Buddy comes running towards you, then skids to a
                    halt, grinning. ";
            }
            buddy.waitingAtShelf = 1;    // Pause for a moment
            leaveCounter = 1;
        }
        else if (--actionTurn == 0) {
            "\b<<actions[actionNum]>>\n";
            actionNum = RAND(length(actions) - 1) + 1;
            actionTurn = 2 + RAND(3);
        }
    }
;

bottle_of_lotion: item
    stage = '2b'
    noun = 'bottle'
    adjective = 'plastic' 'pink'
    sdesc = "pink bottle"
    ldesc = "A plastic bottle with the label \"Lotion\"\ on its side. "
    smelldesc = lotion.smelldesc
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (lotion.location == self)
            "In the bottom of the bottle is a little bit of lotion. ";
        else "The pink bottle is empty. ";
    }
    verDoSqueeze(actor) = {
        if (lotion.location != self)
            "You squeeze the bottle, but none of the lotion is left. ";
    }
    doSqueeze(actor) = {
        lotion.takedesc;
    }
    doPourOn->lotion
;

lotion: fixedItem
    stage = '2b'
    noun = 'lotion'
    adjective = 'greasy'
    location = bottle_of_lotion
    sdesc = "lotion"
    ldesc = "Only a little of it remains in the bottle. "
    smelldesc = "It smells of lilacs. "
    takedesc = {
        "You squeeze the bottle until what's left of the lotion oozes out
            over your hands. You work the lotion into your hands, but a slight
            greasy feel remains. ";
        self.moveInto(nil);
    }
    verDoPourOn(actor, io) = {
        if (io == buddy_front)
            "He is flailing about too wildly for you to cover him with the
                lotion. ";
        else if (!io.isBodypart && io != buddy)
            "There's no need to pour the lotion on <<io.thedesc>>. ";
    }
    doPourOn(actor, io) = {
        if (io.isBodypart)
            "You rub the lotion onto your <<io.sdesc>>. You continue rubbing
                for a few moments, but a slight greasy feel remains. ";
        else {
            "You pour what's left of the lotion onto Little Buddy's torso. It
                soaks into his clothes and his skin, leaving behind a sheen
                of grease. ";
            buddy.isLotioned = true;
        }
        self.moveInto(nil);
    }
    doSynonym('PourOn') = 'PutOn'
;

library_stacks: school_room
    buddyList = [&ne, 'to the northeast']
    buddyToShelf = 1
    goingOut = nil
    sdesc = "Stacks"
    ldesc = {
        "Rows of books stare blindly down, layered in dust. A path winds
            northeast through the claustrophobic stacks. ";
    }
    smelldesc = "Must and mildew fill your nose. "
    exits = {
        "You can go northeast";
        if (large_grate.isopen)
            " and east";
        ". ";
    }
    east = {
        if (large_grate.isopen) {
            goingOut = true;
            return initial_crawl;
        }
        return self.noexit;
    }
    ne = {
        goingOut = nil;
        return school_library;
    }
    out = (self.ne)
    // Turn off buddy_front when we enter the room [from the shaft]
    enterRoom(actor) = {
        buddy_front.wantheartbeat = nil;
        pass enterRoom;
    }
    leaveRoom(actor) = {
        if (self.goingOut && rope.tiedTo == dog && rope.location == Me) {
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                to avoid being unceremoniously hoisted into the shaft. ";
            exit;
        }
        pass leaveRoom;
    }
;

actual_stacks: fixedItem, readable
    stage = '2b'
    isThem = true
    noun = 'stack' 'row' 'book'
    plural = 'stacks' 'rows' 'books'
    adjective = 'stack' 'stacks' 'row' 'rows'
    location = library_stacks
    sdesc = "library stacks"
    ldesc = "The stacks crowd into the room, leaving just enough space
        for you to slide past them. They are interrupted by two
        grates on the wall. "
    readdesc = "The books are no more interesting now than they were then. "
    smelldesc = "They smell of must and aging information. "
;

large_grate: dthing, fixedItem
    stage = '2b'
    isopenable = true
    isopen = nil
    noun = 'grate'
    plural = 'grates'
    adjective = 'large' 'new' 'upper'
    location = library_stacks
    sdesc = "large grate"
    firstdesc = {
        "You don't remember this grate from your tenure here; it looks
            new. ";
        self.seconddesc;
    }
    seconddesc = {
        "It is just under a meter wide and tall";
        if (self.isopen)
            "; it is hanging from hinges, revealing a shaft
                behind it";
        ". Several screws are missing from around its perimeter. ";
    }
    verDoOpen(actor) = {
        if (self.isopen) "It's already open. ";
    }
    doOpen(actor) = {
        "You pull on the grate, which pops open with surprising ease. Behind
            the grate is a large shaft. ";
        self.setOpen;
    }
    verDoTake(actor) = {
        if (self.isopen) "It refuses to come free. ";
    }
    doTake(actor) = (self.doOpen(actor))
    // This function separated so it can be called by fake_large_grate, &c.
    setOpen = {
        self.isopen = true;
        upper_shaft.moveInto(self.location);
        fake_large_grate.moveInto(nil);    // Take care of our doublewalker
    }
    verDoClose(actor) = {
        if (!self.isopen) "It's already closed.";
    }
    doClose(actor) = {
        "You push the grate back in place, covering the shaft behind it. ";
        self.isopen = nil;
        upper_shaft.moveInto(nil);
        fake_large_grate.moveInto(initial_crawl);
    }
    verIoPutIn(actor) = {
        if (!self.isopen)
            "Not while it's closed. ";
    }
    ioPutIn(actor, dobj) = {
        "%You% place%es% <<dobj.thedesc>> in the shaft. ";
        dobj.moveInto(initial_crawl);
    }
    verDoLookin(actor) = {
        if (!self.isopen)
            "You can't see through the grate. ";
    }
    doLookin(actor) = {
        "%You% see%s% a shaft leading into the wall. ";
    }
    doSynonym('Open') = 'Pull'
    doSynonym('Close') = 'Push'
;

upper_shaft: fixedItem
    stage = '2b'
    noun = 'shaft'
    plural = 'shafts'
    adjective = 'upper' 'large'
    sdesc = "upper shaft"
    ldesc = "It leads into the wall, just wide enough for you. "
    heredesc = {
        "A large grate gapes open in the wall, revealing a shaft leading east";
        if (lower_shaft.location == library_stacks)
            "; below it is an open small grate";
        ". ";
    }
    PutIn -> large_grate
    Lookin -> large_grate
    Close -> large_grate
    verDoEnter(actor) = {}
    doEnter(actor) = {
        library_stacks.goingOut = true;
        actor.travelTo(initial_crawl);
    }
;

small_grate: fixedItem
    stage = '2b'
    isopenable = true
    isopen = nil
    isStuckOpen = nil
    noun = 'grate'
    plural = 'grates'
    adjective = 'small' 'old' 'lower'
    location = library_stacks
    sdesc = "small grate"
    ldesc = {
        "The small grate has been here since time immemorial. ";
        if (self.isopen) {
            "It has been opened, revealing ";
            if (fake_steel_plate.location == lower_shaft)
                "a steel plate";
            else "an open shaft";
            " behind it.";
        }
    }
    verDoOpen(actor) = {
        if (self.isopen) "It's already open. ";
    }
    doOpen(actor) = {
        "You pull on the grate, which pops open with surprising ease. Behind
            the grate is a ";
        if (fake_steel_plate.location == lower_shaft)
            "steel plate";
        else "small shaft";
        ". ";
        self.isopen = true;
        lower_shaft.moveInto(self.location);
        fake_small_grate.moveInto(nil);    // Take care of our doublewalker
    }
    verDoTake(actor) = {
        if (self.isopen) "It refuses to come free. ";
    }
    doTake(actor) = (self.doOpen(actor))
    verDoClose(actor) = {
        if (!self.isopen) "It's already closed.";
        else if (isStuckOpen)
            "The grate must have been twisted when you pushed the box through,
            as it no longer closes properly. ";
        else if (buddy.stuckInGrate > 0)
            "Not while Little Buddy is stuck in the shaft. ";
    }
    doClose(actor) = {
        "You push the grate back in place, covering the shaft behind it. ";
        self.isopen = nil;
        lower_shaft.moveInto(nil);
        fake_small_grate.moveInto(small_crawl);
    }
    verIoPutIn(actor) = {
        if (!self.isopen)
            "Not while it's closed. ";
        else if (fake_steel_plate.location == lower_shaft)
            "The steel plate prevents you. ";
    }
    ioPutIn(actor, dobj) = {
        "%You% place%es% <<dobj.thedesc>> in the shaft. ";
        dobj.moveInto(small_crawl);
    }
    verDoLookin(actor) = {
        if (!self.isopen)
            "You can't see through the grate. ";
        else if (fake_steel_plate.location == lower_shaft)
            "The steel plate prevents you. ";
    }
    doLookin(actor) = {
        "%You% see%s% a shaft leading into the wall. ";
    }
    doSynonym('Open') = 'Pull'
    doSynonym('Close') = 'Push'
;

fake_steel_plate: fixedItem
    stage = '2b'
    noun = 'plate'
    adjective = 'steel'
    location = lower_shaft
    sdesc = "steel plate"
    ldesc = "It is set just inside the lower shaft, preventing access. "
;

lower_shaft: fixedItem
    stage = '2b'
    contentsVisible = true        // For the steel plate
    noun = 'shaft'
    plural = 'shafts'
    adjective = 'lower' 'small'
    sdesc = "lower shaft"
    ldesc = "It leads into the wall. "
    heredesc = {
        if (upper_shaft.location != library_stacks)
            "Standing open in the wall is a small grate. ";
    }
    Close -> small_grate
    verIoPutIn(actor) = { small_grate.verIoPutIn(actor); }
    ioPutIn(actor, dobj) = { small_grate.ioPutIn(actor, dobj); }
    Lookin -> small_grate
    verDoEnter(actor) = {
        "It's much too small for you. ";
    }
;

initial_crawl: school_crawlspace
    ldesc = {
        "The shaft is cramped, squeezing you along your hips, your
            shoulders.  It extends to the east and ";
        if (large_grate.isopen)
            "opens into a room";
        else "ends in a grate";
        " to the west. ";
    }
    exits = 'east and west'
    east = further_crawl
    west = {
        if (!large_grate.isopen) {
            "(Opening the large grate)\n";
            large_grate.setOpen;
        }
        return library_stacks;
    }
    // If Little Buddy is stuck, we should hear the commotion
    enterRoom(actor) = {
        if (buddy_front.location == small_crawl)
            buddy_front.wantheartbeat = true;
        pass enterRoom;
    }
;

fake_large_grate: fixedItem
    stage = '2b'
    isopenable = true
    noun = 'grate'
    location = initial_crawl
    sdesc = "grate"
    ldesc = "It is just under a meter wide and tall. It blocks your progress
        to the west. "
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You hit the grate with the edge of your hand; it rings from the
            impact, then falls open. ";
        large_grate.setOpen;               // Open the grate
    }
    verDoLookin(actor) = { "You can't see through the grate. "; }
;

further_crawl: school_crawlspace
    ldesc = "The shaft widens here, offering a modicum of breathing room.
        It branches, leading up, down, and west. "
    exits = 'west, up, and down'
    west = initial_crawl
    up = upper_crawl
    down = small_crawl
;

small_crawl: school_crawlspace
    firstEast = true
    ldesc = {
        "A curve in the crawlspace has brought you west of the passage leading
            up.  To the west, the crawlspace narrows cruelly until it ends
            in ";
        if (!steel_plate.isRaised)
            "a steel plate";
        else {
            if (!small_grate.isopen)
                "a grate";
            else "a hole";
            " above which a steel plate hangs";
        }
        ". In front of the plate is a thin opening in the top of the
            crawlspace";
        if (rope.location == crawl_pulley)
            "; a rope dangles from it";
        ". ";
    }
    exits = 'east'
    firstseen = { plateAh.see; pass firstseen; }
    west = {
        if (!steel_plate.isRaised || !small_grate.isopen) {
            "You can't go that way. ";
            return nil;
        }
        "The opening is too small for you. ";
    }
    east = {
        if (self.firstEast) {
            "You climb up the curve in the crawlspace to the junction above
                and to the east.\b";
            self.firstEast = nil;
        }
        return further_crawl;
    }
    up = (self.east)
;

thin_opening: fixedItem
    noun = 'opening'
    adjective = 'thin'
    location = small_crawl
    sdesc = "thin opening"
    ldesc = "It is about ten centimeters back to front and runs along the
        ceiling from one wall to the other.  You cannot tell how deep it is.
        Inside it is a pulley; beyond that, the opening is lost in
        darkness. "
    verDoLookIn(actor) = { "You see a pulley. "; }
;

crawl_pulley: fixedItem
    contentsVisible = true
    contentsReachable = true
    noun = 'pulley'
    location = small_crawl
    sdesc = "pulley"
    ldesc = {
        "The pulley is affixed to one side of the thin opening and is just
            within your reach. ";
        if (rope.location == self)
            "Dangling from the pulley is a rope. ";
    }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (dobj != rope) {
            "There's no good way to put <<dobj.thedesc>> on the pulley. ";
            return;
        }
        if (rope.location == self) {
            "The rope is already draped over the pulley. ";
            return;
        }
        "You reach up and, after some fumbling, loop the rope over the pulley. ";
        rope.moveInto(self);
    }
    verIoTieTo(actor) = {}
    ioTieTo(actor, dobj) = {
        "There's no need to tie <<dobj.thedesc>> to the pulley. ";
    }
    verDoPull(actor) = { "Hah, hah. "; pass verDoPull; }
    verDoTurn(actor) = {}
    doTurn(actor) = {
        if (rope.location == self) {
            "The rope slides off the pulley and puddles on the floor. ";
            rope.moveInto(small_crawl);
        }
        else "The pulley turns smoothly. ";
    }
;

steel_plate: fixedItem
    stage = '2b'
    isRaised = nil
    noun = 'plate'
    adjective = 'steel'
    location = small_crawl
    sdesc = "steel plate"
    ldesc = {
        "The steel plate ";
        if (!self.isRaised)
            "blocks further progress west. A small protrusion juts from
                its upper edge";
        else "hangs over the west exit, suspended somehow in a thin opening
            above your head. Its edge is wickedly sharp";
        ". ";
    }
    touchdesc = {
        if (gloves.isworn) {
            "You can't make out any details through the gloves. ";
            return;
        }
        if (self.isRaised)
            "You run a finger along the bottom edge of the plate, verifying
                how sharp the plate is. Why someone didn't blunt the edge
                is a mystery. ";
        else "It is cool to the touch. ";
    }
    verDoPull(actor) = {
        if (self.isRaised)
            "The plate has already been raised. ";
        else "Given your awkward position, you can only raise the plate a
            few inches before having to drop it again. ";
    }
    doSynonym('Pull') = 'Open' 'Push'
    verIoTieTo(actor) = {}
    verDoLower(actor) = {
        if (self.isRaised)
            "The plate is locked in place. ";
        else "The plate is already lowered. ";
    }
    verDoRaise(actor) = {
        if (rope.tiedTo != self)
            self.verDoPull(actor);
    }
    doRaise(actor) = {
        rope.doPull(actor);
    }
;

plate_protrusion: fixedItem
    noun = 'protrusion' 'handle'
    adjective = 'small' 'rounded'
    location = steel_plate
    sdesc = "small protrusion"
    ldesc = "It is a small, rounded bar which has been welded to the top of
        the plate. It resembles a handle. "
    ioTieTo->steel_plate
    doPull->steel_plate
    doOpen->steel_plate
    doPush->steel_plate
    doRaise->steel_plate
    doLower->steel_plate
;

fake_small_grate: fixedItem
    stage = '2b'
    isopenable = true
    noun = 'grate'
    location = small_crawl
    sdesc = "grate"
    ldesc = "A small grate which blocks your progress to the west. "
    verDoOpen(actor) = {}
    doOpen(actor) = {
        "You push against the grate, which gives way with surprising ease. ";
        small_grate.isopen = true;
        lower_shaft.moveInto(small_grate.location);
        fake_small_grate.moveInto(nil);    // Take care of our doublewalker
    }
    verDoLookin(actor) = { "You can't see through the grate. "; }
    doSynonym('Open') = 'Push'
;

upper_crawl: school_crawlspace
    ldesc = {
        "The shaft continues below you, forcing you to brace yourself
            against its sides. Above you is ";
        if (second_floor_grate.isopen) "an opening";
        else "a grate";
        ". ";
    }
    exits = {
        "You can go ";
        if (fake_second_grate.location == nil)
            "up and ";
        "down. ";
    }
    up = {
        if (fake_second_grate.location == nil)
            return school_storage_closet;
        "The grate prevents you. ";
        return nil;
    }
    down = further_crawl
    // Let us hear Little Buddy!
    enterRoom(actor) = {
        if (buddy_front.location == small_crawl)
            buddy_front.wantheartbeat = true;
        pass enterRoom;
    }
;

fake_second_grate: fixedItem
    stage = '2b'
    isopenable = true
    noun = 'grate'
    location = upper_crawl
    sdesc = "grate"
    ldesc = "Just under a meter wide and tall. It blocks the crawlspace
        above your head. "
    verDoOpen(actor) = {
        if (school_padlock.location == second_floor_grate)
            "The grate refuses to move. ";
    }
    doOpen(actor) = {
        "You push the grate open, nearly slipping further down the shaft. ";
        second_floor_grate.isopen = true;
        second_floor_shaft.moveInto(second_floor_grate.location);
        self.moveInto(nil);    // Take care of our doublewalker
    }
    verDoLookin(actor) = { "You can't see through the grate. "; }
    verDoKick(actor) = {}
    doKick(actor) = {
        "You brace yourself against the sides of the shaft with your back and
            one leg. With the other, you stretch up and kick the grate as
            hard as you can. ";
        if (school_padlock.location == second_floor_grate) {
            "The grate doesn't budge. The shock travels up your leg and into
                your body, causing you to slip down the shaft before you catch
                yourself.\b";
        }
        else {
            local l;

            "The grate pops open. Surprised, you lose your purchase and slip
                down the shaft before you catch yourself.\b";
            l = outhide(true);
            self.doOpen(actor);
            outhide(l);
        }
        actor.travelTo(further_crawl);
    }
;

ne1_end: school_hall
    buddyList = [&nw, 'to the northwest', &sw, 'to the southwest']
    buddyToShelf = 2
    sdesc = "Northwest-Southwest Bend"
    ldesc = "The hallway curves, its two ends pointing northwest and
        southwest. By a trick of acoustics, the sounds of the building are
        amplified and collected here. "
    listendesc = "You can hear the building settling its tired bones. "
    exits = 'northwest and southwest'
    nw = nw1_end
    sw = mid1_hall_two
;

nw1_end: school_hall
    floating_items = [school_stairs_up, glass_doors]
    buddyList = [&up, 'up the stairs', &se, 'down the hall']
    buddyToShelf = 2
    sdesc = "Northwest End"
    ldesc = "To the northwest, glass doors end the hallway's run. A flight
        of stairs to the southwest leads to the second floor, while the
        hallway stretches onwards to the southeast. "
    exits = 'southeast and up'
    nw = glass_doors
    se = ne1_end
    sw = nw2_end
    up = nw2_end
;

janitor: trackActor
    selfDisambig = true
    stage = '2b'
    isHim = true
    cleaningChemicals = 0
    movingToChemicals = nil
    isPaused = nil   // Pauses the janitor, for when player's @ beach (eggs.t)
    myfollower = janitor_follower
    motionList = [['se'] ['sw'] ['sw'] ['sw'] ['ne'] ['ne'] ['ne'] ['nw']]
    actions = [
        'The janitor hits his broom against the floor a few times, then resumes
            sweeping. '
        'The janitor reaches the end of one long sweep, then turns around and
            begins heading in the other direction. '
        'Having made a small pile of dust, the janitor produces a dustpan,
            scoops up the dust, and dumps it in his cart. '
    ]
    actionNum = 1

    noun = 'janitor'
    location = nw1_end
    sdesc = "janitor"
    thedesc = "the janitor"
    adesc = "a janitor"
    stringsdesc = 'The janitor'
    ldesc = {
        "He is stooped but still quite nimble. His grey steel-wool hair is
            swept back from his wind-burned face. ";
        if (movingToChemicals)
            "Currently he is walking down the hall at a good clip. ";
        else if (cleaningChemicals != 0)
            "He is on hands and knees, mopping up a puddle of chemicals. ";
        else "With the aid of a broom he is sweeping the tile. ";
    }
    janitordesc = "The janitor laughs. \"You know I ain't got time to give
        you mah history. I gots'ta work.\" "
    buddydesc = {
        if (uberloc(self) == uberloc(buddy))
            "Little Buddy cuts his eyes at the janitor and giggles. ";
        else "\"He's cool. He lets me follow him sometimes.\" ";
    }
    askme = &janitordesc
    actorDesc = {
        if (cleaningChemicals != 0)
            "A janitor is on hands and knees cleaning up the chemical spill. ";
        else if (movingToChemicals)
            "Striding down the hall is a janitor, paper towels clutched in his
                hands. ";
        else "A janitor pushes a broom around the hallway. ";
    }
    leavedesc(dirStr) = {
        "\bThe janitor pushes his cart <<dirStr>>. ";
    }
    arrivedesc(dirStr) = {
        "\bThe janitor arrives from the <<dirStr>>, pushing his cart. ";
        janitor_cart.moveInto(self.location);
        cart_castors.moveInto(self.location);
    }
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "The janitor's face crinkles as he smiles. \"Why, hello, Terry.\" ";
            exit;
        }
        else pass actorAction;
    }
    disavow = "He scratches his head. \"Can't say I can help you with that.\" "
    alreadyTold = "He scratches his head. \"Thought I already told you about
        that.\" "
    verDoKick(actor) = {
        "The janitor shuffles out of your way. \"Now why you wanna kick me?\"\ 
            he asks you. ";
    }
    verDoKiss(actor) = {
        "The janitor waves you off. \"Now don't you go messin with mah mind,\"
            he says. ";
    }
    ioGiveTo(actor, dobj) = {
        if (dobj != key_ring)
            "The janitor shakes his head. \"Now what'd I do with that?\"\ he
                asks. ";
        else {
            "\"Mah keys!\"\ he says, snatching them from your grasp. He glares
                at you for a second before pocketing the key ring. ";
            key_ring.moveInto(nil);
        }
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (dobj != key_ring)
            "The janitor just shakes his head and laughs. ";
        else {
            "\"Mah keys!\"\ he says, snatching them from your grasp. He glares
                at you for a second before pocketing the key ring. ";
            key_ring.moveInto(nil);
        }
    }
    heartbeat = {
        // Don't do anything if paused, i.e. the player's @ the beach (eggs.t)
        if (isPaused) {
            moveTurn++;        // Put off action & moving for another turn
            actionTurn++;
            return;
        }

        // Handle moving to the chemical spill
        if (movingToChemicals) {
            local i;

            moveTurn++;        // Put off action & moving for another turn
            actionTurn++;
            i = self.location.buddyToShelf;
            if (Me.location == self.location)
                "\bThe janitor jogs <<self.location.buddyList[i*2]>>. ";
            self.moveInto(self.location.(self.location.buddyList[i*2-1]));
            if (Me.location == self.location)
                "\bThe janitor comes running down the hall. ";
            if (chemical_mess.location == self.location) {
                movingToChemicals = nil;
                cleaningChemicals = 1;
            }
            return;
        }

        // Handle cleaning the chemicals
        if (cleaningChemicals != 0) {
            moveTurn++;        // Put off action & moving for another turn
            actionTurn++;
            if (Me.location == self.location) {
                switch(cleaningChemicals) {
                    case 1:
                        "\bThe janitor begins swabbing up the chemical spill. ";
                        break;
                    case 3:
                        "\bThe chemical spill is shrinking as you watch. ";
                        break;
                    case 5:
                        "\bThe janitor has almost finished cleaning the spill. ";
                        break;
                    case 7:
                        "\bThe janitor finishes sopping up the chemical spill
                            and strides back down the hall. ";
                        break;
                    default:
                }
            }
            if (cleaningChemicals == 7) {
                chemical_mess.moveInto(nil);
                janitor.moveInto(janitor_cart.location);
                if (Me.location == self.location)
                    "\bThe janitor strolls down the hall and reaches his
                        cart. ";
                cleaningChemicals = 0;
            }
            else cleaningChemicals++;
            return;
        }
        if (motionListNum > length(motionList))
            motionListNum = 1;
        inherited.heartbeat;
        if (hasArrived) {
            moveTurn = global.turnsofar + length(actions)*2 + 2;
            actionTurn = global.turnsofar + 2;
            janitor_cart.moveInto(self.location);
            cart_castors.moveInto(self.location);
            if (pile_of_books.location == self.location) {
                if (Me.location == self.location)
                    "He glances at the pile of books. \"Mah, mah,
                        mah,\" he says, shaking his head. With a flourish he
                        produces a small dustpan and his broom. In one sweep
                        he manages to load all of the books onto his dustpan;
                        he then tosses them into his cart before the entire
                        pile can collapse. ";
                pile_of_books.moveInto(limbo);
            }
        }
    }
    actionDaemon = {
        if (Me.location == self.location)
            "\b<<actions[actionNum]>>\n";
        if (actionNum == length(actions))
            actionNum = 1;
        else {
            actionTurn = global.turnsofar + 2;
            actionNum++;
        }
    }
;

janitor_follower: follower
    stage = 0
    noun = 'janitor'
    myactor = janitor
;

janitor_broom: item
    stage = '2b'
    noun = 'broom'
    location = janitor
    sdesc = "broom"
    ldesc = "It belongs to the janitor. "
    janitordesc = "He says, \"Tool of mah trade.\" "
;

janitor_cart: fixedItem, qcontainer
    stage = '2b'
    noun = 'cart' 'bag' 'bin'
    adjective = 'plastic' 'garbage'
    location = nw1_end
    sdesc = "cart"
    ldesc = {
        local list, i;

        "The cart is merely a plastic frame on castors with an attached
            garbage bag. ";
        if (key_ring.location == self) {
            lockedDoorsAh.solve;
            keysAh.see;
            "Hanging from one corner of the frame is a large keyring. ";
        }
        list = contlist(self);
        if ((i = find(list, key_ring)) != nil)
            list -= key_ring;
        if (length(list) > 1)
            "In the garbage bag %you% see%s% <<listlist(list)>>. ";
    }
    hdesc = "Sitting in the middle of the hall is a cart. "
    takedesc = "The cart is much too big. "
    janitordesc = "He says, \"Tool of mah trade.\" "
    verGrab(obj) = {
        if (janitor.location == self.location) {
            "The janitor stops you. ";
            if (obj == key_ring) {
                "\"Y'can't have my keys, Terry. I need my keys.\" ";
                lockedDoorsAh.solve;
            }
            else "\"Don't you have no more sense than to be rooting around in
                garbage?\" ";
        }
    }
    verDoLookin(actor) = {
        "Oddly enough, it is completely empty. ";
    }
    verDoPush(actor) = {
        "The janitor would surely notice. ";
    }
    doSynonym('Push') = 'Move' 'MoveN' 'MoveS' 'MoveE' 'MoveW' 'MoveNE'
        'MoveNW' 'MoveSE' 'MoveSW' 'Pull'
    verIoTieTo(actor) = {}
;

cart_castors: fixedItem
    noun = 'castor' 'castors' 'caster' 'casters'
    location = nw1_end
    sdesc = "castors"
    ldesc = "They are attached to the bottom of the cart. "
;

key_ring: keyItem, treasure
    isThem = true
    noun = 'ring' 'key' 'keys' 'keyring'
    location = janitor_cart
    weight = 3
    bulk = 5
    worth = 5        // Worth 5 points
    sdesc = "ring of keys"
    ldesc = {
        "A group of keys on a metal ring whose circumference is nearly that
            of your outstretched hand from pinky to thumb. The keys open
            most every door in this building. ";
        keysAh.see;
    }
    janitordesc = {
        if (self.location == janitor_cart ||
            janitor.location != janitor_cart.location)
            "He grins. \"I gots'ta have 'em to get places.\" ";
        else "He glances at his cart and hisses between his teeth. \"I
            misplaced mah keys again,\" he says. ";
    }
    adesc = "a ring of keys"
    buddydesc = 'The janitor\'s keys? Ahh, he\'s real careful about them.
        \'Least, he won\'t let _me_ see them.'
    firstMove = { lockedDoorsAh.solve; keysAh.solve; pass firstMove; }
;

sw2_end: school_hall
    floating_items = [school_stairs_down]
    buddyList = [&down, 'to the stairs and slides down the handrail', &ne,
        'down the hall']
    buddyToShelf = 1
    sdesc = "Second Floor, Southwest End"
    ldesc = "The hall from the northeast ends here, brought up short by a
        flight of stairs to the northwest. A lone cracked window graces the
        wall by the stairs. "
    exits = 'northeast and down'
    down = sw1_end
    nw = sw1_end
    ne = mid2_hall_one
;

cracked_window: fixedItem
    stage = '2b'
    noun = 'window'
    adjective = 'cracked' 'lone' 'cold'
    location = sw2_end
    sdesc = "cracked window"
    ldesc = "Though you assume the window to be transparent, you can see
        nothing but grey through it. Bone-chilling cold seeps through the
        crack in its pane. "
    touchdesc = {
        "It is horribly cold";
        if (gloves.isworn) ", even through the gloves";
        ". ";
    }
    verDoOpen(actor) = { "You find that it has been painted shut. "; }
    verDoLookthru(actor) = {}
    doLookthru(actor) = "No matter how hard you strain your eyes, you can make
        out nothing but grey. "
    verDoBreak(actor) = {}
    doBreak(actor) = {
        "You bring your fist back, then plunge it into the weakened glass.
            It gives way in a soundless shower of glinting shards. Grey
            pours in through the gap in the window, covering the floor, your
            shins, your arms, and finally your head.\b
            It is what you imagine drowning in cotton candy would be like.\b";
        die();
    }
;

mid2_hall_one: school_hall
    buddyList = [&ne, 'to the northeast', &sw, 'to the southwest']
    buddyToShelf = 2
    sdesc = "Second Floor Hall"
    ldesc = "The northeast-southwest hall is flanked on either side by
        doors, one to the northwest, the other to the southeast. "
    exits = {
        "You can go northeast";
        if (!storage_door.islocked)
            ", southeast,";
        " and southwest. ";
    }
    ne = mid2_hall_two
    nw = mid2_hall_door
    se = storage_door
    sw = sw2_end
;

mid2_hall_door: mist_door
    openedOnce = 0
    adjective = 'northwest' 'nw'
    location = mid2_hall_one
    sdesc = "northwest door"
    doOpen(actor) = {
        if (openedOnce == 0) {
            "You open the door, finding a swirling grey mist behind it.
                The mist swirls invitingly; you flinch back, slamming shut
                the door. ";
            openedOnce++;
        }
        else if (openedOnce == 1) {
            "This time the mist reaches out and envelops you. You step
                forward, falling into an empty grey space which shades to
                white, until you land softly.\b";
            // Drop the rope if we're carrying it & it's tied to the dog
            if (rope.tiedTo == dog && rope.location == Me)
                rope.moveInto(self.location);
            Me.travelTo(beach1);
            notify(the_author, &chatter, 2);
            notify(beach1, &moveMe, 1);
            buddy.isPaused = true;    // Make LB pause
            dog.isPaused = true;      // Same w/the dog
            janitor.isPaused = true;  //  and with the janitor
            openedOnce++;
        }
        else "You find yourself loathe to open the door again. ";
    }
;

storage_door: school_door
    adjective = 'southeast' 'se'
    location = mid2_hall_one
    sdesc = "southeast door"
    ldesc = "The door looks much older than the other doors you've seen. "
    otherside = inside_storage_door
    doordest = school_storage_closet
;

school_storage_closet: school_room
    noDog = { return !(storage_door.isopen); }
    noBuddy = true
    goingOut = nil
    sdesc = "Storage Closet"
    ldesc = "The room is dim and confining. Odd smells mix with the scent of
        cleaners; no doubt this was once a chemical storage room. "
    smelldesc = "Acidic odors assault you, making your eyes water. "
    exits = {
        "You can go northwest";
        if (second_floor_grate.isopen)
            " and down";
        ". ";
    }
    nw = {
        goingOut = nil;
        return inside_storage_door;
    }
    down = {
        if (second_floor_grate.isopen) {
            goingOut = true;
            return upper_crawl;
        }
        return self.noexit;
    }
    out = (self.nw)
    enterRoom(actor) = {
        buddy_front.wantheartbeat = nil;
        pass enterRoom;
    }
    firstseen = {
        grateAh.see;
        boxAh.see;
        pass firstseen;
    }
    leaveRoom(actor) = {
        if (self.goingOut && rope.tiedTo == dog && rope.location == Me) {
            "<<dog.capdesc>> plants all four feet on the ground and digs in,
                to avoid being unceremoniously hoisted into the shaft. ";
            exit;
        }
        pass leaveRoom;
    }
    roomAction(a, v, d, p, i) = {
        if (a == Me && v.touch && ((d && d.location == school_padlock &&
            d != thermoelectric_cooler) ||
            (i && i.location == school_padlock &&
            i != thermoelectric_cooler)) &&
            !(v == takeVerb && p == withPrep)) {
            "The padlock prevents you. ";
            exit;
        }
        pass roomAction;
    }
;

second_floor_grate: fixedItem, surface
    stage = '2b'
    contentsVisible = true        // For the padlock
    contentsReachable = true
    isopenable = true
    isopen = nil
    noun = 'grate'
    location = school_storage_closet
    sdesc = "grate"
    ldesc = {
        local list;
        
        "The grate is set in the floor. ";
        if (!self.isopen) {
            "It is closed";
            if (school_padlock.location == self)
                " and locked with a padlock";
            list = contlist(self);
            if (length(list) > 0)
                ". Sitting on the grate you see <<listlist(list)>>";
        }
        else "It is open, revealing a shaft leading down";
        ". ";
    }
    heredesc = {
        "A large grate ";
        if (!self.isopen)
            "is set in the floor. ";
        else "gapes open in the floor, revealing a shaft leading down. ";
    }
    showcontents = {
        local list;
        
        list = contlist(self);
        if (length(list) > 0)
            "Sitting on the grate you see <<listlist(list)>>. ";
        school_padlock.showcontents;
    }
    verDoOpen(actor) = {
        if (self.isopen) "It's already open. ";
        else if (school_padlock.location == self)
            "The padlock prevents you. ";
    }
    doOpen(actor) = {
        local list;
        
        "You tug at the grate, which swings open";
        list = contlist(self);
        if (length(list) > 0) {
            ", dumping its contents on the floor";
            moveAllCont(self, school_storage_closet);
        }
        ". Beneath it is a shaft leading down. ";
        self.isopen = true;
        second_floor_shaft.moveInto(self.location);
        fake_second_grate.moveInto(nil);    // Take care of our doublewalker
    }
    verDoClose(actor) = {
        if (!self.isopen) "It's already closed.";
    }
    doClose(actor) = {
        "You push the grate back in place, covering the shaft beneath it. ";
        self.isopen = nil;
        second_floor_shaft.moveInto(nil);
        fake_second_grate.moveInto(upper_crawl);
    }
    verDoLookin(actor) = {
        if (!self.isopen)
            "You can't see through the grate. ";
    }
    doLookin(actor) = {
        "%You% see%s% a shaft leading into the floor. ";
    }
    doSynonym('Open') = 'Pull'
    doSynonym('Close') = 'Push'
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (self.isopen) {
            second_floor_shaft.ioPutIn(actor, dobj);
            return;
        }
        if (dobj == box_of_books)
            "There is no need. ";
        else if (dobj.bulk < 2) {
            "\^<<dobj.thedesc>> falls through the grate and into the depths. ";
            dobj.moveInto(small_crawl);
        }
        else pass ioPutOn;
    }
    verIoPutIn(actor) = {
        if (!self.isopen)
            pass verIoPutIn;
    }
    ioPutIn(actor, dobj) = { second_floor_shaft.ioPutIn(actor, dobj); }
;

second_floor_shaft: fixedItem
    stage = '2b'
    noun = 'shaft'
    plural = 'shafts'
    sdesc = "shaft"
    ldesc = "It leads into the floor, just wide enough for you. "
    Lookin -> large_grate
    verDoEnter(actor) = {
        school_storage_closet.goingOut = true;
        actor.travelTo(upper_crawl);
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (rope.tiedTo == dobj) {
            "%You% dangle <<dobj.thedesc>> down the shaft. After a minute,
                you draw <<dobj.thedesc>> back up. ";
            return;
        }
        if (dobj == box_of_books) {
            "%You% push%es% the box into the shaft. It vanishes, followed
                shortly by a loud whump. ";
            boxAh.solve;
        }
        else "\^<<dobj.thedesc>> vanishes into the shaft, followed shortly
            by the sound of it hitting bottom. ";
        dobj.moveInto(small_crawl);
    }
    ioSynonym('PutIn') = 'PutOn'
    doUnlockWith->school_padlock
;

school_padlock: fixedItem
    stage = '2b'
    contentsVisible = true
    contentsReachable = true
    isWet = nil                // For the water drop inside the blue field
    noun = 'padlock' 'lock'
    adjective = 'old' 'rusty' 'rusted'
    location = second_floor_grate
    sdesc = "rusty padlock"
    ldesc = {
        "The padlock is rusted shut. ";
        if (self.isWet)
            "Water drips from inside it. ";
        if (thermoelectric_cooler.location == self)
            "The ceramic square is balanced atop it. ";
    }
    touchdesc = {
        if (thermoelectric_cooler.location != self ||
            thermoelectric_cooler.coolLevel == 0)
            "The rust crackles as you rub your finger along the padlock. ";
        else if (gloves.isworn)
            "All you can tell through the gloves is that the padlock is cool. ";
        else switch (thermoelectric_cooler.coolLevel) {
            case 1:
                "The padlock feels cool. ";
                break;
            case 2:
                "It is noticeably colder than the surrounding air. ";
                break;
            case 3:
                "The padlock is freezing. ";
        }
    }
    verGrab(obj) = {
        if (isclass(obj, blue_field))
            "It is too deep within the padlock to be reached. ";
    }
    showcontents = {
        if (thermoelectric_cooler.location == self)
            "Sitting on the padlock is the ceramic square. ";
    }
    verDoOpen(actor) = { "It's too rusted for that. "; }
    verDoBreak(actor) = {
        "Despite its weathered condition, it resists your efforts to smash
            it. ";
    }
    verIoTieTo(actor) = {}
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (!isclass(dobj, blue_field) ||
            !isclass(dobj.fieldItem, water_drop)) {
            "\^<<dobj.thedesc>> won't fit inside the padlock. ";
            return;
        }
        "You put the blue sphere inside the padlock. It vanishes into the
            workings of the lock. ";
        dobj.moveInto(self);
    }
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (isclass(dobj, blue_field))
            return self.ioPutIn(actor, dobj);
        if (dobj != thermoelectric_cooler) {
            "There's no good place to put <<dobj.thedesc>> on the padlock. ";
            return;
        }
        "%You% place%s% <<dobj.thedesc>> on the padlock. ";
        if (dobj.coolLevel == 3 && self.isWet) // Check TEC in one turn
            notify(self, &checkTEC, 2);
        dobj.moveInto(self);
    }
    checkTEC = {
        if (thermoelectric_cooler.location == self &&
            thermoelectric_cooler.coolLevel == 3)
            self.coolDown;
    }
    coolDown = {
        thermoelectric_cooler.moveInto(uberloc(self));
        self.moveInto(nil);
        if (Me.location == thermoelectric_cooler.location)
            "\bYou hear a cracking sound from deep within the padlock. Seconds
                later the padlock explodes in a flurry of rust, the water
                inside it having turned to ice. The ceramic square falls to the
                floor as the remains of the padlock drift through the grate. ";
        else "\bYou jump at a loud cracking sound which echoes about the
            building. ";
        incscore(5);
        notify(schoolMessages, &summonMessage, 1);
        grateAh.solve;
    }
    verDoUnlock(actor) = { "The padlock is too filled with rust. "; }
    verDoUnlockWith(actor, io) = {
        if (io == key_ring)
            "The rust is too thick inside the padlock. ";
        else pass verDoUnlockWith;
    }
;

inside_storage_door: school_door
    location = school_storage_closet
    otherside = storage_door
    doordest = mid2_hall_one
;

box_of_books: rollItem, openable, readable
    contentsVisible = true
    contentsReachable = true
    verGrab(obj) = {
        if (obj == rope && obj.tiedTo == self)
            "Not until you untie the rope. ";
    }
    stage = '2b'
    down_stairs = nil
    isopen = nil
    noun = 'box' 'label'
    plural = 'boxes' 'labels'
    adjective = 'cardboard'
    location = school_storage_closet
    sdesc = "cardboard box"
    ldesc = {
        "The box has been used repeatedly, judging from the many crossed-out
            labels which cover its surface. ";
        if (self.isopen)
            "Inside the box, books fill all the available space. ";
        else if (rope.tiedTo == self)
            "The rope is looped around it, holding it shut. ";
        else "Its top flap is closed. ";
    }
    hdesc = "Lying in the middle of the floor is a cardboard box. "
    takedesc = "The box is too heavy. "
    readdesc = "There are so many labels and so many crossed-out scribblings
        that the sum total is unreadable. "
    movedesc(dir) = "You slide the box <<dir>>.\b"
    verDoLookin(actor) = {
        if (!self.isopen)
            "With the box closed, you cannot look in it. ";
        else "The box is filled with books. ";
    }
    verDoKick(actor) = { "You stub your toe and do the box no damage. "; }
    verDoPutIn(actor, iobj) = {
        if (iobj != second_floor_shaft && iobj != second_floor_grate)
            "You can't pick up the box to put it in <<iobj.thedesc>>. ";
    }
    verDoPutOn(actor, iobj) = {
        if (iobj != second_floor_shaft && iobj != second_floor_grate)
            "You can't pick up the box to put it on <<iobj.thedesc>>. ";
    }
    verDoOpen(actor) = {
        if (rope.tiedTo == self)
            "The rope prevents you. ";
        else pass verDoOpen;
    }
    verIoTieTo(actor) = {}
    ioTieTo(actor, dobj) = {
        if (dobj != rope) pass ioTieTo;
        "You ";
        if (self.isopen) {
            self.isopen = nil;
            "close the flaps, ";
        }
        "loop the rope around the box and tie a quick knot. ";
        rope.moveInto(self);
        rope.tiedTo = self;
    }
    verIoPutIn(actor) = {
        if (!self.isopen) "The box isn't open. ";
        else "The books leave no room. ";
    }
    check_dir(dir) = {
        if ((dir == &nw && (self.location == sw1_end)) ||
            (dir == &sw && (self.location == nw1_end)))
            return nil;
        if ((dir == &nw && (self.location == sw2_end)) ||
            (dir == &sw && (self.location == nw2_end))) {
            self.goTo = self.location.(dir);
            self.down_stairs = true;
            return true;
        }
        if (dir == &nw && self.location == school_storage_closet) {
            self.goTo = inside_storage_door.doordest;
            return inside_storage_door.isopen;
        }
        if (dir == &west && self.location == small_crawl &&
            steel_plate.isRaised && small_grate.isopen) {
            small_grate.isStuckOpen = true;
            return true;
        }
        if (dir == &ne && (self.location == library_stacks)) {
            self.goTo = self.location.(dir);
            return true;
        }
        pass check_dir;
    }
    verDoMoveNW(actor) = {
        if (self.location == nw2_end && deans_door.isopen)
            return;
        else pass verDoMoveNW;
    }
    doMoveNW(actor) = {
        if (self.down_stairs) {
            "The crate teeters at the edge of the stairs, then commences a
                slow-motion tumble. At each impact, more of the box rips
                and shreds. ";
            if (rope.tiedTo == self) {
                rope.tiedTo = nil;
                "The knot in the rope works free, allowing what's left of
                    the box to fly open. ";
                rope.moveInto(self.goTo);
            }
            "The box is soon replaced
                by a spray of books which lands at the foot of the stairs.
                Alarmed, you race after.\b";
            self.moveInto(nil);
            self.down_stairs = nil;
            pile_of_books.moveInto(self.goTo);
            actor.travelTo(self.goTo);
        }
        else if (self.location == nw2_end)
            nwVerb.action(actor);
        else pass doMoveNW;
    }
    doMoveSW(actor) = {
        if (self.down_stairs) {
            "The crate teeters at the edge of the stairs, then commences a
                slow-motion tumble. At each impact, more of the box rips
                and shreds. ";
            if (rope.tiedTo == self) {
                rope.tiedTo = nil;
                "The knot in the rope works free, allowing what's left of
                    the box to fly open. ";
                rope.moveInto(self.goTo);
            }
            "The box is soon replaced
                by a spray of books which lands at the foot of the stairs.
                Alarmed, you race after.\b";
            self.moveInto(nil);
            self.down_stairs = nil;
            pile_of_books.moveInto(self.goTo);
            actor.travelTo(self.goTo);
        }
        else pass doMoveSW;
    }
    verDoMoveE(actor) = {
        if (self.location == small_crawl)
            "The crawlspace slopes too sharply for you to push the box up it. ";
        else pass verDoMoveE;
    }
    verDoMoveW(actor) = {
        if (self.location == small_crawl) {
            if (!steel_plate.isRaised)
                "The steel plate prevents you. ";
            else if (!small_grate.isopen)
                "The small grate blocks your way. ";
            else pass verDoMoveW;
        }
        else pass verDoMoveW;
    }
    doMoveW(actor) = {
        if (self.location == small_crawl) {
            self.moveInto(library_stacks);
            "You push the box through the opening into the room beyond. ";
            return;
        }
        pass doMoveW;
    }
;

pile_of_books: fixedItem, readable
    stage = '2b'
    isThem = true
    noun = 'book' 'pile'
    plural = 'books'
    adjective = 'pile' 'gigantic'
    sdesc = "pile of books"
    ldesc = "The box of books has mushroomed into an enormous pile of books
        which sprawls over the bottom step and the floor around the stairs,
        more books than could have ever fit in that box. "
    hdesc = "A gigantic pile of books spills over the bottom step and onto the
        floor. "
    takedesc = "You pick up one book, then another, then another, before giving
        up and replacing all of the books. There must be four, five times
        the number of books now than there were when they were in the box. "
    readdesc = "There are too many to choose from, all on uninteresting
        topics. "
;

mid2_hall_two: school_hall
    buddyList = [&ne, 'to the northeast', &sw, 'to the southwest']
    buddyToShelf = 2
    sdesc = "Second Floor Hall"
    ldesc = "The hall's blue-tinted lighting, reflected weakly by the floor,
        gives everything a sickly cast. A door to the southeast breaks the
        monotony. "
    exits = 'northeast and southwest'
    ne = ne2_end
    se = mid2_hall_door_two
    sw = mid2_hall_one
;

mid2_hall_door_two: mist_door
    adjective = 'southeast' 'se'
    location = mid2_hall_two
;

ne2_end: school_hall
    buddyList = [&nw, 'to the northwest', &sw, 'to the southwest']
    buddyToShelf = 1
    leaveList = [leaky_pipe]
    sdesc = "Northwest-Southwest Bend"
    ldesc = "The hall bends here, pointing northwest and southwest. At the
        middle of the kink, to the northeast, is <<
        demo_door.aWordDesc>> door. "
    listendesc = "You can hear the building settling its tired bones. "
    smelldesc = "You smell mildew. "
    ceildesc = "A broken pipe juts from the ceiling. "
    floordesc = {
        "A thin coat of ";
        if (ice_slick.location == self) "ice";
        else "water";
        " covers part of it. ";
    }
    exits = {
        "You can go northwest";
        if (!demo_door.islocked)
            ", northeast,";
        " and southwest. ";
    }
    enterRoom(actor) = {
        leaky_pipe.wantheartbeat = true;
        pass enterRoom;
    }
    Grab(obj) = {
        leaky_pipe.objLeaving(obj);
        pass Grab;
    }
    ne = demo_door
    nw = nw2_end
    sw = mid2_hall_two
    nrmLkAround(verbosity) = {
        local l, cur, i, tot;
        local fixed_list,hdesc_list,other_list,actor_list;
        // we always build the lists of objects - it's easier that way
        fixed_list = [];
        hdesc_list = [];
        actor_list = [];
        other_list = [];
        l = self.contents;
        while (length(l) > 0) {
            cur = car(l); l = cdr(l);
            // never describe the player
            if (cur == Me) continue;
            // other actors
            if (cur.isactor) {
                actor_list += cur;
                continue;
            }
            // items with 'hdesc' properties
            if (cur.has_hdesc) {    // SRG: moved before fixed items
                hdesc_list += cur;
                continue;
            }
            // fixed items
            if (cur.isfixed) {
                fixed_list += cur;
                continue;
            }
            // everything else
            if (cur.isListed) {
                if (find(leaky_pipe.underList, cur) == nil)
                    other_list += cur;
            }
        }
        // If we are being 'verbose', we display the room description and
        // any fixed items that are here.
        if (verbosity) {
            "\n\t<<self.ldesc>>";
        }
        while (length(fixed_list) > 0) {
            cur=car(fixed_list); fixed_list=cdr(fixed_list);
        /* If isListed = true, place the object in other_list */
            if (cur.isListed)
                other_list += cur;
            else if (verbosity) cur.heredesc;
        }
        // now describe any objects who believe they have an important
        // description (hdesc)
        while (length(hdesc_list) > 0) {
            cur=car(hdesc_list); hdesc_list=cdr(hdesc_list);
            "\n\t<<cur.hdesc>>";
        }
        "\n\t";
        // now describe all the other tacky junk in list form
        if (length(other_list)>0) {
            "You see <<listlist(other_list)>> here. ";
        }
        // describe the contents of anything here
        listsubcontents(self); "\n";
        // now let the actors describe themselves.
        while (length(actor_list)>0) {
            cur = car(actor_list); actor_list = cdr(actor_list);
            if (cur.isListed)
                "\n\t<<cur.actorDesc>>";
        }
    }
;

demo_door: school_door
    messageSent = nil
    location = ne2_end
    doordest = demo_storage
    otherside = inside_demo_door
    doUnlock(actor) = {
        if (!messageSent) {
            messageSent = true;
            notify(schoolMessages, &summonMessage, 2);
        }
        pass doUnlock;
    }
;

leaky_pipe: fixedItem
    givenPoints = nil        // Have we given points for getting H2O?
    askDisambig = true
    stage = '2b'
    dripTime = 1
    underList = []
    ncmWiggled = nil
    noun = 'pipe'
    adjective = 'leaky' 'broken'
    location = ne2_end
    sdesc = "leaky pipe"
    ldesc = "The pipe occasionally drips, splashing water on the tile. "
    heredesc = {
        if (length(underList) == 0) return;
        "Underneath the pipe in the ceiling you see <<listlist(underList)>>. ";
    }
    janitordesc = "He says, \"Ah know. Maintenance keeps forgetting about it.\" "
    wantheartbeat = nil
    heartbeat = {
        local ff, water_item;

        if (dripTime == 0) {
            if ((ff = find(underList, force_field_machine)) != nil &&
                force_field_machine.isOn && !ncmWiggled)
                return;                            // Don't drip if the ff
            if (Me.location == self.location) {    //  machine is active
                "\bA drop of water falls from a pipe in the ceiling";
                if (ff != nil) {
                    if (force_field_machine.isOn) {
                        " and into the blue field. The field wraps around the
                            water, capturing it in a blue globe";
                        water_item = new water_drop;
                        force_field_machine.makeGlobe(water_item);
                        force_field_machine.isOn = nil;
                        if (!self.givenPoints) {
                            self.givenPoints = true;
                            incscore(5);
                            waterAh.solve;
                        }
                    }
                    else " and through the hole in the protrusion";
                }
                ". ";
            }
            ncmWiggled = nil;
            dripTime = 1 + RAND(2);
        }
        else {
            dripTime--;
            if (dripTime == 0 && find(underList, non_causal_machine) != nil
                && Me.location == self.location) {
                "\bThe needle on the cylinder's display wiggles violently. ";
                ncmWiggled = true;
            }
        }
    }
    leaving(actor) = {        // Turn ourselves off
        wantheartbeat = nil;
        return nil;
    }
    objLeaving(obj) = {       // Something is no longer under us
        if (find(underList, obj) != nil)
            underList -= obj;
    }
    verIoPutUnder(actor) = {}
    ioPutUnder(actor, dobj) = {
        local f;

        if (dobj != force_field_machine && dobj != non_causal_machine) {
            "There's no need to put <<dobj.thedesc>> under the pipe. ";
            return;
        }
        if (find(underList, dobj) != nil) {
            "\^<<dobj.thedesc>> is already under the pipe. ";
            return;
        }
        if (dobj == force_field_machine) {
            f = (find(underList, non_causal_machine) != nil);
            "You put the box under the leaky pipe";
            if (f) " and over the cylinder";
            ", positioning it so that any drop of water must fall through the
                hole";
            if (f) " and then into the funnel of the cylinder";
            ". ";
        }
        else {
            f = (find(underList, force_field_machine) != nil);
            "You put the cylinder directly under the end of the pipe";
            if (f) " so that its funnel lies under the box's hole";
            ". ";
        }
        dobj.moveInto(self.location);
        underList += dobj;
    }
;

coat_of_water: fixedItem
    stage = '2b'
    noun = 'water' 'coat' 'puddle'
    adjective = 'coat' 'film' 'puddle'
    location = ne2_end
    sdesc = "coat of water"
    ldesc = {
        "It covers part of the floor. ";
        if (thermoelectric_cooler.location == self)
            "The square rests in it. ";
    }
    takedesc = "Not likely. "
    showcontents = {
        if (thermoelectric_cooler.location == self)
            "Sitting in some water is a ceramic square. ";
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj != thermoelectric_cooler) {
            "There's no need to put that in the water. ";
            return;
        }
        dobj.doPutIn(actor, self);
        if (dobj.coolLevel == 3) {
            "In seconds the water scums over with ice; soon the puddle is
                completely icy. ";
            self.iceOver;
        }
    }
    verDoLookin(actor) = {}
    doLookin(actor) = {
        if (thermoelectric_cooler.location == self)
            "Resting in the water you see a ceramic square. ";
        else "You see yourself reflected in the water. ";
    }
    iceOver = {
        self.moveInto(nil);
        ice_slick.moveInto(ne2_end);
        thermoelectric_cooler.moveInto(ice_slick);
    }
;

ice_slick: fixedItem
    stage = '2b'
    contentsReachable = nil
    noun = 'ice' 'slick'
    adjective = 'ice'
    sdesc = "ice slick"
    ldesc = "The ice covers part of the floor. Deep inside it you see a
        ceramic square. "
    heredesc = "A patch of ice mars the tile floor. "
    takedesc = "Not likely. "
    touchdesc = {
        if (gloves.isworn)
            "You feel the cold even through the gloves. ";
        else "Very cold. ";
    }
    cantReach(actor) = {
        if (!actor.isactor) {
            "\^<<actor.thedesc>> <<actor.isThem ? "do" : "does">> not
                respond. ";
            return;
        }
        if (self.location == nil) {
            "%You% can't reach that from <<actor.location.thedesc>>. ";
            return;
        }
        "The ice prevents you. ";
    }
;

class water_drop: item
    stage = '2b'
    noun = 'drop' 'water'
    adjective = 'water'
    sdesc = "water drop"
    ldesc = "You should not see this. If you _do_ see this, please report it
        as a bug. "
;

demo_storage: school_room
    noDog = { return !(demo_door.isopen); }
    noBuddy = true
    sdesc = "Demonstration Storage"
    ldesc = "Equipment for demonstrating various and sundry scientific
        principles covers the walls, dangles from the ceiling, and lounges
        in untidy piles about the room. The exit to the southwest is nearly
        lost among the clutter. "
    exits = 'southwest'
    firstseen = { seenTECAh.see; seenNoncausalAh.see; pass firstseen; }
    sw = inside_demo_door
    out = inside_demo_door
;

non_causal_machine: container
    askDisambig = true
    stage = '2b'
    weight = 5
    bulk = 10
    noun = 'cylinder' 'funnel' 'display' 'needle'
    adjective = 'shiny'
    location = demo_storage
    sdesc = "shiny cylinder"
    ldesc = {
        local list;

        "The cylinder is knee-high, made of a highly-reflective metal.
            On one side is a display with a needle. It is topped off by a
            stunted funnel. ";
        if (length(list = contlist(self)) > 0)
            "In the funnel %you% see%s% <<listlist(list)>>. ";
    }
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        if (dobj.bulk > 10)
            "\^<<dobj.thedesc>> is too large to fit in the funnel. ";
        else if (addbulk(self.contents) + dobj.bulk > 10)
            "There's not enough room in the funnel. ";
        else {
            "Just before you drop <<dobj.thedesc>> into the funnel, the
                needle in the cylinder's display wiggles violently. ";
            dobj.moveInto(self);
        }
    }
;

thermoelectric_cooler: item
    askDisambig = true
    stage = '2b'
    coolLevel = 0
    contentsReachable = true    // For the switch
    tooBigForHole = true        // For the force-field box
    noun = 'square' 'cooler' 'wire' 'wires' 'tec'
    adjective = 'ceramic' 'white'
    location = demo_storage
    weight = 3
    bulk = 2
    sdesc = "ceramic square"
    ldesc = {
        "The square is about five centimeters on a side and a centimeter
            thick.  Wires trail from it, ending in a switch which is
            currently <<tec_switch.wordDesc>>. ";
        if (coolLevel == 3) "It is rimmed with ice. ";
        else if (coolLevel > 1) "Water vapor is condensing around it. ";
    }
    touchdesc = {
        if (gloves.isworn)
            "Your gloved fingers slide smoothly over its surface. ";
        else switch (coolLevel) {
            case 0:
                "Your fingers slide over its smooth surface. ";
                break;
            case 1:
                "The square feels cool to the touch. ";
                break;
            case 2:
                "It is almost painfully cold. ";
                break;
            case 3:
                "You touch it, then jerk your hand back before you lose skin.
                    The square is incredibly cold. ";
        }
    }
    listendesc = {
        if (tec_switch.isActive) "The square hums quietly. ";
        else "You hear nothing unusual. ";
    }
    verDoTake(actor) = {
        if (coolLevel == 3 && !gloves.isworn)
            "The square is too cold. ";
        else pass verDoTake;
    }
    doSwitch -> tec_switch
    doFlip -> tec_switch
    doTurnon -> tec_switch
    doTurnoff -> tec_switch
;

tec_switch: fixedItem
    stage = '2b'
    wantheartbeat = nil
    isActive = nil
    noun = 'switch'
    plural = 'switches'
    location = thermoelectric_cooler
    sdesc = "switch"
    ldesc = "The switch is <<self.wordDesc>>. "
    wordDesc = { isActive ? "on" : "off"; }
    verDoSwitch(actor) = {}
    doSwitch(actor) = {
        if (!isActive) self.doTurnon(actor);
        else self.doTurnoff(actor);
    }
    doSynonym('Switch') = 'Flip'
    verDoTurnon(actor) = {
        if (isActive)
            "It's already turned on. ";
    }
    doTurnon(actor) = {
        isActive = true;
        "You flip the switch.  Shortly thereafter, the square begins humming
            quietly. ";
        wantheartbeat = true;
    }
    verDoTurnoff(actor) = {
        if (!isActive) "It's already turned off. ";
    }
    doTurnoff(actor) = {
        isActive = nil;
        "You flip the switch.  A quiet hum which you had almost stopped
            noticing disappears. ";
        wantheartbeat = true;
    }
    // heartbeat does the cooling and the heating.  Don't forget: check padlock
    heartbeat = {
        if (isActive) {
            if (thermoelectric_cooler.coolLevel == 3) {
                wantheartbeat = nil;
                if (thermoelectric_cooler.location == school_padlock &&
                    school_padlock.isWet)
                    school_padlock.coolDown;
                else if (thermoelectric_cooler.location == coat_of_water)
                    coat_of_water.iceOver;
            }
            else {
                thermoelectric_cooler.coolLevel++;
                if (thermoelectric_cooler.location == Me && !gloves.isworn) {
                    if (thermoelectric_cooler.coolLevel == 3) {
                        "\bThe square has become too cold to hold onto,
                            forcing you to drop it. ";
                        thermoelectric_cooler.moveInto(Me.location);
                    }
                    else "\bThe square feels cooler. ";
                }
            }
        }
        else {
            if (thermoelectric_cooler.coolLevel == 0)
                wantheartbeat = nil;
            else thermoelectric_cooler.coolLevel--;
        }
    }
    doTake -> thermoelectric_cooler
;

inside_demo_door: school_door
    location = demo_storage
    doordest = ne2_end
    otherside = demo_door
;

demo_equipment: decoration
    noun = 'equipment' 'pendulum' 'generator' 'vinegar' 'soda'
    plural = 'pendulums' 'generators'
    adjective = 'baking'
    location = demo_storage
    sdesc = "equipment"
    ldesc = "Pendulums, van de Graaf generators, vinegar and baking soda,
        and other simple scientific apparatus. "
;

nw2_end: school_hall
    floating_items = [school_stairs_down]
    buddyList = [&down, 'to the stairs and skips down them', &ne,
        'through the northeast doorway', &se, 'to the southeast']
    buddyToShelf = 1
    sdesc = "Second Floor, Northwest End"
    ldesc = "This end of the hall has an odd symmetry, with a doorway to
        the northeast, a door to the northwest, a staircase to the southwest,
        and the hall to the southeast. "
    exits = 'northeast, southeast, and down'
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
    leaveRoom(actor) = {
        if (actor == Me && grey_man.location == self) {
            "The grey man lays a hand on your shoulder, stopping you. \"Not
                just yet, I think,\" he tells you. ";
            exit;
        }
        pass leaveRoom;
    }
    down = nw1_end
    ne = school_lab
    nw = deans_door
    sw = nw1_end
    se = ne2_end
;

nw2_end_doorway: myDoorway
    location = nw2_end
    ldesc = "It leads northeast. "
    lookthrudesc = "You can see part of a lab. "
    doordest = school_lab
;

deans_door: doorItem
    stage = '2b'
    isopen = true
    islocked = nil
    mykey = frankie
    adjective = 'northwest' 'nw' 'wood'
    location = nw2_end
    sdesc = "wood door"
    ldesc = {
        "The door leads to the office of the dean, a man who was, for a brief
            time, your academic advisor. \"Dr.\ Dolby\" is painted across it. ";
        if (self.isopen)
            "The door stands partially ajar";
        else "It is closed, its heavy wood surface separating the office
            from the outside world";
        ". ";
    }
    verDoKnockon(actor) = {
        if (!isopen) pass verDoKnockon;
    }
    doKnockon(actor) = {
        "You knock on the door, but no one answers. ";
        actor.travelTo(self.destination);
    }
    verDoOpen(actor) = {
        if (self.isopen)
            "The door is open enough for you to enter. ";
        else pass verDoOpen;
    }
    destination = {
        if (!self.isopen) {
            "%You%'ll have to open the door first. ";
            setit(self);
            return nil;
        } // The next bit is a quick&dirty workaround to avoid problems
        Me.moveInto(doghouse);    //  with leaveRoom in nw2_end
        "You push the door fully open and enter.  Your eyes sweep over the
            desk, the dean behind it, and a man seated in the chair in front
            of the desk.  All you can see of the man is a thatch of white
            hair, oddly familiar.\b
            The dean glances at you. \"Terry?\"\ he asks, but before you can
            respond, grey hands have grabbed you and pulled you out of the
            room.\b";
        grey_man.moveInto(nw2_end);
        self.isopen = nil;
        self.islocked = true;
        notify(grey_man, &scoldTerryB, 1);
        return nw2_end;
    }
;

school_lab: school_room
    buddyList = [&sw, 'back out of the lab']
    buddyToShelf = 1
    sdesc = "Student Lab"
    ldesc = "Rows of bench-like tables face the front of the room, where
        a chalkboard is set flush into the wall. The floor is raked with
        scratches, evidence of the entrance and exit of heavy machinery. "
    floordesc = "Scratches stretch the length of the floor. "
    exits = 'southwest'
    firstseen = { seenForceFieldAh.see; pass firstseen; }
    sw = nw2_end
    out = nw2_end
;

lab_tables: surface, fixedItem
    stage = '2b'
    isThem = true
    noun = 'table'
    plural = 'tables'    
    adjective = 'lab' 'bench-like' 'rows'
    location = school_lab
    sdesc = "lab tables"
    ldesc = {
        "The surface of the tables has been etched over time by the
            application of countless chemicals. ";
        pass ldesc;
    }
    verDoSiton(actor) = {
        "Given the amount and varying type of chemicals applied to the
            tables, you reconsider. ";
    }
    verIoTieTo(actor) = {}
;

lab_chalkboard: decoration, readable
    stage = '2b'
    noun = 'chalkboard' 'blackboard' 'board'
    location = school_lab
    sdesc = "chalkboard"
    ldesc = "Although the chalkboard has been recently cleaned, its surface
        still bears the scars of a professor's overeager application of
        chalk. "
    readdesc = "You can see that something was once written on the
        board but can't make out what it was. "
;

lab_scratches: decoration
    stage = '2b'
    noun = 'scratch' 'scratches'
    location = school_lab
    sdesc = "scratches"
    ldesc = "They run from the entrance to the middle of the room. "
;

force_field_machine: item
    askDisambig = true
    stage = '2b'
    number = 1
    isOn = nil
    isBurnt = nil
    noun = 'box' 'hole' 'handle' 'protrusion'
    plural = 'boxes' 'handles'
    adjective = 'black' 'rounded'
    weight = 20
    bulk = 15
    location = lab_tables
    sdesc = "rounded box"
    ldesc = {
        "The box is roughly the size of a breadbox and painted a uniform matte
            black. ";
        if (self.isBurnt)
            "Its paint has rippled from a flash of heat. ";
        "Handles stick out from either side. On its front is a
            protrusion through which a hole the size of a quarter has been
            made";
        if (self.isOn)
            "; the hole is filled with a glowing blue field";
        ". Its only control is a button. ";
    }
    smelldesc = {
        if (self.isBurnt) "You smell a lingering hint of smoke. ";
        else pass smelldesc;
    }
    doPush->ff_button
    verIoPutIn(actor) = {}
    ioPutIn(actor, dobj) = {
        local l;

        if (dobj == self)
            "Not likely. ";
        else if (dobj.bulk > 2 || dobj.tooBigForHole)
            "\^<<dobj.thedesc>> won't fit in the hole. ";
        else {
            "%You% put <<dobj.thedesc>> into the hole. ";
            if (!self.isOn) {
                "\^<<dobj.thedesc>> falls through. ";
                dobj.moveInto(uberloc(self));
                return;
            }
            self.isOn = nil;
            flat_field.moveInto(nil);
            if (isclass(dobj, blue_field)) {
                "There is a snap and a flash of light. When you can see past
                    the spots in your eyes, you notice that the blue field
                    surrounding <<dobj.fieldItem.thedesc>> has vanished. ";
                dobj.moveInto(uberloc(self));
                remfuse(numbered_cleanup, dobj);
                l = outhide(true);
                delete dobj;
                outhide(l);
                self.isBurnt = true;
                return;
            }
            "The field wraps around <<dobj.thedesc>>, englobing it; the
                newly-minted blue globe falls to the floor. A wisp of smoke
                rises from the now-empty hole. ";
            self.makeGlobe(dobj);
        }
    }
    verIoPutUnder(actor) = {}
    ioPutUnder(actor, dobj) = {
        if (dobj != non_causal_machine) {
            "There's no need to put <<dobj.thedesc>> under the box. ";
            return;
        }
        if (find(leaky_pipe.underList, self) == nil) {
            "There's no need to put <<dobj.thedesc>> under the box right
                now. ";
            return;
        }
        leaky_pipe.ioPutUnder(actor, dobj);
    }
    turnoff = {
        if (self.isOn && Me.location == uberloc(self) &&
            !(self.location == rucksack && !rucksack.isopen)) {
            "\bThe blue field from <<thedesc>> vanishes. ";
            if (leaky_pipe.dripTime == 0 &&
                find(leaky_pipe.underList, force_field_machine) != nil) {
                "Just after that, a drop of water falls from the pipe and
                    through the hole. ";
                leaky_pipe.dripTime = 1 + RAND(2);
                waterAh.see;
            }
        }
        self.isOn = nil;
        flat_field.moveInto(nil);
    }
    makeGlobe(obj) = {
        local new_field;

        new_field = new blue_field;
        new_field.fieldItem = obj;
        new_field.number = self.number;
        addword(new_field, &adjective, cvtstr(self.number));
        self.number++;
        new_field.moveInto(uberloc(self));
        self.isOn = nil;
        // Use numbered_cleanup to get rid of the field in a while
        setfuse(numbered_cleanup, 12, new_field);
        obj.moveInto(nil);
    }
;

ff_button: buttonitem
    stage = '2b'
    adjective = 'black'
    location = force_field_machine
    sdesc = "black button"
    ldesc = {
        if (force_field_machine.isBurnt)
            "The button is scorched. ";
        else "A matte-black button. ";
    }
    verDoPush(actor) = {
        if (force_field_machine.isBurnt)
            "Nothing happens. ";
    }
    doPush(actor) = {
        "The button depresses with a quiet click. A blue field forms over
            the hole in the protrusion. ";
        force_field_machine.isOn = true;
        flat_field.moveInto(force_field_machine);
        notify(force_field_machine, &turnoff, 2);
    }
;

flat_field: fixedItem
    noun = 'field'
    adjective = 'blue'
    sdesc = "blue field"
    ldesc = "It covers the hole. "
    takedesc = "The field is slightly springy but impossible to get a good
        grip on. "
;

class blue_field: item
    stage = '2b'
    number = 0
    fieldItem = nil
    noun = 'ball' 'globe'
    plural = 'balls' 'globes'
    adjective = 'blue'
    sdesc = "\"<<self.number>>\" blue globe"
    ldesc = "About the size of a marble, it glows faintly. The blue of its
        surface prevents you from seeing inside it. The number \"<<self.number
        >>\" swirls in deeper blue on the globe. "
    destruct = {
        local    locFlag = (Me.location == uberloc(self)),
                 padFlag = (self.location == school_padlock);

        fieldItem.moveInto(self.location);
        if (locFlag) {
            "\b<<padFlag ? "You hear t" : "T">>he blue field surrounding <<
                fieldItem.thedesc>> vanish<<padFlag ? "" : "es">> with a 
                snap. ";
        }
        if (isclass(fieldItem, insulation_tuft) && fieldItem.location == Me &&
            !gloves.isworn) {
            "The insulation jabs into your fingers, causing you to drop it. ";
            fieldItem.moveInto(Me.location);
        }
        else if (isclass(fieldItem, water_drop)) {
            if (self.location == school_padlock) {
                school_padlock.isWet = true;
                if (thermoelectric_cooler.location == school_padlock &&
                    thermoelectric_cooler.coolLevel == 3)
                    notify(school_padlock, &checkTEC, 1);
                if (locFlag)
                    "Seconds later, water drips from the padlock. ";
            }
            else if (locFlag) {
                "The water inside spreads out instantly";
                if (self.location == Me) ", dripping through your fingers";
                ". ";
            }
            delete fieldItem;
        }
        self.moveInto(nil);
    }
;

unfulfilledThreeB: function
{
    "\bWith a start, your eyes fly open. Confused images fill your brain:\ 
        you are not where you were. You thrash about, moaning. Strong
        arms hold you down. You feel a cooling spot on your inner elbow; some
        less-fevered portion of your brain realizes that you have been swabbed
        with an alcohol-soaked cotton ball. There is a pin-prick, then a
        wonderful languid feeling which rushes through you. \"Sedative?\"\
        someone above you asks. You never hear the reply as you fall into a
        sleep too deep for dreams. ";
    die();
}

// The object which keeps track of messages from outside
schoolMessages: object
    messageNum = 1
    summonMessage = {
        switch (messageNum) {
            case 1:
            nurseMessage.setup('Oh!" The voice is fainter than before. "Dr.\ 
                Boozer! Up here, in the attic!');
            "\bA section of the air just above your head shimmers. A small
                pyramid falls from the disturbance to the ground below. ";
            if (buddy.location == Me.location)
                "Little Buddy points at it. \"Ooh, cool,\" he breathes. ";
            nurseMessage.moveInto(Me.location);
            break;

            case 2:
            doctorMessage.setup('Help me..." Dr.\ Boozer\'s voice fades in and
                out, a poorly-tuned radio station.
                "...on the gurney...ambulance...arms and legs...');
            "\bThe air just above you begins shimmering. From the disturbance
                falls a smallish cube. ";
            if (buddy.location == Me.location)
                "Little Buddy looks at the cube in confusion, then up at the
                    ceiling. ";
            doctorMessage.moveInto(Me.location);
            break;

            default:
                return;
        }
        self.messageNum++;
    }
;

/*
    Little Buddy, an actor from _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: buddy.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

buddy: Actor
    selfDisambig = true
    stage = '2b'
    noAlreadyTold = true   // I'll answer questions over and over and over and
    roamPercent = 0
    followPercent = 0
    isFollowing = nil
    stopPercent = 0
    mentionedDog = nil
    lookedAtShelf = nil
    movingToShelf = nil
    waitingAtShelf = 0
    cabinetJumping = nil
    inHiding = nil
    onCabinet = nil
    stuckInGrate = 0
    isLotioned = nil
    isPaused = nil         // Like a pause button. For when the player
                           //  visits the beach (see eggs.t)
    clearProps = {
        roamPercent = followPercent = stopPercent = waitingAtShelf = 0;
        isFollowing = movingToShelf = cabinetJumping = onCabinet = nil;
    }

    noun = 'buddy' 'matthew' 'matt'
    adjective = 'little'
    location = school_library
    isHim = true
    myfollower = buddy_follower
    askme = &buddydesc
    sdesc = "Little Buddy"
    stringsdesc = 'Little Buddy'
    buddydesc = 'I like dinosaurs. Do you like dinosaurs? I\'ve liked
        dinosaurs for ever and ever. You know which one I like most? I really
        like the Ankylosaurus. Have you seen pictures of an Ankylosaurus?
        They looked like big turtles with spikes on their tails. I think
        it would be neat to be one of them." He pauses for breath. "I
        really like dinosaurs.'
    janitordesc = "The janitor just grins wryly. "
    erindesc = {
        if (uberloc(self) == uberloc(erin))
            "Erin sighs in Little Buddy's general direction. ";
        else "\"Man, he bugs me sometimes,\" she tells you. ";
    }
    ldesc = {
        "An eight-year-old bundle of energy, his actual name is Matthew,
            though no one calls him that. He is the
            hyperkinetic offspring of your hyperkinetic former
            advisor. Like his father Tom, you (and everyone else) call him
            \"Little Buddy.\" ";
        if (onCabinet)
            "He is perched precariously atop a file cabinet. ";
        else if (stuckInGrate > 0) {
            "At the moment, all you can see of him are his legs and his lower
                torso";
            if (isLotioned)
                ", which gleam as if lightly greased";
            ". ";
        }
    }
    actorAction(v, d, p, i) = {
        if (self.stuckInGrate > 0) {
            "Little Buddy does not respond. ";
            exit;
        }
        if (v == helloVerb) {
            "Little Buddy waves madly at you. ";
            exit;
        }
        if (v == followVerb && d == Me) {
            self.isFollowing = true;
            followPercent = 0;
            "Little Buddy says, \"Okay! Where're we going?\"\ ";
            if (onCabinet) {
                "as he jumps down from the cabinet. ";
                cabinetJumping = nil;
                onCabinet = nil;
                stopPercent = 0;
            }
            exit;
        }
        pass actorAction;
    }
    actorDesc = {
        if (isFollowing)
            "Little Buddy stands next to you, occasionally staring unabashedly
                up at you. ";
        else if (onCabinet)
            "Little Buddy is perched atop the file cabinet. ";
        else if (stuckInGrate > 0)
            "Little Buddy's legs and part of his torso stick out of the small
                shaft. ";
        else "Little Buddy stands here, looking around. ";
    }
    takedesc = "He's not that small. "
    smelldesc = {
        if (isLotioned)
            "He smells enchantingly of lilacs. ";
        else "He smells like a young boy:\ somewhere between an unwashed dog
            and damp wool. ";
    }
    verDoKick(actor) = {
        if (stuckInGrate > 0)
            "\"Ow!\"\ Little Buddy shrieks. ";
        else "Little Buddy's eyes light up. He skips over your kick, then
            whacks
            you hard in the shins. \"Oops,\" he giggles, \"I expected you to
            dodge like me!\" ";
    }
    verDoKiss(actor) = {
        if (stuckInGrate > 0)
            "You'd rather not. ";
        else "\"Yeeeewwww!\"\ Buddy tells you, avoiding your proffered kiss. ";
    }
    verDoAttack(actor) = {
        if (stuckInGrate > 0)
            "Given his precarious situation, you refrain. ";
        else "As you move to grapple with him, he jumps and climbs on your
            shoulders. He laughs gleefully before getting down. ";
    }
    verDoAskAbout(actor) = {
        if (stuckInGrate > 0)
            "Little Buddy says, \"Help me!\" ";
        else pass verDoAskAbout;
    }
    verIoShowTo(actor) = {}
    ioShowTo(actor, dobj) = {
        if (dobj == key_ring)
            "\"Cool!\"\ Little Buddy says excitedly. \"The janitor gave you
                his keys! He never gives them to me.\" ";
        else "Little Buddy looks at <<dobj.thedesc>>, then looks away, his
            attention elsewhere. ";
    }
    ioGiveTo(actor, dobj) = {
        if (dobj == key_ring)
            "Little Buddy shakes his head. \"Nuh-uh. You know how much trouble
                I'd be in? You keep them.\" ";
        else "\"Nah. Thanks anyway.\" ";
    }
    disavow = "Little Buddy shrugs his shoulders. "
    verIoPutOn(actor) = {}
    ioPutOn(actor, dobj) = {
        if (dobj != lotion)
            "There's no good surface on Little Buddy. ";
        else dobj.doPourOn(actor, self);
    }
    verDoPull(actor) = {
        if (stuckInGrate > 0) {
            if (isLotioned)
                "Even with the lotion, h";
                else "H";
                "e doesn't budge. \"Ow!\"\ comes the muffled response from
                    Little Buddy. ";
        }
        else pass verDoPull;
    }
    verDoPush(actor) = {
        if (stuckInGrate > 0) {
            if (!isLotioned)
                "He doesn't budge. \"Ow!\"\ comes the muffled response from
                    Little Buddy. ";
        }
        else pass verDoPush;
    }
    doPush(actor) = {
        "You push Little Buddy as hard as possible. At first nothing happens,
            but then he gives a little kick and squirts forward, lubricated
            by the lotion. You fall forward, your hands following Little Buddy
            through the shaft opening.\b
            As you do the steel plate quivers, then falls, its sharpened edge
            slicing into your wrists and through them with the squeak of metal
            on bone. You fall back, in too much pain to cry out. The pain
            claws up your arms, clouding your vision, until...\n";
        self.wantheartbeat = nil;
        unnotify(self, &grateProblems);
        gurney.setup;
    }

    wantheartbeat = nil
    heartbeat = {
        local locFlag = (Me.location == self.location);

// Step zero: if waitingAtShelf, inHiding, or isPaused, return
        if (waitingAtShelf != 0 || inHiding || isPaused) return;
// First thing: see if we're climbing on the radiator & cabinet
        if (cabinetJumping) {
            if (locFlag) {
                if (onCabinet) {
                    "\bLittle Buddy says, \"Look at me!\" He then proceeds to
                        jump from the top of the cabinet to the floor below. ";
                    if (RAND(100) < 25)
                        "Erin sighs heavily at his exuberance. ";
                }
                else "\bLittle Buddy climbs onto the radiator, then to a nearby
                    filing cabinet. ";
            }
            onCabinet = !onCabinet;     // Flip the cabinet flag
            if (!onCabinet && RAND(100) < stopPercent) {
                cabinetJumping = nil;
                stopPercent = 0;
                return;
            }
            stopPercent += 3 + RAND(3);
            return;
        }
// Next: if we're moving to the shelf, do so
        if (movingToShelf) {
            local dest, i;

            if ((i = self.location.buddyToShelf) != nil) {
                dest = self.location.(self.location.buddyList[i*2 - 1]);
                if (Me.location == self.location)
                    "\bLittle Buddy runs <<self.location.buddyList[i*2]>>. ";
                self.moveInto(dest);
                if (Me.location == self.location)
                    "\bLittle Buddy comes running towards you, then skids to a
                        halt, grinning. ";
            }
            else {
                movingToShelf = nil;
                notify(self, &waitForShelf, 0);
            }
            return;
        }
// Oh yeah: handle being stuck in the grate
        if (stuckInGrate > 0) {
            return;
        }
// Then: handle the actions if we're not following the player
        if (!isFollowing) {
// If we're around the player, see if we want to follow him/her
            if (locFlag) {
                if (RAND(100) < followPercent) {
                    "\bLittle Buddy looks up at you. \"Whatcha doing?\"\ he
                        asks. \"Mind if I watch? I won't get in the way,
                        honest injun. What's next?\" He fairly bounces with
                        anticipation. ";
                    self.isFollowing = true;
                    followPercent = 0;
                    return;
                }
                followPercent += 12;
// If we're in the library, see if we want to climb stuff (only if the player
//  is around)
                if (self.location == school_library && RAND(100) < 30) {
                    cabinetJumping = true;
                    stopPercent = 0;
                    return;
                }
            }
// Otherwise, roam around a bit
            if (RAND(100) < roamPercent) {
                self.roamAround;
                roamPercent = 0;
                return;
            }
            roamPercent += 12;
        }
        if (!locFlag && isFollowing) {
            if (uberloc(Me).noBuddy) {
                "\bFrom behind you, you hear Little Buddy say, \"Ok...um...I
                    think I'll just, you know, wait out here. Daddy told me
                    not to go in there, so, you know...\" His voice trails
                    off. ";
                stopPercent = 0;
                isFollowing = nil;
                return;
            }
            self.moveInto(Me.location);
            "\bLittle Buddy comes running after you. ";
            if (erin.location == self.location && RAND(100) < 20)
                "Erin stares at Little Buddy, then rubs the bridge of her
                    nose. ";
        }
// If we're following the player, should we stop?
        if (isFollowing) {
            if (RAND(100) < stopPercent) {
                "\bLittle Buddy suddenly stops. \"Hey, what's that?\"\ 
                    he asks, peering into the distance. ";
                self.roamAround;
                stopPercent = 0;
                isFollowing = nil;
                return;
            }
            stopPercent += 1 + RAND(2);
        }
        if (locFlag) {
            if (reagent_shelf.location == self.location && !lookedAtShelf) {
                "\bLittle Buddy glances up at the shelf, then away
                    guiltily. ";
                lookedAtShelf = true;
            }
            if (janitor.location == self.location && RAND(100) < 8)
                "\bLittle Buddy waves madly at the janitor, who laughs and
                    waves back. ";
            else if (erin.location == self.location && RAND(100) < 8)
                "\bLittle Buddy goes over to Erin and tugs on her shirt.
                    \"Whatcha studying? Looks like p-chem. Are those
                    endothermic reactions? 'Cause if so--\"\b
                    He is stopped by Erin's hand across his mouth. \"Enough,
                    LB,\" she says. ";
            else if (erin.location == self.location && RAND(100) < 8)
                "\bLittle Buddy peers at the books surrounding Erin. Erin
                    stares at him, pulling books closer to her. He gets the
                    hint and moves away. ";
// If the dog's around, see if we want to play with it (if the player's around)
            else if (dog.location == self.location && RAND(100) < 30) {
                if (!mentionedDog) {
                    "\bLittle Buddy peers at <<dog.thedesc>>. \"Hey,\" he
                        exclaims, \"what a cool dog! Can I pet it?\"
                        Without waiting for a yes or no, he bends down and
                        pets <<dog.thedesc>>, who bears it stoically. 
                        \"Does it have a name?\"\ he asks you.\b";
                    if (dog.name != nil)
                        "\"\^<<dog.name>>,\" you tell him.\b
                        \"Cool,\" he says. \"Hey, \^<<dog.name>>!\"\ he yells
                        at the dog, who winces. ";
                    else {
                        "\"I...uh...haven't named the dog yet,\" you tell
                        Little Buddy.\b
                        He stares at you in disbelief. \"Well, ok,\" he
                        says. \"I'll name him Max. Hiya, Max!\"\ he tells
                        the dog, who thumps his tail against the floor. ";
                        dog.name = 'max';
                        addword(dog, &noun, 'max');
                    }
                    mentionedDog = true;
                }
                else "\bLittle Buddy bends down and begins talking to <<
                    dog.thedesc>>. \"You wanna play, doggy? You wanna
                    play?\" <<dog.capdesc>> gives Little Buddy
                    a look of infinite patience. ";
            }
        }
    }
    roamAround = {
        self.wanderTo(RAND(length(self.location.buddyList) / 2));
    }
    wanderTo(i) = {
        local dest;

        dest = self.location.(self.location.buddyList[i*2 - 1]);
        if (Me.location == self.location)
            "\bLittle Buddy runs <<self.location.buddyList[i*2]>>. ";
        self.moveInto(dest);
        if (Me.location == self.location) {
            "\bLittle Buddy comes running towards you, then skids to a halt,
                grinning. ";
            if (erin.location == self.location && RAND(100) < 20)
                "Erin pointedly looks away from him. ";
        }
    }
    waitForShelf = {
        if (isPaused) return;        // Don't wait while player's at beach
        if (self.location != Me.location) {
            if (++waitingAtShelf > 30) {
                "\bFrom somewhere in the building, you hear Little Buddy
                    yelling, \"Terry! Terry?\" There is a pause, then,
                    \"TerRY?\" A few seconds later, \"Never mind.\" ";
                waitingAtShelf = 0;
                unnotify(self, &waitForShelf);
            }
            return;
        }
        waitingAtShelf = 0;
        unnotify(self, &waitForShelf);
        "\bLittle Buddy looks at you, then at the shelf. He grins at you.
            \"There's this really cool reaction you gotta see,\" he tells you.
            He glances around and lowers his voice. \"Dad doesn't want me
            doing this, but...\"\b
            In one swift motion he jumps up and nabs one of the bottles. The
            shelf wobbles alarmingly. Little Buddy turns to you, waggling
            his eyebrows. Then he turns back to the shelf, jumps up, and
            grabs a second bottle.\b
            As he's proudly displaying the two bottles, one of the shelf's
            tired angle brackets gives up the ghost, falling to the floor
            with a quiet clink. It bounces once, twice, then is swamped
            by the flood of shattering bottles sliding off the shelf. In an
            unprecedented display of strength the second angle bracket holds
            on, though the shelf is now nearly vertical.\b";
        if (janitor.location == self.location) {
            "The janitor whirls around. His brows lower. \"Son,\" he rumbles,
                but before he can finish Little Buddy has turned and run. ";
            janitor.cleaningChemicals = 1;
        }
        else {
            "Little Buddy takes one look at the mess, turns, and runs down the
                hall as fast as he can. ";
            janitor.movingToChemicals = true;
        }
        self.moveInto(nil);
        inHiding = true;
        isFollowing = nil;
        waitingAtShelf = 0;
        notify(self, &emergeFromHiding, 10);
        chemical_mess.moveInto(mid1_hall_two);
        tilted_shelf.moveInto(mid1_hall_two);
        reagent_shelf.moveInto(nil);
    }
    emergeFromHiding = {
        self.inHiding = nil;
        self.moveInto(nw1_end);
        if (Me.location == self.location) {
            "\bLittle Buddy comes quietly walking down the stairs. ";
            if (janitor.location == self.location) {
                "When he sees the janitor, he stops, then quietly creeps back
                    up the stairs. ";
                self.moveInto(nw2_end);
            }
            else "When he sees you, he grins sheepishly. ";
        }
    }
    grateProblems = {
        // Don't do anything if the player's @ the beach (eggs.t)
        if (!isPaused) switch (stuckInGrate++) {
            case 1:    // Little Buddy makes some noise
            if (Me.location == self.location)
                "\bLittle Buddy's feet kick several times. \"Uh, hello?\"\ he
                    says. \"Um, I'm stuck in here!\" ";
            else if (Me.location == buddy_front.location)
                "\bLittle Buddy tries to look at you. \"Hey,\" he tells you,
                    \"I'm stuck in here!\" ";
            break;
            case 2:    // The steel plate wiggles some
            if (Me.location == self.location)
                "\bYou hear a nasty grinding noise, and Little Buddy screams.
                    \"Owwwww! Something's cutting into my back! OWWWWW!\" His
                    struggles redouble. ";
            else if (Me.location == buddy_front.location)
                "\bYou hear a nasty grinding noise, and Little Buddy screams,
                    almost shattering your eardrums. \"Owwwww! Something's
                    cutting into my back! OWWWWW!\" His struggles redouble. ";
            break;
            case 3:    // The plate does it again
            if (Me.location == self.location ||
                Me.location == buddy_front.location)
                "\bThere is a screeching noise, and Little Buddy jerks
                    spasmodically. \"I...I can't feel my legs...\"\ he
                    whimpers. ";
            break;
            case 4:    // The plate crashes through LB
            if (Me.location == self.location ||
                Me.location == buddy_front.location)
                "\bA horrendous screech splits the air. There is a crunch,";
            else "\bFrom behind you you hear a horrendous screech. You turn
                around; somehow you've been transported to the library stacks.
                Little Buddy's feet jut from the small shaft, kicking feebly.
                The screech is repeated, followed by a crunch,";
            " and Little Buddy's legs go limp. At the same time, a line of
                fire sketches across your back. Your legs buckle and you fall
                to the floor, skull bouncing on the tile.\n";
            buddy_front.wantheartbeat = nil;
            Me.ctrlPoints--;
            gurney.setup;
            return;
        }
        notify(self, &grateProblems, 8);
    }
;

buddy_follower: follower
    stage = 0
    noun = 'buddy' 'matthew' 'matt'
    adjective = 'little'
    myactor = buddy
;

buddy_front: Actor
    stage = '2b'
    noun = 'buddy' 'matthew' 'matt'
    adjective = 'little'
    isHim = true
    sdesc = "Little Buddy"
    stringsdesc = 'Little Buddy'
    ldesc = "He is stuck in the shaft, his front half towards you. "
    actorDesc = "Little Buddy is stuck in the shaft. "
    takedesc = "Little Buddy won't settle down long enough for you to get
        a good grip. "
    verDoPush(actor) = self.takedesc
    doSynonym('Push') = 'Pull'

    actorAction(v, d, p, i) = {
        "Little Buddy wails, \"Get me out of here! Puh-lee-ee-ee-eeease! ";
        exit;
    }
    wantheartbeat = nil
    heartbeat = {
        if (self.location == Me.location)
            "\bLittle Buddy thrashes wildly, sending clangs through the
                shaft. ";
        else "\bYou hear a rhythmic pounding from somewhere in the shaft. ";
    }
;

fake_dinosaurs: conversationPiece
    toldNum = 1
    noun = 'dinosaur' 'dinosaurs'
    sdesc = "dinosaurs"
    buddydesc = {
        switch (self.toldNum) {
            case 1:
            "Little Buddy peers up at you. \"My dad told me to stop
                bothering people about dinosaurs.\" He scuffs his feet. ";
            self.factTold -= buddy;
            self.toldNum++;
            break;
            
            case 2:
            "Little Buddy starts to speak, then stops. \"I could get in
                trouble, so don't ask me again, 'kay?\" ";
            self.factTold -= buddy;
            self.toldNum++;
            break;
            
            case 3:
            "Little Buddy shakes his head. \"Nuh-uh!\" ";
            self.factTold -= buddy;
            buddy.roamPercent = 101;    // Make him wander away if possible
            break;
        }
    }
;

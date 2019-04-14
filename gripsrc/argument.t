/*
    Argument, part 4 of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: argument.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

argument_room: room
    noDog = true
    pictures = nil
    music = nil
    sdesc = "Elegant Room"
    ldesc = "The room is painted a light yellow and hung with drapes. Two
        free-standing lamps and a gently-swinging chandelier cast bright
        circles of light on the dim floor. Against one wall is a table.
        Opposite it are two <<self.pictures ? "" : "empty">> picture<<
        self.pictures ? "" : " frame">>s. "
    listendesc = {
        if (self.music)
            "You hear music. ";
        else "You hear nothing unusual. ";
    }
    enterRoom(actor) = {
        inherited.enterRoom(actor);
        if (dog.isWaiting && dog.location == self) {
            "\b<<dog.capdesc>>, upon seeing you, cocks its head at you and
                stands, more slowly than before. You hear the creak and snap
                of joints. ";
            if (rucksack.location == dog)
                "On its back is the rucksack. ";
            dog.clearProps;
            dog.wantheartbeat = true;
        }
    }
    firstseen = {
        argument_daemon.setup;
        pass firstseen;
    }
;

argument_drapes: decoration
    isThem = true
    noun = 'drape' 'drapes'
    location = argument_room
    sdesc = "drapes"
    ldesc = "The drapes muffle conversation. "
;

argument_lamps: decoration
    isThem = true
    noun = 'lamp' 'lamps'
    adjective = 'two' 'free-standing' 'white'
    location = argument_room
    sdesc = "lamps"
    ldesc = "They are just under two meters tall and painted white. "
;

argument_chandelier: decoration
    noun = 'chandelier'
    adjective = 'swinging'
    location = argument_room
    sdesc = "chandelier"
    ldesc = "It swings gently to and fro. "
;

argument_table: surface, fixedItem
    noun = 'table'
    adjective = 'small'
    location = argument_room
    sdesc = "table"
    ldesc = {
        local conts;

        conts = contlist(self);
        "A small table, pushed up against one of the walls. ";
        if (length(conts) > 0)
            "On it you see <<listlist(conts)>>. ";
    }
;

argument_frames: decoration
    noun = 'frame' 'frames'
    adjective = 'empty'
    location = argument_room
    sdesc = "frames"
    ldesc = "Two empty frames hang on the wall opposite the small table. "
;

butler: Actor
    insulted = nil
    buttleAgain = 1
    isHim = true
    noun = 'butler' 'man'
    adjective = 'tuxedoed' 'gaunt' 'tall' 'bitter'
    sdesc = "tall man"
    thedesc = "the tall man"
    adesc = "a tall man"
    ldesc = "He is quite tall and gaunt, arms jutting from under his tuxedo
        jacket. A bitter expression has taken permanent residence on his
        face. He is carrying a silver tray. "
    actorDesc = "A tall man in a tuxedo stands here, a bitter smile on his
        face. "
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "The tall man nods once. ";
            exit;
        }
        else pass actorAction;
    }
    verDoKiss(actor) = {
        "The thought of kissing a face that bitter is faintly repulsive. ";
    }
    verDoAskAbout(actor) = {
        "\"I am here merely to provide refreshment,\" the man says smoothly. ";
    }
    verDoAskFor(actor, io) = {
        if (io == tray_canapes || io == tray_drink)
            "\"You are welcome to any of the refreshments,\" he says, dipping
                his tray towards you. ";
        else self.verDoAskAbout(actor);
    }
    verDoTellAbout(actor, io) = {
        "The man says, \"Of course. Would you care for refreshment?\" ";
    }
    verIoGiveTo(actor) = {
        "One corner of the man's mouth turns down. \"I believe you have
            reversed our roles,\" he says. ";
    }
    verDoKick(actor) = {}
    doKick(actor) = {
        "The man yelps. \"Well, I see my services are no longer welcome,\" he
            says before walking through a nearby wall. ";
        self.insulted = true;
        self.moveInto(nil);
    }

    setup = {
        self.moveInto(my_hospital_room);
        "\bThe door to your room opens, admitting a tall man in a tuxedo.
            He turns to you and makes an expression which is probably meant
            to be a smile, one which is entirely defeated by the lines of
            bitterness etched in his face. He is carrying a silver tray. ";
        notify(self, &setup1, 1);
    }
    setup1 = {
        "\bThe man wanders around the room, ending up behind the head of your
            bed and out of sight. You feel a familiar sense of helplessness
            at being in a bed while others stand over you. \"Terry
            Hastings?\"\ the man's voice asks. Bemused, you nod. \"You are
            cordially invited to a party.\" The tall man moves back into
            view, smiling. ";
        notify(self, &setup2, 1);
    }
    setup2 = {
        "\b\"If you will, this way.\" The man sweeps
            an arm in the general direction of one of the room's walls.\b
            \"I'm not--that is, I can't--\" you begin.\b
            \"No need to fuss.\" He pulls back the covers of your bed and
            helps you up. You are surprised to find that the faint dizziness
            you had been experiencing is gone. He gently takes you by the
            elbow and leads you through a wall.\b";
        self.moveInto(argument_room);
        pauseAndClear();
        "\b\(Fit the Fourth\):\ Recognizance\b\b";
        makeQuote('"But I\'ll need two brains\n\ 
If I\'m gonna solve my problems"', 'Trout Fishing in America');
        Me.stage = 4;
        Me.travelTo(argument_room);
        notify(self, &leave, 1);
    }
    buttle1 = {
        if (self.insulted) return;
        self.buttleAgain++;
        tray_drink.moveInto(silver_tray);
        self.moveInto(argument_room);
        "\bThe tall man reappears through one of the walls, bearing a silver
            tray covered with drinks. He approaches you and silently offers
            them to you, scowling mildly. ";
        notify(self, &offer_to_others, 2);
    }
    offer_to_others = {
        if (self.insulted) return;
        "\bThe tall man shows the tray to Marie and Jefrey, who ignore
            him. Brow furrowed, the man turns away. ";
        notify(self, &leave, 1);
    }
    buttle2 = {
        if (self.insulted) return;
        self.buttleAgain++;
        tray_drink.moveInto(nil);
        tray_canapes.moveInto(silver_tray);
        self.moveInto(argument_room);
        "\bThe tall man reappears through one of the walls, bearing a silver
            tray covered with canapes. He approaches you and silently offers
            them to you. ";
        notify(self, &offer_to_others, 2);
    }
    leave = {
        if (self.insulted) return;
        self.moveInto(nil);
        "\bThe tall man walks through one of the walls, vanishing. ";
        if (self.buttleAgain == 1)
            notify(self, &buttle1, 3);
        else if (self.buttleAgain == 2)
            notify(self, &buttle2, 3);
    }
;

silver_tray: surface
    noun = 'tray'
    adjective = 'silver'
    location = butler
    sdesc = "silver tray"
    ldesc = {
        "A silver tray. ";
        if (tray_drink.location == self || tray_canapes.location == self) {
            "It is covered with ";
            if (tray_drink.location == self)
                "drinks";
            else "canapes";
            ". ";
        }
    }
;

tray_drink: item
    isThem = true
    takenOne = nil
    noun = 'drink' 'drinks'
    adjective = 'tray' 'remaining'
    sdesc = {
        if (takenOne)
            "remaining ";
        "drinks";
    }
    ldesc = "The drinks are colored pale amber. "
    verGrab(item) = {}
    verDoTake(actor) = {
        if (takenOne)
            "The tall man smoothly moves the tray out of your reach. \"I do
                believe one is enough,\" he says. ";
    }
    doTake(actor) = {
        "You select one of the drinks from the tray. ";
        self.takenOne = true;
        personal_drink.moveInto(actor);
    }
;

personal_drink: item
    noun = 'drink' 'glass'
    adjective = 'sparkling' 'my'
    sdesc = "drink"
    adesc = "your drink"
    thedesc = "your drink"
    ldesc = "A glass of some sparkling drink. "
    verDoDrink(actor) = {}
    doDrink(actor) = {
        "You sip the drink. You fail to recognize it, though it has a pleasing
            taste. As soon as the last of the small drink is gone, the glass
            evaporates. Handy, that. ";
        self.moveInto(nil);
    }
    verDoPourOn(actor, io) = {
        "It would be a shame to waste your drink. ";
    }
;

tray_canapes: item
    isThem = true
    takenOne = nil
    noun = 'canape' 'canapes' 'crackers'
    adjective = 'tray' 'remaining'
    sdesc = {
        if (takenOne)
            "remaining ";
        "canapes";
    }
    adesc = "some <<self.sdesc>>"
    ldesc = "Crackers covered in some sort of spread. "
    verGrab(item) = {}
    verDoTake(actor) = {
        if (takenOne)
            "The tall man smoothly moves the tray out of your reach. \"I do
                believe one is enough,\" he says. ";
    }
    doTake(actor) = {
        "You gingerly take one of the hors d'oeuvres. ";
        self.takenOne = true;
        personal_canape.moveInto(actor);
    }
;

personal_canape: item
    noun = 'canape' 'cracker'
    adjective = 'my'
    sdesc = "canapes"
    adesc = "your canape"
    thedesc = "your canape"
    ldesc = "You cannot tell what the spread on the cracker is. "
    verDoEat(actor) = {}
    doEat(actor) = {
        "In two bites you have finised off the canape. It leaves an odd
            aftertaste. ";
        self.moveInto(nil);
    }
;

marie: Actor
    kissedOnce = nil
    noun = 'woman' 'marie'
    location = argument_room
    sdesc = "Marie"
    ldesc = "Marie is wearing a blue suit. Her black hair is tied in a
        ponytail. She looks desperately bored. "
    actorDesc = {
        if (!argument_room.isseen)
            "A woman in a blue suit and a man in a loose cotton shirt and
                jeans are deep in conversation. ";
        else if (argument_daemon.talking)
            "Marie and Jefrey are deep in conversation. ";
        else "Marie and Jefrey are watching you. ";
    }
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "Marie shakes her head at you. ";
            exit;
        }
        if (v == yesVerb) {
            yesVerb.action(Me);
            exit;
        }
        if (v == noVerb) {
            noVerb.action(Me);
            exit;
        }
        if (v == maybeVerb) {
            maybeVerb.action(Me);
            exit;
        }
        pass actorAction;
    }
    verDoKiss(actor) = {
        if (self.kissedOnce)
            "Marie fends you off. \"No more, Terry. One was quite enough.\" ";
    }
    doKiss(actor) = {
        self.kissedOnce = true;
        "You surprise Marie with a kiss on her lips. When the two of you
            disengage, she chuckles throatily. \"That was unexpected,\" she
            comments. ";
    }
    verDoAskAbout(actor) = {
        "\"Not now, Terry.\" ";
    }
    verDoAskFor(actor, io) = {
        self.verDoAskAbout(actor);
    }
    doSynonym('AskFor') = 'TellAbout'
    verIoGiveTo(actor) = { "Marie ignores you. "; }
    verDoKick(actor) = { "You find yourself unable to kick Marie. "; }
;

jefrey: Actor
    kissedOnce = nil
    isListed = nil            // Marie takes care of describing me
    noun = 'man' 'jefrey' 'jef' 'jeffrey' 'jeff'
    location = argument_room
    sdesc = "Jefrey"
    ldesc = "Jefrey (with one f) is wearing a loose cotton shirt and jeans.
        Stubble covers his chin. His posture is slumped, as if worn down
        over time. "
    actorAction(v, d, p, i) = {
        if (v == helloVerb) {
            "Jefrey grins, but does not answer you. ";
            exit;
        }
        if (v == yesVerb) {
            yesVerb.action(Me);
            exit;
        }
        if (v == noVerb) {
            noVerb.action(Me);
            exit;
        }
        if (v == maybeVerb) {
            maybeVerb.action(Me);
            exit;
        }
        pass actorAction;
    }
    verDoKiss(actor) = {
        if (self.kissedOnce)
            "Jefrey holds you at arms' length. \"Not now,\" he says. ";
    }
    doKiss(actor) = {
        self.kissedOnce = true;
        "Your kiss catches Jefrey by surprise. He is slow to pull away; when
            he does, all he says is, \"Well.\" ";
    }
    verDoAskAbout(actor) = {
        "\"Shh, Terry,\" says Jefrey. ";
    }
    verDoAskFor(actor, io) = {
        self.verDoAskAbout(actor);
    }
    doSynonym('AskFor') = 'TellAbout'
    verIoGiveTo(actor) = { "Jefrey waves you away. "; }
    verDoKick(actor) = { "You find yourself unable to kick Jefrey. "; }
;

argument_daemon: object
    talking = true        // true when Marie and Jefrey are talking
    path = 0              // Which argument Marie & Jefrey have
    pathNum = 1           // Keeps track of where in the argument we are
    paused = nil          // Points to a routine during a pause
                          //  All routines take 1="yes", 2="no", 0="maybe"
    result = 0            // + values mean Marie won; - values mean Jef won
    setup = {
        "\b\"Look, you're not following my argument,\" the woman is saying.
            \"You always react like this.\" She shifts from one foot to the
            other as she talks.\b
        \"I am following your argument and I don't always react like this,
            whatever you mean by 'this.'\" He sighs heavily, rubbing a hand
            along his stubble. \"If you want to talk about someone always--\"\b
        \"TER-ry!\"\ the woman says in a brittle, artificial voice as she
            notices you. \"Jefrey, it's Terry!\"\b
        \"I can see, Marie,\" says Jefrey. \"Why, Terry,\" he continues,
            turning to you, \"I've missed your being gone.\" ";
        self.path = RAND(3);
        self.wantheartbeat = true;
    }
    heartbeat = {
        if (self.paused != nil)
            return;
        switch (self.path) {
            case 1:
                self.argument1;
                break;
            case 2:
                self.argument2;
                break;
            default:
            case 3:
                self.argument3;
                break;
        }
    }
    noComment = {
        "\"Thanks for making a decision, Terry,\" says Jefrey. ";
    }
    unpause = { self.paused = nil; }
    argument1 = {
        "\b";
        switch (self.pathNum) {
            case 1:
                "\"So,\" Jefrey says, \"you don't agree?\"\b
                \"You know I don't.\" Marie shifts her weight from one foot
                    to the other, then sighs resignedly.
                    \"This is as bad as our whole dogs/cats discussion.\"\b
                \"Discussion?\" Jefrey laughs sardonically. \"More like a
                    knock-down drag-out.\" He pauses, then, \"What did we
                    finally decide?\"\b
                \"Nothing,\" says Marie. \"What else?\"\b
                \"Ah, yes, that's right,\" Jefrey agrees. \"Let me see....\"
                    He rubs his chin again. ";
                break;

            case 2:
                "\"Now I remember,\" says Jefrey. \"I say:\ cats make great
                    pets. They can be companionable without fawning and
                    slobbering all over you.\"\b
                Marie is nodding slowly. She looks back at Jefrey. \"Oh,
                    my line. Aah...sure, cats are wonderful if
                    you like cold, ungrateful wretches. I certainly want to
                    take care of a pet that ignores me.\"\b
                \"You'd rather take care of a dumb pet?\"\ Jefrey asks.
                    \"With most dogs you might as well have a pet rock. At
                    least cats are smart.\"\b
                \"Oh, REAL-ly,\" she responds, then pauses. She turns to you.
                    \"Help us out here, Terry:\ you like dogs better, don't
                    you?\"\b
                \"Sure, turn to outside help,\" Jefrey murmurs. \"You might
                    as well answer her, or she'll never stop pestering you,\"
                    he tells you as an afterthought.\b
                \"Jefrey!\"\ Marie snaps. ";
                self.talking = nil;
                self.paused = &question1a;
                break;

            case 3:
                "\"Okay, so I have thought of it,\" Jefrey admits. \"And?\"\b
                \"Well, people who are heavily involved in one or the other
                    often miss the connection, or think it doesn't matter.
                    How many people have you known who enjoy the one and abhor
                    the other?\"\b
                \"I suppose you're discounting college math majors who are
                    Rush fans?\"\b
                \"Jef.\"\b
                \"Hm.\" More chin rubbing. \"Say, why not ask our guest
                    again?\" He inclines his head towards you. \"Do you prefer
                    music over math?\"\b
                \"Now who's turning to outside help?\"\ asks Marie. ";
                self.talking = nil;
                self.paused = &question1b;
                break;
        }
        self.pathNum++;
    }
    question1a(i) = {
        if (i == 1) {        // Dogs
            "\"You see?\"\ nods Marie to Jefrey. \"Terry understands.\"\b
            \"Terry's agreement doesn't necessarily indicate understanding,\"
                says Jefrey sourly.";
            self.result++;
            if (dog.location == Me.location)
                " <<dog.capdesc>>, however, rubs against your legs. ";
        }
        else if (i == 2) {   // Cats
            "\"Terry!\"\ exclaims Marie.\b
            Jefrey sniggers. \"Teach you to count your chickens before they
                hatch.\" ";
            self.result--;
            if (dog.location == Me.location)
                "<<dog.capdesc>> places a paw on your leg and looks at you,
                    hurt. ";
        }
        else self.noComment;
        "\bMarie taps her hand against one leg, lost in thought. \"What about
            math and music?\"\ she finally says.\b
        \"What about them?\"\ says Jefrey.\b
        \"Be serious, please,\" asks Marie. \"Haven't you ever thought about
            how there is music in math and math in music?\"\b
        Jefrey thinks, then blandly says, \"No, not at all,\" before ducking
            Marie's half-hearted slap. ";
        notify(self, &unpause, 1);
        self.talking = true;
    }
    question1b(i) = {
        if (i == 1) {        // Music
            "\"Mmm,\" says Jefrey, scratching his chin. \"Do me a favor,
                Terry? Listen to the music for a sec.\" ";
            self.result--;
        }
        else if (i == 2 || i == 0) {   // Math/neither
            if (i == 2) {
                "\"As I thought.\" ";
                self.result++;
            }
            else "<<self.noComment>>\b";
            "Marie looks at you. \"While we're on the subject, do you hear the
                music? Listen to it for a moment.\" ";
        }
        "You are surprised to realize that music has filled the room. ";
        self.paused = true;
        argument_room.music = true;
        blended_music.moveInto(argument_room);
        high_fast_melody.moveInto(argument_room);
        low_slow_melody.moveInto(argument_room);
    }
    question1c(i) = {
        if (i == 1) {        // Bach
            "Marie smiles at Jefrey, who returns her smile with a frown of
                his own. ";
            self.result++;
        }
        else {               // Beethoven
            "Jefrey nudges Marie gently, who frowns. ";
            self.result--;
        }
        "Then the music ends. ";
        argument_room.music = nil;
        blended_music.moveInto(nil);
        high_fast_melody.moveInto(nil);
        low_slow_melody.moveInto(nil);
        self.conclusion;
    }
    argument2 = {
        "\b";
        switch (self.pathNum) {
            case 1:
                "\"Now that you're here, Terry, would you mind helping us
                    settle some old arguments?\"\ asks Marie.\b
                \"Let Terry cast the deciding vote? Oh, excellent!\"\ Jefrey
                    says, showing excitement for the
                    first time. He turns to you. \"We've been dickering over
                    this and that for ages. Maybe you can, ah, set us
                    straight.\"\b
                Marie places a hand on Jefrey's shoulder, turning him towards
                    her. \"What about faith versus reason?\"\b
                \"You know how much I hate that one.\"\b
                \"More than synthesis versus ex nihilo creation?\"\b
                Jefrey shakes his head, lost in thought. He scratches his
                    chin, then snaps his fingers. \"Introvert or extrovert!\" ";
                break;

            case 2:
                "\"Hmm.\" Marie nods. \"That'll do, for starters.\" Marie
                    glances at you. \"Terry, do you find that you're more of
                    an introvert than an extrovert?\"\b
                \"You sound like a personality test, Marie,\" murmurs Jefrey. 
                    \"Myers-Briggs, to the rescue.\" ";
                self.talking = nil;
                self.paused = &question2a;
                break;
        }
        self.pathNum++;
    }
    question2a(i) = {
        if (i == 1) {        // Introvert
            "\"Thanks, Terry,\" Marie tells you.\b
            \"We're not done yet,\" snaps Jefrey. ";
            self.result++;
        }
        else if (i == 2) {   // Extrovert
            "\"I knew it.\" Jefrey smacks a fist into his palm. \"You know,
                Marie, you could have avoided this by agreeing with me long
                ago.\"\b
            \"I know,\" sighs Marie. \"I suppose it's your turn now.\"\b
            \"No problem,\" responds Jefrey. ";
            self.result--;
        }
        else "<<self.noComment>>\bMarie adds, \"Couldn't you at least try to
            agree with one of us?\" She taps her thigh. \"Your turn,\" she
            tells Jefrey.\bJefrey asks, ";
        "\"Does your enthusiasm normally overwhelm your natural caution?\" Both
            Marie and Jefrey watch you closely. ";
        self.paused = &question2b;
    }
    question2b(i) = {
        if (i == 1) {        // Enthusiasm
            "Jefrey grins sardonically. \"Nice,\" he says.\b
            \"Not nice.\" Marie bites off each word.\b";
            self.result--;
        }
        else if (i == 2) {   // Caution
            "Marie smiles at Jefrey's sudden grimace. \"Not quite what I was
                hoping for,\" Jefrey tells her.\b
            \"Really?\"\ asks Marie, showing teeth.\b";
            self.result++;
        }
        else self.noComment;
        "\"So.\" Jefrey looks at you, then back at Marie. \"What next?\"\b
        \"The paintings. Take a look at them, Terry.\" You turn, suddenly
            noticing the paintings which have filled the frames. ";
        self.paused = true;
        argument_room.paintings = true;
        argument_frames.moveInto(nil);
        blended_paintings.moveInto(argument_room);
        left_painting.moveInto(argument_room);
        right_painting.moveInto(argument_room);
    }
    question2c(i) = {
        if (i == 1) {        // Realism
            "Behind you, you hear Marie whispering to Jefrey. \"Told you.\" ";
            self.result++;
        }
        else {               // Abstract
            "Jefrey nods at your choice of paintings, while Marie sadly
                shakes her head. ";
            self.result--;
        }
        argument_frames.moveInto(argument_room);
        blended_paintings.moveInto(nil);
        left_painting.moveInto(nil);
        right_painting.moveInto(nil);
        self.conclusion;
    }
    argument3 = {
        "\b";
        switch (self.pathNum) {
            case 1:
                "Jefrey resumes talking to Marie. \"I am following your
                    argument. It's just that I don't believe it.\"\b
                \"The argument, or my reasoning?\"\ asks Marie.\b
                \"Argument. Reasoning. Both.\" He scratches his chin.
                    \"Or neither. I don't know!\" Jefrey throws both hands
                    in the air, then lets them drop by his side. \"It just...it
                    just doesn't feel right.\"\b
                Marie sighs. \"It doesn't feel right. Such stunning logic.\" ";
                break;

            case 2:
                "You see Jefrey's jaw clench, then relax. \"It's not my fault
                    you've elevated thought to the point that your feelings
                    are lost.\"\b
                \"My feelings are not--\"\ Marie yells, before stopping and
                    resuming
                    at a more normal level. \"My feelings are not lost. But I
                    don't let them rule my thoughts.\"\b
                \"Terry, back me up here,\" Jefrey says. \"Your feelings are
                    more important than pure logic, right?\" ";
                self.talking = nil;
                self.paused = &question3a;
                break;

            case 3:
                "\"No, look, thought and feeling are inextricably bound up in
                    knowledge and intuition.\"\b
                \"Not necessarily,\" says Jefrey.\b
                Marie stops, then looks at you. \"Let's test it. Terry, do
                    you depend more on knowledge than you do on intuition?\" ";
                self.talking = nil;
                self.paused = &question3b;
                break;
        }
        self.pathNum++;
    }
    question3a(i) = {
        if (i == 1) {        // Feelings
            "Marie chews on her bottom lip. \"But how can you--I mean, if you
                don't--oh, never mind.\" She shakes her head.\b
            \"No hard feelings?\"\ Jefrey asks, then dodges Marie's shove.";
            self.result--;
        }
        else if (i == 2) {   // Logic
            "Marie nods at you. \"Thank you, Terry.\"\b
            \"I should have known,\" Jefrey mutters.";
            self.result++;
        }
        else self.noComment;
        "\b\"This all goes back to the question of whether knowledge or
            intuition plays a more crucial role in everyday living,\" says
            Marie.\b
        \"Not again, please,\" Jefrey says. ";
        self.talking = true;
        notify(self, &unpause, 1);
    }
    question3b(i) = {
        if (i == 1) {        // Knowledge
            "\"Mmm,\" says Marie.\b
            \"Care for another test?\"\ asks Jefrey.\b
            Marie shrugs. \"Why not?\" ";
            self.result++;
        }
        else if (i == 2) {   // Intuition
            "Jefrey nods. \"Interesting.\"\b
            Marie says, \"Let's have another try.\" ";
            self.result--;
        }
        else self.noComment;
        "Marie points towards the table. You turn and see that two books have
            found their way to its surface. \"Do us a favor, Terry,
            and grab one of those books for us.\" ";
        self.talking = nil;
        self.paused = true;
        blended_books.moveInto(argument_room);
        left_book.moveInto(argument_table);
        right_book.moveInto(argument_table);
    }
    question3c(i) = {
        if (i == 1) {        // Truth
            "\"Thanks, Terry,\" Marie says. Jefrey frowns at you.";
            self.result++;
        }
        else {               // Beauty
            "Jefrey flashes you a thumbs-up. \"Nice job,\" he says.";
            self.result--;
        }
        blended_books.moveInto(nil);
        left_book.moveInto(nil);
        right_book.moveInto(nil);
        self.conclusion;
    }
    conclusion = {
        "\bJefrey and Marie move away from you and lower their voices.
            \"So?\"\ Jefrey asks Marie.\b
        \"Looks like ";
        if (self.result > 0)
            "I won.\"\bJefrey says, ";
        else if (self.result < 0)
            "you won.\"\bJefrey says, ";
        else {
            "a tie.\" She takes a coin from her pockets. \"Call it?\"\b
            \"Heads,\" he says. She flips the coin in the air, catches it,
                and shows it to Jefrey. ";
            if (RAND(100) > 50) {
                "\"Woo-hoo!\"\ he says. ";
                self.result--;
            }
            else {
                "He sighs. ";
                self.result++;
            }
        }
        "\"That means <<self.result > 0 ? "I" : "you">> get Terry.\"\b
        \"Thanks,\" Marie says, <<self.result > 0 ? "smiling" : "frowning">>.";
        if (self.result > 0) {
            "\bYou hear a light tinkling sound. The north wall splits open.
                \"Okay, Terry,\" Jefrey says. \"In you go.\" He shoves you
                through the opening";
            if (dog.location == argument_room) {
                ". As the opening shuts behind you, you hear Jefrey saying,
                    \"And you, my doggie friend, can stay with me.\"\b";
                dog.clearProps;
                dog.wantheartbeat = nil;
            }
            else ", which then shuts behind you. ";
            "You spend a moment in darkness before being disgorged into
                light.";
            pauseAndClear();
            "\b";
            Me.travelTo(clock_room);
            Me.stage = '4b';
        }
        else {
            " She turns to you. \"Off you go, then.\"\bThere is
                a horrendous grinding noise, as if someone had recorded
                the sound of a construction site and sped up the playback.
                Then the room around you vanishes. ";
            if (dog.location == argument_room) {
                "As the room fades, you hear Marie saying, \"Stay. Stay.
                    Good dog.\" ";
                dog.clearProps;
                dog.wantheartbeat = nil;
            }
            pauseAndClear();
            "\b";
            Me.travelTo(center);
            Me.stage = '4a';
        }
        self.wantheartbeat = nil;
        butler.insulted = true;        // A quick hack to stop the butler
    }
;

blended_music: intangible
    noun = 'music'
    sdesc = "music"
    smelldesc = "It has no smell. "
    listendesc = "When you concentrate, you can hear two melodies. The first
        melody is higher, fast, intricate, and very regular. The second is
        lower, slow, and more lyrical. You cannot resolve both at once. "
;

high_fast_melody: intangible
    noun = 'melody'
    adjective = 'higher' 'fast' 'intricate' 'regular' 'first'
    sdesc = "higher melody"
    smelldesc = "It has no smell. "
    listendesc = {
        "It is a Bach invention, with melodic lines intricately woven in and
            around each other. As you listen, it becomes louder, swamping
            the other melody entirely. ";
        argument_daemon.question1c(1);
    }
;

low_slow_melody: intangible
    noun = 'melody'
    adjective = 'lower' 'slow' 'lyric' 'lyrical' 'second'
    sdesc = "lower melody"
    smelldesc = "It has no smell. "
    listendesc = {
        "It is a Beethoven piano sonata. It flows and fills the room, making
            it impossible to hear the other melody. ";
        argument_daemon.question1c(2);
    }
;

blended_paintings: fixedItem
    noun = 'paintings' 'pictures'
    sdesc = "paintings"
    ldesc = "There are two paintings, one on the left and one on the right.
        The one on the left is of a landscape; the one on the right is more
        abstract. You can tell nothing else without looking directly at one
        or the other. "
;

left_painting: fixedItem
    noun = 'painting' 'landscape' 'picture'
    adjective = 'left' 'landscape'
    sdesc = "left painting"
    ldesc = {
        "The landscape has been rendered in almost photorealistic detail. It
            looks to be from the late 1800's, although it's been too long since
            your art history class. Out of the corner of your eye you
            notice the other frame emptying, the painting it held draining
            away. Shortly thereafter, this painting vanishes as well. ";
        argument_daemon.question2c(1);
    }
;

right_painting: fixedItem
    noun = 'painting' 'picture'
    adjective = 'right' 'abstract'
    sdesc = "right painting"
    ldesc = {
        "A swirling mass of dribbled colors. It must be by Jackson Pollack,
            or one of his followers. As you stare at the painting, you notice
            that the other painting has vanished. Shortly thereafter, this
            painting vanishes as well. ";
        argument_daemon.question2c(2);
    }
;

blended_books: fixedItem
    noun = 'books'
    ldesc = "Two books have appeared on the table. The one on the left has a
        plain leather cover; the one on the right has a painting on its cover. "
    verDoTake(actor) = {
        "You'll have to specify one or the other of the books. ";
    }
    doSynonym('Take') = 'Read'
;

left_book: item
    noun = 'book'
    adjective = 'left' 'plain' 'leather' 'leather-bound'
    sdesc = "plain book"
    ldesc = "Embossed on its cover is the phrase, \"Book of Facts.\" "
    verDoTake(actor) = {}
    doTake(actor) = {
        "You pick up the leather-bound volume, surprised at how light it is.
            Then Marie has taken it from you and picked up the other book. 
            She does something quick with her hands that you don't quite
            follow and the books vanish. ";
        argument_daemon.question3c(1);
    }
    doSynonym('Take') = 'Read'
    doPutIn(actor, io) = {
        self.doTake(actor);
    }
    doSynonym('PutIn') = 'PutOn'
;

right_book: item
    noun = 'book'
    adjective = 'right' 'colored' 'brightly-colored'
    sdesc = "brightly-colored book"
    ldesc = "On its cover are several bright paintings. Their beauty is
        phenomenal. "
    verDoTake(actor) = {}
    doTake(actor) = {
        "You pick up the book of paintings, surprised at how heavy it is.
            Then Jefrey has taken it from you and picked up the other book. He
            does something quick with his hands that you don't quite
            follow and the books vanish. ";
        argument_daemon.question3c(2);
    }
    doSynonym('Take') = 'Read'
    doPutIn(actor, io) = {
        self.doTake(actor);
    }
    doSynonym('PutIn') = 'PutOn'
;


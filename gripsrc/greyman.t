/*
    The grey man from _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: greyman.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

grey_man: Actor
    selfDisambig = true
    isHim = true
    askme = &greymandesc
    scoldNum = 0
    holdingTight = nil
    holdingLoose = nil
    firstDesc = true
    respondToYesNo = nil

    noun = 'man' 'himself'
    adjective = 'grey' 'gray'
    sdesc = "grey man"
    stringsdesc = 'The grey man'
    ldesc = "There is no color to him, an Edward Gorey sketch come to life.
        His jet-black eyes glitter to either side of an aquiline nose and
        above an outthrust chin. "
    actorDesc = {
        if (self.firstDesc) {
            "A grey man stands over you, grinning. ";
            self.firstDesc = nil;
            return;
        }
        "The grey man ";
        if (holdingTight == true)
            "holds you tightly with one arm. ";
        else if (holdingLoose == true)
            "holds you loosely. ";
        else "is here. ";
    }
    thedesc = "the grey man"
    adesc = "a grey man"
    disavow = "The grey man ignores you. "
    alreadyTold = "The grey man ignores you. "
    takedesc = "There's no way he'll let you do that. "
    touchdesc = "The grey man evades your touch without seeming to move. "
    greymandesc = "The man laughs at you. \"Don't you have other things to
        worry about?\"\ he asks you. "
    actorAction( v, d, p, i ) = {
        if ((v == yesVerb || v == noVerb || v == maybeVerb) &&
            self.respondToYesNo) {
            "The grey man laughs at you, a horrible sound. ";
            exit;
        }
        "The grey man doesn't appear interested. ";
        exit;
    }
    verDoAskFor(actor, io) = { "The grey man ignores you. "; }
    verIoGiveTo(actor) = { "The grey man ignores you. "; }
    verDoKick(actor) = {
        if (!holdingLoose)
            "The grey man catches your leg, then throws you to the ground. He
                grins lopsidedly at you. \"Practice makes perfect,\" he tells
                you as you stand. ";
    }
    doKick(actor) = {
        "You bring your heel down hard on the grey man's instep. He hisses in
            pain, but manages to keep hold of you. \"This speeds things up,\"
            he says, \"though not by much.\" ";
        self.tossOverBluff;
    }
    verDoAttack(actor) = {
        if (!holdingLoose)
            "The grey man fluidly grabs your arm, twisting it painfully behind
                your back. He smiles, white teeth and grey lips. \"Practice
                makes perfect,\" he tells you. ";
    }
    doAttack(actor) = {
        "You twist in the grey man's grip, trying to escape. Your fists pound
            against his chest. He grabs both of your hands in one of his.
            \"Your father would be so proud,\" he says. ";
        self.tossOverBluff;
    }
    verDoAttackWith(actor, io) = {}
    doAttackWith(actor, io) = {
        if (io == oak_staff) {
            "You try to swing the staff at the grey man, but he easily plucks
                it from your grasp and throws it into the kill. \"Your father
                would be so proud,\" he says. ";
            self.tossOverBluff;
        }
        else "The grey man says, \"You appear to have caught mimesis with its
            pants around its ankles.\" {ERROR} ";
    }
    verDoCutWith(actor, io) = {
        if (!holdingLoose)
            "The grey man grabs your wrist. \"Naughty, naughty,\" he says. ";
    }
    doCutWith(actor, io) = {
        "With all your strength you drive the blade of the pocketknife deep
            into the grey man's thigh. He screams, a high-pitched, reedy
            sound. ";
        self.pullOverBluff;
    }
    verIoCutIn(actor) = {
        if (!holdingLoose)
            "The grey man grabs your wrist. \"Naughty, naughty,\" he says. ";
    }
    ioCutIn(actor, dobj) = { self.doCutWith(actor, dobj); }

    scoldTerryA = {
        switch (++scoldNum) {
            case 1:
                "\b\"You've been very busy,\" the grey man says. \"Very, very
                    busy.\" His voice is like a stick of butter squeezed
                    through a fist.
                    \"Don't you even know why you're here?\"\n";
                qDaemon.questionAsked('The grey man laughs at you, a horrible
                    sound.', 'The grey man laughs at you, a horrible sound.',
                    'The grey man laughs at you, a horrible sound.');
                self.respondToYesNo = true;
                break;
            case 2:
                "\b\"No guesses?\"\ Eyebrows lift in mock surprise. ";
                self.respondToYesNo = nil;
                if (old_woman.location == green3 || old_woman.location ==
                        green4 || old_woman.location == green2) {
                    "He points ";
                    if (old_woman.location != green3) "down the hall ";
                    "at the old woman in the wheelchair. \"To help idiots
                    like her, perhaps? ";
                }
                else "\"To help idiots like that old woman, perhaps? ";
                "You weren't successful the first time.\"\b
                    You turn away, your cheeks glowing. The time you spent
                    volunteering at the hospital was far from enjoyable.
                    When you look back, the grey man has vanished.\n";
                grey_man.moveInto(nil);
                scoldNum = 0;
        }
        if (scoldNum == 1)
            notify(self, &scoldTerryA, 1);
    }
    scoldTerryB = {
        switch (++scoldNum) {
            case 1:
                "\b";
                if (buddy.location == self.location) {
                    "The grey man grins at Little Buddy. \"Run along, now,\"
                        he says softly. Little Buddy blanches, then begins
                        walking down the hall. \"Um. Ok. I'll just...go see
                        if...\" He turns and breaks into a run.\bThe grey man
                        turns back to you. ";
                    buddy.clearProps;
                    buddy.moveInto(school_library);
                    buddy.moveInto(school_library);    // To handle follower
                }
                "\"You've been very busy,\" the grey man says. \"Very, very
                    busy.\" His voice is like a stick of butter squeezed
                    through a fist.
                    \"Don't you even know why you're here?\"\n";
                self.respondToYesNo = true;
                qDaemon.questionAsked('The grey man laughs at you, a horrible
                    sound.', 'The grey man laughs at you, a horrible sound.',
                    'The grey man laughs at you, a horrible sound.');
                break;
            case 2:
                "\b\"You've really no clue, have you?\" Eyebrows lift in mock
                    surprise. \"To help a fellow student, perhaps? Then again,
                    why begin now?\"\b
                    You feel your face growing red, and you glance at your
                    feet. They never had much time for you, nor you for them.
                    When you look back up, the grey man has vanished.\n";
                self.respondToYesNo = nil;
                grey_man.moveInto(nil);
                scoldNum = 0;
        }
        if (scoldNum == 1)
            notify(self, &scoldTerryB, 1);
    }
    scoldTerryC = {
        switch (++scoldNum) {
            case 2:
                "\b\"Why, Terry, what a pleasant surprise!\" The arm gripping
                    you twists slightly, pinning you against the grey man. He
                    squints down at you, blinks several times, discomforted
                    by the mild sunlight. ";
                if (dog.location == self.location) {
                    "He lashes out smoothly with one foot, catching <<
                        dog.thedesc>> by surprise. <<dog.capdesc>> yipes and
                        runs. ";
                    dog.moveInto(doghouse);
                }
                dog.clearProps;
                dog.wantheartbeat = nil;
                "\"You've been oh so naughty, and your father has sent
                    me to punish you.\"\b
                    You suddenly realize where you had heard the voice from the
                    needled sphere. Your father's voice, nearly choked by
                    his cancer. ";
                break;
            case 3:
                "\bThe grey man tightens his arm across your chest. \"Come
                    along, come along, I have something special planned!\"
                    He drags you down the hill.\b";
                self.moveInto(bluff);
                Me.travelTo(bluff);
                break;
            case 4:
                "\bThe grey man nods towards the sharp drop-off. \"My, that
                    water looks mighty cold,\" he says, not noticing that his
                    hold on you has loosened. ";
                holdingTight = nil;
                holdingLoose = true;
                break;
            case 5:
                "\b\"No use waiting any longer,\" the grey man says. \"Time
                    for you to join your faerie friends.\" ";
                self.tossOverBluff;
            default:
        }
    }
    tossOverBluff = {
        "Then the grey man lifts you effortlessly and heaves you over the
            bluff. The sound of the kill grows louder as it rushes up to meet
            you.\b
            You jolt upright with the shock of landing. Instead of water
            you are surrounded by a hospital bed. The room is empty of people;
            only monitors keep watch over you. Lassitude overtakes you, and you
            drop into a dreamless sleep....";
        die();
    }
    pullOverBluff = {
        "In pain, the grey man stumbles over the edge of the bluff. With one
            hand he claws at the ground; with the other he drags you with him.
            In desperation you pry his hand free, but not before you have slid
            after him.\b";
        self.moveInto(nil);
        Me.travelTo(below_bluff);
        unnotify(self, &scoldTerryC);
        notify(trapped_faeries, &thrashAbout, 0);
        greyManAh.solve;
        incscore(5);
    }
;


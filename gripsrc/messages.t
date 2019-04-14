/*
    Messages, voices from the other side in _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: messages.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

class message: item
    weight = 3
    bulk = 2
    decaying = nil
    messageStr = ''
    setup(msg) = {
        if (msg == nil)
            decaying = true;
        else self.messageStr = msg;
        notify(self, &giveMessage, 4);
    }
    verDoTake(actor) = {}
    verDoPutIn(actor, io) = { self.doTake(actor); }
;

nurseMessage: message
    noun = 'pyramid' 'message'
    adjective = 'paper'
    sdesc = "paper pyramid"
    ldesc = "A small paper pyramid, about three centimeters on an edge. "
    verDoTake(actor) = {}
    doTake(actor) = {
        if (decaying)
            "The pyramid begins glowing softly, then flares brighter. You can
                hear something coming from the pyramid, but it is more
                like the absence of sound than anything audible. As the
                non-sound ends the pyramid flakes into ash and is gone. ";
        else "The pyramid begins glowing softly. It unfolds like a
            flower and a feminine voice issues from it, saying, \"<<
            self.messageStr>>\" When the light dies down, the pyramid is
            gone. ";
        unnotify(self, &giveMessage);
        self.moveInto(nil);
    }
    giveMessage = {
        if (uberloc(Me) == self.location) {
            "\b";
            self.doTake(Me);
        }
        self.moveInto(nil);
    }
;

doctorMessage: message
    noun = 'cube' 'message'
    adjective = 'wooden'
    sdesc = "wooden cube"
    ldesc = "A wooden cube, about four centimeters on an edge. Its surface is
        remarkably polished. "
    doTake(actor) = {
        if (decaying)
            "Something inside the cube softly clicks. Its walls slide partway
                open, then stop. A non-sound issues from the cube, an absence
                of sound which you can paradoxically hear. As the non-sound
                ends the cube melts into a puddle, then evaporates. ";
        else "Something inside the cube softly clicks. Its walls
            slide open, then flat, and it begins glowing with a warm light.
            A masculine voice drifts from the cube, saying, \"<<
            self.messageStr>>\" Then the cube is gone. ";
        unnotify(self, &giveMessage);
        self.moveInto(nil);
    }
    giveMessage = {
        if (uberloc(Me) == self.location) {
            "\b";
            self.doTake(Me);
        }
        self.moveInto(nil);
    }
;

fatherMessage: message
    counter = 1
    upStairs = nil
    downStairs = nil
    noun = 'sphere' 'message'
    adjective = 'shiny' 'metal'
    sdesc = "metal sphere"
    ldesc = "A shiny metal sphere, dotted all over with tiny holes. "
    setup(msg) = {
        notify(self, &breathe, 1);
        self.counter = 1;
        sphereAh.see;
        pass setup;
    }
    doTake(actor) = {
        "You reach down and take the sphere. As you straighten up, tiny
            needles spring from the thousands of holes which dot it. ";
        if (gloves.isworn)
            "The needles jab through your gloves; w";
        else "W";
        "ith a curse you throw the sphere, now smeared red with your
            blood,
        away from you. As it falls it bursts into flame, oily smoke curling
            from it. From the center of the flame you hear an eerily familiar
            voice say, \"<<self.messageStr>>\" Then the sphere vanishes in a
            final burst of fire. ";
        unnotify(self, &giveMessage);
        unnotify(self, &breathe);
        sphereAh.solve;
        self.moveInto(nil);
    }
    prepare1 = {
        self.setup('Well. Interesting stunt you\'ve pulled, coming to
            where I now live. I trust you\'ll stay for my avalanche.');
        "\bThe air above you shimmers for a brief moment, during which a metal
            sphere falls from the disturbance to the ground below. ";
        self.moveInto(uberloc(Me));
    }
    giveMessage = {
        "\bThe sphere leaps from the ground, hurtling towards your face.
            Instinctively you throw your hands in front of your face. The
            sphere, needles extended from its holes, rams into your hands,
            drawing blood";
        if (gloves.isworn) " which wets your gloves";
        ". With a curse you throw it away from you. As it
            falls, the sphere bursts into flame, oily smoke curling
            from it. From the center of the flame you hear an eerily familiar
            voice say, \"<<self.messageStr>>\" Then the sphere vanishes in a
            final burst of fire. ";
        unnotify(self, &breathe);
        sphereAh.solve;
        self.moveInto(nil);
    }
    breathe = {
        if (uberloc(self) != uberloc(Me)) {
            "\bThe metal sphere rolls ";
            if (self.upStairs)
                "up the stairs ";
            else if (self.downStairs)
                "down the stairs ";
            self.upStairs = self.downStairs = nil;
            "towards you. When it is less than a
                meter away it stops, waiting. ";
            self.moveInto(uberloc(Me));
        }
        notify(self, &breathe, 1);
    }
;

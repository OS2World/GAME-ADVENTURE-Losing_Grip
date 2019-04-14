/*
    Nesting Dolls, from part 4b of _Losing Your Grip_.
    Original concept and programming: Nicholas James
    $Id: dolls.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

// A function to strip all the nouns & adjectives from an object
stripwords: function(obj)
{
    local wordlist, i, len;

    wordlist = getwords(obj, &noun);
    len = length(wordlist);
    for (i = 1; i <= len; i++)
        delword(obj, &noun, wordlist[i]);
    wordlist = getwords(obj, &adjective);
    len = length(wordlist);
    for (i = 1; i <= len; i++)
        delword(obj, &adjective, wordlist[i]);
}

class playerCopy: room
    mysize = 1       // My size
    relsize = { return (Me.psize - self.mysize); }    // My relative size
    isInDoll = true     // Part of the dolls
    isHim = true
    isHer = true
    notakeall = true
    notakedesc = nil // True if we're not to print a takedesc
//    contentsVisible = { return nil; }

    mysdescs = [
        'titanic pillars', 'gargantuan doppelganger', 'brobdingnagian double',
        'giant twin', '', 'miniature copy of yourself', 'miniscule speck']
    myldescs = [
        'A pair of the largest pillars you have ever seen.  They each have
            a wide, flat base that extends beyond the cylindrical pillars
            in only one direction.  The base is hemicylindrical, though
            irregular.  The pillars continue for what looks like forever,
            stretching long past the limits of your vision.',
        'You stand transfixed at the sight of your gargantuan doppelganger.
            Your doppelganger, however, is oblivious to your presence.  This
            is most likely due to your difference in size--you are too small
            to be perceived.',
        'Your oversized double towers over you, nearly fifty times
            your size.',
        'Awe pervades you as you survey this twin of gratuitous proportions
            that towers high above your own somewhat meager stature.  The
            amplification and magnification of every gesture, every
            expression, every motion presents an odd, rather disconcerting
            caricature of your mannerisms.  The face you find most
            disturbing; in the deep chasms of the eyes you find an austere
            comfort.',
        '',
        'The smaller copy of yourself is perfect in every respect.  You
            feel an intense sort of empathy with the copy, especially when
            you look into the eyes, but that empathy is accompanied by an
            equal mixture of sadness at your separation.',
        'The speck is small enough to obscure any detail you might otherwise
            see.  It is entirely conceivable that it is another copy of
            you.'
        ]
    isListed = {
        if (self.relsize < 3 && self.relsize) return true;
        return nil;
    }
    isVisible(loc) = {
        if (self.relsize > 2 || self.relsize == 0) return nil;
        if (Me.location == self) return true;
        pass isVisible;
    }
    // A routine to change the words associated w/this object
    changeid = {
        // First, remove all the old nouns/adjectives
        stripwords(self);
        // Next, add the nouns
        if (self.relsize < 2 && self.relsize != 0) {
            addword(self, &noun, 'me');     // Don't add these words to
            addword(self, &noun, 'self');   // the "invisible me"
        }
        switch (self.relsize) {
            case -4:        // 4x larger
                addword(self, &noun, 'pillars');
                addword(self, &noun, 'pillar');
                addword(self, &noun, 'base');
                addword(self, &adjective, 'titanic');
                break;
            case -3:
                addword(self, &noun, 'doppelganger');
                addword(self, &adjective, 'gargantuan');
                break;
            case -2:
                addword(self, &noun, 'double');
                addword(self, &adjective, 'brobdingnagian');
                break;
            case -1:
                addword(self, &noun, 'twin');
                addword(self, &noun, 'version');
                addword(self, &adjective, 'giant');
                addword(self, &adjective, 'larger');
                break;
            case 1:
                addword(self, &noun, 'copy');
                addword(self, &adjective, 'miniature');
                break;
            case 2:
                addword(self, &noun, 'speck');
                addword(self, &adjective, 'miniscule');
                break;
            default:
        }
    }

    sdesc = {
        if (self.relsize == -1 && Me.location == self)
            "In your own grip";
        else if (self.relsize < 3)
            say(self.mysdescs[self.relsize + 5]);
    }
    ldesc = {
        if (self.relsize == 1 && !dolldaemon.seenSelf) {
            "Identical to you in every respect save size. Startled,
                you recoil involuntarily.  The copy responds in kind,
                which makes you gape with incredulity, which makes your copy
                gape with incredulity.  As
                realization dawns you both smirk in unison--until you see
                the oddly-compelling eyes. They draw your attention, daring
                you to stare down into their endless depths. ";
            dolldaemon.seenSelf = true;
        }
        else if (self.relsize == -1 && Me.location == self)
            "You are being securely held by your larger self.  Your own face
                peers down at you from a great height, an expression of
                fascination evident on its features.  You wriggle about some
                experimentally, but can do nothing, it seems, aside from
                staring into your own eyes. ";
        else if (self.relsize < 3)
            say(self.myldescs[self.relsize + 5]);
    }
    adesc = {
        if (self.relsize == -4)
            "two <<self.sdesc>>";
        else pass adesc;
    }
    thedesc = {
        if (self.relsize == -4)
            "two <<self.sdesc>>";
        else pass thedesc;
    }
    takedesc = {
        if (!self.notakedesc)
            inherited.takedesc;
        else self.notakedesc = nil;
    }
    replace nrmLkAround( verbosity ) =
    {
        if ( verbosity ) {
            "\n\t<<self.ldesc>>";
        }
    }

    noexit = "Even if you could somehow wriggle free from your grasp, you
        are a terminal distance from solid footing. "
    enterRoom(actor) = {
        self.lookAround(true);
    }
    roomAction(a, v, d, p, i) = {
        if (!v.isGripVerb) {
            "%You% are held much too tightly to do most anything. ";
            exit;
        }
        else pass roomAction;
    }
    verDoTake(actor) = {
        if (self.relsize < 0)
            "There is no way for %you% to lift such a colossus. ";
        else if (self.relsize > 1)
            "%You% are much too large to handle such a delicate creature. ";
        else if (self.relsize == 0)
            "%You% cannot pick yourself up. ";
        else if (self.location == actor)
            "%You% already %have% <<self.thedesc>>! ";
    }
    doTake(actor) = {
        // Check for completion
        if (self.mysize == 4 && dolldaemon.checkSelves) {
            "As your hand closes about your smaller self, you become aware
                of all of the sensations and perceptions of all instances
                of yourself. ";
            if (!dolldaemon.dollComplete) {
                "The sensation quickly passes, leaving you puzzled.\n";
                self.notakedesc = true;   // Used to be outhide(true);
                pass doTake;
            }
            "You find yourself reaching down with four arms, grasping four
                copies of yourself, each smaller, each somehow deeper.  Your
                fingers close on yourselves, seeming never to meet.  As you
                pull your hands towards yourselves, you find that you can
                continue the motion, pulling all fragments of yourself
                together into the largest one.  You continue further, feeling
                the walls around you invert.  For an instant you contain the
                universe, until all collapses about you...\b";
            dolldaemon.dolllist[1].moveInto(nil);
            dolldaemon.endIt;
            return;
        }
        dolldaemon.selfComplete = nil;
        "(Praying you don't drop yourself)\n";
        pass doTake;
    }
    doDrop(actor) = {
        dolldaemon.selfComplete = nil;    // Selves aren't complete anymore
        "(Ever so gently placing yourself on the floor)\n";
        pass doDrop;
    }
    verDoAskAbout(actor) = {
        if (self.relsize < 0)
            "The other you does not hear you. ";
        else "The other you does not respond. ";
    }
    verDoThrow(actor) = {
        if (self.location == Me)
            "You shudder at the thought. ";
        else "You would first have to be holding <<self.thedesc>>. ";
    }
    verDoThrowAt(actor, io) = (self.verDoThrow(actor))
    verDoThrowTo(actor, io) = (self.verDoThrow(actor))
;

// Such details as the face, &c, of the larger copies
largeCopyDetails: floatingItem, decoration
    noun = 'face' 'eye' 'eyes' 'pupil' 'fibers' 'iris'
    adjective = 'large'
    location = {
        if (Me.location.isInDoll && Me.psize != 5)
            return Me.location;
        return nil;
    }
    myword = {            // Returns the word used to refer to this obj
        local list, word;

        list = objwords(1);
        if (length(list) == 0) return '';
        if (length(list) == 2)
            word = list[2];
        else word = list[1];
        if (word == 'face' || word == 'eye' || word == 'eyes' ||
            word == 'pupil' || word == 'fibers' || word == 'iris')
                return word;
        list = objwords(2);
        if (length(list) == 0) return '';
        if (length(list) == 2)
            return list[2];
        return list[1];
    }
    sdesc = {
        local word;

        if ((word = self.myword) == '')
            "large face";
        else "large <<word>>";
    }
    ldesc = {
        local word;

        if ((word = self.myword) == '')
            word = 'face';
        switch (word) {
            case 'face':
                "There is something slightly grotesque about the enormous
                    features which loom above you. The features which most
                    hold your attention, however, are the eyes. ";
                break;
            case 'eye':
            case 'eyes':
                "At this magnification, the millions of tendrils and
                    striations in the iris lay waste to your former concept
                    of beauty.  The undulating fibers which frame the pupil
                    seem to form a gateway. ";
                 break;
            case 'pupil':
                "Its blackness looms before you, a rimmed portal to
                    elsewhere. ";
                break;
            case 'fibers':
                "Twisting, turning, seeming to spiral ever inwards... ";
                break;
            case 'iris':
                "Although its color is strikingly varigated, it is somehow
                    overshadowed by the pupil in its center. ";
                break;
        }
    }
    verDoStare(actor) = {
        local word;

        if (((word = self.myword) != 'eye') && (word != 'eyes'))
            pass verDoStare;
    }
    doStare(actor) = {
        stareupVerb.action(actor);
    }
    verDoLookin(actor) = (self.verDoStare(actor))
    doLookin(actor) = {
        stareupVerb.action(actor);
    }
    verDoStareup(actor) = (self.verDoStare(actor))
    doStareup(actor) = { stareupVerb.action(actor); }
    verDoStaredown(actor) = (self.verDoStare(actor))
    doStaredown(actor) = { staredownVerb.action(actor); }
;

// The eyes of the smaller copy
smallCopyDetails: floatingItem, decoration
    noun = 'eye' 'eyes'
    adjective = 'small'
    location = {
        if (Me.location.isInDoll) {
            local bro;

            bro = dolldaemon.queryLittleBrother;
            if (bro)
                return bro.location;
        }
        return nil;
    }
    sdesc = "small eyes"
    ldesc = "The eyes, though small, beckon you to greater depths of
        self-exploration than you have ever contemplated. "
    verDoStare(actor) = {}
    doStare(actor) = {
        staredownVerb.action(actor);
    }
    verDoLookin(actor) = {}
    doLookin(actor) = {
        staredownVerb.action(actor);
    }
    verDoStareup(actor) = {}
    doStareup(actor) = { stareupVerb.action(actor); }
    verDoStaredown(actor) = {}
    doStaredown(actor) = { staredownVerb.action(actor); }
;

class doll: room
    isOpen = nil
    iscontainer = true
    isInDoll = true
    isDoll = true
    contentsReachable = { return self.isOpen; }
    contentsVisible = {
        return (((self.isOpen && self.relsize < 1) ||
            (self.relsize > 0 && inside(Me, self)))
            && !isclass(Me.location, playerCopy));
    }
    showcontents = {
        if (self.contentsVisible) {
            local list;

            list = contlist(self);
            if (length(list)>0) {
                "\^<<self.thedesc>> seems to contain <<listlist(list)>>. ";
            }
        }
    }
    dsize = 1        // Doll's size
    mylid = nil      // Pointer to the associated lid
    relsize = { return (self.dsize - Me.psize + 1); } // Reverse of playerCopy
    isListed = {
        if (self.relsize > -2) return true;
        return nil;
    }
    notakeall = { return (self.relsize < -1); }
    isVisible(loc) = {
        if (self.relsize < -1) return nil;
        if (Me.location == self) return true;
        pass isVisible;
    }
    // A routine to change the words associated w/this object
    changeid = {
        // First, remove all the old nouns/adjectives
        stripwords(self);
        // Next, add the nouns
        switch (self.relsize) {
            case 4:         // 4x larger
                addword(self, &adjective, 'vast');
                addword(self, &noun, 'wall');
                break;
            case 3:
                addword(self, &adjective, 'gigantic');
                addword(self, &adjective, 'curved');
                addword(self, &noun, 'structure');
                break;
            case 2:
                addword(self, &adjective, 'enormous');
                goto kludge_jump;
            case 1:
                addword(self, &noun, 'container');
                addword(self, &adjective, 'large');
                goto kludge_jump;
            case 0:
                addword(self, &adjective, 'small');
                if (self.isOpen) {
                    addword(self, &noun, 'section');
                    addword(self, &noun, 'half');
                    addword(self, &adjective, 'lower');
                }
kludge_jump:
                addword(self, &noun, 'doll');
                addword(self, &adjective, 'nesting');
                addword(self, &adjective, 'wooden');
                break;
            case -1:
                addword(self, &noun, 'capsule');
                addword(self, &adjective, 'minute');
                break;
        }
        if (proptype(self, &mylid) == 2)
            self.mylid.changeid;
    }
    ldesc = {
        if (Me.location == self) {    // Player inside me
            if (self.relsize == 1) {  // Contains largest player possible
                "You are in a cramped wooden container with smooth curved
                    surfaces which restrict your motion. ";
                if (self.isOpen)
                    "The ceiling is conspicuous in its absence, and you can
                        see a larger version of yourself peering at you. ";
                else "By reaching above your head, you can feel a groove
                    running around the interior of the container.  The ceiling
                    arcs high above you. ";
            }
            else if (self.relsize == 2)
                "You are standing in the middle of a vast open space with a
                    wooden floor. ";
            else if (self.relsize > 2)
                "You are standing on an infinitely-large surface made of some
                    strange fibrous material.  It is brown in color and
                    striated with fibers as thick as your head.  You can see
                    your own eyes staring into you from the face that
                    dominates the sky. ";
        }
        else {
            switch (self.relsize) {
                case -1:        // Too small to be handled
                    "It is so small, you almost didn't see it. It appears
                        to be part of the doll set, but you can't really tell
                        if it is an upper half or a lower. ";
                    break;
                case 0:         // Can be handled
                    "This is a very plain Russian doll. You feel a peculiar
                        sort of empathy with this doll, almost as if you and
                        it are inexplicably linked. ";
                    if (self.isOpen) {
                        "It has been disassembled; this is the lower half.
                            It is hollow inside";
                        if (length(contents) != 0)
                            " and seems to contain <<listcont(self)>>";
                        ". ";
                    }
                    else "There is a groove which runs along its outside,
                        bisecting it at the waist. ";
                    break;
                case 1:
                    "It is almost as wide as your arm span. ";
                    if (self.isOpen)
                        "This doll is disassembled and the rim, which is
                            usually connected to the upper section, is a good
                            meter above you. ";
                    else "You can almost reach the groove which runs along its
                        outside and marks the juncture between the two
                        pieces. ";
                    break;
                case 2:
                    "The doll is reminiscent of the row of huge statues
                        standing sentinel on Easter Island. This object,
                        however, is much tackier than any statue you have
                        seen. ";
                    break;
                case 3:
                    "A huge, tacky doll, roughly the size of a minor moon or
                        a major mountain. The grainy surface shimmers before
                        your tired eyes. ";
                    break;
                case 4:
                    "You stand before a vast, pitted wall that spreads in
                        almost every direction. It is made of a material
                        unknown to you. Stepping back from it, you can tell
                        that it curves very slightly as it rises into the
                        distance. ";
                    break;
            }
        }
    }
    sdesc = {
        if (Me.location == self) {    // Inside the doll
            switch (self.relsize) {
                case 1:
                    "Inside a large wooden doll";
                    break;
                case 2:
                    "Inside an enormous wooden doll";
                    break;
                case 3:
                case 4:
                case 5:
                    "Inside a doll of staggering proportions";
                    break;
            }
        }
        else {
            switch (self.relsize) {
                case -1:
                    "minute capsule"; break;
                case 0:
                    if (self.isOpen)
                        "lower section of a doll";
                    else "small wooden doll";
                    break;
                case 1:
                    "large wooden doll"; break;
                case 2:
                    "enormous wooden doll"; break;
                case 3:
                    "gigantic curved structure"; break;
                case 4:
                case 5:
                    "vast wall"; break;
            }
        }
    }
    adesc = {
        if (self.relsize == 2)
            "an <<self.sdesc>>";
        else if (self.relsize == 0 && self.isOpen)
            "the <<self.sdesc>>";
        else pass adesc;
    }
    noexit = "There is no obvious exit from the dolls. "
    enterRoom(actor) = {
        self.lookAround(true);
    }
    roomAction(a, v, d, p, i) = {}
    roomDrop(obj) = {
        "Dropped. ";
        obj.moveInto(self);
    }
    verDoLookin(actor) = {
        if (!self.contentsVisible)
            "You cannot see inside <<self.thedesc>>. ";
    }
    doLookin(actor) = {
        local list;

        list = contlist(self);
        if (length(list)>0) {
            "Inside <<self.thedesc>> you see <<listlist(list)>>. ";
        }
        else "\^<<self.thedesc>> is empty. ";
    }
    verDoTake(actor) = {
        if (self.relsize < 0)
            "It is far too delicate for your hamfisted hands. ";
        else if (self.relsize > 0)
            "It would crush you. ";
        else dolldaemon.dollComplete = nil;    // Dolls aren't done anymore
    }
    verDoOpen(actor) = {
        if (self.location != actor)
            "%You% must first be holding the doll. ";
        else if (self.isOpen)
            "The doll is already disassembled. ";
    }
    doOpen(actor) = {
        self.mylid = new dolllid;
        self.mylid.lidsize = self.dsize;
        self.mylid.changeid;
        self.mylid.moveInto(actor);
        dolldaemon.dollComplete = nil;
        "The two halves of the doll slide apart with moderate resistance. ";
        self.isOpen = true;
        addword(self, &noun, 'section');
        addword(self, &noun, 'half');
        addword(self, &adjective, 'lower');
    }
    verDoClose(actor) = {
        if (!self.isOpen)
            "The doll is already assembled. ";
        else if (self.location != actor || self.mylid.location != actor)
            "%You% must first be holding the two halves of the doll. ";
    }
    doClose(actor) = {
        delete self.mylid;
        self.mylid = nil;
        self.isOpen = nil;
        delword(self, &noun, 'section');
        delword(self, &noun, 'half');
        delword(self, &adjective, 'lower');
        if (dolldaemon.checkDolls(self.dsize))
            "The two pieces slide together effortlessly, as though
                magnetically attracted. ";
        else "After a brief struggle, you manage to force the two pieces
            together again. ";
    }
    verIoPutOn(actor) = {
        if (self.relsize > 0)
            "The doll is much too big for you to put anything on it. ";
        else if (self.relsize < 0)
            "The doll is much too small for you to put anything on it. ";
    }
    ioPutOn(actor, dobj) = {
        if (dobj != mylid)
            "There's no good surface on <<self.thedesc>>. ";
        else self.doClose(actor);
    }
    verIoPutIn(actor) = {
        if (!self.isOpen)
            "%You% can't put anything in <<self.thedesc>>. ";
        else if (self.relsize > 0)
            "The doll is much too big for you simply to put things into
                it. ";
        else if (self.relsize < 0)
            "It is much too small to hold anything. ";
    }
    ioPutIn(actor, dobj) = {
        dobj.doPutIn(actor, self);
    }
    ioThrowAt(actor, dobj) = {
        if (self.relsize == 1 && dobj.isDoll) {
            if (!self.isOpen) {
                "\^<<dobj.thedesc>> glances off the lid of <<self.thedesc>> and
                    spins, landing with a clatter at your feet. ";
                dobj.moveInto(Me.location);
                return;
            }
            if (dolldaemon.checkDolls(self.dsize - 1))
                "The air above the gaping aperture shimmers slightly
                    as <<dobj.thedesc>> passes through it.
                    \^<<dobj.thedesc>> lands inside <<self.thedesc>> with a
                    resonant and satisfying thunk. ";
            else "It lands with a hollow clack that echoes emptily. ";
            dobj.moveInto(self);
        }
        else pass ioThrowAt;
    }
    doDrop(actor) = {
        if (self.dsize == 4 && dolldaemon.checkDolls(self.dsize) &&
            dolldaemon.selfComplete) {
            "Subjective time lags.  You stare fixedly as the doll gently floats
                towards the floor.  In complete silence, the doll lands.  As it
                does, a ripple spreads out from it.  You feel the walls around
                you invert.  For an instant you contain the universe, until
                all collapses about you...\b";
            dolldaemon.dolllist[1].moveInto(nil);
            dolldaemon.endIt;
            return;
        }
        dolldaemon.dollComplete = nil;
        pass doDrop;
    }
;

class dolllid: item
    lidsize = 1      // Lid size
    relsize = { return (self.lidsize - Me.psize); } // Reverse of playerCopy
    mysdescs = [
        '', '', 'minute top', 'lid for a doll', 'upper half of a large
        doll', 'massive roof', 'mammoth dome'
               ]
    myldescs = [
        '', '', 'You can barely see it; it is conceivable that it is part of
        a doll.  Perhaps the toy of an insect?',
        'It appears to be the upper half of one of the dolls.',
        'It looks like the lid for a doll large enough to contain you.',
        'Unless you are mistaken, this is the lid for a very large hollow
         doll.',
        'This grand structure vaguely resembles the lid for a truly titanic
         doll.'
               ]
    isListed = {
        if (self.relsize > -3 && self.relsize != 3) return true;
        return nil;
    }
    notakeall = { return (self.relsize < -2 || self.relsize == 3); }
    isVisible(loc) = {
        if (self.relsize < -2 || self.relsize == 3) return nil;
        pass isVisible;
    }
    // A routine to change the words associated w/this object
    changeid = {
        // First, remove all the old nouns/adjectives
        stripwords(self);
        // Next, add the nouns
        switch (self.relsize) {
            case 2:
                addword(self, &noun, 'dome');
                addword(self, &adjective, 'mammoth');
                break;
            case 1:
                addword(self, &noun, 'roof');
                addword(self, &adjective, 'massive');
                break;
            case 0:
                addword(self, &noun, 'half');
                addword(self, &adjective, 'upper');
                break;
            case -1:
                addword(self, &noun, 'lid');
                break;
            case -2:
                addword(self, &noun, 'top');
                addword(self, &adjective, 'minute');
                break;
        }
    }
    ldesc = {
        local i;

        i = self.relsize + 5;
        if (i > length(self.myldescs)) return;
        say(self.myldescs[i]);
    }
    sdesc = {
        local i;

        i = self.relsize + 5;
        if (i > length(self.mysdescs)) return;
        say(self.mysdescs[i]);
    }
    adesc = {
        if (self.relsize == 0 || self.relsize == -1)
            "the <<self.sdesc>>";
        else pass adesc;
    }
    verDoTake(actor) = {
        if (self.relsize < -1)
            "It is far too delicate for your hamfisted hands. ";
        else if (self.relsize > -1)
            "It would crush you. ";
    }
;

// A groove for the largest doll
groove: fixeditem
    noun = 'groove'
    sdesc = "groove"
    ldesc = "It seems to suggest that the doll may be separated. "
    takedesc = "As easily take a stain from fabric. "
;

// The object which controls all of the dolls
dolldaemon: object
    playerLoc = nil       // Where the player was when (s)he opened the doll
    selflist = []
    dolllist = []
    selfComplete = nil    // True if all selves are held
    dollComplete = nil    // True if all dolls are assembled & in each other
    seenSelf = nil        // True after the player sees his identical copy
    setup = {
        local i;

        for (i = 1; i < 6; i++) {
            self.selflist += new playerCopy;
            self.dolllist += new doll;
            self.selflist[i].mysize = self.dolllist[i].dsize = 6 - i;
            self.selflist[i].moveInto(dolllist[i]);
            if (i > 2)
                self.dolllist[i].moveInto(selflist[i-1]);
        }
        moveAllCont(Me, dollCoatCheck);
        self.dolllist[2].moveInto(Me);
        self.dolllist[1].moveInto(playerLoc);  // Necessary for the largest
        self.changeid;                         // doll to be examinable
        groove.moveInto(self.dolllist[1]);
        self.playerLoc = Me.location;
        Me.travelTo(dolllist[1]);
    }
    endIt = {
        local i;

        moveAllCont(dollCoatCheck, Me);
        Me.solvedDolls = true;
        Me.travelTo(self.playerLoc);
        for (i = 5; i > 0; i--) {
            delete self.selflist[i];
            delete self.dolllist[i];
        }
        russian_doll.moveInto(nil);
        dollsAh.solve;
        incscore(5);
    }
    changeid = {
        local i, len;

        len = length(self.selflist);    // Should be 1 self for every doll
        for (i = 1; i <= len; i++) {
            self.selflist[i].changeid;
            self.dolllist[i].changeid;
        }
    }
    checkSelves = {
        local i;

        for (i = 3; i <= 5; i++) { // We're picking up doll 2
            if (self.selflist[i].location != self.selflist[i-1])
                return nil;
        }
        self.selfComplete = true;
        return true;
    }
    checkDolls(size) = {
        local i, list, len, j;

        for (i = 6 - size; i <= 5; i++) {
            list = self.dolllist[i].contents;
            len = length(list);
            for (j = 1; j <= len; j++)
                if (!list[j].isDoll)
                    return nil;
            if (i == 6 - size) continue;  // No need to check 1st doll's loc
            if ((self.dolllist[i].location != self.dolllist[i-1]) ||
                self.dolllist[i].isOpen)
                return nil;
        }
        if (size == 4)
            self.dollComplete = true;
        return true;
    }
    searchForSize(size) = {
        local i, len;

        len = length(self.selflist);
        for (i = 1; i <= len; i++)
            if (self.selflist[i].relsize == size)
                return self.selflist[i];
        return nil;
    }
    queryBigBrother = { return self.searchForSize(-1); }
    queryBrother = { return self.searchForSize(0); }
    queryLittleBrother = { return self.searchForSize(1); }
    canStareDown = {
        local bro;

        if ((bro = self.queryLittleBrother) != nil)
            return (bro.isVisible(Me.location));
        return nil;
    }
    canStareUp = {
        local bro;

        if ((bro = self.queryBigBrother) != nil)
            return (bro.isVisible(Me.location) || Me.location.isOpen);
        return nil;
    }
;

compoundWord 'up' 'in' 'upin';
compoundWord 'down' 'into' 'downinto';
compoundWord 'up' 'into' 'upinto';

modify inPrep
    preposition = 'downinto' 'upin' 'upinto'
;

stareVerb: deepverb
    verb = 'stare' 'stare at' 'stare in' 'stare into' 'gaze in' 'gaze into'
    sdesc = "stare"
    isGripVerb = true
    doAction = 'Stare'
    action(actor) = {
        if (actor.location.isInDoll) {
            if (Me.psize < 5 || dolldaemon.dolllist[2].isOpen) {
                "You can only stare ";
                if (dolldaemon.canStareDown) {
                    "down into the eyes of your smaller incarnation";
                    if (Me.psize < 5) " and ";
                    else { ". "; return; }
                }
                if (dolldaemon.canStareUp)
                    "up into the eyes of your larger incarnation. ";
                return;
            }
        }
        "There is no need for you to stare at anything right now. ";
    }
;

stareupVerb: deepverb
    verb = 'stare up' 'stare out' 'stare upinto' 'stare upin' 'look upin' 'look upinto'
    sdesc = "stare up"
    isGripVerb = true
    alreadyStared = nil
    doAction = 'Stareup'
    action(actor) = {
        local bigbro, bro;

        if (!dolldaemon.canStareUp) {
            stareVerb.action(actor);
            return;
        }
        if (Me.psize == 5) {
            stareVerb.action(actor);
            return;
        }
        bigbro = dolldaemon.queryBigBrother;
        bro = dolldaemon.queryBrother;
        if (!self.alreadyStared) {
            "You slowly lift your head towards the massive, staring eyes above
                you and lock gazes.  Your peripheral vision gradually dissolves
                until all you see is a pair of eyes staring back at you.  You
                feel your consciousness fracture for a moment, during which you
                see through both pairs of eyes.  You watch yourself watching
                yourself watching yourself...until, just before you are lost,
                you blink and find yourself having swapped with
                the larger you.\b";
            self.alreadyStared = true;
        }
        else "Any thoughts you have of the transition becoming easier are lost
            as you feel yourself pulled into the larger you.\b";
        moveAllCont(actor, bro);
        moveAllCont(bigbro, actor);
        Me.psize++;
        dolldaemon.changeid;
        actor.travelTo(bigbro.location);
    }
;

staredownVerb: deepverb
    verb = 'stare down' 'stare downinto' 'stare downin' 'look downin' 'look downinto'
    sdesc = "stare down"
    isGripVerb = true
    alreadyStared = nil
    doAction = 'Staredown'
    action(actor) = {
        local littlebro, bro;

        if (!dolldaemon.canStareDown) {
            stareVerb.action(actor);
            return;
        }
        littlebro = dolldaemon.queryLittleBrother;
        bro = dolldaemon.queryBrother;
        if (!self.alreadyStared) {
            "You lower your head and stare deeply into the eyes of your smaller
                self.  Your eyes lock together with perfect complimentarity.
                Your peripheral vision gradually dissolves until all you see is a
                pair of eyes staring back at you.  You feel your consciousness
                fracture for a moment, during which you see through both pairs of
                eyes.  You watch yourself watching yourself watching
                yourself...until, just before you are lost,
                you blink and find yourself having swapped with the smaller
                you.\b";
            self.alreadyStared = true;
        }
        else "Again you stare down, feeling your sense of self slip away,
            feeling it returning in a rush, leaving you disoriented.\b";
        moveAllCont(actor, bro);
        moveAllCont(littlebro, actor);
        Me.psize--;
        dolldaemon.changeid;
        actor.travelTo(littlebro.location);
    }
;

// Put a flag in the verbs which may be used while the player is being held
modify inspectVerb
    isGripVerb = true;
modify askVerb
    isGripVerb = true;
modify tellVerb
    isGripVerb = true;
modify lookInVerb
    isGripVerb = true;
modify lookVerb
    isGripVerb = true;
modify againVerb
    isGripVerb = true;
modify waitVerb
    isGripVerb = true;
modify iVerb
    isGripVerb = true;
modify sayVerb
    isGripVerb = true;
modify yellVerb
    isGripVerb = true;
modify sleepVerb
    isGripVerb = true;
modify smellVerb
    isGripVerb = true;
modify listenVerb
    isGripVerb = true;
modify listentoVerb
    isGripVerb = true;
modify sysverb
    isGripVerb = true;

// A place to store the player's possessions while he/she is in the dolls
dollCoatCheck: room;

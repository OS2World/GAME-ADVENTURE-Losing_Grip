/* Copyright (c) 1989, 1991 by Michael J. Roberts.  All Rights Reserved. */
// Modified by Stephen Granade for Losing Your Grip
// $Id: gripstd.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $

#include "sysfuncs.t"
#pragma C+

/*
 *   Pre-declare all functions, so the compiler knows they are functions.
 *   (This is only really necessary when a function will be referenced
 *   as a daemon or fuse before it is defined; however, it doesn't hurt
 *   anything to pre-declare all of them.)
 */
die: function;
scoreRank: function;
init: function;
terminate: function;
pardon: function;
darkTravel: function;
ladyLuck: function;


/*
 *   The die() function is called when the player dies.  It tells the
 *   player how well he has done (with his score), and asks if he'd
 *   like to start over (the alternative being quitting the game).
 */
die: function
{
    "\b--=== Your journey is over ===--\b";
    scoreRank();
    "\bYou may restore a saved game, start over, quit, or undo
    the current command.\n";
    while ( 1 )
    {
        local resp;

    "\nPlease enter (R)ESTORE, RE(S)TART, (Q)UIT, or (U)NDO: >";
        resp = upper(input());
        if ( resp == 'RESTORE' || resp == 'R' )
    {
        resp = askfile( 'File to restore' );
        if ( resp == nil ) "Restore failed. ";
        else if ( restore( resp )) "Restore failed. ";
        else
        {
            Me.location.lookAround(true);
            setscore( global.score, global.turnsofar );
            abort;
        }
    }
        else if ( resp == 'RESTART' || resp == 'S' )
    {
        setscore( 0, 0 );
            restart();
    }
    else if ( resp == 'QUIT' || resp == 'Q' )
        {
        terminate();
            quit();
        abort;
        }
    else if (resp == 'UNDO' || resp == 'U')
    {
        if (undo())
        {
        "(Undoing one command)\b";
        Me.location.lookAround(true);
            setscore(global.score, global.turnsofar);
        abort;
        }
        else
        "Sorry, no undo information is available. ";
    }
    }
}

/*
 *   The scoreRank() function displays how well the player is doing.
 *   This default definition doesn't do anything aside from displaying
 *   the current and maximum scores.  Some game designers like to
 *   provide a ranking that goes with various scores ("Novice Adventurer,"
 *   "Expert," and so forth); this is the place to do so if desired.
 *
 *   Note that "global.maxscore" defines the maximum number of points
 *   possible in the game; change the property in the "global" object
 *   if necessary.
 */
scoreRank: function
{
    "You have achieved a score of <<global.score>> points out of a
        possible <<global.maxscore>>. ";
}

// Grip initialization
gripinit: initialization
    preinit_phase = {
         initSearch();
         countHints();
         numberHints();
    }
;

/*
 *   The init() function is run at the very beginning of the game.
 *   It should display the introductory text for the game, start
 *   any needed daemons and fuses, and move the player's actor ("Me")
 *   to the initial room, which defaults here to "startroom".
 *   Note that it is now gameinit()--see sysfuncs.t for details.
 */
replace gameinit: function
{
    local fnum, s, k, n1, n2, kprime;
    
    fnum = fopen('regkey.txt', 'r');
    if (fnum != nil) {
        s = fread(fnum);
        if (s == 'Losing Your Grip') {
            s = fread(fnum);
            n1 = fread(fnum);
            k = upper(fread(fnum));
            n2 = fread(fnum);
            kprime = upper(keyObj.encode(s));
            if (kprime == k && n1 == keyObj.ennumber(s) &&
                n2 == keyObj.ennumber(k)) {
                global.registered = true;
                global.registeredTo = s;
            }
        }
        fclose(fnum);
    }
    if (restore(nil) == nil) {
        "\b[Restoring saved game]\b";
        scoreStatus(global.score, global.turnsofar);
        Me.location.lookAround(true);
        return;
    }
    clearscreen();
    if (!global.restarting) {  // Only print this the first time around
    "\b\bRain and mud.\b
        Those are your first solid memories. Rain pouring down on your head,
        filling your eyes. Mud beneath your feet, filling your shoes. Other
        details slowly filter in. The trees surrounding you. The leaden skies
        above. The chill wind cutting through your clothes with ease.\b
        Shelter would be a good beginning.\b";

    version.sdesc;                // display the game's name and version number
    }

    "\b\(Fit the First\):\ Replevin\b\b";    // Used to be "Recovery"
    makeQuote('"Rain rain on my face/It hasn\'t stopped raining for days"',
        'Jars of Clay');

    incscore(0);
    Me.location = startroom;                // move player to initial location
    startroom.lookAround( true );           // show player where he is
    startroom.isseen = true;                // note that we've seen the room
    setfuse(&ladyLuck, 1, nil);             // In one turn, randomize
    beginningAh.see;
}

/*
 *   Unless the global.noRand variable is true, this function randomizes
 *   the game.
 */
ladyLuck: function(dummy)
{
    if (!global.noRand)
        randomize();
}

/*
 *   The terminate() function is called just before the game ends.  It
 *   generally displays a good-bye message.  The default version does
 *   nothing.  Note that this function is called only when the game is
 *   about to exit, NOT after dying, before a restart, or anywhere else.
 */
terminate: function
{
    "Thank you for playing \(Losing Your Grip\). ";
}

/*
 *   The pardon() function is called any time the player enters a blank
 *   line.  The function generally just prints a message ("Speak up" or
 *   some such).  This default version just says "I beg your pardon?"
 */
pardon: function
{
    "Lost in thought, you do nothing. ";
}

/*
 *   The numObj object is used to convey a number to the game whenever
 *   the player uses a number in his command.  For example, "turn dial
 *   to 621" results in an indirect object of numObj, with its "value"
 *   property set to 621.
 */
numObj: basicNumObj
;

/*
 *   strObj works like numObj, but for strings.  So, a player command of
 *     type "hello" on the keyboard
 *   will result in a direct object of strObj, with its "value" property
 *   set to the string 'hello'.
 *
 *   Note that, because a string direct object is used in the save, restore,
 *   and script commands, this object must handle those commands.
 */
strObj: basicStrObj     // use default definition from adv.t
    flyingPoints = nil
    verDoCutIn(actor, io) = {}
    doSay(actor) = {
        local val = lower(value);

        setit(nil);
        if (Me.location == light_hall && faerie_guards.hush == true) {
            faerie_guards.spokenTo;
            return;
        }
        if (val == 'yes') {
            yesVerb.action(actor);
            return;
        }
        if (val == 'no') {
            noVerb.action(actor);
            return;
        }
        if (val == 'maybe' || val == 'neither') {
            maybeVerb.action(actor);
            return;
        }
        if (proptype(argument_daemon, &paused) == 13) {
            switch (argument_daemon.paused) {
                case &question1a:
                    if (val == 'dog' || val == 'dogs')
                        yesVerb.action(actor);
                    else if (val == 'cat' || val == 'cats')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
                case &question1b:
                    if (val == 'music')
                        yesVerb.action(actor);
                    else if (val == 'math')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
                case &question2a:
                    if (val == 'introvert')
                        yesVerb.action(actor);
                    else if (val == 'extrovert')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
                case &question2b:
                    if (val == 'enthusiasm')
                        yesVerb.action(actor);
                    else if (val == 'caution')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
                case &question3a:
                    if (val == 'feeling' || val == 'feelings')
                        yesVerb.action(actor);
                    else if (val == 'logic')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
                case &question3b:
                    if (val == 'knowledge')
                        yesVerb.action(actor);
                    else if (val == 'intuition')
                        noVerb.action(actor);
                    else maybeVerb.action(actor);
                    return;
            }
        }
        if ((val == 'i\'m off' || val == 'i\'m off!') &&
            white_hat.isworn) {
            "The hat on your head quivers, as if to take flight, then settles
                back on your head. ";
            return;
        }
        if ((val == 'i\'m after' || val == 'i\'m after!')
            && white_hat.isworn) {
            if (isclass(Me.location, caveRm)) {
                "You rise a bit into the air, then fall back. ";
                return;
            }
            "As the words leave your lips you fly up into the air. Within
                seconds you are far above the ground, the countryside
                surrounding your house spreading out around you.\b
                After a few moments of drifting you hurtle towards the ground.
                As it rushes up to meet you, a tiny crack opens in the top
                of a hill. You zip through the crack and are deposited on the
                floor of a cave. Behind you, the crack seals. ";
            Me.moveInto(faerie_cave);
            unnotify(backyard_faeries, &daemon);
            followFaeriesAh.solve;
            if (!self.flyingPoints) {
                self.flyingPoints = true;
                incscore(5);
            }
        }
        else pass doSay;
    }
;

/*
 *   The "global" object is the dumping ground for any data items that
 *   don't fit very well into any other objects.  The properties of this
 *   object that are particularly important to the objects and functions
 *   are defined here; if you replace this object, but keep other parts
 *   of this file, be sure to include the properties defined here.
 *
 *   Note that awakeTime is set to zero; if you wish the player to start
 *   out tired, just move it up around the sleepTime value (which specifies
 *   the interval between sleeping).  The same goes for lastMealTime; move
 *   it up to around eatTime if you want the player to start out hungry.
 *   With both of these values, the player only starts getting warnings
 *   when the elapsed time (awakeTime, lastMealTime) reaches the interval
 *   (sleepTime, eatTime); the player isn't actually required to eat or
 *   sleep until several warnings have been issued.  Look at the eatDaemon
 *   and sleepDaemon functions for details of the timing.
 */
global: object
    turnsofar = 0                      // no turns have transpired so far
    score = 0                          // no points have been accumulated yet
    maxscore = 100                     // maximum possible score
    verbose = true                     // we are currently in VERBOSE mode
    lamplist = []     // list of all known light providers in the game
    noRand = nil                       // seed the random # generator
    disambiguating = nil               // True when disambiguating objects
    registered = nil                   // Are we registered?
    registeredTo = ''                  // Who has registered us?
;

/*
 *   The "version" object defines, via its "sdesc" property, the name and
 *   version number of the game.  Change this to a suitable name for your
 *   game.
 */
version: object
    compile_time = __DATE__       // Holds when this version was compiled
    sdesc = {
      "\b\(Losing Your Grip\), a Journey in Five Fits\n
        Version 5 (<<self.compile_time>>) Copyright 1997-2001 by Stephen
        Granade\n
        Developed with TADS, the Text Adventure Development System.\n";
      if (global.registered)
          "Registered to <<global.registeredTo>>.\n";
      "For more information, type \"about\".\b";
    }
;

/*
 *   "Me" is the player's actor.  Pick up the default definition, basicMe,
 *   from "adv.t".
 */
Me: basicMe
    ldesc = "What you can see of yourself is familiar. "
    stage = 1             // What stage of the journey the player is in
    stumbleTurns = 0      // How long have I stumbled in the rain?
    coldTurns = 0         // Number of turns the player has been in the snow
    ctrlPoints = 0        // Control points. + is good, - is bad
    smellMasked = nil     // Is the player's smell masked?
    maxweight = 100       // Maxweight & bulk give a scale of 100 i.e. a
    maxbulk = 100         //  %age of what the player can completely carry
    doingCPR = nil        // Am I performing CPR?
    inRain = nil          // Have I seen the rain @ the beach? (see eggs.t)
    psize = 5             // Player size for the dolls
    memory = 0            // + values mean more memory, - values mean less
    frankiedesc = "Frankie shrugs. \"I'd never seen you before you walked down
        the stairs.\" "
    greymandesc = "\"Oh, yes, the all-important Terry.\" The grey man turns
        away. \"There is no better subject.\" "
    drunk = nil           // Have I gotten drunk yet?
    solvedDolls = nil     // Have I solved the russian dolls yet?
    relaxed = nil         // Have we relaxed our hands (or opened them)?
    tenseUp = {           // Reset the relaxed flag
        self.relaxed = nil;
    }
;

/*
 *   darkTravel() is called whenever the player attempts to move from a dark
 *   location into another dark location.  By default, it just says "You
 *   stumble around in the dark," but it could certainly cast the player into
 *   the jaws of a grue, whatever that is...
 */
darkTravel: function {}

goToSleep: function {}

replace scoreStatus:function(points, turns)
{
    setscore('Points: '+cvtstr(points));
}

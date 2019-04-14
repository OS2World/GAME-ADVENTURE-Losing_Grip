/*
    Losing Your Grip, a Journey in Five Fits
    Copyright (c) 1998 by Stephen Granade.  All Rights Reserved.

    Developed using TADS: The Text Adventure Development System

    Programming Begun: 23 Aug 96

    $Id: grip.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#include        "oldadv.t"      // Standard stuff
#include        "gripstd.t"     // Nonstandard stuff
#include        "bugs.t"        // Bug fixes
#include        "consist.t"     // #defines for consistency
#include        "actor.t"       // Better actor class
#include        "adhint.t"      // Adaptive hints
#include        "debug.t"       // Debugging commands
#include        "answerme.t"    // Allow asking Y/N questions
#include        "clothing.t"    // Better clothing
#include        "detect.t"      // Detect save/restore/undo in some places
#include        "plurals.t"     // Handle plural items
#include        "sack.t"        // Sack of holding
#include        "senses.t"      // Smell/hearing
#include        "wallpap.t"     // Wallpaper
#include        "misc.t"        // Misc. items
#include        "askabout.t"    // "ask about" fix
#include        "griph.t"       // New verbs, etc.

#include        "keygrip.t"     // Registration key functions
#include        "messages.t"    // Terry's link to the outside world
#include        "eggs.t"        // Easter eggs
#include        "radio.t"       // The mind's radio station
#include        "greyman.t"     // The grey man of Terry's nightmares
#include        "griphint.t"    // The hints for _Losing Your Grip_
#include        "recovery.t"    // Part 1: Recovery
#include        "dog.t"         // Man's loyal companion
#include        "intlude.t"     // Interludes
#include        "hospital.t"    // Part 2a: Hospital
#include        "woman.t"       // The woman with Alzheimer's
#include        "school.t"      // Part 2b: School
#include        "buddy.t"       // Little Buddy
#include        "home.t"        // Part 3: Home
#include        "argument.t"    // Part 4: Argument
#include        "reason.t"      // Part 4a: Reason
#include        "cube.t"
#include        "feeling.t"     // Part 4b: Feeling
#include        "dolls.t"
#include        "finale.t"      // Part 5: Finale

#include        "griptest.t"    // Testing verbs
#include        "notify.t"      // Notify of an increase in score

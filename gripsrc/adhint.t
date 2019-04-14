/* This program is Copyright (c) 1994 David Allen.  It may be freely
   distributed as long as you leave my name and copyright notice on it.
   I'd really like your comments and feedback; send e-mail to
   allen@viewlogic.com, or send us-mail to David Allen, 10 O'Moore Ave,
   Maynard, MA 01754. */
/* Changes/additions to this file have been made by Stephen Granade, and all
   such changes are documented with comments ending in my initials.  The
   copyright still belongs to David Allen; I release any rights I might have
   to him.  I, too, would appreciate comments at sgranade@phy.duke.edu. */
/* More changes have been made, suggested by Andrew Pontious.  They are:
   - A way of aborting out of the "Which hint do you want?" prompt.  Now
     entering a non-valid number drops you back to the game.
   - A hint list count has been added before each hint.  Note that this
     feature requires more work on the part of the author, although some of
     the work can be done by preinit.
   These changes were made 15 Aug 96 by Stephen Granade. */
/* _More_ changes:
   - Before every hint, the topic is printed, in case the player doesn't
     want that hint.
   These changes were made 22 Nov 96 by Stephen Granade. */
/* Another change: hintVerb is now a sysverb.
   This change was made 21 Nov 98 by Stephen Granade. */


/* This is an "adaptive hint" system.  This file contains the general code
   needed for a hint system which looks at the game state to find the best
   hint to give.  See the file "adhint.doc" for more detailed information. */

#ifndef ADHINT
#define ADHINT

#include "version.t"

#pragma C-

// versionTag added by SG, from Jeff Laing's routines
adhintVersion : versionTag
    id = "$Id: adhint.t,v 1.2 1997/01/24 00:34:40 sgranade Exp $\n"
    author = 'David Allen and Stephen Granade'
    func = 'adaptive hint system'
;

/* Puzzle, hint and clue classes */


/* The puzzle is the most important object.  Calls in the main code can mark
   a puzzle as seen (to begin its life) or as solved (to end its life).
   Before a puzzle's life begins, all of the puzzles listed in its "prereqs"
   list must be solved.  During its life, a request for hints may offer a
   hint on the puzzle.  If this puzzle might be "solvable" when other
   puzzles are also solvable, the function ahPromptHint, below, asks the
   user to select the puzzle for hinting; the puzzle object must define a
   method called title to print the name of the puzzle. */
/* For the new version of the "review" verb, a title MUST be defined for all
   puzzles.  The variable reviewflag is used for the "review" verb, and is
   further explained below.
   Also, if the countHints function is not used (see below), totalNumHints
   must be set.  totalNumHints holds the number of hints available for
   this puzzle. SG */
class ahPuzzle: object
   solved = nil seen = nil prereqs = [] reviewflag = nil
   totalNumHints = -1
   solve = {
      /* Remove comment on next line for debugging messages
      if (not self.solved) "(You have solved the <<self.ahDesc>> puzzle)\n";
      */
      self.solved := true; }
   see = {
      /* Remove comment on next line for debugging messages
      if (not self.seen) "(You are aware of the <<self.ahDesc>> puzzle)\n";
      */
      self.seen := true; }
   /* Normally, a puzzle becomes solvable for hinting when all of its
      prerequisites are solved, that is, an AND relationship. */
   ahAvail = {
      local len := length (self.prereqs), i;
      if (len > 0) for (i:=1; i<=len; i++)
         if (not (self.prereqs[i].solved)) return (nil);
      return (true); };


/* The "clue" object is used to remember whether a particular event has
   occurred.  For example, when an object is seen, or when a particular
   mistake is made. */
class ahClue: object
   seen = nil
   see = {
      /* Remove comment on next line for debugging messages
      if (not self.seen) "(You see the <<self.ahDesc>> clue)\n";
      */
      self.seen := true; };


/* The "hint" object is the actual text of a hint.  It must have an owner
   set to the puzzle for which it is a hint.  If some condition besides
   having the puzzle "solvable" must be satisfied before the hint is given,
   the ahAvail function must be used to return true if the hint is available
   and nil otherwise.  Finally, the "ahTell" method must be defined; it must
   print the text of the hint. */
/* iHintNum is set for compatibility with the new class ahHintList.  ahGive
   has been altered so that it sets its owner puzzle's reviewflag.
   baseHintNum is the number of the hint.  ahGive now prints (x/y)
   before each hint, where x is the hint's number (baseHintNum) and y is
   the total number of hints possible for the puzzle (totalNumHints
   in ahPuzzle).  SG */
class ahHint: object
   seen = nil owner = nil iHintNum = 1
   baseHintNum = -1
   ahAvail = { return (true); }
   ahGive = { self.seen := true; self.iHintNum++; owner.reviewflag := true;
              "(<<self.baseHintNum>>/<<self.owner.totalNumHints>>) ";
              self.ahTell; };


/* The "hintlist" object is actually a combination of several hints which are
   designed to be given in a particular order, preventing the necessity of
   having several separate hint objects.  ahTell should be set to an array
   of hints.  baseHintNum should be set to the number of the first hint
   in the list; ahGive takes care of the rest.  Note that this assumes that
   all hints in the list are given in sequential order, as they should
   be. SG */
class ahHintList: ahHint
   ahTell = []
   ahGive = {
      owner.reviewflag := true;
      "(<<self.baseHintNum + self.iHintNum - 1>>/<<self.owner.totalNumHints>>)
         <<self.ahTell[self.iHintNum]>>\n";
      self.iHintNum++;
      if (self.iHintNum > length(self.ahTell))
         self.seen := true;
   }
;


/* Hint verb and auxilliary functions */


/* A function to list all the titles of a list of puzzles, then input a
   selection.  It returns the chosen selection.  Note that entering an
   invalid selection aborts the command.  SG */
ahListTitles: function (puzzles) {
   local i, len := length(puzzles);
   for (i := 1; i <= len; i++) {
      if (i < 10) "\ ";
      "<<i>>.\ \ <<puzzles[i].title>>\n"; }
   "=>\ "; i := cvtnum(input());
   if ((i < 1) or (i > len)) abort;
   return (i);
}


/* Called from several places, this function prints a random hint related
   to the puzzle passed in to it.  Because the puzzle was selected, there
   must be at least one available hint which hasn't been given yet. */
ahGiveHint: function (puzzle) {
   local h, hints:=[];
   for (h:=firstobj (ahHint); h<>nil; h:=nextobj(h,ahHint))
      if ((h.owner = puzzle) and (not h.seen) and (h.ahAvail))
         hints += h;
   hints [rand (length (hints))].ahGive; }


/* Called from the hint verb, below, when there is more than one puzzle
   "solvable", this function prompts the user to choose one of the
   solvable puzzles.  The title method of the puzzle object is used to
   display the name of the puzzle so the user can select.  The function
   simply exits without displaying a hint if an out of range selection
   is made from the numbered list. */
/* This function has been simplified with the addition of the ahListTitles
   function.  SG */
ahPromptHint: function (puzzles) {
   "For which puzzle would you like a hint?\n";
   ahGiveHint (puzzles[ahListTitles(puzzles)]); }


/* This is the verb that makes it all happen.  The action routine checks to
   see how many puzzles are solvable.  If none, it prints a message to that
   effect.  If there are solvable puzzles, but none have available clues,
   it prints a message to that effect.  If there is one puzzle with available
   clues, it prints one.  If multiple puzzles have available hints, it builds
   a list for the player to choose from. */
hintVerb: sysverb verb = 'hint' sdesc = "hint" issysverb = true
   firstever = true
   action (actor) = {
      local len, o, p:=[], h, i, somesolvable := nil;

      if (self.firstever) {
         "\([Two numbers are printed before each hint, (x/y). x is the number
             of the current hint; y is the total number of hints available
             for this puzzle. You can use the \"review\" command to see
             hints you have already gotten.]\)\b";
         self.firstever := nil; }

      /* Add puzzle o to list p if solvable and has hints available */
      for (o:=firstobj (ahPuzzle); o<>nil; o:=nextobj(o,ahPuzzle))
         if ((not o.solved) and (o.seen) and (o.ahAvail)) {
            somesolvable := true;
            for (h:=firstobj (ahHint); h<>nil; h:=nextobj(h,ahHint))
               if ((h.owner = o) and (not h.seen) and (h.ahAvail)) {
                  p += o; break; } }

      /* If no puzzles or all used, say so; if one or more, ask for a topic
         (to give the player a last chance to abort) */
      len := length (p);
      if (len = 0) {
         if (not somesolvable) "There are no puzzles requiring hints available
             right now. ";
         else "You have used all the hints which are available right now. "; }
//      else if (len = 1) ahGiveHint (p[1]);
      else ahPromptHint (p);

      /* Using this command does not count as a turn */
      abort; };


/* The "review" verb lets a player look back at the hints already received. */
/* This verb no longer prints out all the hints given; instead, it prompts the
   player for a particular puzzle.  If a puzzle's reviewflag has been set,
   then a hint to that puzzle has been given, and it can be included in the
   review list.  Also, the list of hints is now numbered. SG */
reviewVerb: deepverb verb = 'review' sdesc = "review" issysverb = true
   action (actor) = {
      local h, puzzles := [], final_puzzle, i, j;
      for (h:=firstobj (ahPuzzle); h<>nil; h:=nextobj (h, ahPuzzle))
         if (h.reviewflag) puzzles += h;
      if (length(puzzles) = 0) {
         "You have not received any hints yet."; abort;
      }
      "For which puzzle do you want to review the hints you've received?\n";
      final_puzzle := puzzles[ahListTitles(puzzles)];
      "\b\nYou have received the following hints for that puzzle:\n\b\n";
      j := 1;        // A hint counter
      for (h:=firstobj (ahHint); h<>nil; h:=nextobj (h, ahHint))
         if (h.iHintNum > 1 and h.owner = final_puzzle) {
            if (isclass(h, ahHintList) and h.iHintNum > 1) {
               for (i := 1; i < h.iHintNum; i++) {
                  "<<j++>>.\ <<h.ahTell[i]>>\n";
               }
            }
            else if (h.seen) { "<<j++>>.\ <<h.ahTell>>\n"; }
         }
      abort; };


/* Auxilliary function for scoring: display the number of hints used */
ahScoreRank: function (x) {
   local count := 0, h;
   for (h:=firstobj (ahHint); h<>nil; h:=nextobj (h, ahHint)) {
      count += h.iHintNum - 1;
   }
   if (count = 1) "You have used one hint to achieve this score. ";
   if (count > 1) "You have used <<count>> hints to achieve this score. "; }

/* countHints will scan through all ahHint objects and increment the hint's
   owner's totalNumHints.  This keeps you from having to do it yourself.
   If you set a puzzle's totalNumHints by hand, this routine will not change
   it.  Place a call to this function in your preinit() function.  SG */
countHints: function
{
   local o, i, puzzles = [];

   for (o := firstobj(ahPuzzle); o <> nil; o := nextobj(o, ahPuzzle)) {
      if (o.totalNumHints <> -1) continue; // Don't change an already-set
      puzzles += o;                              //  number of hints
      o.totalNumHints := 0;
   }
   for (o := firstobj(ahHint); o <> nil; o := nextobj(o, ahHint)) {
      i := find(puzzles, o.owner);
      if (i = nil) continue;
      if (isclass(o, ahHintList))
         o.owner.totalNumHints += length(o.ahTell);
      else o.owner.totalNumHints++;
   }
}

/* numberHints will scan through all ahHint objects and number them in nominal
   order.  This seems to work if the hints are defined in order, though I
   don't promise anything.  Caveat emptor.  Try it, and if it doesn't work,
   simply set all the hints' baseHintNums by hand.  If a hint's
   baseHintNums is already set, this routine will not change it.  Like
   countHints, it should be called from your preinit() function. SG */
numberHints: function
{
   local o, puzzles := [], numhintobjs := [], i, len;

   for (o := firstobj(ahPuzzle); o <> nil; o := nextobj(o, ahPuzzle))
      puzzles += o;
   len := length(puzzles);
   for (i := 1; i <= len; i++)
      numhintobjs += 1;

   // This next part is rather sloppy, but since this is all done in preinit(),
   // processing time is not crucial
   for (o := firstobj(ahHint); o <> nil; o := nextobj(o, ahHint)) {
      if (o.baseHintNum <> -1) continue;
      i := find(puzzles, o.owner);
      if (i = nil) continue;
      o.baseHintNum := numhintobjs[i];
      if (isclass(o, ahHintList))
         numhintobjs[i] += length(o.ahTell);
      else numhintobjs[i]++;
   }
}

#endif

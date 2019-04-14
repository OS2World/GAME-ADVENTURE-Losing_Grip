#ifndef ANSWERME
#define ANSWERME

/*
 --===ORIGINAL HEADER===--
 ==============================================================================
 =  ANSWERME.T                                                                =
 =                                                                            =
 =  Author:  Scott Steinfath                                                  =
 =                                                                            =
 =  Purpose: Code to allow answers to questions asked by the game itself.     =
 =           It also disallows the specialized response after 1 turn, which   =
 =           in this case it displays a default message.                      =
 =                                                                            =
 =  Creation Date:   January 25th, 1994                                       =
 =                                                                            =
 =  Modification History:                                                     =
 =                                                                            =
 =           None                                                             =
 =                                                                            =
 =  NOTE: If you have any questions or comments regarding this "feature",     =
 =        drop me E-MAIL on High Energy BBS, or America Online; screen name   =
 =        "ELFVAPOUR".                                                        =
 ==============================================================================
 --===END HEADER===--
*/

//--===ORIGINAL EXAMPLE, modified for the new constructs===--
/*
   ============================================================================
   = Example code for your "doMethod" processing                              =
   ============================================================================

   doAttack( actor ) =
   {
      if ( self = dragon )          // Player is trying to attack a dragon
      {
         "What are you, crazy?";    // Pose the question to the player

/*
         Call "qDaemon.questionAsked" to tell it we asked a question.
         questionAsked takes three parameters:
             * the desired "yes" response
             * the desired "no" response
             * the desired "maybe" response

         qDaemon.questionAsked('That\'s what I thought',
             'Well, you *ARE* crazy for trying to attack a dragon!',
             'I can tell your (sp) a very decisive person.')
      }
      else
         "You can't attack that!";  // Give default response for anything
   }                                // else
*/


/*
** A few changes have been made by Stephen Granade, including giving credit
** using Jeff Laing's version routine.  The main change is that I encapsulated
** everything into a qDaemon, which will take care of everything for you.
** All such changes are indicated by SG.
**
** Version history:
**   1.0  15 Aug 96  Initial SG release
**   1.1  21 Oct 96  Changed yesverb->yesVerb, &c. to comply w/adv.t standard
*/

#include "version.t"

#pragma C+

// versionTag added by SG, from Jeff Laing's routines
answerMeVersion : versionTag
    id = "$Id: answerme.t,v 1.1 1997/01/24 00:35:00 sgranade Exp $\n"
    author = 'Scott Steinfath'
    func = 'yes/no question handling'
;

// New creation: the qDaemon, added by SG
qDaemon: object
    yes = ''
    no = ''
    maybe = ''
    // questionAsked, given a response for yes (y), no (n), and maybe (m),
    //  will set up what's needed, as well as only allow the responses to be
    //  given the turn immediately after the question is asked.
    questionAsked(y, n, m) = {
        self.yes = y;
        self.no = n;
        self.maybe = m;
        notify(self, &clearResponse, 1);  // Clear the response in one turn
    }                                     //  (not counting this one)
    // clearResponse clears out the yes, no, and maybe responses after one turn
    clearResponse = {
        self.yes = self.no = self.maybe = '';
    }
;

/*
   ============================================================================
   = Insert this code into your "yes" verb in "adv.t"                         =
   ============================================================================
*/
yesVerb: sysverb
    verb = 'yes'
    action( actor ) = {

// See if there's a response waiting for us in qDaemon
        if (qDaemon.yes != '')
            say(qDaemon.yes);
        else
            "%You% sound%s% rather positive. ";
    }
;

/*
   ============================================================================
   = Insert this code into your "no" verb in "adv.t"                          =
   ============================================================================
*/
noVerb: sysverb
    verb = 'no'
    action( actor ) = {

// Again, see if a response awaits us in qDaemon
        if (qDaemon.no != '')
            say(qDaemon.no);
        else
            "%You% sound%s% rather negative. ";
    }
;


/*
   ============================================================================
   = Insert this code into your "maybe" verb in "adv.t"                       =
   ============================================================================
*/
maybeVerb: sysverb
   verb = 'maybe'
   action( actor ) = {

// Once more, with feeling!
        if (qDaemon.maybe != '')
            say(qDaemon.maybe);
        else
            "%You% sound%s% rather indecisive. ";
    }
;

#endif

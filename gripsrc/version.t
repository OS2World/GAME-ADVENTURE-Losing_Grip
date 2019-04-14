/* ex:set ts=4 sw=4:
 *
 * version.t: Keep track of file versions
 *
 * This module is useful for multi-file TADS games which are maintained
 * with RCS or some other version control system that will update key-text
 * items within the source files themselves at checkin time.
 *
 * The verb 'credits' will scan through the versionTag objects looking for
 * 'author' and 'func' methods.  If it finds them, it will stash their values
 * away and will print a nice summary at the end.
 *
 * The verb 'sources' will dump out every 'versionTag.id' that it
 * finds in the game object space.
 *
 * This module is Copyright (c) 1994 Jeff Laing.  Permission to use any or all
 * of this code in other TADS games is granted provided credit is given in
 * your "CREDITS" command for this code (either use the one supplied here
 * or override it but maintain its creditsVerb.action() output) and that you
 * leave this copyright message in the source whenever distributed.  Please
 * make all changes in a backward compatible manner (where possible) and make
 * them available for free (like I did ;-)
 *
 * A minor bug in creditsVerb.credit_list() which prevented the function from
 * counting the number of modules correctly has been fixed by Stephen Granade.
 * All such changes are marked with my initials, SRG.
 *
 * Changes:
 * 1.10 SRG initial release
 * 1.11 credit_list() bug fixed (4 Mar 97)
 */
#ifndef VERSION
#define VERSION

#pragma C-

class versionTag: object ;

// Every file you create should get one of these.  The object name must be
// unique to keep TADS happy and the class should be 'versionTag' so that I
// can loop through the class definition and find them.  Otherwise, its a
// pretty boring object.
versionVersion: versionTag
    id="$Id: version.t,v 1.11 1997/03/05 04:00:53 sgranade Exp $\n"
    author='Jeff Laing'            // these are hardcoded into the capture
    func='version tracking'        // method so I always come first ;-)
;

// This verb loops through the class 'versionTag' and dumps them all out.
// It could be faster but hey, its only for debugging, not playing with.
sourcesVerb: sysverb
    verb='sources'
    action(actor)={
        local o;
        o := firstobj(versionTag);
        while (o<>nil) {
            o.id;
            o := nextobj(o,versionTag);
        }
        abort;                // don't waste a turn
    }
;

// This verb started out as a joke but ended up something serious when I
// decided I needed to give credit where it was due for example code that
// was made available by others.  Thus, I now have a scheme that will
// remember even when I forget...
creditsVerb: sysverb
    verb='credits'

    action(a) = {
        local o, ap;
        local alist;    // list of authors.
        local flist;    // list of files.

        alist := [];
        flist := [];

        /* scan all objects in our special class */
        o := firstobj(versionTag);
        while (o<>nil) {
            if (proptype(o,&author)=3 and proptype(o,&func)=3) {
                ap := find( alist, o.author );
                if (ap=nil) {
                    alist += o.author;
                    flist += [o.func];
                } else {
                    flist[ap] += ',' + o.func;
                }
            }
            o := nextobj(o,versionTag);
        }

        /* now announce it with overridable methods */
        if (length(alist)>0) {
            self.credit_header;            // display header
            self.credit_list( alist, flist );    // then the list
            self.credit_trailer;            // then the trailer
        }

        abort;                // don't waste a turn
    }

    // this is the text we put in front of every credits message
    credit_header =
        "The following modules were provided by TADS developers
        who were prepared to share their work with others:"

    // this is the text we put in front of every credits message
    credit_trailer =
        "\bIf you are a TADS developer, please consider doing the same.
        All the above mentioned modules should be available for ftp from
        the interactive-fiction archive maintained by \(Volker Blasius\)
        on \(ftp.gmd.de\)."

    // This method is called with a list of authors and a list of modules
    // that they wrote.  For each author (alist[i]), the corresponding list
    // (flist[i]) is a comma delimited string of function descriptions.  We
    // build up an "English" sentence (similiar to the look functions) and
    // then call another method to do the printing.
    credit_list(alist, flist) = {
        local modules, f, l, p;

        modules := '';
        while(length(alist)>0) {
            f := car(flist); flist := cdr(flist);
            l := 0;
            modules := '';
            while (true) {
                p:=find(f,',');
                if (p<>nil) {
                    if (l++>0) modules += ', ';
                    modules += substr(f,1,p-1);
                    f:=substr(f,p+1,length(f));
                    continue;
                }
                if (l++>0) modules += ' and ';    // SRG added ++ to (l>0)
                modules += f;
                break;
            }
            self.credit_entry(car(alist),modules,l);
            alist := cdr(alist);
        }
    }

    // give credit to author 'a' for modules 'l' (list sentence form)
    // (there are 'n' modules provided)
    credit_entry(author,modules,n) = {
        "\b\^<<modules>> <<n > 1 ? "were" : "was">> provided
            by \(<<author>>\).\n";
    }
;

#endif

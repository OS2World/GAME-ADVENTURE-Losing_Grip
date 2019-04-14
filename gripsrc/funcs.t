#ifndef FUNCS
#define FUNCS
#pragma C+

/*
** Funcs.t contains several functions which I've found useful.  They are:
**
** moveAllCont(src, dest) -- takes all of the contents in object src and
**                           moves them into dest.  If an object has
**                           noMoveAll = true, then this function will _not_
**                           move it.
** uberloc(obj) -- Returns the room an object is in, no matter how deeply
**                 nested that object is in other objects.  Note that if
**                 an object has isUber = true, then uberloc considers
**                 that object to be the top of the location tree.
** inside(obj, loc) -- Returns true if obj is contained in loc, false if
**                     it isn't.
** deepcont(objs) -- Returns all contents of an object (or list of objects),
**                   no matter how deep in the content tree they are.
** deeplistcont(objs) -- Returns all *listable* contents of an object or
**                       list of objects.
** shuffle(list) -- Shuffles a list of any length
** distillList(list) -- Goes through a list and deletes any duplicates in
**                      the list. It also removes null elements.
** Copyright (c) 1995-1997 Stephen Granade
** You are permitted to distribute this module freely, as long as 1) my name
** is left on it, and 2) you keep all files together.  You may also use
** this module in any game you like in any form you like.  Hack away at
** it, if you so desire.  All I ask is that you credit me in some way in your
** game.
** I would welcome any comments on or suggestions for this module.  I can be
** reached at:
**  Duke University Physics Department
**  Box 90305
**  Durham, NC  27708-0305
**  U.S.A.
**  sgranade@phy.duke.edu
**
** Version history:
**  29 Dec 95 -- Initial release
**   8 Jan 96 -- bug fix: moveAllCont no longer moves fixeditems.
**  14 Mar 97 -- v1.2  Added noMoveAll check to moveAllCont
**   1 Jun 97 -- v1.3  Added shuffle function
**  24 Jun 97 -- v1.4  Added distillList function
*/

#include "version.t"

funcsVersion: versionTag
    id="$Id: funcs.t,v 1.4 1997/06/25 01:43:04 sgranade Exp $\n"
;

// moveAllCont takes all the contents in the object src and moves them into
//  dest.  It checks for fixeditems, &c.
moveAllCont: function(src, dest)
{
    local cont, i, len;

    cont = src.contents;
    len = length(cont);
    for (i = 1; i <= len; i++)
        if (!cont[i].isfixed && !cont[i].noMoveAll)
            cont[i].moveInto(dest);
}

// uberloc returns the room an object is in, no matter how deeply nested
uberloc: function(ob)
{
    local loc;

    loc = ob;
    while (loc.location) {
        if (loc.isUber) return loc;
        loc = loc.location;
    }
    return loc;
}

// inside returns true if obj is contained in loc, no matter how deeply nested
inside: function(ob, loc)
{
    local cur_loc;

    cur_loc = ob.location;
    while (cur_loc) {
        if (cur_loc == loc)
            return true;
        cur_loc = cur_loc.location;
    }
    return nil;
}

// deepcont returns ALL contents of an object, however deep in the content tree
deepcont : function(objs)
{
    local i, len, contcont;

    i = datatype(objs);
    if (i == 5) return ([]);
    if (i == 2) {
        if (length(objs.contents) == 0)
            return ([]);
        return ([] + objs.contents + deepcont(objs.contents));
    }
    len = length(objs);
    contcont = [];
    for (i = 1; i <= len; i++)
        contcont += objs[i].contents + deepcont(objs[i].contents);
    return ([] + contcont);
}

// deeplistcont returns ALL listable contents of an object, however deep
deeplistcont : function( objs )
{
    local contents, viscontents, i, len;

    contents = deepcont(objs);
    viscontents = [];
    len = length(contents);
    for (i = 1; i <= len; i++) {
        if (contents[i].isListed)
            viscontents += contents[i];
    }
    return viscontents;
}

// shuffle randomly shuffles a list. The algorithm is from Knuth.
shuffle: function(list)
{
    local i, retlist, tempitem, ndx;

    retlist = list;
    for (i = 1; i < length(list); i++) {
        ndx = rand(length(list));
        tempitem = retlist[i];
        retlist[i] = retlist[ndx];
        retlist[ndx] = tempitem;
    }
    return retlist;
}

// distillList removes duplicates from a list. It also strips off any null
//  elements.
distillList: function(list)
{
    local tempList, i, len;
    
    tempList = [];
    len = length(list);
    for (i = 1; i <= len; i++)
        if (list[i] != nil && find(tempList, list[i]) == nil)
            tempList += list[i];
    return tempList;
}

#endif

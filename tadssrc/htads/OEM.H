/* $Header: d:/tads/tads2/RCS/oemproto.h 1.2 96/10/14 16:10:38 mroberts Exp $ */

/* Copyright (c) 1996 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  oem.h - "original equipment manufacturer" identification
Function
  This file identifies the person who created this version of TADS.
  The OEM name defined herein is displayed in the version banner of
  each executable to make it easy to identify the source of a particular
  version of the system.
  
  This file also specifies the OEM version number.  This version
  number identifies the revision level of a particular base version
  of the TADS source code as released by a particular OEM.
Notes

  EACH PERSON WHO PRODUCES A VERSION OF TADS SHOULD SET THE OEM
  IDENTIFIER IN THIS FILE TO A UNIQUE VALUE.  The OEM identifier is
  intended to reduce the confusion that could result from different
  people producing versions of the system.  If you produce a version
  of TADS, and someone has a question about it, you'll be able to
  tell from the OEM identifier on the person's executable whether
  it's your version or a version someone else produced.

  We recommend that you use your email address or full name as your
  OEM identifier, since this is the best way to ensure that you don't
  use an ID that someone else is using.

  Note that, if you release multiple versions of a particular release
  of the base TADS source code (for example, if you find a fix a
  port-specific bug in your version, and the fixed version is based
  on the same base TADS source code as the original release), you
  should update the OEM version number as well.  This should start
  at zero for the first release that you make of a particular version
  of the base TADS source code, and should be incremented each time
  you release a new revision based on the same portable code.  This
  version number shows up as the fourth part of the version number
  displayed in each executable's banner.

Modified
  10/05/96 MJRoberts  - Creation
*/

#ifndef OEM_H
#define OEM_H

/*
 *   OEM name - this should uniquely identify your version, to
 *   distinguish it from versions produced by other people; you should use
 *   your name or email address to ensure uniqueness 
 */
#define  TADS_OEM_NAME   "TADS/2 1.0.0"

/*
 *   OEM version level - increment for each new release based on the same
 *   original source code version 
 */
#define TADS_OEM_VERSION  1


#endif /* OEM_H */

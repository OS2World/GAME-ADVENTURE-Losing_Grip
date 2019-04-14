/*
    Test code for _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: griptest.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

stage2Verb: deepverb
    verb = 'stagetwo' 'stage2'
    action(actor) = {
        sunglasses.moveInto(rucksack);
        moveAllCont(Me, nil);
        dog.clearProps;
        dog.wantheartbeat = nil;
        monitor_leads.moveInto(actor);
        monitor_leads.isworn = true;
        arms.moveInto(Me);
        hands.moveInto(Me);
        Me.stage = '0';
        actor.travelTo(padded_chair);
        op_theatre.enterRoom(Me);
        remfuse(&rollAvalanche, 2);
        remfuse(&rollAvalanche, 3);
        setfuse(withdrawal, 5 + RAND(2), 1);
    }
;

stage3aVerb: deepverb
    verb = 'stagethreea' 'stage3a'
    action(actor) = {
        notify(hospitalDaemon, &passersBy, 5 + RAND(2));
        Me.noWithdrawal = true;    // Stop the withdrawal function
        moveAllCont(Me, nil);
        actor.travelTo(green4);
        if (dog.location != nil) {
            dog.age = 1;
            dog.namedAge = 'young dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            dog.moveInto(admitting);
        }
        radioDaemon.playlist = &playlist2;
        old_woman.wantheartbeat = true;
        Me.stage = '2a';
    }
;

stage3bVerb: deepverb
    verb = 'stagethreeb' 'stage3b'
    action(actor) = {
        notify(janitor, &firstMove, 2);
        notify(schoolDaemon, &passersBy, 5 + RAND(2));
        Me.noWithdrawal = true;    // Stop the withdrawal function
        moveAllCont(Me, nil);
        actor.travelTo(mid1_hall_one);
        if (dog.location != nil) {
            dog.age = 1;
            dog.namedAge = 'young dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            dog.moveInto(nw2_end);
        }
        radioDaemon.playlist = &playlist2;
        buddy.wantheartbeat = true;
        Me.stage = '2b';
    }
;

stage4Verb: deepverb
    verb = 'stagefour' 'stage4'
    action(actor) = {
        moveAllCont(Me, nil);
        dog.clearProps;
        dog.wantheartbeat = nil;
        notify(ambulance_workers, &daemon, 2);
        Me.stage = '0';
        actor.travelTo(gurney);
    }
;

stage5Verb: deepverb
    verb = 'stagefive' 'stage5'
    action(actor) = {
        unnotify(ambulance_workers, &daemon);
        moveAllCont(Me, nil);
        actor.travelTo(bedroom_bed);
        if (dog.location != nil) {
            dog.age = 2;
            dog.namedAge = 'dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            dog.moveInto(top_of_hill);
        }
        bedroom.enterRoom(Me);
        radioDaemon.playlist = &playlist3;
        Me.stage = 3;
    }
;

stage6Verb: deepverb
    verb = 'stagesix' 'stage6'
    action(actor) = {
        moveAllCont(Me, nil);
        dog.clearProps;
        dog.wantheartbeat = nil;
        Me.stage = '0';
        actor.travelTo(my_hospital_bed);
        if (dog.location != nil) {
            dog.age = 3;
            dog.namedAge = 'dog';
            dog.isWaiting = true;
            dog.wantheartbeat = nil;
            dog.moveInto(argument_room);
        }
        curtains.moveInto(my_hospital_room);
        my_hospital_room.enterRoom(Me);
        notify(butler, &setup, 3);
    }
;

stage7Verb: deepverb
    verb = 'stageseven' 'stage7'
    action(actor) = {
        blasted_plain.setup;    // Get this finale running
    }
;

makeKeyVerb: deepverb
    sdesc = "makekey"
    verb = 'makekey'
    doAction = 'Makekey'
;

modify basicStrObj
    verDoMakekey(actor) = {}
    doMakekey(actor) = {
        local n1, n2, k, fnum, flag;
        
        k = keyObj.encode(self.value);
        n1 = keyObj.ennumber(self.value);
        n2 = keyObj.ennumber(k);
        fnum = fopen('regkey.txt', 'w');
        if (fnum != nil) {
            if (fwrite(fnum, 'Losing Your Grip') ||
                fwrite(fnum, self.value) || fwrite(fnum, n1) ||
                fwrite(fnum, k) || fwrite(fnum, n2))
                "Error in writing regkey.txt. ";
            else "Key \"<<k>>\" written to regkey.txt. ";
            fclose(fnum);
        }
        else "Failed to open & write regkey.txt. ";
        abort;
    }
;

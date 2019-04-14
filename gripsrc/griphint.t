/*
    GripHint, part of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $
*/

#pragma C+

// Fit the First
beginningAh: ahPuzzle
    title = "What should I do? I keep wandering around without finding
        anything."
    ahDesc = "beginning"
;
manClueAh: ahClue
    ahDesc = "seen man";
beginningH1: ahHint
    owner = beginningAh
    ahAvail = { return (!manClueAh.seen); }
    ahTell = "The first thing you should do is walk around. "
;
beginningH2: ahHintList
    owner = beginningAh
    ahAvail = { return (manClueAh.seen); }
    ahTell = [
'The man buried in the mud might be able to help.',
'Have you watched him closely?',
'At one point his eyes dart to the northeast.',
'Go northeast once or twice and you should find a building.',
'Enter the building.'
             ]
;

coldAh: ahPuzzle
    title = "Every time I go outside, I begin freezing!"
    ahDesc = "freezing"
;
coatClueAh: ahClue
    ahDesc = "gotten coat";
stitchingAh: ahClue
    ahDesc = "pulled stitching";
insulationClueAh: ahClue
    ahDesc = "seen insulation";
coldH1: ahHint
    owner = coldAh
    ahTell = "The bitter cold is deadly if you are not well-protected."
;
coldH2: ahHintList
    owner = coldAh
    ahAvail = { return (coldH1.seen && !coatClueAh.seen); }
    ahTell = [
'The first step is to find something to wear.',
'A coat would do the trick.',
'Go to the Preparatory Room east of the Audience Hall.'
             ]
;
coldH3: ahHintList
    owner = coldAh
    ahAvail = { return (coldH1.seen && coatClueAh.seen && !stitchingAh.seen); }
    ahTell = [
'The coat alone won\'t protect you from the wind and the snow.',
'There is a way to make it thicker.',
'Look closely at the coat.',
'Specifically, look closely at the stitching on the coat.',
'The stitching could be loosened, allowing you to fill the coat.',
'Pull the stitching twice.'
             ]
;
coldH4: ahHintList
    owner = coldAh
    ahAvail = { return (coldH1.seen && coatClueAh.seen && stitchingAh.seen); }
    ahTell = [
'The coat needs to be better-insulating.',
'Notice that I said better-\(insulating\).',
'You need insulation.'
             ]
;
coldH5: ahHint
    owner = coldAh
    ahAvail = { return (coldH4.seen && !insulationClueAh.seen); }
    ahTell = "There is some in the storage closet west of the Northwest
        Walkway."
;
coldH6: ahHint
    owner = coldAh
    ahAvail = { return (coldH4.seen && insulationClueAh.seen); }
    ahTell = "The coat can protect you if you fill it with three tufts of the
        insulation."
;

insulationAh: ahPuzzle
    title = "How do I pick up the insulation in the storage closet?"
    ahDesc = "insulation"
;
gloveAh: ahClue
    ahDesc = "gotten gloves";
insulationH1: ahHintList
    owner = insulationAh
    ahTell = [
'The problem with insulation is that the fiberglass threads jab into your
 hands.',
'You need to protect your hands.',
'A pair of gloves would do.'
             ]
;
insulationH2: ahHintList
    owner = insulationAh
    ahAvail = { return (insulationH1.seen && !gloveAh.seen); }
    ahTell = [
'A pair of gloves is available in the building.',
'Specifically, in the Preparatory Room east of the Audience Hall.'
             ]
;
insulationH3: ahHint
    owner = insulationAh
    ahAvail = { return (insulationH1.seen && gloveAh.seen); }
    ahTell = "Wear the gloves you found and you can take tufts of the
        insulation."
;

snowblindAh: ahPuzzle
    title = "I'm snowblind when I go outside!"
    ahDesc = "snowblind"
;
glassesAh: ahClue
    ahDesc = "gotten glasses";
snowblindH1: ahHintList
    owner = snowblindAh
    ahTell = [
'A nice blindfold would be helpful.',
'Except then you couldn\'t see.',
'Perhaps a pair of sunglasses?',
'"Sunglasses?"\ you ask.'
             ]
;
snowblindH2: ahHintList
    owner = snowblindAh
    ahAvail = { return (snowblindH1.seen && !glassesAh.seen); }
    ahTell = [
'There are some available somewhere.',
'Someone in the building has them.',
'\(Someone\) in the building...',
'Go look at Frankie.',
'Have you tried getting the sunglasses?',
'Well, don\'t be rude:\ ask for the glasses.',
'ASK FRANKIE FOR GLASSES.'
             ]
;
snowblindH3: ahHint
    owner = snowblindAh
    ahAvail = { return (snowblindH1.seen && glassesAh.seen); }
    ahTell = "Your sunglasses, when worn, will protect your eyes."
;

sphereInfoAh: ahPuzzle
    title = "What do I do with this sphere?"
    ahDesc = "sphereInfo"
;
sphereInfoH1: ahHintList
    owner = sphereInfoAh
    ahTell = [
'Do what Frankie asked:\ find out more about the sphere.',
'There are two places you can research the sphere.',
'One of them is the library, the other is the filing office.',
'There is a way to get information from both places using the sphere.',
'Notice what both rooms have in common?',
'Both rooms boast a metal sentinel by their entrances.',
'Look closely at the sentinels.',
'Look especially at their arms.',
'The arms of the sentinels can be raised, causing them to cup in front of
them.',
'The cupped hands of a sentinel are perfect for holding, say, a sphere.',
'RAISE SENTINEL\'S ARMS. PUT SPHERE IN SENTINEL\'S HANDS.'
             ]
;

findBreakersAh: ahPuzzle
    prereqs = [ snowblindAh, coldAh ]
    title = "Now what do I do? I'm out of ideas."
    ahDesc = "findBreakers"
;
findBreakersH: ahHintList
    owner = findBreakersAh
    ahTell = [
'You haven\'t wandered around outside much, have you?',
'Go outside and circle the building.',
'You\'ll catch a glimpse of something on the east side of the building.',
'LOOK AT BUILDING. Notice the box?',
'Hopefully this will get you moving in the right direction.'
             ]
;

turnOnBreakersAh: ahPuzzle
    title = "What do I do with the box on the side of the building?"
    ahDesc = "turnOnBreakers"
;
askedFrankieClue: ahClue
    ahDesc = "asked Frankie";
turnOnBreakersH1: ahHintList
    owner = turnOnBreakersAh
    ahTell = [
'Have you tried flipping any of the breakers inside the box?',
'Randomly flipping breakers is not a good idea. There are 40320 possible
 ways in which the breakers may be flipped.',
'Have you asked Frankie about the breaker box? About power?'
             ]
;
turnOnBreakersH2: ahHintList
    owner = turnOnBreakersAh
    ahAvail = { return (turnOnBreakersH1.seen && askedFrankieClue.seen); }
    ahTell = [
'Frankie mentioned that the breakers have to be reset in the order that they
 were tripped.',
'You need to find out the order in which rooms lost power. The breaker list in
 the breaker box will let you match each room to its breaker.'
'Visit each of the rooms listed on the breaker list. What do they all have
 in common?',
'They each have a clock.',
'Each clock displays a different time.',
'The clocks stopped when the power went out.',
'The room whose clock shows the earliest time lost power first.',
'Flip the breakers in the same order as the rooms\' clocks.'
             ]
;

sludgeAh: ahPuzzle
    title = "The sludge is going to fill the room; how can I stop it?"
    ahDesc = "sludge"
;
sludgeH: ahHintList
    owner = sludgeAh
    ahTell = [
'Have you asked Frankie about the sludge?',
'He\'ll tell you that the sludge is flammable.',
'The heater could burn the sludge...if you could get the sludge to the
 heater.',
'Have you played with the wheels in the balance room?',
'Try turning them clockwise or counterclockwise.',
'They control the tilt of the room. The one on the south wall controls the
 east-west tilt; the one on the east wall, the north-south tilt.',
'Turn them until the southeast corner is the lowest point of the room. The
 sludge will run into that corner.',
'Now you need to move the heater to the sludge.',
'Push the heater east, twice if necessary. The heat from the heater will burn
 the sludge and keep it from filling the room.'
             ]
;

findJunctionBoxAh: ahPuzzle
    title = "I'm at a loss as to what to do next."
    ahDesc = "findJunctionBox"
;
findJunctionBoxH: ahHintList
    owner = findJunctionBoxAh
    ahTell = [
'Now that you\'ve turned on the power and vanquished the sludge, there\'s only
 one unsolved mystery:\ the cables on the post to the northeast of the
 building.',
'Look at the orange cable on the post.',
'It runs from the post to the building.',
'It runs to the northeast corner of the building.',
'What room is on the first floor in the northeast corner?',
'Take a good look at everything in the balance room.',
'Especially the table which holds the balances.',
'Look under the balance table.',
'Turn on the junction box and go exploring again.'
                 ]
;

sphereAh: ahPuzzle
    title = "How do I avoid the sphere?"
    ahDesc = "sphere"
;
sphereH: ahHint
    owner = sphereAh
    ahTell = "You can't."
;

avalancheAh: ahPuzzle
    title = "What can I do about the avalanche that's bearing down at me?"
    ahDesc = "avalanche"
;
fenceAh: ahClue
    ahDesc = "seen fence";
avalancheH1: ahHint
    owner = avalancheAh
    ahTell = "The avalanche must be diverted from the building."
;
avalancheH2: ahHintList
    owner = avalancheAh
    ahAvail = { return (avalancheH1.seen && !fenceAh.seen); }
    ahTell = [
'Have you taken a look at the dark line in the snow to the northwest and
 northeast of the building?',
'Examine the dark line and you\'ll find that it\'s a fence.'
                 ]
;
avalancheH3: ahHintList
    owner = avalancheAh
    ahAvail = { return (avalancheH1.seen && fenceAh.seen); }
    ahTell = [
'Raise the fence and you\'ll have stopped the avalanche.',
'You can\'t raise the fence by hand.',
'You need to get power to the fence to raise it.',
'There is a cable attached to the northeast fence.',
'Since you\'ve turned on the junction box, the orange cable has power.',
'You need to connect both cables.',
'They\'re not long enough to touch each other without help.',
'There isn\'t anything to connect them...',
'...except you.',
'GET LOWER CABLE. GET UPPER CABLE.'
                 ]
;

// Interlude
monitorsAh: ahPuzzle
    title = "How do I keep those infernal monitors from giving me away?"
    ahDesc = "monitors"
;
monitorsH: ahHint
    owner = monitorsAh
    ahTell = "The easiest way to keep the monitors from shrilling when you
        take off the leads is to turn them off."
;

hideAh: ahPuzzle
    prereqs = [monitorsAh]
    title = "Now that I've removed the monitors, what should I do?"
    ahDesc = "hide"
;
hideH: ahHintList
    owner = hideAh
    ahTell = [
'If you are ready to end your journey, do nothing.',
'If you wish to continue, you need to find a safe place to hide so you can
 reinject yourself with the drug.',
'There are two places in the clinic you can hide safely.'
             ]
;

hide1Ah: ahPuzzle
    prereqs = [monitorsAh]
    ahAvail = { return hideH.seen; }
    title = "Where's the first place I can hide?"
    ahDesc = "hide1"
;
hide1H: ahHintList
    owner = hide1Ah
    ahTell = [
'The first place is the Supplies Room.',
'You have to find a place in the room where you won\'t be readily seen.',
'The Supplies Room is filled with supplies.',
'Some of the supplies are in crates.',
'The crates are stacked in such a way as to leave a space behind them.',
'You can hide in that space.',
'Don\'t forget to close the door to the Supplies Room before you reinject
 the drug.'
             ]
;

hide2Ah: ahPuzzle
    prereqs = [monitorsAh]
    ahAvail = { return hideH.seen; }
    title = "Where's the second place I can hide?"
    ahDesc = "hide2"
;
hide2H: ahHintList
    owner = hide2Ah
    ahTell = [
'The second place is the attic.',
'You have to reach the pull cord which dangles from the ceiling in one of
 the hallways.',
'A chair would help you reach that cord.',
'Say, one of the chairs from the Observation Room.',
'Get a chair, then push it north. Stand on it.',
'Once you\'ve pulled down the attic ladder, push the chair back to where you
 found it. Otherwise, the doctor and nurses will know where you are.',
'Speaking of knowing where you are, you have to pull the ladder up behind
 you once you\'re in the attic for the same reason.'
             ]
;

// Fit the Second, part a
doubleDoorAh: ahPuzzle
    title = "I can't unlock the double doors."
    ahDesc = "doubleDoor"
;
doubleDoorH: ahHintList
    owner = doubleDoorAh
    ahTell = [
'To unlock the doors, you need a key.',
'Have you looked at the double doors from the hallway side?',
'The key is in the lock.',
'Turn the key!'
             ]
;

vialAh: ahPuzzle
    title = "How do I get the vial which rolled under the crates?"
    ahDesc = "vial"
;
dogClueAh: ahClue
    ahDesc = "seen dog";
vialH1: ahHintList
    owner = vialAh
    ahTell = [
'Once the vial has rolled under the crates, it is beyond your ability
 to get it.',
'Sometimes it helps to have a smaller friend who can help you.',
'Do you have a smaller friend?'
             ]
;
vialH2: ahHint
    owner = vialAh
    ahAvail = { return (vialH1.seen && !dogClueAh.seen); }
    ahTell = "If not, you'll need to go back to Fit the First and touch the
        pile of spheres which is in the room with Frankie. "
;
vialH3: ahHintList
    owner = vialAh
    ahAvail = { return (vialH1.seen && dogClueAh.seen); }
    ahTell = [
'Your dog is a smaller friend.',
'Have the dog fetch the vial for you.',
'Once you and the dog are in the room with the crates:\n
DOG, GET VIAL'
             ]
;

dogToVialAh: ahPuzzle
    title = "Every time I try to take the dog anywhere, we're stopped. What's
        up?"
    ahDesc = "dogToVial"
;
ropeAh: ahClue
    ahDesc = "gotten rope";
rucksackAh: ahClue
    ahDesc = "brought rucksack";
dogToVialH1: ahHintList
    owner = dogToVialAh
    ahTell = [
'The hospital has a strict no-pets policy.',
'The staff is instructed to enforce the policy...with one exception.',
'A guide dog for the blind is allowed to be most anywhere in the hospital.',
'You need to look the part of a blind person in order to fool the staff.'
'For one thing, a guide dog has to be leashed in order to lead.'
             ]
;
dogToVialH2: ahHintList
    owner = dogToVialAh
    ahAvail = { return (dogToVialH1.seen && !ropeAh.seen); }
    ahTell = [
'You need a rope to tie to the dog.',
'There\'s one in Fit the First, tied to the northwest fence.'
             ]
;
dogToVialH2a: ahHintList
    owner = dogToVialAh
    ahAvail = { return (dogToVialH2.seen && !rucksackAh.seen); }
    ahTell = [
'Don\'t know how to get the rope to Fit the Second?',
'Hint:\ play with the rucksack.',
'Notice what the dog does when you leave the building holding the rucksack?',
'What happens if you give the rucksack to the dog?',
'Put what you need (like the rope) in the rucksack and give it to the dog.
 That way, you\'ll have what you need in later Fits.'
             ]
;
dogToVialH3: ahHintList
    owner = dogToVialAh
    ahAvail = { return (dogToVialH1.seen && ropeAh.seen); }
    ahTell = [
'Tie the rope you found to the dog.',
'There are two props you need to complete your disguise.',
'One is the pair of sunglasses.',
'The other is a white cane.',
'The cane is in the first room to the south off the orange corridor.'
             ]
;

cuffAh: ahPuzzle
    title = "Where can I find Eileen's BP cuff?"
    ahDesc = "cuff"
;
cuffH: ahHint
    owner = cuffAh
    ahTell = "In the room to the north of Green Three."
;

lindaAh: ahPuzzle
    title = "How do I get the old woman past Linda?"
    ahDesc = "linda"
;
passAh: ahClue
    ahDesc = "gotten pass";
lindaH1: ahHint
    owner = lindaAh
    ahTell = "Linda won't let you wheel the old woman past her without the
        proper permissions."
;
lindaH2: ahHintList
    owner = lindaAh
    ahAvail = { return (lindaH1.seen && !passAh.seen); }
    ahTell = [
'In Purple 1, just north of Admitting, a line of patients and a nurse will
 eventually appear after you\'ve seen the group of doctors in one of the
 operating rooms.',
'Wait there for a while.',
'Help the nurse with the patients and you will be rewarded.',
'Specifically, the nurse will give you a hall pass.',
'The hall pass will let you wheel the old woman past Linda.'
             ]
;
lindaH3: ahHint
    owner = lindaAh
    ahAvail = { return (lindaH1.seen && passAh.seen); }
    ahTell = "Show your hall pass to Linda and she won't stop you from
        wheeling the old woman past her."
;

globeAh: ahPuzzle
    title = "I can't get the globe; it hurts too much."
    ahDesc = "globe"
;
seenVialAh: ahClue
    ahDesc = "seen vial";
syringeAh: ahClue
    ahDesc = "seen syringe";
globeH1: ahHint
    owner = globeAh
    ahTell = "Were your hands numbed, you would be able to pick up the globe."
;
globeH2: ahHintList
    owner = globeAh
    ahAvail = { return (globeH1.seen && !seenVialAh.seen); }
    ahTell = [
'There is a vial of novocaine available.',
'Watch the doctors in any of the operating rooms. When they are done, leave
 and re-enter the room.',
'After you do so, the vial will be apparent.'
             ]
;
globeH3: ahHintList
    owner = globeAh
    ahAvail = { return (globeH1.seen && seenVialAh.seen); }
    ahTell = [
'You can use the vial of novocaine you found to numb your hands.',
'To do so you need a way of getting the novocaine into your hands.'
             ]
;
globeH4: ahHintList
    owner = globeAh
    ahAvail = { return (globeH3.seen && !syringeAh.seen); }
    ahTell = [
'You need a syringe.',
'This being a hospital, there is a syringe available.',
'You won\'t find it until after you wheel the old woman to her room.',
'The old woman\'s room is the room in Orange which is occupied but empty.'
             ]
;
globeH5: ahHintList
    owner = globeAh
    ahAvail = { return (globeH3.seen && syringeAh.seen); }
    ahTell = [
'The syringe you found should do the trick.',
'Put the syringe in the novocaine vial, then inject the syringe into your
 hands.',
'PUT SYRINGE IN VIAL. INJECT SYRINGE IN HANDS.'
             ]
;

// Fit the Second, part b
lockedDoorsAh: ahPuzzle
    title = "How can I open the locked doors I keep seeing?"
    ahDesc = "lockedDoors"
;
lockedDoorsH: ahHintList
    owner = lockedDoorsAh
    ahTell = [
'Find a set of keys.',
'There is a person in the school who has keys to everything.',
'The janitor has to be able to get into any room.',
'Look at the janitor\'s cart.'
             ]
;

keysAh: ahPuzzle
    title = "I think I need to get the janitor's keys."
    ahDesc = "keys"
;
keysH: ahHintList
    owner = keysAh
    ahTell = [
'As long as the janitor is next to his cart, you can\'t get the keys.',
'You need to find a way to distract him.',
'A nasty spill would do the trick.',
'Have you seen anything that would make a nasty mess?',
'How about that shelf of chemicals next to the library entrance?',
'The only problem is that you can\'t knock it over without hurting yourself.',
'You need someone else to do it.',
'Who else is around and could help you out?',
'Little Buddy could.',
'Have him follow you to the shelf. Notice how he keeps glancing at it?',
'Ask him about the shelf.'
             ]
;

grateAh: ahPuzzle
    title = "How do I unlock the grate in the storage closet?"
    ahDesc = "grate"
;
seenForceFieldAh: ahClue
    ahDesc = "seen force field machine";
seenTECAh: ahClue
    ahDesc = "seen TEC";
grateH1: ahHintList
    owner = grateAh
    ahTell = [
'The padlock on the grate is too rusted to be opened by any key.',
'You will have to find a way to break it open.',
'One of the tools you will need is a pipe in the second-floor
 northwest-southwest bend.',
'If you go look at it, you will see that it drips water.',
'You\'ll need to find a way to capture that water.'
             ]
;
grateH2: ahHintList
    owner = grateAh
    ahAvail = { return (grateH1.seen && !seenForceFieldAh.seen); }
    ahTell = [
'You haven\'t found the machine you need to capture the water yet.',
'Go to the Student Lab on the northwest end of the second floor.'
             ]
;
grateH3: ahHintList
    owner = grateAh
    ahAvail = { return (grateH1.seen && seenForceFieldAh.seen); }
    ahTell = [
'The black box you found in the Student Lab holds the key to trapping the
 water from the pipe.',
'Once you\'ve trapped the water, take it to the padlock.',
'Put it in the padlock.',
'What happens to water when it freezes?',
'It expands.',
'If you could freeze the water once it\'s in the padlock, it would burst
 the lock.'
             ]
;
grateH4: ahHintList
    owner = grateAh
    ahAvail = { return (grateH3.seen && !seenTECAh.seen); }
    ahTell = [
'You\'re still missing one piece of the puzzle.',
'There\'s a door in the section of the second-floor hallway where the leaky
 pipe is. Find a way into the room behind the door.'
             ]
;
grateH5: ahHintList
    owner = grateAh
    ahAvail = { return (grateH3.seen && seenTECAh.seen); }
    ahTell = [
'Have you experimented with the square you found in the Demonstration
 Storage room?',
'When turned on, it gets cooler.',
'Put the globe containing the water into the padlock. Put the square on
 the padlock and turn it on. When the padlock (and thus the water) gets
 cold enough, the lock will burst.'
             ]
;

boxAh: ahPuzzle
    title = "I've found the box Erin was talking about; how do I get it to
        her?"
    ahDesc = "box"
;
boxH: ahHint
    owner = boxAh
    ahTell = "The box won't survive a trip down the stairs, and it's too
        heavy for you to lift it. You'll have to get it through the
        crawlspaces beneath the storage closet. "
;

waterAh: ahPuzzle
    title = "Why can't I capture one of the water drops with the force-field
        machine?"
    ahDesc = "water"
;
seenNoncausalAh: ahClue
    ahDesc = "seen the noncausal machine";
waterH1: ahHintList
    owner = waterAh
    ahTell = [
'You are a victim of Murphy\'s law in action: you can\'t get the water to
 fall through the circle when you have the force-field on.',
'What you need is a way to know when the drop of water is about to fall.'
             ]
;
waterH2: ahHint
    owner = waterAh
    ahAvail = { return (waterH1.seen && !seenNoncausalAh.seen); }
    ahTell = "There\'s a door in the section of the second-floor hallway
        where the leaky pipe is. The answer to your dilemma is behind the
        door."
;
waterH3: ahHintList
    owner = waterAh
    ahAvail = { return (waterH1.seen && seenNoncausalAh.seen); }
    ahTell = [
'Here\'s a hint:\ play with the cylinder you found in the Demonstration
 Storage room.',
'Have you dropped anything into its funnel?',
'Just before anything falls into the cylinder, its needle wiggles.',
'Put the cylinder under the leaky pipe and you\'ll know when a drop is
 about to fall.',
'When the needle on the cylinder wiggles, push the button that makes the
 blue field.'
             ]
;

plateAh: ahPuzzle
    title = "I want to raise the metal plate in the small crawlspace."
    ahDesc = "plate"
;
plateH1: ahHintList
    owner = plateAh
    ahTell = [
'Have you tried pulling the plate?',
'If so, you\'ll find that you lack the necessary leverage.',
'There is a small protrusion on the plate which you might find useful.',
'You could conceivably tie something to the protrusion.',
'Say, the rope from Fit the First.'
             ]
;
plateH2: ahHintList
    owner = plateAh
    ahAvail = { return (plateH1.seen && !rucksackAh.seen); }
    ahTell = [
'Don\'t know how to get the rope to Fit the Second?',
'Hint:\ play with the rucksack.',
'Notice what the dog does when you leave the building holding the rucksack?',
'What happens if you give the rucksack to the dog?',
'Put what you need (like the rope) in the rucksack and give it to the dog.
 That way, you\'ll have what you need in later Fits.'
             ]
;
plateH3: ahHintList
    owner = plateAh
    ahAvail = { return (plateH1.seen && rucksackAh.seen); }
    ahTell = [
'The rope alone still won\'t give you enough leverage.',
'For additional help, look to the thin opening above the plate.',
'There is a pulley in the opening.',
'Tie the rope to the plate; put the rope over the pulley; pull the rope.'
             ]
;

buddyAh: ahPuzzle
    title = "How can I get Little Buddy out of the jam he's in?"
    ahDesc = "buddy"
;
buddyH: ahHintList
    owner = buddyAh
    ahTell = [
'Little Buddy is stuck but good in the crawlspace.',
'Pushing him doesn\'t work.',
'At least, it won\'t without any more lubrication.',
'Remember that bottle of lotion Erin was constantly using?',
'She left it in the library.',
'Lotion is pretty slick.',
'Get the lotion. Put it on Little Buddy, then push him.'
             ]
;

// Interlude
insertNeedleAh: ahPuzzle
    title = "What can I do while I'm strapped to this gurney?"
    ahDesc = "insertNeedle"
;
insertNeedleH: ahHintList
    owner = insertNeedleAh
    ahTell = [
'With your arms and legs bound, there is little you can reach.',
'There is the needle bouncing against your hand.',
'Remember how you left the first Interlude?',
'Put the needle in your hand.'
             ]
;

// Fit the Third
roomAh: ahPuzzle
    title = "How do I get out of my bedroom?"
    ahDesc = "room"
;
roomH1: ahHintList
    owner = roomAh
    ahTell = [
'If you can\'t leave through the door...',
'...leave through the window.',
'All you need is a way to make it down safely.'
             ]
;
roomH2: ahHintList
    owner = roomAh
    ahAvail = { return (roomH1.seen && !bedroom_bed.everUnmade); }
    ahTell = [
'Think back to classic movies and stories.',
'Whenever the heroine needs to escape a bedroom, she uses her bedsheets as
 a rope.'
'Get the sheet from the bed.'
             ]
;
roomH3: ahHintList
    owner = roomAh
    ahAvail = { return (roomH1.seen && bedroom_bed.everUnmade); }
    ahTell = [
'Use the sheet as a rope: tie it to one of the pieces of heavy furniture.',
'Now you need only open the window and go out it while holding the sheet.'
             ]
;

voicesAh: ahPuzzle
    title = "I think I hear voices!"
    ahDesc = "voices"
;
voicesH: ahHintList
    owner = voicesAh
    ahTell = [
'The first clue to the identity of the voices is where you hear them:\ from
 somewhere around your feet.',
'The second clue is from one of the books in your bedroom.',
'The voices belong to faeries.',
'If you read the book about faeries, you will find that you can see them
 when you are holding a four-leaf clover.',
'There is a patch of clover in the south part of your backyard.',
'Search the clover patch and you will find a four-leaf clover. As long as
 you are holding it, you can see the faeries.'
             ]
;

followFaeriesAh: ahPuzzle
    title = "How do I follow the faeries?"
    ahDesc = "followFaeries"
;
followFaeriesH: ahHintList
    owner = followFaeriesAh
    ahTell = [
'To follow the faeries, it\'s a good idea to watch how they leave.',
'Did you see what they did?',
'The first faerie put on a white hat and said, "I\'m off!"',
'The second and third faeries also put on white hats and said, "I\'m after!"',
'After they were gone, a white hat was left behind.',
'Might it be linked to their ability to leave magically?',
'Try emulating them.',
'WEAR WHITE HAT. SAY "I\'M AFTER"'
             ]
;

carvingAh: ahPuzzle
    title = "I want to stop that bully from carving up the tree."
    ahDesc = "carving"
;
carvingH: ahHintList
    owner = carvingAh
    ahTell = [
'Whatever you do, don\'t try taking matters into your own hands.',
'The bully always enjoyed pushing you around when the two of you were growing
 up; with that knife in his hand, things could take a nasty turn.',
'What you need is someone to help you.',
'You\'ve made one friend in this journey who has stuck by you.',
'Namely, your dog.',
'Have the dog attack the older boy.',
'DOG, SIC BOY.'
             ]
;

dragonAh: ahPuzzle
    title = "I need to get light from the dragon's fire."
    ahDesc = "dragon"
;
toadstoolDoorAh: ahClue
    ahDesc = "knocked on the toadstool door";
dragonH1: ahHintList
    owner = dragonAh
    ahTell = [
'As with many things, another\'s help would be useful.',
'You need someone who would be familiar with the faerie king\'s wishes.'
             ]
;
dragonH2: ahHintList
    owner = dragonAh
    ahAvail = { return (dragonH1.seen && !toadstoolDoorAh.seen); }
    ahTell = [
'Have you explored all of the forest yet?',
'More specifically, have you looked in the extreme southeast corner of the
 forest?',
'There\'s a faerie ring there.',
'Take a look at the ring.',
'Notice the solitary toadstool?',
'Look at it.',
'A little-known fact:\ few toadstools have a door.',
'Knock on that door.'
             ]
;
dragonH3: ahHintList
    owner = dragonAh
    ahAvail = { return (dragonH1.seen && toadstoolDoorAh.seen); }
    ahTell = [
'The pixie might be able to help.',
'If you ask him about the king, you\'ll find out some interesting
 information.',
'The pixie used to be a member of the king\'s court.',
'He knows the king\'s obsession with light.',
'Ask him about the mason jar the king gave you.'
             ]
;

dragonSeeAh: ahPuzzle
    prereqs = [ dragonAh ]
    title = "How do I keep the dragon from seeing me?"
    ahDesc = "dragonSee"
;
laurelAh: ahClue
    ahDesc = "gotten laurel";
dragonSeeH1: ahHint
    owner = dragonSeeAh
    ahTell = "The pixie told you that you would need a laurel made of ash
        and dipped in the blood of another. "
;
dragonSeeH2: ahHint
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH1.seen && !carvingAh.solved); }
    ahTell = "Don't worry about this problem until you have figured out how
        to stop the bully from carving his initials in the oak tree."
;
dragonSeeH3: ahHint
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH1.seen && carvingAh.solved); }
    ahTell = "There are two major things you must do. "
;
dragonSeeH4: ahHintList
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH3.seen && !laurelAh.seen); }
    ahTell = [
'The first thing to do is get a laurel.',
'Phil the ash tree seems a logical source of ash laurels.',
'Have you tried asking him for a laurel?',
'ASK ASH TREE FOR LAUREL.'
             ]
;
dragonSeeH5: ahHintList
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH3.seen && laurelAh.seen); }
    ahTell = [
'Once you have the laurel you must prepare it.',
'It must be dipped in blood.',
'If you\'ve tried cutting yourself and bleeding on the laurel, you will have
 discovered that that doesn\'t work.',
'The pixie told you that it must be dipped in the blood of another.'
             ]
;
dragonSeeH6: ahHintList
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH5.seen && !dadLeaveAh.solved); }
    ahTell = [
'The bully won\'t work:\ he\'s already gone before you get the knife.',
'The pixie won\'t work. Trust me.',
'You must find someone else.',
'Have you gone back home yet?',
'Your father is most certainly "another".'
             ]
;
dragonSeeH7: ahHintList
    owner = dragonSeeAh
    ahAvail = { return (dragonSeeH5.seen && dadLeaveAh.solved); }
    ahTell = [
'Now that you...persuaded...your father to leave you alone, the answer to
 your dilemma should be more obvious.',
'Your father left a pool of blood behind when he ran up the stairs.',
'DIP LAUREL IN BLOOD.',
'Now when you wear the laurel the dragon won\'t see you.'
             ]
;

dragonSmellAh: ahPuzzle
    prereqs = [ dragonAh ]
    title = "How do I keep the dragon from smelling me?"
    ahDesc = "dragonSmell"
;
dragonSmellH: ahHintList
    owner = dragonSmellAh
    ahTell = [
'The pixie said that you had to mask your smell, but not how you do that.',
'Have you asked him about smell?',
'ASK PIXIE ABOUT SMELL.'
             ]
;

dragonHearAh: ahPuzzle
    prereqs = [ dragonAh ]
    title = "How do I keep the dragon from hearing me?"
    ahDesc = "dragonHear"
;
dragonHearH: ahHint
    owner = dragonHearAh
    ahTell = "You've been given the answer to this one:\ wear the elfin boots
        the pixie gave you. "
;

dragonBurnAh: ahPuzzle
    prereqs = [ dragonAh ]
    title = "How do I keep the dragon from burning me?"
    ahDesc = "dragonBurn"
;
dragonBurnH1: ahHintList
    owner = dragonBurnAh
    ahTell = [
'The pixie said that you needed an oak staff to protect you from dragon
 flame.',
'Have you seen any oak trees around?'
             ]
;
dragonBurnH2: ahHint
    owner = dragonBurnAh
    ahAvail = { return (dragonBurnH1.seen && !carvingAh.solved); }
    ahTell = "Don't worry about this problem until you have figured out how
        to stop the bully from carving his initials in the oak tree."
;
dragonBurnH3: ahHintList
    owner = dragonBurnAh
    ahAvail = { return (dragonBurnH1.seen && carvingAh.solved); }
    ahTell = [
'The oak tree you protected said for you to let him know if you ever needed
 anything.',
'Well, you need an oak staff.',
'ASK OAK TREE FOR STAFF.'
             ]
;

dragonFireNowAh: ahPuzzle
    prereqs = [ dragonAh ]
    title = "How do I get the dragon to breathe fire?"
    ahDesc = "dragonFireNow"
;
dragonFireNowH: ahHintList
    owner = dragonFireNowAh
    ahTell = [
'Now that the dragon doesn\'t notice you, he won\'t breathe fire.',
'You have to make him notice you.',
'Have you tried poking him? Or hitting him?',
'HIT DRAGON.'
             ]
;

dadLeaveAh: ahPuzzle
    title = "Can I keep my father from taking my things?"
    ahDesc = "dadLeave"
;
dadLeaveH1: ahHintList
    owner = dadLeaveAh
    ahTell = [
'You can\'t keep your father from taking your things, but you might be able
 to turn this to your advantage.',
'Notice how he doesn\'t pay all that much attention to what you give him?',
'He\'d probably take anything you gave him without pause.'
             ]
;
dadLeaveH2: ahHint
    owner = dadLeaveAh
    ahAvail = { return (dadLeaveH1.seen && !carvingAh.solved); }
    ahTell = "As it stands right now, you won\'t be able to solve this one.
        I suggest you restore and avoid the house until you have done other
        things. "
;
dadLeaveH3: ahHintList
    owner = dadLeaveAh
    ahAvail = { return (dadLeaveH1.seen && carvingAh.solved); }
    ahTell = [
'Remember that bully\'s knife?',
'Try giving that to your dad.',
'Of course, it won\'t do a lot of good unless it\'s open.'
             ]
;

greyManAh: ahPuzzle
    title = "I can't get away from the grey man!"
    ahDesc = "greyMan"
;
greyManH: ahHintList
    owner = greyManAh
    ahTell = [
'The grey man\'s grip is so tight that you won\'t be able to do anything for
 a moment.'
'You need to bide your time for a little while.',
'Eventually his grip will loosen on you.',
'When it does, make your move.',
'"What move?"\ you ask?',
'You have two choices.',
'For one, you could jab that pocketknife into him.',
'For another, you could smash the jar of light in the hopes of blinding him.',
'Either will work; take your pick.'
             ]
;

// Fit the Fourth, part a
crystalsAh: ahPuzzle
    title = "What do I do with all these crystals?"
    ahDesc = "crystals"
;
crystalsH1: ahHint
    owner = crystalsAh
    ahTell = "The first thing you should do is get all of them. "
;
crystalsH2: ahHintList
    owner = crystalsAh
    ahAvail = { return (crystalsH1.seen && violetAh.solved &&
        greenAh.solved && orangeAh.solved && yellowAh.solved &&
        blueAh.solved); }
    ahTell = [
'The first thing you should do is get all of them.',
'After you\'ve done that...well, remember where you found the red crystal?',
'The pedestal has something to do with the crystals.',
'Also, have you noticed something about the color of the crystals?',
'They are the colors of the rainbow.',
'You need to put them on the pedestal so that they form a rainbow, starting
with the red one.',
'Put the crystals on the pedestal in the following order: PUT RED ON
PEDESTAL. PUT ORANGE ON RED. PUT YELLOW ON ORANGE. PUT GREEN ON YELLOW.
PUT BLUE ON GREEN. PUT VIOLET ON BLUE.'
    ]
;

violetAh: ahPuzzle
    title = "There's a violet crystal piece on this plane that I can't reach."
    ahDesc = "violet"
;
violetH: ahHintList
    owner = violetAh
    ahTell = [
'To get the violet crystal piece you need to recognize where you are...',
'...what the white button does...',
'...and what effect you can have on your surroundings.',
'You are standing on an infinite plane.',
'The button mathematically inverts the plane.',
'2 becomes 1/2, 3 becomes 1/3...',
'...and 0 becomes infinity.',
'When you pressed the button the first time, the violet piece, which was
 sitting at infinity, was moved to 0.',
'Unfortunately, when the plane is inverted, you can no longer walk to 0 in a
 finite time.',
'This is where my third statement comes in:\ what effect you can have on the
 infinite plane.',
'Did you notice what happened when you landed on the plane?',
'It rippled.',
'You could probably recreate that rippling.',
'Say, by jumping.',
'Try jumping when the violet piece is at zero.',
'Notice what happened?',
'Everything on the plane hovered temporarily.',
'If you were to push the button while everything was floating...',
'Then the plane would invert without moving any items.',
'If you need exact instructions, read the next hint.',
'Set things up so that the violet piece is at zero. JUMP. PUSH WHITE BUTTON.
 You will then be able to walk to 0 and get the crystal.'
             ]
;

greenAh: ahPuzzle
    title = "What can I do in the collection of sloping rooms?"
    ahDesc = "green"
;
greenH: ahHintList
    owner = greenAh
    ahTell = [
'As a first step, walk in and out of the first sloping room you enter.',
'After a while, you will trip over a raised patch in the floor.',
'Feel that patch.',
'If you walk around all the sloped rooms, you\'ll find that they all have
 a raised patch.',
'You will also discover that each of the patches have a different texture.',
'And you will find that you can push the patches back into the floor.',
'Did you notice the white rectangle near the entrance?',
'Feel it.',
'It should suggest a course of action. Namely, "rough to smooth."',
'You need to press the roughest patch, then the next roughest, and so on until
 you push the smoothest patch last.',
'Or, you can read the next hint and get the explicit order.',
'Go to the rooms in the following order and press their patches:\ northwest,
 southwest, east, northeast, southeast, west.'
             ]
;

orangeAh: ahPuzzle
    title = "How can I get the orange piece out of the box it's in?"
    ahDesc = "orange"
;
orangeH: ahHintList
    owner = orangeAh
    ahTell = [
'The key to getting the orange piece lies in manipulating the box it\'s in
 using the panel beside it.',
'Play with the buttons on the panel. If you\'re feeling especially lucky,
 try the lever, but be prepared to UNDO.',
'The three buttons select among \(tr\), \(rot\), and \(inv\).',
'In other words, the three buttons select among three different operations on
 the box.',
'If the words \(tr\), \(rot\), and \(inv\) don\'t help, look at the plaque on
 the panel. The plaque describes what each operation does mathematically.',
'Also notice the lever, and how it has three positions (not counting the
 first).',
'The three positions on the lever correspond to the three buttons.',
'Whenever you pull the lever one position closer, the orange piece inside the
 box is altered according to the operation chosen by the corresponding
 button/display combination.',
'\(tr\) means \(translate\). As the plaque explains (albeit somewhat
 obscurely), the orange piece will be translated along the negative x axis,
 the positive y axis, and the positive z axis.',
'The x axis lies east-west; the y axis, north-south; the z axis, up-down.
 This means that the orange piece will be translated one shelf to the west,
 one shelf to the north, and one shelf up.',
'\(rot\) means \(rotate\). The orange piece will be rotated by -90 degrees
 about some axis.',
'The pole defines the origin. Thus the orange piece will be rotated 90
 degrees clockwise around the pole.',
'\(inv\) means \(invert\). The orange piece and the box will flip inside-out
 about the middle of the box.',
'The short of it (too late!) is:\ you must pick the order in which the
 operations are carried out and place the orange piece on the proper shelf
 inside the box so that, when you\'ve pulled the lever all the way towards
 you, the orange piece is outside the box.',
'Hint:\ the inverse function will leave the orange piece outside the box if
 it is on the proper shelf. In this case the proper shelf is the center
 shelf.',
'What follows is a step-by-step explanation of how to solve this puzzle.',
'Put the orange piece on the bottom middle shelf. Select \(tr\) for the first
 operation, \(rot\) for the second, and \(inv\) for the third. Then pull the
 lever thrice.'
             ]
;

yellowAh: ahPuzzle
    title = "I have to admit, this huge granite cube has me stumped."
    ahDesc = "yellow"
;
beltClueAh: ahClue
    ahDesc = "seen belt";
sounderClueAh: ahClue
    ahDesc = "gotten sounder";
yellowH1: ahHint
    owner = yellowAh
    ahAvail = { return (!beltClueAh.seen); }
    ahTell = "You need to walk around the cube some more before I can help.
        There\'s something you need to find. "
;
yellowH2: ahHintList
    owner = yellowAh
    ahAvail = { return (beltClueAh.seen); }
    ahTell = [
'The belt is a big clue as to what you should do.',
'Experiment with the belt while wearing it.',
'There are four knobs which move you around while you\'re wearing the belt.',
'The red knob moves you east-west, the green knob moves you north-south,
 the blue knob moves you up-down...',
'...and the grey knob moves you along a fourth dimension.',
'If you move a little ways away from the cube room along the fourth dimension,
 the cube will no longer be there.',
'You can then move into the space normally occupied by the cube.',
'If there\'s a hollow in the middle of the cube, you can enter it that way by
 turning the grey dial to, say, 613, then turning the other three dials to
 the location of the hollow, then turning the grey dial back to 612.',
'Thing is, you need to know if there is a hollow in the cube.'
             ]
;
yellowH3: ahHint
    owner = yellowAh
    ahAvail = { return (yellowH2.seen && !sounderClueAh.seen); }
    ahTell = "Remember that metal box you left in the tool shed in Fit the
        Third? You need it now. There's no way around it:\ you need to
        restore an old saved game. "
;
yellowH4: ahHintList
    owner = yellowAh
    ahAvail = { return (yellowH2.seen && sounderClueAh.seen); }
    ahTell = [
'The metal box from your father\'s tool shed will come in handy here.',
'Place it on the cube. It will analyze the cube and determine if there is a
 cavity in the cube and, if so, how deep.',
'Of course, it can only analyze the cube from one side at a time, so you\'ll
 have to put it on at least three of the cube\'s sides.',
'Once you have the readings, you\'re almost there. All you have to do is
 figure out what to set the dials to.',
'The first thing to realize is that zero on the red dial corresponds to
 all the way west, zero on the green dial corresponds to all the way south,
 zero on the blue dial corresponds to all the way down.',
'With some experimentation you can determine that the edges of the cube
 lie at 200 on each dial.',
'The edges of the cube run from 200 to 1200 on each dial. Since the cube is
 ten meters on a side, this means that the dials read in centimeters.',
'According to the documentation which came with the metal box, it gives its
 reading in millimeters, plus or minus 3 mm. You must round your readings to
 the nearest ten, then divide by ten to covert them to centimeters. Thus
 4103 is rounded down to 4100 and then converted to 410; 5768 is rounded up
 to 5770 and then converted to 577.',
'To finish your readings\' conversion to numbers on the dials, you need to add
 200 to each of your readings.',
'That is, assuming you took readings on the south face, the west face, and
 the bottom face of the cube.',
'So, to sum up:\ take a reading on the west face and convert it; that will be
 the number to which you will turn the red dial. Take a reading on the
 south face and convert it; that will be the number to which you will turn the
 green dial. Take a reading on the bottom face and convert it; that will be
 the number to which you turn the blue dial.',
'Turn the grey dial to, say, 613. Turn the red, green, and blue dials to the
 proper settings. Turn the grey dial to 612. You will be inside the cube.',
'Pick up the crystal piece you find and you\'re done.'
             ]
;

blueAh: ahPuzzle
    title = "Can you tell me what's going on with the box on the ceiling?"
    ahDesc = "blue"
;
blueH: ahHintList
    owner = blueAh
    ahTell = [
'Have you pressed the button on the box?',
'If the box were on the floor, you could open the box and retrieve the
 crystal piece without damaging it.',
'Try pushing the box towards one of the walls. Notice how it spins?',
'Push it to the floor and press its button.',
'Chances are, you\'ve gotten it to the floor with the button pointing in some
 direction other than up.',
'The object of this game is to get the box to the floor so that its button is
 pointing towards the ceiling. Then you can open the box without damaging the
 crystal.',
'You could experiment to find out how to do that...',
'...or you could push the box south, east, north, then down from its starting
 position.'
             ]
;

// Fit the Fourth, part b
frozenWomanAh: ahPuzzle
    title = "What can I do with the frozen woman?"
    ahDesc = "frozenWoman"
;
frozenWomanH: ahHint
    owner = frozenWomanAh
    ahTell = "Read her sign; do what it says. "
;

monkeysAh: ahPuzzle
    title = "The three monkeys are blocking my path."
    ahDesc = "monkeys"
;
evilClueAh: ahClue
    ahDesc = "gotten evil memory";
monkeysH1: ahHintList
    owner = monkeysAh
    ahTell = [
'Do you know the monkeys\' names?',
'See No Evil, Hear No Evil, Speak No Evil.',
'Given that they\'re supposed to avoid evil, you might be able to scare them
 away with evil.'
             ]
;
monkeysH2: ahHint
    owner = monkeysAh
    ahAvail = { return (monkeysH1.seen && !evilClueAh.seen); }
    ahTell = "Unfortunately, the most evil object you've run into you left
        lying in the Balance Room:\ the dark sphere. There's no help for it
        but to RESTORE. "
;
monkeysH3: ahHintList
    owner = monkeysAh
    ahAvail = { return (monkeysH1.seen && evilClueAh.seen); }
    ahTell = [
'I hope you still have that dark sphere from Fit the First.',
'If so, give it to the monkeys.'
             ]
;

dollsAh: ahPuzzle
    title = "I don't understand what to do with the Russian dolls."
    ahDesc = "dolls"
;
dollsH: ahHintList
    owner = dollsAh
    ahTell = [
'When you first are translated to the dolls, all of your possessions are taken
 from you.',
'They are replaced by a small doll.',
'Examine it. It looks openable.',
'Well, open it.',
'That\'s you in there.',
'The most notable feature of the smaller you is your eyes.',
'Stare down into them.',
'The smaller you (now the \(you\) you) is holding something.',
'It\'s a smaller, openable doll. Inside it is another, smaller you.',
'If you keep staring down into each of your doppelganger\'s eyes, you will
 find that there are five of you and five dolls, including the largest one
 which is holding all of you.',
'Right now you are fragmented. You need to put yourself and the dolls back
 together.',
'Start with the largest you. Open each doll, get the smaller you, and drop
 both the doll and the smaller you. Stare down. Continue until you are at
 the next-to-smallest you.',
'Get the smallest doll; close it and throw it into the large doll. Notice how
 the air above the doll seems to ripple?',
'While you\'re at it, get the smaller copy of yourself. When you\'ve done
 these two things, stare up.',
'Get the doll (the one you can pick up), close it, and throw it in the
 next-larger doll. Get the smaller copy of yourself. Stare up. Repeat until
 you are the largest you can be.',
'When you are the largest you can be, pick up your smaller copy and the
 remaining doll. Close that doll and drop it. Then you contain all the copies
 of yourself, and the doll contains all the copies of itself. Once you and the
 dolls are complete, you will be freed.'
             ]
;

chasmAh: ahPuzzle
    title = "Every time I try to cross the chasm, I can't."
    ahDesc = "chasm"
;
breakAh: ahClue
    ahDesc = "seen break room";
chasmH1: ahHint
    owner = chasmAh
    ahAvail = { return (!monkeysAh.solved); }
    ahTell = "You do not yet possess the means to cross the
        chasm. I suggest you concentrate on other things for now. "
;
chasmH2: ahHint
    owner = chasmAh
    ahAvail = { return (monkeysAh.solved && !breakAh.seen); }
    ahTell = "Before I give you any more hints, I suggest you explore this
        side of the cavern completely. "
;
chasmH3: ahHintList
    owner = chasmAh
    ahAvail = { return (monkeysAh.solved && breakAh.seen); }
    ahTell = [
'When you try to cross the chasm, your memories of hanging above the faerie
 cage prevent you. If you could somehow overcome those memories, you would be
 able to cross.',
'Have you played much with the sink in the break room?',
'It has two faucets, labeled "L" and "M".',
'Would it help if I told you that those letters stood for "Lethe" and
 "Mnemosyne"?',
'Lethe and Mnemosyne, according to Greek mythology, were two of the rivers in
 Hades. Lethe was the river of forgetfulness; Mnemosyne, the river of
 memories.',
'With every sip you take of Lethe\'s waters you forget more memories. When you
 drink of Mnemosyne\'s waters, you remember more than before.',
'Were you to take a drink of Lethe\'s waters, you would forget your recent
 troubles.',
'You would then be able to walk across the chasm unimpeded.'
             ]
;

getstrandsAh: ahPuzzle
    title = "What is that strange woman waiting for now?"
    ahDesc = "get strands"
;
getstrandsH: ahHintList
    owner = getstrandsAh
    ahTell = [
'Have you spent some time watching her?',
'She certainly seems intent on those floating strands.',
'In fact, she seems to want you to get one for her.',
'GET STRAND. GIVE STRAND TO WOMAN.'
             ]
;

givestrandsAh: ahPuzzle
    title = "Okay, I've given the woman some strands. What now?"
    ahDesc = "give strands"
;
weighedAh: ahClue
    ahDesc = "weighed strands";
givestrandsH1: ahHintList
    owner = givestrandsAh
    ahTell = [
'The woman goes from the hazy room to the room with the large balance.',
'Notice what she does when she gets to that room?',
'She moves to the balance.',
'A balance has two pans.',
'For comparing the weight of two things.',
'Say, two strands?',
'You need to give her two strands.'
             ]
;
givestrandsH2: ahHint
    owner = givestrandsAh
    ahAvail = { return (givestrandsH1.seen && !weighedAh.seen); }
    ahTell = "I won't have anything else to tell you until you do as I've
        suggested. Give the woman two strands. If you're still confused after
        that, then we'll talk. "
;
givestrandsH3: ahHintList
    owner = givestrandsAh
    ahAvail = { return (givestrandsH1.seen && weighedAh.seen); }
    ahTell = [
'The balance pan is measuring whether the two strands are the ones she needs.',
'If the balance balances, the two strands are correct.',
'What problem is the woman trying to solve with the strands?',
'She\'s trying to get the chains moving again.',
'So if the two strands you gave her related to that task...',
'...if the two strands were, say, the "chain" and "restart" strands...',
'Go back to the hazy room and get strands until you have the "chain" and
 "restart" strands. Then go give those two strands to the woman.'
             ]
;

drunkAh: ahPuzzle
    title = "Now that I'm drunk, I can't get out of the break room."
    ahDesc = "drunk"
;
drunkH: ahHintList
    owner = drunkAh
    ahTell = [
'There are two ways to get yourself out of the break room.',
'The first, and easiest, is to wait a few turns.',
'If the coffee spoons are anywhere in the room, they will give a little jump.',
'When they do, take them (if you don\'t already have them) or drop them (if
 you do). They will fan out into a line.',
'The direction in which they point is the way you should go.',
'WEST.',
'The second way to get out of the room involves the rope, which I hope you
 still have, and the knob on the archway. I\'ll leave the solution to that
 as an exercise for the reader.'
             ]
;

leaveAh: ahPuzzle
    title = "I'm ready to leave now, but I don't know how."
    ahDesc = "leave"
;
leaveH: ahHintList
    owner = leaveAh
    ahTell = [
'The woman left you two presents to help you out. She left them at the south
 end of the bridge.',
'The note is there to tell you which way to go.',
'There\'s only one place in the entire cavern where you can go down:\ on the
 bridge.',
'But you can\'t willingly jump. Even though your new-found fear of heights is
 repressed, you retain enough vestiges of it to keep you from willingly
 hurling yourself into the depths.',
'However, if your fear of heights was intensified, you might not be able to
 maintain your balance.',
'That\'s where the woman\'s second present helps.',
'You could fill the flask with water.',
'You could fill the flask with water which returns your memories.',
'If you fill the flask with water from the right spigot, walk out onto the
 bridge, and drink the water, your memories of dangling above the faerie
 cage will return. The shock will be enough to cause you to lose your balance
 and fall.'
             ]
;

cantLeaveAh: ahPuzzle
    title = "I fell off the bridge, but then I was back at the side of the
        chasm. What gives?"
    ahDesc = "can't leave"
;
cantLeaveH: ahHintList
    owner = cantLeaveAh
    ahTell = [
'You can\'t leave because you haven\'t done everything yet.',
'You still have to put yourself back together.',
'Remember the matruska doll? Go play with it for a while.',
'More specifically, OPEN DOLL.'
             ]
;

// Fit the Fifth
dadFinalAh: ahPuzzle
    title = "What do I do with my father?"
    ahDesc = "dadFinal"
;
dadFinalH: ahHintList
    owner = dadFinalAh
    ahTell = [
'Are you sure you wouldn\'t rather figure this one out on your own? It\'s the
 big finale.',
'Okay. There are two ways to handle the situation.',
'One:\ watch what he does to your dog.',
'He clenches one of his hands.',
'If you clench the same hand, you could duplicate the effect.',
'Two:\ let him have his way. Don\'t play by his rules.',
'If he is going to clench his hands, relax yours.'
             ]
;


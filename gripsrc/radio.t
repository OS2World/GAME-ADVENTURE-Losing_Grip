/*
    Radio, part of _Losing Your Grip_.
    Copyright (c) 1998, Stephen Granade. All rights reserved.
    $Id: radio.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

radioDaemon: object
    song = 1
    shuffling = nil
    playlist = &playlist1
    playlist1 = [
        'Peter Gabriel, "Digging in the Dirt."'
        'Rush, "Lock & Key."'
        'Pearl Jam\'s "Once."'
        '"Learning to Fly," by Pink Floyd.'
        'Emerson, Lake, and Palmer\'s version of "Jerusalem."'
        'Jars of Clay, "Lift Me Up."'
    ]
    playlist2 = [
        'REM, "Talk About the Passion."'
        'Tori Amos, "Pretty Good Year."'
        '"Hard Times" being performed by Eric Clapton.'
        '"Try Not To Breathe" by REM.'
        'Bjork\'s "Violently Happy."'
    ]
    playlist3 = [
        'Simon and Garfunkel singing "I Am A Rock,"'
        'The Smiths\' "How Soon is Now?"'
        '"Windmills," by Toad the Wet Sprocket,'
        'Blind Faith playing "Can\'t Find My Way Home,"'
        'Jimi Hendrix, "Castles Made of Sand,"'
    ]
    listendesc = {
        say(self.(playlist)[self.song]);
        if (self.shuffling) return;
        self.shuffling = true;
        notify(self, &nextSong, 2 + RAND(3));
    }
    nextSong = {
        self.song++;
        self.shuffling = nil;
        if (self.song > length(self.(playlist)))
            self.song = 1;
        if (Me.location == prep_room)
            "\bYou hear the song the radio has been playing end and a new one
                begin. ";
    }
;

recovery_radio: fixedItem
    stage = 1
    noun = 'radio' 'dial' 'knob'
    location = prep_room
    sdesc = "radio"
    ldesc = "The radio is softly playing music. Its only control is a knob
        on its face. "
    listendesc = { "The radio is playing <<radioDaemon.listendesc>> "; }
    verDoTurn(actor) = {
        "You turn the knob, expecting to hear the radio traverse several
            radio stations. Instead, the same song plays continuously,
            never deviating. ";
    }
;

recovery_music: intangible
    stage = 1
    noun = 'music'
    location = prep_room
    sdesc = "music"
    listendesc = { recovery_radio.listendesc; }
;

hospital_speaker: distantItem
    noun = 'speaker'
    location = admitting
    sdesc = "speaker"
    ldesc = "When you first worked here, only muzak issued from the speaker.
        Now, however, it is playing songs in their original versions. "
    listendesc = { "You hear <<radioDaemon.listendesc>> "; }
    verDoListenTo(actor) = {}
;

erins_headphones: fixedItem
    stage = '2b'
    noun = 'headphone' 'headphones' 'earphone' 'earphones' 'walkman' 'music'
    location = erin
    sdesc = "headphones"
    ldesc = "They are firmly planted on Erin's head. You can just hear
        the music Erin is listening to. "
    takedesc = "As you start to remove them, Erin jerks away and glares at
        you. "
    listendesc = { "You can barely make out <<radioDaemon.listendesc>> "; }
;

home_breeze: intangible
    stage = 3
    noun = 'music' 'breeze'
    location = front_of_house
    sdesc = "breeze"
    listendesc = {
        "You faintly hear <<radioDaemon.listendesc>>\ carried from a distant
            radio by the breeze. ";
    }
    smelldesc = "It smells of clover. "
    verDoTouch(actor) = {
        "The breeze rubs gently over your face and hands. ";
    }
;

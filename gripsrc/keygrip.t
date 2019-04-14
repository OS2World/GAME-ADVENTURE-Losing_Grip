/*
    KeyGrip.t (heh) contains functions for encoding a string for _Losing
    Your Grip_. This is for unlocking the built-in hints.
    Copyright (c) 1998, Stephen Granade. All Rights Reserved.
    $Id: keygrip.t,v 1.1 1998/02/02 01:17:48 sgranade Exp $
*/

#pragma C+

keyObj: object
    keyLetters = [ ' ', 'T', 'H', 'Q', 'U', '-', 'I', 'C', ',', 'K', 'B', 'N',
        'M', 'P', 'E', '*', '.', 'S', 'V', 'L', 'R', 'O', 'F', 'X', '!', 'J',
        'W', '?', 'A', '%', 'Z', 'Y', 'D', 'G' ]
    keyLen = 34
    // ctoi converts a character into an index offset for keyLetters
    ctoi(l) = {
        local i;
    
        for (i = 0; i < self.keyLen; i++)
            if (self.keyLetters[i+1] == l)
                return i;
    }
    // encode encodes a string, using a simple encoding scheme. I don't expect
    //  this to be super-secure; rather, it's a quick-and-dirty way of
    //  deterring the casual hacker. Given that a person's key is stored in a
    //  small file, it'd be much easier to copy the key file and pass it
    //  around than to break the code. Thus, I'm not wasting lots of time on
    //  the algorithm.
    // The algorithm: let S be the original str; let K be the encoded string.
    //     (S_n and K_n refer to the nth letter in the string)
    //  K_1 = keyLen - S_2 + S_1 + 1 modulo keyLen
    //  K_2 = K_1 - S_3 + S_2 + 2 % keyLen
    //  K_3 = K_2 - S_4 + S_3 + 3 % keyLen  &c.
    // For additional grins and chuckles, the key string's letters are
    //  on occasion converted to lowercase, since the encoding is case-
    //  insensitive.
    encode(str) = {
        local i, j, l, len, ltr1, ltr2, s, k = '';
        
        len = length(str);
        l = self.keyLen;
        s = upper(str);
        for (i = 1; i < len; i++) {
            ltr1 = substr(s, i, 1);
            ltr2 = substr(s, i+1, 1);
            j = l - self.ctoi(ltr2) + self.ctoi(ltr1) + i;
            while (j < 1) j += self.keyLen;
            while (j > self.keyLen) j -= self.keyLen;
            if (RAND(100) < 50)
                k += self.keyLetters[j];
            else k += lower(self.keyLetters[j]);
            l = j;
        }
        ltr1 = substr(s, len, 1);
        ltr2 = substr(s, 1, 1);
        j = l - self.ctoi(ltr2) + self.ctoi(ltr1) + len;
        while (j < 1) j += self.keyLen;
        while (j > self.keyLen) j -= self.keyLen;
        k += self.keyLetters[j];
        return k;
    }
    // Ennumber alternately adds and subtracts all the letters in a string
    //  (according to their index in keyLetters) and returns the value
    ennumber(str) = {
        local i, j, total, len, s;
        
        len = length(str);
        s = upper(str);
        j = 0;
        for (i = 1; i < len; i++) {
            if (i % 2 == 1)
                j += self.ctoi(substr(s, i, 1));
            else j -= self.ctoi(substr(s, i, 1));
        }
        return j;
    }
;

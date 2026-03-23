/*
Whistle for the Penalty Kicks Game with Wiring and Arduino.
See http://www.instructables.com/id/Soccer-Penalty-Kicks-Game-with-Wiring-and-Arduino/ for details.
-------------------
copyright : (C) 2013-2026 by Germán Carrillo
email : geotux_tuxman@linuxmail.org
----------------------------------------------------------------------------
----------------------------------------------------------------------------
* *
* This program is free software; you can redistribute it and/or modify *
* it under the terms of the GNU General Public License as published by *
* the Free Software Foundation; either version 2 of the License, or *
* (at your option) any later version. *
* *
----------------------------------------------------------------------------
*/

/*
  Based on: Melody - Plays a melody
  Circuit:
    * 8-ohm speaker on digital pin 8
  created 21 Jan 2010, modified 30 Aug 2011, by Tom Igoe
  This example code is in the public domain.
  http://arduino.cc/en/Tutorial/Tone
 */

#define NOTE_A3  220
#define NOTE_E4  330

// notes in the melody: LA MI
const int melody[] = {NOTE_A3, 0, NOTE_A3, 0, NOTE_A3, 0, NOTE_E4};
// note duration: 4 = quarter note, 8 = eighth note, etc.:
const int noteDurations[] = {2,2, 2,2, 2,2, 2};
const int numberOfNotes = 7;
const int PIEZO_PIN = 4; // 8 Arduino

const int RED_PIN = 0; // 9 Arduino
const int GREEN_PIN = 1; // 10 Arduino
const int BLUE_PIN = 2; // 11 Arduino

const int buttonPin = 3; // 12 Arduino
int buttonState = 0;

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  pinMode(buttonPin, INPUT);     
}

void loop() {
  buttonState = digitalRead(buttonPin);
  if (buttonState == HIGH) {     
    // iterate over the notes of the melody:
    for (int thisNote = 0; thisNote < numberOfNotes; thisNote++) {
  
      // to calculate the note duration, take one second
      // divided by the note type.
      //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
      int noteDuration = 1000/noteDurations[thisNote];
      
      tone(PIEZO_PIN, melody[thisNote], noteDuration);
      
      if (thisNote <= 5 && thisNote%2 == 0) {
        digitalWrite(RED_PIN, HIGH); // Red color
        digitalWrite(GREEN_PIN, LOW);
        digitalWrite(BLUE_PIN, LOW);      
      } else if (thisNote%2 == 1) { // When buzzer is silent, turn off the lights
        digitalWrite(RED_PIN, LOW);
        digitalWrite(GREEN_PIN, LOW);
        digitalWrite(BLUE_PIN, LOW);
      } else { // last note
        digitalWrite(RED_PIN, LOW);
        digitalWrite(GREEN_PIN, HIGH); // Green color
        digitalWrite(BLUE_PIN, LOW);
      }
      
      // Since notes are played asynchronously,
      // set a delay before next iteration.
      delay(noteDuration);
    }
    
    digitalWrite(RED_PIN, LOW);
    digitalWrite(GREEN_PIN, LOW);
    digitalWrite(BLUE_PIN, LOW);
  }
}

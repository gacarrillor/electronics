/*
SparkFun Inventor's Kit
Example sketch 13
Adjusted by: Germán Carrillo [gcarrillo@linuxmail.org]

SHIFT REGISTER

  Use a shift register to turn three pins into eight (or more!)
  outputs

  An integrated circuit ("IC"), or "chip", is a self-contained
  circuit built into a small plastic package. (If you look closely
  at your Arduino board you'll see a number of ICs.) There are
  thousands of different types of ICs available that you can use
  to perform many useful functions.

  The 74HC595 shift register in your kit is an IC that has eight
  digital outputs. To use these outputs, we'll use a new interface
  called SPI (Serial Peripheral Interface). It's like the TX and 
  RX you're used to, but has an additional "clock" line that 
  controls the speed of the data transfer. Many parts use SPI
  for communications, so the Arduino offers simple commands called
  shiftIn() and shiftOut() to access these parts.

  This IC lets you use three digital pins on your Arduino to
  control eight digital outputs on the chip. And if you need 
  even more outputs, you can daisy-chain multiple shift registers
  together, allowing an almost unlimited number of outputs from 
  the same three Arduino pins! See the shift register datasheet
  for details:
  
  http://www.sparkfun.com/datasheets/IC/SN74HC595.pdf

Hardware connections:

  Shift register:
  
    Plug in the chip so it bridges the center "canyon"
    on the breadboard.
    
    The shift register has 16 pins. They are numbered
    counterclockwise starting at the pin 1 mark (notch
    in the end of the chip). See the datasheet above
    for a diagram.

    74HC595 pin		LED pin		Arduino pin
    
    1  (QB)		LED 2 +
    2  (QC)		LED 3 +
    3  (QD)		LED 4 +
    4  (QE)		LED 5 +
    5  (QF)		LED 6 +
    6  (QG)		LED 7 +
    7  (QH)		LED 8 +
    8  (GND)				GND
    
    9  (QH*)
    10 (SRCLR*)				5V
    11 (SRCLK)				Digital 3
    12 (RCLK)				Digital 4
    13 (OE*)				GND
    14 (SER)				Digital 2
    15 (QA)		LED 1 +
    16 (VCC)				5V
  
  LEDs:
  
    After making the above connections to the positive (longer)
    legs of the LEDs, connect the negative side (short lead) of
    each LED to a 330 Ohm resistor, and connect the other side
    of each resistor to GND.
  
This sketch was written by SparkFun Electronics,
with lots of help from the Arduino community.
This code is completely free for any use.
Visit http://learn.sparkfun.com/products/2 for SIK information.
Visit http://www.arduino.cc to learn about the Arduino.

Version 2.0 6/2012 MDG
*/

// Pin definitions:
// The 74HC595 uses a type of serial connection called SPI
// (Serial Peripheral Interface) that requires three pins:

const int datapin = 12;
const int clockpin = 7;
const int latchpin = 8;
const int inputpin = 5;

// Some constants to help us iterate button and LED pins,
// as well as to associate buttons to LEDs.
//
// We'll use all 8 pins from 1st SR and 3 pins from the 2nd one
// for LEDs. The other 5 pins from the 2nd SR, as well as the 
// first 7 pins of the 3rd SR are used for buttons.
//
// In summary, we use 11 LEDs and 12 buttons. This is just for
// a specific use case where each button has a corresponding LED,
// but there is another button that triggers another action and
// does not have a corresponging LED. Adjust it as required by
// your own use case.
const int MAX_PIN_INDEX = 22, MAX_LED_INDEX = 10, MAX_BUTTON_INDEX = MAX_PIN_INDEX;
const int ledPins[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
const int buttonPins[] = {11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22};
const int ledFromButton[] = {0,1,2,3,4,5,6,7,8,9,10,-1}; // note 22 is not assigned to a LED

// We'll also declare global variables for the data we're
// sending to the shift register:
byte dataSR1 = 0, dataSR2 = 0, dataSR3 = 0;


void setup()
{
  // Set the three SPI pins to be outputs:
  pinMode(datapin, OUTPUT);
  pinMode(clockpin, OUTPUT);  
  pinMode(latchpin, OUTPUT);

  pinMode(inputpin, INPUT);
  //Serial.begin(9600);
  //Serial.println("Set up!...");

  //allHigh();  // Use this for first tests
  setAllLEDs(HIGH); // Just to let users know the control starts receiving...
  delay(500);
  initializeLEDsAndButtons();
}


void loop()
{
  if (digitalRead(inputpin) == HIGH){
    //Serial.println("HIGH");
    lightLED(getLEDfromButton(getPressedButton()));
    delay(5);
  }
}


void shiftWrite(int desiredPin, boolean desiredState, boolean write)

// This function lets you make the shift register outputs
// HIGH or LOW in exactly the same way that you use digitalWrite().

// This function takes 3 parameters:

//    "desiredPin" is the shift register output pin
//    you want to affect (0-7 for the SR1, 8-15 for SR2,
//    and 15-22 for SR3)

//    "desiredState" is whether you want that output
//    to be HIGH or LOW

//    "write" is whether you only want to set data variables (false)
//    or you actually want to write to the SRs. This helps us avoid
//    intermediate and unnecesary writes while iterating values.

// Inside the Arduino, numbers are stored as arrays of "bits",
// each of which is a single 1 or 0 value. Because a "byte" type
// is also eight bits, we'll use a byte (which we named "data"
// at the top of this sketch) to send data to the shift register.
// If a bit in the byte is "1", the output will be HIGH. If the bit
// is "0", the output will be LOW.

// To turn the individual bits in "data" on and off, we'll use
// a new Arduino commands called bitWrite(), which can make
// individual bits in a number 1 or 0.
{
  // Translate global desiredPin to an index in its SR's
  int shiftRegisterIndex = desiredPin / 8;
  desiredPin = desiredPin - 8 * shiftRegisterIndex;  // 17 --> 17 - 8 * 2 --> 1

  switch (shiftRegisterIndex){  // integer division, we get the floor value (e.g., 7/8 = 0)
    case 0:
      bitWrite(dataSR1, desiredPin, desiredState);
      break;
    case 1:
      bitWrite(dataSR2, desiredPin, desiredState);
      break;
    case 2:
      bitWrite(dataSR3, desiredPin, desiredState);
      break;
    default:
      Serial.print("[ERROR] The desiredPin is out f range: ");
      Serial.println(desiredPin + 8 * shiftRegisterIndex);
  }

  // It might be the case of only modifying dataSRs variables and
  // not sending the data to the SR nor latching.
  // This is specially useful while setting all index states, and
  // only being interested in actually writting (send and latch) in 
  // the last index.
  if (write){
    // Now we'll actually send that data to the shift register.
    // The shiftOut() function does all the hard work of
    // manipulating the data and clock pins to move the data
    // into the shift register:
    // Serial.println(dataSR1);
    // Serial.println(dataSR2);
    // Serial.println(dataSR3);
    shiftOut(datapin, clockpin, MSBFIRST, dataSR3);
    shiftOut(datapin, clockpin, MSBFIRST, dataSR2);
    shiftOut(datapin, clockpin, MSBFIRST, dataSR1);

    // Once the data is in the shift register, we still need to
    // make it appear at the outputs. We'll toggle the state of
    // the latchPin, which will signal the shift register to "latch"
    // the data to the outputs. (Latch activates on the high-to
    // -low transition).

    digitalWrite(latchpin, HIGH);
    digitalWrite(latchpin, LOW);
  }
}


void allHigh(){
  for(int index = 0; index <= MAX_PIN_INDEX; index++)
  {
    shiftWrite(index, HIGH, index == MAX_PIN_INDEX);          
  }
}

void setAllLEDs(boolean state){
  for (int index : ledPins)
    shiftWrite(index, state, index == MAX_LED_INDEX);
}

void setAllButtons(boolean state){
  for (int index : buttonPins)
    shiftWrite(index, state, index == MAX_BUTTON_INDEX);
}

void initializeLEDsAndButtons(){
  setAllLEDs(LOW);
  setAllButtons(HIGH);
}

int getLEDfromButton(int buttonIndex){
  int ledIndex = -1;
  if (buttonIndex != -1) {
    for (int i = 0; i <= sizeof(buttonPins) / sizeof(buttonPins[0]); i++){
      if (buttonPins[i] == buttonIndex){
        ledIndex = ledFromButton[i];
        break;
      }
    }
  } 
  return ledIndex;
}

int getPressedButton(){
  int buttonIndex = -1;
  delay(50);
  setAllButtons(LOW); // To iterate buttons and get the one pressed
  
  for(int index : buttonPins){
    shiftWrite(index, HIGH, true);
    delayMicroseconds(500);
    if(digitalRead(inputpin) == HIGH){
        buttonIndex = index;  // We've got the button
        break;
    }
    shiftWrite(index, LOW, true);  // Prepare for the next iteration
  }

  setAllButtons(HIGH); //Initialize to HIGH to continue reading buttons
  return buttonIndex;
}

void lightLED(int index){
  if (index != -1){
    setAllLEDs(LOW); // First, turn all LEDs off
    shiftWrite(index, HIGH, true);
    Serial.print("LED on: ");
    Serial.println(index);
  }
  else {
    Serial.print("LED index is -1, don't do anything...");
  }
}


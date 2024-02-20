/*
  Programa para simular movimientos de un arquero en lanzamientos de tiro penal
  En total hay 10 movimientos, dependiendo de la zona del arco que se quiera cubrir.
  
  Dichos 10 movimientos del arquero corresponden a combinaciones de 3 movimientos 
  independientes controlados a traves de Arduino: Un movimiento de rotación del 
  arquero sobre su cadera, un movimiento de traslación horizontal para dirigirse 
  hacia los palos, y un movimiento vertical para simular el salto.

  Copyright: (C) 2013 by Germán Carrillo
  E-mail: gcarrillo [at] linuxmail [dot] org
  URL: https://www.instructables.com/Soccer-Penalty-Kicks-Game-with-Wiring-and-Arduino
*/
#include <Servo.h>  // servo library

const bool DEBUG = true;

/*      C     O     N     T     R     O     L       */

const int dataPin = 12; //pin 14 on the 75HC595  8
const int latchPin = 8; //pin 12 on the 75HC595  9
const int clockPin = 7; //pin 11 on the 75HC595 10
const int inputPin = 5; //To read buttons from 75HC595

  /* Pos _______________           LEDs   _______________           Botones _______________           
        | A  B  C  D  E |                | 5  8  4  2  0 |                | 22 20 18 16 14 |          
        | F  G  H  I  J |                | 6  9 10  3  1 |                | 21 19 17 15 12 |
    =========================        =========================        =========================  
           R        Y                        7                                13       11
  
    Note: Pin numbers refer to 3 SRs in series (0-7, 8-15, 16-22). Pin 23 is not used.
  */
const char posiciones[12] = {'A','B','C','D','E','F','G','H','I','J','R','Y'};
const char LEDs[11] = {6,10,5,3,1,7,11,12,4,2,9};

const int MAX_PIN_INDEX = 22, MAX_LED_INDEX = 10, MAX_BUTTON_INDEX = MAX_PIN_INDEX;
const int ledPins[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
const int buttonPins[] = {11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22};
const int ledFromButton[] = {-1, 1, 7, 0, 3, 2, 10, 4, 9, 8, 6, 5}; // note 11 is not assigned to a LED
const char posFromButton[] = {'Y', 'J', 'R', 'E', 'I', 'D', 'H', 'C', 'G', 'B', 'F', 'A'};
byte dataSR1 = 0, dataSR2 = 0, dataSR3 = 0; // Data to be written to SRs
int pressedButtonPin;

// Constantes velocidad del motor y tiempo (milisegundos)
const int MAX_VEL = 255;
const int IZQIZQARR_TIE = 460;
const int IZQARR_TIE = 250;
const int DERARR_TIE = 250;
const int DERDERARR_TIE = 435;
const int IZQIZQABA_TIE = 460;
const int IZQABA_TIE = 250;
const int DERABA_TIE = 250;
const int DERDERABA_TIE = 435;

char posicion = 'Z'; // Initialize to unknown position
char posicionTemp; 
boolean bLeyendo = false; // Es true si se estan leyendo valores al presionar un botón


/*     M O V    H O R I Z O N T A L   Y   R O T A C I O N    */

// Toggle Switch
const int switchPin = 2;   // Toggle Switch

// Potenciómetro
int const potenciometroPin = 0;  // Pin analógico al cual se conecta el potenciômetro
int valPotenciometro;            // Variable usada para almacenar el valor del pot.

/*       Motor DC
  Arduino          L293D
  ------------------------
  Pin 6            Pin 1
  Pin 3            Pin 2
  Pin 4            Pin 7
*/
const int pinEntrada1 = 3; // Input 1 de L293D
const int pinEntrada2 = 4; // Input 2 de L293D
const int pinVelocidad = 6;

// Servo
Servo servo1;  // Servo control object
const int pinServo = 9;

// Otros (mostly DEBUG or tests)
boolean reversa;
int speed;         // Para la funcion serialSpeed
char serialPos;    // Para la funcion serialPosicion
boolean botonPresionado = true;  // Bandera para evitar multiples estiradas del arquero


/*     M O V    V E R T I C A L   */

Servo servo2;  // servo control object for pin 10
Servo servo3;  // servo control object for pin 11

const int amplitudServosV = 95;  // Máximo de grados que los servos se desplazan


void setup() {
  pinMode(dataPin, OUTPUT);
  pinMode(clockPin, OUTPUT);  
  pinMode(latchPin, OUTPUT);
  pinMode(inputPin, INPUT);
  if (DEBUG){Serial.begin(9600);}

  setAllLEDs(HIGH); // Just to let users know the control starts receiving...
  delay(500);
  initializeLEDsAndButtons();
 
  // Si el input analogo 3 esta desconectado, le da valores aleatorios a random 
  randomSeed(analogRead(3));
  
  pinMode(switchPin, INPUT);  // Set up the switchPin to be an input  
  pinMode(pinEntrada1, OUTPUT);  
  pinMode(pinEntrada2, OUTPUT);  
  pinMode(pinVelocidad, OUTPUT); 

  servo1.attach(pinServo);
  servo1.write(90);    // Tell servo to go to 90 degrees
  
  servo2.attach(10); // Mano izq. del arquero (desde atrás de él)
  servo3.attach(11);  

  inicializarArquero('H'); // Inicializar servos
}

void loop() {
  
  while (digitalRead(switchPin) == HIGH) {
    potCarretica();             // Potenciometro
    botonPresionado = true;
  }
  
  while (digitalRead(switchPin) == LOW) {
    //serialSpeed(); // Para calibrar
    //serialPosicion(); // Esta es la de a de veras
    leerControl();        
  }
}

/*F U N C I O N E S  M O V  H O R I Z O N T A L  Y  R O T A C I O N*/

void potCarretica() {
  valPotenciometro = analogRead(potenciometroPin);
  valPotenciometro = map(valPotenciometro, 0, 1023, -255, 255);
  valPotenciometro = constrain(valPotenciometro, -255, 255);
  
  if (valPotenciometro < 0){
    alistarHaciaDerecha();   
    valPotenciometro *= -1;
    reversa = true;
  } else if (valPotenciometro > 0){
    alistarHaciaIzquierda();
    reversa = false;
  }
  
  if (valPotenciometro < 50){
    
    analogWrite(pinVelocidad, 0); // Parar el motor
    if (DEBUG){Serial.println("Motor parado...");}
    
  } else {
    valPotenciometro = map(valPotenciometro, 50, 255, 170, 255);
    valPotenciometro = constrain(valPotenciometro, 170, 255);
    valPotenciometro = 255;
  
    analogWrite(pinVelocidad, valPotenciometro);
    if (DEBUG){
      if (reversa){
        Serial.print("Velocidad (R): ");
      } else {
        Serial.print("Velocidad:     ");
      }
      Serial.println(valPotenciometro);
    }
  }
  delay(100);
  analogWrite(pinVelocidad, 0); // Parar el motor
  delay(2000);

}

void serialSpeed() {
  /* Funcion para graduar la velocidad y el delay que se necesita para estirar el arquero */
  
  if (DEBUG){
    // First we check to see if incoming data is available:
    while (Serial.available() > 0) {

      // If it is, we'll use parseInt() to pull out any numbers:
      speed = Serial.parseInt();
      
      // Manejar numeros negativos para echar el motor hacia atras
      if (speed < 0) {
        alistarHaciaIzquierda();
        speed *= -1;
        reversa = true;
      } else {
        alistarHaciaDerecha();
        reversa = false;
      }

      // Because analogWrite() only works with numbers from
      // 0 to 255, we'll be sure the input is in that range:
      speed = constrain(speed, 0, 255);
      
      // We'll print out a message to let you know that the
      // number was received:
      Serial.print("Nueva velocidad: ");
      if (reversa) {
          Serial.print(speed);
          Serial.println(" (en reversa)"); 
      } else { 
        Serial.println(speed);
      }

      // And finally, we'll set the speed of the motor!
      analogWrite(pinVelocidad, speed);
      //digitalWrite(pinVelocidad, HIGH);
      delay(400);                // delay for onTime milliseconds
      analogWrite(pinVelocidad, 0);  // Parar el motor antes de cambiar modo
    }
  }
}

void alistarHaciaDerecha(){
  haciaAdelante();
}

void alistarHaciaIzquierda(){
  haciaAtras();
}

void haciaAdelante() {
  // Define la dirección del Motor DC hacia adelante a través del L293D
  digitalWrite(pinEntrada1,LOW);
  digitalWrite(pinEntrada2,HIGH);
}

void haciaAtras() {
  // Define la dirección del Motor DC hacia atrás a través del L293D
  digitalWrite(pinEntrada1,HIGH);
  digitalWrite(pinEntrada2,LOW);
}

void serialPosicion() {
  /* Funcion para recibir posición y estirar el arquero hacia allá */
  
  if (DEBUG){
    // First we check to see if incoming data is available:
    while (Serial.available() > 0) {

      serialPos = Serial.read();
      
      Serial.print("Nueva posicion: ");
      Serial.println(serialPos);
      
      if (botonPresionado){
        botonPresionado = false;
        estirarArquero(serialPos);
        delay(5000);
        if (serialPos == 'A' || serialPos == 'B' || serialPos == 'C' || serialPos == 'D' || serialPos == 'E'){
          inicializarArquero('C');
        } else {
          inicializarArquero('H');
        }
      }
    }
  }
}


/*  F U N C I O N E S   C O N T R O  L  */

void leerControl(){

  if (digitalRead(inputPin) == HIGH){
    pressedButtonPin = getPressedButton();
    posicionTemp = obtenerPosicion(pressedButtonPin);

    switch (posicionTemp){
      case 'Y':
        if (posicion != 'Z'){
          // Estirar arquero a la posicion almacenada con anterioridad
          estirarArquero(posicion);
          setAllLEDs(LOW);

          if (DEBUG){
            Serial.print("Se estira el arquero a la posicion...");
            Serial.println(posicion);
          }
          delay(4000);

          inicializarArquero(posicion);
        }
        else {
          if (DEBUG){Serial.println("El arquero no ha elegido una posición para estirarse!");}
        }
        break;

      case 'R':
        // Elegir posición aleatoriamente y almacenarla hasta que se presione el botón 'Y'
        posicion = posiciones[random(10)];
        while (posicion == 'H'){ // Descartar el centro como opción para el mov. aleatorio
          posicion = posiciones[random(10)];
        }
        lightLED(getLEDfromButton(pressedButtonPin));
        if (DEBUG) {Serial.println("Elegir region aleatoriamente...");}
        break;

      case 'N':
        if (DEBUG){Serial.println("Se obtuvo una posición errada con la lectura...");}
        break;

      default: // A valid position (A-J)
        // Almacenar nueva posición y prender su LED correspondiente
        posicion = posicionTemp;
        lightLED(getLEDfromButton(pressedButtonPin));
        if (DEBUG){
          Serial.print("Se ha presionado el botón de la posición...");
          Serial.println(posicion);
        }
    }

    delay(5);
  }
}

char obtenerPosicion(int pressedButtonPin) {
  // Devolver la posición del botón presionado
  return getPosfromButton(pressedButtonPin);
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
      if (DEBUG){
        Serial.print("[ERROR] The desiredPin is out f range: ");
        Serial.println(desiredPin + 8 * shiftRegisterIndex);
      }
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
    shiftOut(dataPin, clockPin, MSBFIRST, dataSR3);
    shiftOut(dataPin, clockPin, MSBFIRST, dataSR2);
    shiftOut(dataPin, clockPin, MSBFIRST, dataSR1);

    // Once the data is in the shift register, we still need to
    // make it appear at the outputs. We'll toggle the state of
    // the latchPin, which will signal the shift register to "latch"
    // the data to the outputs. (Latch activates on the high-to
    // -low transition).

    digitalWrite(latchPin, HIGH);
    digitalWrite(latchPin, LOW);
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

int getLEDfromButton(int buttonPin){
  int ledPin = -1;
  if (buttonPin != -1) {
    for (int i = 0; i <= sizeof(buttonPins) / sizeof(buttonPins[0]); i++){
      if (buttonPins[i] == buttonPin){
        ledPin = ledFromButton[i];
        break;
      }
    }
  } 
  return ledPin;
}

char getPosfromButton(int buttonPin){
  char pos = 'N';
  if (buttonPin != -1) {
    for (int i = 0; i <= sizeof(buttonPins) / sizeof(buttonPins[0]); i++){
      if (buttonPins[i] == buttonPin){
        pos = posFromButton[i];
        break;
      }
    }
  } 
  return pos;
}

int getPressedButton(){
  int buttonPin = -1;
  delay(50);
  setAllButtons(LOW);

  for(int index : buttonPins){
    shiftWrite(index, HIGH, true);
    delayMicroseconds(500);

    if(digitalRead(inputPin) == HIGH){
        buttonPin = index;
        break;
    }
    shiftWrite(index, LOW, true);  // Better than iterating buttons to set them all OFF
  }

  setAllButtons(HIGH); //Initialize to HIGH to continue reading buttons
  return buttonPin;
}

void lightLED(int index){
  if (index != -1){
    setAllLEDs(LOW); // First, turn all LEDs off
    shiftWrite(index, HIGH, true);
    if (DEBUG){
      Serial.print("LED on: ");
      Serial.println(index);
    }
  }
  else {
    if (DEBUG){Serial.print("LED index is -1, don't do anything...");}
  }
}





void estirarArquero(char pos) {
  moverAPosicion(pos);  
}

void moverAPosicion(char pos) {
  /*     _______________
        | A  B  C  D  E |
        | F  G  H  I  J |
    =========================
  */
  
  switch (pos) {
    case 'A':  // Izq-Izq-Arr
      izqIzqArr();
      break;
    case 'B':  // Izq-Arr
      izqArr();
      break;
    case 'C':  // Arr
      arr();
      break;
    case 'D':  // Der-Arr
      derArr();
      break;
    case 'E':  // Der-Der-Arr
      derDerArr();
      break;
    case 'F':  // Izq-Izq-Aba    
      izqIzqAba();      
      break;
    case 'G':  // Izq-Aba
      izqAba();
      break;
    case 'H':  // Quieto
      quieto();
      break;
    case 'I':  // Der-Aba
      derAba();
      break;
    case 'J':  // Der-Der-Aba
      derDerAba();
      break;    
  } 
}


void izqIzqArr() {       // A
  alistarHaciaIzquierda();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(35);    
  subir();
  delay(IZQIZQARR_TIE);                    // delay for some milliseconds  
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void izqArr() {          // B
  subir();
  alistarHaciaIzquierda();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(80); 
  delay(IZQARR_TIE);                    // delay for some milliseconds
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void arr() {             // C
  // Poleas arriba
  subir();
}

void derArr() {          // D
  subir();
  alistarHaciaDerecha();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(100);
  delay(DERARR_TIE);                    // delay for some milliseconds
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void derDerArr() {       // E
  alistarHaciaDerecha();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(145);
  subir();  
  delay(DERDERARR_TIE);                    // delay for some milliseconds 
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void izqIzqAba() {       // F
  alistarHaciaIzquierda();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(10);    
  delay(IZQIZQABA_TIE);                    // delay for some milliseconds  
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void izqAba() {          // G
  alistarHaciaIzquierda();    
  analogWrite(pinVelocidad, MAX_VEL);
  delay(IZQABA_TIE);                    // delay for some milliseconds
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void quieto() {          // H
  // No haga nada
}

void derAba() {          // I
  alistarHaciaDerecha();    
  analogWrite(pinVelocidad, MAX_VEL);
  delay(DERABA_TIE);                    // delay for some milliseconds
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}

void derDerAba() {       // J
  alistarHaciaDerecha();    
  analogWrite(pinVelocidad, MAX_VEL);
  servo1.write(170);    
  delay(DERDERABA_TIE);                    // delay for some milliseconds 
  analogWrite(pinVelocidad, 0);  // Parar el motor 
}



void inicializarArquero(char pos) {
  String zona = "";
  switch (pos) {
    case 'A':  // Izq-Izq-Arr
      zona = "izqizqarr";
      break;
    case 'B':  // Izq-Arr
      zona = "izqarr";
      break;
    case 'C':  // Arr
      zona = "arr";
      break;
    case 'D':  // Der-Arr
      zona = "derarr";
      break;
    case 'E':  // Der-Der-Arr
      zona = "derderarr";
      break;
    case 'F':  // Izq-Izq-Aba    
      zona = "izqizqaba";    
      break;
    case 'G':  // Izq-Aba
      zona = "izqaba";
      break;
    case 'H':  // Quieto
      zona = "qui";
      break;
    case 'I':  // Der-Aba
      zona = "deraba";
      break;
    case 'J':  // Der-Der-Aba
      zona = "derderaba";
      break;    
  } 
  
  if (zona.endsWith("arr")) {
    bajar();    
    
    if (zona.startsWith("derder")) {
      alistarHaciaIzquierda();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(DERDERARR_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor 
    } else if (zona.startsWith("der")) {
      alistarHaciaIzquierda();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(DERARR_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor   
    } else if (zona.startsWith("izqizq")) {
      alistarHaciaDerecha();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(IZQIZQARR_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor 
    } else if (zona.startsWith("izq")) {
      alistarHaciaDerecha();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(IZQARR_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor   
    } 

    servo1.write(90);
    
  } else {
    inicializarServosMovVertical();   
    
    if (zona.startsWith("derder")) {
      alistarHaciaIzquierda();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(DERDERABA_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor 
    } else if (zona.startsWith("der")) {
      alistarHaciaIzquierda();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(DERABA_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor   
    } else if (zona.startsWith("izqizq")) {
      alistarHaciaDerecha();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(IZQIZQABA_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor 
    } else if (zona.startsWith("izq")) {
      alistarHaciaDerecha();    
      analogWrite(pinVelocidad, MAX_VEL);
      delay(IZQABA_TIE);                    // delay for some milliseconds  
      analogWrite(pinVelocidad, 0);  // Parar el motor   
    } 
    
    servo1.write(90);
  }
}

void inicializarServosMovVertical() {
  servo2.write(0);   
  servo3.write(180); 
}

void subir() {
  servo2.write(amplitudServosV);
  servo3.write(180-amplitudServosV);
}

void bajar() {
  for(int grados = amplitudServosV; grados >= 0; grados -= 2) {                                
    servo2.write(grados);  
    servo3.write(180-grados);  
    delay(20);               // Short pause to allow it to move
  }
}

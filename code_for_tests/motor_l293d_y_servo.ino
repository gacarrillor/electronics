/*
  Controlando un motor DC: Sentido y velocidad
  Controlando un servo motor
  
  Para el motor DC
        Arduino          L293D
        ------------------------
        Pin 6            Pin 1
        Pin 3            Pin 2
        Pin 4            Pin 7
  
*/

#include <Servo.h>  // servo library

// Pines para el Motor DC
const int pinEntrada1 = 3; // Input 1 de L293D (Pin 3 Arduino)
const int pinEntrada2 = 4; // Input 2 de L293D (Pin 3 Arduino)
const int pinVelocidad = 6;

// Pin y objeto para el servo
Servo servo1;  // Servo control object
const int pinServo = 9;

void setup()
{
  pinMode(pinEntrada1, OUTPUT);  
  pinMode(pinEntrada2, OUTPUT);  
  pinMode(pinVelocidad, OUTPUT);  
  
  servo1.attach(pinServo);
}

void loop()
{
  // Modos de operacion
  moverServo();
  //adelanteYAtras(255);
  //haciaAtras(255);
  //haciaAdelante(255);
}

void moverServo()
{
  servo1.write(0);    // Tell servo to go to 0 degrees
  delay(2000);         // Pause to get it time to move
  servo1.write(90);   // Tell servo to go to 90 degrees
  delay(2000);         // Pause to get it time to move
  servo1.write(180);     // Tell servo to go to 180 degrees
  delay(2000);         // Pause to get it time to move  
  
  servo1.write(90);    // Tell servo to go to 90 degrees
  delay(5500);         // Pause to get it time to move 
}

void adelanteYAtras(int velocidad)
{
  int onTimeAdelante = 700;  // milliseconds to turn the motor on  400
  int onTimeAtras = 400;  // milliseconds to turn the motor on     500
  int offTime = 5000; // milliseconds to turn the motor off

  /* 
    400 onTime --> Movimiento horizontal completo
    250 onTime --> Movimiento horizontal medio
  */
  
  haciaAdelante(50);
  haciaAdelante(velocidad);
  servo1.write(0);    // Tell servo to go to 0 degrees
  delay(onTimeAdelante);                // delay for onTime milliseconds
  
  parar();  // Parar el motor antes de cambiar modo
  servo1.write(90);   // Tell servo to go to 90 degrees
  delay(1500);                // delay for onTime milliseconds

  haciaAtras(50);
  haciaAtras(velocidad);
  servo1.write(180);     // Tell servo to go to 180 degrees
  delay(onTimeAtras);                // delay for onTime milliseconds
  
  parar();  // Parar el motor antes de cambiar modo
  servo1.write(90);    // Tell servo to go to 90 degrees
  delay(offTime);               // delay for offTime milliseconds
}

void haciaAdelante(int velocidad)
{
  digitalWrite(pinEntrada1,LOW);
  digitalWrite(pinEntrada2,HIGH);
  analogWrite(pinVelocidad, velocidad);
}

void haciaAtras(int velocidad)
{
  digitalWrite(pinEntrada1,HIGH);
  digitalWrite(pinEntrada2,LOW);
  analogWrite(pinVelocidad, velocidad);
}

void parar()
{
  analogWrite(pinVelocidad, 0);
}

/*
   Controlando dos servos para enrollar pita (van en direccion opuesta)
*/

#include <Servo.h>  // servo library

Servo servo2;  // servo control object for pin 10
Servo servo3;  // servo control object for pin 11

const int amplitudServosV = 95;

void setup()
{
  servo2.attach(10);
  servo3.attach(11);
  
  inicializarServosMovVertical();
}

void loop()
{
  delay(1000);         // Pause to get it time to move
  //subir();
  delay(5000);         // Pause to get it time to move
  //bajar();
  //inicializarServosMovVertical();
  delay(15000);
/*
  servo2.write(180);
  delay(3000);
  servo2.write(0);
  delay(3000);*/
  
}

void inicializarServosMovVertical()
{
  servo2.write(0);   
  servo3.write(180); 
}

void subir()
{
  servo2.write(0+amplitudServosV);
  servo3.write(180-amplitudServosV);
/*  for(int position = 0; position <= 180; position += 2)
  {
    servo2.write(position);  
    servo3.write(180-position);
    delay(20);               // Short pause to allow it to move
  }*/
}

void bajar()
{
  for(int position = amplitudServosV; position >= 0; position -= 2)
  {                                
    servo2.write(position);  
    servo3.write(180-position);  
    delay(20);               // Short pause to allow it to move
  }
}

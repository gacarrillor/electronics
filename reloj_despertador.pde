/*
  German Carrillo, Marzo de 2015
  gcarrillo [at] linuxmail.org
  Compartido bajo licencia GPL v.2.0
*/

#include <LiquidCrystal.h>
#include <myDS3231.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>                      
#include <TMRpcm.h>
#include <EEPROM.h>
#include <avr/pgmspace.h> 

// ***** AUDIO *****
TMRpcm tmrpcm;   

// ***** CLOCK *****
myDS3231 Clock;
bool f=false;
byte second,minute,hour,date,month,year,dow;
bool bIsHoliday=false;
const char* festivos[]={"150518","150608","150615","150629","150817","151012","151102","151116","151208","160111","160321","160324","160325","160509","160530","160606","160704","160815","161017","161107","161114","161208","170109","170320","170413","170414","170529","170619","170626","170703","170821","171016","171106","171113","171208","180108","180319","180329","180330","180514","180604","180611","180702","180820","181015","181105","181112","181208","190107","190325","190418","190419","190603","190624","190701","190819","191014","191104","191111","191208","200106","200323","200409","200410","200525","200615","200622","200629","200817","201012","201102","201116","201208","210111","210322","210401","210402","210517","210607","210614","210705","210816","211018","211101","211115","211208","220110","220321","220414","220415","220530","220620","220627","220704","220815","221017","221107","221114","221208","230109","230320","230406","230407","230522","230612","230619","230703","230821","231016","231106","231113","231208","240108","240325","240328","240329","240513","240603","240610","240701","240819","241014","241104","241111","241208","250106","250324","250417","250418","250602","250623","250630","250818","251013","251103","251117","251208","260112","260323","260402","260403","260518","260608","260615","260629","260817","261012","261102","261116","261208","270111","270322","270325","270326","270510","270531","270607","270705","270816","271018","271101","271115","271208","280110","280320","280413","280414","280529","280619","280626","280703","280821","281016","281106","281113","281208","290108","290319","290329","290330","290514","290604","290611","290702","290820","291015","291105","291112","291208","300107","300325","300418","300419","300603","300624","300701","300819","301014","301104","301111","301208"};

// ***** LCD *****
LiquidCrystal lcd( 10,11,12,13,14,15 );
byte pinBacklight = 7;
bool bToggleBacklightWasPressed = false;
// Custom characters:
byte const heart[] PROGMEM = {0,10,31,31,31,14,4,0};
byte const smiley[] PROGMEM= {0,0,10,0,0,17,14,0};
//byte const armsD[] PROGMEM= {0b00000,0b00100,0b01010,0b00100,0b01110,0b10101,0b00100,0b01010};
//byte const armsU[] PROGMEM= {0b00100,0b01010,0b00100,0b10101,0b01110,0b00100,0b00100,0b01010};
byte const bell[] PROGMEM= {0b00000,0b00100,0b01110,0b01110,0b01110,0b11111,0b00100,0b00000};
byte const pointAbove[] PROGMEM= {0b00000,0b01100,0b01100,0b00000,0b00000,0b00000,0b00000,0b00000};
byte const lNueva[] PROGMEM= {0,14,31,31,31,31,14,0};
byte const lCreciente[] PROGMEM= {0,12,24,24,24,24,12,0};
byte const lLlena[] PROGMEM= {0,14,17,17,17,17,14,0};
byte const lMenguante[] PROGMEM= {0,6,7,7,7,7,6,0};

// Key press  0:Right 1:Up 2:Down 3:Left 4:Select
int const keyVal[5] PROGMEM={100,250,400,600,800};
int kP=-1;//KeyPressed
int key=-1;
int oldkey=-1;

// ***** SETTINGS *****
// In edit mode, which setting are we going to edit?
// (For Alarms: 0:Enabled;1:Type;2:Hour;3:Minutes)
// (For Warning: 0:Enabled;1:Hour;2:Minutes)
// (For Clock: 0:Hour;1:Minutes;2:Seconds;3:Day;4:Date;5:Month;6:Year)
//int setting=0;
// Where should we locate the cursor, depending on the setting we are editing
int curAla[4][2]={{4,0},{0,1},{9,1},{12,1}}; //Cursor Alarm
int curWar[3][2]={{7,0},{10,1},{13,1}}; //Cursor Warning
int curClk[7][2]={{7,0},{10,0},{13,0},{0,1},{5,1},{8,1},{13,1}}; //Cursor Clock
const char a_0[] PROGMEM = "Lun-Vie";
const char a_1[] PROGMEM = "Una vez";
const char a_2[] PROGMEM = "F de Se";
const char a_3[] PROGMEM = "Diaria ";
const char* const tiposA[] PROGMEM = {a_0, a_1, a_2, a_3};
const char d_1[] PROGMEM = "Lunes";
const char d_2[] PROGMEM = "Marte";
const char d_3[] PROGMEM = "Mierc";
const char d_4[] PROGMEM = "Jueve";
const char d_5[] PROGMEM = "Viern";
const char d_6[] PROGMEM = "Sabad";
const char d_7[] PROGMEM = "Domin";
const char* const dias[] PROGMEM = {d_1, d_2, d_3, d_4, d_5, d_6, d_7};
const char m_1[] PROGMEM = "Enero";
const char m_2[] PROGMEM = "Febre";
const char m_3[] PROGMEM = "Marzo";
const char m_4[] PROGMEM = "Abril";
const char m_5[] PROGMEM = "Mayo ";
const char m_6[] PROGMEM = "Junio";
const char m_7[] PROGMEM = "Julio";
const char m_8[] PROGMEM = "Agost";
const char m_9[] PROGMEM = "Septi";
const char m_10[] PROGMEM = "Octub";
const char m_11[] PROGMEM = "Novie";
const char m_12[] PROGMEM = "Dicie";
const char* const meses[] PROGMEM = {m_1, m_2, m_3, m_4, m_5, m_6, m_7, m_8, m_9, m_10, m_11, m_12};
const char s_0[] PROGMEM = "Aviso: ";
const char s_1[] PROGMEM = "Sonar en ";
const char s_2[] PROGMEM = "Activa";
const char s_3[] PROGMEM = "Inactiva";
const char s_4[] PROGMEM = "Reloj: ";
const char s_5[] PROGMEM = "10 min?";
const char s_6[] PROGMEM = "Si";
const char s_7[] PROGMEM = "No";
const char* const strs[] PROGMEM = {s_0, s_1, s_2, s_3, s_4, s_5, s_6, s_7};
char bufS[10];

// ***** EEPROM *****
// For alarms and warning settings
const byte a1EnA = 100; // Address of the enabled variable for alarm1
const byte a1TyA = 101;
const byte a1HA = 102;
const byte a1MA = 103;
const byte a2EnA = 104; // Address of the enabled variable for alarm2
const byte a2TyA = 105;
const byte a2HA = 106;
const byte a2MA = 107;
const byte wEnA = 108; // Address of the enabled variable for warning
const byte wHA = 109;
const byte wMA = 110;

// ***** Msg *****
File myFile;
String msg;
byte lastD=255;
byte lastM=255;
byte lastY=255;
boolean bNewDay=true;
byte strStart=0;
byte strStop =14;
byte scrollCursor=2;
boolean bPrintMsg=false;
byte secsMsg=0;

// ***** Others *****
bool bIsAlOn = false; // A sound was triggered (prevent other sounds to be played for a while)
bool bIsAnAlarm = false; //The sound is an alarm (if alarm sound is stopped we show a dialog, other sounds are stopped and that's all)
byte secsAftA = 0;
byte secsToAvoidCollision = 60; // Time to wait before enabling other sounds to be played
unsigned int secsToW = 0;
boolean b10m = false; //Sonaren10?
byte moon=255;
byte toMoon=255;
char* audios[]={"mygirl.wav","smile.wav","libselva.wav","fprince.wav","nunusual.wav","mapale.wav","arriba.wav","birds1.wav","birds2.wav","birds3.wav","birds4.wav","birds5.wav","birds6.wav","birds7.wav","gallo.wav"};
unsigned long currMillis; // To async running
unsigned long prevMillis;
unsigned long en10Millis;

void setup(){
  currMillis = millis(); //store the time since startup as currentMillis
  prevMillis=currMillis;
  
  Wire.begin();
  initEEPROM();
  EEPROM.write(wEnA,0); //This should only be activated explicitly
  lcd.begin(16, 2);

  // Create new characters
  byte i;
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&heart[i]);
  lcd.createChar(0, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&smiley[i]);
  lcd.createChar(1, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&bell[i]);
  lcd.createChar(2, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&pointAbove[i]);
  lcd.createChar(3, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&lNueva[i]);
  lcd.createChar(4, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&lCreciente[i]);
  lcd.createChar(5, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&lLlena[i]);
  lcd.createChar(6, (byte*)bufS);
  for (i=0;i<8;i++) bufS[i]=pgm_read_byte(&lMenguante[i]);
  lcd.createChar(7, (byte*)bufS);
  
  //Initialize backlight pin
  pinMode(pinBacklight, OUTPUT);
  
  // Initialize audio and microSD
  pinMode(SS, OUTPUT);
  if (!SD.begin(SS)) {  // see if the card is present and can be initialized:
    return;   // don't do anything more if not
  }
  tmrpcm.speakerPin = 6; 
  ReadDS3231();
} 

void loop(){  
  currMillis = millis(); //store the time since startup as currMillis
  lcd.noCursor();

  if (currMillis-prevMillis>=1000){ // Run after a second
    prevMillis=currMillis;
    
    if (bNewDay and !bIsAlOn){//Read values for the new day
      // Read SD for messages
      myFile = SD.open((n2s(month)+n2s(date)).c_str()); // All years the same day
      lcd.setCursor(0,0); // debug
      lcd.print("A"); // debug
      if (!myFile)
        myFile = SD.open((n2s(year)+n2s(month)+n2s(date)).c_str()); // Diff day each year
      lcd.setCursor(0,0); // debug
      lcd.print("B"); // debug
      if (myFile){
        char buf[myFile.size()-1];
        myFile.read(buf,myFile.size()-1);
        myFile.close();
        msg = buf;
        msg=splitText(msg,';',0);
      }
      lcd.setCursor(0,0); // debug
      lcd.print("C"); // debug
      // Read moon phase
      moon = moonPhase(year,month,date);
      toMoon = toMoonPhase(year,month,date);
      // Read if it's holiday 
      bIsHoliday = isHoliday(year,month,date);
      bNewDay=false;
    }

    ReadDS3231(); //Read clock variables
    
    if (EEPROM.read(wEnA)) secsToW--; // Countdown to sound warning

    if ( !bIsAlOn and EEPROM.read(wEnA) ) shouldWarningSound();
    if ( !bIsAlOn and isAlarmEnabled(1) ) shouldAlarmSound(1,dow,year,month,date,hour,minute);
    if ( !bIsAlOn and isAlarmEnabled(2) ) shouldAlarmSound(2,dow,year,month,date,hour,minute);    

    if (minute == 0 and second == 0 and !bIsAlOn){ // En punto
      if (hour>22 or hour<8) tmrpcm.setVolume(0.1);
      else tmrpcm.setVolume(3.2);
      tmrpcm.play("sharp.wav");
      secsToAvoidCollision = 3;
      bIsAlOn=true;
      bIsAnAlarm=false;
    }
    if (hour==22 and minute == 1 and !bIsAlOn){ // Go to bed
      if (digitalRead(pinBacklight) == HIGH) { // If backlight is off we don't want the sound 
        tmrpcm.setVolume(2);
        tmrpcm.play(audios[date%2]); // 0 - 1: My Girl, Smile
        bIsAlOn=true;
        bIsAnAlarm=false; 
      }
    }
    
    // Handle the Backlight 
    if (((hour==22 and minute == 30) or (hour==6 and minute == 0)) and second == 0){
      bToggleBacklightWasPressed = false; // Overwrite/Initialize this flag
    }
    if (!bToggleBacklightWasPressed){
      if (hour>=22 or hour<6){  // Turn backlight off
        if (hour==22 and minute < 30){ 
          //Do nothing 
        } else if (digitalRead(pinBacklight) == HIGH) { 
          digitalWrite( pinBacklight, LOW ); 
        }
      }
      if (hour>=6 and hour<23){ // Turn backlight on
        if (hour==22 and minute >= 30){
          // Do nothing
        } else if (digitalRead(pinBacklight) == LOW) { 
          digitalWrite( pinBacklight, HIGH ); 
        }
      }
    }
    
    if ( bIsAlOn ) {// Alarm was triggered, avoid triggering it again for this minute
      if (secsAftA == secsToAvoidCollision){ 
        bIsAlOn=false; 
        secsAftA = 0;
        tmrpcm.setVolume(0.1); // Be quiet when idle
        secsToAvoidCollision = 60; //Reset this to the default
      } else secsAftA++; 
    }
  }  
    
  if (currMillis-prevMillis>=150){ // Run after a while

    kP=getKeyPressed();
    shouldSoundStop();
    shouldToggleBackLight();
    
    // Settings
    configWarning();
    configAlarm(1);
    configAlarm(2);
    configClock();
  }
  
  if (b10m){
    if (currMillis-en10Millis>=600000 and !bIsAlOn){ //10m   600000
      tmrpcm.setVolume(2);
      tmrpcm.play(audios[date%5+2]); // 2 - 6: libselva, fprince, nunusual, mapale, arriba
      bIsAlOn=true;
      b10m=false;
    }
  }
}

void ReadDS3231(){
  second=Clock.getSecond();
  minute=Clock.getMinute();
  hour=Clock.getHour(f, f);
  date=Clock.getDate();
  month=Clock.getMonth(f);
  year=Clock.getYear();
  dow = Clock.getDoW();
  
  if (date!=lastD or month!=lastM or year!=lastY){// New day
    lastD=date;
    lastY=year;
    lastM=month;
    bNewDay=true; //We need to read SD msg, moon phase, and isHoliday again
    //Initialize some variables
    msg="";
    moon=255;
    bIsHoliday=false;
    strStart=0; // We'll be showing another msg, init scroll vars
    strStop=14;
    scrollCursor=2;
  }
  
  lcd.clear();
//  print1();
  print2();
  print1();  
}
void print1(){
  lcd.setCursor(0, 0);
  if (isAlarmEnabled(1)){lcd.write(2);} //bell 
  else lcd.print(" ");
  lcd.setCursor(1, 0);
  if (isAlarmEnabled(2)){lcd.write(2);} //bell 
  else lcd.print(" ");
  lcd.setCursor(2, 0);
  lcd.write(byte(0)); // Corazon
  lcd.print(' '+n2s(hour)+":"+n2s(minute)+":"+n2s(second)+' ');
  lcd.write(byte(0)); // Corazon
  lcd.setCursor(14, 0);
  if (b10m){lcd.write(1);} //Smiley 
  lcd.setCursor(15, 0);
  if (EEPROM.read(wEnA)){lcd.print((char)239);} //:O 
}
void print2(){
  if (msg==""){ //Siempre fecha
    printFecha();
  } else { //Alternar msg y fecha 
    if (secsMsg>=5){//Toggle
      if (bPrintMsg) bPrintMsg=false;
      else bPrintMsg=true;
      secsMsg=0;
    }
    if (bPrintMsg) printMsg();
    else {
      printFecha();    
      secsMsg++;
    }
  }
}
void printFecha(){
  lcd.setCursor(0, 1);  
  lcd.print(getDia(dow,true)+' '); // Day of the week
  lcd.print(date,DEC);
  lcd.print(' '+getMes(month,true)+' ');

  lcd.setCursor(14,1);  // Print how close are we are to moon phase
  if (moon!=255){
    if (toMoon==0){
      lcd.print((char)46);
    } else if (toMoon==1){
      lcd.print((char)165);
    } else {
      lcd.write(3); // pointAbove
    }
  }
  lcd.setCursor(15,1);
  if (moon!=255) lcd.write(moon);
}
void printMsg(){
  if (msg.length()>16){
    lcd.setCursor(scrollCursor, 1);
    lcd.print(msg.substring(strStart,strStop));
    if (scrollCursor>0) scrollCursor-=2;
    else {
      if (msg.length()-strStart>=14) strStart+=2;
      else { // Switch to fecha
        secsMsg=5; 
        strStart=0;
        strStop=14;
        scrollCursor=2;
      }
    }
    if (strStop < msg.length()) strStop+=2;
  } else { // msg corto
    lcd.setCursor(0, 1);
    lcd.print(msg);
    secsMsg++;
  }
}
String getDia(byte dow, boolean full){
  if (full)
    return strcpy_P(bufS, (char*)pgm_read_word(&(dias[dow-1]))); // PROGMEM read 
  else
    return String(strcpy_P(bufS, (char*)pgm_read_word(&(dias[dow-1])))).substring(0,4); // PROGMEM read 
}

String getMes(byte mes, boolean full){
  if (full)
    return strcpy_P(bufS, (char*)pgm_read_word(&(meses[mes-1]))); // PROGMEM read 
  else
    return String(strcpy_P(bufS, (char*)pgm_read_word(&(meses[mes-1])))).substring(0,4); // PROGMEM read 
}

// Convert ADC value to key number
int get_key(unsigned int in){
    int k;
    for (k=0; k<5; k++){
      if (in < pgm_read_word(&keyVal[k]))
        return k;
    }   
    if (k >= 5) k = -1;  // No valid key pressed
    return k;
}
/*byte get_key(unsigned int in){
    byte k;
    for (k=0; k<5; k++){
      if (in < pgm_read_word(&keyVal[k]))
        return k;
    }   
    if (k >= 5) k = 255;  // No valid key pressed
    return k;
}
byte getKeyPressed(){
   byte key=255;
   byte oldkey=255;
   key = get_key(analogRead(0));  // convert into key press
   if (key != oldkey){   // if keypress is detected
     delay(80);  // wait for debounce time
     key = get_key(analogRead(0));    // convert into key press
     if (key != oldkey){   
       oldkey = key;
       if (key<5){
         return key;
       }
     }
   }
   return 255;
}*/

int getKeyPressed(){
   key = get_key(analogRead(0));  // convert into key press
   if (key != oldkey){   // if keypress is detected
     delay(50);  // wait for debounce time
     key = get_key(analogRead(0));    // convert into key press
     if (key != oldkey){   
       oldkey = key;
       if (key >=0){
         return key;
       }
     }
   }
   return -1;
}

//********************************* W A R N I N G ***********************************************
void configWarning(){
  int setting=0;
  if (kP==4){ //Select 
    lcd.cursor();
    lcd.clear();
    printWarning();
    
    byte oldH, oldM, h, m; 
    oldH=EEPROM.read(wHA);
    oldM=EEPROM.read(wMA);
    h=oldH;
    m=oldM;
 
    setCur('w',setting);
    kP=getKeyPressed();
    while(kP!=4){ //!Select
      if (kP==0){ //Right
        if (setting<2) setting++;
        else setting=0; //Come back to start again
        setCur('w',setting);
      } else if (kP==1){ //Up
        lcd.clear();
        if (setting==0){
          toggleWarning();
        } else if (setting==1){
          if (h<23) h++; else h=0;
        } else if (setting==2){
          if (m<58) m+=2; else m-=58;
        }
        printWarning(h, m);
        setCur('w',setting);
      } else if (kP==2){ //Down
        lcd.clear();
        if (setting==0){
          toggleWarning();
        } else if (setting==1){
          if (h>0) h--; else h=23;
        } else {
          if (m>0) m--; else m=59;
        }
        printWarning(h, m);
        setCur('w',setting);
      } else if (kP==3){ //Left
        if (setting>0) setting--;
        else setting=2; //Come back to end again
        setCur('w',setting); 
      }
      kP=getKeyPressed();
    }
    // Write hours and minutes only once, regardless of multiple modifications
    if (h!=oldH) EEPROM.write(wHA,h); // was there any change in hours?
    if (m!=oldM) EEPROM.write(wMA,m); // was there any change in minutes?
    secsToW = h*3600 + m*60;
    lcd.clear();
  }
}
void toggleWarning(){
  if (EEPROM.read(wEnA)) EEPROM.write(wEnA,0);
  else EEPROM.write(wEnA,1);
}
void printWarning(){
  lcd.setCursor(0,0);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[0])))+b2s(EEPROM.read(wEnA)));
  lcd.setCursor(0,1);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[1]))));
  lcd.print(getWarningTime());
}
void printWarning(byte h, byte m){
  lcd.setCursor(0,0);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[0])))+b2s(EEPROM.read(wEnA)));
  lcd.setCursor(0,1);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[1]))));
  lcd.print(n2s(h)+":"+n2s(m));
}
String getWarningTime(){
  return n2s(EEPROM.read(wHA)) + ":" + n2s(EEPROM.read(wMA));
}
void shouldWarningSound(){
  if ( secsToW==0 ){
    tmrpcm.setVolume(3.8);
    tmrpcm.play("supero.wav");  
    EEPROM.write(wEnA,0);
    bIsAlOn=true;
    bIsAnAlarm=false;
  }
}

//********************************* A L A R M ***********************************************
void configAlarm(byte a){
  int setting=0;
  if (kP==4){ //Select 
    lcd.cursor();
    lcd.clear();
    printAlarm(a);
    
    byte oldH, oldM, h, m; 
    if (a==1){
      oldH=EEPROM.read(a1HA);
      oldM=EEPROM.read(a1MA);
    } else {
      oldH=EEPROM.read(a2HA);
      oldM=EEPROM.read(a2MA);
    }
    h=oldH;
    m=oldM;
 
    setCur('a',setting);
    kP=getKeyPressed();
    while(kP!=4){ //Select
      if (kP==0){ //Right
        if (setting<3) setting++;
        else setting=0; //Come back to start again
        setCur('a',setting);
      } else if (kP==1){ //Up
        lcd.clear();
        if (setting==0){
          toggleAlarm(a);
        } else if (setting==1) {
          nextAlarmType(a);
        } else if (setting==2){
          if (h<23) h++; else h=0;
        } else {
          if (m<55) m+=5; else m-=55;
        }
        printAlarm(a, h, m);
        setCur('a',setting);
      } else if (kP==2){ //Down
        lcd.clear();
        if (setting==0){
          toggleAlarm(a);
        } else if (setting==1) {
          prevAlarmType(a);
        } else if (setting==2){
          if (h>0) h--; else h=23;
        } else {
          if (m>0) m--; else m=59;
        }
        printAlarm(a, h, m);
        setCur('a',setting);
      } else if (kP==3){ //Left
        if (setting>0) setting--;
        else setting=3; //Come back to end again
        setCur('a',setting);
      }
      kP=getKeyPressed();
    }
    // Write hours and minutes only once, regardless of multiple modifications
    if (h!=oldH){ // was there any change in hours?
      if (a==1) EEPROM.write(a1HA,h);
      else EEPROM.write(a2HA,h);
    }
    if (m!=oldM){
      if (a==1) EEPROM.write(a1MA,m);
      else EEPROM.write(a2MA,m);
    }
    lcd.clear();
  }
}
bool isAlarmEnabled(byte alarm){
  if (alarm == 1) return bool( EEPROM.read(a1EnA) );
  else if (alarm == 2) return bool( EEPROM.read(a2EnA) );
  else return false; 
}
void setAlarmEnabled(byte alarm, byte enable){
  if (alarm == 1) EEPROM.write(a1EnA, enable);
  else if (alarm == 2) EEPROM.write(a2EnA, enable);
}
String getAlarmType(byte a){
  // PROGMEM read (alarm types from 0 to 3)
  if (a==1) return strcpy_P(bufS, (char*)pgm_read_word(&(tiposA[EEPROM.read(a1TyA)])));
  else if (a==2) return strcpy_P(bufS, (char*)pgm_read_word(&(tiposA[EEPROM.read(a2TyA)])));
  else return ""; 
}
void setAlarmType(byte a, char type[7]){
  for(byte i=0; i<4; i++){
    if (strcpy_P(bufS, (char*)pgm_read_word(&(tiposA[i]))) == type){ // PROGMEM read (alarm types from 0 to 3)
      if (a==1) EEPROM.write(a1TyA, i);
      else if (a==2) EEPROM.write(a2TyA, i);
      break;
    }
  }
}
String getAlarmTime(byte a){
  if (a==1) return n2s(EEPROM.read(a1HA)) + ":" + n2s(EEPROM.read(a1MA));
  else if (a==2) return n2s(EEPROM.read(a2HA)) + ":" + n2s(EEPROM.read(a2MA));
  else return ""; 
}
void setAlarmHour(byte a, byte h){
  if (a==1) EEPROM.write(a1HA, h);
  else if (a==2) EEPROM.write(a2HA, h);
}
void setAlarmMinute(byte a, byte m){
  if (a==1) EEPROM.write(a1MA, m);
  else if (a==2) EEPROM.write(a2MA, m);
}
String b2s(bool expr){
  //char bufS[8];
  if (expr) return strcpy_P(bufS, (char*)pgm_read_word(&(strs[2])));
  else return strcpy_P(bufS, (char*)pgm_read_word(&(strs[3])));
}
void toggleAlarm(byte a){
  if (isAlarmEnabled(a)){setAlarmEnabled(a,0);}
  else {setAlarmEnabled(a,1);}
}
void nextAlarmType(byte a){
  if (a==1){
    if (EEPROM.read(a1TyA)<3) EEPROM.write(a1TyA, EEPROM.read(a1TyA)+1);
    else EEPROM.write(a1TyA, 0);
  } else {
    if (EEPROM.read(a2TyA)<3) EEPROM.write(a2TyA, EEPROM.read(a2TyA)+1);
    else EEPROM.write(a2TyA, 0);
  }
}
void prevAlarmType(byte a){
  if (a==1){
    if (EEPROM.read(a1TyA)>0) EEPROM.write(a1TyA, EEPROM.read(a1TyA)-1);
    else EEPROM.write(a1TyA, 3);
  } else {
    if (EEPROM.read(a2TyA)>0) EEPROM.write(a2TyA, EEPROM.read(a2TyA)-1);
    else EEPROM.write(a2TyA, 3);
  }
}
void shouldAlarmSound(byte a, byte DoW, byte y, byte mo, byte d, byte h, byte m){
  if ( checkAlarm(a, DoW, y, mo, d, h, m) ){
    // Turn the backlight on for 2 reasons: 
    //  1. We would be able to read snooze messages if it's still dark.
    //  2. Light itself could help us wake up.
    digitalWrite( pinBacklight, HIGH );  
    
    soundAlarm(a, d);
    bIsAlOn=true; 
    bIsAnAlarm=true;
    
    byte type;
    if (a==1) type = EEPROM.read(a1TyA);
    else type = EEPROM.read(a2TyA);
    if (type==1){ // Deactivate alarm if it is of type 'once'
      if (a==1) EEPROM.write(a1EnA,0);
      else EEPROM.write(a2EnA,0);
    }
  }
}
bool checkAlarm(byte a, byte DoW, byte y, byte mo, byte d, byte h, byte m){
  if ( dayMatch(a, DoW, y, mo, d) ){
    if (a==1){
      if (EEPROM.read(a1HA) != h) return false;
      if (EEPROM.read(a1MA) != m) return false;
      return true;
    }
    else if (a==2){
      if (EEPROM.read(a2HA) != h) return false;
      if (EEPROM.read(a2MA) != m) return false;
      return true;    
    }
  }
  return false;
}
bool dayMatch(byte a, byte DoW, byte y, byte mo, byte d){
  byte type;
  if (a==1) type = EEPROM.read(a1TyA);
  if (a==2) type = EEPROM.read(a2TyA);
  
  if (type==0 and DoW>0 and DoW<6 and !bIsHoliday) return true; //(L-V) 1-5 means L-V
  if (type==1) // (Una vez) If we reached here, it must return true, bc we set flags off
    return true; 
  if (type==2 and (DoW>5 or bIsHoliday)) return true; //(FdS) 6 and 7 are FdS
  if (type==3) return true; // (Diaria)
  return false;
}
void printAlarm(byte a){
  lcd.setCursor(0,0);
  lcd.print("A"+String(a)+": "+b2s(isAlarmEnabled(a)));
  lcd.setCursor(0,1);
  lcd.print(getAlarmType(a)+"  ");
  lcd.print(getAlarmTime(a));
}
void printAlarm(byte a, byte h, byte m){
  lcd.setCursor(0,0);
  lcd.print("A"+String(a)+": "+b2s(isAlarmEnabled(a)));
  lcd.setCursor(0,1);
  lcd.print(getAlarmType(a)+"  ");
  lcd.print(n2s(h)+":"+n2s(m));
}
void soundAlarm(byte alarm, byte d){
  // Each time an alarm is off, we activate 10m mode (will be deactivated by hand or after 10m is off)
  b10m=true;
  en10Millis = millis();    
  tmrpcm.setVolume(3.2);
  tmrpcm.play(audios[d%8+7]); // 7 - 14: Birds, Rooster
}
void soundDoneConfiguring(){
  tmrpcm.setVolume(2);
  tmrpcm.play("ready.wav");
  secsToAvoidCollision = 1;
  bIsAlOn=true;
  bIsAnAlarm=false;  
}

//**************************** 1 0   m i n u t e s ***********************************************
void ask10min(){
  lcd.cursor();
  print10Min();
  delay(100);
  kP=getKeyPressed();
  while(kP!=4){ //Select
    if (kP>=0 and kP<4){
      if (b10m) b10m=false;
      else b10m=true;
      print10Min();
    }
    kP=getKeyPressed();
  }
  soundDoneConfiguring();
  
  if (b10m) {
    en10Millis = millis();  
    
    // Turn the backlight off, so that we can go back to sleep in the meantime
    digitalWrite( pinBacklight, LOW );
  }
  else bIsAnAlarm=false;
}
void print10Min(){
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print(String(strcpy_P(bufS, (char*)pgm_read_word(&(strs[1]))) )+ String(strcpy_P(bufS, (char*)pgm_read_word(&(strs[5])))));
  lcd.setCursor(7,1);
  if (b10m) lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[6]))));  
  else lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[7]))));  
  lcd.setCursor(7,1);
}

//********************************* C L O C K ***********************************************
void configClock(){
  int setting=0;
  if (kP==4){ //Select 
    //delay(50); //Don't get next key right away
    lcd.cursor();
    lcd.clear();
    printClock();
    
    byte oldH, oldM, oldS, oldDoW, oldD, oldMo, oldY, h, m, s, tDoW, d, mo, y; 
    oldH=Clock.getHour(f, f);
    oldM=Clock.getMinute();
    oldS=Clock.getSecond();
    oldD=Clock.getDate();
    oldMo=Clock.getMonth(f);
    oldY=Clock.getYear();
    oldDoW=Clock.getDoW();
    h=oldH;
    m=oldM;
    s=oldS;
    tDoW=oldDoW;
    d=oldD;
    mo=oldMo;
    y=oldY;
 
    lcd.setCursor(curClk[setting][0],curClk[setting][1]);
    kP=getKeyPressed();
    while(kP!=4){ //Select
      if (kP==0){ //Right
        if (setting<6) setting++;
        else setting=0; //Come back to start again
        setCur('c',setting);
      } else if (kP==1){ //Up
        lcd.clear();
        if (setting==0){
          if (h<23) h++; else h=0;
        } else if (setting==1){
          if (m<55) m+=5; else m-=55;
        } else if (setting==2){
          if (s<55) s+=5; else s-=55;
        } else if (setting==3){
          if (tDoW<7) tDoW++; else tDoW=1;
        } else if (setting==4){
          if (d<31) d++; else d=1;  
        } else if (setting==5){
          if (mo<12) mo++; else mo=1;
        } else if (setting==6){
          y++; 
        }
        printClock(h, m, s, tDoW, d, mo, y);
        setCur('c',setting);
      } else if (kP==2){ //Down
        lcd.clear();
        if (setting==0){
          if (h>0) h--; else h=23;
        } else if (setting==1){
          if (m>0) m--; else m=59;
        } else if (setting==2){
          if (s>0) s--; else s=59;
        } else if (setting==3){
          if (tDoW>1) tDoW--; else tDoW=7;
        } else if (setting==4){
          if (d>1) d--; else d=31;  
        } else if (setting==5){
          if (mo>1) mo--; else mo=12;
        } else if (setting==6){
          y--; 
        }
        printClock(h, m, s, tDoW, d, mo, y);
        setCur('c',setting);
      } else if (kP==3){ //Left
        if (setting>0) setting--;
        else setting=6; //Come back to end again
        setCur('c',setting); 
      }
      kP=getKeyPressed();
    }
    // Only write settings that changed
    if (h!=oldH) Clock.setHour(h); // was there any change in hours?
    if (m!=oldM) Clock.setMinute(m);
    if (s!=oldS) Clock.setSecond(s);
    if (tDoW!=oldDoW) Clock.setDoW(tDoW);
    if (d!=oldD) Clock.setDate(d);
    if (mo!=oldMo) Clock.setMonth(mo);
    if (y!=oldY) Clock.setYear(y);
    lcd.clear();
    
    // Playback a sound to know we are done with settings
    soundDoneConfiguring();
  }
}
void printClock(){
  lcd.setCursor(0,0);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[4])))+n2s(Clock.getHour(f,f))+":"+n2s(Clock.getMinute())+":"+n2s(Clock.getSecond()));
  lcd.setCursor(0,1);
  lcd.print(getDia(Clock.getDoW(),false)+" "+n2s(Clock.getDate())+" "+getMes(Clock.getMonth(f),false)+" "+Clock.getYear());
}
void printClock(byte h, byte m, byte s, byte tDoW, byte d, byte mo, byte y){
  lcd.setCursor(0,0);
  lcd.print(strcpy_P(bufS, (char*)pgm_read_word(&(strs[4])))+n2s(h)+":"+n2s(m)+":"+n2s(s));
  lcd.setCursor(0,1);
  lcd.print(getDia(tDoW,false)+" "+n2s(d)+" "+getMes(mo,false)+" "+y);
}

//****************************** U T I L I T I E S ***********************************************
void initEEPROM(){
  //Check if variables are properly set, otherwise, initialize them
  if (EEPROM.read(wEnA)>1) EEPROM.write(wEnA,0); 
  if (EEPROM.read(a1EnA)>1) EEPROM.write(a1EnA,0);
  if (EEPROM.read(a2EnA)>1) EEPROM.write(a2EnA,0);
  if (EEPROM.read(a1TyA)>3) EEPROM.write(a1TyA,1);
  if (EEPROM.read(a2TyA)>3) EEPROM.write(a2TyA,1);
  if (EEPROM.read(wHA)>23) EEPROM.write(wHA,0);
  if (EEPROM.read(a1HA)>23) EEPROM.write(a1HA,12);
  if (EEPROM.read(a2HA)>23) EEPROM.write(a2HA,12);
  if (EEPROM.read(wMA)>59) EEPROM.write(wMA,0);  
  if (EEPROM.read(a1MA)>59) EEPROM.write(a1MA,0);  
  if (EEPROM.read(a2MA)>59) EEPROM.write(a2MA,0);  
}
void setCur(char type, int sett){
  if (type=='w')
    lcd.setCursor(curWar[sett][0],curWar[sett][1]);
  else if (type=='a')
    lcd.setCursor(curAla[sett][0],curAla[sett][1]);
  else if (type=='c')
   lcd.setCursor(curClk[sett][0],curClk[sett][1]); 
}
void shouldSoundStop(){
  if (!bIsAlOn) return;
  if (kP>=0 and kP<4){ //Any key other than Select
    tmrpcm.stopPlayback();      
    tmrpcm.setVolume(0.1);
    if (bIsAnAlarm) ask10min();  
    kP=-1; // Don't go to config settings
  }
}
void shouldToggleBackLight(){
  if (kP>=0 and kP<4){ //Any key other than Select and there was not sound to stop
    // Toggle both backlight and flag
    if (digitalRead(pinBacklight) == HIGH) { digitalWrite( pinBacklight, LOW ); } 
    else { digitalWrite( pinBacklight, HIGH ); }
    if (bToggleBacklightWasPressed) { bToggleBacklightWasPressed = false; } 
    else { bToggleBacklightWasPressed = true; }
    kP=-1; // Don't go to config settings
  }
}
String n2s(byte n){
  if (n>9) return String(n);
  return '0'+String(n);
}

byte moonPhase(int year, int month, int day){    
  // Returns the lcd character id corresponding to moon phase
  byte res = Conway(year, month, day);
  if (res>=27 or res<=3) return 4; // Luna nueva
  else if (res>=4 and res<=11) return 5; // Luna creciente
  else  if (res>=12 and res<=18) return 6; // Luna llena
  else return 7; //res>=19 and res<=26 // Luna menguante
}

byte toMoonPhase(int year, int month, int day){
  //Returns 0,1,2 depending on how close is the day to moon phase (1:Phase) 
  byte res = Conway(year, month, day);
  if (res>=27 or res<=3){
    if (29-res<3) return 0; // Before
    else if (res==0) return 1; // Phase
    else return 2; // After
  } else if (res>=4 and res<=11){
    if (11-res<3) return 2; // After 
    else if (res==8) return 1; // Phase
    else return 0; // Before
  } else  if (res>=12 and res<=18){
    if (18-res<3) return 2; // After 
    else if (res==15) return 1; // Phase
    else return 0; // Before
  } else if (res>=19 and res<=26){
    if (26-res<3) return 2; // After 
    else if (res==22 or res==23) return 1; // Phase
    else return 0; // Before
  }
}

byte Conway(int year, int month, int day){
   // Borrowed from http://www.ben-daglish.net/moon.shtml
  year +=2000; // Years come as 2 digits, but we need them complete
  int r = year % 100;
  r %= 19;
  if (r>9){ r -= 19;}
  r = ((r * 11) % 30) + month + day;
  if (month<3){r += 2;}
  r = int(floor(r-((year<2000) ? 4 : 8.3) +0.5))%30;
  int res;
  (r < 0) ? res=r+30 : res=r; //0-29
  return res;
}

String splitText(String data, char separator, int index){
  // Borrowed from http://stackoverflow.com/questions/9072320/split-string-into-string-array
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length()-1;

  for(int i=0; i<=maxIndex && found<=index; i++){
    if(data.charAt(i)==separator || i==maxIndex){
        found++;
        strIndex[0] = strIndex[1]+1;
        strIndex[1] = (i == maxIndex) ? i+1 : i;
    }
  }

  return found>index ? data.substring(strIndex[0], strIndex[1]) : data;
}

bool isHoliday(byte y, byte mo, byte d){
  char* allYears = (char*)(n2s(mo)+n2s(d)).c_str(); // All years the same day
  if (allYears=="0101" or allYears=="1225" or allYears=="0501" or allYears=="0720" or allYears=="0807")
    return true;
  char* eachYear = (char*)(n2s(y)+n2s(mo)+n2s(d)).c_str(); // Diff day each year
  for (int i=0;i<201;i++) // festivos.length() -> 201 
    if (festivos[i]==eachYear)
      return true;
  return false;
}

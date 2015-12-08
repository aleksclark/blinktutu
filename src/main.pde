

#include <FastLED.h>


#define NUM_LEDS 19
#define DATA_PIN 5
#define ANIMATE_INTERVAL 40
#define SENSOR_INTERVAL 25
#define PULSE_LENGTH 4000
#define CHASE_TIME 1000
#define CHASE_WIDTH 6

CRGB leds[NUM_LEDS];
CHSV HSVleds[NUM_LEDS];

// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
// Note that for older NeoPixel strips you might need to change the third parameter--see the strandtest
// example for more information on possible values.

int xPin = A5;    // select the input pin for the potentiometer
int yPin = A6;    // select the input pin for the potentiometer
int zPin = A7;    // select the input pin for the potentiometer
int delayval = 10; // delay for half a second
int r = 100;
int g = 100;
int b = 100;
int currentBright = 0;

unsigned long lastAnimate = 0;
unsigned long lastSensor = 0;
unsigned long currentTime = 0;

CHSV paleBlue( 160, 200, 255);
int incr = 10;
void setup() {
  FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);
  Serial.begin(9600);
  analogReference(EXTERNAL);
  for(int dot = 0; dot < NUM_LEDS; dot++) { 
      HSVleds[dot] = paleBlue;
  }
}

void loop() {

  currentTime = millis();
  if (currentTime >= lastAnimate + ANIMATE_INTERVAL) {
    animate();
    lastAnimate = currentTime;
  }
  
 
}

int addColor(int val, int incr) {
  val = val + incr;
  if (val > 150) {
    return 0;
  } else {
    return val;
  }
}

void animate() {
  colorShift();
  pulse();
  chase();
  for(int dot = 0; dot < NUM_LEDS; dot++) { 
    leds[dot] = HSVleds[dot];
      
  }

// paleBlue.val = quadwave8(currentBright);
 FastLED.show();
}

void colorShift() {
  for(int dot = 0; dot < NUM_LEDS; dot++) { 
    HSVleds[dot].hue = paleBlue.hue;
  }
  currentBright = currentBright + incr;
  if (currentBright > 220) {
    paleBlue.hue += 2;
  }

  if (currentBright < 30) {
  }

  if (paleBlue.hue > 254) {
    paleBlue.hue = 0;
  }  
}


unsigned long lastPulse = 0;

void pulse() {
  if (lastPulse < currentTime - PULSE_LENGTH) {
    lastPulse = currentTime;
  }

  long currentPulse = currentTime - lastPulse;

  long halfPulse = currentPulse - (PULSE_LENGTH / 2);

  // Serial.println(halfPulse);
  long absPulse = abs(halfPulse) * 256;
  absPulse = absPulse / (PULSE_LENGTH / 2);
  // Serial.println(absPulse);
  applyBrightness(quadwave8(absPulse));
}

void applyBrightness(int bright) {
  for(int dot = 0; dot < NUM_LEDS; dot++) { 
    HSVleds[dot].val = bright;
  }
}

unsigned long lastChase = 0;
int lastLED = 0;



void chase() {
  if (lastChase <= currentTime - CHASE_TIME) {
    lastChase = currentTime;
  }

    long currentChase = currentTime - lastChase;
    long timePerLED = CHASE_TIME / NUM_LEDS;
    int currentLED = (currentChase / timePerLED);
    long timeUntilNext = (currentChase - (currentLED * timePerLED));

    for (int i = 0; i <= CHASE_WIDTH; ++i)
    {
      long distance = (long(i) * timePerLED) + timeUntilNext;
      int bright = ((CHASE_TIME - ((i * timePerLED) + timeUntilNext)) * 256) / CHASE_TIME;
      HSVleds[prevIndex(currentLED, i)].val = quadwave8(bright);
    }




    // if (lastLED != currentLED) {

    //   lastLED = currentLED;
    //   for (int i = 0; i < 5; ++i)
    //   {
    //     int thisBright = ((5 - i) * 256) / 5;
    //     if (i == 0) {
    //       Serial.println(thisBright);
    //     }
    //     HSVleds[prevIndex(currentLED, i)].val = quadwave8(thisBright);
    //   }
    // }
    
    
    // int nextBright = quadwave8((currentChase - (currentLED * timePerLED)) * 256 / timePerLED);
    // HSVleds[nextIndex(currentLED, 1)].val = nextBright;
  
  


}

int prevIndex(int cur, int tgt) {
  if (cur >= tgt) {
    return cur - tgt;
  } else {
    int rem = tgt - cur;
    return NUM_LEDS - rem;
  }
}

int nextIndex(int cur, int tgt) {
  if (cur + tgt >= NUM_LEDS) {
    return NUM_LEDS - (cur + tgt + 1);
  } else {
    return cur + tgt;
  }
}

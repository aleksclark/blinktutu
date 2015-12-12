

#include <FastLED.h>


#define NUM_LEDS 22
#define DATA_PIN 5
#define BUTTON_PIN 4
#define ANIMATE_INTERVAL 40
#define SENSOR_INTERVAL 25
#define PULSE_LENGTH 4000
#define CHASE_TIME 1000
#define CHASE_WIDTH 6
#define X_READINGS 10
#define Y_READINGS 10
#define Z_READINGS 10
#define SENSITIVITY 50

CRGB leds[NUM_LEDS];
CHSV HSVleds[NUM_LEDS];


int xPin = A0;    // select the input pin for the potentiometer
int yPin = A1;    // select the input pin for the potentiometer
int zPin = A2;    // select the input pin for the potentiometer

int chaseTime = CHASE_TIME;
int pulseLength = PULSE_LENGTH;

int xRead[X_READINGS];
int yRead[Y_READINGS];
int zRead[Z_READINGS];
int currentXIndex = 0;
int currentYIndex = 0;
int currentZIndex = 0;
int numReadings = 0;

int delayval = 10; // delay for half a second
int r = 100;
int g = 100;
int b = 100;
int currentBright = 0;
int animateMode = 0;

// button vars
int buttonState;
int lastButtonState = LOW;

unsigned long lastAnimate = 0;
unsigned long lastSensor = 0;
unsigned long currentTime = 0;

CHSV paleBlue( 160, 200, 255);
int incr = 10;
void setup() {
  FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);
  // Serial.begin(9600);
  analogReference(EXTERNAL);

  for(int dot = 0; dot < NUM_LEDS; dot++) { 
      HSVleds[dot] = paleBlue;
  }

  pinMode(BUTTON_PIN, INPUT);
}

void loop() {

  currentTime = millis();
  if (currentTime >= lastAnimate + ANIMATE_INTERVAL) {
    animate();
    lastAnimate = currentTime;
  }

  if (currentTime >= lastSensor + SENSOR_INTERVAL) {
    sensor();
    lastSensor = currentTime;
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
  
  if (animateMode > 0 && animateMode < 3) {
    pulse();
  }
  if (animateMode > 1 && animateMode < 4) {
    chase();
  }

  if (animateMode > 2) {
    colorShift(2);
  }

  
  for(int dot = 0; dot < NUM_LEDS; dot++) { 
    leds[dot] = HSVleds[dot];
      
  }

// paleBlue.val = quadwave8(currentBright);
 FastLED.show();
}

void colorShift(int quantity) {

  paleBlue.hue += quantity;

  for(int dot = 0; dot < NUM_LEDS; dot++) { 
    HSVleds[dot].hue = paleBlue.hue;
  }

  if (paleBlue.hue > 254) {
    paleBlue.hue = 0;
  }  
}


unsigned long lastPulse = 0;

void pulse() {
  if (lastPulse < currentTime - pulseLength) {
    lastPulse = currentTime;
  }

  long currentPulse = currentTime - lastPulse;

  long halfPulse = currentPulse - (pulseLength / 2);

  // Serial.println(halfPulse);
  long absPulse = abs(halfPulse) * 256;
  absPulse = absPulse / (pulseLength / 2);
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
  if (lastChase <= currentTime - chaseTime) {
    lastChase = currentTime;
  }

    long currentChase = currentTime - lastChase;
    long timePerLED = chaseTime / NUM_LEDS;
    int currentLED = (currentChase / timePerLED);
    long timeUntilNext = (currentChase - (currentLED * timePerLED));

    for (int i = 0; i <= CHASE_WIDTH; ++i)
    {
      int bright = ((chaseTime - ((i * timePerLED) + timeUntilNext)) * 256) / chaseTime;
      HSVleds[prevIndex(currentLED, i)].val = quadwave8(bright);
    }
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

void sensor() {
  int reading = digitalRead(BUTTON_PIN);

  if (lastButtonState != reading) {
    lastButtonState = reading;
  } else if (lastButtonState != buttonState) {
    buttonState = lastButtonState;
    if (buttonState == HIGH) {
      processButtonPress();
    }
  }

  readAccel();
  checkXGesture();
  bumpIndexes();
}

void processButtonPress() {
  animateMode++;
  if (animateMode > 5) {
    animateMode = 0;
  }
}

void readAccel() {
  xRead[currentXIndex] = (analogRead(xPin) - 417) * 2;
  yRead[currentYIndex] = (analogRead(yPin) - 417) * 2;
  zRead[currentZIndex] = analogRead(zPin) - 370;
  
  // Serial.print("x:" );
  // Serial.print(xRead[currentXIndex]);
  // Serial.print("y:" );
  // Serial.print(yRead[currentYIndex]);
  // Serial.print("z:" );
  // Serial.print(zRead[currentZIndex]);
  // Serial.print("\n");
}

void bumpIndexes() {
  currentXIndex++;
  if (currentXIndex >= X_READINGS) {
    currentXIndex = 0;
  }
  currentYIndex++;
  if (currentYIndex >= Y_READINGS) {
    currentYIndex = 0;
  }
  currentZIndex++;
  if (currentZIndex >= Z_READINGS) {
    currentZIndex = 0;
  }
}

int xDir = 0;

void checkXGesture() {
  int avgQuant = X_READINGS / 2;
  int currentSum = 0;
  int pastSum = 0;

  int currentReader = currentXIndex;
  for (int i = 0; i < X_READINGS; ++i)
  {
    if (i < avgQuant) {
      currentSum += xRead[currentReader];
    } else {
      pastSum += xRead[currentReader];
    }

    currentReader--;

    if (currentReader < 0) {
      currentReader = X_READINGS - 1;
    }
  }

  int currentAvg = currentSum / avgQuant;
  int pastAvg = pastSum / avgQuant;
  int currentDir = 0;

  if (currentAvg > (pastAvg + SENSITIVITY)) {
    currentDir = 1;

  } else if (currentAvg < (pastAvg - SENSITIVITY)) {
    currentDir = 2;
  }

  if (currentDir != 0 && currentDir != xDir) {
    xDir = currentDir;
    if (xDir == 1) {
      xGoDown();
    } else {
      xGoUp();
    }
  }

}

void xGoUp() {
  // Serial.println("Up");
  colorShift(20);
}

void xGoDown() {
  // Serial.println("Down");
  colorShift(20);
}


int yDir = 0;

void checkYGesture() {
  int avgQuant = Y_READINGS / 2;
  int currentSum = 0;
  int pastSum = 0;

  int currentReader = currentYIndex;
  for (int i = 0; i < Y_READINGS; ++i)
  {
    if (i < avgQuant) {
      currentSum += yRead[currentReader];
    } else {
      pastSum += yRead[currentReader];
    }

    currentReader--;

    if (currentReader < 0) {
      currentReader = Y_READINGS - 1;
    }
  }

  int currentAvg = currentSum / avgQuant;
  int pastAvg = pastSum / avgQuant;
  int currentDir = 0;

  if (currentAvg > (pastAvg + SENSITIVITY)) {
    currentDir = 1;

  } else if (currentAvg < (pastAvg - SENSITIVITY)) {
    currentDir = 2;
  }

  if (currentDir != 0 && currentDir != yDir) {
    yDir = currentDir;
    if (yDir == 1) {
      yGoDown();
    } else {
      yGoUp();
    }
  }

}

void yGoUp() {
  lastPulse = currentTime;
}

void yGoDown() {
  lastPulse = currentTime;
}

int zDir = 0;

void checkZGesture() {
  int avgQuant = Z_READINGS / 2;
  int currentSum = 0;
  int pastSum = 0;

  int currentReader = currentZIndex;
  for (int i = 0; i < Z_READINGS; ++i)
  {
    if (i < avgQuant) {
      currentSum += zRead[currentReader];
    } else {
      pastSum += zRead[currentReader];
    }

    currentReader--;

    if (currentReader < 0) {
      currentReader = Z_READINGS - 1;
    }
  }

  int currentAvg = currentSum / avgQuant;
  int pastAvg = pastSum / avgQuant;
  int currentDir = 0;

  if (currentAvg > (pastAvg + SENSITIVITY)) {
    currentDir = 1;

  } else if (currentAvg < (pastAvg - SENSITIVITY)) {
    currentDir = 2;
  }

  if (currentDir != 0 && currentDir != zDir) {
    zDir = currentDir;
    if (zDir == 1) {
      zGoUp();
    } else {
      zGoUp();
    }
  }

}

void zGoUp() {
  chaseTime += 500;
  if (chaseTime > CHASE_TIME * 4) {
    chaseTime = CHASE_TIME / 2;
  }
}

void zGoDown() {
  chaseTime -= 500;
  if (chaseTime < CHASE_TIME / 2) {
    chaseTime = CHASE_TIME * 4;
  }
}

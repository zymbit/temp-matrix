#include "lights.h"

void blink(int led) {
  blink(led, 25);
}

void blink(int led, int duration) {
  digitalWrite(led, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(duration);               // wait for a second
  digitalWrite(led, LOW);    // turn the LED off by making the voltage LOW
}

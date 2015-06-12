#include <Arduino.h>
#include <OneWire.h>
#include <Console.h>
#include <DallasTemperature.h>

#include "lights.h"

#define BUF_SIZE 256
#define REPORT_INTERVAL 60000  // report at least every minute
/*-----( Declare Constants and Pin Numbers )-----*/
#define TEMPERATURE_PRECISION 9
#define NUM_SENSORS_PER_BUS 4

/* change the number of busses being used here */
#define NUM_BUSES 1
#define NUM_TEMPERATURE_SENSORS NUM_BUSES*NUM_SENSORS_PER_BUS

/* update sensor pins according to NUM_BUSES above */
int sensor_pins[] = {2};

/*-----( Declare objects )-----*/
OneWire *onewire_buses[NUM_BUSES];
DallasTemperature *sensor_buses[NUM_BUSES];

DeviceAddress Therms[NUM_TEMPERATURE_SENSORS];

int count = 1;
float temperatures[NUM_TEMPERATURE_SENSORS] = {0.0};
float lastTemperatures[NUM_TEMPERATURE_SENSORS] = {0.0};
unsigned long lastTemperatureReports[NUM_TEMPERATURE_SENSORS] = {0};

unsigned long now = 0;

char buf[BUF_SIZE];

int led = 13;

bool sendData(int pin, float value, char* deviceId, unsigned long* lastReport, float* lastValue);

void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    // zero pad the address if necessary
    if (deviceAddress[i] < 16) Console.print("0");
    Console.print(deviceAddress[i], HEX);
  }
}

void setup()  /****** SETUP: RUNS ONCE ******/
{
  for(int i = 0; i < NUM_BUSES; i++) {
    onewire_buses[i] = new OneWire(sensor_pins[i]);
    sensor_buses[i] = new DallasTemperature(onewire_buses[i]);
  }

  Bridge.begin();
  Console.begin();

  for (int i=0; i<NUM_BUSES; i++){
    for (int j=0; j<=NUM_SENSORS_PER_BUS; j++){
      sensor_buses[i]->getAddress(Therms[NUM_BUSES*i + j], j);
      sensor_buses[i]->setResolution(Therms[NUM_BUSES*i + j], TEMPERATURE_PRECISION);
    }

    delay(100);
  }
}


void loop(void)
{
  if(!Console.connected()) {
    return;
  }
  int sensor_index = 0;

  // call sensors.requestTemperatures() to issue a global temperature

  for (int i=0; i<NUM_BUSES; i++){
    sensor_buses[i]->requestTemperatures();
    for (int j=0; j<NUM_SENSORS_PER_BUS; j++){
      sensor_index = NUM_BUSES*i + j;

      temperatures[sensor_index] = sensor_buses[i]->getTempC(Therms[sensor_index]);
      sendData(sensor_pins[i], temperatures[sensor_index], Therms[sensor_index], &lastTemperatureReports[sensor_index], &lastTemperatures[sensor_index]);
    }

    delay(100);
  }
}

bool sendData(int pin, float value, DeviceAddress deviceId, unsigned long* lastReport, float* lastValue)
{
  unsigned long now = millis();
  float diff = value - *lastValue;

  if((now - *lastReport > REPORT_INTERVAL) || (diff != 0.0)) {

    Console.print("key=temperature.");
    printAddress(deviceId);

    Console.print(", Pin=");
    Console.print(pin);
    Console.print(", DeviceID=");
    printAddress(deviceId);
    Console.print(", value=");
    Console.print(value);
    Console.println();

    *lastValue = value;
    *lastReport = now;

    blink(led);

    return true;
  }

  return false;
}

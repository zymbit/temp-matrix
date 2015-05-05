#include <Arduino.h>
#include <OneWire.h>
#include <Console.h>
#include <DallasTemperature.h>

#include "lights.h"
#include "payload.h"

#define BUF_SIZE 512
#define REPORT_INTERVAL 30000  // report at least every 30 seconds
/*-----( Declare Constants and Pin Numbers )-----*/
#define TEMPERATURE_PRECISION 9
#define NUM_TEMPERATURE_SENSORS 16
#define NUM_BUSES 4

#define SENSOR_1_PIN 2 // For BUS 1
#define SENSOR_2_PIN 4 // For BUS 2
#define SENSOR_3_PIN 6 // For BUS 3
#define SENSOR_4_PIN 8 // For BUS 4

/*-----( Declare objects )-----*/
OneWire  bus1(SENSOR_1_PIN);  // Create a 1-wire object
OneWire  bus2(SENSOR_2_PIN);
OneWire  bus3(SENSOR_3_PIN);  
OneWire  bus4(SENSOR_4_PIN);

DallasTemperature sensors_bus1(&bus1);
DallasTemperature sensors_bus2(&bus2);
DallasTemperature sensors_bus3(&bus3);
DallasTemperature sensors_bus4(&bus4);
  
DeviceAddress Therms[NUM_TEMPERATURE_SENSORS];
int count = 1;
float temperatures[NUM_TEMPERATURE_SENSORS] = {0.0};
float lastTemperatures[NUM_TEMPERATURE_SENSORS] = {0.0};
unsigned long lastTemperatureReports[NUM_TEMPERATURE_SENSORS] = {0};

unsigned long now = 0;

char buf[BUF_SIZE];

payload _payload;

int led = 13;

bool eventCheck(int pin, float value, char* deviceId, unsigned long* lastReport, float* lastValue);

void send_payload(payload *p) {
  // don't send if the console is not connected
  if(!Console.connected()) {
    return;
  }
  payloadJson(buf, BUF_SIZE, p);
  Console.println(buf);
}
void setup()  /****** SETUP: RUNS ONCE ******/
{ 
  Bridge.begin();
  Console.begin();
  
  for (int j=1; j<=NUM_BUSES; j++){
    sensors_bus1.getAddress(Therms[count],j);
    sensors_bus1.setResolution(Therms[count], TEMPERATURE_PRECISION);
    count += 1;
  }
  delay(100);
  for (int j=1; j<=NUM_BUSES; j++){
    sensors_bus2.getAddress(Therms[count],j);
    sensors_bus2.setResolution(Therms[count], TEMPERATURE_PRECISION);
    count += 1;
  }
  delay(100);
  for (int j=1; j<=NUM_BUSES; j++){
    sensors_bus3.getAddress(Therms[count],j);
    sensors_bus3.setResolution(Therms[count], TEMPERATURE_PRECISION);
    count += 1;
  }
  delay(100);
  for (int j=1; j<=NUM_BUSES; j++){
    sensors_bus4.getAddress(Therms[count],j);
    sensors_bus4.setResolution(Therms[count], TEMPERATURE_PRECISION);
    count += 1;
  }
  delay(100);
}
  
void loop(void)
{ 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  Console.print("Requesting temperatures...");
  sensors_bus1.requestTemperatures();
  delay(100);
  sensors_bus2.requestTemperatures();
  delay(100);
  sensors_bus3.requestTemperatures();
  delay(100);
  sensors_bus4.requestTemperatures();
  delay(100);
  
  for (int i=1; i<=4; i++){
    temperatures[i] = sensors_bus1.getTempC(Therms[i]);
    snprintf(buf, BUF_SIZE, "%u", Therms[i]);
    if(eventCheck(SENSOR_1_PIN, temperatures[i], buf, &lastTemperatureReports[i], &lastTemperatures[i])) {
      send_payload(&_payload);
    }
  }
  delay(200);
  for (int i=5; i<=8; i++){
    temperatures[i] = sensors_bus2.getTempC(Therms[i]); 
    snprintf(buf, BUF_SIZE, "%u", Therms[i]);
    if(eventCheck(SENSOR_2_PIN, temperatures[i], buf, &lastTemperatureReports[i], &lastTemperatures[i])) {
      send_payload(&_payload);
    }
  }
  delay(200);
  for (int i=9; i<=12; i++){
    temperatures[i] = sensors_bus3.getTempC(Therms[i]); 
    snprintf(buf, BUF_SIZE, "%u", Therms[i]);
    if(eventCheck(SENSOR_3_PIN, temperatures[i], buf, &lastTemperatureReports[i], &lastTemperatures[i])) {
      send_payload(&_payload);
    }
  }
  delay(200);
  for (int i=13; i<=16; i++){
    temperatures[i] = sensors_bus4.getTempC(Therms[i]); 
    snprintf(buf, BUF_SIZE, "%u", Therms[i]);
    if(eventCheck(SENSOR_4_PIN, temperatures[i], buf, &lastTemperatureReports[i], &lastTemperatures[i])) {
      send_payload(&_payload);
    }
  }
  // for (int i=1; i<=NUM_TEMPERATURE_SENSORS; i++){
//     Console.print(temperatures[i]);
//     Console.print(' ');
//   }
  Console.print(temperatures[16]); 
  delay(1000);
  
}

bool eventCheck(int pin, float value, char* deviceId, unsigned long* lastReport, float* lastValue)
{
  unsigned long now = millis();

  if((now - *lastReport > REPORT_INTERVAL) || value != *lastValue) {
    int idx = 0;

    _payload.millis = millis();
    // change these items based on the device being acquired
    _payload.pin = pin;
    _payload.value = value;
    snprintf(_payload.deviceId, DEVICE_ID_SIZE, "%s", deviceId);

    *lastValue = value;
    *lastReport = now;

    blink(led);

    return true;
  }

  return false;
}
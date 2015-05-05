#include <Arduino.h>
#include <OneWire.h>
#include <Console.h>
#include <DallasTemperature.h>

#include "lights.h"

#define BUF_SIZE 256
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
    sendData(SENSOR_1_PIN, temperatures[i], Therms[i], &lastTemperatureReports[i], &lastTemperatures[i]);
  }
  delay(200);
  for (int i=5; i<=8; i++){
    temperatures[i] = sensors_bus2.getTempC(Therms[i]); 
    sendData(SENSOR_2_PIN, temperatures[i], Therms[i], &lastTemperatureReports[i], &lastTemperatures[i]);
  }
  delay(200);
  for (int i=9; i<=12; i++){
    temperatures[i] = sensors_bus3.getTempC(Therms[i]); 
    sendData(SENSOR_3_PIN, temperatures[i], Therms[i], &lastTemperatureReports[i], &lastTemperatures[i]);
  }
  delay(200);
  for (int i=13; i<=16; i++){
    temperatures[i] = sensors_bus4.getTempC(Therms[i]); 
    sendData(SENSOR_4_PIN, temperatures[i], Therms[i], &lastTemperatureReports[i], &lastTemperatures[i]);
  }
  // for (int i=1; i<=NUM_TEMPERATURE_SENSORS; i++){
//     Console.print(temperatures[i]);
//     Console.print(' ');
//   }
  Console.print(temperatures[16]); 
  delay(1000);
  
}

bool sendData(int pin, float value, DeviceAddress deviceId, unsigned long* lastReport, float* lastValue)
{
  unsigned long now = millis();

  if((now - *lastReport > REPORT_INTERVAL) || value != *lastValue) {

    Console.print("Pin=");
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
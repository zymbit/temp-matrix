#ifndef __PAYLOAD_H__
#define __PAYLOAD_H__

#ifdef AVR
#include <Arduino.h>

// the size of float value written in payloadJson()
#define VALUE_SIZE 8
#endif

#define DEVICE_ID_SIZE 32

typedef struct payload {
  unsigned long millis;
  unsigned int pin;
  double value;
  char deviceId[DEVICE_ID_SIZE];
} payload;


int payloadJson(char* s, size_t n, void* _payload)
{
  int count = 0;
  int numBytes = 0;

  payload* item = (payload*)_payload;

  count += snprintf(s+count, n-count,
    ("{"
      "\"millis\": %lu,"
      "\"pin\": %u,"
      "\"deviceId\": \"%s\","
      "\"value\": "),
    item->millis,
    item->pin,
    item->deviceId);

#ifdef AVR
  dtostrf(item->value, VALUE_SIZE, 2, &s[count]);
  count += VALUE_SIZE;
#else
  count += snprintf(s+count, n-count, "%f", item->value);
#endif

  count += snprintf(s+count, n-count, "}");

  return count;
}

#endif /* __PAYLOAD_H__ */

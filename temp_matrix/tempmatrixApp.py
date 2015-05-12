#!/usr/bin/env python
__author__ = 'evan fairchild'

import time
import sys
import logging
import json
import os
import select

from zymbit.messenger.client import MessengerClient
from zymbit.client import Client

INTERACTOR_HOST = os.environ.get('INTERACTOR_HOST', 'localhost')
INTERACTOR_PORT = int(os.environ.get('INTERACTOR_PORT', 7732))


class TempMatrix(object):

    def __init__(self):
        self.client = Client()
        self.messenger_client = MessengerClient(INTERACTOR_HOST, INTERACTOR_PORT)

    def loop(self):
        while True:
            self.run()

    def run(self):
        r, _, _ = select.select([self.client], [], [], 1.0)
        if self.client in r:
            self.handle_message()

    def data(self, envelope):
        pin = envelope['params']['Pin']
        temp = float(envelope['params']['value'])
        device = str(envelope['params']['DeviceID'])

        self.mapper(pin, temp, device)
        # self.temp_logger(pin, temp, device)

    def bitstream(self, row, probe):
        MAT = [[0 for x in range(9)] for x in range(9)]
        col = [0, 2, 4, 6]
        for i in range(row, row+3):
            for j in range(col[probe], col[probe]+3):
                MAT[i][j] = 100

        return MAT

    def mapper(self, pin, temp, device):
        # pin 2 -> row 1, pin 4 -> row 2, pin 6 -> row 3, pin 8 -> row
        row1 = ['35', 'E2', '6C', '03']
        row2 = ['9B', '83', 'AB', '75']
        row3 = ['A2', '9F', '2D', 'B0']
        row4 = ['CF', 'A1', 'BF', '8E']

        self.send('matrix', {'command': 'clear'})
        time.sleep(.5)

        if pin == 2:
            for i in range(0, len(row1)):
                if row1[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_bitmap', 'bitstream': self.bitstream(0, i)})
        elif pin == 4:
            for i in range(0, len(row2)):
                if row2[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_bitmap', 'bitstream': self.bitstream(2, i)})
        elif pin == 6:
            for i in range(0, len(row3)):
                if row3[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_bitmap', 'bitstream': self.bitstream(4, i)})
        elif pin == 8:
            for i in range(0, len(row4)):
                if row4[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_bitmap', 'bitstream': self.bitstream(6, i)})

        else:
            self.logger.warning('Invalid Pin')

        time.sleep(1)

        if temp <= 27:
            self.send('edge', {'command': 'setColor', 'color': '0000ff'})
        elif 35 <= temp < 55:
            self.send('edge', {'command': 'setColor', 'color': 'FFA500'})
        elif temp >= 55:
            self.send('edge', {'command': 'setColor', 'color': 'FF0000'})

        time.sleep(.5)

        temp_str = str(temp) + "C"
        self.send('softkeyd', {'command': 'draw_text', 'text': temp_str, 'font': 'arial', 'size': 10, 'weight': 'bold'})

    def send(self, action, params):
        self.messenger_client.send(action, params)
        self.messenger_client.loop()
        time.sleep(.5)

    @property
    def logger(self):
        name = '{}.{}'.format(__name__, self.__class__.__name__)
        return logging.getLogger(name)

    def handle_message(self):
        try:
            payload = self.client.recv()
        except WebSocketConnectionClosedException:
            # the connection is closed
            self._ws = None
            return

        if payload is None:
            self.logger.warning('got an empty payload')
            return

        try:
            data = json.loads(payload)
        except TypeError:
            self.logger.error('unable to load payload={}'.format(payload))
            raise

        print 'data={}'.format(data)

        handler_fn = data.get('action')
        if handler_fn is None:
            self.logger.warning('no action in data={}'.format(data))
            return

        handler = getattr(self, handler_fn, None)
        if handler is None:
            self.logger.warning('no handler for handler_fn={}'.format(handler_fn))
            return

        return handler(data)

    def connection(self, data):
        self.logger.debug('connected to websocket')
        self.client.send('subscribe', {'routing_key': 'data.tempmatrix.#'})

if __name__ == '__main__':
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

    while True:
        try:
            logger = logging.getLogger(__name__)
            logger.info('Subscribed to temp-matrix!')
            tempmatrix = TempMatrix()
            tempmatrix.loop()



        except Exception, exc:
            logger = logging.getLogger(__name__)
            logger.exception(exc)
            time.sleep(5)




#python scripts/subscribe.py 'data.zymbit.mood.#'




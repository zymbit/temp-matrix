__author__ = 'evan'

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

        self.max_log = [[0 for x in range(4)] for x in range(4)]
        self.min_log = [[0 for x in range(4)] for x in range(4)]
        self.avg_log = [[0 for x in range(4)] for x in range(4)]
        self.probe_log = [[0 for x in range(4)] for x in range(4)]
        self.send('matrix', {'command': 'clear'})

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

    def mapper(self, pin, temp, device):
        # pin 2 -> row 1, pin 4 -> row 2, pin 6 -> row 3, pin 8 -> row 4
        row1 = ['03', '6C', 'E2', '35']
        row2 = ['52', 'AB', '83', '9B']
        row3 = ['75', '83', 'AB', '9B']
        row4 = ['CF', '8E', 'A1', 'BF']

        start_action_row1 = [[0, 0], [2, 0], [4, 0], [6, 0]]
        start_action_row2 = [[0, 2], [2, 2], [4, 2], [6, 2]]
        start_action_row3 = [[0, 4], [2, 4], [4, 4], [6, 4]]
        start_action_row4 = [[0, 6], [2, 6], [4, 6], [6, 6]]

        end_action_row1 = [[2, 2], [4, 2], [6, 2], [8, 2]]
        end_action_row2 = [[2, 4], [4, 4], [6, 4], [8, 4]]
        end_action_row3 = [[2, 6], [4, 6], [6, 6], [8, 6]]
        end_action_row4 = [[2, 8], [4, 8], [6, 8], [8, 8]]

        self.send('matrix', {'command': 'clear'})
        time.sleep(.5)

        if pin == 2:
            for i in range(0, len(row1)):
                if row1[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_line', 'start_position': start_action_row1[i], 'end_position': end_action_row1[i]})
        elif pin == 4:
            for i in range(0, len(row2)):
                if row2[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_line', 'start_position': start_action_row2[i], 'end_position': end_action_row2[i]})
        elif pin == 6:
            for i in range(0, len(row3)):
                if row3[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_line', 'start_position': start_action_row3[i], 'end_position': end_action_row3[i]})
        elif pin == 8:
            for i in range(0, len(row4)):
                if row4[i] == device[-2:]:
                    self.send('matrix', {'command': 'draw_line', 'start_position': start_action_row4[i], 'end_position': end_action_row4[i]})

        else:
            self.logger.warning('Invalid Pin')
            return

        self.send('softkeyc', {'command': 'draw_text', 'text': temp, 'font': 'arial', 'size': 10, 'weight': 'bold'})

    # def temp_logger(self, pin, temp, device):
    #     if pin == 2:


    def send(self, action, params):
        self.messenger_client.send(action, params)
        self.messenger_client.loop()

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



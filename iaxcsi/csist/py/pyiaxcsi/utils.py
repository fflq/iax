#!/usr/bin/env python3
# -*- coding: utf-8 -*-

class utils:
    @staticmethod
    def output_hexs(data, hex=True):
        for n in range(len(data)):
            if not n % 16:
                print('\n%08d:' % (n), end=' ')
            elif not n % 8:
                print(end='  ')
            elif not n % 4:
                print(end=' ')

            if hex:
                print(' %02X' % (data[n]), end='')
            else:
                print(' %03d' % (data[n]), end='')
        print()

#!/usr/bin/env python
# Copyright (c) 2015 Dropbox, Inc

import os
import sys
import json

EXPORT_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), '.build_vars')

def get_build_vars():
    with open(EXPORT_PATH) as fd:
        ret = json.load(fd)
    return ret

def write_vars_to_file(kv_list):
    with open(EXPORT_PATH, 'w') as fd:
        var_dict = dict([kv.split('=') for kv in kv_list])
        json.dump(var_dict ,fd)

def print_help():
    print '''
    Usage: python gen_export.py <output path> [<var>=<value> ...]

    writes json file to output path
    '''

if __name__ == '__main__':
    if not len(sys.argv) > 1:
        print_help()
    else:
        kv_list = sys.argv[1:]
        write_vars_to_file(kv_list)

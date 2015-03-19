#!/usr/bin/env python
# Copyright (c) 2015 Dropbox, Inc

import os
import glob
import subprocess
import sys
from export_build_vars import get_build_vars

BUILD_VARS = get_build_vars()

def main():
    object_file_dir = BUILD_VARS.get('object_file_dir')
    os.chdir(object_file_dir)
    files = glob.glob("*.gcda")
    if len(files) == 0:
        return
    gcov_proc = subprocess.Popen(['gcov'] + files)


'''Usage: python run_gcov.py

Expects export_build_vars.py to have already been called creating a 
'.build_vars' file with an object_file_dir.

The objects dir should be where all of your .gcda files are.
'''
if __name__ == '__main__':
    main()

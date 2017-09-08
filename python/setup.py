# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import glob
import os
import shutil
import subprocess

from setuptools import setup, find_packages, Distribution
import setuptools.command.build_ext as _build_ext

class build_ext(_build_ext.build_ext):

    def run(self):
        # We build the C++ extension in a different directory to avoid
        # having build artifacts in the package directory and make it
        # easy to clean the build. This means we need to move the files
        # here.
        subprocess.check_call(["./build.sh"])
        build_lib = os.path.join(os.getcwd(), self.build_lib)
        for path in glob.glob("build/lib.cpython*"):
            directory, filename = os.path.split(path)
            for destination in ["ray", os.path.join(build_lib, "ray")]:
                print("Copying {} to {}".format(path, destination))
                shutil.copy(path, destination)

class BinaryDistribution(Distribution):

    def has_ext_modules(self):
        return True

setup(name="ray",
      version="0.0.1",
      packages=find_packages(),
      cmdclass={"build_ext": build_ext},
      entry_points = {
          'console_scripts': [
              'ray = ray.commands:cli'
          ]
      },
      # The BinaryDistribution argument triggers build_ext
      distclass=BinaryDistribution,
      include_package_data=True,
      zip_safe=False,
      license="Apache 2.0")

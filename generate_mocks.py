#!/usr/bin/env python3
"""
    Copyright 2021 natinusala

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
"""

from pathlib import Path
from subprocess import run

# Script to generate mocks using Cuckoo. This will rebuild mocks for every file specified in
# the config below, and copy the generate file in the appropriate place.

# Mocks will be generated for every protocol in those files (relative to `_INPUT`):
_TO_MOCK = [
    "Layers/ActivitiesStackSpec.swift",
]

# Generated file will be placed here
_OUTPUT = Path("Tests") / "LoftwingTests" / "GeneratedMocks.swift"

# Project name
_PROJECT_NAME = "Loftwing"

# Root directory containing sources
_INPUT = Path("Sources") / "Loftwing"

cuckoo_run = Path("External") / "Cuckoo" / "run"

run(
    [
        str(cuckoo_run.absolute()),
        "generate",
        "--testable",
        _PROJECT_NAME,
        "--output",
        str(Path(_OUTPUT).absolute()),
    ]
    + [_INPUT / to_mock for to_mock in _TO_MOCK]
)

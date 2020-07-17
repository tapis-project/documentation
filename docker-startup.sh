#!/usr/bin/env bash

echo " starting requirements install "
pip install -r requirements.txt
echo " make html "
make html
echo " install sphinx-autobuild "
pip install sphinx-autobuild
echo " make livehtml "
make livehtml
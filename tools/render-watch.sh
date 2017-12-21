#!/bin/bash
echo "Serving $1 on localhost:8000"
cd $1
python -m SimpleHTTPServer
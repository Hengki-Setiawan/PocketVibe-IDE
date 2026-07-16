#!/data/data/com.termux/files/usr/bin/bash

if curl -s http://127.0.0.1:4096/doc > /dev/null 2>&1; then
  echo "OK"
else
  echo "FAIL"
fi

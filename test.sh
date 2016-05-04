#!/bin/bash

./catprogress ./out.img 2>/tmp/my_fifo | dd of=t.t bs=1M

echo "fd"

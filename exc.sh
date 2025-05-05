#!/bin/sh

kvm -L . -m 64 -fda ./disk.img -M pc

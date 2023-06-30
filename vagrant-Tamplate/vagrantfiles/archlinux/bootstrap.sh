#!/bin/bash

echo "[TASK 1] Create venkatn user account"
useradd -m -c "sam" sam
echo -e "admin\nadmin" | passwd kadmin >/dev/null 2>&1

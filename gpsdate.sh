#! /bin/sh

NMAX=20
SLEEP=1

N=1
echo -n "Waiting for GPSD to come online..."
until service gpsd status | grep "Active: active" >/dev/null 2>&1 || [ $N -gt $NMAX ]; do
    echo -n "."
    sleep $SLEEP
    N=$((N + 1))
done
if [ $N -gt $NMAX ]; then
    echo " FAILED."
    exit 1
else
    echo " OK."
fi

echo "Sleeping for $(($SLEEP * 3)) seconds..."
sleep $(($SLEEP * 3));

echo "Quering for GPS time..."
Y=$(date +"%Y" | head -c 2);
DT=$(gpspipe -n 60 -r -p -t | sed -n 's/^.*GPRMC,\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.*/'$Y'\6\5\4 \1:\2:\3/p' |tail -1 | tr -d '\n');
echo -n "Setting date from gpsd: "
N=1
# try 10 times as most
until test -n "$DT" && date -s "$DT" || [ $N -gt $NMAX ]; do
    sleep $SLEEP;
    echo "Quering for GPS time..."
    Y=$(date +"%Y" | head -c 2);
    DT=$(gpspipe -n 60 -r -p -t | sed -n 's/^.*GPRMC,\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.*/'$Y'\6\5\4 \1:\2:\3/p' |tail -1 | tr -d '\n');
    echo -n "Setting date from gpsd: "
    N=$((N + 1))
    echo "DT "$DT
done
if [ $N -gt 10 ]; then
    echo " FAILED."
else
    echo " DONE."
fi

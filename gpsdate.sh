#! /bin/sh

# Possible GPRMC messages (the two I've seen), this version ONLY supports the second!
# $GPRMC,225446,A,4916.45,N,12311.12,W,000.5,054.7,191194,020.3,E*68
# $GPRMC,225446.000,A,4916.45,N,12311.12,W,000.5,054.7,191194,020.3,E*68

if ! which gpspipe >/dev/null; then
    echo "Couldn't find 'gpspipe'"
    exit 1
fi

NMAX=40
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
DT=$(gpspipe -n 10 -r -p -t | sed -n 's/^.*GPRMC,\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.[0-9]\{3\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.*/'$Y'\6-\5-\4T\1:\2:\3Z/p' |tail -1 | tr -d '\n');
echo -n "Setting date from gpsd: '$DT'"
N=1
# try 10 times as most
until test -n "$DT" && date -s "$DT" || [ $N -gt $NMAX ]; do
    sleep $(($SLEEP * 10));
    echo "Quering for GPS time..."
    DT=$(gpspipe -n 10 -r -p -t | sed -n 's/^.*GPRMC,\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.[0-9]\{3\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},.\{0,\},\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\),.*/'$Y'\6-\5-\4T\1:\2:\3Z/p' |tail -1 | tr -d '\n');
    echo -n "Setting date from gpsd: "
    N=$((N + 1))
    echo "DT '$DT'"
done

if [ $N -gt $NMAX ]; then
    echo " FAILED."
fi

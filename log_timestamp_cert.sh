#!/bin/sh
set -x
yesterday=`date -d yesterday '+%Y%m%d'`
hashesfilename=loghashes.$yesterday.sha1
logprefix=/var/log/radius/radacct

cat /dev/null > $logprefix/$hashesfilename

\ls -1 $logprefix/*/*$yesterday* | while read file ; do sha1sum $file >> $logprefix/$hashesfilename; done
echo "Verify using -> openssl ts -verify -data $logprefix/$hashesfilename -in $logprefix/$hashesfilename.tsr -CAfile cacert.pem -untrusted tsa.crt " >> $logprefix/$hashesfilename

openssl ts -query -data $logprefix/$hashesfilename -no_nonce -sha512 -cert -out $logprefix/$hashesfilename.tsq

curl -H "Content-Type: application/timestamp-query" --data-binary '@'$logprefix/$hashesfilename.tsq https://freetsa.org/tsr > $logprefix/$hashesfilename.tsr

cp cacert.pem $logprefix/
cp tsa.crt $logprefix/


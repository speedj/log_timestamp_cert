#!/bin/sh
#set -x
#    Copyright (C) 2017 Daniele Albrizio <daniele@albrizio.it>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2.1 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This is a POC for certified timestamping of freeRADIUS logs

yesterday=`date -d yesterday '+%Y%m%d'`
hashesfilename=loghashes.$yesterday.sha1
logprefix=/var/log/radius/radacct


#---------------------------------

cat /dev/null > $logprefix/$hashesfilename

\ls -1 $logprefix/*/*$yesterday* | while read file ; do sha1sum $file >> $logprefix/$hashesfilename; done
echo "Verify using -> openssl ts -verify -data $logprefix/$hashesfilename -in $logprefix/$hashesfilename.tsr -CAfile cacert.pem -untrusted tsa.crt " >> $logprefix/$hashesfilename

openssl ts -query -data $logprefix/$hashesfilename -no_nonce -sha512 -cert -out $logprefix/$hashesfilename.tsq

curl -H "Content-Type: application/timestamp-query" --data-binary '@'$logprefix/$hashesfilename.tsq https://freetsa.org/tsr > $logprefix/$hashesfilename.tsr

cp cacert.pem $logprefix/
cp tsa.crt $logprefix/


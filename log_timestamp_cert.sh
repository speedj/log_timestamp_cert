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

# list all files rotated yesterday and add its name and its sha1sum to a file
\ls -1 $logprefix/*/*$yesterday* | while read file ; do sha1sum $file >> $logprefix/$hashesfilename; done
# Add information to how to verify 
echo "Verify timestamp using -> openssl ts -reply -in $logprefix/$hashesfilename.tsr -text " >> $logprefix/$hashesfilename
echo "---" >> $logprefix/$hashesfilename
echo "Verify signature using -> openssl ts -verify -data $logprefix/$hashesfilename -in $logprefix/$hashesfilename.tsr -CAfile cacert.pem -untrusted tsa.crt " >> $logprefix/$hashesfilename

# Create a Timestamp request
openssl ts -query -data $logprefix/$hashesfilename -no_nonce -sha512 -cert -out $logprefix/$hashesfilename.tsq

# Get a Timestamp response
curl -H "Content-Type: application/timestamp-query" --data-binary '@'$logprefix/$hashesfilename.tsq https://freetsa.org/tsr > $logprefix/$hashesfilename.tsr

# Remove the Timestamp query
\rm $logprefix/$hashesfilename.tsq

# Make a convenience copy of TSA certificates
cp cacert.pem $logprefix/
cp tsa.crt $logprefix/


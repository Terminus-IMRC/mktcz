#!/bin/sh -ex
TCZNAME=openmpi
PKGTARGZ=openmpi-1.8.1.tar.gz
PKGDIR=$(basename "$PKGTARGZ" .tar.gz)
CONFIGURE_OPTS='--prefix=/usr/local CFLAGS="-Os -pipe" CXXFLAGS="-Os -pipe" LDFLAGS="-Wl,-O1"'
MAKE_OPTS=''

if ! test -f $TCZNAME.tcz.info; then
	echo "error: $TCZNAME.tcz.info: no such file"
	exit 1
fi

if ! fgrep -q XXXXX $TCZNAME.tcz.info; then
	echo "error: $TCZNAME.tcz.info: does not contain size substitution"
	exit 1
fi

if echo $PKGDIR | fgrep -q /; then
	echo "error: multi-level package directory is not supported yet"
	exit 1
fi

if ! test -d $PKGDIR; then
	tar xf $PKGTARGZ
fi
cd $PKGDIR

if ! test -f log.c.done; then
	rm -f log.m.done
	./configure $CONFIGURE_OPTS >log.c.1 2>log.c.2
	touch log.c.done
fi

if ! test -f log.m.done; then
	make $MAKE_OPTS >log.m.1 2>log.m.2
	rm -rf ../dest
	mkdir -p ../dest
	make install DESTDIR=$PWD/../dest
	touch log.m.done
fi

cd ../dest
find * -not -type d >../$TCZNAME.tcz.list
cd ..

rm -f $TCZNAME.tcz
mksquashfs dest $TCZNAME.tcz

sed -i "s/XXXXX/$(\du -h $TCZNAME.tcz | awk '{print $1}')/" $TCZNAME.tcz.info

md5sum $TCZNAME.tcz >$TCZNAME.tcz.md5.txt

rm -rf $TCZNAME.tcz.zsync
zsyncmake $TCZNAME.tcz

rm -f $TCZNAME.tar.gz
tar czf $TCZNAME.tar.gz $TCZNAME.tcz $TCZNAME.tcz.info $TCZNAME.tcz.list $TCZNAME.tcz.md5.txt $TCZNAME.tcz.zsync $PKGTARGZ $0

#echo -e 'tinycore\ntinycore' | bcrypt $NAME.tar.gz

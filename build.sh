#!/bin/sh -ex
# mktcz.sh -- for making extensions for TinyCoreLinux
# (c) Akane, alias Sugizaki Yukimasa

. ./build.rc

if test -z "$TCZNAME"; then
	echo "error: \$TCZNAME is empty"
	exit 1
fi
if test -z "$PKGTARGZ"; then
	echo "error: \$PKGTARGZ is empty"
	exit 1
fi

export_if_not_empty(){
	if test -n "$(eval echo \$$1)"; then
		export $1
	fi
}
export_if_not_empty CFLAGS
export_if_not_empty CXXFLAGS
export_if_not_empty LDFLAGS

if echo $PKGDIR | fgrep -q /; then
	echo "error: multi-level package directory is not supported yet"
	exit 1
fi

if ! test -d $PKGDIR; then
	tar xf $PKGTARGZ
fi
cd $PKGDIR

if ! test -f log.c.done; then
	if test -n "$CONFIGURE_OPTS"; then
		./configure $CONFIGURE_OPTS
	else
		./configure
	fi >log.c.1 2>log.c.2
	touch log.c.done
	rm -f log.m.done
fi

if ! test -f log.m.done; then
	if test -n "$MAKE_OPTS"; then
		make $MAKE_OPTS
	else
		make
	fi >log.m.1 2>log.m.2
	rm -rf ../dest
	mkdir -p ../dest
	make install DESTDIR=$PWD/../dest >log.mi.1 2>log.mi.2
	touch log.m.done
fi

find ../dest -name \*.pyc -exec rm {} \;

add_file_as_licence_if_exists(){
	if test -f $1; then
		mkdir -p ../dest/usr/local/share/licences/$TCZNAME
		cp $1 ../dest/usr/local/share/licences/$TCZNAME/
	fi
}
add_file_as_licence_if_exists LICENCE
add_file_as_licence_if_exists LICENSE
add_file_as_licence_if_exists COPYING

cd ..

if ! test -f log.strip.done; then
	cd dest
	#TODO: smarter way is needed
	for f in $(find . -type f); do
		if file $f | grep executable | grep stripped -wq; then
			strip --strip-all $f
		fi
	done
	cd ..
	touch log.strip.done
fi

if ! test -f log.move.done; then
	cd dest

	move_to_another_if_exists(){
		if test -d "$1"; then
			mkdir -p ../dest-$2/${1%/*}
			mv $1 ../dest-$2/${1%/*}/
		fi
	}
	move_to_another_if_exists usr/local/share/man doc
	move_to_another_if_exists usr/local/man doc
	move_to_another_if_exists usr/local/share/doc doc
	move_to_another_if_exists usr/local/include dev
	move_to_another_if_exists usr/local/share/locale locale

	cd ..
	touch log.move.done
fi

if test -d dest-doc; then
	export HAVE_doc=1
fi
if test -d dest-dev; then
	export HAVE_dev=1
fi
if test -d dest-locale; then
	export HAVE_locale=1
fi

pack_all(){
	if ! test -f $1.tcz.info; then
		echo "error: $1.tcz.info: no such file"
		exit 1
	fi

	cd $2
	find * -not -type d >../$1.tcz.list
	cd ..

	rm -f $1.tcz
	mksquashfs $2 $1.tcz

	sed -i "s/\(Size:[ \t]*\).*/\1$(\du -h $1.tcz | awk '{print $1}')/" $1.tcz.info

	md5sum $1.tcz >$1.tcz.md5.txt

	rm -f $1.tcz.zsync
	zsyncmake $1.tcz

	rm -f $1.tar.gz
	tar czf $1.tar.gz $1.tcz $1.tcz.info $1.tcz.list $1.tcz.md5.txt $1.tcz.zsync $(test -f "$1.tcz.dep" && echo $1.tcz.dep || true) $(test -n "$IS_PKGTARBALL_INCLUDE" && echo $PKGTARGZ || true) $(basename $0) build.rc

	#echo -e 'tinycore\ntinycore' | bcrypt $1.tar.gz
}
pack_all $TCZNAME dest
pack_all_co(){
	if test -n "$(eval echo \$HAVE_$1)"; then
		echo $TCZNAME.tcz >$TCZNAME-$1.tcz.dep
		pack_all $TCZNAME-$1 dest-$1
	fi
}
pack_all_co doc
pack_all_co dev
pack_all_co locale

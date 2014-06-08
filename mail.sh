#!/bin/sh
if test -z "$1"; then
	echo "error: specify app.tar.gz" >&2
	exit 1
fi

if ! test -f $1; then
	echo "error: $1: file not found"
	exit 1
fi

if test -z "$(which mutt)"; then
	echo "error: mutt: command not found"
	exit 1
fi

echo "$1 contains below files:"
echo
tar tf $1
echo
read -p "Press return key or so to proceed> " REPLY

TMP=$(mktemp)
cat <<END >$TMP
Hi.

I send you an archive which contains files for $(basename $1 .tar.gz) extension.
Source tarball and build scripts are in the archive.

Please add this extension to the repo.

Regards,
Akane.
END

$EDITOR $TMP

echo "Sending mail..."
mutt -s "Submit $(basename $1 .tar.gz)" -a $1 -- picoresubmit@gmail.com <$TMP

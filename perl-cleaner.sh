#!/usr/local/bin/bash

help() {

	echo "

Usage:

  $0 -h
    - show this message

  $0 -p
    - pretend mode:
      - what p5-* packages would be rebuilt
      - what bsdpan-* packages would be removed
      - what CPAN modules would be installed

  $0 --p5
    - rebuild only p5-* packages

  $0 --bsdpan
    - remove bsdpan-* packages and install appropriate CPAN modules

  $0 --all
    - combination of the two previous

"
	exit 1

}

determine_packages() {
	p5pkg=`pkg info | grep '^p5-' | sed 's/ .*$//'`
	bsdpan_pkg=`pkg info | grep '^bsdpan-' | sed 's/ .*$//'`
	bsdpan_mods=`pkg info | grep '^bsdpan-' | sed 's/^bsdpan-//;s/-[0-9].*$//'`
}

pretend() {
	determine_packages;
	if [ "" = "$p5pkg" ] ; then
		echo "No p5-* packages to rebuild."
	else
		echo "Packages p5-* for rebuild:"
		echo $p5pkg
	fi
	echo
	if [ "" = "$bsdpan_pkg" ] ; then
		echo "No bsdpan-* packages to rebuild."
	else
		echo "Packages bsdpan-* for removal:"
		echo $bsdpan_pkg
		echo
		echo "CPAN modules for installation:"
		echo $bsdpan_mods
	fi
	echo
}

rebuild_p5() {
	determine_packages;
	if [ "" = "$p5pkg" ] ; then
		echo "No p5-* packages to rebuild."
	else
		echo "Rebuilding p5-* packages:"
		echo $p5pkg
		echo
		portmaster -f $p5pkg
	fi
}

rebuild_bsdpan() {
	if [ "" = "$bsdpan_pkg" ] ; then
		echo "No bsdpan-* packages to rebuild."
	else
		determine_packages;
		echo "Removing bsdpan-* packages:"
		echo $bsdpan_pkg
		echo
		pkg delete $bsdpan_pkg
		echo
		echo "Installing CPAN modules:"
		echo $bsdpan_mods
		echo
		cpan $bsdpan_mods
	fi
}


if [ $# -eq 0 ] ; then
		help;
fi

case $1 in

	-h | -help | --help )
		help ;;

	-p )
		pretend ;;

	--p5 )
		rebuild_p5 ;;

	--bsdpan )
		rebuild_bsdpan ;;

	--all )
		rebuild_p5; rebuild_bsdpan ;;

	* )
		help ;;

esac

exit $?

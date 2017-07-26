#!/usr/bin/env bash
##
#

SVN_c=
SVN_f=
SVN_p=

###

#_svnlocal()
#{
	
#}

#TODO
svnlocal_update()
{
	say "TODO"	
}


####

svnlocal()
{
	[ -z $1 ] && say "I need a parameter..." error && exit 1
	[ -z $2 ] && [ -f $2 ] && say "I need a file as second parameter..." error && exit 1
	SVN_c=$1
	SVN_f=$2
	shift	
	shift
	SVN_p=$(cat $SVN_f | grep LOCALSVN | grep HeadURL | sed 's|.*svn://|svn://|g' | sed 's| $.*||g')

	echo "What's left is $*"

	case $SVN_c in
		commit)		svnlocal_commit	$* 	;;
		update)		svnlocal_update $*	;;
		info) 		svnlocal_info   $*	;;
		log) 		svnlocal_log  	$*	;;
	esac
	
}


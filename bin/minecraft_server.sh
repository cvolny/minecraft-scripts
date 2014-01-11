#!/bin/bash

INIT()
{
	BZIP2=/bin/bzip2
	JAVA=/bin/java
	MKTEMP=/bin/mktemp
	MV=/bin/mv
	TAR=/bin/tar
	TAIL=/bin/tail
	TMUX=/bin/tmux

	WORKDIR="$HOME/.minecraft"
	MAPDIR="$WORKDIR/world"
	SESSION="minecraft_server"
	BAKPREFIX="${HOME}/${SESSION}.backup.tar.bz2"
	LOGFILE="${HOME}/${SESSION}.log"
	TMUXOPS="new -d -s $SESSION"
	JAVAOPS="-Xincgc -Xms4G -Xmx4G"
	SRVJAR="$HOME/opt/minecraft_server.jar"
	SRVOPS="-nogui"
	
	WELMSG="Welcome to UT-ACM Minecraft Server!"
	BYEMSG="Server is shutting down now!"
	SAVMSG="Saving world map for backup..."
	SAVMSD="Done Saving!"
}

SENDMSG()
{
	$TMUX send -t $SESSION "$*" C-m
}

START()
{
	(cd $WORKDIR; $TMUX $TMUXOPS "$JAVA $JAVAOPS -jar $SRVJAR $SRVOPS &> $LOGFILE")
	sleep 5
	SENDMSG "say $WELMSG"
}

STOP()
{
	SENDMSG "say $BYEMSG"
	sleep 1
	SENDMSG "save-all"
	sleep 2
	SENDMSG "stop"
}

SAVEMAP()
{
	SENDMSG "say $SAVMSG"
	SENDMSG "save-off"
	SENDMSG "save-all"
	SENDMSG "save-on"
	SENDMSG "say $SAVMSD"
}

BACKUP()
{
	SAVEMAP
	sleep 5
	TMPFILE=`$MKTEMP`
	$TAR -cpf $TMPFILE.tar $MAPDIR 2> /dev/null
	$BZIP2 $TMPFILE.tar
	$MV $BAKPREFIX.3 $BAKPREFIX.4 2> /dev/null
	$MV $BAKPREFIX.2 $BAKPREFIX.3 2> /dev/null
	$MV $BAKPREFIX.1 $BAKPREFIX.2 2> /dev/null
	$MV $BAKPREFIX.0 $BAKPREFIX.1 2> /dev/null
	$MV $TMPFILE.tar.bz2 $BAKPREFIX.0
}

PRINT_USAGE()
{
	echo "Usage:"
	echo "minecraft_server.sh (start|stop|restart|backup|log|msg [msg])"
}

MAIN()
{
	if [ -z "$*" ]; then
		PRINT_USAGE
		exit 1
	fi

	case "$1" in
		"msg")
			shift
			SENDMSG $*
			;;
		"log")
			$TAIL $LOGFILE
			;;
		"backup")
			BACKUP
			;;
		"start")
			START
			;;
		"stop")
			STOP
			;;
		"restart")
			STOP
			START
			;;
		*)
			PRINT_USAGE
			exit 2
			;;
	esac
}

INIT $*
MAIN $*


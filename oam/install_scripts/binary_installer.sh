#!/usr/bin/expect
#
# $Id$
#
# Install RPM and custom OS files on system
# Argument 1 - Remote Module Name
# Argument 2 - Remote Server Host Name or IP address
# Argument 3 - User Password of remote server
# Argument 4 - Package name being installed
# Argument 5 - Module type?
# Argument 6 - Install Type, "initial" or "upgrade"
# Argument 7 - Server type?
# Argument 8 - Debug flag 1 for on, 0 for off
# Argument 9 - install dir (optional)
# Argument 10 - user name (optional)
set USERNAME root
set MODULE [lindex $argv 0]
set SERVER [lindex $argv 1]
set PASSWORD [lindex $argv 2]
set CALPONTPKG [lindex $argv 3]
set MODULETYPE [lindex $argv 4]
set INSTALLTYPE [lindex $argv 5]
set PKGTYPE "binary"
set SERVERTYPE [lindex $argv 6]
set MYSQLPORT [lindex $argv 7]
set DEBUG [lindex $argv 8]
set INSTALLDIR "/usr/local/mariadb/columnstore"
set IDIR [lindex $argv 9]
if { $IDIR != "" } {
	set INSTALLDIR $IDIR
}
set env(COLUMNSTORE_INSTALL_DIR) $INSTALLDIR
set PREFIX [file dirname $INSTALLDIR]
set PREFIX [file dirname $PREFIX]
set USERNAME $env(USER)
set UNM [lindex $argv 10]
if { $UNM != "" } {
	set USERNAME $UNM
}
set DEPLOY_PACKAGES [lindex $argv 11]

set BASH "/bin/bash "
if { $DEBUG == "1" } {
	set BASH "/bin/bash -x "
}

log_user $DEBUG
spawn -noecho /bin/bash
#
if { $DEPLOY_PACKAGES } {
    if { $INSTALLTYPE == "initial" || $INSTALLTYPE == "uninstall" } {
        #
        # remove MariaDB Columnstore files
        #
        send_user "Uninstall MariaDB Columnstore Package                       "
        send " \n"
        send date\n
        send "ssh $USERNAME@$SERVER 'rm -f /etc/init.d/columnstore /etc/init.d/mysql-Columnstore $INSTALLDIR/releasenum >/dev/null 2>&1'\n"
        set timeout 20
        expect {
            "Host key verification failed" { send_user "FAILED: Host key verification failed\n" ; exit 1}
            "service not known" { send_user "FAILED: Invalid Host\n" ; exit 1}
            "authenticity" { send "yes\n"
                                expect {
                                    "word: " { send "$PASSWORD\n" }
                                    "passphrase" { send "$PASSWORD\n" }
                                }
            }
            "word: " { send "$PASSWORD\n" }
            "passphrase" { send "$PASSWORD\n" }
            "Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
            "No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
            "MariaDB Columnstore uninstall completed"	{ send_user "DONE" }
        }
        set timeout 30
        expect {
            "Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
            "MariaDB Columnstore uninstall completed"	{ send_user "DONE" }
        }
        send_user "\n"
    }
}
if { $INSTALLTYPE == "uninstall" } {
	exit 0
}
if { $DEPLOY_PACKAGES } {
    sleep 10
    #
    # send the MariaDB Columnstore package
    #
    send_user "Copy New MariaDB Columnstore Package to Module              "
    send " \n"
    send date\n
    send "scp $CALPONTPKG $USERNAME@$SERVER:$CALPONTPKG\n"
    set timeout 10
    expect {
        "word: " { send "$PASSWORD\n" }
        "passphrase" { send "$PASSWORD\n" }
    }
    set timeout 120
    expect {
        "100%" 				{ send_user "DONE" }
        "scp:"  			{ send_user "ERROR\n" ;
                                send_user "\n*** Installation ERROR\n" ;
                                exit 1 }
        "Permission denied, please try again"         { send_user "ERROR: Invalid password\n" ; exit 1 }
        "No such file or directory" { send_user "ERROR: Invalid package\n" ; exit 1 }
        "Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
        "Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
        "Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
        "No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
        timeout { send_user "ERROR: Timeout\n" ; exit 1 }
    }
    send_user "\n"
    #sleep to make sure it's finished
    sleep 5
    #
    # install package
    #
    send_user "Install MariaDB Columnstore Package on Module               "
    send " \n"
    send date\n
    send "ssh $USERNAME@$SERVER 'tar -C $PREFIX --exclude db -zxf $CALPONTPKG;cat $INSTALLDIR/releasenum'\n"
    set timeout 10
    expect {
        "word: " { send "$PASSWORD\n" }
        "passphrase" { send "$PASSWORD\n" }
    }
    set timeout 120
    expect {
        "release=" 		  	{ send_user "DONE" }
        "No such file" 		  { send_user "ERROR: Binary Install Failed, binary/releasenum not found\n" ; exit 1 }
        "Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
        "Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
        "Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
        "Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
        "No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
        timeout { send_user "ERROR: Timeout\n" ; exit 1 }
    }
    #sleep to give time for cat MariaDB Columnstore/releasenum to complete
    sleep 5
}

send_user "\n"
send_user "Run post-install script                         "
send " \n"
send date\n
send "ssh $USERNAME@$SERVER '$INSTALLDIR/bin/post-install --installdir=$INSTALLDIR'\n"
set timeout 10
expect {
	"word: " { send "$PASSWORD\n" }
	"passphrase" { send "$PASSWORD\n" }
}
set timeout 60
# check return
expect {
	"MariaDB Columnstore syslog logging not working" { send_user "ERROR: MariaDB Columnstore System logging not setup\n" ; exit 1 }
	"Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
	"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
	"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
	"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
	"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
	"postConfigure" { send_user "DONE" }
}
send_user "\n"
sleep 10
#
if { $INSTALLTYPE == "initial"} {
	#
	# copy over calpont config file
	#
	send_user "Copy MariaDB Columnstore Config file to Module              "
	send " \n"
	send date\n
	send "scp $INSTALLDIR/etc/* $USERNAME@$SERVER:$INSTALLDIR/etc\n"
	set timeout 10
	expect {
		"word: " { send "$PASSWORD\n" }
		"passphrase" { send "$PASSWORD\n" }
	}
	set timeout 30
	expect {
		-re {[$#] } 		  		  { send_user "DONE" }
		"Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
		"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
		"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
		"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
		"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
	}
	send_user "\n"
	#
	# copy over custom OS tmp files
	#
	send_user "Copy Custom OS files to Module                  "
	send " \n"
	send date\n
	send "scp -r $INSTALLDIR/local/etc $USERNAME@$SERVER:$INSTALLDIR/local\n"
	set timeout 10
	expect {
		"word: " { send "$PASSWORD\n" }
		"passphrase" { send "$PASSWORD\n" }
	}
	set timeout 60
	expect {
		-re {[$#] } 		  		  { send_user "DONE" }
		"Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
		"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
		"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
		"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
		"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
	}
	send_user "\n"
	#
	# copy over calpont OS files
	#
	send_user "Copy MariaDB Columnstore OS files to Module                 "
	send " \n"
	send date\n
	send "scp $INSTALLDIR/local/etc/$MODULE/*  $USERNAME@$SERVER:$INSTALLDIR/local\n"
	set timeout 10
	expect {
		"word: " { send "$PASSWORD\n" }
		"passphrase" { send "$PASSWORD\n" }
		"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
	}
	set timeout 60
	expect {
		-re {[$#] } 		  		  { send_user "DONE" }
		"Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
		"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
		"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
		"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
	}
	send_user "\n"
	#
	# Start module installer to setup Customer OS files
	#
	send_user "Run Module Installer                            "
	send " \n"
	send date\n
	send "ssh $USERNAME@$SERVER '$INSTALLDIR/bin/module_installer.sh --module=$MODULETYPE --port=$MYSQLPORT --installdir=$INSTALLDIR'\n"
	set timeout 10
	expect {
		"word: " { send "$PASSWORD\n" }
		"passphrase" { send "$PASSWORD\n" }
	}
	set timeout 60
	expect {
		"!!!Module" 				  			{ send_user "DONE" }
		"Permission denied, please try again"   { send_user "ERROR: Invalid password\n" ; exit 1 }
		"FAILED"   								{ send_user "ERROR: missing module file\n" ; exit 1 }
		"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
		"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
		"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
		"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
		"No such file"   { send_user "ERROR: File Not Found\n" ; exit 1 }
        	"WARNING"   { send_user "WARNING: SYSLOG setup failed\n" }
	}
	send_user "\n"
	sleep 10
	if { $MODULETYPE == "um" || $SERVERTYPE == "2" || $SERVERTYPE == "pmwithum" } { 
		#
		# run mysql setup scripts
		#
		send_user "Run MySQL Setup Scripts on Module               "
		send " \n"
		send date\n
		send "ssh $USERNAME@$SERVER '$INSTALLDIR/bin/post-mysqld-install --installdir=$INSTALLDIR'\n"
		set timeout 10
		expect {
			"word: " { send "$PASSWORD\n" }
			"passphrase" { send "$PASSWORD\n" }
		}
		set timeout 60
		expect {
			"ERROR" { send_user "ERROR: Daemon failed to run";
			exit 1 }
			"FAILED" { send_user "ERROR: Daemon failed to run";
			exit 1 }
			"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
			"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
			"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
			"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
		}

		send " \n"
		send date\n
		send "ssh $USERNAME@$SERVER '$INSTALLDIR/bin/post-mysql-install --installdir=$INSTALLDIR'\n"
		set timeout 10
		expect {
			"word: " { send "$PASSWORD\n" }
			"passphrase" { send "$PASSWORD\n" }
		}
		set timeout 60
		expect {
			"Shutting down mysql." { send_user "DONE" }
			timeout { send_user "DONE" }
			"ERROR" { send_user "ERROR: Daemon failed to run";
			exit 1 }
			"FAILED" { send_user "ERROR: Daemon failed to run";
			exit 1 }
			"Read-only file system" { send_user "ERROR: local disk - Read-only file system\n" ; exit 1}
			"Connection refused"   { send_user "ERROR: Connection refused\n" ; exit 1 }
			"Connection closed"   { send_user "ERROR: Connection closed\n" ; exit 1 }
			"No route to host"   { send_user "ERROR: No route to host\n" ; exit 1 }
		}
		send_user "\n"
	}
}


send_user "\nInstallation Successfully Completed on '$MODULE'\n"
exit 0


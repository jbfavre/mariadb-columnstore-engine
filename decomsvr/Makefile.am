# Copyright (C) 2014 InfiniDB, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2 of
# the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

# $Id$
## Process this file with automake to produce Makefile.in

AM_CPPFLAGS = $(idb_cppflags)
AM_CFLAGS = $(idb_cflags)
AM_CXXFLAGS = $(idb_cxxflags)
AM_LDFLAGS = $(idb_ldflags)
bin_PROGRAMS = DecomSvr
DecomSvr_SOURCES = quicklz.c server.cpp
DecomSvr_CPPFLAGS = $(idb_common_includes) $(AM_CPPFLAGS)
DecomSvr_LDFLAGS = $(idb_common_ldflags)  $(AM_LDFLAGS) -lpthread -lrt -lboost_system -lboost_filesystem -lboost_thread -lboost_regex


test:

coverage:

leakcheck:

docs:

bootstrap: install-data-am


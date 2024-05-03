<p align="center">
  <a href="https://bestpractical.com/rtir">
    <img src="https://static.bestpractical.com/rt-ir-logo.png" alt="Best Practical logo" width="500">
  </a>
</p>

<h1 align="center">Request Tracker for Incident Response (RTIR)</h1>

RT for Incident Response is an open source, industrial-grade
incident-handling tool designed to provide a simple, effective
workflow for members of CERT and CSIRT teams. It allows team members
to track, respond to and deal with reported incidents and features a
number of tools to make common operations quick and easy.  RTIR is
built on top of RT, which is also available for free from Best
Practical Solutions at [http://www.bestpractical.com/rt/](http://www.bestpractical.com/rt/).

RT and RTIR are commercially-supported software. To purchase support,
training, custom development, or professional services, please get in
touch with us at [sales@bestpractical.com](mailto:sales@bestpractical.com).

## REQUIRED PACKAGES

- RT version 4.4.1 or later.
- Net::Whois::RIPE 1.31 is bundled with RTIR for compatibility with the
  API RTIR uses and for a fix to run without warnings under perl 5.18.

## UPGRADE INSTRUCTIONS

If you've installed a prior version of RTIR, you will need to follow
special steps to upgrade.  See the docs/UPGRADING file for detailed
information.

## INSTALLATION INSTRUCTIONS

1. Install the current release of the RT 5.0 series following RT's
regular installation instructions

2. Run "perl Makefile.PL" to generate a makefile for RTIR.

3. Install any extra Perl modules RTIR needs that aren't already
installed. The output from the previous step will list new
modules needed, or if existing modules need to be upgraded to a
newer version.

4. Type "make install".

5. Activate the RTIR extension by putting the following line in your
RT's etc/RT_SiteConfig.pm file:
```perl
  Plugin('RT::IR');
```
6. Database:

   A. If you are installing RTIR for the first time, initialize the RTIR
database by typing "make initdb".

   WARNING: Do not attempt to re-initialize the database if you are
upgrading.

   B. If you are UPGRADING from a previous installation, read the
UPGRADING file for instructions on how to upgrade your
database.

1. Stop and start your web server.


## CONFIGURING RTIR

1. Using RT's configuration interface, add the email address
of the Network Operations Team (the people who will handle
activating and removing network blocks) as AdminCc on the
Countermeasures queue.
   RT -> Queues -> Countermeasures -> Watchers

2. You may want to modify the email messages that are automatically
   sent on the creation of Investigations and Countermeasures.

   RT -> Queues -> <Select RTIR's Queue> -> Templates.

   RT -> Global -> Templates.

3. By default, RT ships with a number of global Scrips.  You should use
   RT's configuration interface to look through them, and disable any
   that aren't apropriate in your environment.

   RT -> Queues -> <Select RTIR's Queue> -> Scrips.

   RT -> Global -> Scrips.

4. Add staff members who handle incidents to the DutyTeam group.

   RT -> Configuration -> Groups -> DutyTeam -> Members.

5. You can override values defined in RTIR_Config.pm by creating
   RTIR_SiteConfig.pm in /opt/rt5/etc/ and adding your customizations.

## SETTING UP THE MAIL GATEWAY

An alias for the Incident Reports queue will need to be configured.
Add the following lines to /etc/aliases (or your local equivalent):
```
rtir:         "|/opt/rt5/bin/rt-mailgate --queue 'Incident Reports' --action correspond --url http://rt.example.com/"
```

You should substitute the URL for RT's web interface for http://rt.example.com/.

-  If your webserver uses SSL, rt-mailgate will require several new
   Perl libraries. See the RT README for more details on this option.

-  See "perldoc /opt/rt5/bin/rt-mailgate" for more info about the rt-mailgate
   script.

-  If you're configuring RTIR with support for multiple constituencies, please
   refer to the instructions in the file docs/Constituencies.pod which is also
   viewable here [http://www.bestpractical.com/docs/rtir/4.0/Constituencies.html](http://www.bestpractical.com/docs/rtir/4.0/Constituencies.html)

## DOCUMENTATION FOR RTIR

- Documents included with RTIR are also available for browsing at
  [http://www.bestpractical.com/docs/rtir/5.0/](http://www.bestpractical.com/docs/rtir/5.0/)

- This README file

- docs/UPGRADING

- docs/UPGRADING-*
   - Version specific upgrading files. If upgrading from 3.0, you
     would read the UPGRADING-3.0, UPGRADING-3.2, UPGRADING-4.0
     and UPGRADING-5.0 files.

- docs/Tutorial.pod
   - ( also at [http://bestpractical.com/docs/rtir/5.0/Tutorial](http://bestpractical.com/docs/rtir/5.0/Tutorial) )
   - Extended information about ticket merging

- docs/Constituencies.pod
   - ( also at [http://bestpractical.com/docs/rtir/5.0/Constituencies](http://bestpractical.com/docs/rtir/5.0/Constituencies) )
   - Information about setting up RTIR with multiple user constituencies

- docs/AdministrationTutorial.pod
   - ( also at [http://bestpractical.com/docs/rtir/5.0/AdministrationTutorial](http://bestpractical.com/docs/rtir/5.0/AdministrationTutorial) )
   - Information about setting up RTIR for Administrators

- etc/RTIR_Config.pm
   - Contains a number of RTIR-specific configuration options and
     instructions for their use
   - [http://www.bestpractical.com/docs/rtir/5.0/RTIR_Config.html](http://www.bestpractical.com/docs/rtir/5.0/RTIR_Config.html)

- RTIR mailing list
   - Subscribe by sending mail to [rtir-request@lists.bestpractical.com](rtir-request@lists.bestpractical.com).

## DEVELOPMENT

If you would like to run RTIR's tests, you need to set a few environment
variables:

RT_DBA_USER - a user who can create a database on your RDBMS
              (such as root on mysql)
RT_DBA_PASSWORD - the password for RT_DBA_USER

To run tests:

```sh
$ RTHOME=/opt/my-rt perl Makefile.PL
$ RT_DBA_USER=user RT_DBA_PASSWORD=password make test
```

These are intended to be run before installing RTIR.

Like RT, RTIR expects to be able to create a new database called rt5test
on your system

## REPORTING BUGS

To report a bug, send email to [rtir-bugs@bestpractical.com](mailto:rtir-bugs@bestpractical.com).


# COPYRIGHT AND LICENSE

COPYRIGHT:

This software is Copyright (c) 1996-2024 Best Practical Solutions, LLC
                                         <sales@bestpractical.com>

(Except where explicitly superseded by other copyright notices)


LICENSE:

This work is made available to you under the terms of Version 2 of
the GNU General Public License. A copy of that license should have
been provided with this software, but in any event can be snarfed
from www.gnu.org.

This work is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 or visit their web page on the internet at
http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.


CONTRIBUTION SUBMISSION POLICY:

(The following paragraph is not intended to limit the rights granted
to you to modify and distribute this software under the terms of
the GNU General Public License and is only of importance to you if
you choose to contribute your changes and enhancements to the
community by submitting them to Best Practical Solutions, LLC.)

By intentionally submitting any modifications, corrections or
derivatives to this work, or any other work intended for use with
Request Tracker, to Best Practical Solutions, LLC, you confirm that
you are the copyright holder for those contributions and you grant
Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
royalty-free, perpetual, license to use, copy, create derivative
works based on those contributions, and sublicense and distribute
those contributions and any derivatives thereof.


# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2017 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package RT::IR::Test::GnuPG;
use strict;
use warnings;
use Test::More;
use base qw(RT::IR::Test);
use File::Temp qw(tempdir);

sub import {
    my $class = shift;
    my %args  = @_;
    my $t     = $class->builder;

    $t->plan( skip_all => 'GnuPG required.' )
      unless eval { require GnuPG::Interface; 1 };
    $t->plan( skip_all => 'gpg executable is required.' )
      unless RT::Test->find_executable('gpg');

    $class->SUPER::import(%args);

    RT::Test::diag "GnuPG --homedir " . RT->Config->Get('GnuPGOptions')->{'homedir'};

    $class->add_rights(
        Principal => 'Everyone',
        Right => ['CreateTicket', 'ShowTicket', 'SeeQueue', 'ReplyToTicket', 'ModifyTicket'],
    );
}

sub bootstrap_more_config {
    my $self = shift;
    my $handle = shift;
    my $args = shift;

    $self->SUPER::bootstrap_more_config($handle, $args, @_);

    my %gnupg_options = (
        'no-permission-warning' => undef,
        $args->{gnupg_options} ? %{ $args->{gnupg_options} } : (),
    );
    $gnupg_options{homedir} ||= scalar tempdir( CLEANUP => 1 );

    use Data::Dumper;
    local $Data::Dumper::Terse = 1; # "{...}" instead of "$VAR1 = {...};"
    my $dumped_gnupg_options = Dumper(\%gnupg_options);

    print $handle qq{
Set(\%GnuPG, (
    Enable                 => 1,
    OutgoingMessagesFormat => 'RFC',
));
Set(\%GnuPGOptions => \%{ $dumped_gnupg_options });
Set(\@MailPlugins => qw(Auth::MailFrom));
};

}

1;

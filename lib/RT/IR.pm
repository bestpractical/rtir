# {{{ BEGIN BPS TAGGED BLOCK
# 
# COPYRIGHT:
#  
# This software is Copyright (c) 1996-2004 Best Practical Solutions, LLC 
#                                          <jesse@bestpractical.com>
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
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
# }}} END BPS TAGGED BLOCK
#
package RT::IR;
use warnings;
use strict;

use Business::Hours;
use Business::SLA;

sub BusinessHours {

    my $bizhours = new Business::Hours;
    if ( RT->Config->Get('BusinessHours') ) {
        $bizhours->business_hours( %{ RT->Config->Get('BusinessHours') } );
    }

    return $bizhours;
}

sub DefaultSLA {

    my $sla;
    my $SLAObj = SLAInit();
    $sla = $SLAObj->SLA(time());

    return $sla;

}

sub SLAInit {

    my $class = RT->Config->Get('SLAModule') || 'Business::SLA';

    my $SLAObj = $class->new();

    my $bh = RT::IR::BusinessHours();
    $SLAObj->SetInHoursDefault( RT->Config->Get('_RTIR_SLA_inhours_default') );
    $SLAObj->SetOutOfHoursDefault( RT->Config->Get('_RTIR_SLA_outofhours_default') );

    $SLAObj->SetBusinessHours($bh);

    my $SLA = RT->Config->Get('SLA');
    foreach my $key( keys %$SLA ) {
        if ( $SLA->{ $key } =~ /^\d+$/ ) {
            $SLAObj->Add( $key, ( BusinessMinutes => $SLA->{ $key } ) );
        } else {
            $SLAObj->Add( $key, %{ $SLA->{ $key } } );
        }
    }

    return $SLAObj;

}


# IPs processing hooks
# in order too implement searches by IP ranges we
# store IPs in "%03d.%03d.%03d.%03d" format so ops
# like > and < make sense.
use Hook::LexWrap;
use Regexp::Common qw(RE_net_IPv4);
use Regexp::Common::net::CIDR;
require Net::CIDR;

# limit formatting "%03d.%03d.%03d.%03d"
require RT::Tickets;
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return unless $_[3] =~ /^\s*($RE{net}{IPv4})\s*$/o;
        $_[3] = sprintf "%03d.%03d.%03d.%03d", split /\./, $1;
    };

# "= 'sIP-eIP'" => "( >=sIP AND <=eIP)"
# "!= 'sIP-eIP'" => "( <sIP AND >eIP)"
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return unless $_[3] =~ /^\s*($RE{net}{IPv4})\s*-\s*($RE{net}{IPv4})\s*$/o;
        my ($start_ip, $end_ip) = ($1, $2);
        my ($tickets, $field, $op, $value, @rest) = @_[0..($#_-1)];
        my $negative = ($op =~ /NOT|!=|<>/i)? 1 : 0;
        $tickets->_OpenParen;
        $tickets->_CustomFieldLimit($field, ($negative? '<': '>='), $start_ip, @rest);
        $tickets->_CustomFieldLimit($field, ($negative? '>': '<='), $end_ip, @rest, ENTRYAGGREGATOR => 'AND');
        $tickets->_CloseParen;
        # return right now as we did everything
        $_[-1] = ref @_[-1]? [1]: 1;
    };

# "[!]= 'CIDR'" => "op 'sIP-eIP'"
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return unless $_[3] =~ /^\s*$RE{net}{CIDR}{IPv4}{-keep}\s*$/o;
        # convert incomplete 192.168/24 to 192.168.0.0/24 format
        my $cidr = join( '.', map $_||0, (split /\./, $1)[0..3] ) ."/$2";
        # convert to range and continue, it will be catched by next wrapper
        $_[3] = (Net::CIDR::cidr2range( $cidr ))[0] || $_[3];
    };
$RT::Tickets::dispatch{'CUSTOMFIELD'} = \&RT::Tickets::_CustomFieldLimit;

# on OCFV create format storage
require RT::ObjectCustomFieldValue;
wrap 'RT::ObjectCustomFieldValue::Create',
    pre => sub {
        for ( my $i = 1; $i < @_; $i += 2 ) {
            next unless $_[$i] && $_[$i] eq 'Content';
            return unless $_[++$i] =~ /^\s*($RE{net}{IPv4})\s*$/o;
            $_[$i] = sprintf "%03d.%03d.%03d.%03d", split /\./, $1;
            return;
        }
    };

# strip zero chars(deserialize)
wrap 'RT::ObjectCustomFieldValue::Content',
    post => sub {
        return unless $_[-1];
        if ( ref $_[-1] ) {
            return unless $_[-1][0] =~ /^\s*($RE{net}{IPv4})\s*$/;
            $_[-1][0] = sprintf "%d.%d.%d.%d", split /\./, $1;
        } else {
            return unless $_[-1] =~ /^\s*($RE{net}{IPv4})\s*$/;
            $_[-1] = sprintf "%d.%d.%d.%d", split /\./, $1;
        }
    };

eval "require RT::IR_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IR_Vendor.pm});
eval "require RT::IR_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/IR_Local.pm});

1;

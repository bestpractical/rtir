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
 


package RT::Condition::RTIR_RequireStateChange;


use strict;

use base 'RT::Condition::RTIR';


=head2 IsApplicable

If the ticket was closed

=cut

sub IsApplicable {
    my $self = shift;

    my $type = $self->TransactionObj->Type;
    return 1 if $type eq "Create" or $type eq "CustomField";
    return 1 if $self->IsStatusChange;

    my $field = $self->TransactionObj->Field;
    return 1 if
        ( $type =~ /^(Add|Delete)Link$/ and $field eq "MemberOf" ) or
        ( $type eq "Set" and $field eq "Queue" );

    return 0;
}

eval "require RT::Condition::RTIR_RequireStateChange_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireStateChange_Vendor.pm});
eval "require RT::Condition::RTIR_RequireStateChange_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/RTIR_RequireStateChange_Local.pm});

1;


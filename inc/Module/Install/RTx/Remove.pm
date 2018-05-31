#line 1
package Module::Install::RTx::Remove;

use base 'Exporter';
our @EXPORT = qw/RTxRemove/;

use strict;

#line 27

sub RTxRemove {
    my $remove_files = shift;

    # Trying the naive unlink first. If issues are reported,
    # look at ExtUtils::_unlink_or_rename for more cross-platform options.
    foreach my $file (@$remove_files){
        next unless -e $file;
        print "Removing $file\n";
        unlink($file) or warn "Could not unlink $file: $!";
    }
}

use strict;
use warnings;

use RT::IR::Test tests => undef;

RT::Test->started_ok;
my $m = default_agent();

$m->create_incident( { Subject => "Spam Incident", }, { ('Classification' => 'Spam') } );
$m->create_incident( { Subject => "Ham Incident", },  { ('Classification' => 'Query') } );

$m->get_ok('/RTIR/Search/');
$m->form_name( 'BuildQuery' );

$m->submit_form(
    fields    => { 'ValueOfQueue' => 'Incidents' },
    button    => 'AddClause',
);

$m->form_name( 'BuildQuery' );
my ($cf_field) = $m->find_all_inputs( type => 'option', name_regex => qr/ValueOf.*Classification/ );
$m->submit_form(
    fields    => { $cf_field->name => 'Spam', },
    button    => 'DoSearch',
);

$m->content_contains( 'Spam Incident', 'has spam incident' );
# failure mode is that the CF isn't added and so we find all incidents
# we should only be finding Queue = 'Incidents' and CF.Classification = 'Spam'
$m->content_lacks( 'Ham Incident', 'has not found the ham incident' );

done_testing;

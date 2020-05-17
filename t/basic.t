use warnings;
use strict;
use v5.20;

use Test::More;
use FindBin;
use Web::Mention;
use Path::Tiny;
use Try::Tiny;

use lib "$FindBin::Bin/../lib";
use_ok("Whim");

initialize_tests();

diag("Create Whim object");
my $whim = Whim->new( { data_directory => "$FindBin::Bin/run" } );

{
    my $count = $whim->fetch_webmentions( {} );

    is( $count, 0, 'Zero wms in db at the start of testing.' );
}

{
    diag("Webmention receipt (no tests)");
    my $wm_file = path("$FindBin::Bin/source/many_wms.html");

    my @wms = Web::Mention->new_from_html(
        source => 'file://' . $wm_file->absolute,
        html   => $wm_file->slurp,
    );

    for my $wm (@wms) {
        $whim->receive_webmention($wm);
    }
}

{
    diag("Webmention verification");
    my $count = $whim->process_webmentions;
    is( $count, 7, "Processed expected number of stored webmentions." );

    $count = $whim->fetch_webmentions( {} );

    is( $count, 7, 'Received WMs are in the database.' );
}

{
    diag("Webmention querying");
    my @wms = $whim->fetch_webmentions( { target => 'reply-target' } );
    is( scalar(@wms), 2, "Simple query worked as expected." );
}

done_testing();

sub initialize_tests {
    foreach my $child ( path("$FindBin::Bin/run")->children ) {
        try { $child->remove_tree };
    }
}

#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

plugin('JSLoader');

get '/invalid1' => sub {
    shift->render( 'invalid' );
};
get '/invalid2' => sub {
    my $c = shift;
    $c->js_load( <<'JS', {js => 1, once => 'warn'} );
    $(document).ready(function(){ alert('test') });
JS
    $c->render( 'simple' );
};
get '/warn' => sub {
    shift->render( 'warn' );
};
get '/die' => sub {
    shift->render( 'die' );
};
get '/custom' => sub {
    shift->render( 'custom' );
};
get '/mixed' => sub {
    shift->render( 'mixed' );
};


## Webapp END

my $t = Test::Mojo->new;
$t->get_ok( '/invalid1' )->status_is( 500 );
$t->get_ok( '/invalid2' )->status_is( 500 );

{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    $t->get_ok( '/warn' )->status_is( 200 );
    is_deeply \@warn, ["file1.js used more than once.\n"];
}

$t->get_ok( '/die' )->status_is( 500 );
$t->get_ok( '/custom' )->status_is( 200 );
is $main::custom, 1;

$t->get_ok( '/mixed' )->status_is( 500 );

done_testing();

__DATA__
@@ simple.html.ep
TEST
@@ invalid.html.ep
% js_load( "alert('default');", {no_file => 1, once => 'warn'} );
@@ warn.html.ep
% js_load( "file1.js", { once => 'warn' } );
% js_load( "file1.js" );
@@ die.html.ep
% js_load( "file2.js", { once => 'die' } );
% js_load( "file2.js" );
@@ custom.html.ep
% js_load( "file3.js", { once => sub { ++$main::custom } } );
% js_load( "file3.js" );
% js_load( "file4.js", { once => 'die' } );
@@ mixed.html.ep
% js_load( "file5.js", { once => 'warn' } );
% js_load( "file5.js", { once => 'die' } );


#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', '../lib';
use Mojolicious::Lite;

plugin('JSLoader', { base => '/js' });

any '/' => sub {
    my $self = shift;

    $self->render( 'default' );
};

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->render( 'hello' );
}

any '/no' => sub { shift->render( 'nofile' ) };

app->start;

__DATA__
@@ default.html.ep
% js_load( 'js_file.js' );

@@ hello.html.ep
% js_load( 'test.js', {no_base => 1} );
<html>
<body>
  <div><test /></div>
</body>
</html>

@@ nofile.html.ep
% js_load( '$(document).ready( function() { alert("test") } )', {no_file => 1} );


package Mojolicious::Plugin::JSLoader;

# ABSTRACT: move js loading to the end of the document

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

our $VERSION = 0.01;

sub register {
    my ($self, $app, $config) = @_;

    my $base = $config->{base} || '';

    if ( $base and substr( $base, -1 ) ne '/' ) {
        $base .= '/';
    }

    $app->helper( js_load => sub {
        my $c = shift;
        push @{ $c->stash->{__JSLOADERFILES__} }, [ @_ ];
    } );

    $app->hook( after_render => sub {
        my ($c, $content, $format) = @_;

        return if $format ne 'html';
        return if !$c->stash->{__JSLOADERFILES__};

        my $load_js = join "\n", 
                      map{
                          my ($file,$config) = @{ $_ };
                          my $local_base = $config->{no_base} ? '' : $base;
                          $config->{no_file} ? 
                              qq~<script type="text/javascript">$file</script>~ :
                              qq~<script type="text/javascript" src="$local_base$file"></script>~;
                      }
                      @{ $c->stash->{__JSLOADERFILES__} || [] };

        return if !$load_js;

        ${$content} =~ s!(</body(?:\s|>)|\z)!$load_js$1!;
    });
}

1;

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'JSLoader' );

        # more Mojolicious stuff
    }

In your template:

    <% js_load('js_file.js') %>

=head1 HELPERS

This plugin adds a helper method to your web application:

=head2 js_load

This method requires at least one parameter: The path to the JavaScript file to load.
An optional second parameter is the configuration. You can switch off the I<base> for
this JavaScript file this way:

  # <script type="text/javascript" src="$base/js_file.js"></script>
  <% js_load('js_file.js') %>
  
  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <% js_load('http://domain/js_file.js', {no_base => 1});

=head1 HOOKS

When you use this module, a hook for I<after_render> is installed. That hook inserts
the C<< <script> >> tag at the end of the document or right before the closing
C<< <body> >> tag.

=head1 METHODS

=head2 register

Called when registering the plugin. On creation, the plugin accepts a hashref to configure the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'JSLoader' );

=head3 Configuration

    $self->plugin( 'JSLoader' => {
        base => 'http://domain/js',  # base for all <script> tags
    });

=head1 NOTES

This plugin uses the I<stash> key C<__JSLOADERFILES__>, so you should avoid using
this stash key for your own purposes.


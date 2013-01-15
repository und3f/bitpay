package Business::Bitpay;

use strict;
use warnings;

use 5.008_001;
our $VERSION = '0.02';
eval $VERSION;

use HTTP::Request;
use URI;
use JSON qw(encode_json decode_json);
use LWP::UserAgent;
require Carp;

sub new {
    my ($class, $api_key, @args) = @_ or Carp::croak("api key missed");

    bless {
        key     => $api_key,
        gateway => 'https://bitpay.com/api/',
        ua      => LWP::UserAgent->new,
        @args
    }, $class;
}

sub prepare_request {
    my ($self, $api, $data) = @_;

    my $uri = URI->new($self->{gateway});
    $uri->userinfo($self->{key} . ':');
    $uri->path($uri->path . $api);

    my $method = 'GET';
    if ($data) {
        $method = 'POST';
        $data   = encode_json $data;
    }

    my $request = HTTP::Request->new(
        $method => $uri, [
            'Content-Type' => 'application/json',
            'User-Agent'   => 'bitpay api'
        ],
        $data
    );
}

sub request {
    my $self = shift;

    my $http_response = $self->{ua}->request($self->prepare_request(@_));
    Carp::croak($http_response->status_line)
      unless $http_response->is_success;

    my $response = decode_json($http_response->decoded_content);

    if (my $error = $response->{error}) {
        my $messages = $error->{messages};
        Carp::croak("$error->{message}: ",
            join(', ', map {"$_ ($messages->{$_})"} keys %$messages));
    }

    $response;
}


sub create_invoice {
    my ($self, %args) = @_;

    Carp::croak('price missed')    unless exists $args{price};
    Carp::croak('currency missed') unless exists $args{currency};

    $self->request('invoice', \%args);
}

sub get_invoice {
    my ($self, $id) = @_;

    $self->request("invoice/$id");
}

1;
__END__

=head1 NAME

Business::Bitpay - Bitpay API

=head1 SYNOPSIS

    use Business::Bitpay;
    my $bitpay = Business::Bitpay->new($api_key);

    # create new invoice
    $invoice = $bitpay->create_invoice(price => 10, currency => 'USD');

    # get invoice data
    $invoice = $bitpay->get_invoice($invoice->{id});

=head1 DESCRIPTION
    
Bitpay API documentation contents full description of API methods
L<https://bitpay.com/help-api>.

=head2 C<new>

    my $bitpay = Business::Bitpay->new($api_key);

Construct Business::Bitpay object.

=head2 C<create_invoice>

    my $invoice = $bitpay->create_invoice(price => 10, currency => 'USD');

Creates new invoice. This method will croak in case of error. Full list of
fields and their description can be found in C<Creating an Invoice> section of
Bitpay API documentation.

Returns hashref representing of the invoice object. Description can be found in
C<BitPay Server Response> section of the Bitpay API documentation.

=head2 C<get_invoice>

    my $invoice = $bitpay->get_invoice($invoice_id);

Returns invoice hashref or croak if error occurred. Returned invoice object has
exactly the same format as that which is returned when creating an invoice.

=head1 SEE ALSO

L<https://bitpay.com/downloads/bitpayApi.pdf>

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut

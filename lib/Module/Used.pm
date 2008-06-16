package Module::Used;

use 5.008003;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.0.1');

use English qw<-no_match_vars>;
use Readonly;

use Exporter qw< import >;

our @EXPORT_OK =
    qw<
        modules_used_in_files
        modules_used_in_string
        modules_used_in_document
    >;
our %EXPORT_TAGS    = (
    all => [@EXPORT_OK],
);

use PPI::Document ();


sub modules_used_in_files {
    my (@files) = @_;

    my %modules;

    foreach my $file (@files) {
        my $document = _create_document_from_file($file);
        my @loaded_modules = modules_used_in_document($document);
        @modules{@loaded_modules} = (1) x @loaded_modules;
    } # end foreach

    return keys %modules;
} # end modules_used_in_files()


sub modules_used_in_string {
    my ($string) = @_;

    my $document = PPI::Document->new(\$string, readonly => 1)
        or die qq<Could not parse "$string": >, PPI::Document->errstr(), ".\n";

    return modules_used_in_document($document);
} # end modules_used_in_string()


sub modules_used_in_document {
    my ($document) = @_;

    my %modules;

    my $includes = $document->find('PPI::Statement::Include');
    if ($includes) {
        foreach my $statement ( @{$includes} ) {
            my $module = $statement->module();
            if ($module) {
                $modules{$module} = 1;

                if ($module eq 'base' or $module eq 'parent') {
                    my @loaded_modules =
                        _modules_loaded_by_base_or_parent($statement);

                    @modules{@loaded_modules} = (1) x @loaded_modules;
                } # end if
            } # end if
        } # end foreach
    } # end if

    return keys %modules;
} # end modules_used_in_document()


sub _create_document_from_file {
    my ($source) = @_;

    -e $source
        or die qq<"$source" does not exist.\n>;

    -r _
        or die qq<"$source" is not readable.\n>;

    not -d _
        or die qq<"$source" is a directory.\n>;

    if ( -z _ ) {
        # PPI barfs on empty documents for some reason.
        return PPI::Document->new();
    }

    my $document = PPI::Document->new($source, readonly => 1)
        or die qq<Could not parse "$source": >, PPI::Document->errstr(), ".\n";

    return $document;
} # end _create_document_from_file()


Readonly::Scalar my $QUOTE_WORDS_DELIMITER_OFFSET => length 'qw<';

sub _modules_loaded_by_base_or_parent {
    my ($statement) = @_;

    my @modules;

    my @children = $statement->schildren();
    shift @children; # use/require/my
    shift @children; # 'base'/'parent'

    if (@children and $children[0] =~ m< v? [\d.]+ >xms) {
        # Skip version requirement for 'base'/'parent'.  Not worrying about
        # the potential following comma.
        shift @children;
    }

    foreach my $child (@children) {
        if ( $child->isa('PPI::Token::Quote') ) {
            push @modules, $child->string();
        } elsif ( $child->isa('PPI::Token::QuoteLike::Words') ) {
            my $content = $child->content();

            $content = substr $content, $QUOTE_WORDS_DELIMITER_OFFSET;
            chop $content;
            $content =~ s< \A \s+ ><>xms;
            $content =~ s< \s+ \z ><>xms;
            push @modules, split m< \s+ >xms, $content;
        } # end if
    } # end foreach

    return @modules;
} # end _modules_loaded_by_base_or_parent()


1; # Magic true value required at end of module.

__END__

=encoding utf8

=for stopwords

=head1 NAME

Module::Used - Find modules loaded by Perl code without running it.


=head1 VERSION

This document describes Module::Used version 1.0.1.


=head1 SYNOPSIS

    use Module::Used qw< :all >;

    @modules = modules_used_in_files(@files);

    # "strict", "Find::Bin", "warnings"
    @modules = modules_used_in_string(
        'use strict; require Find::Bin; no warnings;'
    );

    # "Exporter"
    @modules = modules_used_in_string( 'use parent 0.221 qw< Exporter >;' );


=head1 DESCRIPTION

Modules are found statically based upon C<use> and C<require> statements.  If
use of the L<base> or L<parent> is found, both that module and the referenced
ones will be returned.

Dynamically loaded modules will not be found.


=head1 INTERFACE

Nothing is exported by default, but you can import everything using
the C<:all> tag.


=over

=item C< modules_used_in_files( @files ) >

Return a list of modules used in the specified files.

C<die>s if there is a problem reading a file.


=item C< modules_used_in_string( $string ) >

Return a list of modules used in the code in the parameter.


=item C< modules_used_in_document( $document ) >

Return a list of modules used in the specified L<PPI::Document>.


=back


=head1 DIAGNOSTICS

=over

=item "%s" does not exist.

Cannot find the file.


=item "%s" is not readable.

Cannot read the file.


=item "%s" is a directory.

The "file" was actually a directory.


=item Could not parse "%s".

L<PPI> could not interpret the file as a Perl document.


=back


=head1 CONFIGURATION AND ENVIRONMENT

None, currently.


=head1 DEPENDENCIES

L<PPI::Document>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

None reported.

Please report any bugs or feature requests to C<bug-module-used@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 SEE ALSO

L<Devel::Loaded>
L<Module::Extract::Namespaces>
L<Module::ScanDeps>
L<Module::PrintUsed>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008, Elliot Shank C<< <perl@galumph.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :

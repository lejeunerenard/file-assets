package File::Assets::Group;

use strict;
use warnings;

use Tie::LLHash;
use File::Assets;
use Object::Tiny qw/registry _registry_hash name rsc filters/;
use Path::Resource;
use Scalar::Util qw/blessed refaddr/;
use Carp::Clan qw/^File::Assets::/;

sub new {
    my $self = bless {}, shift;
    local %_ = @_;

    my $rsc = File::Assets::Util->parse_rsc($_{rsc} || $_{base_rsc} || $_{base});
    $rsc->uri($_{uri} || $_{base_uri}) if $_{uri} || $_{base_uri};
    $rsc->dir($_{dir} || $_{base_dir}) if $_{dir} || $_{base_dir};
    $self->{rsc} = $rsc;

    my %registry;
    $self->{registry} = tie(%registry, qw/Tie::LLHash/, { lazy => 1 });
    $self->{_registry_hash} = \%registry;

    $self->{filters} = [];

    return $self;
}

sub include {
    my $self = shift;
    return $self->include_path(@_);
}

sub include_path {
    my $self = shift;
    my $path = shift;
    my $rank = shift;
    my $type = shift;

    croak "Don't have a path to include" unless defined $path && length $path;

    return if $self->exists($path);

    my $asset = File::Assets::Util->parse_asset_by_path(path => $path, type => $type, rank => $rank, base => $self->rsc);

    $self->store($asset);

    return $asset;
}

sub empty {
    my $self = shift;
    return keys %{ $self->_registry_hash } ? 0 : 1;
}

sub exists {
    my $self = shift;
    my $path = shift;

    return exists $self->_registry_hash->{$path};
}

sub store {
    my $self = shift;
    my $asset = shift;

    $self->_registry_hash->{$asset->path} = $asset;
}

sub export {
    my $self = shift;
    my $type = shift;
    my $format = shift;
    $format = "html" unless defined $format;
    my @assets = $self->exports($type);

    if ($format eq "html") {
        return $self->_export_html(\@assets);
    }
    else {
        croak "Don't know how to export for format ($format)";
    }
}

sub _export_html {
    my $self = shift;
    my $assets = shift;

    my $html = "";
    for my $asset (@$assets) {
        if ($asset->type->type eq "text/css") {
            $html .= <<_END_;
<link rel="stylesheet" type="text/css" href="@{[ $asset->uri ]}" />
_END_
        }
        elsif ($asset->type->type eq "application/javascript") {
            $html .= <<_END_;
<script src="@{[ $asset->uri ]}" type="text/javascript"></script>
_END_
        }
        else {
            $html .= <<_END_;
<link type="@{[ $asset->type->type ]}" href="@{[ $asset->uri ]}" />
_END_
        }
    }
    return $html;
}

sub exports {
    my $self = shift;
    my @assets = sort { $a->rank <=> $b->rank } $self->_exports(@_);
    $self->_filter(\@assets);
    return @assets;
}

sub _exports {
    my $self = shift;
    my $type = shift;
    $type = File::Assets::Util->parse_type($type);
    my $hash = $self->_registry_hash;
    return values %$hash unless defined $type;
    return grep { $type->type eq $_->type->type } values %$hash;
}

sub filter {
    my $self = shift;
    my $filter = shift;
    return unless $filter = File::Assets::Util->parse_filter($filter, $self, @_);
    push @{ $self->filters }, $filter;
    return $filter;
}

sub filter_clear {
    my $self = shift;
    if (@_) {
        local %_ = @_;
        if ($_{type}) {
            my $type = File::Assets::Util->parse_type($_{type}) or croak "Don't know type ($_{type})";
            for my $filter (@{ $self->filters }) {
                $filter->remove if $filter->type && $filter->type->type eq $type->type;
            }
        }
        if ($_{filter}) {
            my $filter = ref $_{filter} ? refaddr $_{filter} : $_{filter};
            my @filters = grep { $_{filter} ne refaddr $_ } @{ $self->filters };
            $self->{filters} = \@filters;
        }
    }
    else {
        $self->{filters} = [];
    }
}

sub _filter {
    my $self = shift;
    my $assets = shift;
    for my $filter (@{ $self->filters }) {
        $filter->filter($assets);
    }
}

1;

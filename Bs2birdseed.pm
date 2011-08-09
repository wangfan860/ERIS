#! /usr/bin/perl -w

package Concordance::Bs2birdseed;

use strict;
use warnings;
use Config::General;
use File::Copy;
use Log::Log4perl;

my $error_log = Log::Log4perl->get_logger("errorLogger");
my $debug_log = Log::Log4perl->get_logger("debugLogger");

sub new {
	my $self = {};
	$self->{path} = undef;
	$self->{project_name} = undef;
	bless($self);
	return $self;
}

sub path {
	my $self = shift;
	if (@_) { $self->{path} = shift; }
	return $self->{path}; #[^\0]+
}

sub project_name {
	my $self = shift;
	if (@_) { $self->{project_name} = shift; }
	return $self->{project_name}; #[^\0]+
}

sub __get_file_list__ {
	my $self = shift;
	my $file_extension = "";
	if (@_) { $file_extension = shift; }
	my @files = glob($self->path."/*".$file_extension);
	my $size = @files;

	if ($size == 0) {
		$error_log->error("no ".$file_extension." files found in ".$self->path."\n");
		exit;
	}
	return @files;
}

sub execute {
	my $self = shift;
	my @files=$self->__get_file_list__(".bs");
	my $size = @files;

	foreach my $file (@files) {
		my @a=split(/\./,$file);
		my $outfile=$a[0].".birdseed";
		$debug_log->debug("Converting $file to $outfile\n");
		open(FOUT,"> $outfile");
		open(FIN,"$file");
		while (<FIN>) {
			chomp;
			if (/^\[/ || /^\@/) {
				# do nothing
			} else {
				@a=split(/\s+/);
				print FOUT "$a[0]\t$a[1]\t$a[2]\t$a[5]\n";
			}
		}
		close(FIN);
		close(FOUT);
	}
}

sub move_birdseed_to_project_dir {
	my $self = shift;
	if (-e $self->path."/".$self->project_name) {
		my @files = $self->__get_file_list__(".birdseed");
		foreach my $file (@files) {
			move($file, $self->path."/".$self->project_name);
		}
	}
}

1;

=head1 NAME

Concordance::Bs2birdseed - converts .bs to .birdseed

=head1 SYNOPSIS

 use Concordance::Bs2birdseed;
 my $bs_2_birdseed = Concordance::Bs2birdseed->new;
 $bs_2_birdseed->convert_bs_to_birdseed;
 $bs_2_birdseed->move_birdseed_to_project_dir;

=head1 DESCRIPTION

This script converts the .bs files generated by buildGELI.pl into .birdseed files, writing out only the desired columns from the input.  It then moves the .birdseed files to the project directory.

=head2 Methods

=over 12

=item C<new>

Returns a new Concordance::Bs2birdseed object.

=item C<convert_bs_to_birdseed>

Converts each .bs file in a specified directory to a .birdseed.

=item C<move_birdseed_to_project_dir>

Tests for the existence of the project directory and creates it if necessary, then moves the .birdseed files there.

=back

=head1 LICENSE

This script is the property of Baylor College of Medicine.

=head1 AUTHOR

Updated by John McAdams - L<mailto:mcadams@bcm.edu>

=cut

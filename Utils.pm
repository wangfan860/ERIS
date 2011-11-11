package Concordance::Utils;

use strict;
use warnings;
use diagnostics;
use Log::Log4perl;
use Concordance::Sample;

my $error_log = Log::Log4perl->get_logger("errorLogger");
my $error_screen = Log::Log4perl->get_logger("errorScreenLogger");
my $debug_log = Log::Log4perl->get_logger("debugLogger");
my $warn_log = Log::Log4perl->get_logger("warnLogger");

=head1 NAME

Concordance::Utils - common functions

=head1 SYNOPSIS

 my @file_list = Concordance::Utils->get_file_list($path, $ext);
 my %samples = Concordance::Utils->populate_sample_info_hash($run_list);

=head1 DESCRIPTION

=head2 Methods

=head3 get_file_list

 my $path = "/foo/bar";
 my $ext = "foo";
 my @file_list = Concordance::Utils->get_file_list($path, $ext);

For a given path and file extension, returns all files of that type from the directory as an array.

=cut

sub get_file_list {
	# returns a list of all files of type $file_extension from directory $path
	shift;
	my $path = undef;
	my $file_extension = undef; # not prepended with period
	if (@_) { $path = shift }
	if (@_) { $file_extension = shift }
	my @files = glob($path."/*.".$file_extension);
	if ($#files == -1) {
		#$error_log->error("No ".$file_extension." files found in ".$path."\n");
		exit;
	}
	return @files;
}

=head3 populate_sample_info_hash

 my $run_id_list = "foo,bar,rab,oof";
 my %samples = Concordance::Utils->populate_sample_info_hash($run_id_list);

For a given comma-delimited list of run IDs, executes a query against LIMS via curl, returning the associated sample ID, SNP array, and result path, storing each into a Sample object, and returning a hash of sample ID => Sample.

=cut

sub populate_sample_info_hash {
	shift;
	# run_id_list - this should be a comma-delimited list of run IDs
	# returns a hash populated as hash{sample_id} => Concordance::Sample
	my $run_id_list = "";
	if (@_) { $run_id_list = shift } 

	my $post_data = "runnamelist=$run_id_list";
	my $url = "http://gen2.hgsc.bcm.tmc.edu/gen2lims-reporting/jaxrs/reportservice/runinfo";
	my $result = `curl -d "$post_data" -X POST $url`;

	my %samples = ();
	while ($result =~ m/([^,]+),([^,]+),([^,]+),(.*)\n/) {
		my $run_id = $1;
		my $sample_id = $2;
		my $orig_sample_id = $2;
		my $result_path = $3;
		my $snp_array = $4;
		if ($run_id ne "run_name") {
			$samples{$run_id} = Concordance::Sample->new;
			$samples{$run_id}->run_id($run_id);
			$samples{$run_id}->snp_array($snp_array);
			$samples{$run_id}->sample_id($sample_id);
			$samples{$run_id}->result_path($result_path);
		}
	    $result =~ s/$run_id,$orig_sample_id,$result_path,$snp_array\n//; # remove the line; finished processing it
	}
	return %{ (validate_samples_container(\%samples)) };
}

sub validate_samples_container {
	my %samples = %{ (shift) };

	foreach my $sample (values %samples) {
		if ($sample->sample_id eq "null" or $sample->sample_id eq "") {
			print_to_error_log_and_screen("Bad sample_id ".$sample->sample_id." for run ID ".
				$sample->run_id.", removing from Samples container ...");
			delete $samples{$sample->run_id};
			next;
		}
		if ($sample->snp_array eq "null" or $sample->snp_array eq "") {
			print_to_error_log_and_screen("Bad snp_array ".$sample->snp_array." for run ID ".
				$sample->run_id.", removing from Samples container ...");
			delete $samples{$sample->run_id};
			next;
		}
		if ($sample->result_path eq "null" or $sample->result_path eq "") {
			print_to_error_log_and_screen("Bad result_path ".$sample->result_path." for run ID ".
				$sample->run_id.", removing from Samples container ...");
			delete $samples{$sample->run_id};
			next;
		}	
	}
	return \%samples;
}

sub print_to_error_log_and_screen {
	my $message = shift;
	$error_screen->error($message."\n");
	print STDERR $message."\n";
}

=head1 LICENSE

GPLv3.

-head1 AUTHOR

John McAdams - L<mailto:mcadams@bcm.edu>

=cut

1;

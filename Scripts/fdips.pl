#!/usr/bin/perl
use strict;

my $machine = $ARGV[0];

if ($machine eq 'pfe'){
    `qsub job.small.pfe`;
} elsif ($machine eq 'frontera') {
    `sbatch job.small.fronetra`;
} else {
    print "Machine must be either pfe or frontera.";
    exit;
}

print "FDIPS running on ", `hostname`;

while(not -f "fdips_bxyz_np010202.out"){      # fdips output file
    print "FDIPS job submitted on ", `date`;
    sleep 7000;                               # no need to check yet
    sleep 5 while not (-f "fdips_bxyz_np010202.out"); 
    print "FDIPS finished successfully on ", `date`;
    sleep 60;                                 # wait for the job to quit
}

# combine the results into a single file
`redistribute.pl fdips_bxyz_np010202.out fdips_bxyz.out`;

print "AWSoM/AWSoM-R submitted on ", `date`;

# It is in SC now, go to the run dir
chdir "../";

if ($machine eq 'pfe'){
    `qsub job.pfe`;
} elsif ($machine eq 'frontera') {
    `sbatch job.fronetra`;
} else {
    print "Machine must be either pfe or frontera.";
    exit;
}

use Test2::V0;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;

use Getopt::Yath;

# Clean env
delete $ENV{$_} for qw/OT_TEST_A OT_TEST_B/;

subtest 'BoolMap pattern matching' => sub {
    package BoolMapTest;
    use Getopt::Yath;

    option_group {category => 'BoolMap Tests', group => 'boolmap', no_module => 1} => sub {
        option features => (
            type        => 'BoolMap',
            pattern     => qr/feature-(.+)/,
            description => 'Feature flags',
        );
    };

    package main;

    my $res = BoolMapTest::parse_options(['--feature-foo', '--feature-bar', '--no-feature-baz']);
    is(
        $res->{settings}->{boolmap}->{features},
        {foo => 1, bar => 1, baz => 0},
        'BoolMap matches patterns and respects --no- prefix',
    );

    $res = BoolMapTest::parse_options(['--no-features']);
    is(
        $res->{settings}->{boolmap}->{features},
        {},
        'BoolMap --no clears all values',
    );
};

subtest 'PathList glob expansion' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for my $name (qw/alpha.txt beta.txt gamma.log/) {
        open my $fh, '>', "$dir/$name" or die "Cannot create $dir/$name: $!";
        close $fh;
    }

    package PathListTest;
    use Getopt::Yath;

    option_group {category => 'PathList Tests', group => 'pathlist', no_module => 1} => sub {
        option files => (
            type        => 'PathList',
            description => 'File list',
        );
    };

    package main;

    my $res = PathListTest::parse_options(['--files', "$dir/*.txt"]);
    my @files = sort @{$res->{settings}->{pathlist}->{files}};
    is(\@files, ["$dir/alpha.txt", "$dir/beta.txt"], 'PathList expands globs');

    $res = PathListTest::parse_options(['--files', "$dir/gamma.log"]);
    is($res->{settings}->{pathlist}->{files}, ["$dir/gamma.log"], 'PathList passes non-glob through');
};

subtest 'List JSON parsing' => sub {
    package ListJsonTest;
    use Getopt::Yath;

    option_group {category => 'List JSON', group => 'listjson', no_module => 1} => sub {
        option items => (
            type        => 'List',
            description => 'Items list',
        );
    };

    package main;

    my $res = ListJsonTest::parse_options(['--items', '["aaa","bbb","ccc"]']);
    is(
        $res->{settings}->{listjson}->{items},
        ['aaa', 'bbb', 'ccc'],
        'List parses JSON array input',
    );
};

subtest 'Map JSON parsing' => sub {
    package MapJsonTest;
    use Getopt::Yath;

    option_group {category => 'Map JSON', group => 'mapjson', no_module => 1} => sub {
        option kvs => (
            type        => 'Map',
            description => 'Key-value pairs',
        );
    };

    package main;

    my $res = MapJsonTest::parse_options(['--kvs', '{"x":"1","y":"2"}']);
    is(
        $res->{settings}->{mapjson}->{kvs},
        {x => '1', y => '2'},
        'Map parses JSON object input',
    );
};

subtest 'Map custom key_on delimiter' => sub {
    package MapKeyOnTest;
    use Getopt::Yath;

    option_group {category => 'Map KeyOn', group => 'mapkeyon', no_module => 1} => sub {
        option pairs => (
            type        => 'Map',
            key_on      => ':',
            description => 'Colon-separated pairs',
        );
    };

    package main;

    my $res = MapKeyOnTest::parse_options(['--pairs', 'host:localhost']);
    is(
        $res->{settings}->{mapkeyon}->{pairs},
        {host => 'localhost'},
        'Map uses custom key_on delimiter',
    );
};

subtest 'Bool set_env_vars' => sub {
    package BoolEnvTest;
    use Getopt::Yath;

    option_group {category => 'Bool Env', group => 'boolenv', no_module => 1} => sub {
        option loud => (
            type         => 'Bool',
            set_env_vars => ['OT_TEST_A'],
            description  => 'Loud mode',
        );
    };

    package main;

    local $ENV{OT_TEST_A};
    my $res = BoolEnvTest::parse_options(['--loud']);
    is($res->{env}->{OT_TEST_A}, 1, 'Bool set_env_vars sets env to 1 when true');
    is($ENV{OT_TEST_A}, 1, 'ENV actually set');

    local $ENV{OT_TEST_A};
    $res = BoolEnvTest::parse_options(['--loud'], no_set_env => 1);
    is($res->{env}->{OT_TEST_A}, 1, 'env recorded in state');
    ok(!$ENV{OT_TEST_A}, 'ENV not set with no_set_env');
};

subtest 'Count set_env_vars' => sub {
    package CountEnvTest;
    use Getopt::Yath;

    option_group {category => 'Count Env', group => 'cntenv', no_module => 1} => sub {
        option verbosity => (
            type         => 'Count',
            short        => 'V',
            set_env_vars => ['OT_TEST_B'],
            initialize   => 0,
            description  => 'Verbosity level',
        );
    };

    package main;

    local $ENV{OT_TEST_B};
    my $res = CountEnvTest::parse_options(['-VVV']);
    is($res->{env}->{OT_TEST_B}, 3, 'Count set_env_vars captures counter value');
};

subtest 'Scalar with allowed_values at parse time' => sub {
    package ScalarAVTest;
    use Getopt::Yath;

    option_group {category => 'Scalar AV', group => 'sav', no_module => 1} => sub {
        option level => (
            type           => 'Scalar',
            allowed_values => ['low', 'medium', 'high'],
            description    => 'Level setting',
        );
    };

    package main;

    my $res = ScalarAVTest::parse_options(['--level', 'medium']);
    is($res->{settings}->{sav}->{level}, 'medium', 'valid allowed_values accepted');

    like(
        dies { ScalarAVTest::parse_options(['--level', 'extreme']) },
        qr/Invalid value.*'extreme'/,
        'invalid allowed_values rejected at parse time',
    );
};

subtest 'Scalar with normalize' => sub {
    package NormTest;
    use Getopt::Yath;

    option_group {category => 'Norm', group => 'norm', no_module => 1} => sub {
        option mode => (
            type        => 'Scalar',
            normalize   => sub { lc $_[0] },
            description => 'Mode',
        );
    };

    package main;

    my $res = NormTest::parse_options(['--mode', 'UPPER']);
    is($res->{settings}->{norm}->{mode}, 'upper', 'normalize callback applied during parsing');
};

subtest 'maybe option attribute' => sub {
    package MaybeTest;
    use Getopt::Yath;

    option_group {category => 'Maybe', group => 'maybe', no_module => 1} => sub {
        option optional => (
            type        => 'Bool',
            maybe       => 1,
            description => 'An optional bool',
        );

        option opt_list => (
            type        => 'List',
            maybe       => 1,
            description => 'An optional list',
        );
    };

    package main;

    my $res = MaybeTest::parse_options([]);
    is($res->{settings}->{maybe}->{optional}, undef, 'maybe Bool has no default');
    is($res->{settings}->{maybe}->{opt_list}, undef, 'maybe List has no initial value');
};

done_testing;

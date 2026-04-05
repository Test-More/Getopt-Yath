use Test2::V0;

use Getopt::Yath::Option;

subtest 'create factory' => sub {
    my $opt = Getopt::Yath::Option->create(
        type        => 'Bool',
        title       => 'test-opt',
        group       => 'testing',
        no_module   => 1,
        trace       => [__PACKAGE__, __FILE__, __LINE__],
        description => 'a test option',
    );
    isa_ok($opt, 'Getopt::Yath::Option::Bool');
    is($opt->title, 'test-opt', 'title set');
    is($opt->field, 'test_opt', 'field derived from title (dashes to underscores)');
    is($opt->name,  'test-opt', 'name derived from title (underscores to dashes)');
    is($opt->group, 'testing',  'group set');
};

subtest 'create requires type' => sub {
    like(
        dies { Getopt::Yath::Option->create(title => 'x', group => 'g', no_module => 1, trace => [caller]) },
        qr/No 'type' specified/,
        'create dies without type',
    );
};

subtest 'create cannot be called on subclass' => sub {
    like(
        dies { Getopt::Yath::Option::Bool->create(type => 'Bool', title => 'x', group => 'g', no_module => 1, trace => [caller]) },
        qr/create\(\) cannot be called on an option subclass/,
        'create dies on subclass',
    );
};

subtest 'trace_string' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'ts',
        group     => 'g',
        no_module => 1,
        trace     => ['main', 'myfile.pl', 42],
    );
    is($opt->trace_string, 'myfile.pl line 42', 'trace_string formatted correctly');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'ts2',
        group     => 'g',
        no_module => 1,
        trace     => ['main', 'other.pl', 99],
    );
    $opt2->{trace} = undef;
    is($opt2->trace_string, '[UNKNOWN]', 'trace_string with no trace');
};

subtest 'forms' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'my-val',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        short     => 'V',
        alt       => ['val'],
    );

    my $forms = $opt->forms;
    is($forms->{'--my-val'},    1,  '--name is positive');
    is($forms->{'--no-my-val'}, -1, '--no-name is negative');
    is($forms->{'--val'},       1,  '--alt is positive');
    is($forms->{'--no-val'},    -1, '--no-alt is negative');
    is($forms->{'-V'},          1,  '-short is positive');
};

subtest 'forms with prefix' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'verbose',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        prefix    => 'runner',
    );

    my $forms = $opt->forms;
    ok($forms->{'--runner-verbose'},    'prefixed positive form');
    ok($forms->{'--no-runner-verbose'}, 'prefixed negative form');
    ok(!$forms->{'--verbose'},          'unprefixed form not present');
};

subtest 'forms with alt_no' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'color',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        alt_no    => ['no-colour'],
    );

    my $forms = $opt->forms;
    is($forms->{'--no-colour'}, -1, 'alt_no form is negative');
    is($forms->{'--color'},      1, 'primary form is positive');
};

subtest 'is_applicable' => sub {
    my $opt = Getopt::Yath::Option->create(
        type       => 'Bool',
        title      => 'cond',
        group      => 'g',
        no_module  => 1,
        trace      => [caller],
        applicable => sub { 0 },
    );
    ok(!$opt->is_applicable(undef, undef), 'applicable returns false');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'always',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    ok($opt2->is_applicable(undef, undef), 'no applicable callback means always applicable');
};

subtest 'normalize_value' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'norm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        normalize => sub { uc $_[0] },
    );
    is(($opt->normalize_value('hello'))[0], 'HELLO', 'normalize callback applied');

    my $opt2 = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'no-norm',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );
    is(($opt2->normalize_value('hello'))[0], 'hello', 'no normalize is passthrough');
};

subtest 'check_value with arrayref allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'av',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => ['red', 'green', 'blue'],
    );

    my @bad = $opt->check_value(['red']);
    is(\@bad, [], 'valid value passes');

    @bad = $opt->check_value(['purple']);
    is(\@bad, ['purple'], 'invalid value returned');

    @bad = $opt->check_value(['red', 'purple', 'orange']);
    is(\@bad, ['purple', 'orange'], 'multiple invalid values returned');
};

subtest 'check_value with regex allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'avr',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => qr/^\d+$/,
    );

    my @bad = $opt->check_value(['123']);
    is(\@bad, [], 'numeric value passes regex');

    @bad = $opt->check_value(['abc']);
    is(\@bad, ['abc'], 'non-numeric value fails regex');
};

subtest 'check_value with coderef allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type           => 'Scalar',
        title          => 'avc',
        group          => 'g',
        no_module      => 1,
        trace          => [caller],
        allowed_values => sub { $_[1] > 0 },
    );

    my @bad = $opt->check_value([5]);
    is(\@bad, [], 'positive value passes code check');

    @bad = $opt->check_value([-1]);
    is(\@bad, [-1], 'negative value fails code check');
};

subtest 'check_value with no allowed_values' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'avn',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
    );

    my @bad = $opt->check_value(['anything']);
    is(\@bad, [], 'no allowed_values means everything passes');
};

subtest 'trigger' => sub {
    my @calls;
    my $opt = Getopt::Yath::Option->create(
        type      => 'Bool',
        title     => 'trig',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        trigger   => sub { push @calls, {@_[1..$#_]} },
    );

    $opt->trigger(action => 'set', val => 1);
    is(scalar @calls, 1, 'trigger called once');
    is($calls[0]->{action}, 'set', 'trigger received action');
};

subtest 'long_args' => sub {
    my $opt = Getopt::Yath::Option->create(
        type      => 'Scalar',
        title     => 'main-arg',
        group     => 'g',
        no_module => 1,
        trace     => [caller],
        alt       => ['alias-one', 'alias-two'],
    );

    is([$opt->long_args], ['main-arg', 'alias-one', 'alias-two'], 'long_args returns name + alts');
};

subtest 'init validation' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                group => 'g',
                trace => [caller],
                no_module => 1,
                # no title, field, or name
            )
        },
        qr/You must specify 'title' or both 'field' and 'name'/,
        'dies without title or field+name',
    );

    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                title => 'x',
                trace => [caller],
                # no module and no no_module
            )
        },
        qr/You must provide either 'module'/,
        'dies without module or no_module',
    );

    like(
        dies {
            Getopt::Yath::Option->create(
                type  => 'Bool',
                title => 'x',
                # no group
                trace     => [caller],
                no_module => 1,
            )
        },
        qr/The 'group' attribute is required/,
        'dies without group',
    );
};

subtest 'alt with underscore rejected' => sub {
    like(
        dies {
            Getopt::Yath::Option->create(
                type      => 'Bool',
                title     => 'x',
                group     => 'g',
                no_module => 1,
                trace     => [caller],
                alt       => ['bad_alt'],
            )
        },
        qr/alt option form 'bad_alt' contains an underscore/,
        'underscore in alt rejected',
    );

    ok(
        lives {
            Getopt::Yath::Option->create(
                type                     => 'Bool',
                title                    => 'x2',
                group                    => 'g',
                no_module                => 1,
                trace                    => [caller],
                alt                      => ['ok_alt'],
                allow_underscore_in_alt  => 1,
            )
        },
        'underscore allowed when allow_underscore_in_alt is set',
    );
};

done_testing;

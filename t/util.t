use Test2::V0;

use Getopt::Yath::Util qw/mod2file fqmod encode_json decode_json encode_json_file decode_json_file/;

subtest mod2file => sub {
    is(mod2file('Foo::Bar::Baz'), 'Foo/Bar/Baz.pm', 'converts :: to /');
    is(mod2file('Simple'), 'Simple.pm', 'single-segment module');

    like(
        dies { mod2file(undef) },
        qr/No module name provided/,
        'dies with no argument',
    );
};

subtest fqmod_with_prefix => sub {
    # Getopt::Yath::Option::Bool is a known module
    my $mod = fqmod('Bool', 'Getopt::Yath::Option');
    is($mod, 'Getopt::Yath::Option::Bool', 'resolves short name with prefix');
};

subtest fqmod_already_prefixed => sub {
    my $mod = fqmod('Getopt::Yath::Option::Bool', 'Getopt::Yath::Option');
    is($mod, 'Getopt::Yath::Option::Bool', 'does not double-prefix');
};

subtest fqmod_plus_prefix => sub {
    my $mod = fqmod('+Getopt::Yath::Option::Scalar', 'SomePrefix');
    is($mod, 'Getopt::Yath::Option::Scalar', 'strips + and uses fully qualified name');
};

subtest fqmod_no_require => sub {
    my $mod = fqmod('Nonexistent', 'Fake::Prefix', no_require => 1);
    is($mod, 'Fake::Prefix::Nonexistent', 'no_require skips loading');
};

subtest fqmod_not_found => sub {
    like(
        dies { fqmod('ZzzNotReal', 'Zzz::Prefix') },
        qr/Could not locate a module matching 'ZzzNotReal'/,
        'dies when module cannot be found',
    );
};

subtest fqmod_multiple_prefixes => sub {
    my $mod = fqmod('Bool', ['NoSuch::Prefix', 'Getopt::Yath::Option']);
    is($mod, 'Getopt::Yath::Option::Bool', 'tries multiple prefixes, finds the second');
};

subtest json_roundtrip => sub {
    my $data = {foo => [1, 2, 3], bar => 'hello'};
    my $json = encode_json($data);
    ok(defined $json, 'encode_json produces output');
    like($json, qr/"foo"/, 'JSON contains key');

    my $decoded = decode_json($json);
    is($decoded, $data, 'decode_json round-trips');
};

subtest json_file_roundtrip => sub {
    my $data = {test => 'value', nums => [10, 20]};
    my $file = encode_json_file($data);
    ok(-f $file, 'encode_json_file creates a file');

    my $decoded = decode_json_file($file, unlink => 1);
    is($decoded, $data, 'decode_json_file round-trips');
    ok(!-f $file, 'file was unlinked');
};

subtest decode_json_invalid => sub {
    like(
        dies { decode_json('not json at all') },
        qr/./, # Just confirm it dies
        'decode_json dies on invalid input',
    );
};

done_testing;

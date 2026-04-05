use Test2::V0;
use Scalar::Util qw/blessed/;

use Getopt::Yath::Settings;
use Getopt::Yath::Settings::Group;

subtest 'Settings::Group construction' => sub {
    my $g = Getopt::Yath::Settings::Group->new(foo => 'bar', baz => 42);
    isa_ok($g, 'Getopt::Yath::Settings::Group');
    is($g->{foo}, 'bar', 'hash key set via pairs');
    is($g->{baz}, 42,    'hash key set via pairs');

    my $g2 = Getopt::Yath::Settings::Group->new({x => 1});
    is($g2->{x}, 1, 'hash key set via hashref');
};

subtest 'Settings::Group check_option' => sub {
    my $g = Getopt::Yath::Settings::Group->new(alpha => 1);
    ok($g->check_option('alpha'),  'check_option true for existing');
    ok(!$g->check_option('beta'),  'check_option false for missing');
};

subtest 'Settings::Group option get/set' => sub {
    my $g = Getopt::Yath::Settings::Group->new(val => 'original');
    is($g->option('val'), 'original', 'option getter');
    $g->option('val', 'changed');
    is($g->option('val'), 'changed', 'option setter');

    like(
        dies { $g->option('nope') },
        qr/The 'nope' option does not exist/,
        'option dies on missing key',
    );
};

subtest 'Settings::Group option lvalue' => sub {
    my $g = Getopt::Yath::Settings::Group->new(lv => 10);
    $g->option('lv') = 20;
    is($g->option('lv'), 20, 'lvalue assignment works');
};

subtest 'Settings::Group create_option' => sub {
    my $g = Getopt::Yath::Settings::Group->new();
    $g->create_option('new_opt', 'hello');
    is($g->option('new_opt'), 'hello', 'create_option creates and sets');
};

subtest 'Settings::Group option_ref' => sub {
    my $g = Getopt::Yath::Settings::Group->new(reftest => 5);
    my $ref = $g->option_ref('reftest');
    is($$ref, 5, 'option_ref returns scalar ref to value');
    $$ref = 99;
    is($g->option('reftest'), 99, 'writing through ref updates the group');

    like(
        dies { $g->option_ref('missing') },
        qr/The 'missing' option does not exist/,
        'option_ref dies without create flag',
    );

    my $ref2 = $g->option_ref('created', 1);
    $$ref2 = 'new';
    is($g->option('created'), 'new', 'option_ref with create flag');
};

subtest 'Settings::Group delete_option' => sub {
    my $g = Getopt::Yath::Settings::Group->new(del => 'bye');
    $g->delete_option('del');
    ok(!$g->check_option('del'), 'delete_option removes the key');
};

subtest 'Settings::Group remove_option' => sub {
    my $g = Getopt::Yath::Settings::Group->new(rem => 'gone');
    $g->remove_option('rem');
    ok(!$g->check_option('rem'), 'remove_option removes the key');
};

subtest 'Settings::Group all' => sub {
    my $g = Getopt::Yath::Settings::Group->new(a => 1, b => 2);
    is({$g->all}, {a => 1, b => 2}, 'all returns key/value pairs');
};

subtest 'Settings::Group AUTOLOAD' => sub {
    my $g = Getopt::Yath::Settings::Group->new(magic => 'auto');
    is($g->magic, 'auto', 'AUTOLOAD accessor works');

    like(
        dies { $g->no_such_thing },
        qr/The 'no_such_thing' option does not exist/,
        'AUTOLOAD dies for missing option',
    );
};

subtest 'Settings::Group TO_JSON' => sub {
    my $g = Getopt::Yath::Settings::Group->new(j => 1);
    my $h = $g->TO_JSON;
    is($h, {j => 1}, 'TO_JSON returns plain hashref');
    ok(!blessed($h), 'TO_JSON result is not blessed');
};

subtest 'Settings construction' => sub {
    my $s = Getopt::Yath::Settings->new({
        grp1 => {opt_a => 1},
        grp2 => {opt_b => 2},
    });
    isa_ok($s, 'Getopt::Yath::Settings');
    isa_ok($s->{grp1}, ['Getopt::Yath::Settings::Group'], 'groups are blessed');
    isa_ok($s->{grp2}, ['Getopt::Yath::Settings::Group'], 'groups are blessed');
};

subtest 'Settings check_group' => sub {
    my $s = Getopt::Yath::Settings->new({present => {}});
    ok($s->check_group('present'),  'check_group true for existing');
    ok(!$s->check_group('absent'),  'check_group false for missing');
};

subtest 'Settings group' => sub {
    my $s = Getopt::Yath::Settings->new({stuff => {x => 1}});

    my $g = $s->group('stuff');
    isa_ok($g, 'Getopt::Yath::Settings::Group');
    is($g->x, 1, 'retrieved group has correct data');

    like(
        dies { $s->group('nope') },
        qr/The 'nope' group is not defined/,
        'group dies for missing without vivify',
    );

    my $g2 = $s->group('vivified', 1);
    isa_ok($g2, 'Getopt::Yath::Settings::Group');
};

subtest 'Settings maybe' => sub {
    my $s = Getopt::Yath::Settings->new({
        grp => {opt => 'found'},
    });
    is($s->maybe('grp', 'opt'), 'found', 'maybe returns value when present');
    is($s->maybe('grp', 'missing', 'fallback'), 'fallback', 'maybe returns default for missing option');
    is($s->maybe('no_grp', 'opt', 'def'), 'def', 'maybe returns default for missing group');
};

subtest 'Settings create_group' => sub {
    my $s = Getopt::Yath::Settings->new({});
    my $g = $s->create_group('new_grp', x => 1);
    isa_ok($g, 'Getopt::Yath::Settings::Group');
    is($g->x, 1, 'create_group sets values');
};

subtest 'Settings delete_group' => sub {
    my $s = Getopt::Yath::Settings->new({del_me => {a => 1}});
    $s->delete_group('del_me');
    ok(!$s->check_group('del_me'), 'delete_group removes the group');
};

subtest 'Settings AUTOLOAD' => sub {
    my $s = Getopt::Yath::Settings->new({auto_grp => {v => 9}});
    my $g = $s->auto_grp;
    isa_ok($g, 'Getopt::Yath::Settings::Group');
    is($g->v, 9, 'AUTOLOAD group accessor');
};

subtest 'Settings TO_JSON' => sub {
    my $s = Getopt::Yath::Settings->new({g => {a => 1}});
    my $h = $s->TO_JSON;
    ref_ok($h, 'HASH', 'TO_JSON returns hashref');
};

subtest 'Settings FROM_JSON' => sub {
    my $s = Getopt::Yath::Settings->FROM_JSON('{"mygrp":{"val":42}}');
    isa_ok($s, 'Getopt::Yath::Settings');
    is($s->mygrp->val, 42, 'FROM_JSON round-trips correctly');
};

done_testing;

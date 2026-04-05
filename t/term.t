use Test2::V0;

use Getopt::Yath::Term qw/USE_COLOR color fit_to_width/;

subtest USE_COLOR => sub {
    my $val = USE_COLOR();
    ok(defined $val, 'USE_COLOR returns a defined value');
    ok($val == 0 || $val == 1, 'USE_COLOR returns 0 or 1');
};

subtest color => sub {
    my $result = color('red');
    ok(defined $result, 'color returns a defined value');
    # If Term::ANSIColor is available, it returns an escape sequence; otherwise ''
    if (USE_COLOR()) {
        like($result, qr/\e\[/, 'color returns ANSI escape when color is available');
    }
    else {
        is($result, '', 'color returns empty string when color is unavailable');
    }
};

subtest 'fit_to_width basic' => sub {
    my $text = "short text";
    my $out = fit_to_width(" ", $text, width => 80);
    is($out, "short text", 'short text passes through unchanged');
};

subtest 'fit_to_width wrapping' => sub {
    my $text = "word " x 30;    # ~150 chars
    my $out = fit_to_width(" ", $text, width => 40);
    my @lines = split /\n/, $out;
    ok(@lines > 1, 'long text is wrapped into multiple lines');
    for my $line (@lines) {
        ok(length($line) <= 44, "line does not grossly exceed width: '$line'");
    }
};

subtest 'fit_to_width with prefix' => sub {
    my $text = "hello world this is a test";
    my $out = fit_to_width(" ", $text, width => 80, prefix => ">> ");
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^>> /, "line starts with prefix: '$line'");
    }
};

subtest 'fit_to_width with arrayref' => sub {
    my $parts = [qw/alpha beta gamma/];
    my $out = fit_to_width(", ", $parts, width => 80);
    is($out, "alpha, beta, gamma", 'arrayref input joined correctly');
};

subtest 'fit_to_width narrow width forces wrapping' => sub {
    my $text = "one two three four five";
    my $out = fit_to_width(" ", $text, width => 10);
    my @lines = split /\n/, $out;
    ok(@lines >= 2, 'narrow width causes wrapping');
};

done_testing;

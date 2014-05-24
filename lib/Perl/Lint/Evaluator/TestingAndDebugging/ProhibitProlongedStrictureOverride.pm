package Perl::Lint::Evaluator::TestingAndDebugging::ProhibitProlongedStrictureOverride;
use strict;
use warnings;
use utf8;
use Perl::Lint::Constants::Type;
use parent "Perl::Lint::Evaluator";

use constant DEFAULT_ALLOW_STATEMENTS_NUM => 3;

# TODO msg!
use constant {
    DESC => '',
    EXPL => '',
};

sub evaluate {
    my ($class, $file, $tokens, $args) = @_;

    my $statements_arg = $args->{prohibit_prolonged_stricture_override}->{statements};
    my $allow_statements_num = defined $statements_arg ? $statements_arg : DEFAULT_ALLOW_STATEMENTS_NUM;

    my @violations;
    my $token_num = scalar @$tokens;
    my $no_strict = 0;
    my $statements_num_of_after_no_strict = 0;
    TOP: for (my $i = 0; $i < $token_num; $i++) {
        my $token = $tokens->[$i];
        my $token_type = $token->{type};

        if ($token_type == FUNCTION_DECL) {
            my $no_strict = 0;
            my $statements_num_of_after_no_strict = 0;
            my $left_brace_num = 0;
            for ($i++; $i < $token_num; $i++) {
                my $token = $tokens->[$i];
                my $token_type = $token->{type};

                if ($token_type == BUILTIN_FUNC and $token->{data} eq 'no') {
                    $token = $tokens->[++$i];
                    $token_type = $token->{type};

                    my @allows;
                    if ($token_type == KEY && $token->{data} eq 'strict') {
                        $no_strict = 1;
                        $i++;
                    }
                }
                elsif ($token_type == SEMI_COLON && $no_strict) {
                    $statements_num_of_after_no_strict++;
                    if ($statements_num_of_after_no_strict > $allow_statements_num) {
                        push @violations, {
                            filename => $file,
                            line     => $token->{line},
                            description => DESC,
                            explanation => EXPL,
                        };
                        next TOP;
                    }
                }
                elsif ($token_type == LEFT_BRACE) {
                    $left_brace_num++;
                }
                elsif ($token_type == RIGHT_BRACE) {
                    $left_brace_num--;
                    if ($left_brace_num <= 0) {
                        last;
                    }
                }
            }
        }
        elsif ($token_type == BUILTIN_FUNC and $token->{data} eq 'no') {
            $token = $tokens->[++$i];
            $token_type = $token->{type};

            my @allows;
            if ($token_type == KEY && $token->{data} eq 'strict') {
                $no_strict = 1;
                $i++;
            }
        }
        elsif ($token_type == SEMI_COLON && $no_strict) {
            $statements_num_of_after_no_strict++;
            if ($statements_num_of_after_no_strict > $allow_statements_num) {
                push @violations, {
                    filename => $file,
                    line     => $token->{line},
                    description => DESC,
                    explanation => EXPL,
                };
                last;
            }
        }
    }

    return \@violations;
}

1;


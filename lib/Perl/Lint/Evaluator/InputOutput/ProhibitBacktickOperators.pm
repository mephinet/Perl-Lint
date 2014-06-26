package Perl::Lint::Evaluator::InputOutput::ProhibitBacktickOperators;
use strict;
use warnings;
use Perl::Lint::Constants::Type;
use parent "Perl::Lint::Evaluator";

# TODO msg!
use constant {
    DESC => '',
    EXPL => '',
};

sub evaluate {
    my ($class, $file, $tokens, $src, $args) = @_;

    my $only_in_void_context = $args->{prohibit_backtick_operators}->{only_in_void_context};

    my @violations;
    my $is_in_assign_context;
    my $is_in_call_context;
    my $is_in_ctrl_context;
    for (my $i = 0; my $token = $tokens->[$i]; $i++) {
        my $token_type = $token->{type};

        if ($token_type == BUILTIN_FUNC || $token_type == KEY) {
            $is_in_call_context = 1;
            next;
        }

        if (
            $token_type == IF_STATEMENT ||
            $token_type == ELSIF_STATEMENT ||
            $token_type == UNLESS_STATEMENT ||
            $token_type == FOR_STATEMENT ||
            $token_type == FOREACH_STATEMENT ||
            $token_type == WHILE_STATEMENT ||
            $token_type == UNTIL_STATEMENT
        ) {
            $is_in_ctrl_context = 1;
            next;
        }

        if ($only_in_void_context && ($is_in_call_context || $is_in_ctrl_context)) {
            if ($token_type == LEFT_PAREN) {
                my $left_paren_num = 1;
                for ($i++; my $token = $tokens->[$i]; $i++) {
                    my $token_type = $token->{type};
                    if ($token_type == LEFT_PAREN) {
                        $left_paren_num++;
                    }
                    elsif ($token_type == RIGHT_PAREN) {
                        last if --$left_paren_num <= 0
                    }
                }
            }
            $is_in_call_context = 0;
            $is_in_ctrl_context = 0;
            next;
        }

        if ($token_type == ASSIGN) {
            $is_in_assign_context = 1;
            next;
        }

        if ($token_type == SEMI_COLON) {
            $is_in_assign_context = 0;
            next;
        }

        if ($token_type == EXEC_STRING || $token_type == REG_EXEC) {
            next if ($only_in_void_context && $is_in_assign_context);

            push @violations, {
                filename => $file,
                line     => $token->{line},
                description => DESC,
                explanation => EXPL,
            };
        }

    }

    return \@violations;
}

1;


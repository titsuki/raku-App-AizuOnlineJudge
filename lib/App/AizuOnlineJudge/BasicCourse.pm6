use v6;
use App::AizuOnlineJudge::Submittable;

unit class App::AizuOnlineJudge::BasicCourse:ver<0.0.1>;
also does App::AizuOnlineJudge::Submittable;

use URI;
use HTTP::UserAgent;

has $!ua;
has URI $.activity-uri;
has $.code;
has $.problem-number;
has $.user;
has $.language;
has %!form;

submethod BUILD(Str :$!code, Cool :$!problem-number, Str :$!user, Str :$!language, Bool :$mockable = False) {
    self.validate-code($!code);
    self.validate-language($!language);
    self.validate-problem-number($!problem-number);
    self.login(user => $!user, password => self.get-password(:$mockable)) unless $mockable;
    $!ua = HTTP::UserAgent.new;
    $!activity-uri = URI.new("https://judgeapi.u-aizu.ac.jp/submission_records/recent");

    %!form = %(
        problemId => sprintf("%04d", $!problem-number),
        language => $!language,
        sourceCode => $!code.IO.slurp;
    );
}

method run {
    my Str $token = self.post-code(:%!form);
    self.ask-result($token).say;
}

method ask-result($token) returns Str {
    my Bool $success = False;
    loop (my $try-count = 1; $try-count <= 5; $try-count++) {
        self.wait($try-count);
        my $status-response = $!ua.get($!activity-uri);
        next if not $status-response.is-success;
        my %latest = self.get-latest-by-token($status-response.content, $token);
        return sprintf("%s %.2f sec", [%latest<status>, %latest<cputime> / 100]);
    }

    if not $success {
        die "ERROR: Timeout";
    }
}

method get-latest-by-token(Str:D $json-text, Str:D $token --> Hash) {
    use JSON::Fast;

    my %latest;
    my $json = from-json($json-text);
    my @status-list = <CompileError WrongAnswer TimeLimitExceeded MemoryLimitExceeded Accepted OutputLimitExceeded RuntimeError PresentationError>;
    my %row = @($json).grep({ .<token> eq $token }).head;

    %latest<submission-date> = $%row<submissionDate>;
    %latest<status> = @status-list[%row<status>];
    %latest<cputime> = %row<cpuTime>;
    return %latest;
}

method validate-problem-number($problem-number) returns Bool {
    if $problem-number.chars != 4 {
        die "ERROR: Invalid problem-number was specified";
    }
    if not $problem-number ~~ m/\d ** 4/ {
        die "ERROR: Invalid problem-number was specified";
    }
    return True;
}

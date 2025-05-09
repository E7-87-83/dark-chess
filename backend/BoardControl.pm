package BoardControl;
use v5.30;
use DBI;
use Carp;

my $driver = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password) or croak $DBI::errstr;

sub is_board_valid {
    return 1;
}

sub is_valid_move {
    my $game_id = $_[0];
    my $move = $_[1];
    my $player = $_[2];
    my ($bd, $default_player) = $dbh->selectrow_arrayref("SELECT board, player_to_move from boards where game_id = \"$game_id\"")->@*
        or croak "Couldn't execute statement";
    croak "ERROR: Board not found for game_id $game_id." if !$bd;
    return 0 if $default_player ne $player;
    
    if (length $move == 4) {
        return 0 unless _is_valid_coord(substr($move,0,2));
        return 0 unless _is_valid_coord(substr($move,2,2));
        my $fst_cur = ord(substr($move,0,1))-ord('a');
        my $sec_cur = ord(substr($move,1,1))-ord('1');
        my $fst_nxt = ord(substr($move,2,1))-ord('a');
        my $sec_nxt = ord(substr($move,3,1))-ord('1');
        return 0 unless abs($fst_cur-$fst_nxt)+abs($sec_cur-$sec_nxt) == 1;
        return 0 unless _piece_is_belonged_to_the_player($player, substr($bd, 1+$sec_cur*16+$fst_cur*2, 1));
        return 0 unless substr($bd, $sec_cur*16+$fst_cur*2, 1) eq "o";
        return 0 unless substr($bd, $sec_nxt*16+$fst_nxt*2,2) eq ".." || _piece_is_belonged_to_the_player(int(!$player), substr($bd, 1+$sec_nxt*16+$fst_nxt*2, 1)) && substr($bd, $sec_nxt*16+$fst_nxt*2, 1) eq "o";
        if (substr($bd, $sec_nxt*16+$fst_nxt*2,1) eq "o") {
            return 0 unless 
              _can_former_capture_latter( substr($bd, 1+$sec_cur*16+$fst_cur*2, 1) , substr($bd, 1+$sec_nxt*16+$fst_nxt*2, 1) );
        }
    } elsif (length $move == 3) {
        return 0 unless substr($move,0,1) eq "O";
        return 0 unless _is_valid_coord(substr($move,1,2));
        my $fst = ord(substr($move,1,1))-ord('a');
        my $sec = ord(substr($move,2,1))-ord('1');
        return 0 unless substr($bd, $sec*16+$fst*2, 1) eq "x";
    } else {
        return 0;
    }

    return 1;
}

sub act_move_on_game {
    my $game_id = $_[0];
    my $move = $_[1];
    my $player = $_[2];
    my ($bd, $default_player) = $dbh->selectrow_arrayref("SELECT board, player_to_move from boards where game_id = \"$game_id\"")->@*
        or croak "Couldn't execute statement: ". $dbh->errstr;
    croak "ERROR: Board not found for game_id $game_id." if !$bd;
    croak "ERROR: original board string does not fit the format" unless is_board_valid($bd);
    croak "ERROR: not the assigned player's turn" if $default_player ne $player;

    my $new_bd = ""; 
    if (length $move == 4) {
        my $fst_cur = ord(substr($move,0,1))-ord('a');
        my $sec_cur = ord(substr($move,1,1))-ord('1');
        my $fst_nxt = ord(substr($move,2,1))-ord('a');
        my $sec_nxt = ord(substr($move,3,1))-ord('1');
        my $piece = substr($bd, 1+$sec_cur*16+$fst_cur*2,1);
        substr($bd, $sec_cur*16+$fst_cur*2,2) = "..";
        substr($bd, $sec_nxt*16+$fst_nxt*2,2) = "o".$piece;
        $new_bd = $bd;
    } elsif (length $move == 3) {
        my $fst = ord(substr($move,1,1))-ord('a');
        my $sec = ord(substr($move,2,1))-ord('1');
        substr($bd, $sec*16+$fst*2, 1) = "o";
        $new_bd = $bd;
    } else {
        croak "ERROR: illegal move";
    }
    my $new_player = int(!$player);
    croak "ERROR: new board string does not fit the format" unless is_board_valid($new_bd);
    $dbh->do("UPDATE boards SET board = \"$new_bd\" WHERE game_id = \"$game_id\"") or return 0;
    $dbh->do("UPDATE boards SET player_to_move = \"$new_player\" WHERE game_id = \"$game_id\"") or return 0;
    return 1;
}

sub _piece_is_belonged_to_the_player {
    my $player = $_[0];
    my $piece = $_[1];
    return 1 if
        $player == 1 && $piece =~ /^[KRNCABP]{1}$/ || $player == 0 && $piece =~ /^[krncabp]{1}$/; 
    return 0;
}

sub _is_valid_coord {
    my $c = $_[0];
    return 0 unless length $c == 2;
    return 0 unless substr($c,0,1) le "h" && substr($c,0,1) ge "a"
                      && substr($c,1,1) le "4" && substr($c,1,1) ge "1";
    return 1;
}

sub _can_former_capture_latter {
    my $p0 = lc $_[0];
    my $p1 = lc $_[1];
    return 1 if $p0 eq "p" && $p1 eq "k";
    return 0 if $p0 eq "k" && $p1 eq "p";
    my %rate = (
        "k" => 7,
        "r" => 6,
        "n" => 5,
        "c" => 4,
        "a" => 3,
        "b" => 2,
        "p" => 1,
    );
    return 1 if $rate{$p0} >= $rate{$p1};
    return 0;
}

1;

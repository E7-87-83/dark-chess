use v5.30;
use Mojolicious::Lite;
use LWP::UserAgent;

my $localpath = 'http://localhost';
my $board;

post '/play/:game_id/:move' => sub () {
  my $game_id = $_[0]->param('game_id');
  my $move = $_[0]->param('move');
  my $ua = LWP::UserAgent->new(timeout => 10);
  if (is_valid_move($game_id, $move)) {
	  my $res = $ua->post("$localpath:5000/game/$game_id/$move", {passkey => 'darkchess01'} );
  }
  $_[0]->rendered(200);
};

post '/game/:game_id/:move' => sub () {
  my $passkey = $_[0]->param('passkey');
  my $game_id = $_[0]->param('game_id');
  my $move = $_[0]->param('move');
  if ($passkey eq 'darkchess01') {
	  act_move_on_game($game_id, $move);
	  $_[0]->rendered(200);
  } else {
	  $_[0]->rendered(400);
  }
};

get '/cond/:game_id' => sub () {
  my $game_id = $_[0]->param('game_id');
  $_[0]->render(text => $board);
};

# Start the Mojolicious command system
app->start;

sub is_valid_move {
	return 1;
}


sub act_move_on_game {
	my $game_id = $_[0];
	my $move = $_[1];
	$board .= $move;
}

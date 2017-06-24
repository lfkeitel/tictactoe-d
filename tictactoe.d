import engine;
import std.stdio;

void main() {
    writeln("TicTacToe in D");

    engine.Player[2] players = [null, null];

    int numOfPlayers;
    write("Number of Players (1-2): ");
    readf(" %s", numOfPlayers);

    if (numOfPlayers < 1 || numOfPlayers > 2) {
        write("You didn't listen did you.");
        return;
    }

    players[0] = new engine.HumanPlayer('A');

    if (numOfPlayers == 1) {
        players[1] = new engine.AIPlayer('B');
    } else {
        players[1] = new engine.HumanPlayer('B');
    }

    int currentPlayer;
    auto board = new engine.Board();

    while (true) {
        writeln("");
        writefln("Player %s's turn", players[currentPlayer].marker);

        board.print();
        players[currentPlayer].makeMove(board);

        if (board.getWinner() !is null || board.isTie()) {
            break;
        }

        currentPlayer = (currentPlayer + 1) % 2;
    }

    board.print();

    auto winner = board.getWinner();

    if (winner !is null) {
        writefln("Player %s won!", winner.marker());
    } else if (board.isTie()) {
        writeln("It's a tie!");
    } else {
        writeln("The world has ended.");
    }
}

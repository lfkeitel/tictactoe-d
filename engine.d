import std.array;
import std.random;
import std.stdio;

private immutable int[3][8] winningTriplets = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6]
];

class Board {
    private Player[] m_current;

    this() {
        m_current = new Player[9];

        foreach (i; 0 .. 9) {
            m_current[i] = new PlaceholderPlayer(cast(char)(' '));
        }
    }

    bool spaceOpen(Move move) {
        return spaceOpenIndex(move.space-1);
    }

    private bool spaceOpenIndex(int index) {
        auto space = m_current[index];
        return (cast(PlaceholderPlayer)space !is null);
    }

    bool indexBelongsToPlayer(int space, Player player) {
        return m_current[space] == player;
    }

    void print() {
        writeln("");
        writeln("+---+---+---+");
        writefln("| %s | %s | %s |", m_current[0].marker, m_current[1].marker, m_current[2].marker);
        writeln("+---+---+---+");
        writefln("| %s | %s | %s |", m_current[3].marker, m_current[4].marker, m_current[5].marker);
        writeln("+---+---+---+");
        writefln("| %s | %s | %s |", m_current[6].marker, m_current[7].marker, m_current[8].marker);
        writeln("+---+---+---+");
    }

    void makeMove(Move move, Player player) {
        if (!spaceOpen(move)) {
            throw new SpaceTakenException("Space already taken");
        }

        m_current[move.space-1] = player;
    }

    Player getWinner() {
        foreach (triplet; winningTriplets) {
            const int a = triplet[0];
            const int b = triplet[1];
            const int c = triplet[2];

            if (m_current[a] == m_current[b] && m_current[b] == m_current[c]) {
                    return m_current[a];
            }
        }
        return null;
    }

    bool isTie() {
        foreach (space; m_current) {
            if (cast(PlaceholderPlayer)space !is null) {
                return false;
            }
        }
        return true;
    }

    int[] getFreeSpaces() {
        int[] freeSpaces;
        auto apper = appender(freeSpaces);

        foreach(i, space; m_current) {
            if (spaceOpenIndex(i)) {
                apper.put(i);
            }
        }

        return apper.data();
    }
}

class Move {
    private int m_space;

    @property int space() { return m_space; }

    this(int space) {
        if (space < 1 || space > 9) {
            throw new BadMoveException("Space out of bounds");
        }

        this.m_space = space;
    }
}

abstract class Player {
    private char m_marker;

    @disable this();

    this(char marker) {
        this.m_marker = marker;
    }

    @property char marker() { return m_marker; }

    abstract void makeMove(Board board);
}

private class PlaceholderPlayer : Player {
    @disable this();
    this(char marker) {
        super(marker);
    }

    override void makeMove(Board board) {}
}

class HumanPlayer : Player {
    @disable this();
    this(char marker) {
        super(marker);
    }

    override void makeMove(Board board) {
        int move;

        write("Choose a space (1-9): ");
        readf(" %s", move);

        try {
            board.makeMove(new Move(move), this);
        } catch (BadMoveException) {
            write("Bad move, try again");
            makeMove(board);
        } catch (SpaceTakenException) {
            write("Space taken, try again");
            makeMove(board);
        }
    }
}

class AIPlayer : Player {
    @disable this();
    this(char marker) {
        super(marker);
    }

    override void makeMove(Board board) {
        const int winningMove = findWinningMove(board);
        if (winningMove > 0) {
            board.makeMove(new Move(winningMove), this);
            return;
        }

        const int defendingMove = findDefendingMove(board);
        if (defendingMove > 0) {
            board.makeMove(new Move(defendingMove), this);
            return;
        }

        const int randomMove = findRandomMove(board);
        board.makeMove(new Move(randomMove), this);
    }

    private int findWinningMove(Board board) {
        foreach (triplet; winningTriplets) {
            const int a = triplet[0];
            const int b = triplet[1];
            const int c = triplet[2];

            if (board.spaceOpen(new Move(a+1)) &&
                board.indexBelongsToPlayer(b, this) &&
                board.indexBelongsToPlayer(c, this)) {
                return a+1;
            } else if (board.indexBelongsToPlayer(a, this) &&
                        board.spaceOpen(new Move(b+1)) &&
                        board.indexBelongsToPlayer(c, this)) {
                return b+1;
            } else if (board.indexBelongsToPlayer(a, this) &&
                        board.indexBelongsToPlayer(b, this) &&
                        board.spaceOpen(new Move(c+1))) {
                return c+1;
            }
        }
        return 0;
    }

    private int findDefendingMove(Board board) {
        foreach (triplet; winningTriplets) {
            const int a = triplet[0];
            const int b = triplet[1];
            const int c = triplet[2];

            if (board.spaceOpen(new Move(a+1)) &&
                takenAndOwnedByOtherPlayer(b, board) &&
                takenAndOwnedByOtherPlayer(c, board)) {
                return a+1;
            } else if (takenAndOwnedByOtherPlayer(a, board) &&
                        board.spaceOpen(new Move(b+1)) &&
                        takenAndOwnedByOtherPlayer(c, board)) {
                return b+1;
            } else if (takenAndOwnedByOtherPlayer(a, board) &&
                        takenAndOwnedByOtherPlayer(b, board) &&
                        board.spaceOpen(new Move(c+1))) {
                return c+1;
            }
        }
        return 0;
    }

    private bool takenAndOwnedByOtherPlayer(int space, Board board) {
        return (!board.spaceOpen(new Move(space+1)) && !board.indexBelongsToPlayer(space, this));
    }

    private int findRandomMove(Board board) {
        int[] freeSpaces = board.getFreeSpaces();
        const int index = uniform(0, freeSpaces.length);
        return freeSpaces[index]+1;
    }
}

class BadMoveException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class SpaceTakenException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

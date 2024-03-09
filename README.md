# About this project


## Repository

This repository will have at least three Godot projects inside. It will contain:
1) Raw or Pre-refactor version (that was hacked quickly with very questionable design choices), 
2) Object oriented design based around inheritance,
3) Entity component system.

## Project
Project is a game,
When the game starts, player chooses color of his pieces. 
Both sides are being controlled by player(hotseat)
White always starts first.

To move your piece, use mouse to drag it picking one of available legal move. 
Legal moves are highlighted with green color, captures with red.
This release makes it impossible to lose by making misplay and putting your own King in check.

Rules:
*If you king gets checkmated (it got checked and there are no safe legal moves to get out of check),
you lose. If enemy king gets checkmated, you win.

*If your or enemy king didn't get checked but there are no legal safe moves for king to make and there
are no other pieces, stalemate is announced (draw).

*If there is no visible chance to checkmate the opponent on either side (two kings are left on the chessboard,
king and bishop, king and knight etc.), draw is forced.

*If there were no pawn moves and captures for 50 turns, draw is proposed. You can deny it but if situation won't
change in 75 turns, draw will be forced.

*Draw will also be forced once both players start repeating their moves.

Once game is finished, player is offered a choice to play again, change color or quit.

## Additional elements (less known):

*Castling - when your King and Rooks didn't make a move in entire game, there are no pieces between them and squares between
them are not in enemy range, you can move your king by two squares which will also reposition rook you are moving towards to.

*En Passant - from french, tresspassing. Pawns can capture enemy pawn when it's placed on third row on enemy side, it's first
enemy piece move and it moves by two squares, passing your pawn by. This is when you can capture said piece diagonally, capturing
same square as pawn would be in if it moved only one square.

## History
I got commissioned to create simple Chess application in Godot in less than 3 days but requirements
were quite advanced for what I was capable of. I pulled it off, working hard entire weekend but
commissioner first tried to coherce me into adding many extra features for free. While originally he slightly mentioned
adding additional piece or two, initially it was meant to be basic chess functionality for extremally low price (which
I only took as I found it interesting opportunity to learn and make first small, complete, working project).

As this "extra work" he asked for turned out to be full, time consuming feature, I refused and he didn't pay me a dime.
That being said, I decided not to throw project away but finish it, refactor, use as experiment for Godot's capabilities
in terms of object structure/organization and share it with community along with my thoughts.

## Future

I plan to release complete game but with much more content and polish, maybe even giving it some narrative. We shall see. 
That's TBD after Pokemock/Pokemon Blue Replica is released in initial, playable state.

# Lessons

As Uncle Bob mentioned in his Clean Architecture book, you always pay for architecture but cost is much greater if
you do it later. I learned importance of designing and planning way before I touch the code structure. I need to know
what exactly needs to be inside the scope AND how it will roughly be implemented. Then knowing that, I have to prepare
mental (or diagram) image how components are going to interact with each other. Each functionality should be testable
and have as little dependency (ideally none) as possible.
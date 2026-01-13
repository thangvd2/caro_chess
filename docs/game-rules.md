# Game Rules

This document provides detailed explanations of the three game rule variants in Caro Chess.

## Overview

Caro (also known as Gomoku or Five in a Row) is a strategy board game where two players take turns placing pieces on a grid. The goal is to create a line of pieces according to the selected rule variant.

**Board Size**: 15x15 grid (default)

**Players**:
- Player X (always goes first)
- Player O

**Win Directions**: Horizontal, Vertical, Diagonal (both directions)

---

## Standard Rules

### Objective
First player to get **exactly 5 pieces in a row** wins.

### Details
- **Win Condition**: Exactly 5 consecutive pieces
- **Overlines**: 6 or more pieces in a row does NOT count as a win
- **Blocked Ends**: Both ends can be blocked or unblocked (doesn't matter)

### Examples

**Winning Position (X wins):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . . X X X X X . .  <- X wins with exactly 5
4  . . . . . . . . . .
5  . . . . . . . . . .
```

**Not a Win (Overline):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . X X X X X X . .  <- 6 in a row - NOT a win
4  . . . . . . . . . .
5  . . . . . . . . . .
```

### Strategy
- Build towards 5 in a row while blocking opponent
- Be careful not to create 6 in a row
- Control the center of the board for more opportunities

---

## FreeStyle Rules

### Objective
First player to get **5 or more pieces in a row** wins.

### Details
- **Win Condition**: 5 or more consecutive pieces
- **Overlines**: 6 or more pieces in a row DOES count as a win
- **Blocked Ends**: Both ends can be blocked or unblocked (doesn't matter)

### Examples

**Winning Position - Exactly 5:**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . . X X X X X . .  <- X wins with 5
4  . . . . . . . . . .
5  . . . . . . . . . .
```

**Winning Position - Overline:**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . X X X X X X . .  <- X wins with 6
4  . . . . . . . . . .
5  . . . . . . . . . .
```

### Strategy
- More aggressive than Standard - overlines are acceptable
- Focus on building long chains
- Less concern about accidentally creating 6+ in a row

---

## Caro Rules (Vietnamese Style)

### Objective
First player to get **exactly 5 pieces in a row with both ends open** wins.

### Details
- **Win Condition**: Exactly 5 consecutive pieces
- **Both Ends Open**: Neither end of the 5-piece line can be blocked by opponent's piece or board edge
- **Overlines**: 6 or more pieces in a row does NOT count as a win
- **Blocked by Edge**: Board edge counts as a blocked end

### What Counts as "Blocked"?

An end is **blocked** if:
1. The opponent's piece is adjacent to the end, OR
2. The end is at the board edge

An end is **open** if:
1. The cell is empty, OR
2. Your own piece is adjacent (you can extend)

### Examples

**Winning Position (both ends open):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . . X X X X X . .  <- Both ends are empty (open)
4  . . . . . . . . . .
5  . . . . . . . . . .
```

**NOT a Win (one end blocked by O):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . O X X X X X . .  <- Left end blocked by O
4  . . . . . . . . . .     NOT a win in Caro rules
5  . . . . . . . . . .
```

**NOT a Win (one end blocked by edge):**
```
   0 1 2 3 4 5 6 7 8 9
0  X X X X X . . . . .  <- Left end at board edge
1  . . . . . . . . . .     NOT a win in Caro rules
2  . . . . . . . . . .
```

**Winning Position (your piece at end):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . X . . . . . . .
3  . . . X X X X X . .  <- X at left end - still counts as open
4  . . . . . . . . . .     (your piece means you can extend)
5  . . . . . . . . . .
```

**NOT a Win (overline):**
```
   0 1 2 3 4 5 6 7 8 9
0  . . . . . . . . . .
1  . . . . . . . . . .
2  . . . . . . . . . .
3  . . X X X X X X . .  <- 6 in a row - NOT a win
4  . . . . . . . . . .
5  . . . . . . . . . .
```

### Visual Guide

```
Legend:
  . = Empty cell
  X = Player X's piece
  O = Player O's piece
  # = Board edge (implicit)

Standard:  X X X X X  -> WIN
           . X X X X X . -> WIN

FreeStyle:  X X X X X  -> WIN
           X X X X X X  -> WIN (overline counts)

Caro:       . X X X X X . -> WIN (both ends open)
            O X X X X X . -> NO WIN (left blocked)
            # X X X X X . -> NO WIN (left at edge)
```

### Strategy
- More defensive - must avoid being blocked
- Build lines away from board edges
- Create "open fours" (4 in a row with both ends open) as threats
- Block opponent's open ends aggressively

---

## Rule Comparison

| Feature | Standard | FreeStyle | Caro |
|---------|----------|-----------|------|
| Pieces to Win | Exactly 5 | 5 or more | Exactly 5 |
| Overline Wins | No | Yes | No |
| Blocked Ends | Allowed | Allowed | Not Allowed |
| Board Edge | Blocks win | Doesn't matter | Blocks win |
| Difficulty | Medium | Easiest | Hardest |

---

## Implementation Details

### Code Reference

The win detection is implemented in:
- **Client**: `lib/engine/game_engine.dart` (lines 92-153)
- **Server**: `server/engine/engine.go` (lines 67-160)

Both implementations check 4 directions:
1. Horizontal (left-right)
2. Vertical (up-down)
3. Diagonal (\)
4. Anti-diagonal (/)

### Win Detection Algorithm

For each placed piece, the algorithm:
1. Counts consecutive pieces in both directions along each axis
2. Calculates total count: `1 + forward_count + backward_count`
3. Applies rule-specific validation:
   - **Standard**: Total count must equal 5
   - **FreeStyle**: Total count must be >= 5
   - **Caro**: Total count must equal 5 AND both ends must be open

### Edge Cases Handled

- **Board boundaries**: Checks prevent out-of-bounds access
- **Empty cells**: Only counts cells with the current player's pieces
- **Multiple directions**: Returns first winning line found
- **Simultaneous wins**: Only first checked direction returns (rare case)

---

## Tips for Players

### For Beginners
1. Start with **Standard** rules to learn the basics
2. Focus on the center of the board (more opportunities)
3. Watch for opponent's 3-in-a-row threats
4. Create "forks" (two ways to win on next turn)

### For Advanced Players
1. **Caro** rules offer the deepest strategic play
2. Master the "open three" and "open four" patterns
3. Learn to recognize forced sequences
4. Practice defensive blocking strategies

### Common Patterns

**Open Three** (3 in a row, both ends open):
```
. X X X .
```
Dangerous - can become open four!

**Open Four** (4 in a row, both ends open):
```
. X X X X .
```
Guaranteed win ( opponent can only block one end)

**Fork** (two ways to win):
```
. X X . X .
    .   X
    X   .
```
Opponent can't defend both threats!

---

## Rule Selection in Game

Use the **Rule Selector** widget in the game to switch between rules:
- **Standard**: Balanced gameplay
- **FreeStyle**: Faster, more aggressive games
- **Caro**: Traditional Vietnamese rules, more strategic

The selected rule affects both win detection and AI behavior.

---

## References

- [Gomoku Wikipedia](https://en.wikipedia.org/wiki/Gomoku)
- [Caro (Vietnamese variant)](https://en.wikipedia.org/wiki/Gomoku#Variants)

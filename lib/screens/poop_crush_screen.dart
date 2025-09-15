import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../Theme.dart';

enum PoopType { red, blue, green, yellow, purple, orange }
enum SpecialPoopType { none, striped, wrapped, colorBomb }

class Poop {
  PoopType type;
  SpecialPoopType special;
  bool isSelected;
  bool markedForRemoval;

  Poop({
    required this.type,
    this.special = SpecialPoopType.none,
    this.isSelected = false,
    this.markedForRemoval = false,
  });

  String get emoji {
    if (special == SpecialPoopType.colorBomb) return '✨';
    switch (type) {
      case PoopType.red:
        return '💩';
      case PoopType.blue:
        return '🧻';
      case PoopType.green:
        return '🤮';
      case PoopType.yellow:
        return '🚽';
      case PoopType.purple:
        return '🚻';
      case PoopType.orange:
        return '🪠';
    }
  }
}

class PoopCrushGame extends StatefulWidget {
  const PoopCrushGame({super.key});

  @override
  State<PoopCrushGame> createState() => _PoopCrushGameState();
}

class _PoopCrushGameState extends State<PoopCrushGame>
    with TickerProviderStateMixin {
  static const int gridSize = 8;
  List<List<Poop?>> grid = [];
  int score = 0;
  int level = 1;
  int moves = 25;
  int targetScore = 1000;
  int? selectedRow;
  int? selectedCol;

  int highScore = 0;
  int maxLevel = 1;

  late AnimationController _cascadeController;
  bool isAnimating = false;
  bool isGridInitialized = false;
  
  final Random _random = Random();
  
  static const List<PoopType> availablePoopTypes = [
    PoopType.red,
    PoopType.blue,
    PoopType.green,
    PoopType.yellow,
    PoopType.purple,
    PoopType.orange,
  ];

  @override
  void initState() {
    super.initState();
    _cascadeController =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _initializeGameAsync();
  }

  void _initializeGameAsync() async {
    await _loadGameData();
    initializeGrid();
  }

  @override
  void dispose() {
    _cascadeController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          highScore = prefs.getInt('poop_crush_high_score') ?? 0;
          maxLevel = prefs.getInt('poop_crush_max_level') ?? 1;
          score = prefs.getInt('poop_crush_current_score') ?? 0;
          level = prefs.getInt('poop_crush_current_level') ?? 1;
          moves = prefs.getInt('poop_crush_current_moves') ?? 25;
          targetScore = prefs.getInt('poop_crush_target_score') ?? 1000;
        });
      }
    } catch (e) {
      print('Error loading game data: $e');
    }
  }

  Future<void> _saveGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (score > highScore) {
        highScore = score;
        await prefs.setInt('poop_crush_high_score', highScore);
      }
      if (level > maxLevel) {
        maxLevel = level;
        await prefs.setInt('poop_crush_max_level', maxLevel);
      }
      await prefs.setInt('poop_crush_current_score', score);
      await prefs.setInt('poop_crush_current_level', level);
      await prefs.setInt('poop_crush_current_moves', moves);
      await prefs.setInt('poop_crush_target_score', targetScore);
    } catch (e) {
      print('Error saving game data: $e');
    }
  }

  void initializeGrid() {
    try {
      grid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => null));
      
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          final randomIndex = _random.nextInt(availablePoopTypes.length);
          grid[row][col] = Poop(type: availablePoopTypes[randomIndex]);
        }
      }
      
      if (mounted) {
        setState(() {
          isGridInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing grid: $e');
      grid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => 
          Poop(type: PoopType.red)
      ));
      if (mounted) {
        setState(() {
          isGridInitialized = true;
        });
      }
    }
  }

  // ----------------- NEW GAME LOGIC -----------------

  void _onTileTap(int row, int col) {
    if (moves <= 0 || isAnimating || !isGridInitialized) return;
    if (grid[row][col] == null) return;

    if (selectedRow == null || selectedCol == null) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
        grid[row][col]!.isSelected = true;
      });
    } else {
      if ((row - selectedRow!).abs() + (col - selectedCol!).abs() == 1) {
        _swapTiles(selectedRow!, selectedCol!, row, col);
      } else {
        setState(() {
          grid[selectedRow!][selectedCol!]!.isSelected = false;
          selectedRow = row;
          selectedCol = col;
          grid[row][col]!.isSelected = true;
        });
        return;
      }

      setState(() {
        grid[selectedRow!][selectedCol!]!.isSelected = false;
        selectedRow = null;
        selectedCol = null;
      });
    }
  }

  void _swapTiles(int row1, int col1, int row2, int col2) {
    setState(() {
      final temp = grid[row1][col1];
      grid[row1][col1] = grid[row2][col2];
      grid[row2][col2] = temp;
    });

    if (_checkAndHandleMatches()) {
      moves--;
      _saveGameData();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          final temp = grid[row1][col1];
          grid[row1][col1] = grid[row2][col2];
          grid[row2][col2] = temp;
        });
      });
    }
  }

  bool _checkAndHandleMatches() {
    bool foundMatch = false;
    List<List<bool>> toRemove =
        List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

    // Rows
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize - 2; col++) {
        Poop? p1 = grid[row][col];
        Poop? p2 = grid[row][col + 1];
        Poop? p3 = grid[row][col + 2];
        if (p1 != null &&
            p2 != null &&
            p3 != null &&
            p1.type == p2.type &&
            p1.type == p3.type) {
          foundMatch = true;
          toRemove[row][col] = true;
          toRemove[row][col + 1] = true;
          toRemove[row][col + 2] = true;
        }
      }
    }

    // Cols
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize - 2; row++) {
        Poop? p1 = grid[row][col];
        Poop? p2 = grid[row + 1][col];
        Poop? p3 = grid[row + 2][col];
        if (p1 != null &&
            p2 != null &&
            p3 != null &&
            p1.type == p2.type &&
            p1.type == p3.type) {
          foundMatch = true;
          toRemove[row][col] = true;
          toRemove[row + 1][col] = true;
          toRemove[row + 2][col] = true;
        }
      }
    }

    if (foundMatch) {
      _removeMatches(toRemove);
    }
    return foundMatch;
  }

  void _removeMatches(List<List<bool>> toRemove) {
    setState(() {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (toRemove[row][col]) {
            grid[row][col] = null;
            score += 50;
          }
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _cascadeTiles();
    });
  }

  void _cascadeTiles() {
    setState(() {
      for (int col = 0; col < gridSize; col++) {
        int emptyRow = gridSize - 1;
        for (int row = gridSize - 1; row >= 0; row--) {
          if (grid[row][col] != null) {
            grid[emptyRow][col] = grid[row][col];
            if (emptyRow != row) {
              grid[row][col] = null;
            }
            emptyRow--;
          }
        }
        for (int row = emptyRow; row >= 0; row--) {
          grid[row][col] = Poop(
            type: availablePoopTypes[_random.nextInt(availablePoopTypes.length)],
          );
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _checkAndHandleMatches();
    });
  }

  // ----------------- END GAME LOGIC -----------------

  void _resetGame() {
    setState(() {
      score = 0;
      level = 1;
      moves = 25;
      targetScore = 1000;
      selectedRow = null;
      selectedCol = null;
      isGridInitialized = false;
    });
    initializeGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💩 Poop Crush'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _saveGameData();
              _resetGame();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.creamBackground,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Score panel
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoCard('Score', score.toString()),
                  _buildInfoCard('Level', level.toString()),
                  _buildInfoCard('Moves', moves.toString()),
                  _buildInfoCard('Target', targetScore.toString()),
                ],
              ),
            ),
            // High scores display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'High Score: $highScore  •  Max Level: $maxLevel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.softBlack.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Game Grid
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brownPrimary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isGridInitialized ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    int row = index ~/ gridSize;
                    int col = index % gridSize;
                    
                    if (row >= grid.length || col >= grid[row].length) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }
                    
                    Poop? poop = grid[row][col];
                    
                    if (poop == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }
                    
                    return GestureDetector(
                      onTap: () => _onTileTap(row, col),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: poop.isSelected
                              ? AppTheme.orangeAccent.withOpacity(0.3)
                              : Colors.white,
                          border: Border.all(
                            color: poop.isSelected
                                ? AppTheme.orangeAccent
                                : AppTheme.brownPrimary.withOpacity(0.2),
                            width: poop.isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: poop.isSelected 
                              ? [
                                  BoxShadow(
                                    color: AppTheme.orangeAccent.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: AppTheme.softBlack.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(
                            poop.emoji,
                            style: TextStyle(
                              fontSize: poop.isSelected ? 24 : 22,
                              shadows: poop.isSelected
                                  ? [
                                      Shadow(
                                        color: AppTheme.orangeAccent.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ) : const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            // Game status
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (moves <= 0)
                    ElevatedButton(
                      onPressed: _resetGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('New Game'),
                    )
                  else
                    Text(
                      'Tap to select poops and make matches!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.brownPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.brownPrimary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brownPrimary.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.softBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

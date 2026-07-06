import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'unit_tile.dart';

/// The 5x4 drag-to-merge board.
class MergeGrid extends StatelessWidget {
  final List<BoardUnit?> board;

  /// Called when [from] is dropped onto [to] (indices into [board]).
  final void Function(int from, int to) onDrop;

  const MergeGrid({super.key, required this.board, required this.onDrop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final cell =
            ((constraints.maxWidth - gap * (kBoardCols - 1)) / kBoardCols)
                .clamp(0.0, 92.0);

        return Center(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(kBoardSize, (i) {
              return _Cell(
                index: i,
                unit: board[i],
                size: cell,
                onDrop: onDrop,
              );
            }),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final int index;
  final BoardUnit? unit;
  final double size;
  final void Function(int from, int to) onDrop;

  const _Cell({
    required this.index,
    required this.unit,
    required this.size,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onDrop(d.data, index),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final u = unit;
        if (u == null) {
          return EmptySlot(size: size, highlight: hovering);
        }
        return Draggable<int>(
          data: index,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Transform.translate(
            offset: Offset(-size / 2, -size / 2),
            child: UnitCard(level: u.level, size: size * 1.08, dragging: true),
          ),
          childWhenDragging: EmptySlot(size: size, highlight: hovering),
          child: Container(
            decoration: hovering
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.6),
                        blurRadius: 18,
                      ),
                    ],
                  )
                : null,
            child: UnitTile(
              key: ValueKey(u.id),
              level: u.level,
              size: size,
            ),
          ),
        );
      },
    );
  }
}

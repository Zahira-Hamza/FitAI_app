import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerType { card, listTile, grid, statCard }

class ShimmerLoader extends StatelessWidget {
  final ShimmerType type;
  final int count;

  const ShimmerLoader({
    super.key,
    this.type = ShimmerType.listTile,
    this.count = 3,
  });

  static const _base = Color(0xFF1C1C2E);
  static const _highlight = Color(0xFF252538);

  Widget _shimmerBox({
    double? width,
    double height = 16,
    double radius = 8,
  }) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  Widget _buildListTile() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _shimmerBox(width: 48, height: 48, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 14),
                  const SizedBox(height: 8),
                  _shimmerBox(width: 140, height: 12),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildCard() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(16),
        ),
      );

  Widget _buildGridCard() => Container(
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(16),
        ),
      );

  Widget _buildStatCard() => Container(
        height: 90,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(16),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case ShimmerType.card:
        return Column(
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCard(),
            ),
          ),
        );

      case ShimmerType.listTile:
        return Column(
          children: List.generate(count, (_) => _buildListTile()),
        );

      case ShimmerType.grid:
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: List.generate(count, (_) => _buildGridCard()),
        );

      case ShimmerType.statCard:
        return Row(
          children: List.generate(
            count,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: _buildStatCard(),
              ),
            ),
          ),
        );
    }
  }
}

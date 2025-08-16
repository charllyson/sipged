import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerChartBar extends StatelessWidget {
  const ShimmerChartBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 500,
          height: 40,
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: Colors.grey,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(50,),
                borderRadius: const BorderRadius.all(Radius.circular(8,),),),
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),),
        ),
      ],
    );
  }
}

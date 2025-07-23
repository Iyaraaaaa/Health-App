import 'package:flutter/material.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController controller = PageController();
  int selectPage = 0;

  final List<Map<String, String>> pageArr = [
    {
      "img": "assets/images/on_board_1.avif",
      "title": "Health Ministry",
      "subtitle": "A healthier nation that contributes to its economic, social, mental, and spiritual development.",
    },
    {
      "img": "assets/images/on_board_2.jpg",
      "title": "සෞඛ්‍ය අමාත්‍යාංශය",
      "subtitle": "ආර්ථික, සමාජ, මානසික සහ ආත්මික සංවර්ධනයට දායක වන සෞඛ්‍යයෙන් පිරි නව ජාතියක්.",
    },
    {
      "img": "assets/images/on_board_3.jpg",
      "title": "சுகாதார அமைச்சகம்",
      "subtitle": "தனது பொருளாதார, சமூக, மனநல மற்றும் ஆன்மிக முன்னேற்றத்திற்கு συμβளிக்கக்கூடிய ஆரோக்கியமான நாடு..",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: pageArr.length,
            onPageChanged: (page) {
              setState(() {
                selectPage = page;
              });
            },
            itemBuilder: (context, index) {
              final obj = pageArr[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: size.height * 0.6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: AssetImage(obj["img"]!),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      obj["title"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      obj["subtitle"]!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pageArr.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selectPage == i ? 12 : 8,
                          height: selectPage == i ? 12 : 8,
                          decoration: BoxDecoration(
                            color: selectPage == i ? Colors.white : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 70,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip always visible
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login_page');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "Skip",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                // Next or Get Started button
                selectPage == pageArr.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login_page');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Get Started", style: TextStyle(fontSize: 16)),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Next", style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

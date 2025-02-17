import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]!
                  : Colors.grey[300]!,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.grey[400]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Section
              _buildSectionTitle(context, 'About Us'),
              const SizedBox(height: 10),
              FadeInAnimation(
                child: Text(
                  'Welcome to Yantra Prasamvidha!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pacifico',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.tealAccent
                        : Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              // Add Images in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/vcetlogo.png', // Path to VCET logo
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(width: 20), // Spacing between the images
                  Image.asset(
                    'assets/yantraprasamvidha.png', // Path to Yantra Prasamvidha logo
                    width: 105,
                    height: 105,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Our platform is designed to provide seamless solutions for tool rentals.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'Roboto',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent[400]
                      : Colors.teal[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Guide Section
              _buildSectionTitle(context, 'Guide'),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                context,
                name: 'Prof. Pradeep Kumar K G',
                role: 'Head of Department (Computer Science & Engineering)',
                imageUrl: 'assets/pradeepsir.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 20),
              // Team Members Section
              _buildSectionTitle(context, 'Team Members'),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                context,
                name: 'Aneesh S Mayya',
                role: 'Assistant Developer',
                imageUrl: 'assets/aneesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                context,
                name: 'Anwesh Krishna B',
                role: 'Lead Developer',
                imageUrl: 'assets/anwesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                context,
                name: 'Chinmaya Thejasvi U S',
                role: 'Assistant Developer',
                imageUrl: 'assets/chinmay.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                context,
                name: 'Ganesh B S',
                role: 'Assistant Developer',
                imageUrl: 'assets/ganesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 20),
              // Acknowledgments Section
              _buildSectionTitle(context, 'Acknowledgments'),
              const SizedBox(height: 10),
              Text(
                'We extend our heartfelt gratitude to Prof. Pradeep Kumar K G for his guidance and support throughout this project. '
                'We thank Vivekananda College of Engineering and Technology, Puttur, for providing the resources and environment that made this possible. '
                'Special thanks to the Principal, Management, and staff for fostering innovation and academic excellence.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'Roboto',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent[400]
                      : Colors.teal[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Closing Message
              FadeInAnimation(
                child: Text(
                  'This project is a testament to teamwork, dedication, and innovation. We hope you enjoy using our app as much as we enjoyed creating it!',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'DancingScript',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.tealAccent
                        : Colors.teal[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Method to Build Section Titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return FadeInAnimation(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lobster',
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.tealAccent
              : Colors.teal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Helper Method to Build Team Member Cards
Widget _buildTeamMemberCard(
  BuildContext context, {
  required String name,
  required String role,
  required String imageUrl,
  bool isAsset = false, // Flag to check if the image is from assets
}) {
  return FadeInAnimation(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: isAsset
                ? Image.asset(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.tealAccent
                        : Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Custom Animation Widget
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  const FadeInAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _FadeInAnimationState createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

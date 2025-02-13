import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('About Us'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[200]!,
              Colors.grey[300]!,
              Colors.grey[400]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Section
              _buildSectionTitle('About Us'),
              const SizedBox(height: 10),
              FadeInAnimation(
                child: Text(
                  'Welcome to Yantra Prasamvidha!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pacifico',
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Our platform is designed to provide seamless solutions for tool rentals.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'Roboto',
                  color: Colors.teal[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Guide Section
              _buildSectionTitle('Guide'),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                name: 'Prof. Pradeep Kumar K G',
                role: 'Head of Department (Computer Science & Engineering)',
                description:
                    'Prof. Pradeep Kumar K G has been instrumental in guiding and mentoring our team throughout the development process. His expertise and insights have been invaluable in shaping this project.',
                imageUrl: 'assets/pradeepsir.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 20),

              // Team Members Section
              _buildSectionTitle('Team Members'),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                name: 'Aneesh S Mayya',
                role: 'Assistant Developer',
                description:
                    'Aneesh played a key role in coordinating tasks and ensuring smooth progress throughout the project.',
                imageUrl: 'assets/aneesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                name: 'Anwesh Krishna B',
                role: 'Lead Developer',
                description:
                    'Anwesh is the backbone of the technical implementation of this project. He handled everything from backend development to integrating APIs and ensuring functionality.',
                imageUrl: 'assets/anwesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                name: 'Chinmaya Thejasvi U S',
                role: 'Assistant Developer',
                description:
                    'Chinmaya contributed to organizing project documentation and resources.',
                imageUrl: 'assets/chinmay.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 10),
              _buildTeamMemberCard(
                name: 'Ganesh B S',
                role: 'Assistant Developer',
                description:
                    'Ganesh assisted in testing the application to ensure it meets quality standards.',
                imageUrl: 'assets/ganesh.jpg',
                isAsset: true,
              ),
              const SizedBox(height: 20),

              // Acknowledgments Section
              _buildSectionTitle('Acknowledgments'),
              const SizedBox(height: 10),
              Text(
                'We extend our heartfelt gratitude to Prof. Pradeep Kumar K G for his guidance and support throughout this project. '
                'We thank Vivekananda College of Engineering and Technology, Puttur, for providing the resources and environment that made this possible. '
                'Special thanks to the Principal, Management, and staff for fostering innovation and academic excellence.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'Roboto',
                  color: Colors.teal[800],
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
                    color: Colors.teal[700],
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
  Widget _buildSectionTitle(String title) {
    return FadeInAnimation(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lobster',
          color: Colors.teal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Helper Method to Build Team Member Cards
Widget _buildTeamMemberCard({
  required String name,
  required String role,
  required String description,
  required String imageUrl,
  bool isAsset = false, // Flag to check if the image is from assets
}) {
  return FadeInAnimation(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Roboto',
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

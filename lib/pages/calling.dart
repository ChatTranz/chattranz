import 'package:flutter/material.dart';

// Placeholder image URL for demonstration. Replace with your actual asset or network path.
const String dummyImageUrl = 'https://wallpapers.com/images/featured/cool-profile-picture-87h46gcobjl5e4xu.webp';

class CallingScreen extends StatelessWidget {
  const CallingScreen({super.key});

  // Helper function to create the rounded call buttons
  Widget _buildCallControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      // Use raw material to easily get a large, circular button with the icon
      shape: const CircleBorder(),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30, // Adjust size of the icon
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height for proportional spacing
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 14, 14, 14),
      // 1. AppBar for the back button and "Calling ..." text
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 14, 14, 14),
        title: const Text(
          'Calling ...',
          style: TextStyle(
            color: Color.fromARGB(255, 236, 236, 236),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // In a real app, this would navigate back
            Navigator.pop(context);
          },
        ),
      ),
      // 2. Main content arranged in a vertical column
      body: Center(
        child: Column(
          // Align content vertically
          mainAxisAlignment: MainAxisAlignment.start,
          // Align content horizontally
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Add vertical space to position the photo lower
            SizedBox(height: screenHeight * 0.1),

            // 3. User Photo (CircleAvatar)
            CircleAvatar(
              radius: 60,
              // Use a placeholder or a network image for demonstration
              backgroundImage: const NetworkImage(dummyImageUrl),
            ),

            // Vertical space between photo and name
            const SizedBox(height: 20),

            // 4. User Name
            const Text(
              'David Wayne',
              style: TextStyle(
                color: Color.fromARGB(255, 236, 236, 236),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Vertical space between name and number
            const SizedBox(height: 8),

            // 5. Phone Number
            const Text(
              '(+44) 50 9285 3022',
              style: TextStyle(
                color: Color.fromARGB(255, 236, 236, 236),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            // Add flexible space to push buttons to the bottom
            const Spacer(),

            // 6. Call Control Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // End Call Button (Red)
                  _buildCallControlButton(
                    // Note the red button has a slight 'X' symbol on the icon in the image
                    icon: Icons.call_end, 
                    backgroundColor: Colors.red,
                    onPressed: () {
                      print('Call Ended');
                    },
                  ),

                  // Horizontal space between buttons
                  const SizedBox(width: 40),

                  // Answer/Video Call Button (Green)
                  _buildCallControlButton(
                    icon: Icons.call,
                    backgroundColor: Colors.green,
                    onPressed: () {
                      print('Call button pressed');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
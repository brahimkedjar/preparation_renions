import 'package:flutter/material.dart';
import 'package:gestion_reunion/home/cree_vote/CreateVotePage.dart';
import 'package:gestion_reunion/home/gerer_utilisateurs/manage_users_page.dart';
import 'package:gestion_reunion/home/orgnize_renion/Orgnize_Renion.dart';

class Home extends StatelessWidget {
  const Home({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the user management page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsersPage()), // Navigate to the user management page
                  );
                },
                child: const Text('Gérer les utilisateurs'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200, // Set a fixed height for the row
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Orgnize_Renion(title: 'Organiser une réunion')),
                      );
                    },
                    child: _buildFeatureContainer('Organiser une réunion', 'assets/images/reunion.png'),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateVotePage()),
                      );
                    },
                    child: _buildFeatureContainer('Créer un vote', 'assets/images/vote.png'),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Orgnize_Renion(title: 'Bourse')),
                      );
                    },
                    child: _buildFeatureContainer('Bourse', 'assets/images/bourse.jpg'),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Orgnize_Renion(title: 'Créer un sondage')),
                      );
                    },
                    child: _buildFeatureContainer('Créer un sondage', 'assets/images/bib.png'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureContainer(String text, String imagePath) {
    return Container(
      height: double.infinity, // Take all available height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEEEEEE)],
          stops: [0.0, 0.7],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

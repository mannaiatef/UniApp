import 'package:flutter/material.dart';
import 'CardFilm.dart';
import 'detail.dart';

class MyFilms extends StatelessWidget {
  const MyFilms({super.key});

  final List<Map<String, String>> films = const [
    {
      "title": "House of Dead",
      "image": "HouseOfDead.jpg",
      "description": "A thrilling horror film about a group of survivors..."
    },
    {
      "title": "Ice Road",
      "image": "iceroad.jpg",
      "description": "An action-packed adventure on a frozen highway..."
    },
    {
      "title": "The Abyss",
      "image": "theabyss.jpg",
      "description": "A deep sea thriller that explores the unknown..."
    },
    {
      "title": "The Grudge",
      "image": "thegrudge.jpg",
      "description": "A terrifying story of a cursed house..."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Films"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailFilm(
                    title: film['title']!,
                    image: film['image']!,
                    description: film['description']!,
                  ),
                ),
              );
            },
            child: CardFilm(
              title: film['title']!,
              image: film['image']!,
            ),
          );
        },
      ),
    );
  }
}

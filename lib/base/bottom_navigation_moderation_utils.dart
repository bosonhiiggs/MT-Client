import 'package:flutter/material.dart';

BottomNavigationBar buildBottomNavigationBarModeration(int currentIndex, Function(int) onItemTapped) {
  return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.book, color: Colors.white),
        label: 'Курсы',
        backgroundColor: Color(0xFFF48FB1),
        activeIcon: Icon(Icons.book, color: Colors.black),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person, color: Colors.white),
        label: 'Мой профиль',
        backgroundColor: Color(0xFFF48FB1),
        activeIcon: Icon(Icons.person, color: Colors.black),
      ),
    ],
    currentIndex: currentIndex,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.white,
    backgroundColor: Color(0xFFF48FB1),
    onTap: onItemTapped,
  );
}

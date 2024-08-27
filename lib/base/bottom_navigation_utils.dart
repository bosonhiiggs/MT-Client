import 'package:flutter/material.dart';

BottomNavigationBar buildBottomNavigationBar(int currentIndex, Function(int) onItemTapped) {
  return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.menu, color: Colors.white),
        label: 'Каталог',
        backgroundColor: Color(0xFFF48FB1),
        activeIcon: Icon(Icons.menu, color: Colors.black),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_border, color: Colors.white),
        label: 'Мои курсы',
        backgroundColor: Color(0xFFF48FB1),
        activeIcon: Icon(Icons.favorite_border, color: Colors.black),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.storage_outlined, color: Colors.white),
        label: 'Преподавание',
        backgroundColor: Color(0xFFF48FB1),
        activeIcon: Icon(Icons.storage_outlined, color: Colors.black),
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
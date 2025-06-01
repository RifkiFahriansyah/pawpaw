import 'package:bottom_bar_matu/bottom_bar/bottom_bar_bubble.dart';
import 'package:bottom_bar_matu/bottom_bar_item.dart';
import 'package:fasum/firebase_options.dart';
import 'package:fasum/screens/Wish/Favorite_screen.dart';
import 'package:fasum/screens/AddPost/add_post_screen.dart';
import 'package:fasum/screens/Profile/edit_profile_screen.dart';
import 'package:fasum/screens/Home/home_screen.dart';
import 'package:fasum/screens/Profile/profile_screen.dart';
import 'package:fasum/screens/Auth/sign_in_screen.dart';
import 'package:fasum/screens/Auth/sign_up_screen.dart';
import 'package:fasum/screens/splash_screen.dart';
import 'package:fasum/screens/theme/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fasum/screens/theme/theme_provider.dart';
import 'package:provider/provider.dart';


void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform, 
  ); 
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),)); 
} 
class MyApp extends StatelessWidget { 
  const MyApp({super.key}); 
  @override 
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.currentTheme,
          home: SplashScreen(),
          initialRoute: '/',
        routes: {
          '/mainscreen': (context) => const MainScreen(),
          '/homescreen': (context) => const HomeScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
        );
      },
    ); 
  } 
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0,3),
            ),
          ],
        ),
        child: BottomBarBubble(
          backgroundColor: Theme.of(context).primaryColorLight,
          selectedIndex: 0,
          color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor!,
          height: 60,
          items: [
            BottomBarItem(
              iconData: Icons.house_outlined,
              label: 'Home',        
            ),
            BottomBarItem(
              iconData: Icons.library_add_check_outlined,
              label: 'Add Post',
            ),
            BottomBarItem(
              iconData: Icons.favorite_border_outlined,
              label: 'WishList',
            ),
            BottomBarItem(
              iconData: Icons.person_outline,
              label: 'Profile',
            ),
          ],
          onSelect: (index) {
            controller.jumpToPage(index);
          },
        ),
      ),
      body: PageView(
        controller: controller,
        children: const <Widget>[
          Center(
            child: HomeScreen(),
          ),
          Center(
            child: AddPostScreen(),
          ),
          Center(
            child: FavoriteScreen(),
          ),
          Center(
            child: ProfileScreen(),
          ),
        ],
      ),
            );
  }
}
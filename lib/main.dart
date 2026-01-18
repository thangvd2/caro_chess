import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'bloc/game_bloc.dart';
import 'ui/game_board_widget.dart';
import 'ui/game_controls_widget.dart';
import 'ui/rule_selector_widget.dart';
import 'ui/rule_guidelines_widget.dart';
import 'ui/profile_screen.dart';
import 'ui/victory_overlay.dart';
import 'ui/shake_widget.dart';
import 'ui/chat_panel.dart';
import 'ui/history_screen.dart';
import 'ui/leaderboard_screen.dart';
import 'ui/shop_screen.dart';
import 'models/user_profile.dart';

import 'models/game_models.dart';
import 'ui/login_screen.dart';
import 'ui/home_screen.dart';
import 'ui/transitions/custom_page_transition.dart';

import 'services/ad_service.dart';

import 'package:flutter/foundation.dart'; // For kIsWeb

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // AdService internally handles web checks, so we can call safely
  AdService().initialize();
  runApp(const CaroChessApp());
}

class CaroChessApp extends StatelessWidget {
  const CaroChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc()..add(LoadSavedGame()),
      child: MaterialApp(
        title: 'Caro Chess',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            surface: const Color(0xFF1E1E2C), // Dark blue-grey surface
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212), // Almost black
          useMaterial3: true,
          
          // Elevate buttons a bit
          elevatedButtonTheme: ElevatedButtonThemeData(
             style: ElevatedButton.styleFrom(
               elevation: 4,
               shadowColor: Colors.deepPurple.withOpacity(0.5),
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               backgroundColor: Colors.deepPurple.shade700,
               foregroundColor: Colors.white,
             ),
          ),
          
          dialogTheme: const DialogThemeData(
             backgroundColor: Color(0xFF1E1E2C),
             surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const AppContent(),
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        Widget child;
        if (state is GameAuthRequired) {
          child = const LoginScreen();
        } else if (state is GameInitial) {
           child = const HomeScreen();
        } else {
           child = const GamePage();
        }
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          transitionBuilder: (Widget child, Animation<double> animation) {
             // Slide from bottom (0.1) to top (0)
             final offsetAnimation = Tween<Offset>(
               begin: const Offset(0.0, 0.1),
               end: Offset.zero,
             ).animate(animation);
             
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                  position: offsetAnimation,
                  child: child
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  
  @override
  void initState() {
    super.initState();
    // Check current state immediately upon mounting
    // This ensures that if we restore directly into GameOver(showAd: true), the ad triggers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkAndShowAd(context.read<GameBloc>().state);
    });
  }

  void _checkAndShowAd(GameState state) {
    if (state is GameOver && state.showAd) {
        print("GamePage: Triggering Interstitial Ad (State Check)");
        
        final adService = AdService();
        if (adService.isInterstitialAdReady) {
           adService.showInterstitialAd(
             onAdDismissed: () {
               if (mounted) {
                 context.read<GameBloc>().add(AdWatched());
               }
             }
           );
        } else {
           print("GamePage: Ad not ready. Waiting for load...");
           StreamSubscription? sub;
           sub = adService.onInterstitialAdLoaded.listen((_) {
               sub?.cancel();
               // Re-verify state and mounting
               if (!mounted) return;
               
               final currentState = context.read<GameBloc>().state;
               if (currentState is GameOver && currentState.showAd) {
                    print("GamePage: Ad loaded delayed. Showing Ad.");
                    adService.showInterstitialAd(
                     onAdDismissed: () {
                       if (mounted) {
                         context.read<GameBloc>().add(AdWatched());
                       }
                     }
                   );
               }
           });
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
         _checkAndShowAd(state);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Caro Chess'),
        actions: [
          Builder(builder: (context) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CustomPageTransition(page: const HistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.leaderboard),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CustomPageTransition(page: const LeaderboardScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.store),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CustomPageTransition(page: const ShopScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    final state = context.read<GameBloc>().state;
                    UserProfile? profile;
                    if (state is GameInProgress) {
                      profile = state.userProfile;
                    } else if (state is GameOver) {
                      profile = state.userProfile;
                    }
                    
                    Navigator.push(
                      context,
                      CustomPageTransition(page: ProfileScreen(
                        profile: profile ?? const UserProfile(id: "Local Player"),
                      )),
                    );
                  },
                ),
              ],
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                       return Visibility(
                         visible: state is GameInitial,
                         child: Column(
                           children: [
                             const RuleSelectorWidget(),
                             const RuleGuidelinesWidget(),
                           ],
                         ),
                       );
                    },
                  ),
                  const SizedBox(height: 10),
                  const GameControlsWidget(),
                  const SizedBox(height: 20),
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      return ShakeWidget(
                        shouldShake: state is GameOver && state.winner != null,
                        child: const GameBoardWidget(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      if (state is GameInProgress && state.mode == GameMode.online) {
                        return ChatPanel(
                          messages: state.messages,
                          onSend: (text) => context.read<GameBloc>().add(SendChatMessage(text)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              bool showConfetti = false;
              if (state is GameOver && state.winner != null) {
                 if (state.mode == GameMode.localPvP) {
                    showConfetti = true; 
                 } else {
                    // Online or vsAI
                    showConfetti = state.winner == state.myPlayer; 
                 }
              }
              return VictoryOverlay(isVisible: showConfetti);
            },
          ),
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
               if (state is GameInProgress && state.isAIThinking) {
                 return Container(
                   color: Colors.black54,
                   child: const Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         CircularProgressIndicator(color: Colors.white),
                         SizedBox(height: 16),
                         Text(
                           "Thinking...",
                           style: TextStyle(
                             color: Colors.white, 
                             fontSize: 18, 
                             fontWeight: FontWeight.bold
                           ),
                         ),
                       ],
                     ),
                   ),
                 );
               }
               return const SizedBox.shrink();
            },
          ),
        ],
      ),
      ),
    );
  }
}
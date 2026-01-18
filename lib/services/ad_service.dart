import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  // TEST ID for Rewarded Ads
  // Android: ca-app-pub-3940256099942544/5224354917
  // iOS: ca-app-pub-3940256099942544/1712485313
  String get _adUnitId {
    if (kIsWeb) return ''; // No ads on web
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadInterstitialAd();
  }

  void loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  void showRewardedAd({required Function(int) onUserEarnedReward}) {
    if (kIsWeb) {
      debugPrint("Ads not supported on Web. Granting fallback reward for testing.");
      onUserEarnedReward(50); // Auto-grant for web testing
      return;
    }
    if (_rewardedAd == null) {
      debugPrint('Warning: Attempting to show rewarded ad before loaded.');
      // Attempt load for next time
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        // Load the next ad immediately
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        onUserEarnedReward(reward.amount.toInt());
      },
    );
    _rewardedAd = null;
  }
  // Test ID for Interstitial Ads
  String get _interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  bool isPremium = false;

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final StreamController<void> _interstitialLoadStream = StreamController.broadcast();
  
  Stream<void> get onInterstitialAdLoaded => _interstitialLoadStream.stream;
  bool get isInterstitialAdReady => _interstitialAd != null;

  void loadInterstitialAd() {
    if (kIsWeb || isPremium) return;
    InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('$ad loaded (Interstitial).');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialLoadStream.add(null);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
            _interstitialAd = null;
            _numInterstitialLoadAttempts += 1;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              loadInterstitialAd();
            }
          },
        ));
  }
  
  void showInterstitialAd({VoidCallback? onAdDismissed}) {
     if (isPremium) {
         debugPrint("AdService: User is Premium. Skipping Interstitial Ad.");
         if (onAdDismissed != null) onAdDismissed();
         return;
     }
     
    if (kIsWeb) {
       debugPrint("Interstitial Ads not supported on Web. Skipping.");
       if (onAdDismissed != null) onAdDismissed(); // Treat as watched on web
       return;
    }
    if (_interstitialAd == null) {
      debugPrint('Warning: Attempted to show interstitial before loaded.');
      _numInterstitialLoadAttempts = 0;
      loadInterstitialAd();
      // If ad not loaded, we must call the callback to proceed (e.g. clear pending flags)
      if (onAdDismissed != null) onAdDismissed();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        loadInterstitialAd(); // Load next one
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadInterstitialAd();
        // Fail safe: clear flag if error
        if (onAdDismissed != null) onAdDismissed();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}

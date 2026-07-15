import 'package:flutter/foundation.dart';

import '../config/config.dart';
import '../infrastructure/audio_manager.dart';
import '../infrastructure/settings_repository.dart';

/// アプリの設定値(言語/BGM/SE/制限時間/☆×4)を保持し、変更を画面に通知する。
class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier(this._repository, this._audioManager)
      : _language = _repository.language,
        _bgmOn = _repository.bgmOn,
        _seOn = _repository.seOn,
        _twoPlayerTimeLimit = _repository.twoPlayerTimeLimit,
        _starTwoPlayer = _repository.starTwoPlayer,
        _starEasy = _repository.starEasy,
        _starNormal = _repository.starNormal,
        _starHard = _repository.starHard {
    _audioManager.bgmEnabled = _bgmOn;
    _audioManager.seEnabled = _seOn;
  }

  final SettingsRepository _repository;
  final AudioManager _audioManager;

  String _language;
  bool _bgmOn;
  bool _seOn;
  TwoPlayerTimeLimit _twoPlayerTimeLimit;
  bool _starTwoPlayer;
  bool _starEasy;
  bool _starNormal;
  bool _starHard;

  String get language => _language;
  bool get bgmOn => _bgmOn;
  bool get seOn => _seOn;
  TwoPlayerTimeLimit get twoPlayerTimeLimit => _twoPlayerTimeLimit;
  bool get starTwoPlayer => _starTwoPlayer;
  bool get starEasy => _starEasy;
  bool get starNormal => _starNormal;
  bool get starHard => _starHard;

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    await _repository.setLanguage(lang);
    notifyListeners();
  }

  Future<void> setBgmOn(bool value) async {
    if (_bgmOn == value) return;
    _bgmOn = value;
    _audioManager.bgmEnabled = value;
    await _repository.setBgmOn(value);
    if (value) {
      await _audioManager.resumeBgm();
    } else {
      await _audioManager.pauseBgm();
    }
    notifyListeners();
  }

  Future<void> setSeOn(bool value) async {
    if (_seOn == value) return;
    _seOn = value;
    _audioManager.seEnabled = value;
    await _repository.setSeOn(value);
    notifyListeners();
  }

  Future<void> setTwoPlayerTimeLimit(TwoPlayerTimeLimit value) async {
    if (_twoPlayerTimeLimit == value) return;
    _twoPlayerTimeLimit = value;
    await _repository.setTwoPlayerTimeLimit(value);
    notifyListeners();
  }

  /// ☆の確定は勝敗決定画面からの画面遷移時に呼ばれる想定。
  Future<void> setStarTwoPlayer(bool value) async {
    if (_starTwoPlayer == value) return;
    _starTwoPlayer = value;
    await _repository.setStarTwoPlayer(value);
    notifyListeners();
  }

  Future<void> setStarEasy(bool value) async {
    if (_starEasy == value) return;
    _starEasy = value;
    await _repository.setStarEasy(value);
    notifyListeners();
  }

  Future<void> setStarNormal(bool value) async {
    if (_starNormal == value) return;
    _starNormal = value;
    await _repository.setStarNormal(value);
    notifyListeners();
  }

  Future<void> setStarHard(bool value) async {
    if (_starHard == value) return;
    _starHard = value;
    await _repository.setStarHard(value);
    notifyListeners();
  }
}

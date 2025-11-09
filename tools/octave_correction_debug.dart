void main() {
  print('🔍 オクターブ補正メソッドの動作確認');
  
  // テストケース: C2域の周波数
  final testFreqs = [
    60.0,   // B1
    65.41,  // C2 (正解)
    73.42,  // D2
    82.41,  // E2
    64.0,   // 境界ケース1
    66.0,   // 境界ケース2
  ];
  
  const minPitchHz = 65.0;
  const maxPitchHz = 1000.0;
  
  print('設定値:');
  print('  minPitchHz: ${minPitchHz}Hz');
  print('  maxPitchHz: ${maxPitchHz}Hz');
  print('');
  
  for (final freq in testFreqs) {
    print('🎵 入力周波数: ${freq}Hz');
    
    // 元のcorrectOctaveロジックを再現
    double correctedPitch = freq;
    
    print('  初期値: ${correctedPitch}Hz');
    
    // 問題のwhile文
    int iterations = 0;
    while (correctedPitch < minPitchHz && correctedPitch > 0) {
      correctedPitch *= 2.0;
      iterations++;
      print('  反復${iterations}: ${correctedPitch}Hz (2倍)');
      
      if (iterations > 10) {
        print('  ⚠️  無限ループ防止で停止');
        break;
      }
    }
    
    // 上限チェック
    while (correctedPitch > maxPitchHz) {
      correctedPitch /= 2.0;
      print('  半分化: ${correctedPitch}Hz');
    }
    
    print('  最終結果: ${correctedPitch}Hz');
    
    // 判定
    if (freq >= 60 && freq <= 75) {
      if (correctedPitch >= 60 && correctedPitch <= 75) {
        print('  ✅ C2域 → C2域 (正しい)');
      } else if (correctedPitch >= 240 && correctedPitch <= 300) {
        print('  ❌ C2域 → C4域 (問題！)');
      } else {
        print('  ❓ C2域 → その他域');
      }
    }
    
    print('');
  }
  
  print('🔬 境界値の詳細テスト:');
  final preciseTests = [64.5, 64.9, 65.0, 65.1, 65.5];
  
  for (final freq in preciseTests) {
    double result = freq;
    if (result < minPitchHz && result > 0) {
      result *= 2.0;
    }
    print('${freq}Hz → ${result}Hz (${freq < minPitchHz ? "補正あり" : "補正なし"})');
  }
  
  print('\n💡 解決策の提案:');
  print('1. minPitchHzを64.0Hzに下げる');
  print('2. 境界判定の条件を < ではなく <= に変更');
  print('3. C2域の特別処理を追加');
}

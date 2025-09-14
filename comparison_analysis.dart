import 'package:isebushi_karaoke/infrastructure/logging/console_logger.dart';

void main() {
  final logger = ConsoleLogger();
  logger.info('=== Test.wav検出結果比較 ===');
  
  logger.info('\n📊 検出範囲変更前後の比較:');
  logger.info('変更前設定: minPitchHz=80Hz, maxPitchHz=600Hz');
  logger.info('変更後設定: minPitchHz=65Hz, maxPitchHz=1000Hz');
  
  logger.info('\n🎵 検出結果:');
  logger.info('【変更前】2025-07-31T16-04-46（80-600Hz範囲）');
  logger.info('範囲: 256.6Hz 〜 528.2Hz（実質的に同じ）');
  logger.info('平均: 384.6Hz');
  logger.info('最初の8音: 262.67→290.87→326.24→345.96→392.74→438.45→490.07→527.18');
  
  logger.info('\n【変更後】2025-07-31T16-54-15（65-1000Hz範囲）');
  logger.info('範囲: 256.6Hz 〜 528.2Hz（同じ）'); 
  logger.info('平均: 384.6Hz（同じ）');
  logger.info('最初の8音: 262.67→290.87→326.24→345.96→392.74→438.45→490.07→527.18');
  
  logger.info('\n🤔 分析結果:');
  logger.info('✅ 検出値は全く同じ → アルゴリズムは正常動作');
  logger.info('❌ 依然としてC4域（260-520Hz）で検出');
  logger.info('❌ C2域（65-130Hz）での検出なし');
  
  logger.info('\n🔍 考察:');
  logger.info('1. minPitchHz=65Hzに変更しても結果不変');
  logger.info('2. Test.wavの実際のピッチは256-528Hzで記録されている可能性');
  logger.info('3. または、ハーモニクス検出問題が根本原因');
  logger.info('4. WAVファイル自体がC4で録音されている可能性も');
  
  logger.info('\n📝 次のステップ:');
  logger.info('1. WAVファイルの内容を詳細分析');
  logger.info('2. Basic Pitchとの比較検証');
  logger.info('3. ハーモニクス分析の強化検討');
  logger.info('4. 他のC2音階ファイルでのテスト');
}

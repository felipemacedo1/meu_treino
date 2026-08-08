#!/usr/bin/env bash
# Gera o APK de release do Meu Treino.
#
# O app precisa saber onde está a API. Você pode:
#   - passar o endereço:  bash scripts/build-apk.sh 192.168.0.8:8080
#   - ou deixar em branco: o script usa o IP desta máquina na LAN
#
# De qualquer forma, o endereço pode ser trocado depois dentro do app,
# na tela de login ("Servidor"). O valor daqui é apenas o padrão.
set -e
cd "$(dirname "$0")/.."

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  TARGET="$(hostname -I | awk '{print $1}'):${API_PORT:-8080}"
  echo "==> Nenhum endereço informado, usando o IP desta máquina: $TARGET"
fi

case "$TARGET" in
  http://*|https://*) BASE="$TARGET" ;;
  *)                  BASE="http://$TARGET" ;;
esac
BASE="${BASE%/}"
case "$BASE" in
  */api) ;;
  *) BASE="$BASE/api" ;;
esac

echo "==> API padrão do APK: $BASE"

if [ ! -f android/key.properties ]; then
  echo "==> android/key.properties ausente: o APK sairá com a chave de debug."
  echo "    Veja o README (secao Android) para gerar a chave de release."
fi

cd app
flutter pub get >/dev/null

VERSION="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
mkdir -p ../dist

# Universal: um arquivo que instala em qualquer aparelho.
flutter build apk --release --dart-define=API_BASE_URL="$BASE"
cp build/app/outputs/flutter-apk/app-release.apk "../dist/meu-treino-${VERSION}.apk"

# Por arquitetura: bem menores, para quem sabe o aparelho que tem.
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL="$BASE"
for abi in arm64-v8a armeabi-v7a x86_64; do
  SRC="build/app/outputs/flutter-apk/app-${abi}-release.apk"
  [ -f "$SRC" ] && cp "$SRC" "../dist/meu-treino-${VERSION}-${abi}.apk"
done

cd ..
echo
echo "====================================================================="
echo " APKs em dist/"
for f in dist/meu-treino-${VERSION}*.apk; do
  printf "   %-42s %s\n" "$(basename "$f")" "$(du -h "$f" | cut -f1)"
done
echo
echo " API padrão: $BASE   (trocável no app, tela de login > Servidor)"
echo " Assinatura: $(if [ -f app/android/key.properties ]; then echo 'chave de release'; else echo 'chave de DEBUG'; fi)"
echo
echo " Instalar via USB: adb install -r dist/meu-treino-${VERSION}.apk"
echo " Ou copie o arquivo para o celular e abra (permita 'fontes desconhecidas')."
echo "====================================================================="
